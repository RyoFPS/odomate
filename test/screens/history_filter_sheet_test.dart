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
  @override
  Future<List<Ride>> listRides() async => const [];

  @override
  Future<List<ServiceLog>> listServiceLogs() async => const [];

  @override
  Future<Vehicle?> loadVehicle() async => null;
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
  home: HistoryScreen(
    repository: _FakeRepository(),
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
  testWidgets('the sheet does not use Material chips', (tester) async {
    await _openSheet(tester);

    // `ChoiceChip` bawaan menyisipkan centang di keadaan terpilih; desain
    // menandai pilihan dengan warna saja.
    expect(_inSheet(find.byType(ChoiceChip)), findsNothing);

    // Selector periode di layar belakang memang masih memakai `ChoiceChip`,
    // jadi assertion di atas membuktikan sheet-nya — bukan seluruh layar.
    expect(find.byType(ChoiceChip), findsWidgets);
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
