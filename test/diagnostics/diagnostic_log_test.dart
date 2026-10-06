import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/diagnostics/diagnostic_log.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  const entriesKey = 'diagnosticLogs';
  final diagnostics = DiagnosticLog.instance;
  final preferences = InMemorySharedPreferencesAsync.empty();

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = preferences;
    PackageInfo.setMockInitialValues(
      appName: 'OdoMate',
      packageName: 'com.example.odomate',
      version: '0.1.1',
      buildNumber: '2',
      buildSignature: 'test',
    );
    await diagnostics.setEnabled(false);
    await diagnostics.initialize();
  });

  test('keeps a bounded private log and exports diagnostic metadata', () async {
    await diagnostics.setEnabled(true);
    final longTrace = List.filled(9000, 'x').join();

    for (var index = 0; index < 21; index++) {
      await diagnostics.recordError(
        StateError('private-ride-data-$index'),
        StackTrace.fromString(index == 20 ? longTrace : 'stack-$index'),
      );
    }

    final entries = await SharedPreferencesAsync().getStringList(entriesKey);
    expect(entries, hasLength(20));
    expect(entries!.first, contains('stack-1'));
    expect(
      entries.last,
      contains('${longTrace.substring(0, 8000)}\n[truncated]'),
    );
    expect(entries.last, isNot(contains(longTrace)));
    expect(entries.join('\n'), isNot(contains('private-ride-data')));

    final file = await diagnostics.exportFile();
    expect(file, isNotNull);
    expect(DiagnosticLog.exportFileName, 'odomate-diagnostics.txt');
    final report = await file!.readAsString();
    expect(report, contains('App: 0.1.1 (2)'));
    expect(report, contains('OS: ${Platform.operatingSystem}'));
    expect(report, contains('No ride, photo, or location data is included.'));
    expect(report, isNot(contains('private-ride-data')));
  });

  test(
    'does not collect by default and disabling clears saved entries',
    () async {
      expect(diagnostics.enabled, isFalse);
      await diagnostics.recordError(
        StateError('private-data'),
        StackTrace.current,
      );
      expect(await diagnostics.exportFile(), isNull);

      await diagnostics.setEnabled(true);
      await diagnostics.recordError(
        StateError('private-data'),
        StackTrace.current,
      );
      expect(
        await SharedPreferencesAsync().getStringList(entriesKey),
        isNotEmpty,
      );

      await diagnostics.setEnabled(false);
      expect(await SharedPreferencesAsync().getStringList(entriesKey), isNull);
      expect(await diagnostics.exportFile(), isNull);
    },
  );
}
