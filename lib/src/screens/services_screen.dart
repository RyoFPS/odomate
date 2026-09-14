import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/service_schedule.dart';
import '../i18n/app_localizations.dart';
import '../widgets/odometer_correction_sheet.dart';

const _blue = Color(0xFF2563EB);
const _red = Color(0xFFBE123C);
const _amber = Color(0xFFB45309);
const _green = Color(0xFF047857);

class ServicesScreen extends StatefulWidget {
  final OdomateRepository repository;
  const ServicesScreen({super.key, required this.repository});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<ServiceItem> items = [];
  Vehicle? vehicle;
  bool sortByUrgency = true;
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final intervalController = TextEditingController();

  double get odo => vehicle?.odometerKm ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loadedVehicle = await widget.repository.loadVehicle();
    var loadedItems = await widget.repository.listServices();
    if (loadedItems.isEmpty && loadedVehicle != null) {
      for (final service in _defaultServices(loadedVehicle.odometerKm)) {
        await widget.repository.saveService(service);
      }
      loadedItems = await widget.repository.listServices();
    }
    if (!mounted) return;
    setState(() {
      vehicle = loadedVehicle;
      items = loadedItems;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayedItems = [...items];
    if (sortByUrgency) {
      displayedItems.sort((a, b) {
        final byStatus = _status(b).index.compareTo(_status(a).index);
        return byStatus != 0 ? byStatus : a.name.compareTo(b.name);
      });
    }
    final due = items
        .where((item) => _status(item) == ServiceStatus.due)
        .length;
    final soon = items
        .where((item) => _status(item) == ServiceStatus.dueSoon)
        .length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('service_title'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            if (vehicle != null)
              Text(
                [
                  vehicle!.name,
                  if (vehicle!.plateNumber.isNotEmpty) vehicle!.plateNumber,
                ].join('  •  '),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => sortByUrgency = !sortByUrgency),
            icon: Icon(
              sortByUrgency ? Icons.swap_vert_rounded : Icons.sort_by_alpha,
            ),
            tooltip: sortByUrgency ? 'Urut berdasarkan nama' : 'Urutkan jadwal',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton.filled(
              onPressed: _addService,
              icon: const Icon(Icons.add_rounded),
              tooltip: l10n.t('add_service'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _summaryCard(context, due, soon),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Jadwal Perawatan Berkala',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
                _badge('${items.length} item', const Color(0xFF64748B)),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: _showHistory,
                  icon: const Icon(Icons.history_rounded, size: 17),
                  label: const Text('Riwayat'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (displayedItems.isEmpty)
              _emptyState(context, l10n)
            else
              ...displayedItems.map((item) => _serviceCard(context, item)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 17, color: _green),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'Semua jadwal & riwayat tersimpan lokal (Offline-first)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
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

  Widget _summaryCard(BuildContext context, int due, int soon) {
    final colors = Theme.of(context).colorScheme;
    ServiceItem? dueService;
    for (final item in items) {
      if (_status(item) == ServiceStatus.due) {
        dueService = item;
        break;
      }
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .6)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.speed_rounded, color: _blue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ODOMETER TERKINI',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .7,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        text: _km(odo),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                        children: const [
                          TextSpan(
                            text: '  km',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _updateOdometer,
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: const Text('Perbarui'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: _metric(due, 'Jatuh Tempo', _red)),
              const SizedBox(width: 8),
              Expanded(child: _metric(soon, 'Mendekat', _amber)),
              const SizedBox(width: 8),
              Expanded(
                child: _metric(
                  items.length - due - soon,
                  'Kondisi Aman',
                  _green,
                ),
              ),
            ],
          ),
          if (dueService != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: .07),
                border: Border.all(color: _red.withValues(alpha: .14)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: _red, size: 19),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${dueService.name} perlu segera diservis sebelum perjalanan berikutnya.',
                      style: const TextStyle(
                        color: _red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(int count, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .07),
      border: Border.all(color: color.withValues(alpha: .13)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _emptyState(BuildContext context, AppLocalizations l10n) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        const Icon(Icons.build_circle_outlined, size: 40, color: _blue),
        const SizedBox(height: 10),
        Text(l10n.t('empty_services'), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _addService,
          icon: const Icon(Icons.add),
          label: Text(l10n.t('add_service')),
        ),
      ],
    ),
  );

  Widget _serviceCard(BuildContext context, ServiceItem service) {
    final colors = Theme.of(context).colorScheme;
    final status = _status(service);
    final color = _statusColor(status);
    final dueAt = service.lastServicedOdometerKm + service.intervalKm;
    final remaining = dueAt - odo;

    void openDetail() {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => ServiceDetailScreen(
                repository: widget.repository,
                service: service,
              ),
            ),
          )
          .then((_) => _load());
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: status == ServiceStatus.safe
                ? colors.outlineVariant.withValues(alpha: .55)
                : color.withValues(alpha: .25),
          ),
        ),
        child: InkWell(
          onTap: openDetail,
          onLongPress: () => _serviceActions(service),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    _serviceIcon(service.name),
                    color: color,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            service.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          _badge(_statusLabel(status), color),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Rutin tiap ${_km(service.intervalKm)} km',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text.rich(
                        TextSpan(
                          text: 'Terakhir: ',
                          children: [
                            TextSpan(
                              text: '${_km(service.lastServicedOdometerKm)} km',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: '  •  Batas: '),
                            TextSpan(
                              text: '${_km(dueAt)} km',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remaining < 0
                            ? 'Lewat ${_km(-remaining)} km'
                            : 'Sisa ${_km(remaining)} km',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (service.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest.withValues(
                              alpha: .55,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            service.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                status == ServiceStatus.due
                    ? TextButton.icon(
                        onPressed: openDetail,
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Servis'),
                        style: TextButton.styleFrom(
                          foregroundColor: _red,
                          backgroundColor: _red.withValues(alpha: .07),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : Icon(Icons.chevron_right_rounded, color: colors.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ServiceStatus _status(ServiceItem service) =>
      ServiceSchedule.status(odo, service);

  Color _statusColor(ServiceStatus status) => status == ServiceStatus.due
      ? _red
      : status == ServiceStatus.dueSoon
      ? _amber
      : _green;

  String _statusLabel(ServiceStatus status) => status == ServiceStatus.due
      ? 'Jatuh Tempo'
      : status == ServiceStatus.dueSoon
      ? 'Mendekat'
      : 'Aman';

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
    ),
  );

  IconData _serviceIcon(String name) {
    final value = name.toLowerCase();
    if (value.contains('oli')) return Icons.oil_barrel_outlined;
    if (value.contains('busi') || value.contains('listrik')) {
      return Icons.bolt_rounded;
    }
    if (value.contains('filter')) return Icons.air_rounded;
    if (value.contains('rem')) return Icons.stop_circle_outlined;
    return Icons.build_outlined;
  }

  List<ServiceItem> _defaultServices(double km) => [
    ServiceItem(
      name: 'Oli mesin',
      intervalKm: 2000,
      lastServicedOdometerKm: km,
    ),
    ServiceItem(
      name: 'Oli gardan',
      intervalKm: 8000,
      lastServicedOdometerKm: km,
    ),
    ServiceItem(name: 'Busi', intervalKm: 8000, lastServicedOdometerKm: km),
    ServiceItem(
      name: 'Filter udara',
      intervalKm: 12000,
      lastServicedOdometerKm: km,
    ),
  ];

  Future<void> _addService() async {
    final service = await _showServiceEditor();
    if (service == null) return;
    await widget.repository.saveService(service);
    await _load();
  }

  Future<void> _editService(ServiceItem service) async {
    final edited = await _showServiceEditor(service);
    if (edited == null) return;
    await widget.repository.saveService(edited);
    await _load();
  }

  Future<ServiceItem?> _showServiceEditor([ServiceItem? service]) async {
    final editing = service != null;
    nameController.text = service?.name ?? '';
    descriptionController.text = service?.description ?? '';
    intervalController.text = service == null
        ? ''
        : service.intervalKm.toStringAsFixed(0);
    final presets = <String, double>{
      'Ganti Oli Mesin': 2000,
      'Oli Gardan': 8000,
      'Busi (Spark Plug)': 8000,
      'Filter Udara': 12000,
    };

    return showModalBottomSheet<ServiceItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final interval = double.tryParse(intervalController.text);
          final valid =
              nameController.text.trim().isNotEmpty &&
              interval != null &&
              interval > 0;
          void refresh() => setSheetState(() {});

          return AnimatedPadding(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * .92,
              ),
              child: Column(
                children: [
                  _editorHeader(context, sheetContext, editing),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _vehicleCard(context),
                          if (!editing) ...[
                            const SizedBox(height: 16),
                            _sheetSection(
                              context,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        color: _blue,
                                        size: 17,
                                      ),
                                      SizedBox(width: 7),
                                      Text(
                                        'Pilih Cepat Komponen',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: presets.entries.map((entry) {
                                      final selected =
                                          nameController.text == entry.key;
                                      return ChoiceChip(
                                        selected: selected,
                                        label: Text(entry.key),
                                        avatar: Icon(
                                          _serviceIcon(entry.key),
                                          size: 17,
                                          color: selected ? _blue : null,
                                        ),
                                        onSelected: (_) {
                                          nameController.text = entry.key;
                                          intervalController.text = entry.value
                                              .toStringAsFixed(0);
                                          refresh();
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _editorFields(context, interval, refresh),
                        ],
                      ),
                    ),
                  ),
                  _editorFooter(
                    context,
                    sheetContext,
                    editing,
                    valid,
                    interval,
                    service,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _editorHeader(
    BuildContext context,
    BuildContext sheetContext,
    bool editing,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 12, 12),
    child: Column(
      children: [
        Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    editing ? 'Edit Servis' : 'Tambah Servis',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Pencatatan & Jadwal Perawatan',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Batal'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _editorFields(
    BuildContext context,
    double? interval,
    VoidCallback refresh,
  ) => _sheetSection(
    context,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Nama Servis / Pekerjaan', required: true),
        TextField(
          controller: nameController,
          textInputAction: TextInputAction.next,
          onChanged: (_) => refresh(),
          decoration: const InputDecoration(
            hintText: 'Contoh: Ganti Oli Mesin',
          ),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Interval Servis Berikutnya', required: true),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [2000, 4000, 6000, 10000].map((km) {
            return ChoiceChip(
              selected: interval == km,
              label: Text('+${_km(km.toDouble())}'),
              onSelected: (_) {
                intervalController.text = '$km';
                refresh();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: intervalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          onChanged: (_) => refresh(),
          decoration: const InputDecoration(
            hintText: 'Masukkan kilometer',
            suffixText: 'Tiap km',
          ),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Catatan & Spesifikasi Part'),
        TextField(
          controller: descriptionController,
          minLines: 3,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Catatan servis (opsional)',
          ),
        ),
      ],
    ),
  );

  Widget _editorFooter(
    BuildContext context,
    BuildContext sheetContext,
    bool editing,
    bool valid,
    double? interval,
    ServiceItem? service,
  ) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: valid
                ? () => Navigator.pop(
                    sheetContext,
                    ServiceItem(
                      id: service?.id,
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      intervalKm: interval!,
                      lastServicedOdometerKm:
                          service?.lastServicedOdometerKm ?? odo,
                    ),
                  )
                : null,
            icon: const Icon(Icons.check_rounded),
            label: Text(editing ? 'Simpan Perubahan' : 'Simpan Jadwal Servis'),
          ),
          const SizedBox(height: 7),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined, color: _green, size: 15),
              SizedBox(width: 5),
              Text(
                'Data tersimpan offline di database lokal ponsel',
                style: TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _vehicleCard(BuildContext context) => _sheetSection(
    context,
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _blue.withValues(alpha: .08),
            border: Border.all(color: _blue.withValues(alpha: .15)),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.two_wheeler_rounded, color: _blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle?.name ?? 'Kendaraan',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text.rich(
                TextSpan(
                  text: 'Odometer Saat Ini: ',
                  children: [
                    TextSpan(
                      text: '${_km(odo)} km',
                      style: const TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        if (vehicle?.plateNumber.isNotEmpty == true)
          Text(
            vehicle!.plateNumber,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
      ],
    ),
  );

  Widget _sheetSection(BuildContext context, {required Widget child}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant
                .withValues(alpha: .75),
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  Widget _fieldLabel(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text.rich(
      TextSpan(
        text: text,
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: _red),
                ),
              ]
            : const [],
      ),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );

  Future<void> _updateOdometer() async {
    final value = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          OdometerCorrectionSheet(initialValue: odo, vehicle: vehicle),
    );
    if (value == null || value < 0) return;
    await widget.repository.updateOdometer(value);
    await _load();
  }

  Future<void> _showHistory() async {
    final logs = await widget.repository.listServiceLogs();
    if (!mounted) return;
    final names = {for (final item in items) item.id: item.name};
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Servis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Belum ada riwayat servis.')),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFF6FF),
                        foregroundColor: _blue,
                        child: Icon(Icons.event_available_outlined),
                      ),
                      title: Text(names[log.serviceItemId] ?? 'Servis'),
                      subtitle: Text(_date(log.servicedAt)),
                      trailing: Text(
                        '${_km(log.odometerKm)} km',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _serviceActions(ServiceItem service) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit servis'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: _red),
                title: const Text(
                  'Hapus servis',
                  style: TextStyle(color: _red),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == 'edit') await _editService(service);
    if (action == 'delete') await _confirmDelete(service);
  }

  Future<void> _confirmDelete(ServiceItem service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus kategori servis?'),
        content: Text('Apakah Anda yakin ingin menghapus ${service.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: _red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && service.id != null) {
      await widget.repository.deleteService(service.id!);
      await _load();
    }
  }

  String _km(double value) => value.round().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
}

class ServiceDetailScreen extends StatefulWidget {
  final OdomateRepository repository;
  final ServiceItem service;
  const ServiceDetailScreen({
    super.key,
    required this.repository,
    required this.service,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  late ServiceItem service = widget.service;
  List<ServiceLog> logs = [];
  double odometer = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vehicle = await widget.repository.loadVehicle();
    final allLogs = await widget.repository.listServiceLogs();
    if (!mounted) return;
    setState(() {
      odometer = vehicle?.odometerKm ?? 0;
      logs = allLogs.where((log) => log.serviceItemId == service.id).toList();
    });
  }

  Future<void> _markServiced() async {
    if (service.id == null) return;
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );
    if (date == null) return;
    await widget.repository.recordService(
      ServiceLog(
        serviceItemId: service.id!,
        servicedAt: date,
        odometerKm: odometer,
      ),
    );
    await widget.repository.clearNotificationState(service.id!);
    final updated = service.copyWith(lastServicedOdometerKm: odometer);
    if (!mounted) return;
    setState(() => service = updated);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        service.lastServicedOdometerKm + service.intervalKm - odometer;
    final status = ServiceSchedule.status(odometer, service);
    final statusText = status == ServiceStatus.due
        ? 'Jatuh tempo'
        : status == ServiceStatus.dueSoon
        ? 'Mendekat'
        : 'Aman';
    return Scaffold(
      appBar: AppBar(title: const Text('Detail servis')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(service.name, style: Theme.of(context).textTheme.headlineSmall),
          if (service.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(service.description),
          ],
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              title: const Text('Status'),
              subtitle: Text(statusText),
              trailing: Text('${remaining.toStringAsFixed(0)} km'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Interval'),
              subtitle: Text('${service.intervalKm.toStringAsFixed(0)} km'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Terakhir diservis'),
              subtitle: Text(
                logs.isEmpty
                    ? 'Belum ada catatan'
                    : _date(logs.first.servicedAt),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _markServiced,
            icon: const Icon(Icons.check),
            label: const Text('Tandai selesai'),
          ),
          const SizedBox(height: 24),
          Text('Riwayat servis', style: Theme.of(context).textTheme.titleLarge),
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Belum ada riwayat servis.'),
            ),
          ...logs.map(
            (log) => ListTile(
              leading: const Icon(Icons.event_available),
              title: Text(_date(log.servicedAt)),
              subtitle: Text('${log.odometerKm.toStringAsFixed(1)} km'),
            ),
          ),
        ],
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
