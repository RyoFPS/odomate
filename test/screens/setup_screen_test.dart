import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/screens/setup_screen.dart';

class _SetupRepository extends OdomateRepository {
  Vehicle? savedVehicle;

  @override
  Future<void> saveVehicle(Vehicle vehicle) async => savedVehicle = vehicle;

  @override
  Future<void> saveService(ServiceItem service) async {}
}

void main() {
  testWidgets('setup saves user, vehicle, plate, and odometer', (tester) async {
    final repository = _SetupRepository();
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SetupScreen(repository: repository, onSaved: () => saved = true),
      ),
    );

    await tester.enterText(find.byKey(const Key('setup-user-name')), 'Ryo');
    await tester.enterText(
      find.byKey(const Key('setup-vehicle-name')),
      'Honda BeaT',
    );
    await tester.enterText(
      find.byKey(const Key('setup-plate-number')),
      'F 6767 FJO',
    );
    await tester.enterText(find.byKey(const Key('setup-odometer')), '16000');
    await tester.scrollUntilVisible(
      find.text('Mulai menggunakan OdoMate'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mulai menggunakan OdoMate'));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    expect(repository.savedVehicle?.userName, 'Ryo');
    expect(repository.savedVehicle?.name, 'Honda BeaT');
    expect(repository.savedVehicle?.plateNumber, 'F 6767 FJO');
    expect(repository.savedVehicle?.odometerKm, 16000);
  });
}
