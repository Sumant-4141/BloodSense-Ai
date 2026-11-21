import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Import your backend logic
import 'core/report_processor.dart';
import 'core/risk_engine.dart';
import 'results_screen.dart';
import 'manual_entry_screen.dart';
import 'loading_screen.dart';

class UploadImageScreen extends StatefulWidget {
   UploadImageScreen({Key? key}) : super(key: key);

  @override
  State<UploadImageScreen> createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  final String _selectedGender = "Male"; 
  final Color _darkNavy =  Color(0xFF0F172A);

  // --- IMAGE PICKING LOGIC ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  // --- AI ANALYSIS LOGIC ---
  Future<void> _analyzeReport() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);
    
    // 1. START THE TIMER
    final startTime = DateTime.now(); 

    try {
      List<Map<String, dynamic>> evaluated = 
          await generateEvaluatedReport([_selectedImage!.path], _selectedGender);

      if (evaluated.isEmpty) {
        setState(() => _isLoading = false);
        _showBlurryImageWarning();
        return; 
      }

      List<Map<String, dynamic>> lifestyleDf = await loadCsvData('assets/lifestyle.csv');
      List<Map<String, dynamic>> risks = detectHealthRisks(evaluated, lifestyleDf);

      // 2. FORCE THE ANIMATION TO FINISH
      // Calculate how fast the AI finished. If it took less than 5 seconds, 
      // wait for the remaining time so the user sees all the UI ticks.
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime.inMilliseconds < 5000) {
        await Future.delayed(Duration(milliseconds: 5000 - elapsedTime.inMilliseconds));
      }

      if (!mounted) return;
      
      Navigator.push( // Keeps the previous screen alive in the background
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            evaluatedMarkers: evaluated,
            healthRisks: risks,
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error analyzing report: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBlurryImageWarning() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title:  Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Extraction Failed", style: TextStyle(color: Colors.red)),
          ],
        ),
        content:  Text(
          "We couldn't detect any valid markers. The image might be blurry, cropped, or poorly lit.\n\nPlease try our Manual Entry version."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _darkNavy, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx); 
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  ManualEntryScreen()));
            },
            child:  Text("Manual Entry"),
          )
        ],
      ),
    );
  }

  // --- UI HELPER: TIPS LIST ---
  Widget _buildTipItem(String text) {
    return Padding(
      padding:  EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
           Icon(Icons.check, color: Color(0xFF10B981), size: 18), 
           SizedBox(width: 8),
          Text(text, style:  TextStyle(color: Color(0xFF334155), fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color(0xFFF8F9FA), 
      body: _isLoading
          ?  AnalysisLoadingScreen() // Takes over the entire screen!
          : Column(
              children: [
                // ==========================================
                // HEADER SECTION
                // ==========================================
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16, 
                    left: 24, 
                    right: 24, 
                    bottom: 24
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.5)),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding:  EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                          child:  Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                        ),
                      ),
                       SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text("Upload Image", style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                           SizedBox(height: 2),
                          Text("Take or upload a photo of your blood report", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // BODY SECTION
                // ==========================================
                Expanded(
                  child: SingleChildScrollView(
                    physics:  BouncingScrollPhysics(),
                    padding:  EdgeInsets.all(24.0),
                    child: _selectedImage == null 
                        ? _buildUploadState() // STATE 1
                        : _buildPreviewState(), // STATE 2
                  ),
                ),
              ],
            ),
    );
  }

  // ==========================================
  // STATE 1: UPLOAD SELECTION UI
  // ==========================================
  Widget _buildUploadState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fine Dashed Upload Box
        CustomPaint(
          painter: FineDashedRectPainter(color:  Color.fromARGB(255, 0, 0, 0)),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 48),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.image_outlined, color:Color(0xFF00846A), size: 32),
                ),
                 SizedBox(height: 16),
                 Text("Upload Blood Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                 SizedBox(height: 6),
                Text("PNG, JPG up to 10MB", style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
              ],
            ),
          ),
        ),
         SizedBox(height: 24),
        
        // Take Photo Button
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.camera),
          icon:  Icon(Icons.camera_alt_outlined, size: 20),
          label:  Text("Take Photo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF00846A),
            foregroundColor: Colors.white,
            minimumSize:  Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
         SizedBox(height: 12),
        
        // Gallery Button
        OutlinedButton.icon(
          onPressed: () => _pickImage(ImageSource.gallery),
          icon: Icon(Icons.upload_outlined, color: _darkNavy, size: 20),
          label: Text("Choose from Gallery", style: TextStyle(color: _darkNavy, fontSize: 16, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize:  Size(double.infinity, 56),
            side: BorderSide(color: _darkNavy, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
         SizedBox(height: 32),

        // Tips Box
        Container(
          padding:  EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text("Tips for Best Results:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
               SizedBox(height: 16),
              _buildTipItem("Ensure good lighting conditions"),
              _buildTipItem("Keep the report flat and straight"),
              _buildTipItem("Capture all values clearly"),
              _buildTipItem("Avoid shadows and glare"),
            ],
          ),
        )
      ],
    );
  }

  // ==========================================
  // STATE 2: IMAGE PREVIEW UI
  // ==========================================
  Widget _buildPreviewState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text("Image Preview", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
         SizedBox(height: 16),
        
        // Image Container
        Container(
          width: double.infinity,
          height: 400, 
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 2),
            image: DecorationImage(
              image: FileImage(_selectedImage!),
              fit: BoxFit.cover, 
            ),
          ),
        ),
         SizedBox(height: 24),

        // Analyze Button
        ElevatedButton(
          onPressed: _analyzeReport,
          style: ElevatedButton.styleFrom(
            backgroundColor:Color(0xFF00846A),
            foregroundColor: Colors.white,
            minimumSize:  Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child:  Text("Analyze Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
         SizedBox(height: 12),

        // Upload Different Image Button
        OutlinedButton(
          onPressed: () {
            // --- THE FIX: Show a native bottom menu to pick Camera or Gallery ---
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              shape:  RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (BuildContext context) {
                return SafeArea(
                  child: Padding(
                    padding:  EdgeInsets.symmetric(vertical: 12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text("Select Image Source", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ListTile(
                          leading:  Icon(Icons.camera_alt_outlined, color: Colors.black87),
                          title:  Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w500)),
                          onTap: () {
                            Navigator.pop(context); // Close the menu
                            _pickImage(ImageSource.camera); // Open Camera
                          },
                        ),
                        ListTile(
                          leading:  Icon(Icons.photo_library_outlined, color: Colors.black87),
                          title:  Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w500)),
                          onTap: () {
                            Navigator.pop(context); // Close the menu
                            _pickImage(ImageSource.gallery); // Open Gallery
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
            );
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize:  Size(double.infinity, 56),
            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text("Upload Different Image", style: TextStyle(color: _darkNavy, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ==========================================
// PERFECT SMALL-DASH CUSTOM PAINTER
// ==========================================
class FineDashedRectPainter extends CustomPainter {
  final Color color;

  FineDashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Defines the rounded rectangle
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height), 
       Radius.circular(16)
    );

    // Creates the path
    final path = Path()..addRRect(rrect);

    // This creates the tiny, tight dashes (e.g., 6 pixels of line, 4 pixels of gap)
     double dashPattern = 6.0;
     double dashGap = 4.0;

    Path dashedPath = Path();
    for (PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < measurePath.length) {
        final double length = draw ? dashPattern : dashGap;
        if (draw) {
          dashedPath.addPath(measurePath.extractPath(distance, distance + length), Offset.zero);
        }
        distance += length;
        draw = !draw;
      }
    }
    
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}