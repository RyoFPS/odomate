import 'models.dart';

enum StatisticsPeriod { today, lastSevenDays, currentMonth }

class RideStatistics {
  final double totalDistanceKm;
  final int rideCount;
  final double averageDistanceKm;

  const RideStatistics({
    required this.totalDistanceKm,
    required this.rideCount,
    required this.averageDistanceKm,
  });
}

RideStatistics calculateRideStatistics(
  List<Ride> rides,
  DateTime now,
  StatisticsPeriod period,
) {
  final localNow = now.toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final start = switch (period) {
    StatisticsPeriod.today => today,
    StatisticsPeriod.lastSevenDays => today.subtract(const Duration(days: 6)),
    StatisticsPeriod.currentMonth => DateTime(localNow.year, localNow.month),
  };
  final included = rides.where((ride) {
    final startedAt = ride.startedAt.toLocal();
    return !startedAt.isBefore(start) && startedAt.isBefore(localNow);
  });
  final count = included.length;
  final total = included.fold<double>(
    0,
    (distance, ride) => distance + ride.distanceKm,
  );
  return RideStatistics(
    totalDistanceKm: total,
    rideCount: count,
    averageDistanceKm: count == 0 ? 0 : total / count,
  );
}
