import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/ride_statistics.dart';
import '../domain/service_schedule.dart';
import '../i18n/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  final OdomateRepository repository;
  final DateTime Function() now;
  const StatisticsScreen({
    super.key,
    required this.repository,
    this.now = DateTime.now,
  });
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<_StatisticsData> future;
  StatisticsPeriod period = StatisticsPeriod.lastSevenDays;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<_StatisticsData> _load() async => _StatisticsData(
    vehicle: await widget.repository.loadVehicle(),
    rides: await widget.repository.listRides(),
    services: await widget.repository.listServices(),
    now: widget.now(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('statistics'))),
      body: FutureBuilder<_StatisticsData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l10n.t('statistics_error')));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final stats = calculateRideStatistics(data.rides, data.now, period);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SegmentedButton<StatisticsPeriod>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: StatisticsPeriod.today,
                    label: Text(l10n.t('today_period')),
                  ),
                  ButtonSegment(
                    value: StatisticsPeriod.lastSevenDays,
                    label: Text(l10n.t('last_seven_days')),
                  ),
                  ButtonSegment(
                    value: StatisticsPeriod.currentMonth,
                    label: Text(l10n.t('current_month')),
                  ),
                ],
                selected: {period},
                onSelectionChanged: (value) =>
                    setState(() => period = value.first),
              ),
              const SizedBox(height: 16),
              if (stats.rideCount == 0)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(l10n.t('empty_statistics'))),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      l10n.t('distance'),
                      '${stats.totalDistanceKm.toStringAsFixed(1)} km',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      l10n.t('ride_count'),
                      '${stats.rideCount}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _metricCard(
                l10n.t('average_distance'),
                '${stats.averageDistanceKm.toStringAsFixed(1)} km',
              ),
              const SizedBox(height: 12),
              _metricCard(
                l10n.t('total_vehicle_distance'),
                '${data.rides.fold<double>(0, (sum, ride) => sum + ride.distanceKm).toStringAsFixed(1)} km',
              ),
              const SizedBox(height: 20),
              _serviceCard(context, data, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _metricCard(String title, String value) => Card(
    child: ListTile(
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );

  Widget _serviceCard(
    BuildContext context,
    _StatisticsData data,
    AppLocalizations l10n,
  ) {
    final odo = data.vehicle?.odometerKm ?? 0;
    final statuses = data.services
        .map((item) => (item, ServiceSchedule.status(odo, item)))
        .toList();
    final due = statuses.where((entry) => entry.$2 == ServiceStatus.due).length;
    final soon = statuses
        .where((entry) => entry.$2 == ServiceStatus.dueSoon)
        .length;
    statuses.sort((a, b) {
      final rank = (b.$2 == ServiceStatus.due ? 1 : 0).compareTo(
        a.$2 == ServiceStatus.due ? 1 : 0,
      );
      if (rank != 0) return rank;
      final aRemaining = a.$1.lastServicedOdometerKm + a.$1.intervalKm - odo;
      final bRemaining = b.$1.lastServicedOdometerKm + b.$1.intervalKm - odo;
      return aRemaining.compareTo(bRemaining);
    });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('service_summary'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('${statuses.length} ${l10n.t('saved_services')}'),
            const SizedBox(height: 8),
            Text(
              '$due ${l10n.t('due_count')} · $soon ${l10n.t('due_soon_count')}',
            ),
            if (statuses.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${l10n.t('nearest_service')}: ${statuses.first.$1.name}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatisticsData {
  final Vehicle? vehicle;
  final List<Ride> rides;
  final List<ServiceItem> services;
  final DateTime now;
  const _StatisticsData({
    required this.vehicle,
    required this.rides,
    required this.services,
    required this.now,
  });
}
