// ---------------------------------------------------
// Risk Engine
// ---------------------------------------------------

List<Map<String, dynamic>> detectHealthRisks(
    List<Map<String, dynamic>> evaluatedMarkers, // Now takes the List from Step 5 directly!
    List<Map<String, dynamic>> lifestyleDf) {

  // Convert the List back into a lowercase Map for easy lookup in your logic
  Map<String, dynamic> evalLower = {};
  for (var evaluation in evaluatedMarkers) {
    String markerName = evaluation["marker"].toString().toLowerCase();
    evalLower[markerName] = evaluation;
  }

  List<Map<String, dynamic>> risks = [];
  Set<String> usedMarkers = {};

  bool isHigh(String marker) {
    return evalLower[marker.toLowerCase()]?["status"]?.toString().toLowerCase() == "high";
  }

  bool isLow(String marker) {
    return evalLower[marker.toLowerCase()]?["status"]?.toString().toLowerCase() == "low";
  }

  // Safe split helper to prevent crashes on empty CSV cells
  List<String> safeSplit(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return [];
    return value.toString().split(";").map((e) => e.trim()).toList();
  }

  Map<String, dynamic>? getLifestyle(String marker, String condition) {
    for (var row in lifestyleDf) {
      if (row["Marker"].toString().toLowerCase() == marker.toLowerCase() &&
          row["Condition"].toString().toLowerCase() == condition.toLowerCase()) {
        return {
          "Foods_to_Add": safeSplit(row["Foods_to_Add"]),
          "Foods_to_Avoid": safeSplit(row["Foods_to_Avoid"]),
          "Exercise_to_Add": safeSplit(row["Exercise_to_Add"]),
          "Exercise_to_Avoid": safeSplit(row["Exercise_to_Avoid"]),
          "Focus": row["Focus"]?.toString() ?? ""
        };
      }
    }
    return null;
  }

  void addRisk(String riskName, List<String> reasons,
      [List<String>? markersInvolved,
      String? markerForLifestyle,
      String? conditionType]) {
        
    bool exists = risks.any((r) => r["risk"] == riskName);

    if (!exists) {
      Map<String, dynamic> entry = {
        "risk": riskName,
        "reasons": reasons
      };

      if (markerForLifestyle != null && conditionType != null) {
        entry["lifestyle"] = getLifestyle(markerForLifestyle, conditionType);
      }

      risks.add(entry);

      if (markersInvolved != null) {
        usedMarkers.addAll(markersInvolved.map((m) => m.toLowerCase()));
      }
    }
  }

  // ===============================
  // 🩸 DIABETES & METABOLIC
  // ===============================

  if (isHigh("glucose_fasting") && isHigh("hba1c")) {
    addRisk("Prediabetes / Diabetes Risk", ["Glucose Fasting High", "HbA1c High"], ["glucose_fasting", "hba1c"], "glucose_fasting", "High");
  }

  if (isHigh("fasting_insulin") || isHigh("homa_ir")) {
    List<String> reasons = [];
    List<String> markers = [];
    if (isHigh("fasting_insulin")) {
      reasons.add("Fasting Insulin High");
      markers.add("fasting_insulin");
    }
    if (isHigh("homa_ir")) {
      reasons.add("HOMA IR High");
      markers.add("homa_ir");
    }
    addRisk("Insulin Resistance", reasons, markers, markers.isNotEmpty ? markers[0] : null, "High");
  }

  if (isHigh("triglycerides") && isLow("hdl")) {
    addRisk("Metabolic Syndrome Pattern", ["Triglycerides High", "HDL Low"], ["triglycerides", "hdl"], "triglycerides", "High");
  }

  if (isHigh("hba1c") && isHigh("post_prandeal_glucose")) {
    addRisk("Poor Glycemic Control", ["HbA1c High", "Post Prandial Glucose High"], ["hba1c", "post_prandeal_glucose"], "hba1c", "High");
  }

  // ===============================
  // ❤️ CARDIOVASCULAR
  // ===============================

  if (isHigh("ldl") || isHigh("apob") || isHigh("lipoprotein_a")) {
    List<String> reasons = [];
    List<String> markers = [];
    if (isHigh("ldl")) {
      reasons.add("LDL High");
      markers.add("ldl");
    }
    if (isHigh("apob")) {
      reasons.add("ApoB High");
      markers.add("apob");
    }
    if (isHigh("lipoprotein_a")) {
      reasons.add("Lipoprotein(a) High");
      markers.add("lipoprotein_a");
    }
    addRisk("Atherosclerosis Risk", reasons, markers, markers.isNotEmpty ? markers[0] : null, "High");
  }

  if (isHigh("hs_crp") && isHigh("ldl")) {
    addRisk("Inflammatory Cardiovascular Risk", ["hs-CRP High", "LDL High"], ["hs_crp", "ldl"], "hs_crp", "High");
  }

  if (isHigh("triglycerides") && isHigh("vldl")) {
    addRisk("Hyperlipidemia", ["Triglycerides High", "VLDL High"], ["triglycerides", "vldl"], "triglycerides", "High");
  }

  // ===============================
  // 🩺 KIDNEY FUNCTION
  // ===============================

  if (isHigh("creatinine") || isHigh("bun") || isLow("egfr")) {
    List<String> reasons = [];
    List<String> markers = [];
    if (isHigh("creatinine")) {
      reasons.add("Creatinine High");
      markers.add("creatinine");
    }
    if (isHigh("bun")) {
      reasons.add("BUN High");
      markers.add("bun");
    }
    if (isLow("egfr")) {
      reasons.add("eGFR Low");
      markers.add("egfr");
    }
    addRisk("Kidney Dysfunction", reasons, markers, markers.isNotEmpty ? markers[0] : null, "High");
  }

  // ===============================
  // 🧪 LIVER FUNCTION
  // ===============================

  if (isHigh("alt") || isHigh("ast")) {
    addRisk("Liver Injury / Hepatic Dysfunction", ["ALT or AST High"], ["alt", "ast"], "alt", "High");
  }

  if (isHigh("alt") && isHigh("triglycerides")) {
    addRisk("Non-Alcoholic Fatty Liver Pattern", ["ALT High", "Triglycerides High"], ["alt", "triglycerides"], "alt", "High");
  }

  if (isHigh("alp") && isHigh("total_bilirubin")) {
    addRisk("Cholestasis Risk", ["ALP High", "Total Bilirubin High"], ["alp", "total_bilirubin"], "alp", "High");
  }

  if (isHigh("ggt") && isHigh("alt")) {
    addRisk("Alcoholic / Toxic Liver Pattern", ["GGT High", "ALT High"], ["ggt", "alt"], "ggt", "High");
  }

  // ===============================
  // 🧠 THYROID
  // ===============================

  if (isHigh("tsh") && isLow("free_t4")) {
    addRisk("Hypothyroidism", ["TSH High", "Free T4 Low"], ["tsh", "free_t4"], "tsh", "High");
  }

  if (isLow("tsh") && isHigh("free_t4")) {
    addRisk("Hyperthyroidism", ["TSH Low", "Free T4 High"], ["tsh", "free_t4"], "free_t4", "High");
  }

  if (isHigh("tpo_antibodies") || isHigh("tg_antibodies")) {
    List<String> reasons = [];
    List<String> markers = [];
    if (isHigh("tpo_antibodies")) {
      reasons.add("TPO Antibodies High");
      markers.add("tpo_antibodies");
    }
    if (isHigh("tg_antibodies")) {
      reasons.add("TG Antibodies High");
      markers.add("tg_antibodies");
    }
    addRisk("Autoimmune Thyroid Disorder", reasons, markers);
  }

  // ===============================
  // 🩸 ANEMIA
  // ===============================

  if (isLow("hemoglobin") || isLow("rbc")) {
    addRisk("Anemia Risk", ["Hemoglobin or RBC Low"], ["hemoglobin", "rbc"], "hemoglobin", "Low");
  }

  if (isLow("ferritin") || isLow("serum_iron")) {
    addRisk("Iron Deficiency", ["Ferritin or Serum Iron Low"], ["ferritin", "serum_iron"], "ferritin", "Low");
  }

  if (isHigh("ferritin") && isHigh("transferrin_saturation")) {
    addRisk("Iron Overload Disorder", ["Ferritin High", "Transferrin Saturation High"], ["ferritin", "transferrin_saturation"], "ferritin", "High");
  }

  // ===============================
  // 🧪 GOUT
  // ===============================

  if (isHigh("uric_acid")) {
    addRisk("Gout Risk", ["Uric Acid High"], ["uric_acid"], "uric_acid", "High");
  }

  // ===============================
  // 🧪 VITAMINS
  // ===============================

  if (isLow("vitamin_d")) {
    addRisk("Vitamin D Deficiency", ["Vitamin D Low"], ["vitamin_d"], "vitamin_d", "Low");
  }

  if (isLow("vitamin_b12")) {
    addRisk("Vitamin B12 Deficiency", ["Vitamin B12 Low"], ["vitamin_b12"], "vitamin_b12", "Low");
  }

  if (isLow("folate")) {
    addRisk("Folate Deficiency", ["Folate Low"], ["folate"], "folate", "Low");
  }

  // =====================================================
  // 🔥 STEP 2 — GENERIC SINGLE MARKERS
  // =====================================================

  evalLower.forEach((marker, data) {
    if (usedMarkers.contains(marker)) return;

    String status = data["status"]?.toString().toLowerCase() ?? "";

    // Safe capitalization to prevent empty string index errors
    String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : "";
    String formattedMarkerName = marker.replaceAll("_", " ").split(" ").map((e) => capitalize(e)).join(" ");

    if (status == "high") {
      addRisk("$formattedMarkerName Elevated", ["$marker High"], [marker], marker, "High");
    } else if (status == "low") {
      addRisk("$formattedMarkerName Deficiency", ["$marker Low"], [marker], marker, "Low");
    }
  });

  return risks;
}