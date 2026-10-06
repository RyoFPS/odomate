import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:odomate/src/app.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/domain/ride_statistics.dart';
import 'package:odomate/src/screens/home_screen.dart';
import 'package:odomate/src/screens/history_screen.dart';
import 'package:odomate/src/screens/profile_screen.dart';
import 'package:odomate/src/screens/ride_detail_screen.dart';
import 'package:odomate/src/screens/statistics_screen.dart';
import 'package:odomate/src/tracking/ride_tracker.dart';

class _FakeRepository extends OdomateRepository {
  final List<Ride> rides;
  final bool rejectRideList;
  Ride? activeRide;
  final List<GeoPoint> points = [];

  _FakeRepository({this.rides = const [], this.rejectRideList = false});

  @override
  Future<Vehicle?> loadVehicle() async =>
      const Vehicle(name: 'Test', odometerKm: 0);

  @override
  Future<List<Ride>> listRides() async {
    if (rejectRideList) throw StateError('Home must use SQL aggregates');
    return rides;
  }

  @override
  Future<List<DailyRideStatistics>> aggregateRideStatistics(
    DateTime from,
    DateTime until,
  ) async => const [];

  @override
  Future<List<Ride>> listRidesPage({
    required int limit,
    required int offset,
  }) async => rides.skip(offset).take(limit).toList();

  @override
  Future<List<ServiceItem>> listServices() async => const [];

  @override
  Future<List<ServiceLog>> listServiceLogs() async => const [];

  @override
  Future<List<ServiceLog>> listServiceLogsPage({
    required int limit,
    required int offset,
  }) async => const [];

  @override
  Future<int> createRide(Ride ride) async {
    activeRide = ride.copyWith(id: 1);
    return 1;
  }

  @override
  Future<Ride?> loadActiveRide() async => activeRide;

  @override
  Future<void> saveActiveRideCheckpoint(Ride ride) async {
    activeRide = ride;
  }

  @override
  Future<void> appendRidePoint(int rideId, GeoPoint point) async {
    points.add(point);
  }

  @override
  Future<List<GeoPoint>> listRidePoints(int rideId) async => points;
}

/// Meniru halaman Profile: ada TextField yang memunculkan keyboard.
class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: TextField()));
}

class _FakeTracker extends RideTracker {
  final _state = ValueNotifier(const RideTrackingState());
  int startCount = 0;
  int stopCount = 0;

  _FakeTracker(super.repository);

  @override
  ValueListenable<RideTrackingState> get state => _state;

  @override
  Future<void> start() async {
    startCount++;
    _state.value = const RideTrackingState(active: true);
  }

  @override
  Future<Ride> stop() async {
    stopCount++;
    _state.value = const RideTrackingState();
    return Ride(startedAt: DateTime.now(), endedAt: DateTime.now());
  }
}

