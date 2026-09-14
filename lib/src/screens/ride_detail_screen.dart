import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/models.dart';
import '../domain/ride_history.dart';
import '../i18n/app_localizations.dart';

class RideDetailScreen extends StatelessWidget {
  final Ride ride;

  const RideDetailScreen({super.key, required this.ride});

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
      appBar: AppBar(
        centerTitle: false,
        leadingWidth: 40,
        titleSpacing: 0,
        title: Text(
          l10n.t('ride_detail'),
          // Desain: `text-xl font-bold` = 20px w700, bukan 18px bawaan
          // appBarTheme.
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Bagikan',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _share(context, l10n),
          ),
          IconButton(
            tooltip: 'Opsi lainnya',
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
            Row(
              children: [
                Expanded(
                  child: _detailMetric(
                    context,
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
                  child: _detailMetric(
                    context,
                    key: const ValueKey('ride-estimate'),
                    icon: Icons.local_gas_station_outlined,
                    label: l10n.t('estimate'),
                    value: '— L',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _detailMetric(
                    context,
                    key: const ValueKey('ride-final-odometer'),
                    icon: Icons.speed,
                    label: l10n.t('final_odometer'),
                    value: '— km',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailMetric(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Container(
      key: key,
      padding: const EdgeInsets.all(10),
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
              Icon(icon, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('trip_options'),
                style: Theme.of(sheetContext).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                l10n.t('manage_trip_log'),
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _optionTile(
                sheetContext,
                l10n,
                Icons.edit_note,
                l10n.t('edit_notes_weather'),
                l10n.t('edit_notes_weather_subtitle'),
              ),
              _optionTile(
                sheetContext,
                l10n,
                Icons.copy_outlined,
                l10n.t('duplicate_trip'),
                l10n.t('duplicate_trip_subtitle'),
              ),
              _optionTile(
                sheetContext,
                l10n,
                Icons.straighten_outlined,
                l10n.t('manual_distance'),
                l10n.t('manual_distance_subtitle'),
              ),
              _optionTile(
                sheetContext,
                l10n,
                Icons.download_outlined,
                l10n.t('download_gpx'),
                l10n.t('download_gpx_subtitle'),
              ),
              const Divider(height: 20),
              _optionTile(
                sheetContext,
                l10n,
                Icons.delete_outline,
                l10n.t('delete_trip'),
                l10n.t('delete_trip_subtitle'),
                destructive: true,
              ),
            ],
          ),
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
  }) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      icon,
      color: destructive ? Colors.red : Theme.of(context).colorScheme.primary,
    ),
    title: Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: destructive ? Colors.red : null,
      ),
    ),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      Navigator.pop(context);
      _notAvailable(context, l10n, title);
    },
  );

  void _notAvailable(
    BuildContext context,
    AppLocalizations l10n,
    String action,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action${l10n.t('action_unavailable')}')),
    );
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
          SizedBox(
            height: 168,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _RoutePreviewPainter(colors.primary)),
                Positioned(
                  left: 12,
                  top: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.gps_fixed,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(width: 5),
                          Text(l10n.t('gps_accurate')),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FilledButton.tonalIcon(
                    onPressed: null,
                    icon: const Icon(Icons.fullscreen, size: 14),
                    label: Text(l10n.t('zoom_map')),
                  ),
                ),
              ],
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
                  onPressed: () => _notAvailable(
                    context,
                    l10n,
                    l10n.t('edit_notes_weather'),
                  ),
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
                l10n.t('no_trip_notes'),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 7, color: color),
            const SizedBox(width: 6),
            Text(
              active ? l10n.t('active_status') : l10n.t('completed_status'),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
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

class _RoutePreviewPainter extends CustomPainter {
  final Color routeColor;
  const _RoutePreviewPainter(this.routeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFE8EEF2);
    canvas.drawRect(Offset.zero & size, background);
    final roads = Paint()
      ..color = Colors.white.withValues(alpha: .8)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 18), roads);
    }
    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x - 28, size.height), roads);
    }
    final route = Paint()
      ..color = routeColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * .18, size.height * .76)
      ..lineTo(size.width * .32, size.height * .62)
      ..lineTo(size.width * .48, size.height * .67)
      ..lineTo(size.width * .56, size.height * .42)
      ..lineTo(size.width * .72, size.height * .28);
    canvas.drawPath(path, route);
    canvas.drawCircle(
      Offset(size.width * .18, size.height * .76),
      6,
      Paint()..color = Colors.green.shade700,
    );
    canvas.drawCircle(
      Offset(size.width * .72, size.height * .28),
      6,
      Paint()..color = routeColor,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePreviewPainter oldDelegate) =>
      oldDelegate.routeColor != routeColor;
}
