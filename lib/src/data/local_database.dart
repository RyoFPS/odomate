import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static Future<Database> open() async => openDatabase(
    p.join(await getDatabasesPath(), 'odomate.db'),
    version: 3,
    onCreate: _create,
    onUpgrade: (db, oldVersion, newVersion) => _ensureVehicleColumns(db),
    onOpen: _ensureVehicleColumns,
  );

  static Future<void> _ensureVehicleColumns(Database db) async {
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
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute(
      "CREATE TABLE vehicle (id INTEGER PRIMARY KEY, name TEXT NOT NULL, odometer_km REAL NOT NULL, user_name TEXT NOT NULL DEFAULT '', plate_number TEXT NOT NULL DEFAULT '', photo_path TEXT)",
    );
    await db.execute(
      'CREATE TABLE rides (id INTEGER PRIMARY KEY, started_at TEXT NOT NULL, ended_at TEXT, distance_km REAL NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE service_items (id INTEGER PRIMARY KEY, name TEXT NOT NULL, interval_km REAL NOT NULL, last_serviced_km REAL NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE service_logs (id INTEGER PRIMARY KEY, service_item_id INTEGER NOT NULL, serviced_at TEXT NOT NULL, odometer_km REAL NOT NULL, note TEXT)',
    );
    await db.execute(
      'CREATE TABLE notification_state (service_item_id INTEGER PRIMARY KEY, cycle INTEGER NOT NULL, last_reminder TEXT)',
    );
  }
}
