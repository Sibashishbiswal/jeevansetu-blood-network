import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/sos_ticket.dart';
import '../services/app_state.dart';
import '../widgets/emergency_triage_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activeTicket = appState.activeDispatchTicket;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emergency, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JeevanSetu Live Radar',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: appState.isCloudConnected ? Colors.greenAccent : Colors.orangeAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      appState.isCloudConnected ? 'Cloud Sync Online' : 'Offline-First Engine',
                      style: TextStyle(
                        fontSize: 11,
                        color: appState.isCloudConnected ? Colors.greenAccent : Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Switch Mode (${appState.currentRole == UserRole.donor ? "Donor Mode" : "Hospital Mode"})',
            icon: Icon(
              appState.currentRole == UserRole.donor ? Icons.local_hospital_outlined : Icons.person_outline,
              color: appState.currentRole == UserRole.donor ? Colors.redAccent : Colors.tealAccent,
            ),
            onPressed: () {
              appState.toggleRole();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  content: Text(
                    'Switched to ${appState.currentRole == UserRole.donor ? "Donor View" : "Hospital Authority View"}',
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Simulate Incoming Emergency',
            icon: const Icon(Icons.flash_on, color: Colors.amberAccent),
            onPressed: () {
              appState.simulateIncomingEmergency();
            },
          ),
          IconButton(
            tooltip: 'Re-center GPS Location',
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController.move(appState.currentLocation, 13.5);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: appState.currentLocation,
              initialZoom: 13.0,
              minZoom: 4.0,
              maxZoom: 18.0,
            ),
            children: [
              // Free OpenStreetMap Tile Layer (Zero Cost)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jeevansetu.blood_network',
              ),

              // Active Emergency Road Route Polyline Layer
              if (appState.activeRoutePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: appState.activeRoutePoints,
                      strokeWidth: 5.5,
                      color: Colors.redAccent,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.8,
                    ),
                  ],
                ),

              // SOS Emergency Dispatch Radius Circles
              CircleLayer(
                circles: appState.tickets
                    .where((t) => !t.isLocked)
                    .map(
                      (ticket) => CircleMarker(
                        point: LatLng(ticket.latitude, ticket.longitude),
                        radius: ticket.radiusKm * 1000,
                        useRadiusInMeter: true,
                        color: Colors.red.withValues(alpha: 0.10),
                        borderColor: Colors.red.withValues(alpha: 0.4),
                        borderStrokeWidth: 1.5,
                      ),
                    )
                    .toList(),
              ),

              // Markers Layer: Current User, Hospitals, Community Donors
              MarkerLayer(
                markers: [
                  // 1. Current User Marker
                  Marker(
                    point: appState.currentLocation,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade900,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            appState.currentUser.bloodGroup,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                  ),

                  // 2. Active Hospital SOS Markers
                  ...appState.tickets.where((t) => !t.isLocked).map(
                    (ticket) => Marker(
                      point: LatLng(ticket.latitude, ticket.longitude),
                      width: 80,
                      height: 75,
                      child: GestureDetector(
                        onTap: () => EmergencyTriageSheet.show(context, ticket),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: ticket.status == TicketStatus.accepted || ticket.status == TicketStatus.enRoute
                                    ? Colors.blue.shade700
                                    : Colors.red.shade700,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4),
                                ],
                              ),
                              child: Text(
                                ticket.status == TicketStatus.enRoute
                                    ? 'EN ROUTE 🚗'
                                    : '${ticket.bloodGroup} NEEDED',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: ticket.status == TicketStatus.enRoute
                                    ? Colors.blue.shade600
                                    : Colors.red.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.local_hospital, color: Colors.white, size: 24),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Simulated Nearby Donors in the Network
                  ...appState.networkDonors.map(
                    (donor) => Marker(
                      point: LatLng(donor.latitude, donor.longitude),
                      width: 50,
                      height: 50,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: donor.isMedicallyEligible ? Colors.teal.shade600 : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Text(
                              donor.bloodGroup,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Top Info Banner: Quick Eligibility Pill
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: const Color(0xFF161B22).withValues(alpha: 0.92),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          appState.currentUser.isMedicallyEligible ? Icons.verified : Icons.timelapse,
                          color: appState.currentUser.isMedicallyEligible ? Colors.tealAccent : Colors.orangeAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${appState.currentUser.name} (${appState.currentUser.bloodGroup})',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${appState.eligibleTicketsForDonor.length} match you',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // In-Transit Dispatch HUD Overlay Card (Active Dispatch Mode)
          if (activeTicket != null)
            Positioned(
              bottom: 16,
              left: 14,
              right: 14,
              child: Card(
                elevation: 8,
                color: const Color(0xFF161B22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: appState.hasArrivedAtHospital ? Colors.tealAccent : Colors.redAccent,
                    width: 1.8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row: Hospital, Patient, Live ETA & Distance
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (appState.hasArrivedAtHospital ? Colors.teal : Colors.red).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              appState.hasArrivedAtHospital ? Icons.local_hospital : Icons.directions_car,
                              color: appState.hasArrivedAtHospital ? Colors.tealAccent : Colors.redAccent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeTicket.hospitalName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Patient: ${activeTicket.patientName} (${activeTicket.bloodGroup})',
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (appState.hasArrivedAtHospital ? Colors.tealAccent : Colors.greenAccent).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (appState.hasArrivedAtHospital ? Colors.tealAccent : Colors.greenAccent).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              appState.hasArrivedAtHospital
                                  ? 'ARRIVED 🏥'
                                  : '${appState.simulatedDistanceRemainingKm > 0 ? "${appState.simulatedDistanceRemainingKm.toStringAsFixed(1)} km • " : ""}${appState.activeEtaMinutes ?? 8} min ETA',
                              style: TextStyle(
                                color: appState.hasArrivedAtHospital ? Colors.tealAccent : Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Transit Progress Bar
                      if (appState.activeRoutePoints.length > 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: appState.hasArrivedAtHospital
                                  ? 1.0
                                  : appState.currentTransitStep / (appState.activeRoutePoints.length - 1),
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                appState.hasArrivedAtHospital ? Colors.tealAccent : Colors.redAccent,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ),

                      // Arrival Banner if reached hospital bedside
                      if (appState.hasArrivedAtHospital)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified, color: Colors.tealAccent, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ARRIVED AT HOSPITAL BEDSIDE! Tap "Verify Handover" to enter 4-digit code.',
                                  style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Simulation Controls Row (Day 3 Feature)
                      Row(
                        children: [
                          // Live Transit Simulation Button
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appState.isTransitSimulating
                                    ? Colors.amber.shade900
                                    : appState.hasArrivedAtHospital
                                        ? Colors.teal.shade800
                                        : Colors.blueGrey.shade800,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: Icon(
                                appState.isTransitSimulating
                                    ? Icons.pause
                                    : appState.hasArrivedAtHospital
                                        ? Icons.replay
                                        : Icons.play_arrow,
                                size: 18,
                              ),
                              label: Text(
                                appState.isTransitSimulating
                                    ? 'PAUSE (${appState.currentTransitStep + 1}/${appState.activeRoutePoints.length})'
                                    : appState.hasArrivedAtHospital
                                        ? 'RESTART TRANSIT'
                                        : 'SIMULATE LIVE TRANSIT 🚗',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                if (appState.isTransitSimulating) {
                                  appState.pauseTransitSimulation();
                                } else {
                                  appState.startTransitSimulation();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Open Handover Verification / Triage HUD Button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () => EmergencyTriageSheet.show(context, activeTicket),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activeTicket.status == TicketStatus.enRoute
                                    ? Colors.tealAccent.shade700
                                    : Colors.redAccent.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: Icon(
                                activeTicket.status == TicketStatus.enRoute
                                    ? Icons.verified
                                    : Icons.navigation,
                                size: 16,
                              ),
                              label: Text(
                                activeTicket.status == TicketStatus.enRoute
                                    ? 'VERIFY OTP'
                                    : 'DISPATCH HUD',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
