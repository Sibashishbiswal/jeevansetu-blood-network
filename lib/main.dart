import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/create_sos_screen.dart';
import 'screens/hospital_desk_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/sos_list_screen.dart';
import 'services/app_state.dart';
import 'widgets/incoming_sos_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Will initialize automatically if GoogleService-Info.plist or google-services.json is present
    await Firebase.initializeApp();
  } catch (_) {
    // Running in offline-first local mode
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const RakshakApp(),
    ),
  );
}

class RakshakApp extends StatelessWidget {
  const RakshakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JeevanSetu - Emergency Blood Network',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F), // Crimson Medical Red
          primary: const Color(0xFFD32F2F),
          secondary: const Color(0xFF00897B), // Medical Teal
          surface: Colors.white,
        ),
        fontFamily: GoogleFonts.inter().fontFamily,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          centerTitle: false,
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  String? _activeDialogAlertId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activeAlertsCount = appState.tickets.where((t) => !t.isLocked).length;
    final isHospital = appState.currentRole == UserRole.hospital;

    // Real-Time Incoming Emergency Broadcast Modal Listener
    final alert = appState.incomingBroadcastAlert;
    if (alert != null && _activeDialogAlertId != alert.id) {
      _activeDialogAlertId = alert.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        IncomingSosDialog.show(context, alert).then((_) {
          _activeDialogAlertId = null;
        });
      });
    }

    final pages = [
      const MapScreen(),
      isHospital
          ? HospitalDeskScreen(
              onOpenCreateSos: () => setState(() => _currentIndex = 2),
            )
          : const SosListScreen(),
      CreateSosScreen(
        onCreated: () {
          setState(() => _currentIndex = 0); // Jump to map on create
        },
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: Colors.red.shade100,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Colors.red),
            label: 'Live Map',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$activeAlertsCount'),
              isLabelVisible: activeAlertsCount > 0,
              child: Icon(isHospital ? Icons.local_hospital_outlined : Icons.notifications_active_outlined),
            ),
            selectedIcon: Badge(
              label: Text('$activeAlertsCount'),
              isLabelVisible: activeAlertsCount > 0,
              child: Icon(isHospital ? Icons.local_hospital : Icons.notifications_active, color: Colors.red),
            ),
            label: isHospital ? 'Hospital Desk' : 'SOS Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle, color: Colors.red),
            label: 'Dispatch SOS',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.red),
            label: 'My Profile',
          ),
        ],
      ),
    );
  }
}
