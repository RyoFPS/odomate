import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static Future<Database> open() async => openDatabase(
    p.join(await getDatabasesPath(), 'odomate.db'),
    version: 1,
    onCreate: _create,
  );
  static Future<void> _create(Database db, int version) async {
    await db.execute(
      'CREATE TABLE vehicle (id INTEGER PRIMARY KEY, name TEXT NOT NULL, odometer_km REAL NOT NULL)',
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
