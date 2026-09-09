import 'dart:io';

import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/ride_statistics.dart';
import '../domain/service_schedule.dart';
import '../i18n/app_localizations.dart';
import '../tracking/ride_tracker.dart';
import 'notifications_screen.dart';

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
  int todayRideCount = 0;
  double sevenDayDistance = 0;
  int sevenDayRideCount = 0;

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
    final today = calculateRideStatistics(rides, now, StatisticsPeriod.today);
    final sevenDay = calculateRideStatistics(
      rides,
      now,
      StatisticsPeriod.lastSevenDays,
    );
    if (!mounted) return;
    setState(() {
      vehicle = value;
      services = serviceItems;
      todayDistance = today.totalDistanceKm;
      todayRideCount = today.rideCount;
      sevenDayDistance = sevenDay.totalDistanceKm;
      sevenDayRideCount = sevenDay.rideCount;
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(repository: widget.repository),
      ),
    );
  }

  Future<void> _correctOdometer() async {
    final value = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OdometerCorrectionSheet(
        initialValue: vehicle?.odometerKm ?? 0,
        vehicle: vehicle,
      ),
    );
    if (value == null || value < 0) return;
    await widget.repository.updateOdometer(value);
    await _refresh();
  }

  Future<void> _toggleRide() async {
    if (widget.tracker.state.value.active) {
      await widget.tracker.stop();
    } else {
      await widget.tracker.start();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final name = vehicle?.userName.isNotEmpty == true
        ? vehicle!.userName
        : vehicle?.name ?? 'OdoMate';
    final vehicleSummary = [
      vehicle?.name,
      vehicle?.plateNumber,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 16,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  key: ValueKey(
                    vehicle?.photoPath == null
                        ? 'home-profile-avatar-fallback'
                        : 'home-profile-avatar-photo',
                  ),
                  radius: 19,
                  backgroundColor: colors.primaryContainer,
                  backgroundImage: vehicle?.photoPath == null
                      ? const AssetImage(
                          'stitch_odomate_modern_ui/odomate_rider_avatar_updated_full/screen.png',
                        )
                      : FileImage(File(vehicle!.photoPath!)),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.tertiary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_greeting(l10n)}, ${name.split(' ').first}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    vehicleSummary.isEmpty ? 'Motor utama' : vehicleSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton.filledTonal(
              onPressed: _showNotifications,
              icon: const Icon(Icons.notifications_none),
              tooltip: l10n.t('notifications'),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<RideTrackingState>(
        valueListenable: widget.tracker.state,
        builder: (context, state, child) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            _vehicleCard(context, state, l10n),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _metricCard(
                    context,
                    label: 'HARI INI',
                    value: _km(todayDistance),
                    unit: 'km',
                    footer: '$todayRideCount rit',
                    icon: Icons.today_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    context,
                    label: '7 HARI TERAKHIR',
                    value: _km(sevenDayDistance),
                    unit: 'km',
                    footer: '$sevenDayRideCount rit',
                    icon: Icons.date_range_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _shortcutCard(
                    context,
                    icon: Icons.history,
                    title: l10n.t('trip_history'),
                    subtitle: l10n.t('view_saved_trips'),
                    onTap: () => widget.onNavigate?.call(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _shortcutCard(
                    context,
                    icon: Icons.insights_outlined,
                    title: l10n.t('statistics'),
                    subtitle:
                        '${_km(sevenDayDistance)} km • $sevenDayRideCount rit',
                    onTap: () => widget.onNavigate?.call(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _serviceSummary(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _vehicleCard(
    BuildContext context,
    RideTrackingState state,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.two_wheeler,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Motor Utama',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => widget.onNavigate?.call(3),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Ganti'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _correctOdometer,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ODOMETER TOTAL',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.secondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        text: _km(vehicle?.odometerKm ?? 0),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                        children: [
                          TextSpan(
                            text: ' km',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 18),
                    Row(
                      children: [
                        Text(
                          'Ketuk untuk koreksi odometer',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.secondary,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    state.error != null
                        ? Icons.location_off_outlined
                        : state.active
                        ? Icons.gps_fixed
                        : Icons.sensors_outlined,
                    size: 18,
                    color: state.error != null
                        ? colors.error
                        : state.active
                        ? colors.tertiary
                        : colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: state.error != null
                            ? 'Perlu perhatian'
                            : state.active
                            ? l10n.t('ride_active')
                            : l10n.t('no_active_ride'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          TextSpan(
                            text: state.error != null
                                ? ' • ${state.error}'
                                : state.active
                                ? ' • ${_km(state.ride?.distanceKm ?? 0)} ${l10n.t('km_recorded')}'
                                : ' • ${l10n.t('start_hint')}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.secondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _toggleRide,
              icon: Icon(state.active ? Icons.stop : Icons.play_arrow),
              label: Text(
                state.active ? l10n.t('stop_ride') : l10n.t('start_ride'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required String footer,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(icon, size: 17, color: colors.secondary),
              ],
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(
                    text: ' $unit',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 18),
            Text(footer, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _shortcutCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceSummary(BuildContext context, AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.build_outlined, size: 18, color: colors.secondary),
                const SizedBox(width: 8),
                Text(
                  l10n.t('service_schedule'),
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => widget.onNavigate?.call(2),
                  child: const Text('Lihat semua'),
                ),
              ],
            ),
            if (services.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l10n.t('empty_services')),
              )
            else
              ...services
                  .take(3)
                  .map((service) => _serviceRow(context, service)),
          ],
        ),
      ),
    );
  }

  Widget _serviceRow(BuildContext context, ServiceItem service) {
    final colors = Theme.of(context).colorScheme;
    final status = ServiceSchedule.status(vehicle?.odometerKm ?? 0, service);
    final remaining =
        service.lastServicedOdometerKm +
        service.intervalKm -
        (vehicle?.odometerKm ?? 0);
    final isDue = status == ServiceStatus.due;
    final isSoon = status == ServiceStatus.dueSoon;
    final accent = isDue
        ? colors.error
        : isSoon
        ? const Color(0xFFD97706)
        : colors.tertiary;
    final label = isDue
        ? 'Perlu Servis'
        : isSoon
        ? 'Segera'
        : 'Aman';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.settings, size: 17, color: accent),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    isDue
                        ? 'Lewat ${_km(-remaining)} km'
                        : 'Sisa ${_km(remaining)} km lagi',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: accent),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: accent, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _km(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

class _OdometerCorrectionSheet extends StatefulWidget {
  final double initialValue;
  final Vehicle? vehicle;
  const _OdometerCorrectionSheet({
    required this.initialValue,
    required this.vehicle,
  });

  @override
  State<_OdometerCorrectionSheet> createState() =>
      _OdometerCorrectionSheetState();
}

class _OdometerCorrectionSheetState extends State<_OdometerCorrectionSheet> {
  late final TextEditingController controller;
  String? errorText;

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

  double? get value => double.tryParse(controller.text.replaceAll(',', '.'));

  void _setValue(double next) {
    controller.text = next == next.roundToDouble()
        ? next.toStringAsFixed(0)
        : next.toStringAsFixed(1);
    setState(() => errorText = null);
  }

  void _submit() {
    final next = value;
    if (next == null || next < 0) {
      setState(() => errorText = 'Masukkan angka odometer yang valid.');
      return;
    }
    Navigator.pop(context, next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final vehicleSummary = [
      widget.vehicle?.name,
      widget.vehicle?.plateNumber,
    ].whereType<String>().where((item) => item.isNotEmpty).toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Odometer Manual',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Sinkronisasi fisik speedometer kendaraan',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Tutup',
                ),
              ],
            ),
            if (vehicleSummary.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.two_wheeler,
                        size: 17,
                        color: colors.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicleSummary.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (vehicleSummary.length > 1)
                            Text(
                              vehicleSummary.last,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.secondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'ANGKA ODOMETER BARU',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.secondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                errorText: errorText,
                suffixText: 'km',
                suffixStyle: theme.textTheme.titleMedium?.copyWith(
                  color: colors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onChanged: (_) {
                if (errorText != null) setState(() => errorText = null);
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final amount in const [10.0, 50.0, 100.0]) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _setValue((value ?? widget.initialValue) + amount),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: Text('+${amount.toInt()} km'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _setValue(widget.initialValue),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: colors.primary),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Estimasi jadwal servis akan dihitung dari angka odometer ini.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Simpan Odometer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
