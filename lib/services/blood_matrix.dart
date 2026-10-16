class BloodMatrix {
  // Map of Patient/Recipient blood group -> List of acceptable Donor blood groups
  static const Map<String, List<String>> _compatibleDonors = {
    'O-': ['O-'],
    'O+': ['O-', 'O+'],
    'A-': ['O-', 'A-'],
    'A+': ['O-', 'O+', 'A-', 'A+'],
    'B-': ['O-', 'B-'],
    'B+': ['O-', 'O+', 'B-', 'B+'],
    'AB-': ['O-', 'A-', 'B-', 'AB-'],
    'AB+': ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'],
  };

  /// Returns true if a donor with `donorGroup` can donate to a patient with `patientGroup`
  static bool isCompatible(String donorGroup, String patientGroup) {
    final compatibleList = _compatibleDonors[patientGroup.toUpperCase().trim()];
    if (compatibleList == null) return false;
    return compatibleList.contains(donorGroup.toUpperCase().trim());
  }

  static List<String> getCompatibleDonorsFor(String patientGroup) {
    return _compatibleDonors[patientGroup.toUpperCase().trim()] ?? [];
  }

  static const List<String> allGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];
}
