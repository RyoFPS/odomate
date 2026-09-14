import 'package:flutter/material.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/service_schedule.dart';
import '../i18n/app_localizations.dart';
import 'services_screen.dart';

/// Aksen warna kartu, mengikuti empat varian kartu di desain Stitch: biru untuk
/// ride yang sedang direkam, amber untuk peringatan servis, hijau untuk
/// perjalanan selesai, dan slate untuk info profil.
enum _Tone { ride, service, done, profile }

/// Apa yang terjadi kalau aksi kartu ditekan.
enum _ActionKind { none, liveRide, schedule }

class NotificationsScreen extends StatefulWidget {
  final OdomateRepository repository;
  const NotificationsScreen({super.key, required this.repository});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<_NotificationEntry>> future;
  String filter = 'all';
  bool allRead = false;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  /// Mengumpulkan entri dari data yang benar-benar ada di perangkat. Isinya
  /// sengaja tidak dirakit di sini: penyusunan kalimatnya butuh `l10n`, dan itu
  /// baru tersedia saat `build`.
  Future<List<_NotificationEntry>> _load() async {
    final vehicle = await widget.repository.loadVehicle();
    final active = await widget.repository.loadActiveRide();
    final rides = await widget.repository.listRides();
    final services = await widget.repository.listServices();
    final odo = vehicle?.odometerKm ?? 0;
    final entries = <_NotificationEntry>[];

    if (active != null) {
      entries.add(
        _NotificationEntry(
          kind: 'ride',
          tone: _Tone.ride,
          icon: Icons.navigation,
          titleKey: 'active_ride_notification',
          subject: vehicle?.name ?? '',
          value: active.distanceKm,
          time: active.startedAt,
          unread: true,
          action: _ActionKind.liveRide,
        ),
      );
    }

    for (final service in services) {
      final status = ServiceSchedule.status(odo, service);
      if (status == ServiceStatus.safe) continue;
      entries.add(
        _NotificationEntry(
          kind: 'service',
          tone: _Tone.service,
          icon: Icons.build,
          titleKey: status == ServiceStatus.due
              ? 'service_due_notification'
              : 'service_soon_notification',
          subject: service.name,
          value: service.lastServicedOdometerKm +
              service.intervalKm -
              odo,
          time: DateTime.now(),
          unread: true,
          action: _ActionKind.schedule,
        ),
      );
    }

    // Perjalanan yang sudah selesai masuk bagian "Sebelumnya".
    final finished = rides.where((ride) => ride.endedAt != null);
    if (finished.isNotEmpty) {
      final ride = finished.first;
      entries.add(
        _NotificationEntry(
          kind: 'ride',
          tone: _Tone.done,
          icon: Icons.check_circle,
          titleKey: 'ride_completed_notification',
          subject: '',
          value: ride.distanceKm,
          time: ride.startedAt,
          unread: false,
          action: _ActionKind.none,
          duration: _duration(ride),
        ),
      );
    }

    if (vehicle != null) {
      entries.add(
        _NotificationEntry(
          kind: 'profile',
          tone: _Tone.profile,
          icon: Icons.person,
          titleKey: 'profile_saved_notification',
          subject: vehicle.name,
          userName: vehicle.userName,
          unread: false,
          action: _ActionKind.none,
        ),
      );
    }

    return entries;
  }

