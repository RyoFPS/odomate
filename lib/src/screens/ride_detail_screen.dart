import 'package:flutter/material.dart';

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
        centerTitle: true,
        title: Text(
          l10n.t('ride_detail'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _summaryCard(context, l10n, active, duration, averageSpeed),
          const SizedBox(height: 16),
          _timelineCard(context, l10n, active),
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
            if (averageSpeed != null) ...[
              const SizedBox(height: 16),
              Container(
                key: const ValueKey('ride-average-speed'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.speed_outlined, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.t('average_speed'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      '${averageSpeed.toStringAsFixed(1)} km/${l10n.t('hours_unit')}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
