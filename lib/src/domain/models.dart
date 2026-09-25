class GeoPoint {
  final double latitude, longitude, accuracyMeters;
  final DateTime? timestamp;
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      latitude == other.latitude &&
      longitude == other.longitude &&
      accuracyMeters == other.accuracyMeters &&
      timestamp == other.timestamp;

  @override
  int get hashCode =>
      Object.hash(latitude, longitude, accuracyMeters, timestamp);
}

class DistanceResult {
  final bool accepted;
  final double meters;
  const DistanceResult(this.accepted, this.meters);
}

class Vehicle {
  final int? id;
  final String name;
  final double odometerKm;
  final String userName, plateNumber;
  final String? photoPath;
  const Vehicle({
    this.id,
    required this.name,
    required this.odometerKm,
    this.userName = '',
    this.plateNumber = '',
    this.photoPath,
  });
  Vehicle copyWith({
    int? id,
    String? name,
    double? odometerKm,
    String? userName,
    String? plateNumber,
    String? photoPath,
  }) => Vehicle(
    id: id ?? this.id,
    name: name ?? this.name,
    odometerKm: odometerKm ?? this.odometerKm,
    userName: userName ?? this.userName,
    plateNumber: plateNumber ?? this.plateNumber,
    photoPath: photoPath ?? this.photoPath,
  );
}

class Ride {
  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceKm;
  final String notes, weather;
  const Ride({
    this.id,
    required this.startedAt,
    this.endedAt,
    this.distanceKm = 0,
    this.notes = '',
    this.weather = '',
  });
  Ride copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    double? distanceKm,
    String? notes,
    String? weather,
  }) => Ride(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    distanceKm: distanceKm ?? this.distanceKm,
    notes: notes ?? this.notes,
    weather: weather ?? this.weather,
  );
}

class ServiceItem {
  final int? id;
  final String name, description;

  /// Bengkel / tempat servis dikerjakan. Diakses dari halaman Tambah Servis.
  final String location;

  /// Total biaya dalam rupiah. `0` berarti belum diisi (kolomnya opsional).
  final double cost;
  final double intervalKm, lastServicedOdometerKm;
  final DateTime? lastServicedAt;
  final int intervalMonths;

  /// Kalau `false`, pengingat untuk item ini tidak pernah dikirim — dipakai
  /// tombol "Pengingat Jadwal Servis" di halaman Tambah Servis.
  final bool remind;
  const ServiceItem({
    this.id,
    required this.name,
    this.description = '',
    this.location = '',
    this.cost = 0,
    required this.intervalKm,
    required this.lastServicedOdometerKm,
    this.lastServicedAt,
    this.intervalMonths = 0,
    this.remind = true,
  });
  ServiceItem copyWith({
    int? id,
    String? name,
    String? description,
    String? location,
    double? cost,
    double? intervalKm,
    double? lastServicedOdometerKm,
    DateTime? lastServicedAt,
    int? intervalMonths,
    bool? remind,
  }) => ServiceItem(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    location: location ?? this.location,
    cost: cost ?? this.cost,
    intervalKm: intervalKm ?? this.intervalKm,
    lastServicedOdometerKm:
        lastServicedOdometerKm ?? this.lastServicedOdometerKm,
    lastServicedAt: lastServicedAt ?? this.lastServicedAt,
    intervalMonths: intervalMonths ?? this.intervalMonths,
    remind: remind ?? this.remind,
  );
}

class ServiceLog {
  final int? id, serviceItemId;
  final DateTime servicedAt;
  final double odometerKm;
  final String? note;
  const ServiceLog({
    this.id,
    required this.serviceItemId,
    required this.servicedAt,
    required this.odometerKm,
    this.note,
  });
}

enum ServiceStatus { safe, dueSoon, due }

enum ServiceReminder { dueSoon, due }

class NotificationState {
  final int? cycle;
  final ServiceReminder? lastReminder;
  const NotificationState({this.cycle, this.lastReminder});
}
