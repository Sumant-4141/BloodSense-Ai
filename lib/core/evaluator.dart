// ---------------------------------------------------
// Evaluation Engine
// ---------------------------------------------------

Map<String, dynamic> evaluateMarker(
    String marker,
    dynamic value,
    String? gender, // Allowed to be null in case OCR missed it
    List<Map<String, dynamic>> referenceDf) {

  // Ensure marker is lowercase to match the standard names in your CSV ('rbc', 'hemoglobin')
  marker = marker.trim().toLowerCase();

  double numericValue;
  try {
    numericValue = double.parse(value.toString());
  } catch (e) {
    return {
      "marker": marker,
      "status": "Invalid Value",
      "severity": null,
      "low": null,
      "high": null,
      "unit": null
    };
  }

  // Find matching marker row in the reference dataframe
  Map<String, dynamic>? row;
  for (var r in referenceDf) {
    if (r["Marker"].toString().toLowerCase() == marker) {
      row = r;
      break;
    }
  }

  // If the extracted text wasn't in the reference_ranges.csv (like "MR No" or "Dr Name")
  if (row == null) {
    return {
      "marker": marker,
      "status": "No Reference",
      "severity": null,
      "low": null,
      "high": null,
      "unit": null
    };
  }

  double low;
  double high;

  // Default to Male if gender wasn't detected by OCR, or use explicit gender
  String safeGender = (gender ?? "male").toLowerCase();

  try {
    if (safeGender == "male") {
      low = double.parse(row["Male_Low"].toString());
      high = double.parse(row["Male_High"].toString());
    } else {
      low = double.parse(row["Female_Low"].toString());
      high = double.parse(row["Female_High"].toString());
    }
  } catch (e) {
    // Failsafe if the CSV has empty cells for ranges
    return {
      "marker": marker,
      "status": "Missing Range Data",
      "severity": null,
      "low": null,
      "high": null,
      "unit": row["Unit"]
    };
  }

  double rangeWidth = (high != low) ? (high - low) : 1;
  String unit = row["Unit"].toString();

  // -------------------------
  // NORMAL RANGE
  // -------------------------
  if (numericValue >= low && numericValue <= high) {
    return {
      "marker": marker,
      "status": "Normal",
      "severity": "None",
      "low": low,
      "high": high,
      "unit": unit
    };
  }

  // -------------------------
  // LOW RANGE
  // -------------------------
  if (numericValue < low) {
    double deviation = low - numericValue;
    double ratio = deviation / rangeWidth;

    String severity;
    if (ratio < 0.1) {
      severity = "Mild Low";
    } else if (ratio <= 0.25) {
      severity = "Moderate Low";
    } else {
      severity = "Severe Low";
    }

    return {
      "marker": marker,
      "status": "Low",
      "severity": severity,
      "low": low,
      "high": high,
      "unit": unit
    };
  }

  // -------------------------
  // HIGH RANGE
  // -------------------------
  if (numericValue > high) {
    double deviation = numericValue - high;
    double ratio = deviation / rangeWidth;

    String severity;
    if (ratio < 0.1) {
      severity = "Mild High";
    } else if (ratio <= 0.25) {
      severity = "Moderate High";
    } else {
      severity = "Severe High";
    }

    return {
      "marker": marker,
      "status": "High",
      "severity": severity,
      "low": low,
      "high": high,
      "unit": unit
    };
  }

  return {};
}