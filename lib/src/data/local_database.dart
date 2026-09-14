import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static Future<Database> open() async => openDatabase(
    p.join(await getDatabasesPath(), 'odomate.db'),
    version: 6,
    onCreate: _create,
    onUpgrade: (db, oldVersion, newVersion) => _ensureColumns(db),
    onOpen: _ensureColumns,
  );

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
    final rideRows = await db.rawQuery('PRAGMA table_info(rides)');
    final rideColumns = rideRows.map((row) => row['name'] as String).toSet();
    if (!rideColumns.contains('odometer_applied_km')) {
      await db.execute(
        'ALTER TABLE rides ADD COLUMN odometer_applied_km REAL NOT NULL DEFAULT 0',
      );
    }
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute(
      "CREATE TABLE vehicle (id INTEGER PRIMARY KEY, name TEXT NOT NULL, odometer_km REAL NOT NULL, user_name TEXT NOT NULL DEFAULT '', plate_number TEXT NOT NULL DEFAULT '', photo_path TEXT)",
    );
    await db.execute(
      'CREATE TABLE rides (id INTEGER PRIMARY KEY, started_at TEXT NOT NULL, ended_at TEXT, distance_km REAL NOT NULL, odometer_applied_km REAL NOT NULL DEFAULT 0)',
    );
    await db.execute(
      "CREATE TABLE service_items (id INTEGER PRIMARY KEY, name TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', location TEXT NOT NULL DEFAULT '', cost REAL NOT NULL DEFAULT 0, remind INTEGER NOT NULL DEFAULT 1, interval_km REAL NOT NULL, last_serviced_km REAL NOT NULL)",
    );
    await db.execute(
      'CREATE TABLE service_logs (id INTEGER PRIMARY KEY, service_item_id INTEGER NOT NULL, serviced_at TEXT NOT NULL, odometer_km REAL NOT NULL, note TEXT)',
    );
    await db.execute(
      'CREATE TABLE notification_state (service_item_id INTEGER PRIMARY KEY, cycle INTEGER NOT NULL, last_reminder TEXT)',
    );
  }
}
