import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../i18n/app_localizations.dart';
import '../widgets/plate_number_sheet.dart';

class SetupScreen extends StatefulWidget {
  final OdomateRepository repository;
  final VoidCallback onSaved;
  const SetupScreen({
    super.key,
    required this.repository,
    required this.onSaved,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final userName = TextEditingController();
  final vehicleName = TextEditingController();
  final plateNumber = TextEditingController();
  final odometer = TextEditingController();
  String? error;
  bool saving = false;

  @override
  void dispose() {
    userName.dispose();
    vehicleName.dispose();
    plateNumber.dispose();
    odometer.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final l10n = AppLocalizations.of(context);
    final km = double.tryParse(odometer.text.trim());
    if (userName.text.trim().isEmpty ||
        vehicleName.text.trim().isEmpty ||
        plateNumber.text.trim().isEmpty ||
        km == null ||
        km < 0) {
      setState(() => error = l10n.t('valid_setup'));
      return;
    }

    setState(() {
      error = null;
      saving = true;
    });
    await widget.repository.saveVehicle(
      Vehicle(
        name: vehicleName.text.trim(),
        odometerKm: km,
        userName: userName.text.trim(),
        plateNumber: plateNumber.text.trim().toUpperCase(),
      ),
    );
    for (final n in ['Oli mesin', 'Oli gardan', 'Busi', 'Filter udara']) {
      await widget.repository.saveService(
        ServiceItem(name: n, intervalKm: 1000, lastServicedOdometerKm: km),
      );
    }
    if (!mounted) return;
    setState(() => saving = false);
    widget.onSaved();
  }

  Future<void> _editPlate() async {
    final value = await showPlateNumberSheet(
      context,
      initialValue: plateNumber.text,
    );
    if (value != null && mounted) setState(() => plateNumber.text = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.two_wheeler, color: colors.onPrimary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'OdoMate',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: colors.tertiary),
                          const SizedBox(width: 6),
                          Text(
                            l10n.t('quick_setup'),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.t('step_one'), style: theme.textTheme.bodyMedium),
                  Text(
                    l10n.t('ready_percent'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(value: 1, minHeight: 6),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.t('welcome_odomate'),
                // Judul onboarding: desain memakai `text-2xl font-bold` = w700,
                // bukan extrabold.
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.t('welcome_subtitle'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.secondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SetupField(
                        key: const Key('setup-user-name'),
                        controller: userName,
                        label: l10n.t('your_name_upper'),
                        hint: 'Ryo',
                        helper: l10n.t('name_helper'),
                        icon: Icons.person_outline,
                      ),
                      _SetupField(
                        key: const Key('setup-vehicle-name'),
                        controller: vehicleName,
                        label: l10n.t('vehicle_upper'),
                        hint: 'Honda BeaT',
                        helper: l10n.t('vehicle_helper'),
                        icon: Icons.two_wheeler,
                      ),
                      _SetupField(
                        key: const Key('setup-plate-number'),
                        controller: plateNumber,
                        label: l10n.t('plate_upper'),
                        hint: 'F 6767 FJO',
                        icon: Icons.badge_outlined,
                        textCapitalization: TextCapitalization.characters,
                        onTap: _editPlate,
                      ),
                      _SetupField(
                        key: const Key('setup-odometer'),
                        controller: odometer,
                        label: l10n.t('current_odo_upper'),
                        hint: '16000',
                        helper: l10n.t('odo_helper'),
                        icon: Icons.speed_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        suffix: 'km',
                      ),
                    ],
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: TextStyle(color: colors.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: saving ? null : save,
                icon: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(saving ? l10n.t('saving') : l10n.t('start_using')),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: colors.secondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width - 80,
                    ),
                    child: Text(
                      l10n.t('offline_safe'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final String? helper, suffix;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final VoidCallback? onTap;

  const _SetupField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.helper,
    this.suffix,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.secondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            onTap: onTap,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon),
              suffixText: suffix,
              suffixStyle: TextStyle(
                color: colors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(
              helper!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.secondary),
            ),
          ],
        ],
      ),
    );
  }
}
