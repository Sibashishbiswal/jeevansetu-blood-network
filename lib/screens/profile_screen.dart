import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/blood_matrix.dart';
import '../widgets/network_stats_card.dart';
import '../widgets/life_saver_certificate_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final donor = appState.currentUser;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Medical Pass & Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Edit Profile Info',
            icon: const Icon(Icons.edit_note),
            onPressed: () => _showEditProfileDialog(context, appState),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Avatar Card
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.red.shade100,
                    child: Text(
                      donor.bloodGroup,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              donor.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              donor.phone,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    donor.donorBadgeTier,
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 90-Day Medical Safety Cooldown Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: donor.isMedicallyEligible ? Colors.teal.shade50 : Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          donor.isMedicallyEligible ? Icons.check_circle : Icons.timer,
                          color: donor.isMedicallyEligible ? Colors.teal.shade800 : Colors.amber.shade900,
                          size: 32,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                donor.isMedicallyEligible
                                    ? 'Medically Eligible to Donate'
                                    : 'Medical Cooldown Active',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: donor.isMedicallyEligible ? Colors.teal.shade900 : Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                donor.isMedicallyEligible
                                    ? 'Last donation was >90 days ago. You can safely accept emergency dispatches.'
                                    : '${donor.daysUntilEligible} days remaining until next safe donation.',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Testing Toggle: Toggle Cooldown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            final newDate = donor.isMedicallyEligible
                                ? DateTime.now().subtract(const Duration(days: 20)) // into cooldown
                                : DateTime.now().subtract(const Duration(days: 105)); // eligible
                            appState.updateDonorProfile(lastDonationDate: newDate);
                          },
                          icon: const Icon(Icons.bolt, size: 16),
                          label: Text(
                            donor.isMedicallyEligible ? 'Simulate In Cooldown' : 'Simulate Eligible Now',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Live Testing Helper: Switch Blood Group
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Simulate Blood Group Compatibility:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: BloodMatrix.allGroups.map((group) {
                        final isSelected = donor.bloodGroup == group;
                        return ChoiceChip(
                          label: Text(group),
                          selected: isSelected,
                          selectedColor: Colors.red.shade700,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              appState.updateDonorBloodGroup(group);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Clinical Compatibility Matrix Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.biotech, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Clinical Compatibility Matrix',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildCompatibilityRow(
                      'Can donate red blood cells to:',
                      BloodMatrix.allGroups
                          .where((g) => BloodMatrix.isCompatible(donor.bloodGroup, g))
                          .join(', '),
                      Colors.teal.shade700,
                    ),
                    const SizedBox(height: 10),
                    _buildCompatibilityRow(
                      'Can receive blood from:',
                      BloodMatrix.getCompatibleDonorsFor(donor.bloodGroup).join(', '),
                      Colors.blue.shade800,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Verified Donation History (Day 2 Milestone)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history_edu, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Text(
                          'My Verified Donation Passport (${donor.donationHistory.length})',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (donor.donationHistory.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No donations logged yet. Complete an emergency SOS dispatch to receive your verified digital stamp.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    else
                      ...donor.donationHistory.map(
                        (record) => InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            LifeSaverCertificateDialog.show(
                              context,
                              record: record,
                              donorName: donor.name,
                              donorBloodGroup: donor.bloodGroup,
                              donorBadgeTier: donor.donorBadgeTier,
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.teal,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.workspace_premium, color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.hospitalName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        'Patient: ${record.patientName} (${record.bloodGroup})',
                                        style: const TextStyle(color: Colors.black87, fontSize: 12),
                                      ),
                                      Text(
                                        dateFormat.format(record.donatedAt),
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'OTP #${record.verificationOtp}',
                                        style: TextStyle(
                                          color: Colors.teal.shade900,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.open_in_new, size: 11, color: Colors.teal),
                                        SizedBox(width: 2),
                                        Text('Certificate', style: TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
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
              ),
            ),
            const SizedBox(height: 16),

            // Day 4 Feature: Live Network Health & Statistics
            const NetworkStatsCard(),
            const SizedBox(height: 24),

            // Role Toggle (Demonstration helper)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.swap_horiz),
              label: Text(
                'Current Mode: ${appState.currentRole == UserRole.donor ? "Donor View" : "Hospital Authority View"}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                appState.toggleRole();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 1),
                    content: Text(
                      'Switched to ${appState.currentRole == UserRole.donor ? "Donor View" : "Hospital Authority View"}',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AppState appState) {
    final nameCtrl = TextEditingController(text: appState.currentUser.name);
    final phoneCtrl = TextEditingController(text: appState.currentUser.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Donor Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              appState.updateDonorProfile(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityRow(String title, String groups, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          groups.isEmpty ? 'None' : groups,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

