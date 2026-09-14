import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/i18n/app_localizations.dart';
import 'package:odomate/src/screens/services_screen.dart';
import 'package:odomate/src/widgets/odometer_correction_sheet.dart';

class _FakeRepository extends OdomateRepository {
  _FakeRepository({
    this.vehicle,
    this.services = const [],
    this.logs = const [],
  });

  final Vehicle? vehicle;
  final List<ServiceItem> services;
  final List<ServiceLog> logs;
  final List<double> savedOdometers = [];

  @override
  Future<Vehicle?> loadVehicle() async => vehicle;

  @override
  Future<List<ServiceItem>> listServices() async => services;

  @override
  Future<List<ServiceLog>> listServiceLogs() async => logs;

  @override
  Future<int> saveService(ServiceItem item) async => item.id ?? 0;

  @override
  Future<void> updateOdometer(double odometerKm) async =>
      savedOdometers.add(odometerKm);
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
  home: ServicesScreen(repository: repository),
);

const _vehicle = Vehicle(
  name: 'Honda Vario 160',
  odometerKm: 24582,
  plateNumber: 'B 1234 XYZ',
);

// Angka-angka ini sengaja sama dengan contoh di
// stitch_odomate_modern_ui/odomate_servis/code.html supaya teks yang diuji
// benar-benar teks yang muncul di desain ("Lewat 82 km", "Sisa 5.418 km").
const _overdueService = ServiceItem(
  id: 1,
  name: 'Ganti Oli Mesin',
  intervalKm: 2000,
  lastServicedOdometerKm: 22500,
);

const _safeService = ServiceItem(
  id: 2,
  name: 'Ganti Busi (Spark Plug)',
  intervalKm: 10000,
  lastServicedOdometerKm: 20000,
);

/// Warna hijau tua `_green`; desain tidak memakainya untuk baris sisa km.
const _safeGreen = Color(0xFF047857);

Finder get _sheetField => find.descendant(
  of: find.byType(OdometerCorrectionSheet),
  matching: find.byType(TextField),
);

void main() {
  testWidgets('editing the odometer opens a bottom sheet, not a dialog', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_FakeRepository(vehicle: _vehicle)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perbarui'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(OdometerCorrectionSheet), findsOneWidget);
    expect(find.text('Edit Odometer Manual'), findsOneWidget);
  });

  testWidgets('the sheet starts from the vehicle odometer and saves the edit', (
    tester,
  ) async {
    final repository = _FakeRepository(vehicle: _vehicle);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perbarui'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(_sheetField).controller?.text, '24582.0');

    await tester.enterText(_sheetField, '25100');
    await tester.tap(find.text('Simpan Odometer'));
    await tester.pumpAndSettle();

    expect(repository.savedOdometers, [25100.0]);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('the +10 km shortcut is applied on top of the entered value', (
    tester,
  ) async {
    final repository = _FakeRepository(vehicle: _vehicle);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perbarui'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('+10 km'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Odometer'));
    await tester.pumpAndSettle();

    expect(repository.savedOdometers, [24592.0]);
  });

  testWidgets('dismissing the sheet leaves the odometer untouched', (
    tester,
  ) async {
    final repository = _FakeRepository(vehicle: _vehicle);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perbarui'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(repository.savedOdometers, isEmpty);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('a safe item shows its remaining distance in gray, not green', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_FakeRepository(vehicle: _vehicle, services: const [_safeService])),
    );
    await tester.pumpAndSettle();

    final scheme = Theme.of(tester.element(find.byType(ServicesScreen)))
        .colorScheme;
    final line = tester.widget<Text>(find.text('Sisa 5.418 km'));

    // Teks desain: `text-secondary font-medium` untuk item yang masih aman.
    expect(line.style?.color, scheme.secondary);
    expect(line.style?.color, isNot(_safeGreen));
    expect(line.style?.fontWeight, FontWeight.w500);
  });

  testWidgets(
    'an overdue item is rose, carries the error icon, and offers Servis',
    (tester) async {
      await tester.pumpWidget(
        _app(
          _FakeRepository(vehicle: _vehicle, services: const [_overdueService]),
        ),
      );
      await tester.pumpAndSettle();

      // `text-rose-600 font-semibold` + ikon `error` 14 hanya untuk yang lewat.
      final line = tester.widget<Text>(find.text('Lewat 82 km'));
      expect(line.style?.color, const Color(0xFFE11D48));
      expect(line.style?.fontWeight, FontWeight.w600);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      // Badge `bg-rose-100 text-rose-700` 10px, dan tombol Servis bergaris.
      // Dicari lewat key karena "Jatuh Tempo" juga jadi label kotak metrik di
      // kartu ringkasan.
      final badge = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('service-card-status-badge')),
          matching: find.text('Jatuh Tempo'),
        ),
      );
      expect(badge.style?.fontSize, 10);
      expect(badge.style?.color, const Color(0xFFBE123C));
      expect(badge.style?.fontWeight, FontWeight.w700);
      expect(
        find.byKey(const ValueKey('service-card-mark-serviced')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the due metric tile labels itself a shade lighter than its count',
    (tester) async {
      await tester.pumpWidget(
        _app(
          _FakeRepository(vehicle: _vehicle, services: const [_overdueService]),
        ),
      );
      await tester.pumpAndSettle();

      final scheme = Theme.of(tester.element(find.byType(ServicesScreen)))
          .colorScheme;
      // Desain: angka `text-rose-700`, label `text-rose-600`. Labelnya juga tidak
      // boleh tertukar dengan badge kartu, yang 10px tapi ber-weight 700.
      final label = tester.widget<Text>(find.text('Jatuh Tempo').first);
      expect(label.style?.color, const Color(0xFFE11D48));
      expect(label.style?.fontWeight, FontWeight.w600);
      expect(label.style?.color, isNot(scheme.onSurface));
    },
  );

  testWidgets('a safe item has no status line icon and no Servis button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_FakeRepository(vehicle: _vehicle, services: const [_safeService])),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    expect(
      find.byKey(const ValueKey('service-card-mark-serviced')),
      findsNothing,
    );
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  testWidgets('the schedule line reads "Rutin Tiap", matching the design', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_FakeRepository(vehicle: _vehicle, services: const [_safeService])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rutin Tiap 10.000 km'), findsOneWidget);
  });

  testWidgets('the section counter is a flat chip next to the heading', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _FakeRepository(
          vehicle: _vehicle,
          services: const [_overdueService, _safeService],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scheme = Theme.of(tester.element(find.byType(ServicesScreen)))
        .colorScheme;
    final chip = tester.widget<Text>(find.text('2 item'));
    expect(chip.style?.color, scheme.secondary);
    expect(chip.style?.fontSize, 12);
  });

  testWidgets('service detail uses the modern status and history layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ServiceDetailScreen(
          repository: _FakeRepository(
            vehicle: _vehicle,
            logs: [
              ServiceLog(
                serviceItemId: _safeService.id!,
                servicedAt: DateTime(2026, 9, 1),
                odometerKm: 24000,
              ),
            ],
          ),
          service: _safeService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Status perawatan'), findsOneWidget);
    expect(find.text('Target berikutnya'), findsOneWidget);
    expect(find.text('Tandai sudah servis'), findsOneWidget);
    expect(find.text('Riwayat servis'), findsOneWidget);
  });
}
