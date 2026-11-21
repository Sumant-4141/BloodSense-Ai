import 'package:flutter/material.dart';

class StandardPlanScreen extends StatefulWidget {
  const StandardPlanScreen({Key? key}) : super(key: key);

  @override
  State<StandardPlanScreen> createState() => _StandardPlanScreenState();
}

class _StandardPlanScreenState extends State<StandardPlanScreen> {
  final Color _darkNavy = const Color(0xFF0F172A);
  final Color _emerald = const Color(0xFF10B981);

  // ==========================================
  // HARDCODED CLINICAL DATA (Vegan, RBC 4, BMI 31.1)
  // ==========================================
  final String _insightText = "This protocol is optimized for a Vegan diet with a focus on improving cardiovascular fitness and supporting red blood cell (RBC) production. Given a BMI of 31.1, the routine prioritizes joint-friendly exercises. The diet emphasizes iron-rich plant foods and Vitamin C combinations to address the borderline low RBC count.";
  
  final String _totalDietCalories = "1,410 kcal";
  final String _totalWorkoutBurn = "350 kcal burn";

  

  // --- UPGRADED: Maps containing Text AND Image URLs ---
  final List<Map<String, String>> _dietPlan = [
    {
      "text": "Breakfast: Iron-fortified oatmeal made with soy milk || 210 kcal • Pumpkin seeds and strawberries (Vitamin C) || 150 kcal • B12 supplement || 0 kcal",
      "image": "https://img.freepik.com/premium-photo/healthy-breakfast_200402-11108.jpg", // Oatmeal
    },
    {
      "text": "Lunch: Large spinach and kale salad || 80 kcal • 1/2 cup lentils and quinoa || 220 kcal • Cherry tomatoes and lemon-tahini dressing || 110 kcal",
      "image": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=300&q=80" // Salad
    },
    {
      "text": "Snack: A handful of walnuts || 180 kcal • 1 whole orange || 60 kcal",
      "image": "https://images.rawpixel.com/image_800/czNmcy1wcml2YXRlL3Jhd3BpeGVsX2ltYWdlcy93ZWJzaXRlX2NvbnRlbnQvbHIvcHg2Njg0MTAtaW1hZ2Uta3d2eGxnazcuanBn.jpg" // Walnuts/Fruit
    },
    {
      "text": "Dinner: Tofu and broccoli stir-fry with bell peppers || 250 kcal • Small portion of brown rice || 150 kcal",
      "image": "https://www.99acorns.com/wp-content/uploads/2024/11/Healthy-Dinner-Ideas.jpg" // Veggie Bowl
    }
  ];

  final List<Map<String, String>> _workoutPlan = [
    {
      "text": "Warm-up: 5-7 minutes of dynamic stretching || 25 kcal • Arm circles, gentle torso twists, and walking in place || 15 kcal",
      "image": "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=300&q=80" // Stretching
    },
    {
      "text": "Cardio (Low Impact): 20-30 minutes of brisk walking, swimming, or cycling || 180 kcal",
      "image": "https://www.mensjournal.com/.image/w_3840,q_auto:good,c_fill,ar_16:9/MjEwMzk2ODkyMzc3ODUxNzI5/man-running-on-treadmill.jpg" // Shoes
    },
    {
      "text": "Strength (Light): 3 sets of 10 Wall Pushups || 40 kcal • 3 sets of 12 Chair Squats (sit to stand) || 50 kcal • 3 sets of 20-second Planks || 20 kcal",
      "image": "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&w=300&q=80" // Weights
    },
    {
      "text": "Cool-down: 5-10 minutes of gentle static stretching || 20 kcal",
      "image": "https://tse3.mm.bing.net/th/id/OIP.kVh-EiEym-F1gAx67wkxdAHaEK?pid=Api&P=0&h=180" // Yoga Mat
    }
  ];

