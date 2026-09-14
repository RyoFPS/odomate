import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/screens/profile_screen.dart';

class _ProfileRepository extends OdomateRepository {
  @override
  Future<Vehicle?> loadVehicle() async =>
      const Vehicle(name: 'Honda Vario 160', odometerKm: 24582);
}

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
}
