import 'dart:convert';
import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';

// ==========================================
// 1. BMI CALCULATOR HELPER
// ==========================================
Map<String, dynamic> calculateBMI(double weightKg, double heightCm) {
  double heightM = heightCm / 100;
  double bmi = weightKg / pow(heightM, 2);
  
  String category;
  if (bmi < 18.5) category = "Underweight";
  else if (bmi < 24.9) category = "Normal weight";
  else if (bmi < 29.9) category = "Overweight";
  else category = "Obese";

  return {
    "bmi_value": double.parse(bmi.toStringAsFixed(1)),
    "category": category,
  };
}

// ==========================================
// 2. TRUE GENERATIVE AI ENGINE
// ==========================================
// ==========================================
// 2. TRUE GENERATIVE AI ENGINE
// ==========================================
Future<Map<String, dynamic>> generateTrueAIPersonalizedPlan({
  required double weightKg,
  required double heightCm,
  required String goal, 
  required String dietaryPreference, // <-- NEW PARAMETER ADDED
  List<Map<String, dynamic>>? bloodReportRisks, 
}) async {
  
  var bmiData = calculateBMI(weightKg, heightCm);
  
  String medicalContext = "None. The user is generally healthy.";
  if (bloodReportRisks != null && bloodReportRisks.isNotEmpty) {
    List<String> riskStatements = [];
    for (var risk in bloodReportRisks) {
      riskStatements.add(risk["risk"].toString());
    }
    medicalContext = "WARNING: The user has the following anomalous blood markers and risks: ${riskStatements.join(' | ')}. You MUST tailor the diet and exercise to mitigate these risks safely.";
  }

  const apiKey = 'AIzaSyCeA3OL1gzSpSpPU2vQhNSzIoM-aTgIAEQ'; // Keep your actual key here!
  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
    generationConfig: GenerationConfig(
      temperature: 0.4, 
      responseMimeType: 'application/json', 
    ),
  );

  // <-- UPDATED PROMPT -->
  final prompt = '''
    You are an expert clinical nutritionist and certified personal trainer. 
    Generate a highly personalized daily diet and exercise plan.
    
    USER PROFILE:
    - Weight: $weightKg kg
    - Height: $heightCm cm
    - BMI: ${bmiData['bmi_value']} (${bmiData['category']})
    - Primary Fitness Goal: $goal
    - Dietary Preference: $dietaryPreference 
    
    MEDICAL CONTEXT:
    $medicalContext

    INSTRUCTIONS:
    1. If there is a Medical Context warning, it STRICTLY overrides their fitness goal.
    2. You MUST strictly adhere to the Dietary Preference ($dietaryPreference). For example, if "Vegan", include absolutely zero animal products.
    3. Provide an estimated daily calorie target.
    4. Structure the diet into exact meals (Breakfast, Lunch, Dinner, Snack).

    OUTPUT FORMAT:
    You must respond ONLY with a valid JSON object matching this exact schema:
    {
      "ai_insight": "A 2-sentence clinical explanation of this plan.",
      "daily_calories": "e.g., 2200 kcal",
      "diet_plan": ["Breakfast: [food]", "Lunch: [food]", "Dinner: [food]", "Snack: [food]"],
      "workout_plan": ["Warmup: [text]", "Main: [text]", "Cooldown: [text]"],
      "foods_to_avoid": ["Food 1", "Food 2"]
    }
  ''';

  // --- ROBUST AUTO-RETRY LOGIC (EXPONENTIAL BACKOFF) ---
  int maxRetries = 3;
  int delaySeconds = 2;

  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      // 1. Make the API Call
      final response = await model.generateContent([Content.text(prompt)]);
      final String responseText = response.text ?? "{}";
      
      // 2. Decode the JSON
      Map<String, dynamic> aiData = json.decode(responseText);
      
      // 3. If successful, return the data and EXIT the loop
      return {
        "bmi_data": bmiData,
        "goal": goal,
        "ai_insight": aiData["ai_insight"] ?? "Plan generated successfully.",
        "daily_calories": aiData["daily_calories"] ?? "Calculating...",
        "diet_plan": aiData["diet_plan"] ?? [],
        "workout_plan": aiData["workout_plan"] ?? [],
        "foods_to_avoid": aiData["foods_to_avoid"] ?? [],
      };
      
    } catch (e) {
      String rawError = e.toString();
      print("Attempt $attempt failed: $rawError");

      // 4. Check if it's a "Server Busy" (503) or "Quota" (429) error
      if (rawError.contains("503") || rawError.contains("429") || rawError.contains("high demand")) {
        
        // If we have tried 3 times and it STILL fails, tell the user.
        if (attempt == maxRetries) {
          throw Exception("The AI servers are exceptionally busy right now. Please wait a minute and tap Generate again.");
        }
        
        // Otherwise, silently wait and try again!
        print("Servers busy. Retrying in $delaySeconds seconds...");
        await Future.delayed(Duration(seconds: delaySeconds));
        
        // Double the wait time for the next attempt (2s -> 4s -> 8s)
        delaySeconds *= 2; 
        
      } else {
        // If it's a DIFFERENT error (like no internet), throw it immediately so the user knows.
        throw Exception("Could not connect to the AI. Please check your internet and try again.");
      }
    }
  }
  
  // Fallback in case the loop completely breaks (safety net)
  throw Exception("An unexpected error occurred during generation.");
}