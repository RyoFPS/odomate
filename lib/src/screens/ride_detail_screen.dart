import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/odomate_repository.dart';
import '../domain/gpx_export.dart';
import '../domain/models.dart';
import '../domain/ride_history.dart';
import '../i18n/app_localizations.dart';
import '../widgets/app_header.dart';
import '../widgets/metric_tile.dart';
import '../widgets/ride_map.dart';
import '../widgets/status_badge.dart';

class RideDetailScreen extends StatefulWidget {
  final Ride ride;
  final OdomateRepository? repository;

  const RideDetailScreen({super.key, required this.ride, this.repository});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  late Ride ride;
  late Future<List<GeoPoint>> _routePoints;

  @override
  void initState() {
    super.initState();
    ride = widget.ride;
    _routePoints = _loadRoutePoints();
  }

  Future<List<GeoPoint>> _loadRoutePoints() {
    final rideId = ride.id;
    final repository = widget.repository;
    if (rideId == null || repository == null) return Future.value(const []);
    return repository.listRidePoints(rideId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active =
        ride.endedAt == null || ride.endedAt!.isBefore(ride.startedAt);
    final duration = active
        ? l10n.t('active_status')
        : formatRideDuration(
            ride,
            hourSuffix: l10n.t('hours_unit'),
            minuteSuffix: l10n.t('minutes_unit'),
          );
    final elapsedMinutes = active
        ? 0
        : ride.endedAt!.difference(ride.startedAt).inMinutes;
    final averageSpeed = elapsedMinutes > 0
        ? ride.distanceKm / elapsedMinutes * 60
        : null;

    return Scaffold(
      appBar: AppHeader(
        title: l10n.t('ride_detail'),
        titleStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        actions: [
          IconButton(
            tooltip: l10n.t('share_trip'),
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _share(context, l10n),
          ),
          IconButton(
            tooltip: l10n.t('trip_more_options'),
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMore(context, l10n, active, duration),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _summaryCard(context, l10n, active, duration, averageSpeed),
          const SizedBox(height: 16),
          _routePreview(context, l10n),
          const SizedBox(height: 16),
          _timelineCard(context, l10n, active),
          const SizedBox(height: 16),
          _notesCard(context, l10n),
        ],
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    AppLocalizations l10n,
    bool active,
    String duration,
    double? averageSpeed,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.two_wheeler, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.t('ride_summary'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _statusPill(context, l10n, active),
              ],
            ),
            const Divider(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(flex: 3, child: _distanceMetric(context, l10n)),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('duration'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            letterSpacing: .6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          duration,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: MetricTile(
                      key: const ValueKey('ride-average-speed'),
                      icon: Icons.speed_outlined,
                      label: l10n.t('average_speed'),
                      value: averageSpeed == null
                          ? '—'
                          : '${averageSpeed.toStringAsFixed(0)} km/h',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricTile(
                      key: const ValueKey('ride-estimate'),
                      icon: Icons.local_gas_station_outlined,
                      label: l10n.t('estimate'),
                      value: '— L',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricTile(
                      key: const ValueKey('ride-final-odometer'),
                      icon: Icons.speed,
                      label: l10n.t('final_odometer'),
                      value: '— km',
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

  Future<void> _share(BuildContext context, AppLocalizations l10n) async {
    final text =
        '${l10n.t('distance')}: ${ride.distanceKm.toStringAsFixed(1)} km\n'
        '${l10n.t('duration')}: ${ride.endedAt == null ? l10n.t('active_status') : formatRideDuration(ride, hourSuffix: l10n.t('hours_unit'), minuteSuffix: l10n.t('minutes_unit'))}';
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.t('share_failed'))));
      }
    }
  }

  Future<void> _showMore(
    BuildContext context,
    AppLocalizations l10n,
    bool active,
    String duration,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _RideSheetFrame(
      title: l10n.t('trip_options'),
      subtitle: l10n.t('manage_trip_log'),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            _optionTile(
              sheetContext,
              l10n,
              Icons.edit_note,
              l10n.t('edit_notes_weather'),
              l10n.t('edit_notes_weather_subtitle'),
              onTap: () => _editDetails(context, l10n),
            ),
            _optionTile(
              sheetContext,
              l10n,
              Icons.copy_outlined,
              l10n.t('duplicate_trip'),
              l10n.t('duplicate_trip_subtitle'),
              onTap: () => _duplicate(context, l10n),
            ),
            _optionTile(
              sheetContext,
              l10n,
              Icons.straighten_outlined,
              l10n.t('manual_distance'),
              l10n.t('manual_distance_subtitle'),
              onTap: () => _correctDistance(context, l10n),
            ),
            _optionTile(
              sheetContext,
              l10n,
              Icons.download_outlined,
              l10n.t('download_gpx'),
              l10n.t('download_gpx_subtitle'),
              onTap: () => _download(context, l10n),
            ),
            const Divider(height: 20),
            _optionTile(
              sheetContext,
              l10n,
              Icons.delete_outline,
              l10n.t('delete_trip'),
              l10n.t('delete_trip_subtitle'),
              destructive: true,
              onTap: () => _delete(context, l10n),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _optionTile(
    BuildContext context,
    AppLocalizations l10n,
    IconData icon,
    String title,
    String subtitle, {
    bool destructive = false,
    required VoidCallback onTap,
  }) => Material(
    color: Colors.transparent,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: destructive
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: destructive ? Theme.of(context).colorScheme.error : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );

  Future<void> _editDetails(BuildContext context, AppLocalizations l10n) async {
    Navigator.pop(context);
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RideEditSheet(
        title: l10n.t('edit_notes_weather'),
        notesLabel: l10n.t('trip_notes'),
        weatherLabel: l10n.t('weather'),
        saveLabel: l10n.t('save'),
        initialNotes: ride.notes,
        initialWeather: ride.weather,
      ),
    );
    if (result == null || widget.repository == null || ride.id == null) return;
    try {
      await widget.repository!.updateRideDetails(
        ride.id!,
        notes: result.$1,
        weather: result.$2,
      );
      if (!mounted) return;
      setState(
        () => ride = ride.copyWith(notes: result.$1, weather: result.$2),
      );
      _feedback(l10n.t('edit_notes_weather'), success: true);
    } catch (_) {
      _feedback(l10n.t('edit_notes_weather'), success: false);
    }
  }

  Future<void> _duplicate(BuildContext context, AppLocalizations l10n) async {
    Navigator.pop(context);
    if (widget.repository == null) {
      return _feedback(l10n.t('duplicate_trip'), success: false);
    }
    try {
      await widget.repository!.duplicateRide(ride);
      _feedback(l10n.t('duplicate_trip'), success: true);
    } catch (_) {
      _feedback(l10n.t('duplicate_trip'), success: false);
    }
  }

  Future<void> _correctDistance(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    Navigator.pop(context);
    final value = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RideDistanceSheet(
        title: l10n.t('manual_distance'),
        distanceLabel: l10n.t('distance'),
        saveLabel: l10n.t('save'),
        initialDistance: ride.distanceKm,
      ),
    );
    if (value == null ||
        value < 0 ||
        widget.repository == null ||
        ride.id == null) {
      return;
    }
    try {
      await widget.repository!.updateRideDistance(ride.id!, value);
      if (!mounted) return;
      setState(() => ride = ride.copyWith(distanceKm: value));
      _feedback(l10n.t('manual_distance'), success: true);
    } catch (_) {
      _feedback(l10n.t('manual_distance'), success: false);
    }
  }

  Future<void> _download(BuildContext context, AppLocalizations l10n) async {
    Navigator.pop(context);
    try {
      final points = await _routePoints;
      if (points.length < 2) {
        return _feedback(l10n.t('gpx_route_unavailable'), success: false);
      }
      final fileName = rideGpxFileName(ride);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(buildRideGpx(ride: ride, points: points)),
              mimeType: 'application/gpx+xml',
              name: fileName,
            ),
          ],
          fileNameOverrides: [fileName],
          subject: l10n.t('download_gpx'),
        ),
      );
      if (mounted) _feedback(l10n.t('download_gpx'), success: true);
    } catch (_) {
      _feedback(l10n.t('download_gpx'), success: false);
    }
  }

  Future<void> _delete(BuildContext context, AppLocalizations l10n) async {
    Navigator.pop(context);
    if (widget.repository == null || ride.id == null) {
      return _feedback(l10n.t('delete_trip'), success: false);
    }
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _RideSheetFrame(
        title: l10n.t('delete_trip'),
        subtitle: l10n.t('delete_trip_subtitle'),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(sheetContext, false),
                child: Text(l10n.t('cancel')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, true),
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.t('delete_trip')),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository!.deleteRide(ride.id!);
      if (context.mounted) Navigator.pop(context, true);
    } catch (_) {
      _feedback(l10n.t('delete_trip'), success: false);
    }
  }

