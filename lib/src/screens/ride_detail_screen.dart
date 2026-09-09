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
    final scheme = Theme.of(context).colorScheme;
    final duration = active
        ? l10n.t('active_status')
        : formatRideDuration(
            ride,
            hourSuffix: l10n.t('hours_unit'),
            minuteSuffix: l10n.t('minutes_unit'),
          );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.t('ride_detail'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _sectionLabel(l10n.t('ride_summary')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route_rounded, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.t('gps_recorded'),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      _statusPill(context, active, l10n),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          context,
                          l10n.t('distance'),
                          '${ride.distanceKm.toStringAsFixed(1)} km',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 48,
                        color: scheme.outlineVariant,
                      ),
                      Expanded(
                        child: _metric(context, l10n.t('duration'), duration),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel(l10n.t('ride_timeline')),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Column(
                children: [
                  _timelineRow(
                    context,
                    icon: Icons.radio_button_checked,
                    color: scheme.primary,
                    label: l10n.t('started_at'),
                    value: _dateTime(context, ride.startedAt),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 11),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 2,
                        height: 28,
                        color: scheme.outlineVariant,
                      ),
                    ),
                  ),
                  _timelineRow(
                    context,
                    icon: Icons.location_on_outlined,
                    color: active ? scheme.primary : scheme.tertiary,
                    label: l10n.t('ended_at'),
                    value: active
                        ? l10n.t('active_status')
                        : _dateTime(context, ride.endedAt!),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      );

  Widget _metric(BuildContext context, String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      );

  Widget _statusPill(
    BuildContext context,
    bool active,
    AppLocalizations l10n,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.tertiary;
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
            Icon(Icons.circle, size: 8, color: color),
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
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  static String _dateTime(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(local);
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(local));
    return '$date, $time';
  }
}
