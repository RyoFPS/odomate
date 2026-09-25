import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/i18n/app_localizations.dart';
import 'package:odomate/src/widgets/ride_map.dart';

Widget _testApp(Widget child) => MaterialApp(
  locale: const Locale('id'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

class _FailingTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      const AssetImage('missing-map-tile.png');
}

void main() {
  testWidgets('shows unavailable UI for a route with no points', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const RideMap(points: [], followCurrentLocation: false, height: 260),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('ride-map-empty')), findsOneWidget);
  });

  testWidgets('builds start, end, and route layers for saved points', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        RideMap(
          points: [
            GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 5),
            GeoPoint(latitude: -6.201, longitude: 106.801, accuracyMeters: 5),
          ],
          followCurrentLocation: false,
          height: 260,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('ride-map')), findsOneWidget);
    expect(find.byKey(const ValueKey('ride-map-start')), findsOneWidget);
    expect(find.byKey(const ValueKey('ride-map-end')), findsOneWidget);
    expect(find.byKey(const ValueKey('ride-map-fit-route')), findsOneWidget);
    expect(find.byKey(const ValueKey('ride-map-recenter')), findsNothing);
  });

  testWidgets('shows a recenter control while following an active ride', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const RideMap(
          points: [
            GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 5),
          ],
          followCurrentLocation: true,
          height: 260,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('ride-map-recenter')), findsOneWidget);
  });

  testWidgets('shows weak GPS status on the live map', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const RideMap(
          points: [
            GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 25),
          ],
          followCurrentLocation: true,
          height: 260,
          gpsAccuracyMeters: 25,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('ride-map-gps-status')), findsOneWidget);
    expect(find.text('Sinyal GPS lemah'), findsOneWidget);
  });

  testWidgets('shows an offline status after a map tile fails to load', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        RideMap(
          points: [
            GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 5),
          ],
          followCurrentLocation: false,
          height: 260,
          tileProvider: _FailingTileProvider(),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('ride-map-offline')), findsOneWidget);
    expect(find.byKey(const ValueKey('ride-map-retry')), findsOneWidget);
  });
}
