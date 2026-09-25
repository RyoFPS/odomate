import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../i18n/app_localizations.dart';
import 'service_style.dart';

/// Halaman Tambah / Edit Servis.
///
/// Sumber desainnya `stitch_odomate_modern_ui/odomate_tambah_servis/code.html`:
/// halaman penuh dengan header sendiri, banner kendaraan, pemilih jenis servis,
/// katalog komponen, lalu formulir rinci dan bilah simpan yang menempel di bawah.
///
/// Satu kali simpan menulis dua tabel: `service_items` (jadwal berikutnya) dan
/// `service_logs` (servis yang baru dikerjakan). Tanggal dan odometer di
/// formulir ini adalah servis yang sudah terjadi, bukan jadwal berikutnya —
/// itulah sebabnya keduanya jadi satu baris log, bukan sekadar angka di jadwal.
class ServiceEditorScreen extends StatefulWidget {
  final OdomateRepository repository;

  /// `null` berarti menambah jadwal baru.
  final ServiceItem? service;
  final double odometerKm;
  final Vehicle? vehicle;

  const ServiceEditorScreen({
    super.key,
    required this.repository,
    this.service,
    required this.odometerKm,
    this.vehicle,
  });

  @override
  State<ServiceEditorScreen> createState() => _ServiceEditorScreenState();
}

/// Desain memisahkan servis berkala dari perbaikan sekali jalan. Bedanya di sini
/// hanya satu: katalog komponen ditampilkan untuk servis rutin, dan
/// disembunyikan untuk perbaikan kustom.
enum _ServiceKind { routine, custom }

class _ServiceEditorScreenState extends State<ServiceEditorScreen> {
  final nameController = TextEditingController();
  final intervalController = TextEditingController();
  final costController = TextEditingController();
  final locationController = TextEditingController();
  final notesController = TextEditingController();
  final odoController = TextEditingController();

  _ServiceKind kind = _ServiceKind.routine;
  DateTime serviceDate = DateTime.now();
  int intervalMonths = 0;
  bool remind = true;
  bool saving = false;