  void _feedback(String message, {required bool success}) {
    if (!mounted) return;
    final colors = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearMaterialBanners()
      ..showMaterialBanner(
        MaterialBanner(
          backgroundColor: success
              ? colors.tertiaryContainer
              : colors.errorContainer,
          leading: Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            color: success ? colors.tertiary : colors.error,
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: messenger.hideCurrentMaterialBanner,
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
            ),
          ],
        ),
      );
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) messenger.hideCurrentMaterialBanner();
    });
  }

  Widget _routePreview(BuildContext context, AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: const ValueKey('ride-route-preview'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          FutureBuilder<List<GeoPoint>>(
            future: _routePoints,
            initialData: const [],
            builder: (context, snapshot) => RideMap(
              points: snapshot.data ?? const [],
              followCurrentLocation: false,
              height: 300,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Icon(Icons.route_outlined, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.t('route_detail'),
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesCard(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('ride-notes'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.t('trip_notes'),
                  // Judul seksi: desain `text-sm font-bold` = w700.
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _editDetails(context, l10n),
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: Text(l10n.t('edit')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ride.notes.isEmpty ? l10n.t('no_trip_notes') : ride.notes,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _distanceMetric(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('distance'),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              text: ride.distanceKm.toStringAsFixed(1),
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
              letterSpacing: -1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _timelineCard(
    BuildContext context,
    AppLocalizations l10n,
    bool active,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_outlined, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.t('ride_timeline'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _timelineRow(
              context,
              color: colors.primary,
              label: l10n.t('started_at'),
              value: _dateTime(context, ride.startedAt),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Container(
                width: 2,
                height: 32,
                color: colors.outlineVariant,
              ),
            ),
            _timelineRow(
              context,
              color: active ? colors.primary : colors.tertiary,
              label: l10n.t('ended_at'),
              value: active
                  ? l10n.t('active_status')
                  : _dateTime(context, ride.endedAt!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(BuildContext context, AppLocalizations l10n, bool active) {
    final colors = Theme.of(context).colorScheme;
    final color = active ? colors.primary : colors.tertiary;

    return StatusBadge(
      label: active ? l10n.t('active_status') : l10n.t('completed_status'),
      foregroundColor: color,
      backgroundColor: color.withValues(alpha: .12),
      icon: Icons.circle,
    );
  }

  Widget _timelineRow(
    BuildContext context, {
    required Color color,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _dateTime(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final material = MaterialLocalizations.of(context);
    final date = material.formatMediumDate(local);
    final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(local));
    return '$date, $time';
  }
}

class _RideSheetFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _RideSheetFrame({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SafeArea(
        top: false,
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
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.secondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _RideEditSheet extends StatefulWidget {
  final String title, notesLabel, weatherLabel, saveLabel;
  final String initialNotes, initialWeather;

  const _RideEditSheet({
    required this.title,
    required this.notesLabel,
    required this.weatherLabel,
    required this.saveLabel,
    required this.initialNotes,
    required this.initialWeather,
  });

  @override
  State<_RideEditSheet> createState() => _RideEditSheetState();
}

class _RideEditSheetState extends State<_RideEditSheet> {
  late final TextEditingController notes;
  late final TextEditingController weather;

  @override
  void initState() {
    super.initState();
    notes = TextEditingController(text: widget.initialNotes);
    weather = TextEditingController(text: widget.initialWeather);
  }

  @override
  void dispose() {
    notes.dispose();
    weather.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _RideSheetFrame(
    title: widget.title,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: notes,
          decoration: InputDecoration(labelText: widget.notesLabel),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: weather,
          decoration: InputDecoration(labelText: widget.weatherLabel),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.pop(context, (
              notes.text.trim(),
              weather.text.trim(),
            )),
            icon: const Icon(Icons.check_rounded),
            label: Text(widget.saveLabel),
          ),
        ),
      ],
    ),
  );
}

class _RideDistanceSheet extends StatefulWidget {
  final String title, distanceLabel, saveLabel;
  final double initialDistance;

  const _RideDistanceSheet({
    required this.title,
    required this.distanceLabel,
    required this.saveLabel,
    required this.initialDistance,
  });

  @override
  State<_RideDistanceSheet> createState() => _RideDistanceSheetState();
}

class _RideDistanceSheetState extends State<_RideDistanceSheet> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.initialDistance.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _RideSheetFrame(
    title: widget.title,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: widget.distanceLabel),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(controller.text.replaceAll(',', '.')),
            ),
            icon: const Icon(Icons.check_rounded),
            label: Text(widget.saveLabel),
          ),
        ),
      ],
    ),
  );
}
