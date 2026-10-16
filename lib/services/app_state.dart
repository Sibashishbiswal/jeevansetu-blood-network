import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/donor.dart';
import '../models/sos_ticket.dart';
import 'blood_matrix.dart';
import 'geo_service.dart';

enum UserRole { donor, hospital }

class AppState extends ChangeNotifier {
  final Uuid _uuid = const Uuid();

  // Active User Profile (Default: O- Universal Donor)
  Donor currentUser = Donor(
    id: 'user-001',
    name: 'Sibananda (You)',
    phone: '+91 98765 43210',
    bloodGroup: 'O-',
    latitude: 28.6139,
    longitude: 77.2090,
    lastDonationDate: DateTime.now().subtract(const Duration(days: 105)), // Eligible!
    isAvailable: true,
  );

  UserRole currentRole = UserRole.donor;
  LatLng currentLocation = const LatLng(28.6139, 77.2090);
  bool isLoadingLocation = true;

  // Active SOS Emergency Tickets
  final List<SosTicket> _tickets = [];
  List<SosTicket> get tickets => List.unmodifiable(_tickets);

  // Simulated Nearby Donors in the Network
  final List<Donor> _networkDonors = [];
  List<Donor> get networkDonors => List.unmodifiable(_networkDonors);

  AppState() {
    _initSampleData();
    refreshLocation();
  }

  void _initSampleData() {
    // 2 Initial Realistic Emergency Tickets in Delhi NCR
    _tickets.addAll([
      SosTicket(
        id: _uuid.v4(),
        patientName: 'Aarav Sharma (Accident ICU)',
        bloodGroup: 'O-',
        unitsRequired: 2,
        unitsFulfilled: 0,
        hospitalName: 'AIIMS Trauma Center',
        hospitalAddress: 'Ring Road, Safdarjung Enclave, New Delhi',
        latitude: 28.5672,
        longitude: 77.2100,
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
        radiusKm: 7.5,
        status: TicketStatus.pending,
      ),
      SosTicket(
        id: _uuid.v4(),
        patientName: 'Pooja Verma (Postpartum Surgery)',
        bloodGroup: 'B+',
        unitsRequired: 1,
        unitsFulfilled: 0,
        hospitalName: 'Max Super Speciality Hospital',
        hospitalAddress: 'Press Enclave Marg, Saket, New Delhi',
        latitude: 28.5284,
        longitude: 77.2185,
        createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
        radiusKm: 10.0,
        status: TicketStatus.pending,
      ),
    ]);

    // Simulated community donors scattered within 1-6 km radius
    _networkDonors.addAll([
      Donor(
        id: 'd-1',
        name: 'Rahul Verma',
        phone: '+91 98111 22334',
        bloodGroup: 'O-',
        latitude: 28.6010,
        longitude: 77.2150,
        lastDonationDate: DateTime.now().subtract(const Duration(days: 120)),
      ),
      Donor(
        id: 'd-2',
        name: 'Priya Singh',
        phone: '+91 98222 33445',
        bloodGroup: 'B+',
        latitude: 28.6250,
        longitude: 77.1980,
        lastDonationDate: DateTime.now().subtract(const Duration(days: 95)),
      ),
      Donor(
        id: 'd-3',
        name: 'Amit Patel',
        phone: '+91 98333 44556',
        bloodGroup: 'A+',
        latitude: 28.5900,
        longitude: 77.2300,
        lastDonationDate: DateTime.now().subtract(const Duration(days: 45)), // In cooldown!
      ),
      Donor(
        id: 'd-4',
        name: 'Dr. Neha Gupta',
        phone: '+91 98444 55667',
        bloodGroup: 'AB+',
        latitude: 28.6300,
        longitude: 77.2200,
        lastDonationDate: DateTime.now().subtract(const Duration(days: 140)),
      ),
    ]);
  }

  Future<void> refreshLocation() async {
    isLoadingLocation = true;
    notifyListeners();

    currentLocation = await GeoService.getCurrentLocationOrDefault();
    currentUser = Donor(
      id: currentUser.id,
      name: currentUser.name,
      phone: currentUser.phone,
      bloodGroup: currentUser.bloodGroup,
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
      lastDonationDate: currentUser.lastDonationDate,
      isAvailable: currentUser.isAvailable,
    );

    isLoadingLocation = false;
    notifyListeners();
  }

  void toggleRole() {
    currentRole = currentRole == UserRole.donor ? UserRole.hospital : UserRole.donor;
    notifyListeners();
  }

  void updateDonorBloodGroup(String newGroup) {
    currentUser = Donor(
      id: currentUser.id,
      name: currentUser.name,
      phone: currentUser.phone,
      bloodGroup: newGroup,
      latitude: currentUser.latitude,
      longitude: currentUser.longitude,
      lastDonationDate: currentUser.lastDonationDate,
      isAvailable: currentUser.isAvailable,
    );
    notifyListeners();
  }

  // Create an Emergency SOS Ticket (Hospital Authority Action)
  void createSosTicket({
    required String patientName,
    required String bloodGroup,
    required int unitsRequired,
    required String hospitalName,
    required String hospitalAddress,
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) {
    final newTicket = SosTicket(
      id: _uuid.v4(),
      patientName: patientName,
      bloodGroup: bloodGroup,
      unitsRequired: unitsRequired,
      hospitalName: hospitalName,
      hospitalAddress: hospitalAddress,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
      radiusKm: radiusKm,
      status: TicketStatus.pending,
    );

    _tickets.insert(0, newTicket);
    notifyListeners();
  }

  // Donor accepts an emergency request
  bool acceptTicket(String ticketId) {
    final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
    if (ticketIndex == -1) return false;

    final ticket = _tickets[ticketIndex];
    if (ticket.isLocked) return false;

    // Check blood compatibility & cooldown
    if (!currentUser.isMedicallyEligible) return false;
    if (!BloodMatrix.isCompatible(currentUser.bloodGroup, ticket.bloodGroup)) return false;

    ticket.status = TicketStatus.accepted;
    ticket.unitsFulfilled += 1;
    ticket.acceptedDonorName = currentUser.name;
    ticket.acceptedDonorPhone = currentUser.phone;

    notifyListeners();
    return true;
  }

  // Donor marks themselves en route to hospital
  void markEnRoute(String ticketId) {
    final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
    if (ticketIndex != -1) {
      _tickets[ticketIndex].status = TicketStatus.enRoute;
      notifyListeners();
    }
  }

  // Hospital verifies arrival and marks fulfilled
  void fulfillTicket(String ticketId) {
    final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
    if (ticketIndex != -1) {
      _tickets[ticketIndex].status = TicketStatus.fulfilled;
      notifyListeners();
    }
  }

  // Get distance in KM from current user to ticket hospital
  double getDistanceToTicket(SosTicket ticket) {
    return GeoService.calculateDistanceKm(
      currentLocation.latitude,
      currentLocation.longitude,
      ticket.latitude,
      ticket.longitude,
    );
  }

  // Filter tickets that match current donor's compatibility, medical eligibility, and geo-radius
  List<SosTicket> get eligibleTicketsForDonor {
    return _tickets.where((ticket) {
      // 1. Check blood compatibility
      final isCompatible = BloodMatrix.isCompatible(currentUser.bloodGroup, ticket.bloodGroup);
      if (!isCompatible) return false;

      // 2. Check distance vs ticket urgency radius
      final distance = getDistanceToTicket(ticket);
      final isWithinRadius = distance <= ticket.radiusKm * 1.5; // slight tolerance

      return isWithinRadius;
    }).toList();
  }
}
