import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

// ---------------------------------------------------
// Pick Image From Gallery
// ---------------------------------------------------

Future<String?> pickReportImage() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    return image.path;
  }
  return null;
}

// ---------------------------------------------------
// Extract Lab Values Using Bounding Box Row Reconstruction
// ---------------------------------------------------

Future<Map<String, dynamic>> extractLabValuesFromImage(String imagePath) async {
  final textRecognizer = TextRecognizer();
  final inputImage = InputImage.fromFilePath(imagePath);
  
  // Get the full structured recognized text, not just the raw string
  final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
  await textRecognizer.close();

  return processTextByBoundingBox(recognizedText);
}

// ---------------------------------------------------
// Process Table Logic
// ---------------------------------------------------

Map<String, dynamic> processTextByBoundingBox(RecognizedText recognizedText) {
  Map<String, dynamic> labValues = {};
  
  // --- 1. GENDER DETECTION ---
  String fullTextLower = recognizedText.text.toLowerCase();
  // Changed "female" to "fema" to catch OCR typos like "Fema ke"
  if (fullTextLower.contains("fema") || fullTextLower.contains("mrs.") || fullTextLower.contains(" f ")) {
    labValues["Gender"] = "Female";
  } else if (fullTextLower.contains("male") || fullTextLower.contains("mr.") || fullTextLower.contains(" m ")) {
    labValues["Gender"] = "Male";
  } else {
    labValues["Gender"] = "Male"; // Default fallback
  }

  List<TextLine> allLines = [];

  // 1. Gather all individual text snippets with their screen coordinates
  for (TextBlock block in recognizedText.blocks) {
    for (TextLine line in block.lines) {
      allLines.add(line);
    }
  }

  // 2. Sort all lines vertically (top to bottom) based on their Y coordinate
  allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

  // 3. Group lines into horizontal "Rows"
  List<List<TextLine>> rows = [];
  for (TextLine line in allLines) {
    bool addedToRow = false;
    for (List<TextLine> row in rows) {
      // Calculate the vertical center of the existing row and the new line
      double rowCenterY = row.first.boundingBox.top + (row.first.boundingBox.height / 2);
      double lineCenterY = line.boundingBox.top + (line.boundingBox.height / 2);

      // If they are within 15 pixels of each other vertically, they belong to the same row
      if ((rowCenterY - lineCenterY).abs() < 15) {
        row.add(line);
        addedToRow = true;
        break;
      }
    }
    // If it didn't fit into an existing row, create a new row
    if (!addedToRow) {
      rows.add([line]);
    }
  }

  print("--- START TABLE ROW DEBUG ---");

  // 4. Process each reconstructed row from left-to-right
  for (List<TextLine> row in rows) {
    // Sort items in the row horizontally (left to right by X coordinate)
    row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

    // Print the reconstructed row so you can see the magic happening!
    String rowText = row.map((e) => e.text).join("  |  ");
    print("Reconstructed Row: $rowText");

    String? markerName;
    double? numericValue;
    String rowFullText = row.map((e) => e.text).join(" ").toLowerCase();

    for (TextLine item in row) {
      String text = item.text.trim();
      String lowerText = text.toLowerCase();

      // Skip common header words
      if (lowerText.contains("date") || lowerText.contains("time") || lowerText.contains("patient")) {
        continue;
      }

      // --- 2. THE COMMA BUG FIX (e.g., "7,400" -> "7400") ---
      String cleanForNumber = text.replaceAll(RegExp(r',(?=\d{3})'), '');
      
      // Replace remaining spaces or rogue commas with dots for actual decimals
      cleanForNumber = cleanForNumber.replaceAll(' ', '.').replaceAll(',', '.');
      double? parsedNum = double.tryParse(cleanForNumber);

      if (parsedNum != null) {
        // Grab the FIRST number we see from left to right (this is usually the patient result, ignoring ref ranges)
        numericValue ??= parsedNum; 
      } else {
        // If it's not a number, and it contains letters, treat it as the marker name
        if (markerName == null && text.length > 2 && text.contains(RegExp(r'[a-zA-Z]'))) {
          // Clean up OCR artifacts like the '|' symbol seen in your logs
          markerName = text.replaceAll('|', '').trim();
        }
      }
    }

    // If we successfully found both a name and a number on the same row, save it!
    if (markerName != null && numericValue != null) {
      
      // --- NEW: SMART UNIT SCALING (10^3) ---
      // If the report uses 10^3 or 10*3 (thousands), multiply the number!
      if (rowFullText.contains("10^3") || rowFullText.contains("10*3") || rowFullText.contains("10 3")) {
        numericValue = numericValue! * 1000;
      }

      // --- 3. SMART UNIT DETECTION ---
      // If the row contains "cells" or "#" or "absolute", it is an absolute count!
      if (rowFullText.contains("cells") || rowFullText.contains("cu.mm") || rowFullText.contains("absolute") || markerName.contains("#")) {
        if (!markerName.toLowerCase().contains("absolute")) {
           markerName = "${markerName}_absolute";
        }
      }

      // Prevent overwriting
      if (labValues.containsKey(markerName)) {
        String newKey = "${markerName}_absolute";
        labValues[newKey] = numericValue;
        print("✅ EXTRACTED: $newKey = $numericValue");
      } else {
        labValues[markerName] = numericValue;
        print("✅ EXTRACTED: $markerName = $numericValue");
      }
    }
  }

  print("--- END TABLE ROW DEBUG ---");
  return labValues;
}