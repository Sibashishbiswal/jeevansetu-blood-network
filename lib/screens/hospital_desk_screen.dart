import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sos_ticket.dart';
import '../services/app_state.dart';
import '../widgets/emergency_triage_sheet.dart';
import '../widgets/hospital_audit_timeline.dart';

class HospitalDeskScreen extends StatefulWidget {
  final VoidCallback onOpenCreateSos;

  const HospitalDeskScreen({super.key, required this.onOpenCreateSos});

  @override
  State<HospitalDeskScreen> createState() => _HospitalDeskScreenState();
}

class _HospitalDeskScreenState extends State<HospitalDeskScreen> {
  String _selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allTickets = appState.tickets;

    final pendingCount = allTickets.where((t) => t.status == TicketStatus.pending).length;
    final enRouteCount = allTickets.where((t) => t.status == TicketStatus.accepted || t.status == TicketStatus.enRoute).length;
    final fulfilledCount = allTickets.where((t) => t.status == TicketStatus.fulfilled).length;

    List<SosTicket> filteredTickets = allTickets;
    if (_selectedFilter == 'PENDING') {
      filteredTickets = allTickets.where((t) => t.status == TicketStatus.pending).toList();
    } else if (_selectedFilter == 'EN_ROUTE') {
      filteredTickets = allTickets.where((t) => t.status == TicketStatus.accepted || t.status == TicketStatus.enRoute).toList();
    } else if (_selectedFilter == 'FULFILLED') {
      filteredTickets = allTickets.where((t) => t.status == TicketStatus.fulfilled).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_hospital, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Hospital Command Desk',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Simulate Influx',
            icon: const Icon(Icons.flash_on, color: Colors.amberAccent),
            onPressed: () {
              appState.simulateIncomingEmergency();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text('🚨 Simulated Incoming SOS created!'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Authority Center Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1E293B), Colors.blueGrey.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'VIPS Emergency Medical Center',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'TRIAGE ONLINE',
                          style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Outer Ring Road, Pitampura, New Delhi • Trauma Command',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Metrics Row
                  Row(
                    children: [
                      _buildMetricTile('AWAITING DONOR', '$pendingCount', Colors.redAccent),
                      const SizedBox(width: 8),
                      _buildMetricTile('DONOR EN ROUTE', '$enRouteCount', Colors.amberAccent),
                      const SizedBox(width: 8),
                      _buildMetricTile('FULFILLED', '$fulfilledCount', Colors.tealAccent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All (${allTickets.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('PENDING', 'Awaiting ($pendingCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('EN_ROUTE', 'In-Transit ($enRouteCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('FULFILLED', 'Fulfilled ($fulfilledCount)'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Dispatches Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hospital Emergency Requests (${filteredTickets.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: widget.onOpenCreateSos,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New SOS', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // List of Hospital Tickets
            if (filteredTickets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 48),
                    const SizedBox(height: 8),
                    const Text('No tickets under this status filter.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              ...filteredTickets.map((ticket) => _buildHospitalTicketCard(context, ticket, appState)),

            const SizedBox(height: 18),
            // Day 5 Milestone: Live Clinical Dispatch Audit Trail
            const HospitalAuditTimelineWidget(),
            const SizedBox(height: 70), // Spacing for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.emergency_share),
        label: const Text('DISPATCH SOS 🩸', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: widget.onOpenCreateSos,
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade300, fontSize: 9, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.red.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = key);
      },
    );
  }

  Widget _buildHospitalTicketCard(BuildContext context, SosTicket ticket, AppState appState) {
    final isEnRoute = ticket.status == TicketStatus.accepted || ticket.status == TicketStatus.enRoute;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isEnRoute ? Colors.amber.shade700 : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Blood Group, Units, Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ticket.bloodGroup,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${ticket.unitsRequired} Units Required',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                _buildStatusBadge(ticket.status),
              ],
            ),
            const SizedBox(height: 10),

            // Patient and Triage Notes
            Text(
              ticket.patientName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (ticket.triageNotes.isNotEmpty)
              Text(
                'Notes: ${ticket.triageNotes}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            const SizedBox(height: 10),

            // Responder Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isEnRoute
                    ? Colors.amber.withValues(alpha: 0.12)
                    : ticket.status == TicketStatus.fulfilled
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isEnRoute
                        ? Icons.directions_car
                        : ticket.status == TicketStatus.fulfilled
                            ? Icons.verified
                            : Icons.radar,
                    size: 18,
                    color: isEnRoute
                        ? Colors.amber.shade900
                        : ticket.status == TicketStatus.fulfilled
                            ? Colors.green.shade800
                            : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEnRoute
                          ? 'Responder: ${ticket.acceptedDonorName ?? "Verified Donor"} • ETA: ${ticket.etaMinutes ?? 8} min'
                          : ticket.status == TicketStatus.fulfilled
                              ? 'Fulfilled at Bedside by ${ticket.acceptedDonorName ?? "Donor"}'
                              : 'Searching in ${ticket.radiusKm.toStringAsFixed(1)} km radius...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isEnRoute
                            ? Colors.amber.shade900
                            : ticket.status == TicketStatus.fulfilled
                                ? Colors.green.shade900
                                : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bedside Handover OTP Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BEDSIDE HANDOVER OTP',
                        style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Provide to arriving donor at bedside',
                        style: TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amberAccent),
                    ),
                    child: Text(
                      '#${ticket.handoverOtp}',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (ticket.status != TicketStatus.fulfilled)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => appState.cancelDispatch(ticket.id),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancel Request', style: TextStyle(fontSize: 12)),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => EmergencyTriageSheet.show(context, ticket),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Triage Details', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TicketStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case TicketStatus.pending:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'SOS PENDING';
        break;
      case TicketStatus.accepted:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'ACCEPTED';
        break;
      case TicketStatus.enRoute:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = 'EN ROUTE';
        break;
      case TicketStatus.fulfilled:
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade800;
        label = 'FULFILLED';
        break;
      case TicketStatus.cancelled:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        label = 'CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
