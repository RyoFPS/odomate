import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/service_schedule.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin;
  final OdomateRepository? repository;
  final Map<int, ServiceReminder> _sent = {};
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    this.repository,
  }) : plugin = plugin ?? FlutterLocalNotificationsPlugin();
  Future<void> initialize() async => plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  Future<void> showTrackingActive(double distanceKm) async => plugin.show(
    id: 1,
    title: 'OdoMate sedang merekam perjalanan',
    body: '${distanceKm.toStringAsFixed(1)} km',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'tracking',
        'Tracking',
        channelDescription: 'Ride aktif',
        ongoing: true,
      ),
    ),
  );
  Future<void> clearTrackingActive() async => plugin.cancel(id: 1);
  Future<void> maybeNotifyService(ServiceItem item, double odometerKm) async {
    if (item.id == null) return;
    final persisted = repository == null
        ? NotificationState(lastReminder: _sent[item.id])
        : await repository!.loadNotificationState(item.id!);
    final type = ServiceSchedule.reminderType(odometerKm, item, persisted);
    if (type == null) return;
    _sent[item.id!] = type;
    await repository?.saveNotificationState(
      item.id!,
      NotificationState(cycle: persisted.cycle ?? 0, lastReminder: type),
    );
    await plugin.show(
      id: item.id!,
      title: type == ServiceReminder.due
          ? 'Sudah waktunya servis'
          : 'Servis mendekat',
      body: item.name,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'service',
          'Service reminders',
          channelDescription: 'Pengingat servis',
        ),
      ),
    );
  }

  Future<void> resetService(int serviceItemId) async {
    _sent.remove(serviceItemId);
    await repository?.clearNotificationState(serviceItemId);
  }
}
