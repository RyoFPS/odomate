import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/notifications/notification_service.dart';

void main() {
  test('requests Android notification permission during initialization', () async {
    var initialized = false;
    var requested = false;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final service = NotificationService(
      initializePlugin: () async => initialized = true,
      requestNotificationsPermission: () async => requested = true,
      cancelTrackingNotification: () async {},
    );

    await service.initialize();

    expect(initialized, isTrue);
    expect(requested, isTrue);
  });
}
