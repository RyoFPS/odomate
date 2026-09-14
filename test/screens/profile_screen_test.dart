import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/app.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/i18n/app_localizations.dart';
import 'package:odomate/src/screens/profile_screen.dart';
import 'package:odomate/src/widgets/odometer_correction_sheet.dart';

class _ProfileRepository extends OdomateRepository {
  @override
  Future<Vehicle?> loadVehicle() async => const Vehicle(
    name: 'Honda Vario 160',
    odometerKm: 24582,
    plateNumber: 'F 2723 FJO',
  );
}

/// Kartu identitas kendaraan dirender dengan tema app.
///
/// Tinggi sel ditentukan tema app, jadi tanpa `odomateTheme` yang terukur adalah
/// bawaan Material — bukan yang dipakai app, dan selnya akan terlihat "salah
/// tinggi" padahal bukan.
Widget _app() => MaterialApp(
  theme: odomateTheme(Brightness.light),
  locale: const Locale('id'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: ProfileScreen(
    repository: _ProfileRepository(),
    themeMode: ThemeMode.light,
    language: 'id',
    onThemeChanged: (_) {},
    onLanguageChanged: (_) {},
  ),
);

/// Sel dicari lewat label di dalamnya, bukan lewat tipe widget: yang dijaga
/// adalah hubungan antara kedua kotak ini, jadi testnya tidak boleh ikut rapuh
/// kalau isi salah satunya berganti widget.
Finder _cellOf(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(Container)).first;

void main() {
  testWidgets('profile uses the Stitch rider avatar when no photo is saved', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          repository: _ProfileRepository(),
          themeMode: ThemeMode.light,
          language: 'id',
          onThemeChanged: (_) {},
          onLanguageChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profile-avatar-fallback')),
      findsOneWidget,
    );
  });

  testWidgets('sel plat dan sel odometer sama besar dan sebaris', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final plateCell = _cellOf('Plat nomor');
    final odoCell = _cellOf('Odometer saat ini');

    // Inilah keluhan asalnya: kotak odometer 9px lebih tinggi dari kotak plat.
    expect(
      tester.getSize(odoCell).height,
      tester.getSize(plateCell).height,
      reason: 'tinggi sel odometer vs sel plat',
    );
    expect(
      tester.getTopLeft(plateCell).dy,
      tester.getTopLeft(odoCell).dy,
      reason: 'kedua sel harus mulai di baris yang sama',
    );

    // Labelnya juga ikut sebaris — dulu yang kiri memakai label melayang milik
    // `TextField` sehingga duduk di tempat yang berbeda dari yang kanan.
    expect(
      tester.getTopLeft(find.text('Plat nomor')).dy,
      tester.getTopLeft(find.text('Odometer saat ini')).dy,
      reason: 'label kedua sel harus sebaris',
    );

    // Chip plat tidak menonjol keluar dari kotaknya.
    final chip = find
        .ancestor(of: find.text('F 2723 FJO'), matching: find.byType(Container))
        .first;
    expect(
      tester.getRect(chip).bottom,
      lessThanOrEqualTo(tester.getRect(plateCell).bottom),
    );
  });

  testWidgets('mengetuk sel plat membuka sheet nomor plat', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Lewat labelnya, bukan lewat chip-nya: chip cuma setinggi teksnya, dan
    // yang dijaga di sini adalah seluruh kotak tetap jadi sasaran ketuk.
    await tester.tap(find.text('Plat nomor'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      find.byType(OdometerCorrectionSheet),
      findsNothing,
      reason: 'yang terbuka harus sheet plat, bukan sheet odometer',
    );
  });

  testWidgets('mengetuk sel odometer membuka sheet koreksi odometer', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Odometer saat ini'));
    await tester.pumpAndSettle();

    expect(find.byType(OdometerCorrectionSheet), findsOneWidget);
  });
}
