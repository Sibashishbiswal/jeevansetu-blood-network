import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/donor.dart';
import '../models/sos_ticket.dart';
import 'blood_matrix.dart';
import 'firebase_sync_service.dart';
import 'geo_service.dart';
import 'storage_service.dart';

enum UserRole { donor, hospital }

class AppState extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final FirebaseSyncService _firebaseSync = FirebaseSyncService();

  // Active User Profile (Default: O- Universal Donor)
  Donor currentUser = Donor(
    id: 'donor-sibashish',
    name: 'Sibashish Biswal',
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

  // Active in-transit emergency navigation state
  SosTicket? activeDispatchTicket;
  List<LatLng> activeRoutePoints = [];
  int? activeEtaMinutes;
  bool isCalculatingRoute = false;

  bool get isCloudConnected => FirebaseSyncService.isConnectedToCloud;

  AppState() {
    _initApp();
  }

  Future<void> _initApp() async {
    await _loadPersistedData();
    await refreshLocation();
    await _initFirebaseSync();
  }

  Future<void> _loadPersistedData() async {
    final savedUser = await StorageService.loadUser();
    if (savedUser != null) {
      currentUser = savedUser;
    }

    final savedTickets = await StorageService.loadTickets();
    if (savedTickets != null && savedTickets.isNotEmpty) {
      _tickets.clear();
      _tickets.addAll(savedTickets);
    } else {
      _initSampleData();
    }

    // Check if there's an ongoing active dispatch
    final inProgress = _tickets.firstWhere(
      (t) => (t.status == TicketStatus.accepted || t.status == TicketStatus.enRoute) &&
             t.acceptedDonorName == currentUser.name,
      orElse: () => SosTicket(
        id: '',
        patientName: '',
        bloodGroup: '',
        unitsRequired: 0,
        hospitalName: '',
        hospitalAddress: '',
        latitude: 0,
        longitude: 0,
        createdAt: DateTime.now(),
        handoverOtp: '',
      ),
    );

    if (inProgress.id.isNotEmpty) {
      activeDispatchTicket = inProgress;
      activeRoutePoints = inProgress.routePoints;
      activeEtaMinutes = inProgress.etaMinutes;
    }

    notifyListeners();
  }

  Future<void> _initFirebaseSync() async {
    await _firebaseSync.init(
      onRemoteTicketsUpdated: (remoteTickets) {
        if (remoteTickets.isNotEmpty) {
          // Merge remote tickets, preserving any newer local mutations
          _tickets.clear();
          _tickets.addAll(remoteTickets);
          StorageService.saveTickets(_tickets);
          notifyListeners();
        }
      },
    );
  }

  void _initSampleData() {
    _tickets.addAll([
      SosTicket(
        id: _uuid.v4(),
        patientName: 'Aarav Sharma (Accident Trauma)',
        bloodGroup: 'O-',
        unitsRequired: 2,
        unitsFulfilled: 0,
        hospitalName: 'AIIMS Trauma Center',
        hospitalAddress: 'Ring Road, Safdarjung Enclave, New Delhi',
        hospitalPhone: '+91 11 2658 8500',
        triageNotes: 'Emergency OT 2 - Massive internal hemorrhage',
        latitude: 28.5672,
        longitude: 77.2100,
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
        radiusKm: 7.5,
        status: TicketStatus.pending,
        handoverOtp: '8492',
      ),
      SosTicket(
        id: _uuid.v4(),
        patientName: 'Pooja Verma (Postpartum Surgery)',
        bloodGroup: 'B+',
        unitsRequired: 1,
        unitsFulfilled: 0,
        hospitalName: 'Max Super Speciality Hospital',
        hospitalAddress: 'Press Enclave Marg, Saket, New Delhi',
        hospitalPhone: '+91 11 6611 5050',
        triageNotes: 'Labor & Delivery ICU - Bed 14',
        latitude: 28.5284,
        longitude: 77.2185,
        createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
        radiusKm: 10.0,
        status: TicketStatus.pending,
        handoverOtp: '3914',
      ),
    ]);

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
    currentUser = currentUser.copyWith(
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
    );

    isLoadingLocation = false;
    notifyListeners();
  }

  void toggleRole() {
    currentRole = currentRole == UserRole.donor ? UserRole.hospital : UserRole.donor;
    notifyListeners();
  }

  void updateDonorBloodGroup(String newGroup) {
    currentUser = currentUser.copyWith(bloodGroup: newGroup);
    StorageService.saveUser(currentUser);
    notifyListeners();
  }

  void updateDonorProfile({
    String? name,
    String? phone,
    String? bloodGroup,
    bool? isAvailable,
    DateTime? lastDonationDate,
  }) {
    currentUser = currentUser.copyWith(
      name: name,
      phone: phone,
      bloodGroup: bloodGroup,
      isAvailable: isAvailable,
      lastDonationDate: lastDonationDate,
    );
    StorageService.saveUser(currentUser);
    notifyListeners();
  }

  // Create an Emergency SOS Ticket (Hospital Authority Action)
  Future<void> createSosTicket({
    required String patientName,
    required String bloodGroup,
    required int unitsRequired,
    required String hospitalName,
    required String hospitalAddress,
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String hospitalPhone = '+91 11 2658 8500',
    String triageNotes = 'Trauma / Surgery ICU Desk',
  }) async {
    // Generate secure 4-digit verification OTP
    final randomOtp = (1000 + Random().nextInt(9000)).toString();

    final newTicket = SosTicket(
      id: _uuid.v4(),
      patientName: patientName,
      bloodGroup: bloodGroup,
      unitsRequired: unitsRequired,
      hospitalName: hospitalName,
      hospitalAddress: hospitalAddress,
      hospitalPhone: hospitalPhone,
      triageNotes: triageNotes,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
      radiusKm: radiusKm,
      status: TicketStatus.pending,
      handoverOtp: randomOtp,
    );

    _tickets.insert(0, newTicket);
    await StorageService.saveTickets(_tickets);
    await _firebaseSync.publishTicket(newTicket);
    notifyListeners();
  }

  // Donor accepts an emergency request
  Future<bool> acceptTicket(String ticketId) async {
    final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
    if (ticketIndex == -1) return false;

    final ticket = _tickets[ticketIndex];
    if (ticket.isLocked) return false;

    // Check blood compatibility & cooldown
    if (!currentUser.isMedicallyEligible) return false;
    if (!BloodMatrix.isCompatible(currentUser.bloodGroup, ticket.bloodGroup)) return false;

    isCalculatingRoute = true;
    notifyListeners();

    // Calculate real road route and ETA
    final hospitalLocation = LatLng(ticket.latitude, ticket.longitude);
    final routeResult = await GeoService.getRoadRoute(currentLocation, hospitalLocation);

    ticket.status = TicketStatus.accepted;
    ticket.unitsFulfilled += 1;
    ticket.acceptedDonorName = currentUser.name;
    ticket.acceptedDonorPhone = currentUser.phone;
    ticket.acceptedAt = DateTime.now();
    ticket.routePoints = routeResult.points;
    ticket.etaMinutes = routeResult.etaMinutes;

    activeDispatchTicket = ticket;
    activeRoutePoints = routeResult.points;
    activeEtaMinutes = routeResult.etaMinutes;
    isCalculatingRoute = false;

    await StorageService.saveTickets(_tickets);
    await _firebaseSync.updateTicketStatus(
      ticketId,
      TicketStatus.accepted,
      donorName: currentUser.name,
      donorPhone: currentUser.phone,
    );

    notifyListeners();
    return true;
  }

  // Donor marks themselves en route to hospital
  Future<void> markEnRoute(String ticketId) async {
    final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
    if (ticketIndex != -1) {
      _tickets[ticketIndex].status = TicketStatus.enRoute;
      activeDispatchTicket = _tickets[ticketIndex];
      await StorageService.saveTickets(_tickets);
      await _firebaseSync.updateTicketStatus(ticketId, TicketStatus.enRoute);
      notifyListeners();
    }
  }

  // Cancel an active dispatch
  Future<void> cancelDispatch(String ticketId) async {
    final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
    if (ticketIndex != -1) {
      final ticket = _tickets[ticketIndex];
      ticket.status = TicketStatus.pending;
      ticket.unitsFulfilled = max(0, ticket.unitsFulfilled - 1);
      ticket.acceptedDonorName = null;
      ticket.acceptedDonorPhone = null;
      ticket.acceptedAt = null;
      ticket.routePoints = [];
      ticket.etaMinutes = null;

      if (activeDispatchTicket?.id == ticketId) {
        activeDispatchTicket = null;
        activeRoutePoints = [];
        activeEtaMinutes = null;
      }

      await StorageService.saveTickets(_tickets);
      await _firebaseSync.updateTicketStatus(ticketId, TicketStatus.pending);
      notifyListeners();
    }
  }

  // Bedside 4-digit OTP handover verification
  Future<bool> verifyAndFulfillHandover(String ticketId, String enteredOtp) async {
    final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
    if (ticketIndex == -1) return false;

    final ticket = _tickets[ticketIndex];
    if (ticket.handoverOtp.trim() != enteredOtp.trim()) {
      return false; // Invalid OTP
    }

    // Success! Mark ticket fulfilled
    ticket.status = TicketStatus.fulfilled;
    ticket.fulfilledAt = DateTime.now();

    // Record verified donation in donor's medical pass
    final newRecord = DonationRecord(
      id: _uuid.v4(),
      hospitalName: ticket.hospitalName,
      patientName: ticket.patientName,
      bloodGroup: ticket.bloodGroup,
      units: 1,
      donatedAt: DateTime.now(),
      verificationOtp: enteredOtp.trim(),
    );

    final updatedHistory = [newRecord, ...currentUser.donationHistory];
    currentUser = currentUser.copyWith(
      lastDonationDate: DateTime.now(), // 90-day cooldown starts NOW!
      donationHistory: updatedHistory,
    );

    activeDispatchTicket = null;
    activeRoutePoints = [];
    activeEtaMinutes = null;

    await StorageService.saveUser(currentUser);
    await StorageService.saveTickets(_tickets);
    await _firebaseSync.updateTicketStatus(ticketId, TicketStatus.fulfilled);

    notifyListeners();
    return true;
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

  // Test Simulation Trigger: Influx of critical emergency
  void simulateIncomingEmergency() {
    final randomOtp = (1000 + Random().nextInt(9000)).toString();
    final urgentTicket = SosTicket(
      id: _uuid.v4(),
      patientName: 'Karan Mehra (Emergency Surgery)',
      bloodGroup: currentUser.bloodGroup, // Tailored to current user!
      unitsRequired: 2,
      hospitalName: 'Fortis Escorts Heart Institute',
      hospitalAddress: 'Okhla Road, Sukhdev Vihar, New Delhi',
      hospitalPhone: '+91 11 4713 5000',
      triageNotes: 'Cardiac Bypass OT 1 - Immediate Transfusion Needed',
      latitude: currentLocation.latitude + 0.018,
      longitude: currentLocation.longitude + 0.015,
      createdAt: DateTime.now(),
      radiusKm: 6.0,
      status: TicketStatus.pending,
      handoverOtp: randomOtp,
    );

    _tickets.insert(0, urgentTicket);
    StorageService.saveTickets(_tickets);
    notifyListeners();
  }
}

