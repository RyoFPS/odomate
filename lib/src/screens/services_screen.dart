import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/service_schedule.dart';

class ServicesScreen extends StatefulWidget {
  final OdomateRepository repository;
  const ServicesScreen({super.key, required this.repository});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<ServiceItem> items = [];
  double odo = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    items = await widget.repository.listServices();
    if (items.isEmpty) {
      final vehicle = await widget.repository.loadVehicle();
      if (vehicle != null) {
        for (final service in _defaultServices(vehicle.odometerKm)) {
          await widget.repository.saveService(service);
        }
        items = await widget.repository.listServices();
      }
    }
    odo = (await widget.repository.loadVehicle())?.odometerKm ?? 0;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Servis'),
      actions: [
        IconButton(
          onPressed: _addService,
          icon: const Icon(Icons.add),
          tooltip: 'Tambah servis',
        ),
      ],
    ),
    body: items.isEmpty
        ? const Center(
            child: Text('Belum ada daftar servis. Tekan + untuk menambah.'),
          )
        : ListView(
            children: items.map((s) {
              final status = ServiceSchedule.status(odo, s);
              return ListTile(
                title: Text(s.name),
                subtitle: Text(
                  status == ServiceStatus.due
                      ? 'Jatuh tempo'
                      : status == ServiceStatus.dueSoon
                      ? 'Mendekat'
                      : 'Aman',
                ),
                trailing: Text(
                  '${(s.lastServicedOdometerKm + s.intervalKm - odo).toStringAsFixed(0)} km',
                ),
              );
            }).toList(),
          ),
  );

  List<ServiceItem> _defaultServices(double km) => [
    ServiceItem(
      name: 'Oli mesin',
      intervalKm: 2000,
      lastServicedOdometerKm: km,
    ),
    ServiceItem(
      name: 'Oli gardan',
      intervalKm: 8000,
      lastServicedOdometerKm: km,
    ),
    ServiceItem(name: 'Busi', intervalKm: 8000, lastServicedOdometerKm: km),
    ServiceItem(
      name: 'Filter udara',
      intervalKm: 12000,
      lastServicedOdometerKm: km,
    ),
  ];

  Future<void> _addService() async {
    final name = TextEditingController();
    final interval = TextEditingController();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah servis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nama servis'),
            ),
            TextField(
              controller: interval,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Interval (km)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final km = double.tryParse(interval.text) ?? 0;
              if (name.text.trim().isNotEmpty && km > 0) {
                Navigator.pop(context, [name.text.trim(), interval.text]);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    name.dispose();
    interval.dispose();
    if (result == null) return;
    final vehicle = await widget.repository.loadVehicle();
    await widget.repository.saveService(
      ServiceItem(
        name: result[0],
        intervalKm: double.parse(result[1]),
        lastServicedOdometerKm: vehicle?.odometerKm ?? 0,
      ),
    );
    await _load();
  }
}
