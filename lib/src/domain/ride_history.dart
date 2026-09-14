import 'models.dart';

enum RideHistoryPeriod { all, today, lastSevenDays, currentMonth }

/// Rentang [start, end) sebuah periode, atau null untuk [RideHistoryPeriod.all]
/// yang memang tidak punya batas.
({DateTime start, DateTime end})? rideHistoryWindow(
  DateTime now,
  RideHistoryPeriod period,
) {
  if (period == RideHistoryPeriod.all) return null;

  final localNow = now.toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  return switch (period) {
    RideHistoryPeriod.today => (
      start: today,
      end: today.add(const Duration(days: 1)),
    ),
    RideHistoryPeriod.lastSevenDays => (
      start: today.subtract(const Duration(days: 6)),
      end: today.add(const Duration(days: 1)),
    ),
    RideHistoryPeriod.currentMonth => (
      start: DateTime(localNow.year, localNow.month),
      end: DateTime(localNow.year, localNow.month + 1),
    ),
    RideHistoryPeriod.all => throw StateError('all has no window'),
  };
}

/// Rentang pembanding di periode sebelumnya.
///
/// Panjangnya mengikuti rentang sekarang *yang sudah berjalan*, bukan panjang
/// periode penuh. Tanpa pemotongan itu "Hari ini" pukul 09.00 selalu
/// dibandingkan dengan "kemarin seharian", jadi angkanya terlihat turun jauh
/// padahal yang dihitung baru sembilan jam — dan hal yang sama terjadi pada
/// "Bulan ini" di awal bulan.
///
/// [RideHistoryPeriod.all] tidak punya pembanding, jadi hasilnya null.
({DateTime start, DateTime end})? previousRideHistoryWindow(
  DateTime now,
  RideHistoryPeriod period,
) {
  final window = rideHistoryWindow(now, period);
  if (window == null) return null;

  final localNow = now.toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final previousStart = switch (period) {
    RideHistoryPeriod.today => today.subtract(const Duration(days: 1)),
    // Rentang sekarang mulai H-6, jadi pembandingnya mulai H-13.
    RideHistoryPeriod.lastSevenDays => today.subtract(const Duration(days: 13)),
    RideHistoryPeriod.currentMonth => DateTime(
      localNow.year,
      localNow.month - 1,
    ),
    RideHistoryPeriod.all => throw StateError('all has no previous window'),
  };

  return (
    start: previousStart,
    end: previousStart.add(localNow.difference(window.start)),
  );
}

List<Ride> filterRides(
  List<Ride> rides,
  DateTime now,
  RideHistoryPeriod period,
) {
  final window = rideHistoryWindow(now, period);
  if (window == null) return rides;

  return rides
      .where((ride) => _startsWithin(ride, window.start, window.end))
      .toList();
}

/// Jarak total periode sebelumnya yang sebanding, atau null kalau tidak ada
/// pembanding yang bisa dipakai.
double? previousPeriodDistance(
  List<Ride> rides,
  DateTime now,
  RideHistoryPeriod period,
) {
  final window = previousRideHistoryWindow(now, period);
  if (window == null) return null;
  return _distanceBetween(rides, window.start, window.end);
}

/// Persentase perubahan jarak, atau null kalau periode sebelumnya nol km —
/// "naik tak hingga" tidak lebih berguna daripada tidak menampilkan apa pun.
double? distanceChangePercent(double current, double previous) =>
    previous == 0 ? null : (current - previous) / previous * 100;

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

bool _startsWithin(Ride ride, DateTime start, DateTime end) {
  final startedAt = ride.startedAt.toLocal();
  return !startedAt.isBefore(start) && startedAt.isBefore(end);
}

double _distanceBetween(List<Ride> rides, DateTime start, DateTime end) => rides
    .where((ride) => _startsWithin(ride, start, end))
    .fold<double>(0, (total, ride) => total + ride.distanceKm);
