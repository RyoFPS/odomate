import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../widgets/loading_skeleton.dart';

class HistoryScreen extends StatelessWidget {
  final OdomateRepository repository;
  const HistoryScreen({super.key, required this.repository});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Riwayat')),
    body: FutureBuilder<_HistoryData>(
      future: _load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoadingSkeleton();
        }
        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (data.rides.isNotEmpty) ...[
              const ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                title: Text('Perjalanan'),
              ),
              ...data.rides.map(
                (ride) => ListTile(
                  leading: const Icon(Icons.route),
                  title: Text('Ride ${ride.distanceKm.toStringAsFixed(1)} km'),
                  subtitle: Text(ride.startedAt.toLocal().toString()),
                ),
              ),
            ],
            if (data.logs.isNotEmpty) ...[
              const ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                title: Text('Servis'),
              ),
              ...data.logs.map(
                (log) => ListTile(
                  leading: const Icon(Icons.build_outlined),
                  title: Text(_date(log.servicedAt)),
                  subtitle: Text('${log.odometerKm.toStringAsFixed(1)} km'),
                ),
              ),
            ],
            if (data.rides.isEmpty && data.logs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Belum ada riwayat.'),
                ),
              ),
          ],
        );
      },
    ),
  );

  Future<_HistoryData> _load() async => _HistoryData(
    await repository.listRides(),
    await repository.listServiceLogs(),
  );
  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _HistoryData {
  final List<Ride> rides;
  final List<ServiceLog> logs;
  const _HistoryData(this.rides, this.logs);
}
