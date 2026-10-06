import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/app.dart';
import 'package:odomate/src/diagnostics/diagnostic_log.dart';
import 'package:odomate/src/screens/settings_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    PackageInfo.setMockInitialValues(
      appName: 'OdoMate',
      packageName: 'com.example.odomate',
      version: '0.1.1',
      buildNumber: '2',
      buildSignature: 'test',
    );
    await DiagnosticLog.instance.setEnabled(false);
    await DiagnosticLog.instance.initialize();
  });

  testWidgets('settings opt-in controls export availability', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: odomateTheme(Brightness.light),
        home: SettingsScreen(
          themeMode: ThemeMode.light,
          language: 'id',
          onThemeChanged: (_) {},
          onLanguageChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final toggleLabel = find.text('Kumpulkan log error aplikasi');
    await tester.scrollUntilVisible(toggleLabel, 250);
    final toggle = find.ancestor(
      of: toggleLabel,
      matching: find.byType(SwitchListTile),
    );
    final toggleSwitch = find.descendant(
      of: toggle,
      matching: find.byType(Switch),
    );
    final exportLabel = find.text('Ekspor log diagnostik');
    await tester.scrollUntilVisible(exportLabel, 250);
    final exportButton = find.widgetWithText(
      OutlinedButton,
      'Ekspor log diagnostik',
    );
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(tester.widget<OutlinedButton>(exportButton).onPressed, isNull);

    await tester.ensureVisible(toggle);
    await tester.tap(toggleSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(tester.widget<OutlinedButton>(exportButton).onPressed, isNotNull);

    await tester.ensureVisible(toggle);
    await tester.tap(toggleSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(tester.widget<OutlinedButton>(exportButton).onPressed, isNull);
  });
}
