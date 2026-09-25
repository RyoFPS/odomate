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
  Future<void> updateOdometer(double odometerKm) async {
    await (await db).update('vehicle', {'odometer_km': odometerKm});
  }

  Future<int> createRide(Ride r) async => (await db).insert('rides', {
    'started_at': r.startedAt.toIso8601String(),
    'ended_at': r.endedAt?.toIso8601String(),
    'distance_km': r.distanceKm,
    'notes': r.notes,
    'weather': r.weather,
  });
  Future<int> duplicateRide(Ride r) {
    final startedAt = DateTime.now();
    final duration = r.endedAt?.difference(r.startedAt);
    return createRide(
      Ride(
        startedAt: startedAt,
        endedAt: duration == null ? null : startedAt.add(duration),
        distanceKm: r.distanceKm,
        notes: r.notes,
        weather: r.weather,
      ),
    );
  }

  Future<void> updateRideDetails(
    int id, {
    required String notes,
    required String weather,
  }) async => (await db).update(
    'rides',
    {'notes': notes, 'weather': weather},
    where: 'id = ?',
    whereArgs: [id],
  );
  Future<void> updateRideDistance(int id, double distanceKm) async {
    final d = await db;
    await d.transaction((tx) async {
      final rows = await tx.query(
        'rides',
        columns: ['distance_km'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Ride not found');
      final oldDistance = (rows.first['distance_km'] as num).toDouble();
      await tx.update(
        'rides',
        {'distance_km': distanceKm},
        where: 'id = ?',
        whereArgs: [id],
      );
      final vehicle = await tx.query('vehicle', limit: 1);
      if (vehicle.isNotEmpty) {
        await tx.update(
          'vehicle',
          {
            'odometer_km':
                (vehicle.first['odometer_km'] as num).toDouble() +
                distanceKm -
                oldDistance,
          },
          where: 'id = ?',
          whereArgs: [vehicle.first['id']],
        );
      }
    });
  }

  Future<void> deleteRide(int id) async {
    final d = await db;
    await d.transaction((tx) async {
      await tx.delete('ride_points', where: 'ride_id = ?', whereArgs: [id]);
      await tx.delete('rides', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> appendRidePoint(int rideId, GeoPoint point) async =>
      (await db).insert('ride_points', {
        'ride_id': rideId,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'accuracy_m': point.accuracyMeters,
        'recorded_at': (point.timestamp ?? DateTime.now()).toIso8601String(),
      });
  Future<List<GeoPoint>> listRidePoints(int rideId) async =>
      (await (await db).query(
            'ride_points',
            where: 'ride_id = ?',
            whereArgs: [rideId],
            orderBy: 'id ASC',
          ))
          .map(
            (row) => GeoPoint(
              latitude: (row['latitude'] as num).toDouble(),
              longitude: (row['longitude'] as num).toDouble(),
              accuracyMeters: (row['accuracy_m'] as num).toDouble(),
              timestamp: DateTime.parse(row['recorded_at'] as String),
            ),
          )
          .toList();
  Future<void> finishRide(int id, DateTime endedAt, double distanceKm) async =>
      (await db).transaction((tx) async {
        final ride = await tx.query(
          'rides',
          columns: ['distance_km', 'odometer_applied_km'],
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        final appliedDistance = ride.isEmpty
            ? 0.0
            : (ride.first['odometer_applied_km'] as num).toDouble();
        final remainingDistance = (distanceKm - appliedDistance)
            .clamp(0.0, double.infinity)
            .toDouble();
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
                  (v.first['odometer_km'] as num).toDouble() +
                  remainingDistance,
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
  Future<List<Ride>> listRidesPage({
    required int limit,
    required int offset,
  }) async => (await (await db).query(
    'rides',
    orderBy: 'started_at DESC, id DESC',
    limit: limit,
    offset: offset,
  )).map(_ride).toList();
  Future<List<ServiceItem>> listServices() async => (await (await db).query(
    'service_items',
    orderBy: 'id',
  )).map(_service).toList();

  /// Mengembalikan id baris, supaya pemanggil yang baru membuat jadwal bisa
  /// langsung menuliskan log servis pertama untuk id itu.
  Future<int> saveService(ServiceItem s) async =>
      (await db).insert('service_items', {
        'id': s.id,
        'name': s.name,
        'description': s.description,
        'location': s.location,
        'cost': s.cost,
        'remind': s.remind ? 1 : 0,
        'interval_km': s.intervalKm,
        'last_serviced_km': s.lastServicedOdometerKm,
        'interval_months': s.intervalMonths,
        'last_serviced_at': s.lastServicedAt?.toIso8601String(),
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
        {
          'last_serviced_km': l.odometerKm,
          'last_serviced_at': l.servicedAt.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [l.serviceItemId],
      );
    });
  }

  Future<void> saveActiveRideCheckpoint(Ride r) async {
    final d = await db;
    if (r.id == null) return;
    await d.transaction((tx) async {
      final ride = await tx.query(
        'rides',
        columns: ['distance_km', 'odometer_applied_km'],
        where: 'id = ?',
        whereArgs: [r.id],
        limit: 1,
      );
      if (ride.isEmpty) return;
      final storedDistance = (ride.first['distance_km'] as num).toDouble();
      final appliedDistance = (ride.first['odometer_applied_km'] as num)
          .toDouble();
      final increment = (r.distanceKm - storedDistance)
          .clamp(0.0, double.infinity)
          .toDouble();
      await tx.update(
        'rides',
        {
          'distance_km': r.distanceKm,
          'odometer_applied_km': appliedDistance + increment,
        },
        where: 'id = ?',
        whereArgs: [r.id],
      );
      if (increment == 0) return;
      final vehicle = await tx.query('vehicle', limit: 1);
      if (vehicle.isEmpty) return;
      await tx.update(
        'vehicle',
        {
          'odometer_km':
              (vehicle.first['odometer_km'] as num).toDouble() + increment,
        },
        where: 'id = ?',
        whereArgs: [vehicle.first['id']],
      );
    });
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
  Future<List<ServiceLog>> listServiceLogsPage({
    required int limit,
    required int offset,
  }) async =>
      (await (await db).query(
            'service_logs',
            orderBy: 'serviced_at DESC, id DESC',
            limit: limit,
            offset: offset,
          ))
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
  Future<NotificationState> loadNotificationState(int serviceItemId) async {
    final rows = await (await db).query(
      'notification_state',
      where: 'service_item_id = ?',
      whereArgs: [serviceItemId],
      limit: 1,
    );
    if (rows.isEmpty) return const NotificationState();
    final reminder = rows.first['last_reminder'] as String?;
    return NotificationState(
      cycle: rows.first['cycle'] as int?,
      lastReminder: reminder == null
          ? null
          : ServiceReminder.values.byName(reminder),
    );
  }

  Future<void> saveNotificationState(
    int serviceItemId,
    NotificationState state,
  ) async {
    await (await db).insert('notification_state', {
      'service_item_id': serviceItemId,
      'cycle': state.cycle ?? 0,
      'last_reminder': state.lastReminder?.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearNotificationState(int serviceItemId) async {
    await (await db).delete(
      'notification_state',
      where: 'service_item_id = ?',
      whereArgs: [serviceItemId],
    );
  }

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
    notes: r['notes'] as String? ?? '',
    weather: r['weather'] as String? ?? '',
  );
  ServiceItem _service(Map<String, Object?> r) => ServiceItem(
    id: r['id'] as int,
    name: r['name'] as String,
    description: r['description'] as String? ?? '',
    location: r['location'] as String? ?? '',
    cost: (r['cost'] as num?)?.toDouble() ?? 0,
    intervalKm: (r['interval_km'] as num).toDouble(),
    lastServicedOdometerKm: (r['last_serviced_km'] as num).toDouble(),
    lastServicedAt: r['last_serviced_at'] == null
        ? null
        : DateTime.parse(r['last_serviced_at'] as String),
    intervalMonths: (r['interval_months'] as num?)?.toInt() ?? 0,
    remind: (r['remind'] as int? ?? 1) != 0,
  );
}
