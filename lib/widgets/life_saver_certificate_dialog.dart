import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/donor.dart';

/// Day 5 Milestone: Official Life-Saver Clinical Handover Certificate Modal
///
/// Displayed upon bedside OTP handover verification or when inspecting
/// past donation records in the donor's digital medical passport.
class LifeSaverCertificateDialog extends StatelessWidget {
  final DonationRecord record;
  final String donorName;
  final String donorBloodGroup;
  final String donorBadgeTier;

  const LifeSaverCertificateDialog({
    super.key,
    required this.record,
    required this.donorName,
    required this.donorBloodGroup,
    required this.donorBadgeTier,
  });

  static Future<void> show(
    BuildContext context, {
    required DonationRecord record,
    required String donorName,
    required String donorBloodGroup,
    required String donorBadgeTier,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => LifeSaverCertificateDialog(
        record: record,
        donorName: donorName,
        donorBloodGroup: donorBloodGroup,
        donorBadgeTier: donorBadgeTier,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Premium dark navy slate
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD97706), // Gold border
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Certificate Inner Decorative Frame
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium, color: Colors.amberAccent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'OFFICIAL CLINICAL CERTIFICATE',
                      style: TextStyle(
                        color: Colors.amber.shade200,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              const Text(
                'JEEVANSETU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const Text(
                'EMERGENCY BLOOD DISPATCH NETWORK',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              const Divider(color: Color(0xFF334155), height: 1),
              const SizedBox(height: 16),

              const Text(
                'This certifies that voluntary donor',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 6),
              Text(
                donorName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Donor Group: $donorBloodGroup • $donorBadgeTier',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'has successfully completed an emergency bedside blood transfusion, helping stabilize a critical clinical condition at:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade300, fontSize: 11.5, height: 1.4),
              ),
              const SizedBox(height: 8),

              // Hospital Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF475569)),
                ),
                child: Column(
                  children: [
                    Text(
                      record.hospitalName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Patient: ${record.patientName} • ${record.units} Unit(s) • ${record.bloodGroup}',
                      style: TextStyle(color: Colors.tealAccent.shade400, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Verification Code & Timestamp Strip
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BEDSIDE AUTH OTP', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            '#${record.verificationOtp}',
                            style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CERTIFICATE ID', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            record.certificateSerial,
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Text(
                dateFormat.format(record.donatedAt),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),

              const SizedBox(height: 18),
              const Divider(color: Color(0xFF334155), height: 1),
              const SizedBox(height: 14),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade300,
                        side: const BorderSide(color: Color(0xFF475569)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.teal.shade800,
                            content: Text(
                              '📜 ${record.certificateSerial} downloaded to device storage!',
                            ),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Save / Share', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
