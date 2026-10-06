import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class LocalDatabase {
  static const _keyStorage = FlutterSecureStorage();
  static const _keyName = 'odomate_database_key';

  static Future<Database> open() async {
    final directory = await getDatabasesPath();
    final legacyPath = p.join(directory, 'odomate.db');
    final databasePath = p.join(directory, 'odomate_encrypted.db');
    final password = await _databaseKey();

    if (!await databaseExists(databasePath) &&
        await databaseExists(legacyPath)) {
      await _encryptLegacyDatabase(legacyPath, databasePath, password);
    }

    final database = await _openEncrypted(databasePath, password);
    try {
      if (await databaseExists(legacyPath)) await deleteDatabase(legacyPath);
      return database;
    } catch (_) {
      await database.close();
      rethrow;
    }
  }

  static Future<String> _databaseKey() async {
    final existing = await _keyStorage.read(key: _keyName);
    if (existing != null) {
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(existing)) {
        throw StateError('Stored database encryption key is invalid.');
      }
      return existing;
    }

    final random = Random.secure();
    final key = List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _keyStorage.write(key: _keyName, value: key);
    return key;
  }

  static Future<Database> _openEncrypted(String path, String password) =>
      openDatabase(
        path,
        password: password,
        version: 8,
        onCreate: _create,
        onUpgrade: (db, oldVersion, newVersion) => _ensureColumns(db),
        onOpen: _ensureColumns,
      );

  static Future<void> _encryptLegacyDatabase(
    String legacyPath,
    String databasePath,
    String password,
  ) async {
    final temporaryPath = '$databasePath.migrating';
    await deleteDatabase(temporaryPath);

    final legacy = await openDatabase(
      legacyPath,
      version: 8,
      onUpgrade: (db, oldVersion, newVersion) => _ensureColumns(db),
      onOpen: _ensureColumns,
    );
    try {
      await legacy.execute('ATTACH DATABASE ? AS encrypted KEY ?', [
        temporaryPath,
        password,
      ]);
      try {
        await legacy.rawQuery("SELECT sqlcipher_export('encrypted')");
        await legacy.execute('PRAGMA encrypted.user_version = 8');
      } finally {
        await legacy.execute('DETACH DATABASE encrypted');
      }
    } finally {
      await legacy.close();
    }

    final encrypted = await openDatabase(
      temporaryPath,
      password: password,
      readOnly: true,
    );
    try {
      final check = await encrypted.rawQuery('PRAGMA quick_check');
      if (check.isEmpty || check.first.values.first != 'ok') {
        throw StateError('Encrypted database migration failed validation.');
      }
    } finally {
      await encrypted.close();
    }
    await File(temporaryPath).rename(databasePath);
  }

  static Future<void> _ensureColumns(Database db) async {
    final rows = await db.rawQuery('PRAGMA table_info(vehicle)');
    final columns = rows.map((row) => row['name'] as String).toSet();
    if (!columns.contains('user_name')) {
      await db.execute(
        "ALTER TABLE vehicle ADD COLUMN user_name TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!columns.contains('plate_number')) {
      await db.execute(
        "ALTER TABLE vehicle ADD COLUMN plate_number TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!columns.contains('photo_path')) {
      await db.execute('ALTER TABLE vehicle ADD COLUMN photo_path TEXT');
    }
    final serviceRows = await db.rawQuery('PRAGMA table_info(service_items)');
    final serviceColumns = serviceRows
        .map((row) => row['name'] as String)
        .toSet();
    if (!serviceColumns.contains('description')) {
      await db.execute(
        "ALTER TABLE service_items ADD COLUMN description TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!serviceColumns.contains('location')) {
      await db.execute(
        "ALTER TABLE service_items ADD COLUMN location TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!serviceColumns.contains('cost')) {
      await db.execute(
        'ALTER TABLE service_items ADD COLUMN cost REAL NOT NULL DEFAULT 0',
      );
    }
    if (!serviceColumns.contains('remind')) {
      await db.execute(
        'ALTER TABLE service_items ADD COLUMN remind INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (!serviceColumns.contains('interval_months')) {
      await db.execute(
        'ALTER TABLE service_items ADD COLUMN interval_months INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!serviceColumns.contains('last_serviced_at')) {
      await db.execute(
        'ALTER TABLE service_items ADD COLUMN last_serviced_at TEXT',
      );
    }
    final rideRows = await db.rawQuery('PRAGMA table_info(rides)');
    final rideColumns = rideRows.map((row) => row['name'] as String).toSet();
    if (!rideColumns.contains('odometer_applied_km')) {
      await db.execute(
        'ALTER TABLE rides ADD COLUMN odometer_applied_km REAL NOT NULL DEFAULT 0',
      );
    }
    if (!rideColumns.contains('notes')) {
      await db.execute(
        "ALTER TABLE rides ADD COLUMN notes TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!rideColumns.contains('weather')) {
      await db.execute(
        "ALTER TABLE rides ADD COLUMN weather TEXT NOT NULL DEFAULT ''",
      );
    }
    await db.execute(
      'CREATE TABLE IF NOT EXISTS ride_points ('
      'id INTEGER PRIMARY KEY, ride_id INTEGER NOT NULL, '
      'latitude REAL NOT NULL, longitude REAL NOT NULL, '
      'accuracy_m REAL NOT NULL, recorded_at TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ride_points_ride_id_id '
      'ON ride_points(ride_id, id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_rides_started_at ON rides(started_at)',
    );
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute(
      "CREATE TABLE vehicle (id INTEGER PRIMARY KEY, name TEXT NOT NULL, odometer_km REAL NOT NULL, user_name TEXT NOT NULL DEFAULT '', plate_number TEXT NOT NULL DEFAULT '', photo_path TEXT)",
    );
    await db.execute(
      "CREATE TABLE rides (id INTEGER PRIMARY KEY, started_at TEXT NOT NULL, ended_at TEXT, distance_km REAL NOT NULL, odometer_applied_km REAL NOT NULL DEFAULT 0, notes TEXT NOT NULL DEFAULT '', weather TEXT NOT NULL DEFAULT '')",
    );
    await db.execute(
      'CREATE TABLE ride_points ('
      'id INTEGER PRIMARY KEY, ride_id INTEGER NOT NULL, '
      'latitude REAL NOT NULL, longitude REAL NOT NULL, '
      'accuracy_m REAL NOT NULL, recorded_at TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE INDEX idx_ride_points_ride_id_id '
      'ON ride_points(ride_id, id)',
    );
    await db.execute(
      "CREATE TABLE service_items (id INTEGER PRIMARY KEY, name TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', location TEXT NOT NULL DEFAULT '', cost REAL NOT NULL DEFAULT 0, remind INTEGER NOT NULL DEFAULT 1, interval_km REAL NOT NULL, last_serviced_km REAL NOT NULL, interval_months INTEGER NOT NULL DEFAULT 0, last_serviced_at TEXT)",
    );
    await db.execute(
      'CREATE TABLE service_logs (id INTEGER PRIMARY KEY, service_item_id INTEGER NOT NULL, serviced_at TEXT NOT NULL, odometer_km REAL NOT NULL, note TEXT)',
    );
    await db.execute(
      'CREATE TABLE notification_state (service_item_id INTEGER PRIMARY KEY, cycle INTEGER NOT NULL, last_reminder TEXT)',
    );
  }
}
