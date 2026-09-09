import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';

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
    final km = double.tryParse(odometer.text.trim());
    if (userName.text.trim().isEmpty ||
        vehicleName.text.trim().isEmpty ||
        plateNumber.text.trim().isEmpty ||
        km == null ||
        km < 0) {
      setState(() => error = 'Lengkapi data profil dan odometer yang valid.');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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
                            'Setup Cepat',
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
                  Text('Langkah 1 dari 1', style: theme.textTheme.bodyMedium),
                  Text(
                    '100% Siap',
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
                'Selamat datang di OdoMate',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Catat perjalanan dan rawat kendaraanmu dengan mudah.',
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
                        label: 'NAMA KAMU',
                        hint: 'Ryo',
                        helper: 'Nama panggilan Anda di aplikasi',
                        icon: Icons.person_outline,
                      ),
                      _SetupField(
                        key: const Key('setup-vehicle-name'),
                        controller: vehicleName,
                        label: 'NAMA MOTOR',
                        hint: 'Honda BeaT',
                        helper: 'Merk & tipe motor utama',
                        icon: Icons.two_wheeler,
                      ),
                      _SetupField(
                        key: const Key('setup-plate-number'),
                        controller: plateNumber,
                        label: 'PLAT NOMOR',
                        hint: 'F 6767 FJO',
                        icon: Icons.badge_outlined,
                        textCapitalization: TextCapitalization.characters,
                      ),
                      _SetupField(
                        key: const Key('setup-odometer'),
                        controller: odometer,
                        label: 'ODOMETER SAAT INI (KM)',
                        hint: '16000',
                        helper: 'Angka kilometer di speedometer motor kamu saat ini',
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
                label: Text(
                  saving ? 'Menyimpan...' : 'Mulai menggunakan OdoMate',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: colors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Data tersimpan di perangkat ini (Offline-first & Aman)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary,
                      ),
                      textAlign: TextAlign.center,
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
