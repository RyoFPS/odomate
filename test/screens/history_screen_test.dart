import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/i18n/app_localizations.dart';
import 'package:odomate/src/screens/history_screen.dart';
import 'package:odomate/src/widgets/skeleton_loader.dart';

class _FakeRepository extends OdomateRepository {
  final List<Ride> rides;
  final Object? error;
  final Duration delay;
  final Vehicle? vehicle;

  _FakeRepository({
    this.rides = const [],
    this.error,
    this.delay = Duration.zero,
    this.vehicle,
  });

  @override
  Future<List<Ride>> listRides() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (error != null) throw error!;
    return rides;
  }

  @override
  Future<List<Ride>> listRidesPage({
    required int limit,
    required int offset,
  }) async {
    final all = await listRides();
    return all.skip(offset).take(limit).toList();
  }

  @override
  Future<List<ServiceLog>> listServiceLogs() async => const [];

  @override
  Future<List<ServiceLog>> listServiceLogsPage({
    required int limit,
    required int offset,
  }) async {
    final all = await listServiceLogs();
    return all.skip(offset).take(limit).toList();
  }

  @override
  Future<Vehicle?> loadVehicle() async => vehicle;
}

Widget _app(OdomateRepository repository, {String language = 'id'}) =>
    MaterialApp(
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HistoryScreen(
        key: UniqueKey(),
        repository: repository,
        now: () => DateTime(2026, 9, 10, 12),
      ),
    );

void main() {
  testWidgets('renders all rides with localized labels by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _FakeRepository(
          rides: [
            Ride(
              startedAt: DateTime(2026, 9, 10, 10),
              endedAt: DateTime(2026, 9, 10, 11, 5),
              distanceKm: 12.5,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.textContaining('12.5 km'), findsWidgets);
    expect(find.textContaining('1jam 05mnt'), findsOneWidget);
  });

  testWidgets('renders a period summary with active filter metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _FakeRepository(
          vehicle: const Vehicle(name: 'Honda Vario 160', odometerKm: 2500),
          rides: [
            Ride(
              startedAt: DateTime(2026, 9, 10, 10),
              endedAt: DateTime(2026, 9, 10, 11),
              distanceKm: 12,
            ),
            Ride(
              startedAt: DateTime(2026, 9, 9, 10),
              endedAt: DateTime(2026, 9, 9, 11),
              distanceKm: 8,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Semua'), findsOneWidget);
    expect(find.text('Honda Vario 160'), findsOneWidget);
    expect(find.text('Total Jarak'), findsOneWidget);
    expect(find.text('Frekuensi'), findsOneWidget);
    expect(find.text('Rata-rata harian'), findsOneWidget);
    expect(find.textContaining('Efisiensi BBM rata-rata'), findsOneWidget);
    expect(find.textContaining('20.0'), findsWidgets);
    expect(find.textContaining('2'), findsWidgets);

    await tester.tap(find.text('Hari ini'));
    await tester.pump();

    expect(find.text('Ringkasan Hari ini'), findsOneWidget);
    expect(find.textContaining('12.0'), findsWidgets);
    expect(find.text('8.0'), findsNothing);
  });

  testWidgets('switches to today and filters out older rides', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeRepository(
          rides: [
            Ride(startedAt: DateTime(2026, 9, 10, 9), distanceKm: 3),
            Ride(startedAt: DateTime(2026, 9, 9, 9), distanceKm: 9),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hari ini'));
    await tester.pump();

    expect(find.textContaining('3.0 km'), findsWidgets);
    expect(find.textContaining('9.0 km'), findsNothing);
  });

  testWidgets('renders active ride status and opens its detail screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _FakeRepository(
          rides: [Ride(startedAt: DateTime(2026, 9, 10, 9), distanceKm: 0)],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Sedang berlangsung'), findsOneWidget);
    await tester.tap(find.textContaining('0.0 km').last);
    await tester.pumpAndSettle();

    expect(find.text('Detail perjalanan'), findsOneWidget);
    expect(find.text('Jarak'), findsOneWidget);
    expect(find.textContaining('0.0 km'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('renders loading, empty, and error states', (tester) async {
    await tester.pumpWidget(
      _app(_FakeRepository(delay: const Duration(milliseconds: 100))),
    );
    await tester.pump();
    expect(find.byType(SkeletonLoader), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada perjalanan.'), findsOneWidget);

    await tester.pumpWidget(_app(_FakeRepository(error: Exception('nope'))));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Gagal memuat riwayat.'), findsOneWidget);
  });

  testWidgets('renders English labels', (tester) async {
    await tester.pumpWidget(_app(_FakeRepository(), language: 'en'));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('No rides yet.'), findsOneWidget);
  });

  testWidgets('localizes completed duration units in Japanese', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeRepository(
          rides: [
            Ride(
              startedAt: DateTime(2026, 9, 10, 10),
              endedAt: DateTime(2026, 9, 10, 11, 5),
              distanceKm: 1,
            ),
          ],
        ),
        language: 'ja',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1時間 05分'), findsOneWidget);
  });
}
