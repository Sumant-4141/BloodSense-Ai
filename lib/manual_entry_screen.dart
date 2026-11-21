import 'dart:async';
import 'package:flutter/material.dart';
import 'core/report_processor.dart';
import 'core/risk_engine.dart';
import 'results_screen.dart';

class ManualEntryScreen extends StatefulWidget {
   ManualEntryScreen({Key? key}) : super(key: key);

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  // Logic State
  List<Map<String, String>> _allMarkers = [];
  List<Map<String, String>> _filteredMarkers = [];
  final Set<String> _selectedMarkers = {};
  final Map<String, TextEditingController> _controllers = {};
  
  String _searchQuery = "";
  String _selectedGender = "Male"; 
  bool _isLoading = false;

  // UI State: 1 = Selection Phase, 2 = Entry Phase
  int _currentStep = 1; 
  final Color _darkNavy =  Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _loadAvailableMarkers();
  }

  // --- LOGIC: LOAD MARKERS ---
  Future<void> _loadAvailableMarkers() async {
    List<Map<String, dynamic>> referenceDf = await loadCsvData('assets/reference_ranges.csv');
    
    setState(() {
      List<Map<String, String>> temp = [];
      for (var e in referenceDf) {
        String marker = e["Marker"]?.toString() ?? "";
        String unit = e["Unit"]?.toString() ?? ""; 
        
        if (marker.isNotEmpty) {
          marker = marker[0].toUpperCase() + marker.substring(1);
          temp.add({"name": marker, "unit": unit});
        }
      }
      _allMarkers = temp;
      _filteredMarkers = List.from(_allMarkers);
    });
  }

  // --- LOGIC: FILTER & TOGGLE ---
  void _filterMarkers(String query) {
    setState(() {
      _searchQuery = query;
      _filteredMarkers = _allMarkers
          .where((m) => m["name"]!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleMarker(String markerName, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedMarkers.add(markerName);
        _controllers[markerName] = TextEditingController();
      } else {
        _selectedMarkers.remove(markerName);
        _controllers[markerName]?.dispose();
        _controllers.remove(markerName);
      }
    });
  }

  // --- LOGIC: ANALYZE ---
  Future<void> _analyzeManualData() async {
    Map<String, dynamic> manualData = {};
    
    for (String marker in _selectedMarkers) {
      String valueText = _controllers[marker]?.text ?? "";
      double? numericValue = double.tryParse(valueText);
      if (numericValue != null) {
        manualData[marker] = numericValue;
      }
    }

    if (manualData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid numbers for the selected markers."))
      );
      return;
    }

    setState(() => _isLoading = true);
    // 2. THE MAGIC FIX: Force the CPU to wait 100 milliseconds so Flutter has time to actually draw the animation!
    await Future.delayed(const Duration(milliseconds: 100)); 

    final startTime = DateTime.now(); 

    try {
      // 3. NOW run the heavy math
      List<Map<String, dynamic>> evaluated = await processManualData(manualData, _selectedGender);
      List<Map<String, dynamic>> lifestyleDf = await loadCsvData('assets/lifestyle.csv');
      List<Map<String, dynamic>> risks = detectHealthRisks(evaluated, lifestyleDf);

      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime.inMilliseconds < 5000) {
        await Future.delayed(Duration(milliseconds: 5000 - elapsedTime.inMilliseconds));
      }

      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => ResultsScreen(evaluatedMarkers: evaluated, healthRisks: risks)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ==========================================
  // UI HELPER: GET ICON FOR MARKER
  // ==========================================
  IconData _getIconForMarker(String name) {
    String lower = name.toLowerCase();
    if (lower.contains("hemoglobin") || lower.contains("platelet") || lower.contains("rbc") || lower.contains("wbc") || lower.contains("blood")) {
      return Icons.water_drop_outlined;
    } else if (lower.contains("glucose") || lower.contains("vitamin") || lower.contains("energy")) {
      return Icons.bolt_outlined;
    } else if (lower.contains("cholesterol") || lower.contains("hdl") || lower.contains("ldl") || lower.contains("lipid")) {
      return Icons.favorite_border_outlined;
    } else {
      return Icons.show_chart_outlined;
    }
  }

  // ==========================================
  // MAIN UI BUILDER
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color(0xFFF8F9FA),
      body: Column(
        children: [
          // --- 1. HEADER & PROGRESS BAR ---
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16, 
              left: 20, 
              right: 20, 
              bottom: 0
            ),
            decoration:  BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (_currentStep == 2) {
                          setState(() => _currentStep = 1);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding:  EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child:  Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                      ),
                    ),
                     SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text("Manual Entry", style: TextStyle(color: Color(0xFF00846A), fontSize: 20, fontWeight: FontWeight.bold, height: 1.1)),
                           SizedBox(height: 2),
                          Text(
                            _currentStep == 1 ? "Select blood markers to test" : "Enter values (${_selectedMarkers.length} selected)", 
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                 SizedBox(height: 16),
                
                // Progress Bar
                Row(
                  children: [
                    Expanded(child: Container(height: 4, color:Color(0xFF00846A))),
                     SizedBox(width: 8),
                    Expanded(child: Container(height: 3, color: _currentStep == 2 ? Color(0xFF00846A) : Colors.grey.shade300)),
                  ],
                ),
                 SizedBox(height: 16),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.shade200),

          // --- 2. DYNAMIC BODY ---
          Expanded(
            child: _currentStep == 1 ? _buildSelectionStep() : _buildEntryStep(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 1: SELECTION UI
  // ==========================================
  Widget _buildSelectionStep() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding:  EdgeInsets.all(24),
            physics:  BouncingScrollPhysics(),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding:  EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Color(0xFF00846A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          borderRadius: BorderRadius.circular(20),
                          dropdownColor: Colors.black,
                          value: _selectedGender,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down, color:  Colors.white),
                          items: ['Male', 'Female'].map((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text("Gender: $value", style:  TextStyle(fontSize: 14, color: Colors.white),));
                          }).toList(),
                          onChanged: (String? newValue) => setState(() => _selectedGender = newValue!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
               SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: "Search biomarkers...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:  EdgeInsets.symmetric(vertical: 0),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _darkNavy)),
                ),
                onChanged: _filterMarkers,
              ),
               SizedBox(height: 24),
              Text("Tap to select the markers from your blood report", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
               SizedBox(height: 16),
              
              ..._filteredMarkers.map((markerData) {
                String name = markerData["name"]!;
                String unit = markerData["unit"]!;
                bool isSelected = _selectedMarkers.contains(name);
                
                return GestureDetector(
                  onTap: () => _toggleMarker(name, !isSelected),
                  child: AnimatedContainer(
                    duration:  Duration(milliseconds: 200),
                    margin:  EdgeInsets.only(bottom: 12),
                    padding:  EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? Color(0xFF00846A): Colors.grey.shade300, width: isSelected ? 2 : 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? Color(0xFF00846A) : Colors.grey.shade300,
                          size: 24,
                        ),
                         SizedBox(width: 16),
                        Container(
                          padding:  EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFF00846A) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_getIconForMarker(name), color: isSelected ? Colors.white : Colors.grey.shade500, size: 20),
                        ),
                         SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.black87)),
                              if (unit.isNotEmpty) Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        
        Container(
          padding:  EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: Column(
            children: [
              if (_selectedMarkers.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding:  EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin:  EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color:Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    "${_selectedMarkers.length} marker${_selectedMarkers.length > 1 ? 's' : ''} selected",
                    style:  TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.bold, fontSize: 14), 
                  ),
                ),
              ElevatedButton(
                onPressed: _selectedMarkers.isEmpty ? null : () {
                  setState(() => _currentStep = 2);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00846A),
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  minimumSize:  Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child:  Text("Continue to Entry", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        )
      ],
    );
  }

  // ==========================================
  // STEP 2: DATA ENTRY UI
  // ==========================================
  Widget _buildEntryStep() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding:  EdgeInsets.all(24),
            physics:  BouncingScrollPhysics(),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _currentStep = 1),
                  icon:  Icon(Icons.remove, size: 16, color: Color(0xFF0F172A)),
                  label:  Text("Modify selection", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                ),
              ),
               SizedBox(height: 16),
              
              ..._selectedMarkers.map((markerName) {
                String unit = _allMarkers.firstWhere((m) => m["name"] == markerName, orElse: () => {"unit": ""})["unit"]!;
                
                return Container(
                  margin:  EdgeInsets.only(bottom: 16),
                  padding:  EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding:  EdgeInsets.all(8),
                            decoration: BoxDecoration(color:Color(0xFF00846A), borderRadius: BorderRadius.circular(10)),
                            child: Icon(_getIconForMarker(markerName), color: Colors.white, size: 18),
                          ),
                           SizedBox(width: 12),
                          Text(markerName, style:  TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                       SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controllers[markerName],
                              keyboardType:  TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: "Enter value",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                contentPadding:  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _darkNavy)),
                                
                                // NEW: Integrated custom animated step controls
                                suffixIcon: _StepperControls(controller: _controllers[markerName]!),
                              ),
                            ),
                          ),
                          if (unit.isNotEmpty) ...[
                             SizedBox(width: 12),
                            SizedBox(
                              width: 40,
                              child: Text(unit, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                            )
                          ]
                        ],
                      )
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        
        Container(
          padding:  EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _analyzeManualData,
            style: ElevatedButton.styleFrom(
              backgroundColor:Color(0xFF00846A),
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              minimumSize:  Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
              ?  SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              :  Text("Analyze Blood Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }
}

// ==========================================
// NEW CUSTOM WIDGET: STEPPER CONTROLS
// ==========================================
class _StepperControls extends StatefulWidget {
  final TextEditingController controller;

   _StepperControls({Key? key, required this.controller}) : super(key: key);

  @override
  __StepperControlsState createState() => __StepperControlsState();
}

class __StepperControlsState extends State<_StepperControls> {
  Timer? _timer;
  double _step = 0.01;
  int _ticks = 0;

  void _changeValue(bool increment) {
    // Parse current value, default to 0.0 if empty
    double current = double.tryParse(widget.controller.text) ?? 0.0;
    
    // Add or subtract
    current += increment ? _step : -_step;
    
    // Prevent negative numbers
    if (current < 0) current = 0;

    // Clean up the formatting (removes trailing zeros if it's a whole number)
    String formatted = current.toStringAsFixed(2);
    if (formatted.endsWith(".00")) {
      formatted = formatted.substring(0, formatted.length - 3);
    } else if (formatted.endsWith("0")) {
      formatted = formatted.substring(0, formatted.length - 1);
    }

    // Apply the new text and move the cursor back to the end
    widget.controller.text = formatted;
    widget.controller.selection = TextSelection.fromPosition(TextPosition(offset: formatted.length));
  }

  void _startHold(bool increment) {
    // Cancel any existing timer just in case
    _stopHold(); 
    
    _ticks = 0;
    _step = 0.01; // Start slowly at 0.01
    
    _changeValue(increment); // Immediate trigger on the first tap

    // Setup repeating timer for when the button is held down
    _timer = Timer.periodic( Duration(milliseconds: 100), (timer) {
      _ticks++;
      
      // Accelerate the step amount the longer they hold it
      if (_ticks > 25) {
        _step = 10.0; // Super fast
      } else if (_ticks > 15) {
        _step = 1.0;  // Fast
      } else if (_ticks > 5) {
        _step = 0.1;  // Medium
      }
      
      _changeValue(increment);
    });
  }

  void _stopHold() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Up Arrow (Using Listener to bypass ScrollView cancellation)
        Listener(
          onPointerDown: (_) => _startHold(true),
          onPointerUp: (_) => _stopHold(),
          onPointerCancel: (_) => _stopHold(),
          child: Container(
            color: Colors.transparent, // Ensures the whole area is tappable
            padding:  EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
            child:  Icon(Icons.arrow_drop_up, size: 24, color: Color(0xFF0F172A)),
          ),
        ),
        // Down Arrow (Using Listener)
        Listener(
          onPointerDown: (_) => _startHold(false),
          onPointerUp: (_) => _stopHold(),
          onPointerCancel: (_) => _stopHold(),
          child: Container(
            color: Colors.transparent,
            padding:  EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
            child:  Icon(Icons.arrow_drop_down, size: 24, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}