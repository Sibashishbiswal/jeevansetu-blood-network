import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

/// Day 6 Milestone: Live Offline-First Resilience & Cloud Sync Banner
///
/// Demonstrates that JeevanSetu operates with zero data loss in disconnected
/// trauma environments, gracefully toggling between local cache and cloud sync.
class OfflineSyncBanner extends StatelessWidget {
  const OfflineSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isOffline = appState.isOfflineModeSimulated;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isOffline ? const Color(0xFF78350F) : const Color(0xFF064E3B),
        border: Border(
          bottom: BorderSide(
            color: isOffline ? Colors.amber.withValues(alpha: 0.4) : Colors.tealAccent.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.wifi_off : Icons.cloud_done,
            size: 14,
            color: isOffline ? Colors.amberAccent : Colors.tealAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOffline
                  ? 'OFFLINE CACHE ACTIVE • Local Storage Engaged'
                  : 'CLOUD SYNC ONLINE • Zero-Latency Dispatch Mesh',
              style: TextStyle(
                color: isOffline ? Colors.amber.shade100 : Colors.teal.shade100,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () {
              appState.toggleOfflineMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  backgroundColor: isOffline ? Colors.teal.shade800 : Colors.amber.shade900,
                  content: Text(
                    isOffline
                        ? '🟢 Cloud Sync Reconnected!'
                        : '🟡 Offline Mode Simulated - Local Cache Active',
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOffline ? Colors.amberAccent.withValues(alpha: 0.5) : Colors.tealAccent.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                isOffline ? 'GO ONLINE' : 'SIMULATE OFFLINE',
                style: TextStyle(
                  color: isOffline ? Colors.amberAccent : Colors.tealAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
