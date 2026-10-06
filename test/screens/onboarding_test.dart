import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/app.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/notifications/notification_service.dart';
import 'package:odomate/src/screens/onboarding_screen.dart';
import 'package:odomate/src/screens/setup_screen.dart';
import 'package:odomate/src/tracking/ride_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _Repository extends OdomateRepository {
  @override
  Future<Vehicle?> loadVehicle() async => null;

  @override
  Future<Ride?> loadActiveRide() async => null;

  @override
  Future<List<ServiceItem>> listServices() async => const [];
}

Widget _app(_Repository repository) {
  final notifications = NotificationService(
    initializePlugin: () async {},
    requestNotificationsPermission: () async {},
    cancelTrackingNotification: () async {},
  );
  return OdoMateApp(
    repository: repository,
    tracker: RideTracker(repository),
    notifications: notifications,
  );
}

void main() {
  late InMemorySharedPreferencesAsync preferences;

  setUp(() {
    preferences = InMemorySharedPreferencesAsync.empty();
    SharedPreferencesAsyncPlatform.instance = preferences;
  });

  testWidgets(
    'first launch shows onboarding, skip saves and next launch bypasses it',
    (tester) async {
      await tester.pumpWidget(_app(_Repository()));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(SetupScreen), findsNothing);
      expect(find.byKey(const Key('onboarding-skip')), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding-skip')));
      await tester.pumpAndSettle();

      expect(find.byType(SetupScreen), findsOneWidget);
      expect(
        await SharedPreferencesAsync().getBool('hasSeenOnboarding'),
        isTrue,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_app(_Repository()));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(SetupScreen), findsOneWidget);
    },
  );

  testWidgets('Start on the final page continues to setup', (tester) async {
    await tester.pumpWidget(_app(_Repository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-skip')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-start')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-start')));
    await tester.pumpAndSettle();

    expect(find.byType(SetupScreen), findsOneWidget);
    expect(await SharedPreferencesAsync().getBool('hasSeenOnboarding'), isTrue);
  });
}
