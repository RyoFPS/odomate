import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../tracking/ride_tracker.dart';
import 'services_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  final OdomateRepository repository;
  final RideTracker tracker;
  const HomeScreen({
    super.key,
    required this.repository,
    required this.tracker,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double odo = 0;
  String vehicleName = '';
  int serviceCount = 0;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final vehicle = await widget.repository.loadVehicle();
    final services = await widget.repository.listServices();
    if (!mounted) return;
    setState(() {
      odo = vehicle?.odometerKm ?? 0;
      vehicleName = vehicle?.name ?? '';
      serviceCount = services.length;
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_greeting(), style: Theme.of(context).textTheme.bodySmall),
          Text(vehicleName.isEmpty ? 'OdoMate' : vehicleName),
        ],
      ),
    ),
    body: ValueListenableBuilder<RideTrackingState>(
      valueListenable: widget.tracker.state,
      builder: (context, state, child) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Odometer saat ini',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${odo.toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                state.active ? Icons.gps_fixed : Icons.gps_not_fixed,
              ),
              title: Text(
                state.active ? 'Ride sedang aktif' : 'Belum ada ride aktif',
              ),
              subtitle: state.active
                  ? Text(
                      '${state.ride!.distanceKm.toStringAsFixed(1)} km tercatat',
                    )
                  : const Text('Tekan tombol tengah untuk mulai'),
            ),
          ),
          if (state.error != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(state.error!),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.build_outlined),
              title: const Text('Jadwal servis'),
              subtitle: Text('\$serviceCount item servis tersimpan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServicesScreen(repository: widget.repository),
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Riwayat perjalanan'),
              subtitle: const Text('Lihat perjalanan yang sudah tersimpan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryScreen(repository: widget.repository),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
