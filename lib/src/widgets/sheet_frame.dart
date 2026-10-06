import 'package:flutter/material.dart';

import '../i18n/app_localizations.dart';
import '../tracking/ride_tracker.dart';

/// Bingkai bottom sheet standar OdoMate: drag handle, judul, subjudul opsional.
///
/// Dipakai semua bottom sheet agar tampilan konsisten di seluruh app.
class SheetFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const SheetFrame({
    super.key,
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

/// Bottom sheet konfirmasi standar: tombol Batal + aksi destruktif.
///
/// Me-return `true` jika user menekan tombol konfirmasi, `false` jika
/// membatalkan atau menutup sheet.
Future<bool> showConfirmSheet({
  required BuildContext context,
  required String title,
  String? subtitle,
  required String confirmLabel,
  required String cancelLabel,
  IconData confirmIcon = Icons.delete_outline,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SheetFrame(
      title: title,
      subtitle: subtitle,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(sheetContext, false),
              child: Text(cancelLabel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(sheetContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(sheetContext).colorScheme.error,
              ),
              icon: Icon(confirmIcon),
              label: Text(confirmLabel),
            ),
          ),
        ],
      ),
    ),
  );
  return confirmed == true;
}

Future<void> stopRideWithConfirmation({
  required BuildContext context,
  required RideTracker tracker,
  required AppLocalizations l10n,
}) async {
  final state = tracker.state.value;
  final ride = state.ride;
  if (!state.active || ride == null) return;

  final elapsed = DateTime.now().difference(ride.startedAt);
  final hours = elapsed.inHours;
  final duration = hours > 0
      ? '$hours ${l10n.t('hours_unit')} ${elapsed.inMinutes.remainder(60)} ${l10n.t('minutes_unit')}'
      : '${elapsed.inMinutes} ${l10n.t('minutes_unit')}';
  final confirmed = await showConfirmSheet(
    context: context,
    title: l10n.t('confirm_stop_ride'),
    subtitle:
        '${l10n.t('distance')}: ${ride.distanceKm.toStringAsFixed(1)} km\n'
        '${l10n.t('duration')}: $duration',
    confirmLabel: l10n.t('stop_ride'),
    cancelLabel: l10n.t('cancel'),
    confirmIcon: Icons.stop,
  );
  if (!confirmed || !context.mounted || !tracker.state.value.active) return;
  await tracker.stop();
}
