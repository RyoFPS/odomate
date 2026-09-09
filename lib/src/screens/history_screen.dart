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
  _HistorySort sort = _HistorySort.newest;
  bool searching = false;
  String query = '';

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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: searching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: MaterialLocalizations.of(context).searchFieldLabel,
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => query = value),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('history'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _copy(context, 'subtitle'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            onPressed: () => setState(() {
              searching = !searching;
              if (!searching) query = '';
            }),
            icon: Icon(searching ? Icons.close : Icons.search),
            tooltip: searching
                ? MaterialLocalizations.of(context).closeButtonTooltip
                : MaterialLocalizations.of(context).searchFieldLabel,
          ),
          IconButton(
            onPressed: _showFilters,
            icon: const Icon(Icons.tune),
            tooltip: _copy(context, 'filter'),
          ),
        ],
      ),
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
          final rides = _rides(context, data, l10n);
          final logs = _logs(data.logs);
          final distance = rides.fold<double>(
            0,
            (total, ride) => total + ride.distanceKm,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              _periodSelector(context, l10n),
              const SizedBox(height: 12),
              _summary(context, l10n, rides.length, distance),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    l10n.t('history_rides'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (rides.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        '${rides.length} ${_copy(context, 'entries')}',
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
              if (rides.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...rides.map((ride) => _rideCard(context, ride, l10n)),
              ],
              if (logs.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.t('history_services'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ...logs.map((log) => _serviceCard(context, log)),
              ],
              if (rides.isEmpty && logs.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(l10n.t('history_empty'))),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.offline_pin_outlined,
                    size: 16,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _copy(context, 'offline'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  List<Ride> _rides(
    BuildContext context,
    _HistoryData data,
    AppLocalizations l10n,
  ) {
    final needle = query.trim().toLowerCase();
    final rides = filterRides(data.rides, data.now, period).where((ride) {
      if (needle.isEmpty) return true;
      return [
        _dateTime(context, ride.startedAt),
        ride.distanceKm.toStringAsFixed(1),
        _duration(ride, l10n),
        _isActive(ride) ? l10n.t('active_status') : l10n.t('completed_status'),
      ].join(' ').toLowerCase().contains(needle);
    }).toList();
    rides.sort(switch (sort) {
      _HistorySort.newest => (a, b) => b.startedAt.compareTo(a.startedAt),
      _HistorySort.oldest => (a, b) => a.startedAt.compareTo(b.startedAt),
      _HistorySort.distance => (a, b) => b.distanceKm.compareTo(a.distanceKm),
    });
    return rides;
  }

  List<ServiceLog> _logs(List<ServiceLog> logs) {
    final needle = query.trim().toLowerCase();
    final visible = logs.where((log) {
      if (needle.isEmpty) return true;
      return [
        _date(log.servicedAt),
        log.odometerKm.toStringAsFixed(1),
        log.note ?? '',
      ].join(' ').toLowerCase().contains(needle);
    }).toList();
    visible.sort((a, b) => b.servicedAt.compareTo(a.servicedAt));
    return visible;
  }

  Widget _periodSelector(BuildContext context, AppLocalizations l10n) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<RideHistoryPeriod>(
          showSelectedIcon: false,
          segments: RideHistoryPeriod.values
              .map(
                (value) => ButtonSegment(
                  value: value,
                  label: Text(_periodLabel(l10n, value)),
                ),
              )
              .toList(),
          selected: {period},
          onSelectionChanged: (value) => setState(() => period = value.first),
        ),
      );

  Widget _summary(
    BuildContext context,
    AppLocalizations l10n,
    int count,
    double distance,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _metric(
                    context,
                    '${l10n.t('distance')} (km)',
                    distance.toStringAsFixed(1),
                    Icons.straighten_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metric(
                    context,
                    l10n.t('ride_count'),
                    '$count',
                    Icons.alt_route,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
              Icon(icon, size: 17, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rideCard(BuildContext context, Ride ride, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final active = _isActive(ride);
    final accent = active
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => RideDetailScreen(ride: ride)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _status(
                    context,
                    active
                        ? l10n.t('active_status')
                        : l10n.t('completed_status'),
                    accent,
                    active,
                  ),
                  const Spacer(),
                  Text(
                    _dateTime(context, ride.startedAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.two_wheeler, color: accent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ride.distanceKm.toStringAsFixed(1)} km',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!active) Text(_duration(ride, l10n)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _status(BuildContext context, String text, Color color, bool active) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active) ...[
                Icon(Icons.circle, size: 9, color: color),
                const SizedBox(width: 5),
              ],
              Text(
                text,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );

  Widget _serviceCard(BuildContext context, ServiceLog log) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        child: const Icon(Icons.build_outlined),
      ),
      title: Text(_date(log.servicedAt)),
      subtitle: Text(
        [
          '${log.odometerKm.toStringAsFixed(1)} km',
          if (log.note?.trim().isNotEmpty ?? false) log.note!.trim(),
        ].join(' · '),
      ),
    ),
  );

  Future<void> _showFilters() async {
    var draftPeriod = period;
    var draftSort = sort;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) {
          final l10n = AppLocalizations.of(context);
          final theme = Theme.of(context);
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _copy(context, 'filterTitle'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(
                    _copy(context, 'dateRange'),
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: RideHistoryPeriod.values
                        .map(
                          (value) => ChoiceChip(
                            label: Text(_periodLabel(l10n, value)),
                            selected: draftPeriod == value,
                            onSelected: (_) =>
                                updateSheet(() => draftPeriod = value),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _copy(context, 'sort'),
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _HistorySort.values
                        .map(
                          (value) => ChoiceChip(
                            label: Text(_sortLabel(context, value)),
                            selected: draftSort == value,
                            onSelected: (_) =>
                                updateSheet(() => draftSort = value),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => updateSheet(() {
                          draftPeriod = RideHistoryPeriod.all;
                          draftSort = _HistorySort.newest;
                        }),
                        child: Text(_copy(context, 'reset')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              period = draftPeriod;
                              sort = draftSort;
                            });
                            Navigator.pop(sheetContext);
                          },
                          icon: const Icon(Icons.check),
                          label: Text(_copy(context, 'apply')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

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

  static bool _isActive(Ride ride) =>
      ride.endedAt == null || ride.endedAt!.isBefore(ride.startedAt);

  static String _periodLabel(AppLocalizations l10n, RideHistoryPeriod value) =>
      switch (value) {
        RideHistoryPeriod.all => l10n.t('all_period'),
        RideHistoryPeriod.today => l10n.t('today_period'),
        RideHistoryPeriod.lastSevenDays => l10n.t('last_seven_days'),
        RideHistoryPeriod.currentMonth => l10n.t('current_month'),
      };

  static String _sortLabel(BuildContext context, _HistorySort value) =>
      _copy(context, switch (value) {
        _HistorySort.newest => 'newest',
        _HistorySort.oldest => 'oldest',
        _HistorySort.distance => 'farthest',
      });

  static String _copy(BuildContext context, String key) {
    const copy = {
      'id': {
        'subtitle': 'Log waktu & jarak tempuh',
        'filter': 'Filter',
        'entries': 'entri',
        'offline': 'Semua data tersimpan secara offline',
        'filterTitle': 'Filter Riwayat Perjalanan',
        'dateRange': 'Rentang waktu',
        'sort': 'Urutan perjalanan',
        'newest': 'Terbaru',
        'oldest': 'Terlama',
        'farthest': 'Terjauh',
        'reset': 'Reset',
        'apply': 'Terapkan',
      },
      'en': {
        'subtitle': 'Time & distance log',
        'filter': 'Filter',
        'entries': 'entries',
        'offline': 'All data is stored offline',
        'filterTitle': 'Filter Ride History',
        'dateRange': 'Date range',
        'sort': 'Ride order',
        'newest': 'Newest',
        'oldest': 'Oldest',
        'farthest': 'Farthest',
        'reset': 'Reset',
        'apply': 'Apply',
      },
      'ja': {
        'subtitle': '時間と走行距離の記録',
        'filter': 'フィルター',
        'entries': '件',
        'offline': 'すべてのデータはオフラインで保存されます',
        'filterTitle': '走行履歴を絞り込む',
        'dateRange': '期間',
        'sort': '並び順',
        'newest': '新しい順',
        'oldest': '古い順',
        'farthest': '距離順',
        'reset': 'リセット',
        'apply': '適用',
      },
    };
    final language = Localizations.localeOf(context).languageCode;
    return (copy[language] ?? copy['en'])![key] ?? key;
  }

  static String _dateTime(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final date = MaterialLocalizations.of(context).formatShortDate(local);
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(local));
    return '$date, $time';
  }

  static String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

enum _HistorySort { newest, oldest, distance }

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
