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
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final v = await widget.repository.loadVehicle();
    if (mounted) setState(() => odo = v?.odometerKm ?? 0);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('OdoMate')),
    body: ValueListenableBuilder<RideTrackingState>(
      valueListenable: widget.tracker.state,
      builder: (context, s, child) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '${odo.toStringAsFixed(1)} km',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const Text('Odometer saat ini'),
          if (s.error != null)
            Text(s.error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              if (s.active) {
                await widget.tracker.stop();
                await _refresh();
              } else {
                await widget.tracker.start();
              }
              setState(() {});
            },
            child: Text(s.active ? 'Stop Ride' : 'Start Ride'),
          ),
          if (s.active)
            Text('Jarak ride: ${s.ride!.distanceKm.toStringAsFixed(1)} km'),
          ListTile(
            title: const Text('Servis'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServicesScreen(repository: widget.repository),
              ),
            ),
          ),
          ListTile(
            title: const Text('Riwayat'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryScreen(repository: widget.repository),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
