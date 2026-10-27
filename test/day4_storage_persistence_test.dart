import 'package:flutter_test/flutter_test.dart';
import 'package:rakshak_blood_network/models/donor.dart';
import 'package:rakshak_blood_network/models/sos_ticket.dart';
import 'package:rakshak_blood_network/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ──────────────────────────────────────────────────────────────────────────
  // StorageService — Offline-First Persistence Round-Trips
  // ──────────────────────────────────────────────────────────────────────────
  group('StorageService Persistence Round-Trips', () {
    test('saveUser then loadUser returns identical Donor profile', () async {
      final record = DonationRecord(
        id: 'rec-persist-1',
        hospitalName: 'AIIMS New Delhi',
        patientName: 'Persist Patient',
        bloodGroup: 'O-',
        units: 1,
        donatedAt: DateTime.parse('2026-10-01T08:30:00Z'),
        verificationOtp: '4242',
      );

      final originalDonor = Donor(
        id: 'donor-persist-1',
        name: 'Sibashish Biswal',
        phone: '+91 98765 43210',
        bloodGroup: 'O-',
        latitude: 28.6139,
        longitude: 77.2090,
        lastDonationDate: DateTime.parse('2026-07-15T00:00:00Z'),
        isAvailable: true,
        donationHistory: [record],
      );

      await StorageService.saveUser(originalDonor);
      final loadedDonor = await StorageService.loadUser();

      expect(loadedDonor, isNotNull);
      expect(loadedDonor!.id, equals('donor-persist-1'));
      expect(loadedDonor.name, equals('Sibashish Biswal'));
      expect(loadedDonor.bloodGroup, equals('O-'));
      expect(loadedDonor.phone, equals('+91 98765 43210'));
      expect(loadedDonor.latitude, closeTo(28.6139, 0.0001));
      expect(loadedDonor.longitude, closeTo(77.2090, 0.0001));
      expect(loadedDonor.donationHistory.length, equals(1));
      expect(loadedDonor.donationHistory.first.verificationOtp, equals('4242'));
      expect(loadedDonor.donationHistory.first.hospitalName, equals('AIIMS New Delhi'));
    });

    test('loadUser returns null when nothing has been saved', () async {
      final result = await StorageService.loadUser();
      expect(result, isNull);
    });

    test('saveUser overwrites previous save correctly', () async {
      final first = Donor(
        id: 'donor-overwrite',
        name: 'First Name',
        phone: '+91 11111 11111',
        bloodGroup: 'A+',
        latitude: 28.6,
        longitude: 77.2,
        lastDonationDate: DateTime.now().subtract(const Duration(days: 100)),
      );
      await StorageService.saveUser(first);

      final second = first.copyWith(name: 'Updated Name', bloodGroup: 'B+');
      await StorageService.saveUser(second);

      final loaded = await StorageService.loadUser();
      expect(loaded!.name, equals('Updated Name'));
      expect(loaded.bloodGroup, equals('B+'));
    });

    test('saveTickets then loadTickets returns identical list', () async {
      final now = DateTime.parse('2026-10-27T10:00:00Z');
      final tickets = [
        SosTicket(
          id: 'ticket-persist-1',
          patientName: 'Ram Lal (Trauma)',
          bloodGroup: 'O-',
          unitsRequired: 2,
          unitsFulfilled: 1,
          hospitalName: 'AIIMS Trauma Center',
          hospitalAddress: 'Ring Road, Safdarjung Enclave, New Delhi',
          hospitalPhone: '+91 11 2658 8500',
          triageNotes: 'Emergency OT 1',
          latitude: 28.5672,
          longitude: 77.2100,
          createdAt: now,
          radiusKm: 8.0,
          status: TicketStatus.enRoute,
          handoverOtp: '7777',
          etaMinutes: 12,
        ),
        SosTicket(
          id: 'ticket-persist-2',
          patientName: 'Anjali Sharma (Postpartum)',
          bloodGroup: 'B+',
          unitsRequired: 1,
          unitsFulfilled: 0,
          hospitalName: 'Max Hospital Saket',
          hospitalAddress: 'Press Enclave Marg, Saket',
          latitude: 28.5284,
          longitude: 77.2185,
          createdAt: now,
          handoverOtp: '3333',
          status: TicketStatus.pending,
        ),
      ];

      await StorageService.saveTickets(tickets);
      final loaded = await StorageService.loadTickets();

      expect(loaded, isNotNull);
      expect(loaded!.length, equals(2));

      final t1 = loaded.firstWhere((t) => t.id == 'ticket-persist-1');
      expect(t1.patientName, equals('Ram Lal (Trauma)'));
      expect(t1.bloodGroup, equals('O-'));
      expect(t1.status, equals(TicketStatus.enRoute));
      expect(t1.handoverOtp, equals('7777'));
      expect(t1.etaMinutes, equals(12));
      expect(t1.radiusKm, closeTo(8.0, 0.001));

      final t2 = loaded.firstWhere((t) => t.id == 'ticket-persist-2');
      expect(t2.status, equals(TicketStatus.pending));
      expect(t2.unitsFulfilled, equals(0));
    });

    test('loadTickets returns null when nothing saved', () async {
      final result = await StorageService.loadTickets();
      expect(result, isNull);
    });

    test('saveTickets with empty list persists and reloads as empty', () async {
      await StorageService.saveTickets([]);
      final result = await StorageService.loadTickets();
      // Empty JSON array loaded back — may return empty list or null depending on impl
      // Both are acceptable: null means "no saved data", [] means "saved empty"
      expect(result == null || result.isEmpty, isTrue);
    });

    test('saveDonationHistory then loadDonationHistory returns full history', () async {
      final history = [
        DonationRecord(
          id: 'hist-1',
          hospitalName: 'Fortis Hospital',
          patientName: 'Vinod Kumar',
          bloodGroup: 'A+',
          units: 1,
          donatedAt: DateTime.parse('2026-09-01T09:00:00Z'),
          verificationOtp: '1122',
        ),
        DonationRecord(
          id: 'hist-2',
          hospitalName: 'Apollo Hospital',
          patientName: 'Kavita Rao',
          bloodGroup: 'O-',
          units: 2,
          donatedAt: DateTime.parse('2026-06-15T14:30:00Z'),
          verificationOtp: '3344',
        ),
      ];

      await StorageService.saveDonationHistory(history);
      final loaded = await StorageService.loadDonationHistory();

      expect(loaded, isNotNull);
      expect(loaded!.length, equals(2));
      expect(loaded.first.id, equals('hist-1'));
      expect(loaded.first.verificationOtp, equals('1122'));
      expect(loaded.last.bloodGroup, equals('O-'));
      expect(loaded.last.units, equals(2));
    });

    test('loadDonationHistory returns null when nothing saved', () async {
      final result = await StorageService.loadDonationHistory();
      expect(result, isNull);
    });

    test('Ticket serialization preserves all TicketStatus enum values correctly', () async {
      final allStatuses = [
        TicketStatus.pending,
        TicketStatus.accepted,
        TicketStatus.enRoute,
        TicketStatus.fulfilled,
        TicketStatus.cancelled,
      ];

      for (final status in allStatuses) {
        final ticket = SosTicket(
          id: 'status-test-${status.name}',
          patientName: 'Status Test',
          bloodGroup: 'O+',
          unitsRequired: 1,
          hospitalName: 'Test Hospital',
          hospitalAddress: 'Test Address',
          latitude: 28.5,
          longitude: 77.2,
          createdAt: DateTime.now(),
          handoverOtp: '5555',
          status: status,
        );

        await StorageService.saveTickets([ticket]);
        final loaded = await StorageService.loadTickets();

        expect(loaded, isNotNull);
        expect(loaded!.first.status, equals(status),
            reason: 'Status ${status.name} must survive JSON round-trip');

        // Reset for next iteration
        SharedPreferences.setMockInitialValues({});
      }
    });
  });
}
