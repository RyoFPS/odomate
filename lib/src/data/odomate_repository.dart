import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';
import 'local_database.dart';

class OdomateRepository {
  final Future<Database> Function() _open;
  Database? _db;
  OdomateRepository({Future<Database> Function()? databaseFactory})
    : _open = databaseFactory ?? LocalDatabase.open;
  Future<Database> get db async => _db ??= await _open();

  Future<Vehicle?> loadVehicle() async {
    final rows = await (await db).query('vehicle', limit: 1);
    return rows.isEmpty ? null : _vehicle(rows.first);
  }

  Future<void> saveVehicle(Vehicle v) async => (await db).insert('vehicle', {
    'id': v.id ?? 1,
    'name': v.name,
    'odometer_km': v.odometerKm,
    'user_name': v.userName,
    'plate_number': v.plateNumber,
    'photo_path': v.photoPath,
  }, conflictAlgorithm: ConflictAlgorithm.replace);
  Future<int> createRide(Ride r) async => (await db).insert('rides', {
    'started_at': r.startedAt.toIso8601String(),
    'distance_km': r.distanceKm,
  });
  Future<void> finishRide(int id, DateTime endedAt, double distanceKm) async =>
      (await db).transaction((tx) async {
        await tx.update(
          'rides',
          {'ended_at': endedAt.toIso8601String(), 'distance_km': distanceKm},
          where: 'id = ?',
          whereArgs: [id],
        );
        final v = await tx.query('vehicle', limit: 1);
        if (v.isNotEmpty) {
          await tx.update(
            'vehicle',
            {
              'odometer_km':
                  (v.first['odometer_km'] as num).toDouble() + distanceKm,
            },
            where: 'id = ?',
            whereArgs: [v.first['id']],
          );
        }
      });
  Future<Ride?> loadActiveRide() async {
    final rows = await (await db).query(
      'rides',
      where: 'ended_at IS NULL',
      orderBy: 'id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : _ride(rows.first);
  }

  Future<List<Ride>> listRides() async => (await (await db).query(
    'rides',
    orderBy: 'started_at DESC',
  )).map(_ride).toList();
  Future<List<ServiceItem>> listServices() async => (await (await db).query(
    'service_items',
    orderBy: 'id',
  )).map(_service).toList();
  Future<void> saveService(ServiceItem s) async =>
      (await db).insert('service_items', {
        'id': s.id,
        'name': s.name,
        'interval_km': s.intervalKm,
        'last_serviced_km': s.lastServicedOdometerKm,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> deleteService(int id) async =>
      (await db).delete('service_items', where: 'id = ?', whereArgs: [id]);
  Future<void> recordService(ServiceLog l) async {
    final d = await db;
    await d.transaction((tx) async {
      await tx.insert('service_logs', {
        'service_item_id': l.serviceItemId,
        'serviced_at': l.servicedAt.toIso8601String(),
        'odometer_km': l.odometerKm,
        'note': l.note,
      });
      await tx.update(
        'service_items',
        {'last_serviced_km': l.odometerKm},
        where: 'id = ?',
        whereArgs: [l.serviceItemId],
      );
    });
  }

  Future<void> saveActiveRideCheckpoint(Ride r) async {
    final d = await db;
    if (r.id == null) return;
    await d.update(
      'rides',
      {'distance_km': r.distanceKm},
      where: 'id = ?',
      whereArgs: [r.id],
    );
  }

  Future<List<ServiceLog>> listServiceLogs() async =>
      (await (await db).query('service_logs', orderBy: 'serviced_at DESC'))
          .map(
            (r) => ServiceLog(
              id: r['id'] as int,
              serviceItemId: r['service_item_id'] as int,
              servicedAt: DateTime.parse(r['serviced_at'] as String),
              odometerKm: (r['odometer_km'] as num).toDouble(),
              note: r['note'] as String?,
            ),
          )
          .toList();
  Vehicle _vehicle(Map<String, Object?> r) => Vehicle(
    id: r['id'] as int,
    name: r['name'] as String,
    odometerKm: (r['odometer_km'] as num).toDouble(),
    userName: r['user_name'] as String? ?? '',
    plateNumber: r['plate_number'] as String? ?? '',
    photoPath: r['photo_path'] as String?,
  );
  Ride _ride(Map<String, Object?> r) => Ride(
    id: r['id'] as int,
    startedAt: DateTime.parse(r['started_at'] as String),
    endedAt: r['ended_at'] == null
        ? null
        : DateTime.parse(r['ended_at'] as String),
    distanceKm: (r['distance_km'] as num).toDouble(),
  );
  ServiceItem _service(Map<String, Object?> r) => ServiceItem(
    id: r['id'] as int,
    name: r['name'] as String,
    intervalKm: (r['interval_km'] as num).toDouble(),
    lastServicedOdometerKm: (r['last_serviced_km'] as num).toDouble(),
  );
}
