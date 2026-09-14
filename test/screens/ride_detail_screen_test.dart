import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/screens/ride_detail_screen.dart';

void main() {
  testWidgets(
    'ride detail surfaces an average speed metric from saved ride data',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RideDetailScreen(
            ride: Ride(
              startedAt: DateTime(2026, 9, 14, 7),
              endedAt: DateTime(2026, 9, 14, 7, 30),
              distanceKm: 15,
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('ride-average-speed')), findsOneWidget);
    },
  );
}
