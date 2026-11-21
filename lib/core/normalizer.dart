// ---------------------------------------------------
// Normalizer Engine
// ---------------------------------------------------

Map<String, String> buildSynonymMap(List<Map<String, dynamic>> synonymsDf) {
  Map<String, String> synonymMap = {};

  for (var row in synonymsDf) {
    // Standard names from CSV (e.g., 'rbc', 'hemoglobin')
    String standardName = row["Standard_Name"].toString().trim().toLowerCase();
    String synonym = row["Synonym"].toString();

    // 1. Add the exact lowercase synonym
    synonymMap[synonym.trim().toLowerCase()] = standardName;

    // 2. Add an aggressively cleaned version (removes all spaces and symbols)
    // This catches OCR errors like "HAEM O GLOBIN" or "M CH"
    String cleanedSynonym = synonym.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    synonymMap[cleanedSynonym] = standardName;

    // 3. Add the standard name itself to the map just in case the report uses it directly
    synonymMap[standardName] = standardName;
  }

  return synonymMap;
}

String normalizeMarker(String marker, Map<String, String> synonymMap) {
  // Try exact match first
  String keyExact = marker.trim().toLowerCase();
  if (synonymMap.containsKey(keyExact)) {
    return synonymMap[keyExact]!;
  }

  // Try aggressively cleaned match (strips spaces and symbols)
  String keyCleaned = marker.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  if (synonymMap.containsKey(keyCleaned)) {
    return synonymMap[keyCleaned]!;
  }

  // Return the cleaned key as a fallback if not found in CSV
  return keyExact;
}