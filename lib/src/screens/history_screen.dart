import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/ride_history.dart';
import '../i18n/app_localizations.dart';
import 'ride_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final OdomateRepository repository;
  final DateTime Function() now;

  const HistoryScreen({
    super.key,
    required this.repository,
    this.now = DateTime.now,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<_HistoryData> future;
  RideHistoryPeriod period = RideHistoryPeriod.all;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<_HistoryData> _load() async => _HistoryData(
    rides: await widget.repository.listRides(),
    logs: await widget.repository.listServiceLogs(),
    now: widget.now(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('history'))),
      body: FutureBuilder<_HistoryData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l10n.t('history_error')));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final rides = filterRides(data.rides, data.now, period);
          final totalDistance = rides.fold<double>(
            0,
            (sum, ride) => sum + ride.distanceKm,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _summary(
                          l10n.t('ride_count'),
                          '${rides.length}',
                          Icons.route_outlined,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 44,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      Expanded(
                        child: _summary(
                          '${l10n.t('distance')} (km)',
                          totalDistance.toStringAsFixed(1),
                          Icons.straighten_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<RideHistoryPeriod>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: RideHistoryPeriod.all,
                      label: Text(l10n.t('all_period')),
                    ),
                    ButtonSegment(
                      value: RideHistoryPeriod.today,
                      label: Text(l10n.t('today_period')),
                    ),
                    ButtonSegment(
                      value: RideHistoryPeriod.lastSevenDays,
                      label: Text(l10n.t('last_seven_days')),
                    ),
                    ButtonSegment(
                      value: RideHistoryPeriod.currentMonth,
                      label: Text(l10n.t('current_month')),
                    ),
                  ],
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surface,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  selected: {period},
                  onSelectionChanged: (value) =>
                      setState(() => period = value.first),
                ),
              ),
              const SizedBox(height: 20),
              if (rides.isNotEmpty) ...[
                Text(
                  l10n.t('history_rides'),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...rides.map((ride) => _rideCard(context, ride, l10n)),
              ],
              if (data.logs.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.t('history_services'),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...data.logs.map((log) => _serviceCard(log)),
              ],
              if (rides.isEmpty && data.logs.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(l10n.t('history_empty'))),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _rideCard(
    BuildContext context,
    Ride ride,
    AppLocalizations l10n,
  ) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(Icons.route, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(_dateTime(context, ride.startedAt)),
      subtitle: Text(
        '${ride.distanceKm.toStringAsFixed(1)} km · ${_duration(ride, l10n)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => RideDetailScreen(ride: ride)),
      ),
    ),
  );

  Widget _serviceCard(ServiceLog log) => Card(
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        child: Icon(
          Icons.build_outlined,
          color: Theme.of(context).colorScheme.onTertiaryContainer,
        ),
      ),
      title: Text(_date(log.servicedAt)),
      subtitle: Text('${log.odometerKm.toStringAsFixed(1)} km'),
    ),
  );

  Widget _summary(String title, String value, IconData icon) => Column(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      const SizedBox(height: 6),
      Text(title, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 2),
      Text(
        value,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );

  String _duration(Ride ride, AppLocalizations l10n) {
    final endedAt = ride.endedAt;
    if (endedAt == null || endedAt.isBefore(ride.startedAt)) {
      return l10n.t('active_status');
    }
    return formatRideDuration(
      ride,
      hourSuffix: l10n.t('hours_unit'),
      minuteSuffix: l10n.t('minutes_unit'),
    );
  }

  static String _dateTime(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(local);
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(local));
    return '$date, $time';
  }

  static String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _HistoryData {
  final List<Ride> rides;
  final List<ServiceLog> logs;
  final DateTime now;

  const _HistoryData({
    required this.rides,
    required this.logs,
    required this.now,
  });
}
