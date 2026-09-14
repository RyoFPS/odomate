import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late String databasePath;
  var databaseClosed = false;
  late OdomateRepository repository;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final directory = await Directory.systemTemp.createTemp('odomate-test-');
    databasePath = p.join(directory.path, 'odomate.db');
    database = await databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE vehicle (id INTEGER PRIMARY KEY, name TEXT NOT NULL, odometer_km REAL NOT NULL, user_name TEXT NOT NULL DEFAULT \'\', plate_number TEXT NOT NULL DEFAULT \'\', photo_path TEXT)',
          );
          await db.execute(
            'CREATE TABLE service_items (id INTEGER PRIMARY KEY, name TEXT NOT NULL, description TEXT NOT NULL DEFAULT \'\', location TEXT NOT NULL DEFAULT \'\', cost REAL NOT NULL DEFAULT 0, remind INTEGER NOT NULL DEFAULT 1, interval_km REAL NOT NULL, last_serviced_km REAL NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE service_logs (id INTEGER PRIMARY KEY, service_item_id INTEGER NOT NULL, serviced_at TEXT NOT NULL, odometer_km REAL NOT NULL, note TEXT)',
          );
          await db.execute(
            'CREATE TABLE rides (id INTEGER PRIMARY KEY, started_at TEXT NOT NULL, ended_at TEXT, distance_km REAL NOT NULL, odometer_applied_km REAL NOT NULL DEFAULT 0)',
          );
          await db.execute(
            'CREATE TABLE notification_state (service_item_id INTEGER PRIMARY KEY, cycle INTEGER NOT NULL, last_reminder TEXT)',
          );
        },
      ),
    );
    databaseClosed = false;
    repository = OdomateRepository(databaseFactory: () async => database);
  });

  tearDown(() async {
    if (!databaseClosed) await database.close();
    await databaseFactory.deleteDatabase(databasePath);
  });

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

  test('round-trips the service cost, workshop, and reminder flag', () async {
    await repository.saveService(
      const ServiceItem(
        id: 1,
        name: 'Ganti Oli Mesin',
        location: 'AHASS Tebet Jaya',
        cost: 85000,
        intervalKm: 2000,
        lastServicedOdometerKm: 24582,
        remind: false,
      ),
    );

    final stored = (await repository.listServices()).single;
    expect(stored.location, 'AHASS Tebet Jaya');
    expect(stored.cost, 85000);
    expect(stored.remind, isFalse);
  });

  test('defaults cost, workshop, and reminder for rows saved without them', () async {
    // Baris lama (skema sebelum kolom ini ada) harus tetap terbaca: biaya 0,
    // bengkel kosong, dan pengingat menyala.
    await database.insert('service_items', {
      'id': 7,
      'name': 'Busi',
      'interval_km': 8000.0,
      'last_serviced_km': 1000.0,
    });

    final stored = (await repository.listServices()).single;
    expect(stored.location, isEmpty);
    expect(stored.cost, 0);
    expect(stored.remind, isTrue);
  });

  test('corrects odometer without creating a ride', () async {
    await repository.saveVehicle(const Vehicle(name: 'Beat', odometerKm: 1000));
    await repository.updateOdometer(1234.5);

    expect((await repository.loadVehicle())!.odometerKm, 1234.5);
    expect(await repository.listRides(), isEmpty);
  });

  test(
    'applies an active ride checkpoint to the odometer immediately',
    () async {
      await repository.saveVehicle(
        const Vehicle(name: 'Beat', odometerKm: 1000),
      );
      final id = await repository.createRide(
        Ride(startedAt: DateTime(2026, 9, 14, 8)),
      );

      await repository.saveActiveRideCheckpoint(
        Ride(id: id, startedAt: DateTime(2026, 9, 14, 8), distanceKm: 1.25),
      );

      expect((await repository.loadVehicle())!.odometerKm, 1001.25);
    },
  );

  test(
    'does not add an already applied checkpoint again when stopping',
    () async {
      await repository.saveVehicle(
        const Vehicle(name: 'Beat', odometerKm: 1000),
      );
      final id = await repository.createRide(
        Ride(startedAt: DateTime(2026, 9, 14, 8)),
      );
      await repository.saveActiveRideCheckpoint(
        Ride(id: id, startedAt: DateTime(2026, 9, 14, 8), distanceKm: 1.25),
      );

      await repository.finishRide(id, DateTime(2026, 9, 14, 8, 10), 1.25);

      expect((await repository.loadVehicle())!.odometerKm, 1001.25);
    },
  );

  test('lists stored rides after reopening the repository', () async {
    final startedAt = DateTime(2026, 9, 5, 8, 30);
    await repository.createRide(Ride(startedAt: startedAt, distanceKm: 12.5));
    await database.close();
    databaseClosed = true;

    final reopenedRepository = OdomateRepository(
      databaseFactory: () => databaseFactory.openDatabase(databasePath),
    );

    database = await reopenedRepository.db;
    databaseClosed = false;
    final rides = await reopenedRepository.listRides();
    expect(rides, hasLength(1));
    expect(rides.single.startedAt, startedAt);
    expect(rides.single.distanceKm, 12.5);
  });
}
