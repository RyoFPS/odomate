import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/data/odomate_repository.dart';
import 'src/diagnostics/diagnostic_log.dart';
import 'src/notifications/notification_service.dart';
import 'src/tracking/ride_tracker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final diagnostics = DiagnosticLog.instance;
  await diagnostics.initialize();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(diagnostics.recordError(details.exception, details.stack));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(diagnostics.recordError(error, stack));
    return false;
  };

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
