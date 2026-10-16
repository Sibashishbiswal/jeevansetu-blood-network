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

  group('BloodMatrix Clinical Compatibility Tests', () {
    test('O- is universal donor to all 8 blood groups', () {
      for (final recipient in BloodMatrix.allGroups) {
        expect(BloodMatrix.isCompatible('O-', recipient), isTrue,
            reason: 'O- must be compatible with $recipient');
      }
    });

    test('AB+ is universal recipient from all 8 blood groups', () {
      for (final donor in BloodMatrix.allGroups) {
        expect(BloodMatrix.isCompatible(donor, 'AB+'), isTrue,
            reason: 'AB+ must be able to receive from $donor');
      }
    });

    test('O+ cannot donate to Rh-negative recipients', () {
      expect(BloodMatrix.isCompatible('O+', 'O-'), isFalse);
      expect(BloodMatrix.isCompatible('O+', 'A-'), isFalse);
      expect(BloodMatrix.isCompatible('O+', 'B-'), isFalse);
      expect(BloodMatrix.isCompatible('O+', 'AB-'), isFalse);
    });

    test('A+ cannot donate to B or O recipients', () {
      expect(BloodMatrix.isCompatible('A+', 'B+'), isFalse);
      expect(BloodMatrix.isCompatible('A+', 'B-'), isFalse);
      expect(BloodMatrix.isCompatible('A+', 'O+'), isFalse);
      expect(BloodMatrix.isCompatible('A+', 'O-'), isFalse);
    });
  });

  group('GeoService Calculations & Waypoints', () {
    test('Haversine distance calculation is accurate', () {
      // Distance between Connaught Place (28.6315, 77.2167) and AIIMS Delhi (28.5672, 77.2100) is approx ~7.1 km
      final dist = GeoService.calculateDistanceKm(28.6315, 77.2167, 28.5672, 77.2100);
      expect(dist, greaterThan(6.5));
      expect(dist, lessThan(7.8));
    });

    test('ETA calculation handles urban transit bounds', () {
      expect(GeoService.calculateEtaMinutes(5.0), inInclusiveRange(8, 12));
      expect(GeoService.calculateEtaMinutes(0.0), equals(1));
    });

    test('Road route fallback generates valid non-empty waypoints', () async {
      final start = const LatLng(28.6139, 77.2090);
      final dest = const LatLng(28.5672, 77.2100);
      final result = await GeoService.getRoadRoute(start, dest);

      expect(result.points.length, greaterThan(5));
      expect(result.points.first.latitude, equals(start.latitude));
      expect(result.points.last.latitude, equals(dest.latitude));
      expect(result.etaMinutes, greaterThan(0));
    });
  });

  group('SosTicket Handover OTP & Serialization', () {
    test('SosTicket JSON serialization roundtrip', () {
      final ticket = SosTicket(
        id: 'ticket-101',
        patientName: 'Kavita Rao',
        bloodGroup: 'O-',
        unitsRequired: 2,
        unitsFulfilled: 1,
        hospitalName: 'Apollo Hospital',
        hospitalAddress: 'Sarita Vihar, Delhi',
        hospitalPhone: '+91 11 2692 5858',
        triageNotes: 'ICU Bed 12',
        latitude: 28.5398,
        longitude: 77.2917,
        createdAt: DateTime.parse('2026-10-16T10:00:00Z'),
        radiusKm: 8.0,
        status: TicketStatus.enRoute,
        handoverOtp: '7492',
        etaMinutes: 14,
      );

      final jsonMap = ticket.toJson();
      final restored = SosTicket.fromJson(jsonMap);

      expect(restored.id, equals('ticket-101'));
      expect(restored.patientName, equals('Kavita Rao'));
      expect(restored.bloodGroup, equals('O-'));
      expect(restored.handoverOtp, equals('7492'));
      expect(restored.status, equals(TicketStatus.enRoute));
      expect(restored.etaMinutes, equals(14));
    });

    test('Donor JSON serialization roundtrip with DonationRecord', () {
      final record = DonationRecord(
        id: 'rec-1',
        hospitalName: 'AIIMS',
        patientName: 'Aarav',
        bloodGroup: 'O-',
        units: 1,
        donatedAt: DateTime.now(),
        verificationOtp: '8492',
      );

      final donor = Donor(
        id: 'donor-test',
        name: 'Sibashish',
        phone: '+91 99999 11111',
        bloodGroup: 'O-',
        latitude: 28.6139,
        longitude: 77.2090,
        lastDonationDate: DateTime.now().subtract(const Duration(days: 100)),
        donationHistory: [record],
      );

      final jsonMap = donor.toJson();
      final restored = Donor.fromJson(jsonMap);

      expect(restored.name, equals('Sibashish'));
      expect(restored.bloodGroup, equals('O-'));
      expect(restored.isMedicallyEligible, isTrue);
      expect(restored.donationHistory.length, equals(1));
      expect(restored.donationHistory.first.verificationOtp, equals('8492'));
    });
  });

  group('AppState Ticket Lifecycle & Handover Verification', () {
    test('Accepting ticket generates route, sets en-route, and verifies OTP', () async {
      final appState = AppState();

      // Ensure donor is eligible O-
      appState.updateDonorBloodGroup('O-');
      appState.updateDonorProfile(lastDonationDate: DateTime.now().subtract(const Duration(days: 105)));

      // Create an SOS ticket
      await appState.createSosTicket(
        patientName: 'Emergency Trauma Patient',
        bloodGroup: 'O-',
        unitsRequired: 1,
        hospitalName: 'Safdarjung Hospital',
        hospitalAddress: 'Ring Road, New Delhi',
        latitude: 28.5694,
        longitude: 77.2078,
        radiusKm: 10.0,
      );

      final ticket = appState.tickets.first;
      expect(ticket.status, equals(TicketStatus.pending));
      final generatedOtp = ticket.handoverOtp;
      expect(generatedOtp.length, equals(4));

      // 1. Accept ticket
      final accepted = await appState.acceptTicket(ticket.id);
      expect(accepted, isTrue);
      expect(appState.activeDispatchTicket?.id, equals(ticket.id));
      expect(appState.activeRoutePoints.isNotEmpty, isTrue);

      // 2. Mark en-route
      await appState.markEnRoute(ticket.id);
      expect(ticket.status, equals(TicketStatus.enRoute));

      // 3. Attempt verification with WRONG OTP
      final wrongVerify = await appState.verifyAndFulfillHandover(ticket.id, '0000');
      expect(wrongVerify, isFalse);
      expect(ticket.status, equals(TicketStatus.enRoute)); // Still en route!

      // 4. Verify with CORRECT OTP
      final correctVerify = await appState.verifyAndFulfillHandover(ticket.id, generatedOtp);
      expect(correctVerify, isTrue);
      expect(ticket.status, equals(TicketStatus.fulfilled));
      expect(appState.activeDispatchTicket, isNull);

      // Donor should now have a recorded donation and be in 90-day cooldown
      expect(appState.currentUser.donationHistory.length, greaterThan(0));
      expect(appState.currentUser.donationHistory.first.hospitalName, equals('Safdarjung Hospital'));
      expect(appState.currentUser.isMedicallyEligible, isFalse);
      expect(appState.currentUser.daysUntilEligible, inInclusiveRange(89, 90));
    });
  });
}
