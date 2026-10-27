import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/audit_log.dart';
import '../services/app_state.dart';

/// Day 5 Milestone: Real-Time Hospital Dispatch Audit Trail & Timeline Widget
///
/// Gives triage physicians and hospital coordinators a transparent,
/// chronological audit log of all emergency events, dispatches, and bedside handovers.
class HospitalAuditTimelineWidget extends StatelessWidget {
  const HospitalAuditTimelineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final auditLogs = appState.auditLogs;
    final timeFormat = DateFormat('h:mm a');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.indigo, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Dispatch Audit Trail (Live)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'AUDIT ACTIVE',
                        style: TextStyle(
                          color: Colors.indigo,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Chronological medico-legal log of all emergency broadcast and bedside events.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
            ),
            const Divider(height: 20),

            if (auditLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'No audit records logged yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: auditLogs.length > 6 ? 6 : auditLogs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final log = auditLogs[index];
                  return _buildAuditItem(log, timeFormat);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditItem(AuditLog log, DateFormat timeFormat) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (log.type) {
      case 'created':
        icon = Icons.emergency_share;
        iconColor = Colors.redAccent;
        bgColor = Colors.red.withValues(alpha: 0.1);
        break;
      case 'accepted':
        icon = Icons.person_pin;
        iconColor = Colors.amber.shade800;
        bgColor = Colors.amber.withValues(alpha: 0.1);
        break;
      case 'transit':
        icon = Icons.directions_car;
        iconColor = Colors.blueAccent;
        bgColor = Colors.blue.withValues(alpha: 0.1);
        break;
      case 'arrival':
        icon = Icons.near_me;
        iconColor = Colors.teal;
        bgColor = Colors.teal.withValues(alpha: 0.1);
        break;
      case 'fulfilled':
        icon = Icons.verified;
        iconColor = Colors.green.shade700;
        bgColor = Colors.green.withValues(alpha: 0.12);
        break;
      case 'cancelled':
        icon = Icons.cancel;
        iconColor = Colors.grey.shade700;
        bgColor = Colors.grey.withValues(alpha: 0.12);
        break;
      default:
        icon = Icons.info_outline;
        iconColor = Colors.indigo;
        bgColor = Colors.indigo.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        log.title,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeFormat.format(log.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  log.details,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade800,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
