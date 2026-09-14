import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/i18n/app_localizations.dart';
import 'package:odomate/src/screens/services_screen.dart';
import 'package:odomate/src/widgets/odometer_correction_sheet.dart';

class _FakeRepository extends OdomateRepository {
  _FakeRepository({this.vehicle});

  final Vehicle? vehicle;
  final List<double> savedOdometers = [];

  @override
  Future<Vehicle?> loadVehicle() async => vehicle;

  @override
  Future<List<ServiceItem>> listServices() async => const [];

  @override
  Future<void> saveService(ServiceItem item) async {}

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
}
