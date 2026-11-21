import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

// Import your backend logic
import 'core/report_processor.dart';
import 'core/risk_engine.dart';
import 'results_screen.dart';
import 'manual_entry_screen.dart';
import 'pdf_handler.dart'; // Ensure your PDF handler is imported
import 'loading_screen.dart';

class UploadPdfScreen extends StatefulWidget {
   UploadPdfScreen({Key? key}) : super(key: key);

  @override
  State<UploadPdfScreen> createState() => _UploadPdfScreenState();
}

class _UploadPdfScreenState extends State<UploadPdfScreen> {
  File? _selectedPdf;
  String? _fileName;
  String? _fileSize;
  
  bool _isLoading = false;
  final String _selectedGender = "Male"; 
  final Color _darkNavy =  Color(0xFF0F172A);

  // --- PDF PICKING LOGIC ---
  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        
        // --- THE FIX: Dynamic File Size Formatting ---
        int bytes = file.lengthSync();
        String formattedSize;
        
        if (bytes < 1024) {
          formattedSize = "$bytes B"; // Bytes
        } else if (bytes < 1024 * 1024) {
          formattedSize = "${(bytes / 1024).toStringAsFixed(2)} KB"; // Kilobytes
        } else {
          formattedSize = "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB"; // Megabytes
        }
        
        setState(() {
          _selectedPdf = file;
          _fileName = result.files.single.name;
          _fileSize = formattedSize; // Now dynamically assigns KB or MB!
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick PDF: $e')),
      );
    }
  }

  // --- AI ANALYSIS LOGIC ---
  Future<void> _analyzePdf() async {
    if (_selectedPdf == null) return;

    setState(() => _isLoading = true);
    final startTime = DateTime.now(); // Start a timer

    try {
      List<String>? imagePaths = await convertExistingPdfToImages(_selectedPdf!.path); 

      if (imagePaths == null || imagePaths.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      List<Map<String, dynamic>> evaluated = 
          await generateEvaluatedReport(imagePaths, _selectedGender);

      if (evaluated.isEmpty) {
        setState(() => _isLoading = false);
        _showExtractionWarning();
        return; 
      }

      List<Map<String, dynamic>> lifestyleDf = await loadCsvData('assets/lifestyle.csv');
      List<Map<String, dynamic>> risks = detectHealthRisks(evaluated, lifestyleDf);

      // --- THE FIX: Force the animation to finish ---
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime.inMilliseconds < 5000) {
        await Future.delayed(Duration(milliseconds: 5000 - elapsedTime.inMilliseconds));
      }

      if (!mounted) return;
      
      Navigator.push(
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
        SnackBar(content: Text("Error analyzing PDF: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showExtractionWarning() {
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
          "We couldn't detect any valid markers in this PDF. It might be scanned poorly or use an unsupported format.\n\nPlease try our Manual Entry version."
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
  Widget _buildFormatItem(String text) {
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
      backgroundColor:  Color(0xFFF8F9FA), // Subtle off-white body background
      // THE FIX: Move the loading check to the very top!
      body: _isLoading
          ?  AnalysisLoadingScreen() // Takes over the entire screen, hiding the header
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
                  decoration:  BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color.fromARGB(255, 91, 89, 89), width: 2)),
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
                           Text("Upload PDF", style: TextStyle(color: Color(0xFF00846A), fontSize: 25, fontWeight: FontWeight.bold)),
                           SizedBox(height: 2),
                          Text("Upload your digital blood report", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
                    child: _selectedPdf == null 
                        ? _buildUploadState() // STATE 1
                        : _buildSelectedState(), // STATE 2
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
            padding:  EdgeInsets.symmetric(vertical: 48),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Container(
                  padding:  EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.description_outlined, color:Color(0xFF00846A), size: 32),
                ),
                 SizedBox(height: 16),
                 Text("Upload Blood Report PDF", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                 SizedBox(height: 6),
                Text("PDF up to 10MB", style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
              ],
            ),
          ),
        ),
         SizedBox(height: 24),
        
        // Choose PDF Button
        ElevatedButton.icon(
          onPressed: _pickPdf,
          icon:  Icon(Icons.upload_outlined, size: 20),
          label:  Text("Choose PDF File", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF00846A),
            foregroundColor: Colors.white,
            minimumSize:  Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
         SizedBox(height: 32),

        // Formats Box
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
               Text("Supported Formats:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
               SizedBox(height: 16),
              _buildFormatItem("PDF files from medical labs"),
              _buildFormatItem("Digital blood test reports"),
              _buildFormatItem("Scanned documents (PDF)"),
              _buildFormatItem("Maximum file size: 10MB"),
            ],
          ),
        )
      ],
    );
  }

  // ==========================================
  // STATE 2: PDF SELECTED UI
  // ==========================================
  Widget _buildSelectedState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text("Selected File", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
         SizedBox(height: 12),
        
        // Selected File Card
        Container(
          padding:  EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding:  EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _darkNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:  Icon(Icons.description_outlined, color: Colors.white, size: 24),
              ),
               SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName ?? "document.pdf",
                      style:  TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                     SizedBox(height: 4),
                    Text(
                      _fileSize ?? "Unknown Size",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
               Icon(Icons.check_circle_outline, color: Color(0xFF00846A), size: 24),
            ],
          ),
        ),
         SizedBox(height: 32),

        // Analyze Button
        ElevatedButton(
          onPressed: _analyzePdf,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF00846A),
            foregroundColor: Colors.white,
            minimumSize:  Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child:  Text("Analyze PDF", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
         SizedBox(height: 12),

        // Upload Different File Button
        OutlinedButton.icon(
          onPressed: _pickPdf,
          icon: Icon(Icons.upload_outlined, color:Color(0xFF00846A), size: 20),
          label: Text("Upload Different File", style: TextStyle(color: Color(0xFF00846A), fontSize: 16, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize:  Size(double.infinity, 56),
            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// PERFECT SMALL-DASH CUSTOM PAINTER (Reused)
// ==========================================
class FineDashedRectPainter extends CustomPainter {
  final Color color;

  FineDashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height), 
       Radius.circular(16)
    );

    final path = Path()..addRRect(rrect);

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