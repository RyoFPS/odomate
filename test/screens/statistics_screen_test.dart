import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/i18n/app_localizations.dart';
import 'package:odomate/src/screens/statistics_screen.dart';

class _FakeRepository extends OdomateRepository {
  final Vehicle? vehicle;
  final List<Ride> rides;
  final List<ServiceItem> services;
  final Object? error;

  _FakeRepository({
    this.vehicle,
    this.rides = const [],
    this.services = const [],
    this.error,
  });

  @override
  Future<Vehicle?> loadVehicle() async {
    if (error != null) throw error!;
    return vehicle;
  }

  @override
  Future<List<Ride>> listRides() async => rides;

  @override
  Future<List<ServiceItem>> listServices() async => services;
}

Widget _app(OdomateRepository repository) => MaterialApp(
  locale: const Locale('id'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: StatisticsScreen(repository: repository),
);

void main() {
  testWidgets('defaults to the seven-day period and renders ride metrics', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      _app(
        _FakeRepository(
          vehicle: const Vehicle(name: 'Scoopy', odometerKm: 1200),
          rides: [
            Ride(
              startedAt: now.subtract(const Duration(days: 1)),
              distanceKm: 12.5,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('7 hari terakhir'), findsOneWidget);
    expect(find.text('12.5 km'), findsAtLeastNWidgets(1));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Rata-rata'), findsOneWidget);
  });

  testWidgets('switching to today updates the selected period metrics', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      _app(
        _FakeRepository(
          rides: [
            Ride(
              startedAt: now.subtract(const Duration(days: 1)),
              distanceKm: 12,
            ),
            Ride(
              startedAt: now.subtract(const Duration(hours: 1)),
              distanceKm: 3,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('15.0 km'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Hari ini'));
    await tester.pumpAndSettle();

    expect(find.text('3.0 km'), findsAtLeastNWidgets(1));
  });

  testWidgets('shows a stable empty state and service summary', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeRepository(
          vehicle: const Vehicle(name: 'Scoopy', odometerKm: 1200),
          services: [
            const ServiceItem(
              name: 'Oli mesin',
              intervalKm: 1000,
              lastServicedOdometerKm: 0,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pump();

    expect(find.text('Belum ada perjalanan pada periode ini.'), findsOneWidget);
    expect(find.text('Ringkasan servis'), findsOneWidget);
    expect(find.textContaining('Oli mesin'), findsOneWidget);
    expect(find.textContaining('1 jatuh tempo'), findsOneWidget);
    expect(find.textContaining('1 item servis tersimpan'), findsOneWidget);
  });

  testWidgets('shows a localized error when loading statistics fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_FakeRepository(error: StateError('offline'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gagal memuat statistik.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('offline'), findsNothing);
  });

  testWidgets('current month excludes rides from the previous month', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 5, 12);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticsScreen(
          repository: _FakeRepository(
            rides: [
              Ride(startedAt: DateTime(2026, 8, 31), distanceKm: 99),
              Ride(startedAt: DateTime(2026, 9, 1), distanceKm: 12),
            ],
          ),
          now: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bulan ini'));
    await tester.pumpAndSettle();

    expect(find.text('12.0 km'), findsAtLeastNWidgets(1));
    expect(find.text('99.0 km'), findsNothing);
  });
}