  String _duration(Ride ride) {
    final ended = ride.endedAt;
    if (ended == null) return '';
    final minutes = ended.difference(ride.startedAt).inMinutes;
    return '${minutes ~/ 60 > 0 ? '${minutes ~/ 60}h ' : ''}${minutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.t('notifications'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => allRead = true),
            child: Text(l10n.t('mark_all_read')),
          ),
        ],
      ),
      body: FutureBuilder<List<_NotificationEntry>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final visible = snapshot.data!
              .where((entry) => filter == 'all' || entry.kind == filter)
              .toList();
          final today = <_NotificationEntry>[];
          final earlier = <_NotificationEntry>[];
          for (final entry in visible) {
            _isToday(entry.time) ? today.add(entry) : earlier.add(entry);
          }
          return ListView(
            // 14 = pt-3.5 dan 40 = pb-10 di desain.
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
            children: [
              _filters(context, l10n, visible),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                _empty(context, l10n)
              else ...[
                if (today.isNotEmpty) _section(context, l10n, 'today_period', today),
                if (today.isNotEmpty && earlier.isNotEmpty)
                  const SizedBox(height: 16),
                if (earlier.isNotEmpty)
                  _section(
                    context,
                    l10n,
                    'previous_period',
                    earlier,
                    trailing: l10n.t('stored_locally'),
                  ),
              ],
              const SizedBox(height: 12),
              _footer(context, l10n),
            ],
          );
        },
      ),
    );
  }

  bool _isToday(DateTime? value) {
    if (value == null) return false;
    final now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  void _runAction(BuildContext context, _ActionKind action) {
    switch (action) {
      // Kembali ke Home: di situlah UI perekaman ride berjalan.
      case _ActionKind.liveRide:
        Navigator.pop(context);
      case _ActionKind.schedule:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServicesScreen(repository: widget.repository),
          ),
        );
      case _ActionKind.none:
        break;
    }
  }

  /// Chip filter. Ukurannya mengikuti desain — `px-3.5 py-1.5 rounded-full
  /// text-xs` dengan lebar intrinsik, bukan melebar memenuhi baris.
  Widget _filters(
    BuildContext context,
    AppLocalizations l10n,
    List<_NotificationEntry> visible,
  ) {
    final labels = <String, String>{
      'all': l10n.t('all_period'),
      'ride': l10n.t('notification_rides'),
      'service': l10n.t('notification_services'),
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in labels.entries) ...[
            _filter(context, l10n, entry.value, entry.key, visible),
            if (entry.key != labels.keys.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _filter(
    BuildContext context,
    AppLocalizations l10n,
    String label,
    String value,
    List<_NotificationEntry> visible,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selected = filter == value;
    // Badge hanya muncul di chip yang sedang aktif, seperti di desain.
    final unread = visible
        .where((entry) => entry.kind == value || value == 'all')
        .where((entry) => entry.unread)
        .length;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: .12)
          : scheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? scheme.primaryContainer.withValues(alpha: .45)
              : scheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => filter = value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? scheme.primary : scheme.secondary,
                ),
              ),
              if (selected && unread > 0 && !allRead) ...[
                const SizedBox(width: 6),
                Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unread',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Judul bagian: label kecil huruf kapital berwarna abu-abu, titik biru, dan
  /// keterangan di sisi kanan.
  Widget _section(
    BuildContext context,
    AppLocalizations l10n,
    String titleKey,
    List<_NotificationEntry> entries, {
    String? trailing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final unread = entries.where((entry) => entry.unread).length;
    final note = trailing ??
        ((unread > 0 && !allRead) ? '$unread ${l10n.t('new_suffix')}' : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l10n.t(titleKey).toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: scheme.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
            const Spacer(),
            if (note != null)
              Text(
                note,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: scheme.secondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _entry(context, l10n, entries[i]),
        ],
      ],
    );
  }

  Widget _entry(
    BuildContext context,
    AppLocalizations l10n,
    _NotificationEntry entry,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = _accent(context, entry.tone);
    final segments = _description(context, l10n, entry);
    return Material(
      color: scheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(entry.icon, size: 20, color: foreground),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.t(entry.titleKey),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      if (entry.unread && !allRead) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(children: segments),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Kartu profil tidak punya waktu penyimpanan yang jujur
                      // untuk ditampilkan (tabel `vehicle` tidak menyimpan
                      // timestamp), jadi slot kiri dibiarkan kosong daripada
                      // memakai waktu karangan.
                      if (entry.time != null)
                        Text(
                          _time(context, l10n, entry.time!),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: scheme.secondary,
                          ),
                        ),
                      const Spacer(),
                      entry.action == _ActionKind.none
                          ? _marker(context, l10n, entry)
                          : _action(context, l10n, entry, foreground),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Susunan kalimat deskripsi per jenis kartu. Angka penting di tengah kalimat
  /// dibuat tebal, meniru `<span class="font-semibold">` di desain.
  List<InlineSpan> _description(
    BuildContext context,
    AppLocalizations l10n,
    _NotificationEntry entry,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final (_, foreground) = _accent(context, entry.tone);
    final value = entry.value;
    final km = value == null ? '' : _number(value);
    InlineSpan strong(String text, [Color? color]) => TextSpan(
      text: text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: color ?? scheme.onSurface,
      ),
    );
    switch (entry.tone) {
      case _Tone.ride:
        return [
          TextSpan(
            text: '${l10n.t('active_ride_description')} ${entry.subject}. ',
          ),
          strong('$km km'),
          TextSpan(text: ' ${l10n.t('active_ride_recorded')}'),
        ];
      case _Tone.service:
        return [
          TextSpan(
            text:
                '${entry.subject}: ${l10n.t('service_remaining_before')} ',
          ),
          strong('$km km', foreground),
          TextSpan(text: ' ${l10n.t('service_remaining_after')}'),
        ];
      case _Tone.done:
        return [
          strong('$km km'),
          TextSpan(
            text: entry.duration == null || entry.duration!.isEmpty
                ? ''
                : ' · ${entry.duration}',
          ),
        ];
      case _Tone.profile:
        return [
          TextSpan(text: '${l10n.t('profile_saved_before')} '),
          if (entry.userName != null && entry.userName!.isNotEmpty)
            TextSpan(
              text:
                  '${entry.userName} ${l10n.t('profile_saved_and_vehicle')} ',
            ),
          TextSpan(text: entry.subject),
          TextSpan(text: ' ${l10n.t('profile_saved_after')}'),
        ];
    }
  }

  /// Tombol aksi di kanan bawah kartu.
  Widget _action(
    BuildContext context,
    AppLocalizations l10n,
    _NotificationEntry entry,
    Color foreground,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final labelKey = switch (entry.action) {
      _ActionKind.liveRide => 'view_live_ride_action',
      _ActionKind.schedule => 'schedule_service_action',
      _ActionKind.none => null,
    };
    if (labelKey == null) return const SizedBox.shrink();
    final label = l10n.t(labelKey);
    if (entry.tone == _Tone.ride) {
      // Kartu ride aktif memakai tombol terisi penuh.
      return Material(
        color: scheme.primaryContainer,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _runAction(context, entry.action),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: scheme.onPrimary,
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Kartu servis memakai tautan teks biasa.
    return InkWell(
      onTap: () => _runAction(context, entry.action),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_forward, size: 13, color: scheme.primary),
          ],
        ),
      ),
    );
  }

  /// Penanda status di kartu yang sudah selesai — hijau untuk yang tersinkron,
  /// abu-abu untuk keterangan penyimpanan biasa.
  Widget _marker(
    BuildContext context,
    AppLocalizations l10n,
    _NotificationEntry entry,
  ) {
    final scheme = Theme.of(context).colorScheme;
    if (entry.tone == _Tone.done) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt, size: 13, color: scheme.tertiary),
          const SizedBox(width: 4),
          Text(
            l10n.t('synced'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: scheme.tertiary,
            ),
          ),
        ],
      );
    }
    return Text(
      'Database SQLite v2',
      style: TextStyle(fontSize: 11, color: scheme.secondary),
    );
  }

  (Color, Color) _accent(BuildContext context, _Tone tone) {
    final scheme = Theme.of(context).colorScheme;
    switch (tone) {
      case _Tone.ride:
        return (
          scheme.primaryContainer.withValues(alpha: .12),
          scheme.primary,
        );
      case _Tone.service:
        const amber = Color(0xFFD97706);
        return (amber.withValues(alpha: .15), amber);
      case _Tone.done:
        return (
          scheme.tertiary.withValues(alpha: .15),
          scheme.tertiary,
        );
      case _Tone.profile:
        return (
          scheme.onSurfaceVariant.withValues(alpha: .12),
          scheme.onSurfaceVariant,
        );
    }
  }

  Widget _footer(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: .6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off, size: 18, color: scheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.t('notifications_local_note'),
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: scheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(l10n.t('empty_notifications')),
        ],
      ),
    ),
  );

  /// "07:45 WIB", "Kemarin, 07:15 WIB", atau "12/9/26, 06:10 WIB".
  String _time(BuildContext context, AppLocalizations l10n, DateTime value) {
    final clock =
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    if (sameDay(value, now)) return '$clock WIB';
    if (sameDay(value, yesterday)) {
      return '${l10n.t('yesterday')}, $clock WIB';
    }
    return '${value.day}/${value.month}/${value.year % 100}, $clock WIB';
  }

  /// Angka jarak dengan koma sebagai pemisah desimal, seperti di desain
  /// ("6,2 km"). Di locale Inggris titik tetap lebih lazim, tapi desain memakai
  /// koma dan app ini berbahasa Indonesia sebagai default.
  String _number(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');
}

class _NotificationEntry {
  final String kind;
  final _Tone tone;
  final IconData icon;
  final String titleKey;
  final String subject;
  final String? userName;
  final double? value;
  final DateTime? time;
  final bool unread;
  final _ActionKind action;
  final String? duration;

  const _NotificationEntry({
    required this.kind,
    required this.tone,
    required this.icon,
    required this.titleKey,
    required this.subject,
    required this.unread,
    required this.action,
    this.userName,
    this.value,
    this.time,
    this.duration,
  });
}
