class VersionComparison {
  // Clean version string by removing any non-numeric characters except dots
  static String _cleanVersionString(String version) {
    // Remove any characters that aren't numbers or dots
    // Also handles cases where version might have prefixes like 'v1.0.0' or suffixes
    return version.replaceAll(RegExp(r'[^0-9.]'), '');
  }

  // Parse version string into list of integers
  static List<int> _parseVersion(String version) {
    try {
      String cleanVersion = _cleanVersionString(version);
      return cleanVersion
          .split('.')
          .map((part) => int.tryParse(part) ?? 0)
          .toList();
    } catch (e) {
      print('Error parsing version: $version');
      return [0, 0, 0]; // Return default version if parsing fails
    }
  }

  // Normalize version lists to same length
  static void _normalizeVersionLists(List<int> list1, List<int> list2) {
    int maxLength = list1.length > list2.length ? list1.length : list2.length;
    
    // Pad shorter list with zeros
    while (list1.length < maxLength) list1.add(0);
    while (list2.length < maxLength) list2.add(0);
  }

  // Main version comparison method
  static bool isUpdateRequired(String currentVersion, String newVersion) {
    try {
      // Parse both versions
      List<int> current = _parseVersion(currentVersion);
      List<int> latest = _parseVersion(newVersion);

      // Normalize to same length
      _normalizeVersionLists(current, latest);

      // Compare version numbers
      for (int i = 0; i < current.length; i++) {
        if (latest[i] > current[i]) return true;
        if (latest[i] < current[i]) return false;
      }
      
      return false; // Versions are equal
    } catch (e) {
      print('Version comparison error: $e');
      return false; // In case of error, don't require update
    }
  }

  // Version compatibility check
  static bool isVersionCompatible(String currentVersion, String minRequired) {
    try {
      // Parse both versions
      List<int> current = _parseVersion(currentVersion);
      List<int> minimum = _parseVersion(minRequired);

      // Normalize to same length
      _normalizeVersionLists(current, minimum);

      // Compare version numbers
      for (int i = 0; i < current.length; i++) {
        if (current[i] < minimum[i]) return false;
        if (current[i] > minimum[i]) return true;
      }
      
      return true; // Versions are equal
    } catch (e) {
      print('Version compatibility check error: $e');
      return false; // In case of error, assume incompatible
    }
  }
}