import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/service_schedule.dart';
import '../i18n/app_localizations.dart';

class ServicesScreen extends StatefulWidget {
  final OdomateRepository repository;
  const ServicesScreen({super.key, required this.repository});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<ServiceItem> items = [];
  double odo = 0;
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final intervalController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    items = await widget.repository.listServices();
    if (items.isEmpty) {
      final vehicle = await widget.repository.loadVehicle();
      if (vehicle != null) {
        for (final service in _defaultServices(vehicle.odometerKm)) {
          await widget.repository.saveService(service);
        }
        items = await widget.repository.listServices();
      }
    }
    odo = (await widget.repository.loadVehicle())?.odometerKm ?? 0;
    if (mounted) setState(() {});
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
    final due = items
        .where((s) => ServiceSchedule.status(odo, s) == ServiceStatus.due)
        .length;
    final soon = items
        .where((s) => ServiceSchedule.status(odo, s) == ServiceStatus.dueSoon)
        .length;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.t('service_title'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _addService,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.t('add_service'),
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(child: Text(l10n.t('empty_services')))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.t('odometer')}: ${odo.toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _countPill(
                              context,
                              '$due ${l10n.t('due')}',
                              Theme.of(context).colorScheme.error,
                            ),
                            _countPill(
                              context,
                              '$soon ${l10n.t('soon')}',
                              const Color(0xFFD97706),
                            ),
                            _countPill(
                              context,
                              '${items.length - due - soon} ${l10n.t('safe')}',
                              const Color(0xFF15803D),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.t('service_schedule'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...items.map((s) => _serviceCard(context, s, l10n)),
              ],
            ),
    );
  }

  Widget _serviceCard(
    BuildContext context,
    ServiceItem service,
    AppLocalizations l10n,
  ) {
    final status = ServiceSchedule.status(odo, service);
    final color = status == ServiceStatus.due
        ? Theme.of(context).colorScheme.error
        : status == ServiceStatus.dueSoon
        ? const Color(0xFFD97706)
        : const Color(0xFF15803D);
    final remaining = service.lastServicedOdometerKm + service.intervalKm - odo;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          foregroundColor: color,
          child: Icon(
            status == ServiceStatus.due
                ? Icons.warning_amber_rounded
                : Icons.build_outlined,
          ),
        ),
        title: Text(
          service.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${remaining.toStringAsFixed(0)} km'),
        trailing: _countPill(context, _statusLabel(status, l10n), color),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServiceDetailScreen(
              repository: widget.repository,
              service: service,
            ),
          ),
        ),
        onLongPress: () => _serviceActions(service),
      ),
    );
  }

  String _statusLabel(ServiceStatus status, AppLocalizations l10n) =>
      status == ServiceStatus.due
      ? l10n.t('due')
      : status == ServiceStatus.dueSoon
      ? l10n.t('soon')
      : l10n.t('safe');

  Widget _countPill(BuildContext context, String text, Color color) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );

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
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tambah servis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama servis'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            TextField(
              controller: intervalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Interval (km)'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    final km = double.tryParse(intervalController.text) ?? 0;
                    if (nameController.text.trim().isNotEmpty && km > 0) {
                      Navigator.pop(context, [
                        nameController.text.trim(),
                        descriptionController.text.trim(),
                        intervalController.text,
                      ]);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    final vehicle = await widget.repository.loadVehicle();
    await widget.repository.saveService(
      ServiceItem(
        name: result[0],
        description: result[1],
        intervalKm: double.parse(result[2]),
        lastServicedOdometerKm: vehicle?.odometerKm ?? 0,
      ),
    );
    await _load();
  }

  Future<void> _serviceActions(ServiceItem service) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit servis'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Hapus servis'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'edit') await _editService(service);
    if (action == 'delete') await _confirmDelete(service);
  }

  Future<void> _editService(ServiceItem service) async {
    nameController.text = service.name;
    descriptionController.text = service.description;
    intervalController.text = service.intervalKm.toStringAsFixed(0);
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit servis', style: Theme.of(context).textTheme.titleLarge),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama servis'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            TextField(
              controller: intervalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Interval (km)'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    final km = double.tryParse(intervalController.text) ?? 0;
                    if (nameController.text.trim().isNotEmpty && km > 0) {
                      Navigator.pop(context, [
                        nameController.text.trim(),
                        descriptionController.text.trim(),
                        intervalController.text,
                      ]);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (result == null || service.id == null) return;
    await widget.repository.saveService(
      ServiceItem(
        id: service.id,
        name: result[0],
        description: result[1],
        intervalKm: double.parse(result[2]),
        lastServicedOdometerKm: service.lastServicedOdometerKm,
      ),
    );
    await _load();
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

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
