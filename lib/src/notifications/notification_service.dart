import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/models.dart';
import '../domain/service_schedule.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin;
  final Map<int, ServiceReminder> _sent = {};
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : plugin = plugin ?? FlutterLocalNotificationsPlugin();
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
    final type = ServiceSchedule.reminderType(
      odometerKm,
      item,
      NotificationState(lastReminder: _sent[item.id]),
    );
    if (type == null || item.id == null) return;
    _sent[item.id!] = type;
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
}
