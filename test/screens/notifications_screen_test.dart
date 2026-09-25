import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/i18n/app_localizations.dart';
import 'package:odomate/src/screens/notifications_screen.dart';

/// Sisa 200 km → status `dueSoon`, jadi muncul sebagai "Servis mendekat".
const _oilSoon = ServiceItem(
  id: 1,
  name: 'Oli mesin',
  intervalKm: 2000,
  lastServicedOdometerKm: 700,
);

const _defaultVehicle = Vehicle(name: 'Honda Beat', odometerKm: 2500);

/// `DateTime` bukan konstruktor const, jadi daftar ini tidak bisa dipakai
/// sebagai nilai default parameter — makanya di-`?? ` di initializer list.
final _defaultRides = [
  Ride(
    startedAt: DateTime(2026, 9, 10, 7),
    endedAt: DateTime(2026, 9, 10, 7, 30),
    distanceKm: 6.2,
  ),
];

class _FakeRepository extends OdomateRepository {
  _FakeRepository({
    Vehicle? vehicle,
    List<ServiceItem>? services,
    List<Ride>? rides,
    this.active,
  }) : vehicle = vehicle ?? _defaultVehicle,
       services = services ?? const [_oilSoon],
       rides = rides ?? _defaultRides;

  final Vehicle? vehicle;
  final List<ServiceItem> services;
  final List<Ride> rides;
  final Ride? active;

  @override
  Future<Vehicle?> loadVehicle() async => vehicle;

  @override
  Future<Ride?> loadActiveRide() async => active;

  @override
  Future<List<Ride>> listRides() async => rides;

  @override
  Future<List<ServiceItem>> listServices() async => services;
}

Widget _app([OdomateRepository? repository]) => MaterialApp(
  locale: const Locale('id'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: NotificationsScreen(repository: repository ?? _FakeRepository()),
);

/// Fixture lengkap: keempat jenis kartu di desain, semuanya dari data nyata.
const _detailVehicle = Vehicle(
  name: 'Honda Vario 160',
  odometerKm: 24582,
  plateNumber: 'B 1234 XYZ',
  userName: 'Dimas Prasetyo',
);

const _soonService = ServiceItem(
  name: 'Oli mesin',
  intervalKm: 100,
  lastServicedOdometerKm: 24582,
);

final _finishedRide = Ride(
  id: 1,
  startedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
  endedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
  distanceKm: 12.4,
);

_FakeRepository _full() => _FakeRepository(
  vehicle: _detailVehicle,
  services: const [_soonService],
  rides: [_finishedRide],
  active: Ride(
    id: 2,
    startedAt: DateTime.now().subtract(const Duration(hours: 3)),
    distanceKm: 6.2,
  ),
);

Finder _chip(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first;

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

  testWidgets('renders every card kind from the design', (tester) async {
    await tester.pumpWidget(_app(_full()));
    await tester.pumpAndSettle();

    expect(find.text('Ride sedang merekam'), findsOneWidget);
    expect(find.text('Servis mendekat'), findsOneWidget);
    expect(find.text('Perjalanan selesai'), findsOneWidget);
    expect(find.text('Profil tersimpan'), findsOneWidget);

    // Dua bagian, plus penanda penyimpanan lokal.
    expect(find.text('HARI INI'), findsOneWidget);
    expect(find.text('SEBELUMNYA'), findsOneWidget);
    expect(find.text('Tersimpan lokal'), findsOneWidget);

    // Aksi dan penanda status di baris bawah kartu.
    expect(find.text('Lihat Live Ride'), findsOneWidget);
    expect(find.text('Jadwalkan Servis'), findsOneWidget);
    expect(find.text('Tersinkron'), findsOneWidget);
    expect(find.text('Database SQLite v2'), findsOneWidget);
  });

  testWidgets('the section label is gray, not the on-surface black', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_full()));
    await tester.pumpAndSettle();

    final scheme = Theme.of(tester.element(find.byType(NotificationsScreen)))
        .colorScheme;
    final label = tester.widget<Text>(find.text('HARI INI'));

    expect(label.style?.color, scheme.secondary);
    expect(label.style?.color, isNot(scheme.onSurface));
  });

  testWidgets('the filter chips size to their content instead of the row', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_full()));
    await tester.pumpAndSettle();

    final all = tester.getSize(_chip('Semua'));
    final rides = tester.getSize(_chip('Perjalanan'));
    final services = tester.getSize(_chip('Servis'));

    // `py-1.5` + `text-xs` di desain menghasilkan pill setinggi ~28px.
    expect(all.height, lessThanOrEqualTo(32));
    // Lebar intrinsik: tiap label punya lebar sendiri, dan ketiganya tidak
    // direntangkan sama rata memenuhi baris (itulah efek `Expanded` dulu).
    expect(all.width, isNot(rides.width));
    expect(rides.width, isNot(services.width));
    final used = all.width + rides.width + services.width + 2 * 8;
    expect(used, lessThan(tester.getSize(find.byType(ListView)).width - 32));
  });

  testWidgets('the chips filter the list down to one kind', (tester) async {
    await tester.pumpWidget(_app(_full()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Servis'));
    await tester.pumpAndSettle();

    expect(find.text('Servis mendekat'), findsOneWidget);
    expect(find.text('Ride sedang merekam'), findsNothing);
    expect(find.text('Perjalanan selesai'), findsNothing);
    expect(find.text('Profil tersimpan'), findsNothing);
  });

  testWidgets('a ride is only reported once it is finished', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeRepository(
          vehicle: _detailVehicle,
          rides: [Ride(id: 3, startedAt: DateTime.now(), distanceKm: 4)],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Perjalanan selesai'), findsNothing);
    expect(find.text('SEBELUMNYA'), findsOneWidget);
  });

  testWidgets('marking all as read clears the unread dots and badge', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_full()));
    await tester.pumpAndSettle();

    // Chip aktif membawa badge jumlah yang belum dibaca: satu ride aktif dan
    // satu peringatan servis.
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('Tandai semua dibaca'));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsNothing);
  });
}
