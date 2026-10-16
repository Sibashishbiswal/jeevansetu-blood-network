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
            tooltip: 'Simulate Incoming Emergency',
            icon: const Icon(Icons.flash_on, color: Colors.amberAccent),
            onPressed: () {
              appState.simulateIncomingEmergency();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text('🚨 Simulated Incoming SOS generated near your location!'),
                ),
              );
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
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions_car, color: Colors.redAccent, size: 22),
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
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '${activeTicket.etaMinutes ?? 8} min ETA',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _mapController.move(
                                  LatLng(activeTicket.latitude, activeTicket.longitude),
                                  14.0,
                                );
                              },
                              icon: const Icon(Icons.crop_free, size: 16),
                              label: const Text('View Target'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () => EmergencyTriageSheet.show(context, activeTicket),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activeTicket.status == TicketStatus.enRoute
                                    ? Colors.tealAccent.shade700
                                    : Colors.blue.shade700,
                                foregroundColor: Colors.white,
                              ),
                              icon: Icon(
                                activeTicket.status == TicketStatus.enRoute
                                    ? Icons.verified
                                    : Icons.navigation,
                                size: 18,
                              ),
                              label: Text(
                                activeTicket.status == TicketStatus.enRoute
                                    ? 'VERIFY HANDOVER'
                                    : 'OPEN DISPATCH HUD',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
