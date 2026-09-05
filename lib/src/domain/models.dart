class GeoPoint {
  final double latitude, longitude, accuracyMeters;
  final DateTime? timestamp;
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    this.timestamp,
  });
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
  const Vehicle({this.id, required this.name, required this.odometerKm});
  Vehicle copyWith({int? id, String? name, double? odometerKm}) => Vehicle(
    id: id ?? this.id,
    name: name ?? this.name,
    odometerKm: odometerKm ?? this.odometerKm,
  );
}

class Ride {
  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceKm;
  const Ride({
    this.id,
    required this.startedAt,
    this.endedAt,
    this.distanceKm = 0,
  });
  Ride copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    double? distanceKm,
  }) => Ride(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    distanceKm: distanceKm ?? this.distanceKm,
  );
}

class ServiceItem {
  final int? id;
  final String name;
  final double intervalKm, lastServicedOdometerKm;
  const ServiceItem({
    this.id,
    required this.name,
    required this.intervalKm,
    required this.lastServicedOdometerKm,
  });
  ServiceItem copyWith({
    int? id,
    String? name,
    double? intervalKm,
    double? lastServicedOdometerKm,
  }) => ServiceItem(
    id: id ?? this.id,
    name: name ?? this.name,
    intervalKm: intervalKm ?? this.intervalKm,
    lastServicedOdometerKm:
        lastServicedOdometerKm ?? this.lastServicedOdometerKm,
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
