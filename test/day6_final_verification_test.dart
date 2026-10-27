import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rakshak_blood_network/models/sos_ticket.dart';
import 'package:rakshak_blood_network/services/app_state.dart';
import 'package:rakshak_blood_network/widgets/offline_sync_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Day 6: Proximity Sorting & Multi-Radius Filtering Tests', () {
    test('getTicketsSortedByProximity returns tickets sorted nearest to farthest', () {
      final appState = AppState();
      final sorted = appState.getTicketsSortedByProximity();

      expect(sorted, isNotEmpty);
      for (int i = 0; i < sorted.length - 1; i++) {
        final distCurrent = appState.getDistanceToTicket(sorted[i]);
        final distNext = appState.getDistanceToTicket(sorted[i + 1]);
        expect(distCurrent, lessThanOrEqualTo(distNext));
      }
    });

    test('getTicketsSortedByProximity filters accurately by blood group', () {
      final appState = AppState();
      final onlyONeg = appState.getTicketsSortedByProximity(bloodGroupFilter: 'O-');

      for (final ticket in onlyONeg) {
        expect(ticket.bloodGroup, equals('O-'));
      }
    });

    test('getTicketsSortedByProximity filters by max radius threshold', () {
      final appState = AppState();
      const radiusLimit = 8.0;
      final nearbyOnly = appState.getTicketsSortedByProximity(maxRadiusKm: radiusLimit);

      for (final ticket in nearbyOnly) {
        final dist = appState.getDistanceToTicket(ticket);
        expect(dist, lessThanOrEqualTo(radiusLimit));
      }
    });

    test('getTicketsSortedByProximity with ALL returns tickets of all blood groups', () {
      final appState = AppState();
      final allFiltered = appState.getTicketsSortedByProximity(bloodGroupFilter: 'ALL');
      expect(allFiltered.length, equals(appState.tickets.length));
    });
  });

  group('Day 6: Offline-First Mode & Connectivity Resiliency', () {
    test('toggleOfflineMode switches simulation state correctly', () {
      final appState = AppState();
      expect(appState.isOfflineModeSimulated, isFalse);

      appState.toggleOfflineMode();
      expect(appState.isOfflineModeSimulated, isTrue);

      appState.toggleOfflineMode();
      expect(appState.isOfflineModeSimulated, isFalse);
    });

    testWidgets('OfflineSyncBanner renders and toggles offline mode on tap', (tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: appState,
              child: const OfflineSyncBanner(),
            ),
          ),
        ),
      );

      expect(find.byType(OfflineSyncBanner), findsOneWidget);
      expect(find.textContaining('CLOUD SYNC ONLINE'), findsOneWidget);
      expect(find.text('SIMULATE OFFLINE'), findsOneWidget);

      await tester.tap(find.text('SIMULATE OFFLINE'));
      await tester.pumpAndSettle();

      expect(appState.isOfflineModeSimulated, isTrue);
      expect(find.textContaining('OFFLINE CACHE ACTIVE'), findsOneWidget);
      expect(find.text('GO ONLINE'), findsOneWidget);
    });
  });

  group('Day 6: Complete End-to-End Clinical Dispatch Lifecycle & Certification', () {
    test('Full End-to-End Simulation: Creation -> Dispatch -> Route -> Arrival -> OTP Bedside Verification -> Medical Stamp', () async {
      final appState = AppState();
      // Ensure donor is eligible
      appState.currentUser = appState.currentUser.copyWith(
        bloodGroup: 'O-',
        lastDonationDate: DateTime.now().subtract(const Duration(days: 100)),
      );

      final initialAuditCount = appState.auditLogs.length;
      final initialDonations = appState.currentUser.donationHistory.length;

      // 1. Hospital creates critical SOS
      await appState.createSosTicket(
        patientName: 'End-to-End Validation Patient',
        bloodGroup: 'O-',
        unitsRequired: 1,
        hospitalName: 'Safdarjung Emergency Trauma Center',
        hospitalAddress: 'Ring Road, New Delhi',
        latitude: 28.5680,
        longitude: 77.2070,
      );

      final newTicket = appState.tickets.first;
      expect(newTicket.status, equals(TicketStatus.pending));
      expect(newTicket.isLocked, isFalse);
      expect(appState.auditLogs.length, equals(initialAuditCount + 1));

      // 2. Compatible donor accepts dispatch
      final accepted = await appState.acceptTicket(newTicket.id);
      expect(accepted, isTrue);
      expect(newTicket.status, equals(TicketStatus.accepted));
      expect(newTicket.isLocked, isTrue);
      expect(appState.activeDispatchTicket?.id, equals(newTicket.id));
      expect(appState.activeRoutePoints, isNotEmpty);

      // 3. Donor engages route transit
      await appState.markEnRoute(newTicket.id);
      expect(newTicket.status, equals(TicketStatus.enRoute));

      // 4. Transit simulator moves donor to bedside (<50m arrival detection)
      appState.startTransitSimulation();
      expect(appState.isTransitSimulating, isTrue);

      // 5. Duty Doctor provides Handover OTP at patient's bedside
      final otp = newTicket.handoverOtp;
      final fulfilled = await appState.verifyAndFulfillHandover(newTicket.id, otp);

      expect(fulfilled, isTrue);
      expect(newTicket.status, equals(TicketStatus.fulfilled));
      expect(newTicket.fulfilledAt, isNotNull);
      expect(appState.isTransitSimulating, isFalse);

      // 6. Medical Safety Passport Verification
      expect(appState.currentUser.donationHistory.length, equals(initialDonations + 1));
      final latestRecord = appState.currentUser.donationHistory.first;
      expect(latestRecord.hospitalName, equals('Safdarjung Emergency Trauma Center'));
      expect(latestRecord.verificationOtp, equals(otp));
      expect(latestRecord.certificateSerial, startsWith('JS-CERT-'));

      // 7. Strict 90-day cooldown activated
      expect(appState.currentUser.isMedicallyEligible, isFalse);
      expect(appState.currentUser.daysUntilEligible, greaterThanOrEqualTo(89));

      // 8. Life-Saver Honor Recognition Tier verified
      expect(appState.currentUser.totalUnitsDonated, greaterThanOrEqualTo(1));
      expect(appState.currentUser.donorBadgeTier, isNot(equals('Active Volunteer 🩸')));
    });
  });
}
