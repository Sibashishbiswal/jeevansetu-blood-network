import 'package:flutter_test/flutter_test.dart';
import 'package:rakshak_blood_network/models/sos_ticket.dart';
import 'package:rakshak_blood_network/services/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Day 3 Milestone: Live Transit Simulation Engine', () {
    test('startTransitSimulation advances waypoints and updates ETA/distance', () async {
      final appState = AppState();
      appState.updateDonorBloodGroup('O-');
      appState.updateDonorProfile(lastDonationDate: DateTime.now().subtract(const Duration(days: 100)));

      // Create an emergency ticket
      await appState.createSosTicket(
        patientName: 'Simulation Test Patient',
        bloodGroup: 'O-',
        unitsRequired: 1,
        hospitalName: 'Apollo Hospital',
        hospitalAddress: 'Sarita Vihar, New Delhi',
        latitude: 28.5398,
        longitude: 77.2917,
      );

      final ticket = appState.tickets.first;
      final accepted = await appState.acceptTicket(ticket.id);
      expect(accepted, isTrue);
      expect(appState.activeRoutePoints.isNotEmpty, isTrue);

      // Verify initial simulation state
      expect(appState.isTransitSimulating, isFalse);
      expect(appState.currentTransitStep, equals(0));
      expect(appState.hasArrivedAtHospital, isFalse);

      // Start transit simulation
      appState.startTransitSimulation();
      expect(appState.isTransitSimulating, isTrue);
      expect(appState.activeDispatchTicket?.status, equals(TicketStatus.enRoute));

      // Pause transit simulation
      appState.pauseTransitSimulation();
      expect(appState.isTransitSimulating, isFalse);

      // Reset transit simulation
      appState.resetTransitSimulation();
      expect(appState.isTransitSimulating, isFalse);
      expect(appState.currentTransitStep, equals(0));
      expect(appState.hasArrivedAtHospital, isFalse);
    });
  });

  group('Day 3 Milestone: Real-Time Incoming Emergency Broadcast Alert', () {
    test('Simulating incoming emergency triggers incomingBroadcastAlert for compatible donor', () {
      final appState = AppState();
      expect(appState.incomingBroadcastAlert, isNull);

      appState.simulateIncomingEmergency();

      expect(appState.incomingBroadcastAlert, isNotNull);
      expect(appState.incomingBroadcastAlert!.patientName, contains('Karan Mehra'));
      expect(appState.incomingBroadcastAlert!.bloodGroup, equals(appState.currentUser.bloodGroup));

      // Dismiss alert
      appState.dismissBroadcastAlert();
      expect(appState.incomingBroadcastAlert, isNull);
    });

    test('Accepting an emergency ticket automatically clears the broadcast alert', () async {
      final appState = AppState();
      appState.updateDonorBloodGroup('O-');
      appState.updateDonorProfile(lastDonationDate: DateTime.now().subtract(const Duration(days: 110)));

      appState.simulateIncomingEmergency();
      final alertId = appState.incomingBroadcastAlert!.id;

      await appState.acceptTicket(alertId);
      expect(appState.incomingBroadcastAlert, isNull);
      expect(appState.activeDispatchTicket?.id, equals(alertId));
    });
  });

  group('Day 3 Milestone: Hospital Command Desk & Role Switching', () {
    test('Toggling role switches between Donor and Hospital Authority', () {
      final appState = AppState();
      expect(appState.currentRole, equals(UserRole.donor));

      appState.toggleRole();
      expect(appState.currentRole, equals(UserRole.hospital));

      appState.toggleRole();
      expect(appState.currentRole, equals(UserRole.donor));
    });

    test('Hospital desk can access Handover OTP for bedside verification', () async {
      final appState = AppState();
      await appState.createSosTicket(
        patientName: 'Ramesh Gupta',
        bloodGroup: 'B+',
        unitsRequired: 2,
        hospitalName: 'Fortis Hospital',
        hospitalAddress: 'Shalimar Bagh, Delhi',
        latitude: 28.7150,
        longitude: 77.1650,
      );

      final ticket = appState.tickets.first;
      expect(ticket.handoverOtp.length, equals(4));
      expect(int.tryParse(ticket.handoverOtp), isNotNull);
    });
  });
}
