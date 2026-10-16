import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/blood_matrix.dart';

class CreateSosScreen extends StatefulWidget {
  final VoidCallback onCreated;

  const CreateSosScreen({super.key, required this.onCreated});

  @override
  State<CreateSosScreen> createState() => _CreateSosScreenState();
}

class _CreateSosScreenState extends State<CreateSosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _hospitalNameController = TextEditingController(text: 'VIPS Emergency Medical Center');
  final _hospitalAddressController = TextEditingController(text: 'Outer Ring Road, Pitampura, New Delhi');

  String _selectedBloodGroup = 'O-';
  int _units = 2;
  double _radiusKm = 6.0;

  @override
  void dispose() {
    _patientNameController.dispose();
    _hospitalNameController.dispose();
    _hospitalAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hospital Emergency Dispatch',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Broadcasting an SOS triggers immediate geo-fenced push alerts to nearby verified donors.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Patient Name
              TextFormField(
                controller: _patientNameController,
                decoration: const InputDecoration(
                  labelText: 'Patient Full Name & Ward/Bed',
                  hintText: 'e.g. Ramesh Kumar (Trauma OT-2)',
                  prefixIcon: Icon(Icons.person_pin),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter patient name' : null,
              ),
              const SizedBox(height: 16),

              // Blood Group & Units Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedBloodGroup,
                      decoration: const InputDecoration(
                        labelText: 'Required Blood Group',
                        border: OutlineInputBorder(),
                      ),
                      items: BloodMatrix.allGroups.map((g) {
                        return DropdownMenuItem(value: g, child: Text(g));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBloodGroup = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<int>(
                      initialValue: _units,
                      decoration: const InputDecoration(
                        labelText: 'Units',
                        border: OutlineInputBorder(),
                      ),
                      items: [1, 2, 3, 4, 5].map((u) {
                        return DropdownMenuItem(value: u, child: Text('$u Units'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _units = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Hospital Name
              TextFormField(
                controller: _hospitalNameController,
                decoration: const InputDecoration(
                  labelText: 'Hospital Name',
                  prefixIcon: Icon(Icons.local_hospital),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter hospital name' : null,
              ),
              const SizedBox(height: 16),

              // Hospital Address
              TextFormField(
                controller: _hospitalAddressController,
                decoration: const InputDecoration(
                  labelText: 'Hospital Address / Floor',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter address' : null,
              ),
              const SizedBox(height: 20),

              // Dispatch Radius Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Emergency Dispatch Radius:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_radiusKm.toStringAsFixed(1)} KM',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _radiusKm,
                min: 2.0,
                max: 15.0,
                divisions: 13,
                activeColor: Colors.red.shade700,
                label: '${_radiusKm.toInt()} km',
                onChanged: (val) => setState(() => _radiusKm = val),
              ),
              const SizedBox(height: 24),

              // Broadcast Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.emergency_share, size: 24),
                  label: const Text(
                    'BROADCAST EMERGENCY SOS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      appState.createSosTicket(
                        patientName: _patientNameController.text.trim(),
                        bloodGroup: _selectedBloodGroup,
                        unitsRequired: _units,
                        hospitalName: _hospitalNameController.text.trim(),
                        hospitalAddress: _hospitalAddressController.text.trim(),
                        latitude: appState.currentLocation.latitude + 0.005,
                        longitude: appState.currentLocation.longitude + 0.005,
                        radiusKm: _radiusKm,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.teal.shade800,
                          content: Text(
                            'SOS Broadcast Sent! Matched nearby donors within ${_radiusKm.toInt()} km.',
                          ),
                        ),
                      );

                      widget.onCreated();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
