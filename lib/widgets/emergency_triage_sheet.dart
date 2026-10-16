import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sos_ticket.dart';
import '../services/app_state.dart';
import '../services/blood_matrix.dart';

class EmergencyTriageSheet extends StatefulWidget {
  final SosTicket ticket;

  const EmergencyTriageSheet({super.key, required this.ticket});

  static void show(BuildContext context, SosTicket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmergencyTriageSheet(ticket: ticket),
    );
  }

  @override
  State<EmergencyTriageSheet> createState() => _EmergencyTriageSheetState();
}

class _EmergencyTriageSheetState extends State<EmergencyTriageSheet> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifyingOtp = false;
  String? _otpError;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    // Look up latest state of this ticket from appState
    final ticket = appState.tickets.firstWhere(
      (t) => t.id == widget.ticket.id,
      orElse: () => widget.ticket,
    );

    final distanceKm = appState.getDistanceToTicket(ticket);
    final isCompatible = BloodMatrix.isCompatible(appState.currentUser.bloodGroup, ticket.bloodGroup);
    final isMedicallyEligible = appState.currentUser.isMedicallyEligible;
    final isHospitalRole = appState.currentRole == UserRole.hospital;
    final isMyDispatch = ticket.acceptedDonorName == appState.currentUser.name;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Emergency Status Row
            Row(
              children: [
                _buildStatusBadge(ticket.status),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on, color: Colors.redAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${ticket.radiusKm.toStringAsFixed(1)} KM RADAR',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Patient & Hospital Header
            Text(
              ticket.patientName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.local_hospital, color: Colors.redAccent, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ticket.hospitalName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              ticket.hospitalAddress,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 14),

            // Blood Group & Distance Stats Grid
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    label: 'BLOOD NEEDED',
                    value: ticket.bloodGroup,
                    color: Colors.redAccent,
                    isLarge: true,
                  ),
                  Container(width: 1, height: 36, color: Colors.white12),
                  _buildStatItem(
                    label: 'UNITS',
                    value: '${ticket.unitsRequired} Unit(s)',
                    color: Colors.white,
                  ),
                  Container(width: 1, height: 36, color: Colors.white12),
                  _buildStatItem(
                    label: 'DISTANCE',
                    value: '${distanceKm.toStringAsFixed(1)} km',
                    color: Colors.orangeAccent,
                  ),
                  Container(width: 1, height: 36, color: Colors.white12),
                  _buildStatItem(
                    label: 'EST. TRANSIT',
                    value: '${ticket.etaMinutes ?? ((distanceKm / 30 * 60).round().clamp(3, 120))} min',
                    color: Colors.greenAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Triage Notes & Ward
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes, color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Triage Note: ${ticket.triageNotes}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Handover OTP Section (Hospital Desk vs Donor Bedside)
            if (isHospitalRole)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_user, color: Colors.amberAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Hospital Bedside Verification Code:',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'OTP: ${ticket.handoverOtp}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Share this 4-digit code with the arriving voluntary donor to verify blood donation handover.',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              )
            else if (isMyDispatch && (ticket.status == TicketStatus.accepted || ticket.status == TicketStatus.enRoute))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.pin, color: Colors.tealAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Hospital Arrival Handover',
                          style: TextStyle(
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'When you reach the patient bed, ask the nurse/attendant for the 4-digit Handover OTP:',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 6,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '####',
                              hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 4),
                              filled: true,
                              fillColor: const Color(0xFF0D1117),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.5)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.3)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _isVerifyingOtp ? null : () => _handleVerifyOtp(appState, ticket),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          icon: _isVerifyingOtp
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check_circle, size: 18),
                          label: const Text('Verify Handover'),
                        ),
                      ],
                    ),
                    if (_otpError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _otpError!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 18),

            // Action Buttons
            if (isHospitalRole)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close Triage Sheet'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                ),
              )
            else if (ticket.status == TicketStatus.pending) ...[
              if (!isCompatible)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '⚠️ Incompatible: Your ${appState.currentUser.bloodGroup} blood cannot be given to ${ticket.bloodGroup}.',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                )
              else if (!isMedicallyEligible)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '⏳ Medical Cooldown: You donated recently. Eligible in ${appState.currentUser.daysUntilEligible} days.',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final success = await appState.acceptTicket(ticket.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: success ? Colors.green.shade800 : Colors.red.shade800,
                            content: Text(
                              success
                                  ? '🚑 Dispatch Accepted! Route polyline plotted on map.'
                                  : 'Could not accept ticket (locked or claimed).',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.directions_run),
                    label: const Text(
                      'ACCEPT EMERGENCY DISPATCH 🩸',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
            ] else if (isMyDispatch && ticket.status == TicketStatus.accepted) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await appState.cancelDispatch(ticket.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 16),
                      label: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await appState.markEnRoute(ticket.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.blueAccent,
                              content: Text('🚗 Marked En Route! Hospital alerted of your transit.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.navigation),
                      label: const Text('MARK EN ROUTE 🚗'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (ticket.status == TicketStatus.fulfilled) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '✅ This emergency request has been fulfilled. Life saved!',
                    style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleVerifyOtp(AppState appState, SosTicket ticket) async {
    final entered = _otpController.text.trim();
    if (entered.length != 4) {
      setState(() => _otpError = 'Please enter the 4-digit code provided by hospital.');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _otpError = null;
    });

    final success = await appState.verifyAndFulfillHandover(ticket.id, entered);

    if (!mounted) return;
    setState(() => _isVerifyingOtp = false);
    if (success) {
      Navigator.pop(context); // Close sheet
      _showCelebrationDialog(context, ticket);
    } else {
      setState(() => _otpError = 'Invalid OTP code! Please check with triage desk.');
    }
  }

  void _showCelebrationDialog(BuildContext ctx, SosTicket ticket) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('Heroic Life Saved! 🩸', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thank you, Sibashish! Your blood handover at ${ticket.hospitalName} was successfully verified.',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
              ),
              child: const Text(
                '• Added to your Official Medical Pass\n• 90-day clinical cooldown is now active to safeguard your health.',
                style: TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('View Medical Pass', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TicketStatus status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case TicketStatus.pending:
        bg = Colors.red.withValues(alpha: 0.2);
        fg = Colors.redAccent;
        label = 'EMERGENCY PENDING';
        icon = Icons.warning_amber_rounded;
        break;
      case TicketStatus.accepted:
        bg = Colors.amber.withValues(alpha: 0.2);
        fg = Colors.amberAccent;
        label = 'ACCEPTED - PREPARING';
        icon = Icons.thumb_up_alt_rounded;
        break;
      case TicketStatus.enRoute:
        bg = Colors.blue.withValues(alpha: 0.2);
        fg = Colors.blueAccent;
        label = 'DONOR EN ROUTE 🚗';
        icon = Icons.directions_car_rounded;
        break;
      case TicketStatus.fulfilled:
        bg = Colors.green.withValues(alpha: 0.2);
        fg = Colors.greenAccent;
        label = 'FULFILLED & HANDED OVER';
        icon = Icons.check_circle_rounded;
        break;
      case TicketStatus.cancelled:
        bg = Colors.grey.withValues(alpha: 0.2);
        fg = Colors.grey;
        label = 'CANCELLED';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    bool isLarge = false,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isLarge ? 20 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 0.5),
        ),
      ],
    );
  }
}
