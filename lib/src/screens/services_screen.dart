import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/service_schedule.dart';

class ServicesScreen extends StatefulWidget {
  final OdomateRepository repository;
  final VoidCallback? onBack;
  const ServicesScreen({super.key, required this.repository, this.onBack});
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
    odo = (await widget.repository.loadVehicle())?.odometerKm ?? 0;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Servis'),
      leading: widget.onBack == null
          ? null
          : BackButton(onPressed: widget.onBack),
    ),
    body: ListView(
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
}
