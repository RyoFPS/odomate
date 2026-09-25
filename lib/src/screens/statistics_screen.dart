import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/ride_statistics.dart';
import '../domain/service_schedule.dart';
import '../i18n/app_localizations.dart';
import '../widgets/date_range_chips.dart';
import '../widgets/skeleton_loader.dart';

class StatisticsScreen extends StatefulWidget {
  final OdomateRepository repository;
  final DateTime Function() now;
  final VoidCallback? onBack;
  const StatisticsScreen({
    super.key,
    required this.repository,
    this.now = DateTime.now,
    this.onBack,
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: Text(l10n.t('statistics')),
      ),
      body: FutureBuilder<_StatisticsData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l10n.t('statistics_error')));
          }
          if (!snapshot.hasData) {
            return const SkeletonLoader(rows: 2);
          }
          final data = snapshot.data!;
          final stats = calculateRideStatistics(data.rides, data.now, period);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _periodSelector(context, l10n),
              const SizedBox(height: 16),
              _overviewCard(context, l10n, stats),
              const SizedBox(height: 12),
              _monthlyDistanceCard(context, l10n, data),
              const SizedBox(height: 12),
              _trendCard(context, l10n, data, period),
              const SizedBox(height: 20),
              _serviceCard(context, data, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _periodSelector(BuildContext context, AppLocalizations l10n) {
    final labels = {
      StatisticsPeriod.today: l10n.t('today_period'),
      StatisticsPeriod.lastSevenDays: l10n.t('last_seven_days'),
      StatisticsPeriod.currentMonth: l10n.t('current_month'),
    };
    return DateRangeChips(
      labels: StatisticsPeriod.values.map((value) => labels[value]!).toList(),
      selectedIndex: StatisticsPeriod.values.indexOf(period),
      onSelected: (index) =>
          setState(() => period = StatisticsPeriod.values[index]),
    );
  }

  Widget _overviewCard(
    BuildContext context,
    AppLocalizations l10n,
    RideStatistics stats,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('statistics_overview'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('distance'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text.rich(
                        TextSpan(
                          text: stats.totalDistanceKm.toStringAsFixed(1),
                          children: [
                            TextSpan(
                              text: ' km',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _overviewMetric(
                    context,
                    l10n.t('ride_count'),
                    '${stats.rideCount}',
                  ),
                ),
                Expanded(
                  child: _overviewMetric(
                    context,
                    l10n.t('average_distance'),
                    '${stats.averageDistanceKm.toStringAsFixed(1)} km',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: colors.outlineVariant),
            const SizedBox(height: 10),
            _overviewMetric(
              context,
              l10n.t('total_duration'),
              _formatDuration(stats.totalDuration, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthlyDistanceCard(
    BuildContext context,
    AppLocalizations l10n,
    _StatisticsData data,
  ) {
    final theme = Theme.of(context);
    final values = calculateMonthlyDistances(data.rides, data.now);
    final maxValue = values.fold<double>(
      0,
      (max, value) => value.distanceKm > max ? value.distanceKm : max,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('monthly_distance'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.t('last_six_months'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 118,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final value in values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              value.distanceKm == 0
                                  ? ''
                                  : value.distanceKm.toStringAsFixed(0),
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: maxValue == 0
                                  ? 6
                                  : 72 * value.distanceKm / maxValue,
                              decoration: BoxDecoration(
                                color:
                                    value.month.month == data.now.month &&
                                        value.month.year == data.now.year
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '${value.month.month}/${value.month.year % 100}',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewMetric(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _trendCard(
    BuildContext context,
    AppLocalizations l10n,
    _StatisticsData data,
    StatisticsPeriod selectedPeriod,
  ) {
    final theme = Theme.of(context);
    final bars = _trendValues(data.rides, data.now, selectedPeriod);
    final maxValue = bars.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('daily_trend'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.t('daily_trend_subtitle'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (bars.every((value) => value == 0)) ...[
              const SizedBox(height: 14),
              Text(l10n.t('empty_statistics')),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 118,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < bars.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: maxValue == 0
                                  ? 6
                                  : 78 * bars[i] / maxValue,
                              decoration: BoxDecoration(
                                color: i == bars.length - 1
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              _trendLabel(data.now, selectedPeriod, i),
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _trendValues(
    List<Ride> rides,
    DateTime now,
    StatisticsPeriod selectedPeriod,
  ) {
    return calculateDailyDistances(rides, now, selectedPeriod);
  }

  String _trendLabel(DateTime now, StatisticsPeriod selectedPeriod, int index) {
    if (selectedPeriod == StatisticsPeriod.today) return 'Hari';
    if (selectedPeriod == StatisticsPeriod.currentMonth) {
      return '${index + 1}';
    }
    final day = now.toLocal().subtract(Duration(days: 6 - index));
    return '${day.day}/${day.month}';
  }

  String _formatDuration(Duration duration, AppLocalizations l10n) {
    if (duration.inHours > 0) {
      return '${duration.inHours} ${l10n.t('hours_unit')} ${duration.inMinutes.remainder(60)} ${l10n.t('minutes_unit')}';
    }
    return '${duration.inMinutes} ${l10n.t('minutes_unit')}';
  }

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
