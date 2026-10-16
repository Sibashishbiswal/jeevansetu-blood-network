import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/blood_matrix.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final donor = appState.currentUser;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donor Health & Profile', style: TextStyle(fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 20),

            // 90-Day Medical Safety Cooldown Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: donor.isMedicallyEligible ? Colors.teal.shade50 : Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
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
                                ? 'Last donation was on ${dateFormat.format(donor.lastDonationDate)} (>90 days ago).'
                                : '${donor.daysUntilEligible} days remaining until next safe donation.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                          ),
                        ],
                      ),
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
                      'Test Different Compatibility Modes:',
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
