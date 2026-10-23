import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sos_ticket.dart';
import '../services/app_state.dart';
import '../widgets/emergency_triage_sheet.dart';

class SosListScreen extends StatelessWidget {
  const SosListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Emergency Blood Feed',
            style: TextStyle(fontWeight: FontWeight.bold),
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
          ],
          bottom: const TabBar(
            indicatorColor: Colors.redAccent,
            labelColor: Colors.redAccent,
            tabs: [
              Tab(icon: Icon(Icons.verified), text: 'Eligible For You'),
              Tab(icon: Icon(Icons.list_alt), text: 'All Active SOS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTicketList(context, appState.eligibleTicketsForDonor, appState, isFiltered: true),
            _buildTicketList(context, appState.tickets, appState, isFiltered: false),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(
    BuildContext context,
    List<SosTicket> tickets,
    AppState appState, {
    required bool isFiltered,
  }) {
    if (tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.health_and_safety_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                isFiltered
                    ? 'No matching emergencies within your radius.'
                    : 'No active blood SOS requests currently.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              Text(
                'Your current blood group: ${appState.currentUser.bloodGroup}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => appState.simulateIncomingEmergency(),
                icon: const Icon(Icons.flash_on, color: Colors.amberAccent, size: 16),
                label: const Text('Simulate Emergency SOS'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tickets.length,
      itemBuilder: (ctx, index) {
        final ticket = tickets[index];
        final distance = appState.getDistanceToTicket(ticket);
        final isMyDispatch = ticket.acceptedDonorName == appState.currentUser.name;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isMyDispatch ? Colors.redAccent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => EmergencyTriageSheet.show(context, ticket),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header: Blood Group, Status Badge, Units
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${ticket.unitsRequired} Units Required',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
                      ),
                      _buildStatusChip(ticket.status),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Hospital and Location Info
                  Text(
                    ticket.hospitalName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ticket.hospitalAddress,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),

                  // Patient Info & Distance
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Patient: ${ticket.patientName}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.near_me, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} km away',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Bottom Action Button / Triage Tap Hint
                  Row(
                    children: [
                      if (appState.currentRole == UserRole.hospital)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Text(
                            'Handover OTP: ${ticket.handoverOtp}',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else if (isMyDispatch && (ticket.status == TicketStatus.accepted || ticket.status == TicketStatus.enRoute))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ETA: ${ticket.etaMinutes ?? 8} min • ${ticket.status == TicketStatus.enRoute ? "En Route" : "Preparing"}',
                            style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        )
                      else
                        Text(
                          'Tap to inspect triage & dispatch details',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(TicketStatus status) {
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
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
