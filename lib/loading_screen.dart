import 'dart:async';
import 'package:flutter/material.dart';

class AnalysisLoadingScreen extends StatefulWidget {
   AnalysisLoadingScreen({Key? key}) : super(key: key);

  @override
  State<AnalysisLoadingScreen> createState() => _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends State<AnalysisLoadingScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  double _progress = 0.0;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup the pulsing brain animation
    _pulseController = AnimationController(
      vsync: this,
      duration:  Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 2. Setup the fake progress timer
    _timer = Timer.periodic( Duration(milliseconds: 800), (timer) {
      if (!mounted) return;
      
      setState(() {
        // Increment progress bar smoothly
        if (_progress < 0.9) {
          _progress += 0.08; 
        }

        // Advance the text steps based on timer ticks
        if (timer.tick == 2) _currentStep = 1; // Analyzing biomarkers
        if (timer.tick == 4) _currentStep = 2; // AI health evaluation
        if (timer.tick == 6) _currentStep = 3; // Generating insights
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // --- HELPER: BUILD A STEP CARD ---
  Widget _buildStepCard({required String title, required IconData icon, required int stepIndex}) {
    bool isCompleted = _currentStep > stepIndex;
    bool isActive = _currentStep == stepIndex;
    bool isPending = _currentStep < stepIndex;

    return AnimatedContainer(
      duration:  Duration(milliseconds: 300),
      margin:  EdgeInsets.only(bottom: 12),
      padding:  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        // Highlight active step slightly more
        color: isActive ? Colors.white.withOpacity(0.15) :  Color.fromARGB(255, 0, 0, 0).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ?  Color.fromARGB(255, 0, 0, 0).withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            padding:  EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:  Color.fromARGB(255, 0, 0, 0).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isPending ? Colors.white38 :  Color.fromARGB(255, 0, 0, 0), size: 20),
          ),
           SizedBox(width: 16),
          // Title
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isPending ? Colors.white54 :  Color.fromARGB(255, 0, 0, 0),
                fontSize: 15,
                fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          // Status Checkmark (Green if done)
          if (isCompleted)
             Icon(Icons.check_circle_outline, color: Color(0xFF00E676), size: 22)
          else if (isActive)
             SizedBox(
              width: 18, 
              height: 18, 
              child: CircularProgressIndicator(color: Color.fromARGB(255, 0, 0, 0), strokeWidth: 2)
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        // The gorgeous Purple-to-Cyan Gradient
        decoration:  BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 255, 255, 255), // Deep Purple
              Color.fromARGB(255, 255, 255, 255), // Vibrant Cyan/Blue
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                 SizedBox(height: 20),
                
                // --- PULSING BRAIN ICON ---
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulsing ring
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color:  Color.fromARGB(255, 0, 0, 0).withOpacity(0.15), width: 2),
                        ),
                      ),
                    ),
                    // Inner static ring
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color:  Color.fromARGB(255, 0, 0, 0).withOpacity(0.3), width: 1.5),
                      ),
                    ),
                    // Brain Icon
                     Icon(Icons.psychology, size: 50, color: Color(0xFF10B981)),
                  ],
                ),
                 SizedBox(height: 40),

                // --- HEADER TEXT ---
                 Text(
                  "Analyzing your\nbiomarkers...",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0), height: 1.2),
                ),
                 SizedBox(height: 12),
                Text(
                  "Our AI is evaluating your health markers",
                  style: TextStyle(fontSize: 15, color:  Color.fromARGB(255, 0, 0, 0).withOpacity(0.8)),
                ),
                 SizedBox(height: 48),

                // --- STEPS LIST ---
                _buildStepCard(title: "Scanning blood report", icon: Icons.document_scanner_outlined, stepIndex: 0),
                _buildStepCard(title: "Analyzing biomarkers", icon: Icons.show_chart_rounded, stepIndex: 1),
                _buildStepCard(title: "AI health evaluation", icon: Icons.psychology_outlined, stepIndex: 2),
                
                // Show 4th step only if timer reaches it, to match your Figma exactly
                if (_currentStep >= 2) 
                  _buildStepCard(title: "Generating insights", icon: Icons.lightbulb_outline, stepIndex: 3),

                 Spacer(),

                // --- PROGRESS BAR ---
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor:  Color.fromARGB(255, 0, 0, 0).withOpacity(0.2),
                    valueColor:  AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 0, 0, 0)),
                  ),
                ),
                 SizedBox(height: 16),
                Text(
                  "This may take a few seconds...",
                  style: TextStyle(color:  Color.fromARGB(255, 0, 0, 0).withOpacity(0.7), fontSize: 13),
                ),
                 SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}