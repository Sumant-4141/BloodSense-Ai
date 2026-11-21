import 'package:flutter/services.dart' show rootBundle;
import '../pdf_extractor.dart';
import 'normalizer.dart';
import 'evaluator.dart';

// ---------------------------------------------------
// 1. Simple CSV Parser Helper
// ---------------------------------------------------
Future<List<Map<String, dynamic>>> loadCsvData(String assetPath) async {
  final String csvString = await rootBundle.loadString(assetPath);
  List<String> lines = csvString.split('\n');
  
  if (lines.isEmpty) return [];

  List<String> headers = lines.first.split(',').map((e) => e.trim()).toList();
  List<Map<String, dynamic>> data = [];

  for (int i = 1; i < lines.length; i++) {
    if (lines[i].trim().isEmpty) continue; // Skip empty lines
    
    List<String> values = lines[i].split(',').map((e) => e.trim()).toList();
    Map<String, dynamic> row = {};
    
    for (int j = 0; j < headers.length; j++) {
      row[headers[j]] = j < values.length ? values[j] : "";
    }
    data.add(row);
  }
  
  return data;
}

// ---------------------------------------------------
// 2. The Master Processing Function (Handles Multi-Page!)
// ---------------------------------------------------
Future<List<Map<String, dynamic>>> generateEvaluatedReport(List<String> imagePaths, String defaultGender) async {
  print("--- STARTING AI BLOOD REPORT ANALYSIS (${imagePaths.length} Pages) ---");

  Map<String, dynamic> combinedRawValues = {};

  // Step 1: Loop through all pages and merge the extracted data!
  for (String path in imagePaths) {
    print("Scanning page: $path...");
    Map<String, dynamic> pageValues = await extractLabValuesFromImage(path);
    combinedRawValues.addAll(pageValues); // Combine them into the master map
  }

  // Grab the gender detected by the OCR on any of the pages
  String patientGender = combinedRawValues["Gender"]?.toString() ?? defaultGender;
  combinedRawValues.remove("Gender"); 

  // Step 2: Load Datasets from Assets
  List<Map<String, dynamic>> synonymsDf = await loadCsvData('assets/marker_synonyms.csv');
  List<Map<String, dynamic>> referenceDf = await loadCsvData('assets/reference_ranges.csv');

  // Step 3: Build Synonym Dictionary
  Map<String, String> synonymMap = buildSynonymMap(synonymsDf);

  List<Map<String, dynamic>> finalEvaluatedResults = [];

  // Step 4: Process Each Extracted Marker
  combinedRawValues.forEach((rawMarker, value) {
    String standardMarker = normalizeMarker(rawMarker, synonymMap);
    Map<String, dynamic> evaluation = evaluateMarker(standardMarker, value, patientGender, referenceDf);

    // Step 5: Filter out OCR garbage
    if (evaluation["status"] != "No Reference" && evaluation["status"] != "Invalid Value") {
      evaluation["original_ocr_name"] = rawMarker;
      evaluation["extracted_value"] = value;
      finalEvaluatedResults.add(evaluation);
      print("🧬 PROCESSED: ${evaluation['marker']} | Value: $value | Status: ${evaluation['status']} (${evaluation['severity']})");
    }
  });

  print("--- ANALYSIS COMPLETE ---");
  return finalEvaluatedResults;
}


// ---------------------------------------------------
// 3. Manual Data Processing Function
// ---------------------------------------------------
Future<List<Map<String, dynamic>>> processManualData(
  Map<String, dynamic> rawValues,
  String patientGender,
) async {
  List<Map<String, dynamic>> synonymsDf = await loadCsvData(
    'assets/marker_synonyms.csv',
  );
  List<Map<String, dynamic>> referenceDf = await loadCsvData(
    'assets/reference_ranges.csv',
  );
  Map<String, String> synonymMap = buildSynonymMap(synonymsDf);

  List<Map<String, dynamic>> finalEvaluatedResults = [];

  rawValues.forEach((rawMarker, value) {
    String standardMarker = normalizeMarker(rawMarker, synonymMap);
    Map<String, dynamic> evaluation = evaluateMarker(
      standardMarker,
      value,
      patientGender,
      referenceDf,
    );

    if (evaluation["status"] != "No Reference" &&
        evaluation["status"] != "Invalid Value") {
      evaluation["original_ocr_name"] = rawMarker;
      evaluation["extracted_value"] = value;
      finalEvaluatedResults.add(evaluation);
    }
  });

  return finalEvaluatedResults;
}