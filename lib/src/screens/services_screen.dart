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
  final nameController = TextEditingController();
  final intervalController = TextEditingController();
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
  void dispose() {
    nameController.dispose();
    intervalController.dispose();
    super.dispose();
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
                onLongPress: () => _serviceActions(s),
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
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tambah servis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama servis'),
            ),
            TextField(
              controller: intervalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Interval (km)'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    final km = double.tryParse(intervalController.text) ?? 0;
                    if (nameController.text.trim().isNotEmpty && km > 0) {
                      Navigator.pop(context, [
                        nameController.text.trim(),
                        intervalController.text,
                      ]);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  Future<void> _serviceActions(ServiceItem service) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit servis'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Hapus servis'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'edit') await _editService(service);
    if (action == 'delete') await _confirmDelete(service);
  }

  Future<void> _editService(ServiceItem service) async {
    nameController.text = service.name;
    intervalController.text = service.intervalKm.toStringAsFixed(0);
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit servis', style: Theme.of(context).textTheme.titleLarge),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama servis'),
            ),
            TextField(
              controller: intervalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Interval (km)'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    final km = double.tryParse(intervalController.text) ?? 0;
                    if (nameController.text.trim().isNotEmpty && km > 0) {
                      Navigator.pop(context, [
                        nameController.text.trim(),
                        intervalController.text,
                      ]);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (result == null || service.id == null) return;
    await widget.repository.saveService(
      ServiceItem(
        id: service.id,
        name: result[0],
        intervalKm: double.parse(result[1]),
        lastServicedOdometerKm: service.lastServicedOdometerKm,
      ),
    );
    await _load();
  }

  Future<void> _confirmDelete(ServiceItem service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus kategori servis?'),
        content: Text('Apakah Anda yakin ingin menghapus ${service.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && service.id != null) {
      await widget.repository.deleteService(service.id!);
      await _load();
    }
  }
}
