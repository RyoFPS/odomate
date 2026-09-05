import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late OdomateRepository repository;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE vehicle (id INTEGER PRIMARY KEY, name TEXT NOT NULL, odometer_km REAL NOT NULL, user_name TEXT NOT NULL DEFAULT \'\', plate_number TEXT NOT NULL DEFAULT \'\', photo_path TEXT)',
          );
          await db.execute(
            'CREATE TABLE service_items (id INTEGER PRIMARY KEY, name TEXT NOT NULL, description TEXT NOT NULL DEFAULT \'\', interval_km REAL NOT NULL, last_serviced_km REAL NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE service_logs (id INTEGER PRIMARY KEY, service_item_id INTEGER NOT NULL, serviced_at TEXT NOT NULL, odometer_km REAL NOT NULL, note TEXT)',
          );
          await db.execute(
            'CREATE TABLE rides (id INTEGER PRIMARY KEY, started_at TEXT NOT NULL, ended_at TEXT, distance_km REAL NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE notification_state (service_item_id INTEGER PRIMARY KEY, cycle INTEGER NOT NULL, last_reminder TEXT)',
          );
        },
      ),
    );
    repository = OdomateRepository(databaseFactory: () async => database);
  });

  tearDown(() => database.close());

  test('persists service description, logs, and notification state', () async {
    await repository.saveVehicle(const Vehicle(name: 'Beat', odometerKm: 1000));
    await repository.saveService(
      const ServiceItem(
        id: 1,
        name: 'Oli',
        description: 'Ganti oli',
        intervalKm: 1000,
        lastServicedOdometerKm: 0,
      ),
    );
    await repository.recordService(
      ServiceLog(
        serviceItemId: 1,
        servicedAt: DateTime(2026, 9, 5),
        odometerKm: 1000,
      ),
    );
    await repository.saveNotificationState(
      1,
      const NotificationState(cycle: 2, lastReminder: ServiceReminder.dueSoon),
    );

    expect((await repository.listServices()).single.description, 'Ganti oli');
    expect((await repository.listServiceLogs()).single.odometerKm, 1000);
    final state = await repository.loadNotificationState(1);
    expect(state.cycle, 2);
    expect(state.lastReminder, ServiceReminder.dueSoon);
  });

  test('corrects odometer without creating a ride', () async {
    await repository.saveVehicle(const Vehicle(name: 'Beat', odometerKm: 1000));
    await repository.updateOdometer(1234.5);

    expect((await repository.loadVehicle())!.odometerKm, 1234.5);
    expect(await repository.listRides(), isEmpty);
  });
}
