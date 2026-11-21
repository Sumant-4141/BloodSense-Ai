import 'dart:async';
import 'package:flutter/material.dart';
import 'core/planner_engine.dart'; 

class AiPlannerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> healthRisks; 

  const AiPlannerScreen({Key? key, required this.healthRisks}) : super(key: key);

  @override
  State<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends State<AiPlannerScreen> {
  final Color _darkNavy = const Color(0xFF0F172A);
  final Color _emerald = const Color(0xFF10B981);
  
  // User Inputs
  double _weight = 70.0;
  double _height = 170.0;
  String _selectedGoal = "Stay Fit";
  String _selectedDiet = "Standard";
  
  final List<String> _goals = ["Lose Weight", "Gain Weight", "Stay Fit", "Hardcore Muscles"];
  final List<String> _diets = ["Standard", "Vegetarian", "Vegan", "Keto", "Lactose-Free"];

  // State Management
  bool _isLoading = false;
  Map<String, dynamic>? _generatedPlan;

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _generatedPlan = null; 
    });

    try {
      final result = await generateTrueAIPersonalizedPlan(
        weightKg: _weight,
        heightCm: _height,
        goal: _selectedGoal,
        dietaryPreference: _selectedDiet,
        bloodReportRisks: widget.healthRisks,
      );

      // Add a tiny artificial delay so the user can enjoy the loading animation
      await Future.delayed(const Duration(milliseconds: 1500));

      setState(() {
        _generatedPlan = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // UI: INPUT FORM STATE
  // ==========================================
  Widget _buildInputState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Physical Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          
          // Height Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200, width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Height", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black54)), Text("${_height.toInt()} cm", style: TextStyle(color: _darkNavy, fontWeight: FontWeight.bold, fontSize: 18))]),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(activeTrackColor: _darkNavy, inactiveTrackColor: Colors.grey.shade200, thumbColor: _darkNavy, overlayColor: _darkNavy.withOpacity(0.1), trackHeight: 6),
                  child: Slider(value: _height, min: 120, max: 220, divisions: 100, onChanged: (val) => setState(() => _height = val)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weight Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200, width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Weight", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black54)), Text("${_weight.toInt()} kg", style: TextStyle(color: _darkNavy, fontWeight: FontWeight.bold, fontSize: 18))]),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(activeTrackColor: _darkNavy, inactiveTrackColor: Colors.grey.shade200, thumbColor: _darkNavy, overlayColor: _darkNavy.withOpacity(0.1), trackHeight: 6),
                  child: Slider(value: _weight, min: 40, max: 150, divisions: 110, onChanged: (val) => setState(() => _weight = val)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Dietary Preference
          const Text("Dietary Preference", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _diets.map((diet) {
              bool isSelected = _selectedDiet == diet;
              return ChoiceChip(
                label: Text(diet, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                selected: isSelected,
                selectedColor: _darkNavy,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? _darkNavy : Colors.grey.shade300)),
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                onSelected: (selected) { if (selected) setState(() => _selectedDiet = diet); },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Primary Goal
          const Text("Primary Goal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _goals.map((goal) {
              bool isSelected = _selectedGoal == goal;
              return ChoiceChip(
                label: Text(goal, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                selected: isSelected,
                selectedColor: _emerald,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? _emerald : Colors.grey.shade300)),
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                onSelected: (selected) { if (selected) setState(() => _selectedGoal = goal); },
              );
            }).toList(),
          ),
          const SizedBox(height: 48),

          // Generate Button
          ElevatedButton.icon(
            onPressed: _generatePlan,
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text("Generate AI Plan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: _darkNavy, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

 
  // ==========================================
  // HELPER: BUILD EXPANDABLE CARDS (Diet & Workout)
  // ==========================================
  Widget _buildExpandableList(List items, IconData icon, Color iconColor, Color bgColor, String defaultTitle) {
    return Column(
      children: items.map((item) {
        String fullText = item.toString();
        
        // Find the colon (e.g., "Breakfast: ") to split the Title from the Content
        int colonIndex = fullText.indexOf(':');
        String title = defaultTitle;
        String content = fullText;

        if (colonIndex != -1 && colonIndex < 30) {
          title = fullText.substring(0, colonIndex).trim().toUpperCase();
          content = fullText.substring(colonIndex + 1).trim();
        }

        // --- NEW LOGIC: Smart String Splitter for Bullet Points ---
        // 1. Try splitting by periods, newlines, or existing bullet dashes
        List<String> rawPoints = content.split(RegExp(r'\.\s+|\n|•\s*'));
        
        List<String> bulletPoints = rawPoints.map((p) {
          String clean = p.trim();
          // Remove stray hyphens or asterisks at the start
          if (clean.startsWith('-') || clean.startsWith('*')) {
            clean = clean.substring(1).trim();
          }
          // Remove stray periods at the end
          if (clean.endsWith('.')) {
            clean = clean.substring(0, clean.length - 1);
          }
          return clean;
        }).where((p) => p.isNotEmpty).toList();

        // 2. Fallback: If it's just one short sentence, split by commas instead to force a list!
        if (bulletPoints.length == 1 && content.contains(',')) {
           rawPoints = content.split(RegExp(r',\s*'));
           bulletPoints = rawPoints.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent), 
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              iconColor: Colors.grey.shade600,
              collapsedIconColor: Colors.grey.shade600,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20)
              ),
              // Bold Title (e.g., BREAKFAST)
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              // One-line Preview Text
              subtitle: Text(content, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4)),
              childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              children: [
                Divider(color: Colors.grey.shade100, height: 1.5),
                const SizedBox(height: 16),
                
                // --- NEW UI: Render as Bullet Points ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: bulletPoints.map((point) {
                    // Capitalize the first letter of each bullet point nicely
                    String formattedPoint = point.isNotEmpty 
                        ? point[0].toUpperCase() + point.substring(1) 
                        : point;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6, right: 12),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: iconColor, // Uses the blue for workouts, orange for diet!
                              shape: BoxShape.circle
                            ),
                          ),
                          Expanded(
                            child: Text(
                              formattedPoint, 
                              style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4)
                            )
                          ),
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



  // --- NEW HELPER: Floating AI Badge ---
  Widget _buildFloatingBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
        ],
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




  // ==========================================
  // UI: RESULTS DISPLAY STATE
  // ==========================================
  Widget _buildResultsState() {
    var plan = _generatedPlan!;
    List avoids = plan["foods_to_avoid"] as List;
    List meals = plan["diet_plan"] as List;
    List workouts = plan["workout_plan"] as List;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         // ==========================================
          // 1. NEW AI INSIGHT CARD (Green)
          // ==========================================
          Stack(
            clipBehavior: Clip.none, // Allows the badge to float outside the box
            children: [
              Container(
                margin: const EdgeInsets.only(top: 14), // Pushes the box down to make room for the badge
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)], // Deep to vibrant green
                    begin: Alignment.topLeft, end: Alignment.bottomRight
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8), // Spacing so badge doesn't cover title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22)
                        ),
                        const SizedBox(width: 12),
                        const Text("AI Clinical Insight", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                      ]
                    ),
                    const SizedBox(height: 16),
                    Text(plan["ai_insight"].toString(), style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 15)),
                  ],
                ),
              ),
              // The Floating Badge!
              Positioned(
                top: 0,
                left: 20,
                child: _buildFloatingBadge(const Color(0xFF059669)),
              )
            ],
          ),
          
          // ==========================================
          // 2. NEW MEDICAL RESTRICTIONS CARD (Red)
          // ==========================================
          if (avoids.isNotEmpty) ...[
            const SizedBox(height: 24),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDC2626), Color(0xFFEF4444)], // Deep to vibrant red
                      begin: Alignment.topLeft, end: Alignment.bottomRight
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22)
                          ),
                          const SizedBox(width: 12),
                          const Text("Medical Restrictions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        ]
                      ),
                      const SizedBox(height: 16),
                      // Render the restrictions with "X" icons instead of dots
                      ...avoids.map((food) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.close, size: 18, color: Colors.white), // White X mark
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(food.toString(), style: const TextStyle(color: Colors.white, height: 1.4, fontSize: 15))),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 20,
                  child: _buildFloatingBadge(const Color(0xFFDC2626)),
                )
              ],
            ),
          ],
          
          const SizedBox(height: 32),
          const Text("Dietary Protocol", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          
          // NEW: Expandable Diet Cards
          _buildExpandableList(meals, Icons.restaurant, const Color(0xFFD97706), const Color(0xFFFEF0E6), "MEAL"),

          const SizedBox(height: 32),
          const Text("Workout Routine", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),

          // NEW: Expandable Workout Cards
          _buildExpandableList(workouts, Icons.fitness_center, const Color(0xFF0284C7), const Color(0xFFE0F2FE), "EXERCISE"),

          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: () => setState(() => _generatedPlan = null),
            icon: const Icon(Icons.refresh),
            label: const Text("Adjust Parameters", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(foregroundColor: _darkNavy, minimumSize: const Size(double.infinity, 56), side: BorderSide(color: Colors.grey.shade300, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading ? const _PlannerLoadingScreen() : Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.5))),
            child: Row(
              children: [
                InkWell(onTap: () => Navigator.pop(context), borderRadius: BorderRadius.circular(30), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20))),
                const SizedBox(width: 16),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("AI Health", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, height: 1.1)), Text("Planner", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, height: 1.1))])),
              ],
            ),
          ),
          Expanded(
            child: _generatedPlan == null ? _buildInputState() : _buildResultsState(),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// UI: CUSTOM LOADING OVERLAY
// ==========================================
class _PlannerLoadingScreen extends StatefulWidget {
  const _PlannerLoadingScreen({Key? key}) : super(key: key);
  @override
  State<_PlannerLoadingScreen> createState() => _PlannerLoadingScreenState();
}

class _PlannerLoadingScreenState extends State<_PlannerLoadingScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  double _progress = 0.0;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!mounted) return;
      setState(() {
        if (_progress < 0.9) _progress += 0.08; 
        if (timer.tick == 2) _currentStep = 1; 
        if (timer.tick == 4) _currentStep = 2; 
        if (timer.tick == 6) _currentStep = 3; 
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildStepCard(String title, IconData icon, int stepIndex) {
    bool isActive = _currentStep == stepIndex;
    bool isCompleted = _currentStep > stepIndex;
    bool isPending = _currentStep < stepIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(color: isActive ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: isActive ? Colors.white.withOpacity(0.3) : Colors.transparent, width: 1)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: isPending ? Colors.white38 : Colors.white, size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(color: isPending ? Colors.white54 : Colors.white, fontSize: 15, fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal))),
          if (isCompleted) const Icon(Icons.check_circle_outline, color: Color(0xFF00E676), size: 22)
          else if (isActive) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F172A), Color(0xFF10B981)]),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Stack(
                alignment: Alignment.center,
                children: [
                  ScaleTransition(scale: _pulseAnimation, child: Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.15), width: 2)))),
                  Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5))),
                  const Icon(Icons.auto_awesome, size: 50, color: Colors.white),
                ],
              ),
              const SizedBox(height: 40),
              const Text("Generating Custom\nHealth Protocol...", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
              const SizedBox(height: 48),
              _buildStepCard("Evaluating physical profile", Icons.person_outline, 0),
              _buildStepCard("Cross-referencing medical data", Icons.biotech, 1),
              _buildStepCard("Structuring macronutrients", Icons.restaurant_menu, 2),
              if (_currentStep >= 2) _buildStepCard("Designing workout regimen", Icons.fitness_center, 3),
              const Spacer(),
              ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: _progress, minHeight: 6, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}