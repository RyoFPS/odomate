import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../i18n/app_localizations.dart';

/// Bottom sheet untuk mengoreksi odometer kendaraan secara manual.
///
/// Menutup dirinya lewat `Navigator.pop(context, value)` dengan angka baru,
/// atau `Navigator.pop(context)` (null) kalau dibatalkan. Pemanggil bertanggung
/// jawab menyimpan nilainya ke repository.
///
/// Dipakai bersama oleh halaman Home dan halaman Services supaya keduanya
/// memakai satu tampilan yang sama.
class OdometerCorrectionSheet extends StatefulWidget {
  final double initialValue;
  final Vehicle? vehicle;
  const OdometerCorrectionSheet({
    super.key,
    required this.initialValue,
    required this.vehicle,
  });

  @override
  State<OdometerCorrectionSheet> createState() =>
      _OdometerCorrectionSheetState();
}

class _OdometerCorrectionSheetState extends State<OdometerCorrectionSheet> {
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
      setState(() => errorText = AppLocalizations.of(context).t('valid_odo'));
      return;
    }
    Navigator.pop(context, next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final vehicleSummary = [
      widget.vehicle?.name,
      widget.vehicle?.plateNumber,
    ].whereType<String>().where((item) => item.isNotEmpty).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        l10n.t('edit_odometer'),
                        // Judul sheet: teks, bukan angka, jadi w700 — dan 18px
                        // supaya sama dengan judul sheet lain ('Riwayat Servis').
                        // titleLarge bawaan 22px, angka yang tidak dipakai desain.
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.t('odometer_sync'),
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
                  tooltip: l10n.t('close'),
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
              l10n.t('new_odo'),
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
                    child: FilledButton(
                      onPressed: () =>
                          _setValue((value ?? widget.initialValue) + amount),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF0F172A),
                        minimumSize: const Size(0, 32),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text('+${amount.toInt()} km'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () => _setValue(widget.initialValue),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF2F2),
                      foregroundColor: colors.error,
                      minimumSize: const Size(0, 32),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(l10n.t('reset')),
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
                      l10n.t('service_estimate_note'),
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
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      side: BorderSide(color: colors.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    child: Text(l10n.t('cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check, size: 18),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    label: Text(l10n.t('save_odometer')),
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