void main() {
  testWidgets('bottom navigation preserves four tabs and ride action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigation(
          pages: const [
            Text('Home page'),
            Text('History page'),
            Text('Service page'),
            Text('Profile page'),
          ],
          rideActive: false,
          onRide: () {},
        ),
      ),
    );
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.byTooltip('Start Ride'), findsOneWidget);
    expect(find.text('Service'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Home and global ride controls stay reachable and signal STOP', (
    tester,
  ) async {
    final repository = _FakeRepository();
    final tracker = _FakeTracker(repository);
    await tester.pumpWidget(
      MaterialApp(
        theme: odomateTheme(Brightness.light),
        home: MainNavigation(
          pages: [
            HomeScreen(repository: repository, tracker: tracker),
            const Text('History page'),
            const Text('Service page'),
            const Text('Profile page'),
          ],
          tracker: tracker,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final homeControl = find.byKey(const ValueKey('home-ride-control'));
    final globalControl = find.byKey(const ValueKey('global-ride-control'));
    final card = find.byType(Card).first;
    final theme = odomateTheme(Brightness.light);
    expect(tester.getSize(homeControl).height, 64);
    expect(tester.getSize(homeControl).width, tester.getSize(card).width - 32);
    expect(tester.getSize(globalControl).height, 64);
    final fabBounds = tester.getRect(globalControl);
    final viewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(fabBounds.top, greaterThanOrEqualTo(0));
    expect(fabBounds.bottom, lessThanOrEqualTo(viewportHeight));
    expect(
      tester.getCenter(globalControl).dx,
      tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
    );
    expect(find.byTooltip('Start Ride'), findsOneWidget);
    final startButton = tester.widget<FilledButton>(
      find.descendant(of: homeControl, matching: find.byType(FilledButton)),
    );
    final startFab = tester.widget<FloatingActionButton>(
      find.descendant(
        of: globalControl,
        matching: find.byType(FloatingActionButton),
      ),
    );
    expect(
      startButton.style!.backgroundColor!.resolve({}),
      theme.colorScheme.primary,
    );
    expect(startFab.backgroundColor, theme.colorScheme.primary);

    await tester.tap(homeControl);
    await tester.pump();
    expect(tracker.startCount, 1);
    expect(tracker.state.value.active, isTrue);
    await tester.pump(const Duration(milliseconds: 220));

    final stopButton = tester.widget<FilledButton>(
      find.descendant(of: homeControl, matching: find.byType(FilledButton)),
    );
    final floatingButton = tester.widget<FloatingActionButton>(
      find.descendant(
        of: globalControl,
        matching: find.byType(FloatingActionButton),
      ),
    );
    expect(find.text('Stop Ride'), findsOneWidget);
    expect(find.byTooltip('Stop Ride'), findsOneWidget);
    expect(
      stopButton.style!.backgroundColor!.resolve({}),
      theme.colorScheme.error,
    );
    expect(
      stopButton.style!.foregroundColor!.resolve({}),
      theme.colorScheme.onError,
    );
    expect(floatingButton.backgroundColor, theme.colorScheme.error);
    expect(floatingButton.foregroundColor, theme.colorScheme.onError);
    expect(find.byIcon(Icons.stop), findsNWidgets(2));
    expect(
      tester
          .widget<ScaleTransition>(
            find.descendant(
              of: homeControl,
              matching: find.byType(ScaleTransition),
            ),
          )
          .scale
          .value,
      greaterThan(1),
    );
    expect(
      tester
          .widget<ScaleTransition>(
            find.descendant(
              of: globalControl,
              matching: find.byType(ScaleTransition),
            ),
          )
          .scale
          .value,
      greaterThan(1),
    );

    await tester.tap(
      find.descendant(of: globalControl, matching: find.byIcon(Icons.stop)),
    );
    await tester.pump();
    expect(tracker.stopCount, 1);
    expect(tracker.state.value.active, isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Start Ride'), findsOneWidget);
    expect(
      tester.getCenter(globalControl).dx,
      tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
    );
  });

  testWidgets('keyboard does not lift the bottom bar or the Start button', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigation(
          pages: const [
            Text('Home page'),
            Text('History page'),
            Text('Service page'),
            _ProfilePage(),
          ],
          rideActive: false,
          onRide: () {},
        ),
      ),
    );
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    final buttonBefore = tester.getCenter(find.byTooltip('Start Ride'));
    final tabBefore = tester.getCenter(find.text('Riwayat'));

    // Keyboard setinggi 600px logis muncul di bawah layar.
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    await tester.pumpAndSettle();

    expect(tester.getCenter(find.byTooltip('Start Ride')), buttonBefore);
    expect(tester.getCenter(find.text('Riwayat')), tabBefore);
  });

  testWidgets('Home statistics card opens Statistics and keeps ride action', (
    tester,
  ) async {
    final repository = _FakeRepository(rejectRideList: true);
    final tracker = RideTracker(repository);
    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigation(
          pages: [
            HomeScreen(repository: repository, tracker: tracker),
            const Text('History page'),
            const Text('Service page'),
            const Text('Profile page'),
            StatisticsScreen(repository: repository),
          ],
          tracker: tracker,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Statistik perjalanan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byIcon(Icons.route_outlined), findsOneWidget);
    expect(find.byIcon(Icons.straighten_outlined), findsOneWidget);
    await tester.tap(
      find.ancestor(
        of: find.text('Statistik perjalanan').first,
        matching: find.byType(Card),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StatisticsScreen), findsOneWidget);
    expect(find.text('Jarak'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byTooltip('Start Ride'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byTooltip('Start Ride'), findsOneWidget);
  });

  testWidgets('Home shows the rider avatar template without a profile photo', (
    tester,
  ) async {
    final repository = _FakeRepository();
    final tracker = RideTracker(repository);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(repository: repository, tracker: tracker),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('home-profile-avatar-fallback')),
      findsOneWidget,
    );
    final avatar = tester.widget<Image>(find.byType(Image).first);
    expect((avatar.image as ResizeImage).width, 76);
    expect((avatar.image as ResizeImage).height, 76);
  });

  testWidgets('Home only shows the live map during an active ride', (
    tester,
  ) async {
    final repository = _FakeRepository();
    final tracker = RideTracker(
      repository,
      positionStream: const Stream.empty(),
      locationServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.always,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(repository: repository, tracker: tracker),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('home-live-ride-map')), findsNothing);

    await tracker.start();
    await tracker.onLocation(
      const GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 5),
    );
    await tracker.onLocation(
      const GeoPoint(latitude: -6.2, longitude: 106.8001, accuracyMeters: 5),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('home-live-ride-map')), findsOneWidget);
  });

  testWidgets('Home history card opens the upgraded History screen', (
    tester,
  ) async {
    final repository = _FakeRepository(
      rides: [
        Ride(
          startedAt: DateTime(2026, 9, 10, 9),
          endedAt: DateTime(2026, 9, 10, 10),
          distanceKm: 1,
        ),
      ],
    );
    final tracker = RideTracker(repository);
    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigation(
          pages: [
            HomeScreen(repository: repository, tracker: tracker),
            HistoryScreen(repository: repository),
            const Text('Service page'),
            const Text('Profile page'),
            const Text('Statistics page'),
          ],
          tracker: tracker,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.history).first);
    await tester.pumpAndSettle();

    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.byTooltip('Start Ride'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('1.0 km').last,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -220));
    await tester.pump();
    await tester.tap(find.textContaining('1.0 km').last);
    await tester.pumpAndSettle();
    expect(find.byType(RideDetailScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);
  });

  testWidgets('bottom-nav History opens the upgraded History screen', (
    tester,
  ) async {
    final repository = _FakeRepository();
    final tracker = RideTracker(repository);
    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigation(
          pages: [
            HomeScreen(repository: repository, tracker: tracker),
            HistoryScreen(repository: repository),
            const Text('Service page'),
            const Text('Profile page'),
            const Text('Statistics page'),
          ],
          tracker: tracker,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Riwayat'));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.byTooltip('Start Ride'), findsOneWidget);
  });

  testWidgets('the Profile fields stay above the keyboard', (tester) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigation(
          pages: [
            ProfileScreen(
              repository: repository,
              themeMode: ThemeMode.system,
              language: 'id',
              onThemeChanged: (_) {},
              onLanguageChanged: (_) {},
            ),
          ],
          rideActive: false,
          onRide: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    const keyboard = 300.0;
    tester.view.viewInsets = FakeViewPadding(
      bottom: keyboard * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();

    // Scaffold halaman di dalam MainNavigation harus tetap menyusut sendiri,
    // supaya kolom yang sedang diisi tidak tertutup keyboard. Kalau inset-nya
    // ikut hilang, daftar ini akan tetap setinggi layar penuh.
    final list = tester.getRect(find.byType(ListView).first);
    expect(
      list.bottom,
      lessThanOrEqualTo(
        tester.view.physicalSize.height / tester.view.devicePixelRatio -
            keyboard,
      ),
    );
  });
}
