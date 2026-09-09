import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/service_schedule.dart';
import '../i18n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  final OdomateRepository repository;
  const NotificationsScreen({super.key, required this.repository});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<_NotificationEntry>> future;
  String filter = 'all';
  bool allRead = false;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<_NotificationEntry>> _load() async {
    final vehicle = await widget.repository.loadVehicle();
    final rides = await widget.repository.listRides();
    final services = await widget.repository.listServices();
    final entries = <_NotificationEntry>[];
    if (rides.isNotEmpty) {
      final ride = rides.first;
      entries.add(
        _NotificationEntry(
          kind: 'ride',
          icon: Icons.check_circle_outline,
          titleKey: 'ride_completed_notification',
          description:
              '${ride.distanceKm.toStringAsFixed(1)} km · ${ride.endedAt == null ? '' : _duration(ride)}',
          time: ride.startedAt,
          unread: false,
        ),
      );
    }
    final odo = vehicle?.odometerKm ?? 0;
    for (final service in services) {
      final status = ServiceSchedule.status(odo, service);
      if (status != ServiceStatus.safe) {
        entries.add(
          _NotificationEntry(
            kind: 'service',
            icon: Icons.build_outlined,
            titleKey: status == ServiceStatus.due
                ? 'service_due_notification'
                : 'service_soon_notification',
            description: service.name,
            time: DateTime.now(),
            unread: true,
          ),
        );
      }
    }
    return entries;
  }

  String _duration(Ride ride) {
    final ended = ride.endedAt;
    if (ended == null) return '';
    final minutes = ended.difference(ride.startedAt).inMinutes;
    return '${minutes ~/ 60 > 0 ? '${minutes ~/ 60}h ' : ''}${minutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.t('notifications'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => allRead = true),
            child: Text(l10n.t('mark_all_read')),
          ),
        ],
      ),
      body: FutureBuilder<List<_NotificationEntry>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data!
              .where((entry) => filter == 'all' || entry.kind == filter)
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _filters(context, l10n),
              const SizedBox(height: 20),
              Text(
                l10n.t('today_period'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                _empty(context, l10n)
              else
                ...entries.map((entry) => _entry(context, l10n, entry)),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_outlined),
                  title: Text(l10n.t('offline_notifications')),
                  dense: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filters(BuildContext context, AppLocalizations l10n) => Row(
    children: [
      _filter(context, l10n.t('all_period'), 'all'),
      const SizedBox(width: 8),
      _filter(context, l10n.t('notification_rides'), 'ride'),
      const SizedBox(width: 8),
      _filter(context, l10n.t('notification_services'), 'service'),
    ],
  );

  Widget _filter(BuildContext context, String label, String value) {
    final selected = filter == value;
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => filter = value),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? scheme.primaryContainer : null,
          foregroundColor: selected
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _entry(
    BuildContext context,
    AppLocalizations l10n,
    _NotificationEntry entry,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final color = entry.kind == 'service'
        ? const Color(0xFFD97706)
        : scheme.primary;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          foregroundColor: color,
          child: Icon(entry.icon),
        ),
        title: Row(
          children: [
            Expanded(child: Text(l10n.t(entry.titleKey))),
            if (entry.unread && !allRead)
              Icon(Icons.circle, size: 9, color: scheme.primary),
          ],
        ),
        subtitle: Text('${entry.description}\n${_time(entry.time)}'),
        isThreeLine: true,
      ),
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(l10n.t('empty_notifications')),
        ],
      ),
    ),
  );

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _NotificationEntry {
  final String kind;
  final IconData icon;
  final String titleKey;
  final String description;
  final DateTime time;
  final bool unread;

  const _NotificationEntry({
    required this.kind,
    required this.icon,
    required this.titleKey,
    required this.description,
    required this.time,
    required this.unread,
  });
}
