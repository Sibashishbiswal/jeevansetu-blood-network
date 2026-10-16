enum TicketStatus {
  pending,
  accepted,
  enRoute,
  fulfilled,
  cancelled,
}

class SosTicket {
  final String id;
  final String patientName;
  final String bloodGroup;
  final int unitsRequired;
  int unitsFulfilled;
  final String hospitalName;
  final String hospitalAddress;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  double radiusKm;
  TicketStatus status;
  String? acceptedDonorName;
  String? acceptedDonorPhone;

  SosTicket({
    required this.id,
    required this.patientName,
    required this.bloodGroup,
    required this.unitsRequired,
    this.unitsFulfilled = 0,
    required this.hospitalName,
    required this.hospitalAddress,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.radiusKm = 5.0,
    this.status = TicketStatus.pending,
    this.acceptedDonorName,
    this.acceptedDonorPhone,
  });

  bool get isLocked => unitsFulfilled >= unitsRequired || status == TicketStatus.fulfilled;
}
