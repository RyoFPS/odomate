import 'models.dart';

enum StatisticsPeriod { today, lastSevenDays, currentMonth }

class RideStatistics {
  final double totalDistanceKm;
  final int rideCount;
  final double averageDistanceKm;
  final Duration totalDuration;

  const RideStatistics({
    required this.totalDistanceKm,
    required this.rideCount,
    required this.averageDistanceKm,
    required this.totalDuration,
  });
}

class DailyRideStatistics {
  final DateTime day;
  final double totalDistanceKm;
  final double chartDistanceKm;
  final int rideCount;
  final Duration totalDuration;

  const DailyRideStatistics({
    required this.day,
    required this.totalDistanceKm,
    required this.chartDistanceKm,
    required this.rideCount,
    required this.totalDuration,
  });
}

class MonthlyDistance {
  final DateTime month;
  final double distanceKm;

  const MonthlyDistance({required this.month, required this.distanceKm});
}

RideStatistics calculateRideStatistics(
  List<Ride> rides,
  DateTime now,
  StatisticsPeriod period,
) {
  final localNow = now.toLocal();
  final start = _periodStart(localNow, period);
  final included = rides.where((ride) {
    final startedAt = ride.startedAt.toLocal();
    return !startedAt.isBefore(start) && startedAt.isBefore(localNow);
  });
  final count = included.length;
  final total = included.fold<double>(
    0,
    (distance, ride) => distance + ride.distanceKm,
  );
  final duration = included.fold<Duration>(Duration.zero, (total, ride) {
    final endedAt = ride.endedAt;
    if (endedAt == null || endedAt.isBefore(ride.startedAt)) return total;
    return total + endedAt.difference(ride.startedAt);
  });
  return RideStatistics(
    totalDistanceKm: total,
    rideCount: count,
    averageDistanceKm: count == 0 ? 0 : total / count,
    totalDuration: duration,
  );
}

RideStatistics calculateRideStatisticsFromDaily(
  List<DailyRideStatistics> days,
  DateTime now,
  StatisticsPeriod period,
) {
  final localNow = now.toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final start = _periodStart(localNow, period);
  final included = days.where(
    (day) => !day.day.isBefore(start) && !day.day.isAfter(today),
  );
  final count = included.fold<int>(0, (sum, day) => sum + day.rideCount);
  final total = included.fold<double>(
    0,
    (sum, day) => sum + day.totalDistanceKm,
  );
  final duration = included.fold<Duration>(
    Duration.zero,
    (sum, day) => sum + day.totalDuration,
  );
  return RideStatistics(
    totalDistanceKm: total,
    rideCount: count,
    averageDistanceKm: count == 0 ? 0 : total / count,
    totalDuration: duration,
  );
}

List<MonthlyDistance> calculateMonthlyDistances(
  List<Ride> rides,
  DateTime now, {
  int monthCount = 6,
}) {
  final localNow = now.toLocal();
  final current = DateTime(localNow.year, localNow.month);
  return List.generate(monthCount, (index) {
    final month = DateTime(
      current.year,
      current.month - monthCount + 1 + index,
    );
    final distance = rides
        .where((ride) {
          final startedAt = ride.startedAt.toLocal();
          return startedAt.year == month.year &&
              startedAt.month == month.month &&
              !startedAt.isAfter(localNow);
        })
        .fold<double>(0, (sum, ride) => sum + ride.distanceKm);
    return MonthlyDistance(month: month, distanceKm: distance);
  });
}

List<MonthlyDistance> calculateMonthlyDistancesFromDaily(
  List<DailyRideStatistics> days,
  DateTime now, {
  int monthCount = 6,
}) {
  final localNow = now.toLocal();
  final current = DateTime(localNow.year, localNow.month);
  return List.generate(monthCount, (index) {
    final month = DateTime(
      current.year,
      current.month - monthCount + 1 + index,
    );
    final distance = days
        .where(
          (day) =>
              day.day.year == month.year &&
              day.day.month == month.month &&
              !day.day.isAfter(localNow),
        )
        .fold<double>(0, (sum, day) => sum + day.chartDistanceKm);
    return MonthlyDistance(month: month, distanceKm: distance);
  });
}

List<double> calculateDailyDistances(
  List<Ride> rides,
  DateTime now,
  StatisticsPeriod period,
) {
  final localNow = now.toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final days = switch (period) {
    StatisticsPeriod.today => 1,
    StatisticsPeriod.lastSevenDays => 7,
    StatisticsPeriod.currentMonth => DateTime(
      localNow.year,
      localNow.month + 1,
      0,
    ).day,
  };
  return List.generate(days, (index) {
    final day = switch (period) {
      StatisticsPeriod.today => today,
      StatisticsPeriod.lastSevenDays => today.subtract(
        Duration(days: days - index - 1),
      ),
      StatisticsPeriod.currentMonth => DateTime(
        localNow.year,
        localNow.month,
        index + 1,
      ),
    };
    return rides
        .where((ride) {
          final date = ride.startedAt.toLocal();
          return date.year == day.year &&
              date.month == day.month &&
              date.day == day.day &&
              !date.isAfter(localNow);
        })
        .fold<double>(0, (sum, ride) => sum + ride.distanceKm);
  });
}

List<double> calculateDailyDistancesFromDaily(
  List<DailyRideStatistics> days,
  DateTime now,
  StatisticsPeriod period,
) {
  final dailyDistances = {
    for (final summary in days)
      DateTime(summary.day.year, summary.day.month, summary.day.day):
          summary.chartDistanceKm,
  };
  final localNow = now.toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final count = switch (period) {
    StatisticsPeriod.today => 1,
    StatisticsPeriod.lastSevenDays => 7,
    StatisticsPeriod.currentMonth => DateTime(
      localNow.year,
      localNow.month + 1,
      0,
    ).day,
  };
  return List.generate(count, (index) {
    final day = switch (period) {
      StatisticsPeriod.today => today,
      StatisticsPeriod.lastSevenDays => today.subtract(
        Duration(days: count - index - 1),
      ),
      StatisticsPeriod.currentMonth => DateTime(
        localNow.year,
        localNow.month,
        index + 1,
      ),
    };
    return dailyDistances[day] ?? 0;
  });
}

DateTime _periodStart(DateTime localNow, StatisticsPeriod period) {
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  return switch (period) {
    StatisticsPeriod.today => today,
    StatisticsPeriod.lastSevenDays => today.subtract(const Duration(days: 6)),
    StatisticsPeriod.currentMonth => DateTime(localNow.year, localNow.month),
  };
}
