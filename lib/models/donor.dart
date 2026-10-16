class DonationRecord {
  final String id;
  final String hospitalName;
  final String patientName;
  final String bloodGroup;
  final int units;
  final DateTime donatedAt;
  final String verificationOtp;

  DonationRecord({
    required this.id,
    required this.hospitalName,
    required this.patientName,
    required this.bloodGroup,
    required this.units,
    required this.donatedAt,
    required this.verificationOtp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'hospitalName': hospitalName,
    'patientName': patientName,
    'bloodGroup': bloodGroup,
    'units': units,
    'donatedAt': donatedAt.toIso8601String(),
    'verificationOtp': verificationOtp,
  };

  factory DonationRecord.fromJson(Map<String, dynamic> json) => DonationRecord(
    id: json['id'] as String,
    hospitalName: json['hospitalName'] as String,
    patientName: json['patientName'] as String,
    bloodGroup: json['bloodGroup'] as String,
    units: (json['units'] as num).toInt(),
    donatedAt: DateTime.parse(json['donatedAt'] as String),
    verificationOtp: (json['verificationOtp'] as String?) ?? '0000',
  );
}

class Donor {
  final String id;
  final String name;
  final String phone;
  final String bloodGroup; // 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  final double latitude;
  final double longitude;
  final DateTime lastDonationDate;
  final bool isAvailable;
  final List<DonationRecord> donationHistory;

  Donor({
    required this.id,
    required this.name,
    required this.phone,
    required this.bloodGroup,
    required this.latitude,
    required this.longitude,
    required this.lastDonationDate,
    this.isAvailable = true,
    this.donationHistory = const [],
  });

  /// Medical 90-day safety cooldown check
  bool get isMedicallyEligible {
    final daysSinceDonation = DateTime.now().difference(lastDonationDate).inDays;
    return daysSinceDonation >= 90;
  }

  int get daysUntilEligible {
    final daysSinceDonation = DateTime.now().difference(lastDonationDate).inDays;
    if (daysSinceDonation >= 90) return 0;
    return 90 - daysSinceDonation;
  }

  Donor copyWith({
    String? id,
    String? name,
    String? phone,
    String? bloodGroup,
    double? latitude,
    double? longitude,
    DateTime? lastDonationDate,
    bool? isAvailable,
    List<DonationRecord>? donationHistory,
  }) {
    return Donor(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      isAvailable: isAvailable ?? this.isAvailable,
      donationHistory: donationHistory ?? this.donationHistory,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'bloodGroup': bloodGroup,
    'latitude': latitude,
    'longitude': longitude,
    'lastDonationDate': lastDonationDate.toIso8601String(),
    'isAvailable': isAvailable,
    'donationHistory': donationHistory.map((d) => d.toJson()).toList(),
  };

  factory Donor.fromJson(Map<String, dynamic> json) => Donor(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    bloodGroup: json['bloodGroup'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    lastDonationDate: DateTime.parse(json['lastDonationDate'] as String),
    isAvailable: json['isAvailable'] as bool? ?? true,
    donationHistory: (json['donationHistory'] as List<dynamic>?)
            ?.map((e) => DonationRecord.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}
