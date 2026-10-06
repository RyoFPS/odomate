import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiagnosticLog {
  DiagnosticLog._();

  static final instance = DiagnosticLog._();
  static const _enabledKey = 'diagnosticLogsEnabled';
  static const _entriesKey = 'diagnosticLogs';
  static const _maxEntries = 20;
  static const _maxStackLength = 8000;
  static const exportFileName = 'odomate-diagnostics.txt';

  late final _preferences = SharedPreferencesAsync();
  var _enabled = false;
  var _entries = <String>[];
  Future<void> _writes = Future.value();

  bool get enabled => _enabled;

  Future<void> initialize() async {
    try {
      _enabled = await _preferences.getBool(_enabledKey) ?? false;
      _entries = _enabled
          ? (await _preferences.getStringList(_entriesKey) ?? [])
                .take(_maxEntries)
                .toList()
          : [];
      if (!_enabled) await _preferences.remove(_entriesKey);
    } catch (error, stackTrace) {
      debugPrint('Failed to initialize diagnostic logs: $error\n$stackTrace');
      _enabled = false;
      _entries = [];
    }
  }

  Future<bool> setEnabled(bool enabled) async {
    try {
      await _enqueue(() async {
        if (enabled) {
          await _preferences.setBool(_enabledKey, true);
          _enabled = true;
        } else {
          _enabled = false;
          _entries.clear();
          try {
            await _preferences.remove(_entriesKey);
          } finally {
            await _preferences.setBool(_enabledKey, false);
          }
        }
      });
      return true;
    } catch (error, stackTrace) {
      debugPrint('Failed to save diagnostic setting: $error\n$stackTrace');
      return false;
    }
  }

  Future<void> recordError(Object error, StackTrace? stack) async {
    try {
      await _enqueue(() async {
        if (!_enabled) return;
        final trace = (stack ?? StackTrace.current).toString();
        final entry = [
          DateTime.now().toUtc().toIso8601String(),
          error.runtimeType.toString(),
          trace.length > _maxStackLength
              ? '${trace.substring(0, _maxStackLength)}\n[truncated]'
              : trace,
        ].join('\n');
        _entries.add(entry);
        if (_entries.length > _maxEntries) _entries.removeAt(0);
        await _preferences.setStringList(_entriesKey, _entries);
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to record diagnostic error: $error\n$stackTrace');
    }
  }

  Future<XFile?> exportFile() async {
    await _writes;
    if (!_enabled || _entries.isEmpty) return null;

    final package = await PackageInfo.fromPlatform();
    final osVersion = Platform.operatingSystemVersion.replaceAll(
      RegExp(r'[\r\n]+'),
      ' ',
    );
    final report = [
      'OdoMate diagnostic report',
      'App: ${package.version} (${package.buildNumber})',
      'OS: ${Platform.operatingSystem} $osVersion',
      'Contains error types and stack traces only.',
      'No ride, photo, or location data is included.',
      '',
      ..._entries,
    ].join('\n\n');

    return XFile.fromData(
      utf8.encode(report),
      mimeType: 'text/plain',
      name: exportFileName,
    );
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _writes.then((_) => action());
    _writes = next.catchError((_) {});
    return next;
  }
}
