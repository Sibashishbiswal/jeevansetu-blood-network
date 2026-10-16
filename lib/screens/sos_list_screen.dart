import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sos_ticket.dart';
import '../services/app_state.dart';

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
            'Emergency Blood Requests',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.red,
            labelColor: Colors.red,
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

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                    Text(
                      'Patient: ${ticket.patientName}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                    ),
                    const Spacer(),
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

                // Bottom Action Button
                if (ticket.status == TicketStatus.pending)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.volunteer_activism),
                      label: const Text('Accept & Save Life'),
                      onPressed: () {
                        final ok = appState.acceptTicket(ticket.id);
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.teal.shade800,
                              content: Text('Accepted! En-route to ${ticket.hospitalName}.'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.redAccent,
                              content: Text('Cannot accept: You are in 90-day cooldown or incompatible.'),
                            ),
                          );
                        }
                      },
                    ),
                  )
                else if (ticket.status == TicketStatus.accepted)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.directions_car),
                          label: const Text('Mark En Route'),
                          onPressed: () => appState.markEnRoute(ticket.id),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700),
                          icon: const Icon(Icons.verified),
                          label: const Text('Verify Arrival'),
                          onPressed: () => appState.fulfillTicket(ticket.id),
                        ),
                      ),
                    ],
                  )
                else if (ticket.status == TicketStatus.enRoute)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Hospital Verification (Complete)'),
                      onPressed: () => appState.fulfillTicket(ticket.id),
                    ),
                  )
                else
                  const Center(
                    child: Text(
                      '✓ Fulfilled & Safe',
                      style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
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
