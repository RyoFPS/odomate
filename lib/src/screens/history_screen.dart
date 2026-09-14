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
    vehicle: await widget.repository.loadVehicle(),
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
              _summary(context, data, rides.length, distance),
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
        child: Row(
          children: [
            for (var i = 0; i < RideHistoryPeriod.values.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              _periodChip(
                context,
                _periodLabel(l10n, RideHistoryPeriod.values[i]),
                period == RideHistoryPeriod.values[i],
                () => setState(() => period = RideHistoryPeriod.values[i]),
              ),
            ],
          ],
        ),
      );

  Widget _periodChip(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onSelected,
  ) {
    const blue = Color(0xFF2563EB);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFEFF6FF),
      side: BorderSide(
        color: selected ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: TextStyle(
        color: selected ? blue : const Color(0xFF475569),
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _summary(
    BuildContext context,
    _HistoryData data,
    int count,
    double distance,
  ) {
    final l10n = AppLocalizations.of(context);
    final activeDays = _activeDays(rides: _ridesForPeriod(data));
    final averageDaily = activeDays == 0 ? 0.0 : distance / activeDays;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_copy(context, 'summary')} ${_periodLabel(l10n, period)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (data.vehicle?.name.isNotEmpty ?? false)
                  Chip(
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    avatar: Icon(
                      Icons.two_wheeler,
                      size: 14,
                      color: const Color(0xFF2563EB),
                    ),
                    label: Text(
                      data.vehicle!.name,
                      style: const TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: _metric(
                    context,
                    _copy(context, 'totalDistance'),
                    distance.toStringAsFixed(1),
                    Icons.straighten_outlined,
                    suffix: 'km',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _smallMetric(
                        context,
                        _copy(context, 'frequency'),
                        '$count',
                        Icons.alt_route,
                        suffix: 'rit',
                      ),
                      const SizedBox(height: 8),
                      _smallMetric(
                        context,
                        _copy(context, 'averageDaily'),
                        averageDaily.toStringAsFixed(1),
                        Icons.calendar_view_day_outlined,
                        suffix: 'km',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.show_chart,
                  size: 14,
                  color: const Color(0xFF16A34A),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_copy(context, 'fuelEfficiency')}: —',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: const Color(0xFF475569)),
                ),
                const Spacer(),
                ...List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      width: 4,
                      height: 6 + index * 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB)
                            .withValues(alpha: .25 + index * .15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Ride> _ridesForPeriod(_HistoryData data) =>
      filterRides(data.rides, data.now, period);

  static int _activeDays({required List<Ride> rides}) => rides
      .map((ride) {
        final date = ride.startedAt.toLocal();
        return DateTime(date.year, date.month, date.day);
      })
      .toSet()
      .length;

  Widget _smallMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    String? suffix,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: value,
                    children: suffix == null
                        ? const []
                        : [
                            TextSpan(
                              text: ' $suffix',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, size: 16, color: theme.colorScheme.primary),
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    String? suffix,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 108),
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
          Text.rich(
            TextSpan(
              text: value,
              children: suffix == null
                  ? const []
                  : [
                      TextSpan(
                        text: ' $suffix',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
            ),
            style: theme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFF0F172A),
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
          final colors = theme.colorScheme;
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
                      Icon(Icons.tune, size: 20, color: colors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _copy(context, 'filterTitle'),
                          // Desain: `text-base font-bold tracking-tight` —
                          // 16px w700, bukan w800.
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        // Desain: lingkaran 32px berlatar slate-100. Yang
                        // mengecil hanya yang terlihat — `tapTargetSize`
                        // bawaan tetap melapisi area sentuh 48px.
                        style: IconButton.styleFrom(
                          backgroundColor: colors.surfaceContainer,
                          foregroundColor: colors.secondary,
                          minimumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(
                    _copy(context, 'dateRange'),
                    style: _filterLabelStyle(theme),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in RideHistoryPeriod.values)
                        _filterChip(
                          context,
                          label: _periodLabel(l10n, value),
                          selected: draftPeriod == value,
                          onTap: () => updateSheet(() => draftPeriod = value),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_copy(context, 'sort'), style: _filterLabelStyle(theme)),
                  const SizedBox(height: 8),
                  // Desain memakai `grid grid-cols-3` untuk grup ini: ketiga
                  // chip membagi lebar sama rata, bukan selebar isinya.
                  Row(
                    children: [
                      for (var i = 0; i < _HistorySort.values.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _filterChip(
                            context,
                            label: _sortLabel(context, _HistorySort.values[i]),
                            selected: draftSort == _HistorySort.values[i],
                            onTap: () => updateSheet(
                              () => draftSort = _HistorySort.values[i],
                            ),
                            // `py-2 px-2` di desain, bukan `py-1.5 px-3`.
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => updateSheet(() {
                          draftPeriod = RideHistoryPeriod.all;
                          draftSort = _HistorySort.newest;
                        }),
                        // `OutlinedButton` tanpa tema bawaan berbentuk pill;
                        // desain memakai `px-4 py-3 rounded-xl`.
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.secondary,
                          side: BorderSide(color: colors.outlineVariant),
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                          // `bg-[#2563EB] shadow-md shadow-blue-500/20`, teks
                          // 12px w600. minimumSize menimpa tema yang memaksa
                          // tinggi 48px di seluruh app.
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            elevation: 4,
                            shadowColor: colors.primary.withValues(alpha: .2),
                          ),
                          icon: const Icon(Icons.check, size: 16),
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

  /// Label grup di dalam sheet filter: desain memakai
  /// `text-xs font-semibold text-slate-700` = 12px w600.
  static TextStyle? _filterLabelStyle(ThemeData theme) =>
      theme.textTheme.labelLarge?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
      );

  /// Chip filter sesuai desain.
  ///
  /// Keadaan terpilih hanya berubah warna — tint biru, border biru, teks biru
  /// dengan weight naik ke w600. **Tanpa centang**, karena centang itu bawaan
  /// `ChoiceChip` Material dan tidak ada di desain.
  Widget _filterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
  }) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(12);
    return Material(
      color: selected
          ? colors.primary.withValues(alpha: .08)
          : colors.surfaceContainerLow,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          // `center` membuat chip selebar isinya saat berada di dalam `Wrap`,
          // dan menengahkan teks saat direntangkan `Expanded` di grup urutan.
          alignment: Alignment.center,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: .25)
                  : colors.outlineVariant,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? colors.primary : colors.secondary,
            ),
          ),
        ),
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
        'summary': 'Ringkasan',
        'totalDistance': 'Total Jarak',
        'frequency': 'Frekuensi',
        'averageDaily': 'Rata-rata harian',
        'fuelEfficiency': 'Efisiensi BBM rata-rata',
        'filter': 'Filter',
        'entries': 'entri',
        'offline': 'Semua data tersimpan secara offline',
        'filterTitle': 'Filter Riwayat Perjalanan',
        'dateRange': 'Rentang Waktu',
        'sort': 'Urutan Log',
        'newest': 'Terbaru',
        'oldest': 'Terlama',
        'farthest': 'Jarak Terjauh',
        'reset': 'Reset Filter',
        'apply': 'Terapkan Filter',
      },
      'en': {
        'subtitle': 'Time & distance log',
        'summary': 'Summary',
        'totalDistance': 'Total distance',
        'frequency': 'Frequency',
        'averageDaily': 'Daily average',
        'fuelEfficiency': 'Average fuel efficiency',
        'filter': 'Filter',
        'entries': 'entries',
        'offline': 'All data is stored offline',
        'filterTitle': 'Filter Ride History',
        'dateRange': 'Date Range',
        'sort': 'Log Order',
        'newest': 'Newest',
        'oldest': 'Oldest',
        'farthest': 'Farthest Distance',
        'reset': 'Reset Filters',
        'apply': 'Apply Filters',
      },
      'ja': {
        'summary': '概要',
        'totalDistance': '合計距離',
        'frequency': '回数',
        'averageDaily': '日平均',
        'fuelEfficiency': '平均燃費',
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
  final Vehicle? vehicle;
  final DateTime now;

  const _HistoryData({
    required this.rides,
    required this.logs,
    required this.vehicle,
    required this.now,
  });
}