  // ==========================================
  // UI HELPERS 
  // ==========================================
  Widget _buildFloatingBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: color),
          const SizedBox(width: 4),
          Text("AI-SAGE", style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  // --- UPGRADED EXPANDABLE LIST WITH IMAGE SUPPORT ---
  Widget _buildExpandableList(List<Map<String, String>> items, IconData icon, Color iconColor, Color bgColor, String defaultTitle) {
    return Column(
      children: items.map((item) {
        String fullText = item["text"]!;
        String imageUrl = item["image"]!;
        
        int colonIndex = fullText.indexOf(':');
        String title = defaultTitle;
        String content = fullText;

        if (colonIndex != -1 && colonIndex < 30) {
          title = fullText.substring(0, colonIndex).trim().toUpperCase();
          content = fullText.substring(colonIndex + 1).trim();
        }

        List<String> rawPoints = content.split(RegExp(r'\.\s+|\n|•\s*'));
        List<String> bulletPoints = rawPoints.map((p) {
          String clean = p.trim();
          if (clean.startsWith('-') || clean.startsWith('*')) clean = clean.substring(1).trim();
          if (clean.endsWith('.')) clean = clean.substring(0, clean.length - 1);
          return clean;
        }).where((p) => p.isNotEmpty).toList();

        if (bulletPoints.length == 1 && content.contains(',')) {
           rawPoints = content.split(RegExp(r',\s*'));
           bulletPoints = rawPoints.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
        }

        int subTotal = 0;
        for (String bp in bulletPoints) {
          if (bp.contains("||")) {
            String calStr = bp.split("||")[1].replaceAll(RegExp(r'[^0-9]'), '');
            if (calStr.isNotEmpty) {
              subTotal += int.parse(calStr);
            }
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent), 
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              iconColor: Colors.grey.shade600, collapsedIconColor: Colors.grey.shade600,
              
              // --- UPGRADED LEADING WIDGET (Image with Icon Fallback) ---
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // If image fails to load, show the beautiful colored icon instead!
                    return Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), 
                      child: Icon(icon, color: iconColor, size: 24)
                    );
                  },
                ),
              ),
              
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87))),
                  if (subTotal > 0)
                    Text("$subTotal kcal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: iconColor)),
                ],
              ),
              
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(content.replaceAll(RegExp(r'\|\|[^•]+'), ''), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4)),
              ),
              childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              children: [
                Divider(color: Colors.grey.shade100, height: 1.5),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: bulletPoints.map((point) {
                    String displayPoint = point;
                    String calorieValue = "";
                    
                    if (point.contains("||")) {
                      var parts = point.split("||");
                      displayPoint = parts[0].trim();
                      calorieValue = parts[1].trim();
                    }
                    
                    String formattedPoint = displayPoint.isNotEmpty ? displayPoint[0].toUpperCase() + displayPoint.substring(1) : displayPoint;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(margin: const EdgeInsets.only(top: 6, right: 12), width: 6, height: 6, decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle)),
                          Expanded(child: Text(formattedPoint, style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4))),
                          if (calorieValue.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(calorieValue, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                            )
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // MAIN BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.5))),
            child: Row(
              children: [
                InkWell(onTap: () => Navigator.pop(context), borderRadius: BorderRadius.circular(30), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20))),
                const SizedBox(width: 16),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Targeted Health", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, height: 1.1)), Text("Protocol", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, height: 1.1))])),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 14),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22)),
                                const SizedBox(width: 12),
                                const Text("Clinical Insight", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                              ]
                            ),
                            const SizedBox(height: 16),
                            Text(_insightText, style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 15)),
                          ],
                        ),
                      ),
                      Positioned(top: 0, left: 20, child: _buildFloatingBadge(const Color(0xFF059669))),
                    ],
                  ),
            
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Dietary Protocol", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFEF0E6), borderRadius: BorderRadius.circular(20)), child: Text(_totalDietCalories, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD97706))))
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildExpandableList(_dietPlan, Icons.restaurant, const Color(0xFFD97706), const Color(0xFFFEF0E6), "MEAL"),

                  const SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Workout Routine", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(20)), child: Text(_totalWorkoutBurn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0284C7))))
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildExpandableList(_workoutPlan, Icons.fitness_center, const Color(0xFF0284C7), const Color(0xFFE0F2FE), "EXERCISE"),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}