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
      expect(find.byKey(const ValueKey('ride-estimate')), findsOneWidget);
      expect(find.byKey(const ValueKey('ride-final-odometer')), findsOneWidget);
      expect(find.byKey(const ValueKey('ride-route-preview')), findsOneWidget);
      expect(find.byTooltip('Bagikan'), findsOneWidget);
      expect(find.byTooltip('Opsi lainnya'), findsOneWidget);
    },
  );

  testWidgets('more actions open ride detail sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RideDetailScreen(ride: Ride(startedAt: DateTime(2026, 9, 14))),
      ),
    );
    await tester.tap(find.byTooltip('Opsi lainnya'));
    await tester.pumpAndSettle();
    expect(find.text('Detail perjalanan'), findsWidgets);
    expect(find.text('Edit Catatan & Cuaca'), findsOneWidget);
    expect(find.text('Duplikasi Log Perjalanan'), findsOneWidget);
    expect(find.text('Koreksi Jarak Manual'), findsOneWidget);
    expect(find.text('Unduh Bukti GPX / KML'), findsOneWidget);
    expect(find.text('Hapus Log Perjalanan Ini'), findsOneWidget);
  });
}
