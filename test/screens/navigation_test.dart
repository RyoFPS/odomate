import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/app.dart';

void main() {
  testWidgets('bottom navigation exposes four tabs and ride action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigation(
          pages: const [
            Text('Home page'),
            Text('History page'),
            Text('Service page'),
            Text('Profile page'),
          ],
          rideActive: false,
          onRide: () {},
        ),
      ),
    );
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.byTooltip('Start Ride'), findsOneWidget);
    expect(find.text('Service'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
