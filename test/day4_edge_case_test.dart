import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rakshak_blood_network/models/donor.dart';
import 'package:rakshak_blood_network/models/sos_ticket.dart';
import 'package:rakshak_blood_network/services/app_state.dart';
import 'package:rakshak_blood_network/services/blood_matrix.dart';
import 'package:rakshak_blood_network/services/geo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ──────────────────────────────────────────────────────────────────────────
  // BloodMatrix Edge Cases
  // ──────────────────────────────────────────────────────────────────────────
  group('BloodMatrix Edge Cases', () {
    test('B- can donate to B-, B+, AB-, and AB+ (Rh-negative donor rule)', () {
      // B- donor is accepted by any recipient whose donor list includes 'B-'
      expect(BloodMatrix.isCompatible('B-', 'B-'), isTrue);
      expect(BloodMatrix.isCompatible('B-', 'B+'), isTrue);  // B+ accepts B- donors
      expect(BloodMatrix.isCompatible('B-', 'AB-'), isTrue);
      expect(BloodMatrix.isCompatible('B-', 'AB+'), isTrue); // AB+ is universal recipient
      // B- cannot donate to A or O recipients
      expect(BloodMatrix.isCompatible('B-', 'O-'), isFalse);
      expect(BloodMatrix.isCompatible('B-', 'O+'), isFalse);
      expect(BloodMatrix.isCompatible('B-', 'A-'), isFalse);
      expect(BloodMatrix.isCompatible('B-', 'A+'), isFalse);
    });

    test('AB- can donate to AB- and AB+ only', () {
      expect(BloodMatrix.isCompatible('AB-', 'AB-'), isTrue);
      expect(BloodMatrix.isCompatible('AB-', 'AB+'), isTrue);
      expect(BloodMatrix.isCompatible('AB-', 'A+'), isFalse);
      expect(BloodMatrix.isCompatible('AB-', 'B+'), isFalse);
      expect(BloodMatrix.isCompatible('AB-', 'O+'), isFalse);
    });

    test('A- can donate to A-, A+, AB-, and AB+ (Rh-negative donor rule)', () {
      // A- donor is accepted by any recipient whose donor list includes 'A-'
      expect(BloodMatrix.isCompatible('A-', 'A-'), isTrue);
      expect(BloodMatrix.isCompatible('A-', 'A+'), isTrue);  // A+ accepts A- donors
      expect(BloodMatrix.isCompatible('A-', 'AB-'), isTrue);
      expect(BloodMatrix.isCompatible('A-', 'AB+'), isTrue); // AB+ is universal recipient
      // A- cannot donate to B or O recipients
      expect(BloodMatrix.isCompatible('A-', 'O-'), isFalse);
      expect(BloodMatrix.isCompatible('A-', 'O+'), isFalse);
      expect(BloodMatrix.isCompatible('A-', 'B-'), isFalse);
      expect(BloodMatrix.isCompatible('A-', 'B+'), isFalse);
    });

    test('getCompatibleDonorsFor returns non-empty list for all 8 groups', () {
      for (final group in BloodMatrix.allGroups) {
        final donors = BloodMatrix.getCompatibleDonorsFor(group);
        expect(donors, isNotEmpty,
            reason: '$group should have at least one compatible donor');
      }
    });

    test('unknown blood group returns false for isCompatible', () {
      expect(BloodMatrix.isCompatible('O-', 'Z+'), isFalse);
      expect(BloodMatrix.isCompatible('X-', 'AB+'), isFalse);
    });

    test('allGroups contains exactly 8 entries', () {
      expect(BloodMatrix.allGroups.length, equals(8));
      expect(BloodMatrix.allGroups, containsAll(['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+']));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Donor Medical Eligibility Edge Cases
  // ──────────────────────────────────────────────────────────────────────────
  group('Donor Medical Eligibility Edge Cases', () {
    test('Donor exactly at 90-day boundary is eligible', () {
      final donor = Donor(
        id: 'donor-boundary',
        name: 'Boundary Donor',
        phone: '+91 00000 11111',
        bloodGroup: 'A+',
        latitude: 28.6139,
        longitude: 77.2090,
        lastDonationDate: DateTime.now().subtract(const Duration(days: 90)),
      );
      expect(donor.isMedicallyEligible, isTrue);
      expect(donor.daysUntilEligible, equals(0));
    });

    test('Donor at 89 days is NOT eligible and shows 1 day remaining', () {
      final donor = Donor(
        id: 'donor-ineligible',
        name: 'Cooldown Donor',
        phone: '+91 00000 22222',
        bloodGroup: 'B+',
        latitude: 28.6139,
        longitude: 77.2090,
        lastDonationDate: DateTime.now().subtract(const Duration(days: 89)),
      );
      expect(donor.isMedicallyEligible, isFalse);
      expect(donor.daysUntilEligible, equals(1));
    });

    test('First-time donor (180+ days ago) is fully eligible', () {
      final donor = Donor(
        id: 'donor-new',
        name: 'Fresh Donor',
        phone: '+91 00000 33333',
        bloodGroup: 'O+',
        latitude: 28.6139,
        longitude: 77.2090,
        lastDonationDate: DateTime.now().subtract(const Duration(days: 180)),
      );
      expect(donor.isMedicallyEligible, isTrue);
      expect(donor.daysUntilEligible, equals(0));
    });

    test('DonationRecord JSON round-trip preserves all fields', () {
      final now = DateTime.now();
      final record = DonationRecord(
        id: 'rec-edge-1',
        hospitalName: 'Safdarjung Hospital',
        patientName: 'Test Patient',
        bloodGroup: 'AB+',
        units: 2,
        donatedAt: now,
        verificationOtp: '5678',
      );
      final restored = DonationRecord.fromJson(record.toJson());
      expect(restored.id, equals('rec-edge-1'));
      expect(restored.units, equals(2));
      expect(restored.bloodGroup, equals('AB+'));
      expect(restored.verificationOtp, equals('5678'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GeoService Edge Cases
  // ──────────────────────────────────────────────────────────────────────────
  group('GeoService Edge Cases', () {
    test('Distance to same point is zero', () {
      final dist = GeoService.calculateDistanceKm(28.6139, 77.2090, 28.6139, 77.2090);
      expect(dist, lessThan(0.001));
    });

    test('ETA for very short distance returns minimum value', () {
      expect(GeoService.calculateEtaMinutes(0.01), equals(1));
      expect(GeoService.calculateEtaMinutes(0.0), equals(1));
    });

    test('ETA for 10 km journey at 32 km/h is approximately 19 minutes', () {
      final eta = GeoService.calculateEtaMinutes(10.0);
      // 10km / 32 km/h = 0.3125 hours = 18.75 minutes → rounds to 19
      expect(eta, inInclusiveRange(18, 20));
    });

    test('Curved fallback waypoints start and end at correct coordinates', () async {
      const startLat = 28.6315; // Connaught Place
      const startLng = 77.2167;
      const destLat = 28.5672; // AIIMS
      const destLng = 77.2100;
      final result = await GeoService.getRoadRoute(
        const LatLng(startLat, startLng),
        const LatLng(destLat, destLng),
      );
      // Whether OSRM or fallback, first point is near start, last near dest
      expect(result.points.first.latitude, closeTo(startLat, 0.01));
      expect(result.points.last.latitude, closeTo(destLat, 0.01));
      expect(result.distanceKm, greaterThan(0));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // SosTicket Business Logic Edge Cases
  // ──────────────────────────────────────────────────────────────────────────
  group('SosTicket Business Logic Edge Cases', () {
    test('Ticket isLocked when unitsFulfilled >= unitsRequired', () {
      final ticket = SosTicket(
        id: 'lock-test',
        patientName: 'Patient A',
        bloodGroup: 'O+',
        unitsRequired: 1,
        unitsFulfilled: 1,
        hospitalName: 'Test Hospital',
        hospitalAddress: 'Test Address',
        latitude: 28.5,
        longitude: 77.2,
        createdAt: DateTime.now(),
        handoverOtp: '1234',
      );
      expect(ticket.isLocked, isTrue);
    });

    test('Ticket isLocked when status is fulfilled', () {
      final ticket = SosTicket(
        id: 'fulfilled-test',
        patientName: 'Patient B',
        bloodGroup: 'B-',
        unitsRequired: 2,
        unitsFulfilled: 0,
        hospitalName: 'Test Hospital',
        hospitalAddress: 'Test Address',
        latitude: 28.5,
        longitude: 77.2,
        createdAt: DateTime.now(),
        handoverOtp: '9999',
        status: TicketStatus.fulfilled,
      );
      expect(ticket.isLocked, isTrue);
    });

    test('Pending ticket with 0 units fulfilled is NOT locked', () {
      final ticket = SosTicket(
        id: 'open-test',
        patientName: 'Patient C',
        bloodGroup: 'A-',
        unitsRequired: 3,
        unitsFulfilled: 0,
        hospitalName: 'Test Hospital',
        hospitalAddress: 'Test Address',
        latitude: 28.5,
        longitude: 77.2,
        createdAt: DateTime.now(),
        handoverOtp: '4321',
      );
      expect(ticket.isLocked, isFalse);
    });

    test('SosTicket fromJson handles missing optional fields with defaults', () {
      final minimalJson = {
        'id': 'minimal-1',
        'patientName': 'Minimal Patient',
        'bloodGroup': 'O+',
        'unitsRequired': 1,
        'hospitalName': 'Minimal Hospital',
        'hospitalAddress': 'Minimal Address',
        'latitude': 28.5,
        'longitude': 77.2,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'pending',
        'handoverOtp': '1111',
      };
      final ticket = SosTicket.fromJson(minimalJson);
      expect(ticket.unitsFulfilled, equals(0));
      expect(ticket.radiusKm, equals(5.0));
      expect(ticket.etaMinutes, isNull);
      expect(ticket.routePoints, isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // AppState Concurrency & Safety Guards
  // ──────────────────────────────────────────────────────────────────────────
  group('AppState Concurrency & Safety Guards', () {
    test('Ineligible donor (in cooldown) cannot accept ticket', () async {
      final appState = AppState();
      appState.updateDonorBloodGroup('O-');
      // Set donor in cooldown (donated 30 days ago — within 90-day window)
      appState.updateDonorProfile(
        lastDonationDate: DateTime.now().subtract(const Duration(days: 30)),
      );

      await appState.createSosTicket(
        patientName: 'Cooldown Test Patient',
        bloodGroup: 'O-',
        unitsRequired: 1,
        hospitalName: 'Safdarjung Hospital',
        hospitalAddress: 'Ring Road, New Delhi',
        latitude: 28.5694,
        longitude: 77.2078,
      );

      final ticket = appState.tickets.first;
      final accepted = await appState.acceptTicket(ticket.id);
      expect(accepted, isFalse,
          reason: 'Donor within 90-day cooldown must NOT be able to accept');
      expect(appState.activeDispatchTicket, isNull);
    });

    test('Incompatible donor blood group cannot accept ticket', () async {
      final appState = AppState();
      appState.updateDonorBloodGroup('A+'); // donor is A+
      appState.updateDonorProfile(
        lastDonationDate: DateTime.now().subtract(const Duration(days: 100)),
      );

      await appState.createSosTicket(
        patientName: 'Incompatible Patient',
        bloodGroup: 'B+', // requires B+, O+, B-, O- donors
        unitsRequired: 1,
        hospitalName: 'Apollo Hospital',
        hospitalAddress: 'Sarita Vihar, New Delhi',
        latitude: 28.5398,
        longitude: 77.2917,
      );

      final ticket = appState.tickets.first;
      final accepted = await appState.acceptTicket(ticket.id);
      expect(accepted, isFalse,
          reason: 'A+ donor must NOT be accepted for a B+ ticket');
    });

    test('Locked ticket cannot be accepted twice (atomic lock guard)', () async {
      final appState = AppState();
      appState.updateDonorBloodGroup('O-');
      appState.updateDonorProfile(
        lastDonationDate: DateTime.now().subtract(const Duration(days: 100)),
      );

      await appState.createSosTicket(
        patientName: 'Lock Guard Patient',
        bloodGroup: 'O-',
        unitsRequired: 1, // Only 1 unit needed
        hospitalName: 'AIIMS Trauma Center',
        hospitalAddress: 'Ring Road, New Delhi',
        latitude: 28.5672,
        longitude: 77.2100,
      );

      final ticket = appState.tickets.first;
      final first = await appState.acceptTicket(ticket.id);
      expect(first, isTrue);

      // Second attempt must be rejected
      final second = await appState.acceptTicket(ticket.id);
      expect(second, isFalse,
          reason: 'Ticket must be atomically locked after first acceptance');
    });

    test('Cancel dispatch resets ticket back to pending state', () async {
      final appState = AppState();
      appState.updateDonorBloodGroup('O-');
      appState.updateDonorProfile(
        lastDonationDate: DateTime.now().subtract(const Duration(days: 100)),
      );

      await appState.createSosTicket(
        patientName: 'Cancel Test Patient',
        bloodGroup: 'O-',
        unitsRequired: 2,
        hospitalName: 'Fortis Hospital',
        hospitalAddress: 'Shalimar Bagh, Delhi',
        latitude: 28.7150,
        longitude: 77.1650,
      );

      final ticket = appState.tickets.first;
      await appState.acceptTicket(ticket.id);
      expect(appState.activeDispatchTicket, isNotNull);

      await appState.cancelDispatch(ticket.id);
      expect(appState.activeDispatchTicket, isNull);
      expect(ticket.status, equals(TicketStatus.pending));
      expect(ticket.acceptedDonorName, isNull);
      expect(appState.isTransitSimulating, isFalse);
    });

    test('Wrong OTP does not fulfill ticket and leaves it en-route', () async {
      final appState = AppState();
      appState.updateDonorBloodGroup('O-');
      appState.updateDonorProfile(
        lastDonationDate: DateTime.now().subtract(const Duration(days: 100)),
      );

      await appState.createSosTicket(
        patientName: 'OTP Edge Patient',
        bloodGroup: 'O-',
        unitsRequired: 1,
        hospitalName: 'Max Hospital',
        hospitalAddress: 'Saket, New Delhi',
        latitude: 28.5284,
        longitude: 77.2185,
      );

      final ticket = appState.tickets.first;
      await appState.acceptTicket(ticket.id);
      await appState.markEnRoute(ticket.id);

      // Try 5 wrong OTPs
      for (final wrongOtp in ['0000', '1111', '2222', '9999', '    ']) {
        final result = await appState.verifyAndFulfillHandover(ticket.id, wrongOtp);
        expect(result, isFalse,
            reason: 'OTP "$wrongOtp" must be rejected');
      }
      expect(ticket.status, equals(TicketStatus.enRoute));
    });

    test('Dismissing broadcast alert clears incomingBroadcastAlert', () {
      final appState = AppState();
      appState.simulateIncomingEmergency();
      expect(appState.incomingBroadcastAlert, isNotNull);

      appState.dismissBroadcastAlert();
      expect(appState.incomingBroadcastAlert, isNull);
    });

    test('eligibleTicketsForDonor filters out incompatible blood groups', () async {
      final appState = AppState();
      appState.updateDonorBloodGroup('A+'); // A+ can only donate to A+, AB+

      // Create a B+ ticket — A+ donor should NOT see it
      await appState.createSosTicket(
        patientName: 'B+ Patient',
        bloodGroup: 'B+',
        unitsRequired: 1,
        hospitalName: 'Test Hospital',
        hospitalAddress: 'Test Address',
        latitude: appState.currentLocation.latitude + 0.01,
        longitude: appState.currentLocation.longitude + 0.01,
        radiusKm: 50.0,
      );

      final eligible = appState.eligibleTicketsForDonor;
      final hasBPlusTicket = eligible.any((t) => t.bloodGroup == 'B+');
      expect(hasBPlusTicket, isFalse,
          reason: 'A+ donor must NOT see B+ tickets in eligible list');
    });
  });
}
