import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/i18n/app_localizations.dart';
import 'package:odomate/src/screens/history_screen.dart';

/// Baris pembanding di bawah angka Total Jarak pada kartu ringkasan.
///
/// Desain (`stitch_odomate_modern_ui/odomate_history_2/code.html:174-177`) menaruh
/// `trending_up` + "+18% vs minggu lalu" 10px `#15803D` tepat di bawah angkanya.
/// Sebelum ini app tidak punya baris itu sama sekali.
class _FakeRepository extends OdomateRepository {
  _FakeRepository(this.rides);

  final List<Ride> rides;

  @override
  Future<List<Ride>> listRides() async => rides;

  @override
  Future<List<ServiceLog>> listServiceLogs() async => const [];

  @override
  Future<Vehicle?> loadVehicle() async => null;
}

/// Dipakai semua test: 10 September 2026 pukul 12.00.
///
/// Jamnya sengaja tidak tengah malam — justru di situ pemotongan rentang
/// pembanding terlihat, karena "hari ini" pukul 12.00 hanya sebanding dengan
/// setengah hari kemarin.
final _now = DateTime(2026, 9, 10, 12);

Widget _app(List<Ride> rides) => MaterialApp(
  locale: const Locale('id'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: HistoryScreen(repository: _FakeRepository(rides), now: () => _now),
);

/// Membuka layar, lalu memilih periode lewat chip di atas kartu ringkasan.
/// [period] null berarti dibiarkan di bawaan layar, yaitu "Semua".
Future<void> _open(
  WidgetTester tester,
  List<Ride> rides, {
  String? period,
}) async {
  await tester.pumpWidget(_app(rides));
  await tester.pumpAndSettle();
  if (period != null) {
    await tester.tap(find.text(period));
    await tester.pumpAndSettle();
  }
}

/// Token warna tema yang berlaku di layar.
///
/// Layar ini tidak menetapkan hex sendiri, jadi yang dijaga di sini adalah
/// "memakai token yang mana" — nilai `#15803D`-nya dijaga `_theme()` di
/// `lib/src/app.dart`. Membandingkan ke hex langsung hanya akan menguji tema
/// bawaan `MaterialApp`, bukan tema app ini.
ColorScheme _colors(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(HistoryScreen))).colorScheme;

/// Warna teks baris pembanding, atau null kalau barisnya tidak dirender.
Color? _comparisonColor(WidgetTester tester, String text) {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) return null;
  return tester.widget<Text>(finder).style?.color;
}

/// Jarak naik 118 berbanding 100 km.
final _rising = [
  Ride(startedAt: DateTime(2026, 9, 5), distanceKm: 118),
  // Pembanding sepekan sebelumnya, yang berhenti 3 September pukul 12.00.
  Ride(startedAt: DateTime(2026, 8, 30), distanceKm: 100),
];

void main() {
  testWidgets('shows the change against the previous week', (tester) async {
    await _open(tester, _rising, period: '7 hari terakhir');

    expect(find.text('+18% vs minggu lalu'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
    expect(
      _comparisonColor(tester, '+18% vs minggu lalu'),
      _colors(tester).tertiary,
    );
  });

  testWidgets('marks a decline instead of calling it a rise', (tester) async {
    await _open(tester, [
      Ride(startedAt: DateTime(2026, 9, 5), distanceKm: 50),
      Ride(startedAt: DateTime(2026, 8, 30), distanceKm: 100),
    ], period: '7 hari terakhir');

    expect(find.text('-50% vs minggu lalu'), findsOneWidget);
    expect(find.byIcon(Icons.trending_down), findsOneWidget);
    expect(
      _comparisonColor(tester, '-50% vs minggu lalu'),
      _colors(tester).error,
    );
  });

  testWidgets('stays hidden when the previous period was empty', (
    tester,
  ) async {
    // Nol km sebelumnya berarti perubahan tak hingga — lebih berguna tidak
    // menampilkan apa pun daripada menampilkan "∞%".
    await _open(tester, [
      Ride(startedAt: DateTime(2026, 9, 5), distanceKm: 50),
    ], period: '7 hari terakhir');

    expect(find.byIcon(Icons.trending_up), findsNothing);
    expect(find.byIcon(Icons.trending_down), findsNothing);
    expect(find.byIcon(Icons.trending_flat), findsNothing);
  });

  testWidgets('has nothing to compare the unbounded period against', (
    tester,
  ) async {
    // Bawaan layar adalah "Semua", yang memang tidak punya periode sebelumnya.
    await _open(tester, _rising);

    expect(find.byIcon(Icons.trending_up), findsNothing);
    expect(find.byIcon(Icons.trending_down), findsNothing);
  });

  testWidgets('compares today against yesterday', (tester) async {
    await _open(tester, [
      Ride(startedAt: DateTime(2026, 9, 10, 9), distanceKm: 12),
      // Kemarin pagi, jadi masih masuk pembanding yang berhenti pukul 12.00.
      Ride(startedAt: DateTime(2026, 9, 9, 6), distanceKm: 10),
    ], period: 'Hari ini');

    expect(find.text('+20% vs kemarin'), findsOneWidget);
  });

  testWidgets('compares this month against the same stretch of last month', (
    tester,
  ) async {
    await _open(tester, [
      Ride(startedAt: DateTime(2026, 9, 2), distanceKm: 60),
      // Bulan lalu, tapi masih di dalam rentang sebanding 1-10 Agustus.
      Ride(startedAt: DateTime(2026, 8, 5), distanceKm: 50),
    ], period: 'Bulan ini');

    expect(find.text('+20% vs bulan lalu'), findsOneWidget);
  });
}
