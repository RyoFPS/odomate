import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/widgets/app_header.dart';
import 'package:odomate/src/widgets/metric_tile.dart';
import 'package:odomate/src/widgets/status_badge.dart';

void main() {
  testWidgets('AppHeader renders title, subtitle, back, and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: const AppHeader(
            title: 'Riwayat',
            subtitle: 'Log waktu & jarak tempuh',
            actions: [Icon(Icons.search)],
          ),
        ),
      ),
    );

    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Log waktu & jarak tempuh'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('MetricTile renders value, suffix, and icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricTile(
            label: 'Jarak',
            value: '12.4',
            suffix: 'km',
            icon: Icons.route,
          ),
        ),
      ),
    );

    expect(find.text('Jarak'), findsOneWidget);
    expect(find.text('12.4 km'), findsOneWidget);
    expect(find.byIcon(Icons.route), findsOneWidget);
  });

  testWidgets('StatusBadge renders its label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(
            label: 'Selesai',
            foregroundColor: Colors.blue,
            backgroundColor: Colors.lightBlueAccent,
          ),
        ),
      ),
    );

    expect(find.text('Selesai'), findsOneWidget);
  });
}
