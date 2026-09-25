import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/app.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/screens/history_screen.dart';
import 'package:odomate/src/screens/services_screen.dart';
import 'package:odomate/src/screens/service_style.dart';
import 'package:odomate/src/widgets/date_range_chips.dart';
import 'package:odomate/src/widgets/skeleton_loader.dart';
import 'package:odomate/src/i18n/app_localizations.dart';

class _FakeRepository extends OdomateRepository {
  @override
  Future<Vehicle?> loadVehicle() async =>
      const Vehicle(name: 'Honda Vario 160', odometerKm: 24582);

  @override
  Future<List<ServiceItem>> listServices() async => const [
    ServiceItem(
      id: 1,
      name: 'Ganti Oli Mesin',
      intervalKm: 2000,
      lastServicedOdometerKm: 24000,
    ),
  ];

  @override
  Future<List<Ride>> listRidesPage({
    required int limit,
    required int offset,
  }) async => const [];

  @override
  Future<List<ServiceLog>> listServiceLogsPage({
    required int limit,
    required int offset,
  }) async => const [];
}

Widget _darkApp(Widget child) => MaterialApp(
  theme: odomateTheme(Brightness.dark),
  locale: const Locale('id'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

Widget _darkScreen(Widget child) => MaterialApp(
  theme: odomateTheme(Brightness.dark),
  locale: const Locale('id'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: child,
);

void main() {
  testWidgets('date range chips use dark scheme colors', (tester) async {
    await tester.pumpWidget(
      _darkApp(
        DateRangeChips(
          labels: const ['Semua', '7 hari'],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final colors = odomateTheme(Brightness.dark).colorScheme;
    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));

    expect(chips.first.backgroundColor, colors.surfaceContainer);
    expect(chips.first.selectedColor, colors.primaryContainer);
    expect(chips.first.labelStyle?.color, colors.onPrimary);
  });

  testWidgets('skeleton loader uses dark surface tokens', (tester) async {
    await tester.pumpWidget(_darkApp(const SkeletonLoader(rows: 1)));
    await tester.pumpAndSettle();

    final colors = odomateTheme(Brightness.dark).colorScheme;
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color == colors.surface,
      ),
      findsWidgets,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color ==
                colors.surfaceContainerHighest,
      ),
      findsWidgets,
    );
  });

  testWidgets('services screen uses dark scaffold and app bar surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      _darkScreen(ServicesScreen(repository: _FakeRepository())),
    );
    await tester.pumpAndSettle();

    final colors = odomateTheme(Brightness.dark).colorScheme;
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      colors.surface,
    );
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).backgroundColor,
      colors.surface,
    );
  });

  testWidgets('history summary uses dark text and vehicle pill tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      _darkScreen(HistoryScreen(repository: _FakeRepository())),
    );
    await tester.pumpAndSettle();

    final colors = odomateTheme(Brightness.dark).colorScheme;
    final summary = find.textContaining('Ringkasan');
    expect(tester.widget<Text>(summary).style?.color, colors.onSurfaceVariant);
    expect(find.text('Honda Vario 160'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Honda Vario 160')).style?.color,
      colors.onPrimary,
    );
  });

  test('safe service tone stays green in dark mode', () {
    final colors = odomateTheme(Brightness.dark).colorScheme;
    final tone = serviceTone(ServiceStatus.safe, colors);

    expect(tone.icon, colors.tertiary);
    expect(tone.soft, colors.tertiary.withValues(alpha: .18));
    expect(tone.chipBg, colors.tertiary.withValues(alpha: .22));
    expect(tone.chipText, colors.tertiary);
  });
}