  bool get editing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    serviceDate = service?.lastServicedAt ?? DateTime.now();
    intervalMonths = service?.intervalMonths ?? 0;
    nameController.text = service?.name ?? '';
    intervalController.text = service == null
        ? ''
        : service.intervalKm.toStringAsFixed(0);
    costController.text = service == null || service.cost <= 0
        ? ''
        : service.cost.toStringAsFixed(0);
    locationController.text = service?.location ?? '';
    notesController.text = service?.description ?? '';
    // Servis terakhir yang tercatat; untuk jadwal baru, odometer kendaraan saat
    // ini adalah tebakan yang paling masuk akal dan tetap bisa diubah.
    odoController.text = (service?.lastServicedOdometerKm ?? widget.odometerKm)
        .toStringAsFixed(0);
    remind = service?.remind ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    intervalController.dispose();
    costController.dispose();
    locationController.dispose();
    notesController.dispose();
    odoController.dispose();
    super.dispose();
  }

  double? get interval {
    final value = double.tryParse(intervalController.text.trim());
    return value == null || value <= 0 ? null : value;
  }

  String? get serviceOdometer {
    final value = double.tryParse(odoController.text.trim());
    return value == null ? null : odoController.text.trim();
  }

  bool get valid =>
      nameController.text.trim().isNotEmpty &&
      interval != null &&
      serviceOdometer != null;

  /// Target servis berikutnya, ditampilkan sebagai badge di sebelah label
  /// interval. Kosong selama odometer atau intervalnya belum masuk akal.
  String? get targetLabel {
    final odo = double.tryParse(odoController.text.trim());
    final km = interval;
    if (odo == null || km == null) return null;
    return AppLocalizations.of(context)
        .t('service_editor_target')
        .replaceFirst('{value}', serviceKm(odo + km));
  }

  /// Nama yang sedang diketik cocok dengan salah satu entri katalog, jadi
  /// formulir bisa menandainya "Bawaan" seperti di desain.
  bool get isPreset => servicePresets.any(
    (preset) =>
        preset.name == nameController.text.trim() ||
        _presetLabel(context, preset) == nameController.text.trim(),
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: serviceDate,
    );
    if (picked != null) setState(() => serviceDate = picked);
  }

  void _applyPreset(ServicePreset preset) {
    setState(() {
      nameController.text = _presetLabel(context, preset);
      // Preset tanpa angka pabrikan tidak menebak intervalnya — kolomnya
      // dibiarkan seperti semula supaya pengguna yang menentukan.
      if (preset.intervalKm != null) {
        intervalController.text = preset.intervalKm!.toStringAsFixed(0);
      }
    });
  }

  Future<void> _save() async {
    final km = interval;
    final odo = double.tryParse(odoController.text.trim());
    if (km == null || odo == null) return;
    setState(() => saving = true);

    final repository = widget.repository;
    final item = ServiceItem(
      id: widget.service?.id,
      name: _canonicalPresetName(nameController.text.trim()),
      description: notesController.text.trim(),
      location: locationController.text.trim(),
      cost: double.tryParse(costController.text.trim()) ?? 0,
      intervalKm: km,
      lastServicedOdometerKm: odo,
      lastServicedAt: serviceDate,
      intervalMonths: intervalMonths,
      remind: remind,
    );
    final id = await repository.saveService(item);

    // Hanya jadwal yang baru dibuat yang menulis log. Mengedit jadwal — misalnya
    // sekadar mengubah interval — bukan peristiwa servis, jadi riwayatnya tidak
    // boleh bertambah hanya karena formulirnya dibuka dan disimpan lagi.
    // `saveService` sudah memperbarui `last_serviced_km` untuk kasus itu.
    if (!editing) {
      await repository.recordService(
        ServiceLog(serviceItemId: id, servicedAt: serviceDate, odometerKm: odo),
      );
    }
    await repository.clearNotificationState(id);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _canonicalPresetName(String value) {
    for (final preset in servicePresets) {
      if (value == _presetLabel(context, preset)) return preset.name;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          // Ukuran ikonnya dibiarkan bawaan (24) — jaraknya ke judul datang dari
          // appBarTheme, dan ikon yang lebih kecil menggeser tepinya 1px.
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          editing
              ? l10n.t('service_editor_title_edit')
              : l10n.t('service_editor_title_new'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(l10n.t('cancel')),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _vehicleBanner(context),
          const SizedBox(height: 16),
          _kindSegment(context),
          if (kind == _ServiceKind.routine) ...[
            const SizedBox(height: 16),
            _presetCatalogue(context),
          ],
          const SizedBox(height: 16),
          _identityCard(context),
          const SizedBox(height: 16),
          _costCard(context),
          const SizedBox(height: 16),
          _reminderCard(context),
        ],
      ),
      bottomNavigationBar: _saveBar(context),
    );
  }

  /// Banner kendaraan. Desain menaruh tombol "Ganti Motor" di kanan; app ini
  /// menyimpan tepat satu baris `vehicle`, jadi tidak ada motor kedua untuk
  /// dituju dan tombolnya sengaja tidak dibuat.
  Widget _vehicleBanner(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vehicle = widget.vehicle;
    return _card(
      context,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: .08),
              border: Border.all(color: colors.primary.withValues(alpha: .18)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.two_wheeler_rounded,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        vehicle?.name ??
                            AppLocalizations.of(context).t('vehicle_fallback'),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (vehicle?.plateNumber.isNotEmpty == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vehicle!.plateNumber,
                        style: TextStyle(
                          color: colors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      '${AppLocalizations.of(context).t('service_editor_current_odo')}:',
                      style: TextStyle(color: colors.secondary, fontSize: 11),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${serviceKm(widget.odometerKm)} km',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kindSegment(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _kindButton(
              context,
              kind: _ServiceKind.routine,
              icon: Icons.schedule_rounded,
              label: AppLocalizations.of(context).t('service_editor_routine'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _kindButton(
              context,
              kind: _ServiceKind.custom,
              icon: Icons.edit_outlined,
              label: AppLocalizations.of(context).t('service_editor_custom'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kindButton(
    BuildContext context, {
    required _ServiceKind kind,
    required IconData icon,
    required String label,
  }) {
    final colors = Theme.of(context).colorScheme;
    final selected = this.kind == kind;
    return Material(
      color: selected ? colors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: selected ? 1 : 0,
      child: InkWell(
        onTap: () => setState(() => this.kind = kind),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetCatalogue(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 14, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).t('quick_component'),
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context).t('manufacturer_catalog'),
                style: TextStyle(color: colors.outline, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in servicePresets)
                    SizedBox(
                      width: width,
                      child: _presetButton(context, preset),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _presetButton(BuildContext context, ServicePreset preset) {
    final colors = Theme.of(context).colorScheme;
    final selected = nameController.text.trim() == preset.name;
    return Material(
      color: selected
          ? colors.primary.withValues(alpha: .08)
          : colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: () => _applyPreset(preset),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(preset.icon, size: 14, color: colors.onPrimary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _presetLabel(context, preset),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? colors.primary : colors.onSurface,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _presetLabel(BuildContext context, ServicePreset preset) {
    final key = switch (preset.name) {
      'Ganti Oli Mesin' => 'preset_engine_oil',
      'Oli Gardan' => 'preset_gear_oil',
      'Servis CVT & Roller' => 'preset_cvt',
      'Filter Udara' => 'preset_air_filter',
      'Busi (Spark Plug)' => 'preset_spark_plug',
      'Kampas Rem' => 'preset_brake_pad',
      'Aki & Kelistrikan' => 'preset_battery',
      'Ban Depan / Belakang' => 'preset_tires',
      _ => null,
    };
    return key == null ? preset.name : AppLocalizations.of(context).t(key);
  }

  String _timeIntervalLabel(BuildContext context, int months) =>
      AppLocalizations.of(context).t(switch (months) {
        1 => 'service_editor_month_1',
        2 => 'service_editor_month_2',
        3 => 'service_editor_month_3',
        6 => 'service_editor_month_6',
        12 => 'service_editor_month_12',
        _ => 'service_editor_no_time_interval',
      });

  Widget _identityCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(
            context,
            AppLocalizations.of(context).t('service_editor_name'),
            required: true,
            trailing: isPreset
                ? Text(
                    AppLocalizations.of(context).t('default_badge'),
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : null,
          ),
          TextField(
            key: const Key('service-editor-name'),
            controller: nameController,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)
                  .t('service_editor_name_hint'),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(
                      context,
                      AppLocalizations.of(context).t('service_editor_date'),
                      required: true,
                    ),
                    _dateField(context),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(
                      context,
                      AppLocalizations.of(context).t('service_editor_odo'),
                      required: true,
                    ),
                    TextField(
                      key: const Key('service-editor-odometer'),
                      controller: odoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(suffixText: 'km'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _label(
            context,
            AppLocalizations.of(context).t('next_service_interval'),
            trailing: _targetBadge(context),
          ),
          Row(
            children: [
              for (final km in const [2000, 4000, 6000, 10000]) ...[
                Expanded(child: _intervalPill(context, km)),
                if (km != 10000) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('service-editor-interval'),
            controller: intervalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).t('manual_km_hint'),
              suffixText: AppLocalizations.of(context).t('per_km'),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).t('manufacturer_recommendation'),
            style: TextStyle(color: colors.outline, fontSize: 10),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: intervalMonths,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)
                  .t('service_editor_time_interval'),
            ),
            items: [
              for (final months in [0, 1, 2, 3, 6, 12])
                DropdownMenuItem(
                  value: months,
                  child: Text(_timeIntervalLabel(context, months)),
                ),
            ],
            onChanged: (value) => setState(() => intervalMonths = value ?? 0),
          ),
        ],
      ),
    );
  }

  /// Badge "Target: 26.582 km" di sebelah label interval.
  Widget? _targetBadge(BuildContext context) {
    final label = targetLabel;
    if (label == null) return null;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _dateField(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${serviceDate.day}/${serviceDate.month}/${serviceDate.year}',
                style: TextStyle(color: colors.onSurface, fontSize: 12),
              ),
            ),
            Icon(Icons.calendar_today_rounded, size: 14, color: colors.outline),
          ],
        ),
      ),
    );
  }

  Widget _intervalPill(BuildContext context, int km) {
    final colors = Theme.of(context).colorScheme;
    final selected = interval == km.toDouble();
    return Material(
      color: selected ? colors.primary : colors.surfaceContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => setState(() => intervalController.text = km.toString()),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: Text(
              '+${serviceKm(km.toDouble())}',
              style: TextStyle(
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _costCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(
                      context,
                      AppLocalizations.of(context).t('service_editor_cost'),
                      optional: true,
                    ),
                    TextField(
                      key: const Key('service-editor-cost'),
                      controller: costController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: '0',
                        prefixText: 'Rp ',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(
                      context,
                      AppLocalizations.of(context).t('service_editor_workshop'),
                    ),
                    TextField(
                      key: const Key('service-editor-location'),
                      controller: locationController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)
                            .t('service_editor_workshop'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _label(
            context,
            AppLocalizations.of(context).t('service_editor_notes'),
            optional: true,
          ),
          TextField(
            key: const Key('service-editor-notes'),
            controller: notesController,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).t('service_editor_notes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminderCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _card(
      context,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 16,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).t('service_reminder_title'),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: AppLocalizations.of(context)
                        .t('service_reminder_prefix'),
                    children: [
                      TextSpan(
                        text: '500 km',
                        style: TextStyle(
                          color: colors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: AppLocalizations.of(context)
                            .t('service_reminder_suffix'),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: const Key('service-editor-remind'),
            value: remind,
            onChanged: (value) => setState(() => remind = value),
          ),
        ],
      ),
    );
  }

  Widget _saveBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: valid && !saving ? _save : null,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                AppLocalizations.of(context).t(
                  editing
                      ? 'service_editor_save_edit'
                      : 'service_editor_save_new',
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: colors.tertiary,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context).t('saved_offline_local'),
                    style: TextStyle(color: colors.secondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }

  Widget _label(
    BuildContext context,
    String text, {
    bool required = false,
    bool optional = false,
    Widget? trailing,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Flexible(
            child: Text.rich(
              TextSpan(
                text: text,
                children: [
                  if (required)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: colors.error),
                    ),
                  if (optional)
                    TextSpan(
                      text: '  (Opsional)',
                      style: TextStyle(
                        color: colors.outline,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing],
        ],
      ),
    );
  }
}
