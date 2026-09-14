import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/app.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/i18n/app_localizations.dart';
import 'package:odomate/src/screens/history_screen.dart';
import 'package:odomate/src/screens/notifications_screen.dart';
import 'package:odomate/src/screens/profile_screen.dart';
import 'package:odomate/src/screens/ride_detail_screen.dart';
import 'package:odomate/src/screens/service_editor_screen.dart';
import 'package:odomate/src/screens/services_screen.dart';
import 'package:odomate/src/screens/settings_screen.dart';
import 'package:odomate/src/screens/statistics_screen.dart';

/// Jarak tombol back ke judul header, disamakan di seluruh app.
///
/// Halaman **Setting** yang jadi referensinya: di sana jaraknya 16px, dan angka
/// itu bukan ditulis di layarnya melainkan muncul dari `appBarTheme` —
/// `leadingWidth: 56` + `titleSpacing: 0`, dengan ikon back 24 di tengah slot
/// sehingga tepi kanannya di x=40 sementara judul mulai di x=56.
///
/// Test ini karena itu **mengukur** jaraknya, bukan menyalin angkanya: referensi
/// diambil dari Setting yang benar-benar dirender, lalu kelima layar berback
/// lainnya dibandingkan ke situ. Kalau suatu saat jarak di Setting berubah, test
/// ini menuntut layar lain ikut berubah — bukan diam-diam lolos.
class _FakeRepository extends OdomateRepository {
  @override
  Future<Vehicle?> loadVehicle() async =>
      const Vehicle(name: 'Honda Vario 160', odometerKm: 24582);

  @override
  Future<Ride?> loadActiveRide() async => null;

  @override
  Future<List<Ride>> listRides() async => const [];

  @override
  Future<List<ServiceItem>> listServices() async => const [];

  @override
  Future<List<ServiceLog>> listServiceLogs() async => const [];
}

const _service = ServiceItem(
  id: 1,
  name: 'Ganti Oli Mesin',
  intervalKm: 2000,
  lastServicedOdometerKm: 22500,
);

/// Layar dibuka dengan tema app yang asli, bukan tema bawaan `MaterialApp`.
///
/// Tanpa `odomateTheme` test ini hanya akan mengukur `AppBarTheme` bawaan
/// Material (judul 32px dari ikon) — angkanya terlihat "salah", tapi yang salah
/// bukan app-nya, melainkan tema yang dipakai test.
Widget _app(GlobalKey<NavigatorState> navigatorKey) => MaterialApp(
  navigatorKey: navigatorKey,
  theme: odomateTheme(Brightness.light),
  locale: const Locale('id'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: const Scaffold(),
);

/// Layar berback di-push, bukan dipasang sebagai `home`.
///
/// Tombol back bawaan `AppBar` hanya muncul kalau rutenya memang bisa di-pop
/// (`Navigator.canPop`). Dipasang sebagai `home`, layar-layar ini tidak punya
/// tombol back sama sekali dan yang terukur di AppBar malah ikon aksi.
Future<void> _push(WidgetTester tester, Widget screen) async {
  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(_app(navigatorKey));
  // Delegasi lokalisasi dimuat asinkron, jadi frame pertama belum punya
  // Navigator sama sekali — `currentState` masih null sampai frame berikutnya.
  await tester.pumpAndSettle();
  navigatorKey.currentState!.push(MaterialPageRoute(builder: (_) => screen));
  await tester.pumpAndSettle();
}

/// Untuk header tab, yang memang bukan rute yang bisa di-pop.
Future<void> _home(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: odomateTheme(Brightness.light),
      locale: const Locale('id'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}

/// Widget pertama yang cocok di dalam `AppBar`.
///
/// `leading` selalu lebih dulu daripada `title` dan `actions` di pohon toolbar,
/// jadi `.first` adalah tombol back untuk ikon, dan baris pertama judul untuk
/// teks. Dicari lewat tipe — bukan lewat teks tombol — supaya pengukurannya
/// tidak bergantung pada bahasa yang sedang dipakai.
Finder _firstInAppBar(Type type) =>
    find.descendant(of: find.byType(AppBar), matching: find.byType(type)).first;

/// Jarak tepi kanan ikon back ke tepi kiri judul.
double _backTitleGap(WidgetTester tester) =>
    tester.getTopLeft(_firstInAppBar(Text)).dx -
    tester.getRect(_firstInAppBar(Icon)).right;

/// Jarak tepi kiri judul dari tepi kiri layar, untuk AppBar tanpa leading.
double _titleInset(WidgetTester tester) =>
    tester.getTopLeft(_firstInAppBar(Text)).dx;

void main() {
  /// Referensi: jarak di halaman Setting.
  const reference = 16.0;

  testWidgets('halaman Setting jadi referensi: 16px', (tester) async {
    await _push(
      tester,
      SettingsScreen(
        themeMode: ThemeMode.light,
        language: 'id',
        onThemeChanged: (_) {},
        onLanguageChanged: (_) {},
      ),
    );

    // Angka referensinya sendiri ikut dijaga: kalau halaman Setting bergeser,
    // test ini yang memberi tahu lebih dulu, bukan layar-layar lain.
    expect(_backTitleGap(tester), closeTo(reference, 0.5));
  });

  testWidgets('setiap layar berback memakai jarak yang sama', (tester) async {
    final screens = <String, Widget>{
      'ride detail': RideDetailScreen(
        ride: Ride(
          startedAt: DateTime(2026, 9, 14, 7),
          endedAt: DateTime(2026, 9, 14, 7, 30),
          distanceKm: 15,
        ),
      ),
      'notifikasi': NotificationsScreen(repository: _FakeRepository()),
      'detail servis': ServiceDetailScreen(
        repository: _FakeRepository(),
        service: _service,
      ),
      'tambah servis': ServiceEditorScreen(
        repository: _FakeRepository(),
        odometerKm: 24582,
      ),
      'statistik': StatisticsScreen(repository: _FakeRepository()),
    };

    for (final entry in screens.entries) {
      await _push(tester, entry.value);
      expect(
        _backTitleGap(tester),
        closeTo(reference, 0.5),
        reason: 'jarak tombol back ke judul di layar ${entry.key}',
      );
    }
  });

  testWidgets('header tab tanpa tombol back tidak ikut menempel ke tepi', (
    tester,
  ) async {
    // `titleSpacing: 0` di appBarTheme berlaku juga untuk AppBar tanpa leading;
    // di situ judulnya akan menempel ke tepi kalau layarnya tidak menulis
    // `titleSpacing` sendiri.
    final tabs = <String, Widget>{
      'riwayat': HistoryScreen(repository: _FakeRepository()),
      'profil': ProfileScreen(
        repository: _FakeRepository(),
        themeMode: ThemeMode.light,
        language: 'id',
        onThemeChanged: (_) {},
        onLanguageChanged: (_) {},
      ),
    };

    for (final entry in tabs.entries) {
      await _home(tester, entry.value);
      expect(
        _titleInset(tester),
        closeTo(reference, 0.5),
        reason: 'jarak judul dari tepi kiri di header tab ${entry.key}',
      );
    }
  });
}
