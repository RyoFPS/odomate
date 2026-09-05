import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/app.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/screens/home_screen.dart';
import 'package:odomate/src/screens/statistics_screen.dart';
import 'package:odomate/src/tracking/ride_tracker.dart';

class _FakeRepository extends OdomateRepository {
  @override
  Future<Vehicle?> loadVehicle() async =>
      const Vehicle(name: 'Test', odometerKm: 0);

  @override
  Future<List<Ride>> listRides() async => const [];

  @override
  Future<List<ServiceItem>> listServices() async => const [];
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
}
