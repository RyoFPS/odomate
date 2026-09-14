import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/app.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/screens/home_screen.dart';
import 'package:odomate/src/screens/history_screen.dart';
import 'package:odomate/src/screens/ride_detail_screen.dart';
import 'package:odomate/src/screens/statistics_screen.dart';
import 'package:odomate/src/tracking/ride_tracker.dart';

class _FakeRepository extends OdomateRepository {
  final List<Ride> rides;

  _FakeRepository({this.rides = const []});

  @override
  Future<Vehicle?> loadVehicle() async =>
      const Vehicle(name: 'Test', odometerKm: 0);

  @override
  Future<List<Ride>> listRides() async => rides;

  @override
  Future<List<ServiceItem>> listServices() async => const [];

  @override
  Future<List<ServiceLog>> listServiceLogs() async => const [];
}

/// Meniru halaman Profile: ada TextField yang memunculkan keyboard.
class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: TextField()));
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
    final repository = _FakeRepository();
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
    await tester.tap(
      find.ancestor(
        of: find.text('Statistik perjalanan').first,
        matching: find.byType(Card),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StatisticsScreen), findsOneWidget);
    expect(find.text('Jarak'), findsOneWidget);
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
      find.textContaining('1.0 km'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -220));
    await tester.pump();
    await tester.tap(find.textContaining('1.0 km'));
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
}
