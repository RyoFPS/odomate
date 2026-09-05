import 'dart:io';

import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/service_schedule.dart';
import '../i18n/app_localizations.dart';
import '../tracking/ride_tracker.dart';

class HomeScreen extends StatefulWidget {
  final OdomateRepository repository;
  final RideTracker tracker;
  final ValueChanged<int>? onNavigate;
  const HomeScreen({
    super.key,
    required this.repository,
    required this.tracker,
    this.onNavigate,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Vehicle? vehicle;
  List<ServiceItem> services = [];
  double todayDistance = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final value = await widget.repository.loadVehicle();
    final serviceItems = await widget.repository.listServices();
    final rides = await widget.repository.listRides();
    final now = DateTime.now();
    final distance = rides
        .where(
          (r) =>
              r.startedAt.toLocal().year == now.year &&
              r.startedAt.toLocal().month == now.month &&
              r.startedAt.toLocal().day == now.day,
        )
        .fold<double>(0, (sum, r) => sum + r.distanceKm);
    if (!mounted) return;
    setState(() {
      vehicle = value;
      services = serviceItems;
      todayDistance = distance;
    });
  }

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 11) return l10n.t('morning');
    if (hour < 15) return l10n.t('afternoon');
    if (hour < 18) return l10n.t('evening');
    return l10n.t('night');
  }

  Future<void> _showNotifications() async {
    final l10n = AppLocalizations.of(context);
    final due = services
        .where(
          (s) =>
              ServiceSchedule.status(vehicle?.odometerKm ?? 0, s) !=
              ServiceStatus.safe,
        )
        .toList();
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('notifications'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.route),
                title: Text(l10n.t('today_trip')),
                subtitle: Text('${todayDistance.toStringAsFixed(1)} km'),
              ),
              ListTile(
                leading: const Icon(Icons.build_outlined),
                title: Text(l10n.t('due_service')),
                subtitle: Text(
                  due.isEmpty
                      ? l10n.t('no_notifications')
                      : due.map((s) => s.name).join(', '),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _correctOdometer() async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) =>
          _OdometerCorrectionDialog(initialValue: vehicle?.odometerKm ?? 0),
    );
    if (value == null || value < 0) return;
    await widget.repository.updateOdometer(value);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = vehicle?.userName.isNotEmpty == true
        ? vehicle!.userName
        : vehicle?.name ?? 'OdoMate';
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: vehicle?.photoPath == null
                  ? null
                  : FileImage(File(vehicle!.photoPath!)),
              child: vehicle?.photoPath == null
                  ? const Icon(Icons.person, size: 22)
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(l10n),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(name, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showNotifications,
            icon: const Icon(Icons.notifications_outlined),
            tooltip: l10n.t('notifications'),
          ),
        ],
      ),
      body: ValueListenableBuilder<RideTrackingState>(
        valueListenable: widget.tracker.state,
        builder: (context, state, child) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Card(
              child: InkWell(
                onTap: _correctOdometer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('odometer'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(vehicle?.odometerKm ?? 0).toStringAsFixed(1)} km',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 4),
                      const Text('Ketuk untuk koreksi'),
                    ],
                  ),
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
                  state.active
                      ? l10n.t('ride_active')
                      : l10n.t('no_active_ride'),
                ),
                subtitle: state.active
                    ? Text(
                        '${state.ride!.distanceKm.toStringAsFixed(1)} ${l10n.t('km_recorded')}',
                      )
                    : Text(l10n.t('start_hint')),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.build_outlined),
                title: Text(l10n.t('service_schedule')),
                subtitle: Text(
                  '${services.length} ${l10n.t('saved_services')}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => widget.onNavigate?.call(2),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(l10n.t('trip_history')),
                subtitle: Text(l10n.t('view_saved_trips')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => widget.onNavigate?.call(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OdometerCorrectionDialog extends StatefulWidget {
  final double initialValue;
  const _OdometerCorrectionDialog({required this.initialValue});

  @override
  State<_OdometerCorrectionDialog> createState() =>
      _OdometerCorrectionDialogState();
}

class _OdometerCorrectionDialogState extends State<_OdometerCorrectionDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.initialValue.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Koreksi odometer'),
    content: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(labelText: 'Odometer baru (km)'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: () =>
            Navigator.pop(context, double.tryParse(controller.text)),
        child: const Text('Simpan'),
      ),
    ],
  );
}
