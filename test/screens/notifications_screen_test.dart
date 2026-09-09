import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/i18n/app_localizations.dart';
import 'package:odomate/src/screens/notifications_screen.dart';

class _FakeRepository extends OdomateRepository {
  @override
  Future<List<Ride>> listRides() async => [
    Ride(
      startedAt: DateTime(2026, 9, 10, 7),
      endedAt: DateTime(2026, 9, 10, 7, 30),
      distanceKm: 6.2,
    ),
  ];

  @override
  Future<List<ServiceItem>> listServices() async => [
    ServiceItem(
      id: 1,
      name: 'Oli mesin',
      intervalKm: 2000,
      lastServicedOdometerKm: 700,
    ),
  ];

  @override
  Future<Vehicle?> loadVehicle() async =>
      const Vehicle(name: 'Honda Beat', odometerKm: 2500);
}

Widget _app() => MaterialApp(
  locale: const Locale('id'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: NotificationsScreen(repository: _FakeRepository()),
);

void main() {
  testWidgets('renders notification filters and local ride/service alerts', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Perjalanan'), findsOneWidget);
    expect(find.text('Servis'), findsOneWidget);
    expect(find.text('Perjalanan selesai'), findsOneWidget);
    expect(find.text('Servis mendekat'), findsOneWidget);
  });
}
