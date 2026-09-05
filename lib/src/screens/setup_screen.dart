import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';

class SetupScreen extends StatefulWidget {
  final OdomateRepository repository;
  final VoidCallback onSaved;
  const SetupScreen({
    super.key,
    required this.repository,
    required this.onSaved,
  });
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final name = TextEditingController();
  final odo = TextEditingController(text: '0');
  String? error;
  Future<void> save() async {
    final km = double.tryParse(odo.text);
    if (name.text.trim().isEmpty || km == null || km < 0) {
      setState(() => error = 'Isi nama motor dan odometer yang valid.');
      return;
    }
    await widget.repository.saveVehicle(
      Vehicle(name: name.text.trim(), odometerKm: km),
    );
    for (final n in ['Oli mesin', 'Oli gardan', 'Busi', 'Filter udara']) {
      await widget.repository.saveService(
        ServiceItem(name: n, intervalKm: 1000, lastServicedOdometerKm: km),
      );
    }
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Siapkan OdoMate')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nama motor'),
          ),
          TextField(
            controller: odo,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Odometer awal (km)'),
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 20),
          FilledButton(onPressed: save, child: const Text('Simpan dan mulai')),
        ],
      ),
    ),
  );
}
