import 'models.dart';
import 'ride_statistics.dart';

enum RideHistoryPeriod { all, today, lastSevenDays, currentMonth }

List<Ride> filterRides(
  List<Ride> rides,
  DateTime now,
  RideHistoryPeriod period,
) {
  if (period == RideHistoryPeriod.all) return rides;

  final localNow = now.toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final statisticsPeriod = switch (period) {
    RideHistoryPeriod.today => StatisticsPeriod.today,
    RideHistoryPeriod.lastSevenDays => StatisticsPeriod.lastSevenDays,
    RideHistoryPeriod.currentMonth => StatisticsPeriod.currentMonth,
    RideHistoryPeriod.all => throw StateError('all has no boundary'),
  };
  final start = switch (statisticsPeriod) {
    StatisticsPeriod.today => today,
    StatisticsPeriod.lastSevenDays => today.subtract(const Duration(days: 6)),
    StatisticsPeriod.currentMonth => DateTime(localNow.year, localNow.month),
  };
  final end = period == RideHistoryPeriod.currentMonth
      ? DateTime(localNow.year, localNow.month + 1)
      : today.add(const Duration(days: 1));

  return rides.where((ride) {
    final startedAt = ride.startedAt.toLocal();
    return !startedAt.isBefore(start) && startedAt.isBefore(end);
  }).toList();
}

String formatRideDuration(
  Ride ride, {
  String hourSuffix = 'h',
  String minuteSuffix = 'm',
}) {
  final endedAt = ride.endedAt?.toLocal();
  final startedAt = ride.startedAt.toLocal();
  if (endedAt == null || endedAt.isBefore(startedAt)) return 'Active';

  final duration = endedAt.difference(startedAt);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '$minutes$minuteSuffix';
  return '$hours$hourSuffix ${minutes.toString().padLeft(2, '0')}$minuteSuffix';
}
