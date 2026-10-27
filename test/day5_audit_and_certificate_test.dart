import 'package:flutter_test/flutter_test.dart';
import 'package:rakshak_blood_network/models/audit_log.dart';
import 'package:rakshak_blood_network/models/donor.dart';
import 'package:rakshak_blood_network/services/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Day 5: AuditLog Data Model Tests', () {
    test('AuditLog JSON serialization round-trip preserves all fields', () {
      final now = DateTime.now();
      final original = AuditLog(
        id: 'audit-101',
        title: 'Emergency SOS Created',
        details: 'AIIMS: 2 Units O- requested for patient Aarav Sharma',
        timestamp: now,
        type: 'created',
        ticketId: 'ticket-999',
      );

      final json = original.toJson();
      final parsed = AuditLog.fromJson(json);

      expect(parsed.id, equals('audit-101'));
      expect(parsed.title, equals('Emergency SOS Created'));
      expect(parsed.details, equals('AIIMS: 2 Units O- requested for patient Aarav Sharma'));
      expect(parsed.type, equals('created'));
      expect(parsed.ticketId, equals('ticket-999'));
      expect(parsed.timestamp.toIso8601String(), equals(now.toIso8601String()));
    });

    test('AuditLog handles null ticketId correctly in JSON round-trip', () {
      final original = AuditLog(
        id: 'audit-102',
        title: 'System Initialized',
        details: 'Local dispatch node started',
        timestamp: DateTime.now(),
        type: 'system',
        ticketId: null,
      );

      final json = original.toJson();
      final parsed = AuditLog.fromJson(json);

      expect(parsed.ticketId, isNull);
      expect(parsed.type, equals('system'));
    });
  });

  group('Day 5: AppState Audit Trail Lifecycle Integration', () {
    test('AppState initializes with seeded audit entries for Hospital Desk', () {
      final appState = AppState();
      expect(appState.auditLogs, isNotEmpty);
      expect(appState.auditLogs.first.title, isNotEmpty);
    });

    test('addAuditLog inserts newest event at index 0 (chronological order)', () {
      final appState = AppState();
      final initialCount = appState.auditLogs.length;

      appState.addAuditLog(
        title: 'Test Dispatch Alert',
        details: 'Manual test entry for audit verification',
        type: 'test',
      );

      expect(appState.auditLogs.length, equals(initialCount + 1));
      expect(appState.auditLogs.first.title, equals('Test Dispatch Alert'));
      expect(appState.auditLogs.first.type, equals('test'));
    });

    test('addAuditLog caps retention at 50 logs to prevent memory leak', () {
      final appState = AppState();

      for (int i = 0; i < 60; i++) {
        appState.addAuditLog(
          title: 'Event #$i',
          details: 'Details for event $i',
          type: 'bench',
        );
      }

      expect(appState.auditLogs.length, lessThanOrEqualTo(50));
      expect(appState.auditLogs.first.title, equals('Event #59'));
    });

    test('createSosTicket appends created audit log with ticket ID', () async {
      final appState = AppState();

      await appState.createSosTicket(
        patientName: 'Test Patient',
        bloodGroup: 'B+',
        unitsRequired: 1,
        hospitalName: 'Apollo Hospital',
        hospitalAddress: 'Delhi',
        latitude: 28.5355,
        longitude: 77.2600,
      );

      final latestLog = appState.auditLogs.first;
      expect(latestLog.type, equals('created'));
      expect(latestLog.title, equals('Emergency SOS Created'));
      expect(latestLog.details, contains('Apollo Hospital'));
      expect(latestLog.details, contains('Test Patient'));
      expect(latestLog.ticketId, isNotNull);
    });

    test('acceptTicket appends accepted audit log with donor info', () async {
      final appState = AppState();
      appState.currentUser = appState.currentUser.copyWith(
        bloodGroup: 'O-',
        lastDonationDate: DateTime.now().subtract(const Duration(days: 100)),
      );

      await appState.createSosTicket(
        patientName: 'Critical Patient',
        bloodGroup: 'O-',
        unitsRequired: 1,
        hospitalName: 'Fortis Hospital',
        hospitalAddress: 'Shalimar Bagh',
        latitude: 28.7166,
        longitude: 77.1593,
      );

      final ticketId = appState.tickets.first.id;
      final accepted = await appState.acceptTicket(ticketId);

      expect(accepted, isTrue);
      final latestLog = appState.auditLogs.first;
      expect(latestLog.type, equals('accepted'));
      expect(latestLog.title, equals('Donor Matched & Dispatched'));
      expect(latestLog.details, contains(appState.currentUser.name));
    });

    test('markEnRoute appends transit audit log', () async {
      final appState = AppState();
      final ticket = appState.tickets.first;

      await appState.markEnRoute(ticket.id);

      final latestLog = appState.auditLogs.first;
      expect(latestLog.type, equals('transit'));
      expect(latestLog.title, equals('Donor In-Transit'));
      expect(latestLog.details, contains(ticket.hospitalName));
    });

    test('cancelDispatch appends cancelled audit log and resets ticket', () async {
      final appState = AppState();
      final ticket = appState.tickets.first;

      await appState.cancelDispatch(ticket.id);

      final latestLog = appState.auditLogs.first;
      expect(latestLog.type, equals('cancelled'));
      expect(latestLog.title, equals('Dispatch Cancelled'));
    });

    test('verifyAndFulfillHandover appends fulfilled audit log with OTP', () async {
      final appState = AppState();
      final ticket = appState.tickets.first;

      final success = await appState.verifyAndFulfillHandover(ticket.id, ticket.handoverOtp);

      expect(success, isTrue);
      final latestLog = appState.auditLogs.first;
      expect(latestLog.type, equals('fulfilled'));
      expect(latestLog.title, equals('Transfusion Verified & Fulfilled'));
      expect(latestLog.details, contains(ticket.handoverOtp));
    });
  });

  group('Day 5: Donor Life-Saver Badge Tiers & Certificate Serial', () {
    test('Donor with 0 donations is Active Volunteer', () {
      final donor = Donor(
        id: 'd-test-0',
        name: 'New Donor',
        phone: '9999999999',
        bloodGroup: 'A+',
        latitude: 28.6,
        longitude: 77.2,
        lastDonationDate: DateTime.now().subtract(const Duration(days: 100)),
        donationHistory: [],
      );

      expect(donor.totalUnitsDonated, equals(0));
      expect(donor.donorBadgeTier, equals('Active Volunteer 🩸'));
    });

    test('Donor with 1-2 donations is Bronze Life-Saver', () {
      final record = DonationRecord(
        id: 'rec-1',
        hospitalName: 'AIIMS',
        patientName: 'Patient X',
        bloodGroup: 'O+',
        units: 1,
        donatedAt: DateTime.now(),
        verificationOtp: '1234',
      );

      final donor = Donor(
        id: 'd-test-1',
        name: 'Bronze Donor',
        phone: '9999999999',
        bloodGroup: 'O+',
        latitude: 28.6,
        longitude: 77.2,
        lastDonationDate: DateTime.now(),
        donationHistory: [record],
      );

      expect(donor.totalUnitsDonated, equals(1));
      expect(donor.donorBadgeTier, equals('Bronze Life-Saver 🥉'));
    });

    test('Donor with 3-5 donations is Silver Guardian and 6+ is Gold Rakshak', () {
      DonationRecord makeRecord(int i) => DonationRecord(
        id: 'rec-$i',
        hospitalName: 'Hospital $i',
        patientName: 'Patient $i',
        bloodGroup: 'B-',
        units: 1,
        donatedAt: DateTime.now(),
        verificationOtp: '100$i',
      );

      final silverDonor = Donor(
        id: 'd-silver',
        name: 'Silver Donor',
        phone: '9999999999',
        bloodGroup: 'B-',
        latitude: 28.6,
        longitude: 77.2,
        lastDonationDate: DateTime.now(),
        donationHistory: [makeRecord(1), makeRecord(2), makeRecord(3)],
      );

      expect(silverDonor.totalUnitsDonated, equals(3));
      expect(silverDonor.donorBadgeTier, equals('Silver Guardian 🥈'));

      final goldDonor = silverDonor.copyWith(
        donationHistory: [
          makeRecord(1), makeRecord(2), makeRecord(3),
          makeRecord(4), makeRecord(5), makeRecord(6),
        ],
      );

      expect(goldDonor.totalUnitsDonated, equals(6));
      expect(goldDonor.donorBadgeTier, equals('Gold Rakshak 🥇'));
    });

    test('DonationRecord certificateSerial formats correctly with JS-CERT- prefix', () {
      final record = DonationRecord(
        id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        hospitalName: 'Safdarjung Hospital',
        patientName: 'Rohit Kumar',
        bloodGroup: 'AB-',
        units: 1,
        donatedAt: DateTime.now(),
        verificationOtp: '8492',
      );

      expect(record.certificateSerial, equals('JS-CERT-A1B2C3D4'));
    });
  });
}
