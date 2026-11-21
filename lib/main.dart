import 'package:flutter/material.dart';
import 'manual_entry_screen.dart';
import 'upload_image_screen.dart';
import 'upload_pdf_screen.dart';


void main() {
  runApp( BloodReportApp());
}

class BloodReportApp extends StatelessWidget {
   BloodReportApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloodSense AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white, 
        useMaterial3: true,
      ),
      home:  MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
   MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isLoading = false;
  
  // Custom Dark Navy Color from your Figma
  final Color _darkNavy =  Color(0xFF0F172A);

  // ---------------------------------------------------
  // 1. IMAGE SCANNER
  // ---------------------------------------------------
  



  // ---------------------------------------------------
  // MAIN UI BUILDER
  // ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _darkNavy),
                   SizedBox(height: 24),
                   Text("Analyzing Report...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   SizedBox(height: 8),
                  Text("Extracting text & calculating risks.", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          : SafeArea(
              // ENTIRE SCREEN IS NOW SCROLLABLE
              child: SingleChildScrollView(
                physics:  BouncingScrollPhysics(),
                padding:  EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // --- 1. HEADER ROW ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                              "BloodSense",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color:Color(0xFF00846A)),
                            ),
                            Text(
                              "AI Blood Report Analyzer",
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Container(
                          padding:  EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:Color(0xFF00846A),
                            shape: BoxShape.circle,
                          ),
                          child:  Icon(Icons.person_outline, color: Colors.black87, size: 22),
                        )
                      ],
                    ),
                     SizedBox(height: 32),

                    // --- 2. QUOTE CARD ---
                    Container(
                      width: double.infinity,
                      padding:  EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade400, width: 1.5),
                      ),
                      child: Column(
                        children: [
                           Text(
                            '"Your health is an investment, not\nan expense."',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B), height: 1.4),
                          ),
                           SizedBox(height: 12),
                          Text(
                            "— Take charge of your wellbeing",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                     SizedBox(height: 40),

                    // --- 3. SECTION TITLE ---
                     Text(
                      "Choose Analysis Method",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                     SizedBox(height: 6),
                    Text(
                      "Select how you'd like to analyze your blood\nreport",
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.3),
                    ),
                     SizedBox(height: 24),

                    // --- 4. ACTION CARDS (With Hover Animation) ---
                    HoverableMethodCard(
                      title: "Upload Image",
                      subtitle: "Scan your blood report\nphoto",
                      icon: Icons.camera_alt_outlined,
                      iconColor: Color(0xFF00846A),
                     onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) =>  UploadImageScreen())
                        );
                      },
                    ),
                    HoverableMethodCard(
                      title: "Upload PDF",
                      subtitle: "Import your digital\nreport",
                      icon: Icons.description_outlined,
                      iconColor: Color(0xFF00846A),
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) =>  UploadPdfScreen())
                        );
                      },
                    ),
                    HoverableMethodCard(
                      title: "Manual Entry",
                      subtitle: "Enter values manually",
                      icon: Icons.edit_outlined,
                      iconColor: Color(0xFF00846A),
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) =>  ManualEntryScreen())
                        );
                      },
                    ),
                     SizedBox(height: 32),

                    // --- 5. SECURE FOOTER ---
                    Divider(color:  Color.fromARGB(255, 2, 2, 2), thickness: 1.5),
                     SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding:  EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:  Color.fromARGB(255, 0, 0, 0),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.lock, color: Colors.orange.shade400, size: 24),
                          ),
                           SizedBox(height: 16),
                           Text(
                            "Secure & Private",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                           SizedBox(height: 8),
                          Text(
                            "Your medical data is encrypted and never\nshared. We ensure complete privacy and\nsecurity.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 2),
                          ),
                           SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ==========================================
// CUSTOM WIDGET: INTERACTIVE ACTION CARD (BULLETPROOF MOBILE)
// ==========================================
class HoverableMethodCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

   HoverableMethodCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  }) : super(key: key);

  @override
  State<HoverableMethodCard> createState() => _HoverableMethodCardState();
}

class _HoverableMethodCardState extends State<HoverableMethodCard> {
  bool _isPressed = false; 

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // THIS FIXES THE EMPTY SPACE BUG: Forces the whole card to be tappable
      behavior: HitTestBehavior.opaque, 
      
      onTapDown: (_) {
        setState(() => _isPressed = true); // Instantly turn black
      },
      onTapCancel: () {
        setState(() => _isPressed = false); // User swiped away, turn grey
      },
      onTapUp: (_) {
        setState(() => _isPressed = false); // Finger lifted, turn grey
      },
      onTap: () async {
        // Force the black border to stay for 100ms so the human eye can see it
        // before the app jumps to the camera or PDF picker!
        setState(() => _isPressed = true);
        await Future.delayed( Duration(milliseconds: 50));
        setState(() => _isPressed = false);
        
        widget.onTap(); // Execute the actual button action
      },
      
      // Removed AnimatedContainer. Using standard Container for INSTANT color change.
      child: Container(
        margin:  EdgeInsets.only(bottom: 16),
        padding:  EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // Instantly swaps to black when pressed
            color: _isPressed ?  Color.fromARGB(255, 0, 0, 0) : Colors.grey.shade400,
            width: _isPressed ? 2.5 : 1.5, // Made it slightly thicker on press so it pops
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: widget.iconColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: Colors.white, size: 26),
            ),
             SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                   SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: TextStyle(fontSize: 13, color:  Color.fromARGB(255, 0, 0, 0)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_outlined, color:  Color.fromARGB(255, 0, 0, 0), size: 20),
          ],
        ),
      ),
    );
  }
}