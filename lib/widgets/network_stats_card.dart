import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sos_ticket.dart';
import '../services/app_state.dart';

/// Day 4 Feature: Live Network Health & Statistics Card
///
/// Displays real-time JeevanSetu network metrics:
///   • Total registered donors in the simulation network
///   • Active SOS tickets (pending + en-route)
///   • Total units fulfilled (completed donations)
///   • Computed Network Health Score (0–100)
class NetworkStatsCard extends StatefulWidget {
  const NetworkStatsCard({super.key});

  @override
  State<NetworkStatsCard> createState() => _NetworkStatsCardState();
}

class _NetworkStatsCardState extends State<NetworkStatsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Compute a Network Health Score (0–100) based on:
  ///   • Ratio of fulfilled to total tickets (40 pts max)
  ///   • Number of eligible donors in network (30 pts max)
  ///   • No pending tickets older than 30 min (30 pts max)
  int _computeHealthScore(AppState appState) {
    final tickets = appState.tickets;
    final donors = appState.networkDonors;

    // Metric 1: Fulfillment rate (40 pts)
    final fulfilled = tickets.where((t) => t.status == TicketStatus.fulfilled).length;
    final total = tickets.length;
    final fulfillScore = total == 0 ? 40 : min(40, ((fulfilled / total) * 40).round());

    // Metric 2: Eligible donors available (30 pts)
    final eligibleDonors = donors.where((d) => d.isMedicallyEligible).length;
    final donorScore = min(30, eligibleDonors * 10);

    // Metric 3: No stale pending tickets > 30 min (30 pts)
    final stalePending = tickets.where((t) {
      if (t.status != TicketStatus.pending) return false;
      return DateTime.now().difference(t.createdAt).inMinutes > 30;
    }).length;
    final stalenessScore = max(0, 30 - stalePending * 10);

    return fulfillScore + donorScore + stalenessScore;
  }

  Color _healthColor(int score) {
    if (score >= 80) return const Color(0xFF00C853); // green
    if (score >= 50) return const Color(0xFFFFAB00); // amber
    return const Color(0xFFD50000);                  // red
  }

  String _healthLabel(int score) {
    if (score >= 80) return 'HEALTHY';
    if (score >= 50) return 'MODERATE';
    return 'CRITICAL';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tickets = appState.tickets;
    final donors = appState.networkDonors;

    final activeCount = tickets
        .where((t) => t.status == TicketStatus.pending || t.status == TicketStatus.accepted || t.status == TicketStatus.enRoute)
        .length;
    final fulfilledCount = tickets.where((t) => t.status == TicketStatus.fulfilled).length;
    final unitsFulfilled = tickets
        .where((t) => t.status == TicketStatus.fulfilled)
        .fold<int>(0, (sum, t) => sum + t.unitsFulfilled);
    final eligibleDonors = donors.where((d) => d.isMedicallyEligible).length;
    final healthScore = _computeHealthScore(appState);
    final healthColor = _healthColor(healthScore);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1A1F2E), const Color(0xFF0D1117)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  ),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: healthColor,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: healthColor.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 2)],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'NETWORK HEALTH MONITOR',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: healthColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: healthColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _healthLabel(healthScore),
                    style: TextStyle(
                      color: healthColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Health score bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: healthScore / 100,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$healthScore/100',
                  style: TextStyle(
                    color: healthColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Stats grid
            Row(
              children: [
                _StatTile(
                  icon: Icons.campaign,
                  iconColor: Colors.redAccent,
                  value: '$activeCount',
                  label: 'Active SOS',
                ),
                _StatDivider(),
                _StatTile(
                  icon: Icons.people,
                  iconColor: Colors.blueAccent,
                  value: '${donors.length}',
                  label: 'Network Donors',
                ),
                _StatDivider(),
                _StatTile(
                  icon: Icons.verified_user,
                  iconColor: Colors.tealAccent,
                  value: '$eligibleDonors',
                  label: 'Eligible Now',
                ),
                _StatDivider(),
                _StatTile(
                  icon: Icons.water_drop,
                  iconColor: Colors.pinkAccent,
                  value: '${unitsFulfilled}u ($fulfilledCount)',
                  label: 'Units Saved',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Footer note
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white38, size: 12),
                const SizedBox(width: 6),
                Text(
                  '${appState.tickets.length} total SOS tickets tracked • Offline-first engine',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white12,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}
