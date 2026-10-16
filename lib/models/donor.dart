class Donor {
  final String id;
  final String name;
  final String phone;
  final String bloodGroup; // 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  final double latitude;
  final double longitude;
  final DateTime lastDonationDate;
  final bool isAvailable;

  Donor({
    required this.id,
    required this.name,
    required this.phone,
    required this.bloodGroup,
    required this.latitude,
    required this.longitude,
    required this.lastDonationDate,
    this.isAvailable = true,
  });

  // Medical 90-day safety cooldown check
  bool get isMedicallyEligible {
    final daysSinceDonation = DateTime.now().difference(lastDonationDate).inDays;
    return daysSinceDonation >= 90;
  }

  int get daysUntilEligible {
    final daysSinceDonation = DateTime.now().difference(lastDonationDate).inDays;
    if (daysSinceDonation >= 90) return 0;
    return 90 - daysSinceDonation;
  }
}
