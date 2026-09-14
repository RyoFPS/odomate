import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/service_schedule.dart';
import '../i18n/app_localizations.dart';
import '../widgets/app_header.dart';
import '../widgets/odometer_correction_sheet.dart';
import '../widgets/status_badge.dart';
import 'service_editor_screen.dart';
import 'service_style.dart';

const _blue = serviceBlue;
const _red = serviceRed;
const _green = serviceGreen;
const _black = serviceBlack;

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('service_title'),
              // Desain: `text-xl font-bold tracking-tight`.
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -.4,
              ),
            ),
            if (vehicle != null) _vehicleLine(context),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => sortByUrgency = !sortByUrgency),
            icon: Icon(
              sortByUrgency ? Icons.swap_vert_rounded : Icons.sort_by_alpha,
            ),
            tooltip: sortByUrgency ? 'Urut berdasarkan nama' : 'Urutkan jadwal',
            color: Theme.of(context).colorScheme.secondary,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: _addService,
              // Desain: `w-9 h-9 rounded-xl` — 36×36 dengan sudut 12, bukan
              // tombol bulat bawaan Material.
              icon: const Icon(Icons.add_rounded, size: 22),
              tooltip: l10n.t('add_service'),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                minimumSize: const Size(36, 36),
                maximumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Jadwal Perawatan Berkala',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _countChip('${items.length} item'),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _showHistory,
                  icon: const Icon(Icons.history_rounded, size: 15),
                  label: const Text('Riwayat'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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

  /// Baris kendaraan di bawah judul: ikon motor, nama, lalu plat bernomor
  /// dengan pemisah titik. Desain menaruh plat di `font-mono` — app ini hanya
  /// membawa Poppins, jadi yang dipertahankan adalah bobot dan ukurannya.
  Widget _vehicleLine(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vehicle = this.vehicle!;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(Icons.two_wheeler_rounded, size: 14, color: colors.primary),
          const SizedBox(width: 4),
          Text(
            vehicle.name,
            style: TextStyle(
              color: colors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (vehicle.plateNumber.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              '•',
              style: TextStyle(color: colors.outlineVariant, fontSize: 12),
            ),
            const SizedBox(width: 4),
            Text(
              vehicle.plateNumber,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: .2,
              ),
            ),
          ],
        ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.surfaceContainer),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.speed_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ODOMETER TERKINI',
                          style: TextStyle(
                            color: colors.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: .6,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            text: serviceKm(odo),
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.4,
                            ),
                            children: [
                              TextSpan(
                                text: ' km',
                                style: TextStyle(
                                  color: colors.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0,
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
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    label: const Text('Perbarui'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _metric(due, 'Jatuh Tempo', ServiceStatus.due),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metric(soon, 'Mendekat', ServiceStatus.dueSoon),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metric(
                      items.length - due - soon,
                      'Kondisi Aman',
                      ServiceStatus.safe,
                    ),
                  ),
                ],
              ),
            ),
            if (dueService != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: .06),
                  border: Border.all(color: _red.withValues(alpha: .12)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.warning_rounded, color: _red, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${dueService.name} perlu segera diservis sebelum perjalanan berikutnya.',
                        style: const TextStyle(
                          color: _red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Kotak metrik di kartu ringkasan. Desain: `py-2 px-1 rounded-xl` dengan
  /// latar shade -50, garis shade -100, dan label 10px.
  Widget _metric(int count, String label, ServiceStatus status) {
    final tone = serviceTone(status, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: tone.soft,
        border: Border.all(color: tone.softBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: tone.metricNumber,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tone.metricLabel,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, AppLocalizations l10n) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(Icons.build_circle_outlined, size: 40, color: _black),
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
    ),
  );

  Widget _serviceCard(BuildContext context, ServiceItem service) {
    final colors = Theme.of(context).colorScheme;
    final status = _status(service);
    final tone = serviceTone(status, colors);
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
      child: Card(
        child: InkWell(
          onTap: openDetail,
          onLongPress: () => _serviceActions(service),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: tone.soft,
                          border: Border.all(color: tone.softBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          serviceIcon(service.name),
                          color: tone.icon,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  service.name,
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                  ),
                                ),
                                _statusBadge(_statusLabel(status), tone),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rutin Tiap ${serviceKm(service.intervalKm)} km',
                              style: TextStyle(
                                color: colors.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Terakhir: ',
                                    style: TextStyle(color: colors.secondary),
                                  ),
                                  TextSpan(
                                    text:
                                        '${serviceKm(service.lastServicedOdometerKm)} km',
                                    style: TextStyle(
                                      color: colors.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' • ',
                                    style: TextStyle(
                                      color: colors.outlineVariant,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Batas: ',
                                    style: TextStyle(color: colors.secondary),
                                  ),
                                  TextSpan(
                                    text: '${serviceKm(dueAt)} km',
                                    style: TextStyle(
                                      color: colors.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Desain hanya menandai "Lewat" dengan ikon error;
                            // "Sisa" pada item mendekat tetap polos, dan pada
                            // item aman justru abu-abu — bukan hijau.
                            Row(
                              children: [
                                if (status == ServiceStatus.due) ...[
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Color(0xFFE11D48),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  remaining < 0
                                      ? 'Lewat ${serviceKm(-remaining)} km'
                                      : 'Sisa ${serviceKm(remaining)} km',
                                  style: TextStyle(
                                    color: tone.line,
                                    fontSize: 12,
                                    fontWeight: status == ServiceStatus.safe
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (status == ServiceStatus.due)
                  Material(
                    key: const ValueKey('service-card-mark-serviced'),
                    color: tone.soft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: tone.card),
                    ),
                    child: InkWell(
                      onTap: openDetail,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: tone.chipText,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Servis',
                              style: TextStyle(
                                color: tone.chipText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: colors.secondary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ServiceStatus _status(ServiceItem service) =>
      ServiceSchedule.status(odo, service);

  String _statusLabel(ServiceStatus status) => status == ServiceStatus.due
      ? 'Jatuh Tempo'
      : status == ServiceStatus.dueSoon
      ? 'Mendekat'
      : 'Aman';

  Widget _statusBadge(String text, ServiceTone tone) => Container(
    key: const ValueKey('service-card-status-badge'),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: tone.chipBg,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: tone.chipText,
        fontSize: 10,
        fontWeight: tone.chipWeight,
        letterSpacing: -.1,
      ),
    ),
  );

  /// Penghitung "6 item" di sebelah judul bagian. Desain memakai `rounded-md`
  /// dengan latar surface-container, bukan pill berwarna seperti badge status.
  Widget _countChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.secondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  /// Jadwal awal untuk kendaraan baru. Hanya komponen yang intervalnya tercatat
  /// di [servicePresets] yang dipakai — preset tanpa angka tidak diikutkan,
  /// supaya app tidak mengarang jadwal servis yang tidak diminta pengguna.
  List<ServiceItem> _defaultServices(double km) => [
    for (final preset in servicePresets)
      if (preset.intervalKm != null)
        ServiceItem(
          name: preset.name,
          intervalKm: preset.intervalKm!,
          lastServicedOdometerKm: km,
        ),
  ];

  Future<void> _addService() async {
    final saved = await _openEditor();
    if (saved != true) return;
    await _load();
  }

  Future<void> _editService(ServiceItem service) async {
    final saved = await _openEditor(service);
    if (saved != true) return;
    await _load();
  }

  /// Membuka halaman Tambah/Edit Servis, dan melaporkan apakah ada perubahan
  /// yang tersimpan. Penulisannya sendiri ada di dalam halaman itu, karena satu
  /// kali simpan bisa menyentuh dua tabel: jadwal servis dan log servisnya.
  Future<bool?> _openEditor([ServiceItem? service]) =>
      Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ServiceEditorScreen(
            repository: widget.repository,
            service: service,
            odometerKm: odo,
            vehicle: vehicle,
          ),
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
              // Judul sheet: teks, bukan angka, jadi w700 seperti `font-bold`.
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                        '${serviceKm(log.odometerKm)} km',
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
    final tone = serviceTone(status, Theme.of(context).colorScheme);
    final target = service.lastServicedOdometerKm + service.intervalKm;
    final progress = service.intervalKm == 0
        ? 0.0
        : ((odometer - service.lastServicedOdometerKm) / service.intervalKm)
              .clamp(0.0, 1.0);
    final statusText = status == ServiceStatus.due
        ? 'Jatuh tempo'
        : status == ServiceStatus.dueSoon
        ? 'Mendekat'
        : 'Aman';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(
        title: 'Detail servis',
        titleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          _hero(context, tone, statusText, remaining),
          const SizedBox(height: 14),
          _progressCard(context, tone, progress, remaining, target),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _detailTile(
                  context,
                  Icons.repeat_rounded,
                  'Interval servis',
                  '${serviceKm(service.intervalKm)} km',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _detailTile(
                  context,
                  Icons.history_rounded,
                  'Terakhir servis',
                  logs.isEmpty ? 'Belum ada' : _date(logs.first.servicedAt),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _markServiced,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Tandai sudah servis'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Riwayat servis',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              _historyCount(context),
            ],
          ),
          const SizedBox(height: 10),
          if (logs.isEmpty) _emptyHistory(context),
          ...logs.map((log) => _historyCard(context, log)),
        ],
      ),
    );
  }

  Widget _hero(
    BuildContext context,
    ServiceTone tone,
    String status,
    double remaining,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tone.soft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tone.softBorder),
            ),
            child: Icon(serviceIcon(service.name), color: tone.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (service.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    service.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                StatusBadge(
                  label: status,
                  foregroundColor: tone.chipText,
                  backgroundColor: tone.chipBg,
                  icon: Icons.circle,
                ),
              ],
            ),
          ),
          Text(
            remaining < 0 ? 'Lewat' : 'Sisa',
            style: TextStyle(color: tone.line, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );

  Widget _progressCard(
    BuildContext context,
    ServiceTone tone,
    double progress,
    double remaining,
    double target,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status perawatan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: tone.icon,
              backgroundColor: tone.soft,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  remaining < 0
                      ? 'Lewat ${serviceKm(-remaining)} km'
                      : 'Sisa ${serviceKm(remaining)} km',
                  style: TextStyle(
                    color: tone.line,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Target berikutnya',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${serviceKm(target)} km',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _detailTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );

  Widget _historyCount(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '${logs.length} entri',
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );

  Widget _emptyHistory(BuildContext context) => Card(
    child: const Padding(
      padding: EdgeInsets.all(18),
      child: Text('Belum ada riwayat servis.'),
    ),
  );

  Widget _historyCard(BuildContext context, ServiceLog log) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer
              .withValues(alpha: .28),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.event_available_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        _date(log.servicedAt),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('${serviceKm(log.odometerKm)} km'),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
