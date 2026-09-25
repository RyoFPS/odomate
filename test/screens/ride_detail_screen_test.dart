import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/screens/ride_detail_screen.dart';

class _RouteRepository extends OdomateRepository {
  final List<GeoPoint> points;

  _RouteRepository(this.points);

  @override
  Future<List<GeoPoint>> listRidePoints(int rideId) async => points;
}

void main() {
  testWidgets(
    'ride detail surfaces an average speed metric from saved ride data',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RideDetailScreen(
            ride: Ride(
              startedAt: DateTime(2026, 9, 14, 7),
              endedAt: DateTime(2026, 9, 14, 7, 30),
              distanceKm: 15,
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('ride-average-speed')), findsOneWidget);
      expect(find.byKey(const ValueKey('ride-estimate')), findsOneWidget);
      expect(find.byKey(const ValueKey('ride-final-odometer')), findsOneWidget);
      expect(find.byKey(const ValueKey('ride-map-empty')), findsOneWidget);
      expect(find.byTooltip('Bagikan'), findsOneWidget);
      expect(find.byTooltip('Opsi lainnya'), findsOneWidget);

      final averageSpeedHeight = tester
          .getSize(find.byKey(const ValueKey('ride-average-speed')))
          .height;
      final estimateHeight = tester
          .getSize(find.byKey(const ValueKey('ride-estimate')))
          .height;
      final finalOdometerHeight = tester
          .getSize(find.byKey(const ValueKey('ride-final-odometer')))
          .height;

      expect(averageSpeedHeight, estimateHeight);
      expect(estimateHeight, finalOdometerHeight);
    },
  );

  testWidgets('more actions open ride detail sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RideDetailScreen(ride: Ride(startedAt: DateTime(2026, 9, 14))),
      ),
    );
    await tester.tap(find.byTooltip('Opsi lainnya'));
    await tester.pumpAndSettle();
    expect(find.text('Detail perjalanan'), findsWidgets);
    expect(find.text('Edit Catatan & Cuaca'), findsOneWidget);
    expect(find.text('Duplikasi Log Perjalanan'), findsOneWidget);
    expect(find.text('Koreksi Jarak Manual'), findsOneWidget);
    expect(find.text('Ekspor GPX'), findsOneWidget);
    expect(find.text('Hapus Log Perjalanan Ini'), findsOneWidget);
  });

  testWidgets('GPX export explains when a ride has no saved route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RideDetailScreen(ride: Ride(startedAt: DateTime(2026, 9, 14))),
      ),
    );

    await tester.tap(find.byTooltip('Opsi lainnya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ekspor GPX'));
    await tester.pumpAndSettle();

    expect(
      find.text('Rute GPS belum tersedia untuk diekspor sebagai GPX.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('ride detail renders saved route start and end markers', (
    tester,
  ) async {
    final repository = _RouteRepository([
      const GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 5),
      const GeoPoint(latitude: -6.201, longitude: 106.801, accuracyMeters: 5),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: RideDetailScreen(
          ride: Ride(id: 1, startedAt: DateTime(2026, 9, 14)),
          repository: repository,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('ride-map')), findsOneWidget);
    expect(find.byKey(const ValueKey('ride-map-start')), findsOneWidget);
    expect(find.byKey(const ValueKey('ride-map-end')), findsOneWidget);
  });
}
