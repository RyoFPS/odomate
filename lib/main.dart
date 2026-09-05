import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/data/odomate_repository.dart';
import 'src/notifications/notification_service.dart';
import 'src/tracking/ride_tracker.dart';

void main() {
  final repository = OdomateRepository();
  final notifications = NotificationService(repository: repository);
  runApp(
    OdoMateApp(
      repository: repository,
      tracker: RideTracker(repository, notifications: notifications),
      notifications: notifications,
    ),
  );
}
