import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/widgets/app_header.dart';
import 'package:odomate/src/widgets/metric_tile.dart';
import 'package:odomate/src/widgets/sheet_frame.dart';
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

  testWidgets('MetricTile renders optional footer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricTile(
            label: 'Hari ini',
            value: '12.4',
            suffix: 'km',
            footer: '3 ride',
            icon: Icons.today_outlined,
          ),
        ),
      ),
    );

    expect(find.text('3 ride'), findsOneWidget);
  });

  testWidgets('SheetFrame renders title, subtitle, and child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SheetFrame(
            title: 'Hapus ride?',
            subtitle: 'Tindakan ini tidak bisa dibatalkan.',
            child: Text('isi'),
          ),
        ),
      ),
    );

    expect(find.text('Hapus ride?'), findsOneWidget);
    expect(find.text('Tindakan ini tidak bisa dibatalkan.'), findsOneWidget);
    expect(find.text('isi'), findsOneWidget);
  });

  testWidgets('showConfirmSheet returns true on confirm', (tester) async {
    var result = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showConfirmSheet(
                  context: context,
                  title: 'Hapus?',
                  confirmLabel: 'Hapus',
                  cancelLabel: 'Batal',
                );
              },
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('showConfirmSheet returns false on cancel', (tester) async {
    var result = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showConfirmSheet(
                  context: context,
                  title: 'Hapus?',
                  confirmLabel: 'Hapus',
                  cancelLabel: 'Batal',
                );
              },
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
