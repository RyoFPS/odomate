import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';

class HistoryScreen extends StatelessWidget {
  final OdomateRepository repository;
  const HistoryScreen({super.key, required this.repository});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Riwayat')),
    body: FutureBuilder(
      future: repository.listRides(),
      builder: (_, snapshot) => snapshot.hasData
          ? ListView(
              children: snapshot.data!
                  .map(
                    (r) => ListTile(
                      title: Text('Ride ${r.distanceKm.toStringAsFixed(1)} km'),
                      subtitle: Text(r.startedAt.toLocal().toString()),
                    ),
                  )
                  .toList(),
            )
          : const Center(child: CircularProgressIndicator()),
    ),
  );
}
