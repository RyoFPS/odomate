import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/i18n/app_localizations.dart';
import 'package:odomate/src/screens/history_screen.dart';

/// Perilaku tombol di bottom sheet "Filter Riwayat Perjalanan".
///
/// Yang dijaga di sini adalah hal-hal yang sebelumnya melenceng dari
/// `stitch_odomate_modern_ui/odomate_history_2/code.html`: centang di chip
/// terpilih, grup urutan yang tidak membagi rata, dan label kaki sheet.
class _FakeRepository extends OdomateRepository {
  _FakeRepository({this.rides = const [], this.logs = const []});

  final List<Ride> rides;
  final List<ServiceLog> logs;

  @override
  Future<List<Ride>> listRides() async => rides;

  @override
  Future<List<Ride>> listRidesPage({
    required int limit,
    required int offset,
  }) async => rides.skip(offset).take(limit).toList();

  @override
  Future<List<ServiceLog>> listServiceLogs() async => logs;

  @override
  Future<List<ServiceLog>> listServiceLogsPage({
    required int limit,
    required int offset,
  }) async => logs.skip(offset).take(limit).toList();

  @override
  Future<Vehicle?> loadVehicle() async => null;
}

Widget _app({List<Ride> rides = const [], List<ServiceLog> logs = const []}) =>
    MaterialApp(
      locale: const Locale('id'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HistoryScreen(
        repository: _FakeRepository(rides: rides, logs: logs),
        now: () => DateTime(2026, 9, 10, 12),
      ),
    );

Finder get _sheet => find.byType(BottomSheet);

Finder _inSheet(Finder finder) => find.descendant(of: _sheet, matching: finder);

Future<void> _openSheet(WidgetTester tester) async {
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.tune));
  await tester.pumpAndSettle();
}

/// Kotak chip untuk sebuah label — `Material` terdekat di atas teksnya, yang
/// memang yang dilukis `_filterChip`. Di dalam grup urutan kotak ini direntangkan
/// `Expanded`, jadi lebarnya sama dengan lebar sel grid-nya.
Finder _chip(Finder label) =>
    find.ancestor(of: label, matching: find.byType(Material)).first;

Color _chipColor(WidgetTester tester, Finder label) =>
    tester.widget<Material>(_chip(label)).color!;

double _chipWidth(WidgetTester tester, String label) =>
    tester.getSize(_chip(_inSheet(find.text(label)))).width;

void main() {
  testWidgets('no chip in the sheet draws a checkmark', (tester) async {
    await _openSheet(tester);

    // `ChoiceChip` bawaan menyisipkan centang di keadaan terpilih; desain
    // menandai pilihan dengan warna saja. Grup periode memakai `DateRangeChips`
    // bersama dan grup urutan memakai chip sendiri, jadi yang dijaga di sini
    // adalah sifatnya — bukan widget mana yang dipakai.
    final chips = _inSheet(find.byType(ChoiceChip));
    expect(chips, findsWidgets);
    for (final chip in tester.widgetList<ChoiceChip>(chips)) {
      expect(chip.showCheckmark, isFalse);
    }
  });

  testWidgets('labels read the way the design writes them', (tester) async {
    await _openSheet(tester);

    expect(find.text('Rentang Waktu'), findsOneWidget);
    expect(find.text('Urutan Log'), findsOneWidget);
    expect(find.text('Reset Filter'), findsOneWidget);
    expect(find.text('Terapkan Filter'), findsOneWidget);

    expect(find.text('Rentang waktu'), findsNothing);
    expect(find.text('Urutan perjalanan'), findsNothing);
    expect(find.text('Reset'), findsNothing);
    expect(find.text('Terapkan'), findsNothing);
  });

  testWidgets('labels the sheet as history filter and offers history types', (
    tester,
  ) async {
    await _openSheet(tester);

    expect(find.text('Filter Riwayat'), findsOneWidget);
    expect(find.text('Jenis Riwayat'), findsOneWidget);
    expect(find.text('Tampilkan semua'), findsOneWidget);
    expect(find.text('Tampilkan perjalanan'), findsOneWidget);
    expect(find.text('Tampilkan service'), findsOneWidget);
  });

  testWidgets('service-only filter hides rides and keeps service history', (
    tester,
  ) async {
    final ride = Ride(startedAt: DateTime(2026, 9, 9), distanceKm: 12);
    final log = ServiceLog(
      serviceItemId: 1,
      servicedAt: DateTime(2026, 9, 8),
      odometerKm: 24582,
    );
    await tester.pumpWidget(_app(rides: [ride], logs: [log]));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tampilkan service'));
    await tester.tap(find.text('Terapkan Filter'));
    await tester.pumpAndSettle();

    expect(find.text('Perjalanan Terbaru'), findsNothing);
    expect(find.text('Servis'), findsOneWidget);
  });

  testWidgets('service-only empty state names service history', (tester) async {
    await _openSheet(tester);
    await tester.tap(find.text('Tampilkan service'));
    await tester.tap(find.text('Terapkan Filter'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada riwayat service.'), findsOneWidget);
    expect(find.text('Belum ada perjalanan.'), findsNothing);
  });

  testWidgets('reset history type returns to all history', (tester) async {
    final ride = Ride(startedAt: DateTime(2026, 9, 9), distanceKm: 12);
    final log = ServiceLog(
      serviceItemId: 1,
      servicedAt: DateTime(2026, 9, 8),
      odometerKm: 24582,
    );
    await tester.pumpWidget(_app(rides: [ride], logs: [log]));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tampilkan service'));
    await tester.tap(find.text('Reset Filter'));
    await tester.tap(find.text('Terapkan Filter'));
    await tester.pumpAndSettle();

    expect(find.text('Perjalanan Terbaru'), findsOneWidget);
    expect(find.text('Servis'), findsOneWidget);
  });

  testWidgets('the order chips split the row into equal thirds', (
    tester,
  ) async {
    await _openSheet(tester);

    // Desain memakai `grid grid-cols-3`. Kalau grup ini kembali jadi `Wrap`,
    // lebar ketiganya akan mengikuti panjang label dan tidak lagi sama.
    final newest = _chipWidth(tester, 'Terbaru');
    expect(newest, greaterThan(0));
    expect(
      _chipWidth(tester, 'Terlama'),
      moreOrLessEquals(newest, epsilon: .5),
    );
    expect(
      _chipWidth(tester, 'Jarak Terjauh'),
      moreOrLessEquals(newest, epsilon: .5),
    );
  });

  testWidgets('selection is carried by colour, and tapping moves it', (
    tester,
  ) async {
    await _openSheet(tester);

    final newest = _inSheet(find.text('Terbaru'));
    final oldest = _inSheet(find.text('Terlama'));
    final selected = _chipColor(tester, newest);
    final unselected = _chipColor(tester, oldest);
    expect(selected, isNot(unselected));

    await tester.tap(oldest);
    await tester.pumpAndSettle();

    expect(_chipColor(tester, newest), unselected);
    expect(_chipColor(tester, oldest), selected);
  });

  testWidgets('Reset Filter puts the order back to newest', (tester) async {
    await _openSheet(tester);

    final newest = _inSheet(find.text('Terbaru'));
    final selected = _chipColor(tester, newest);

    await tester.tap(_inSheet(find.text('Terlama')));
    await tester.pumpAndSettle();
    expect(_chipColor(tester, newest), isNot(selected));

    await tester.tap(find.text('Reset Filter'));
    await tester.pumpAndSettle();
    expect(_chipColor(tester, newest), selected);
  });
}
