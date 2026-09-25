import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/domain/ride_statistics.dart';

void main() {
  final now = DateTime(2026, 9, 5, 12);

  test('today includes local midnight and excludes now', () {
    final result = calculateRideStatistics(
      [
        Ride(startedAt: DateTime(2026, 9, 5), distanceKm: 3),
        Ride(startedAt: DateTime(2026, 9, 5, 11, 59), distanceKm: 5),
        Ride(startedAt: DateTime(2026, 9, 4, 23, 59), distanceKm: 100),
        Ride(startedAt: now, distanceKm: 100),
      ],
      now,
      StatisticsPeriod.today,
    );

    expect(result.rideCount, 2);
    expect(result.totalDistanceKm, 8);
    expect(result.averageDistanceKm, 4);
  });

  test('last seven days includes six previous local dates and today', () {
    final result = calculateRideStatistics(
      [
        Ride(startedAt: DateTime(2026, 8, 30), distanceKm: 1),
        Ride(startedAt: DateTime(2026, 8, 29), distanceKm: 100),
        Ride(startedAt: DateTime(2026, 9, 5, 11), distanceKm: 2),
      ],
      now,
      StatisticsPeriod.lastSevenDays,
    );

    expect(result.rideCount, 2);
    expect(result.totalDistanceKm, 3);
  });

  test('current month includes first day and excludes next month', () {
    final result = calculateRideStatistics(
      [
        Ride(startedAt: DateTime(2026, 9, 1), distanceKm: 4),
        Ride(startedAt: DateTime(2026, 8, 31, 23, 59), distanceKm: 100),
        Ride(startedAt: DateTime(2026, 10, 1), distanceKm: 100),
      ],
      now,
      StatisticsPeriod.currentMonth,
    );

    expect(result.rideCount, 1);
    expect(result.totalDistanceKm, 4);
  });

  test('zero-distance rides count and empty averages stay safe', () {
    final zero = calculateRideStatistics(
      [Ride(startedAt: DateTime(2026, 9, 5), distanceKm: 0)],
      now,
      StatisticsPeriod.today,
    );
    final empty = calculateRideStatistics(
      const [],
      now,
      StatisticsPeriod.today,
    );

    expect(zero.rideCount, 1);
    expect(zero.totalDistanceKm, 0);
    expect(zero.averageDistanceKm, 0);
    expect(empty.averageDistanceKm, 0);
  });

  test('totals completed ride duration without counting active rides', () {
    final result = calculateRideStatistics(
      [
        Ride(
          startedAt: DateTime(2026, 9, 5, 8),
          endedAt: DateTime(2026, 9, 5, 9, 30),
          distanceKm: 10,
        ),
        Ride(startedAt: DateTime(2026, 9, 5, 10), distanceKm: 4),
      ],
      now,
      StatisticsPeriod.today,
    );

    expect(result.totalDuration, const Duration(minutes: 90));
  });

  test('groups the last six calendar months in chronological order', () {
    final result = calculateMonthlyDistances([
      Ride(startedAt: DateTime(2026, 4, 2), distanceKm: 10),
      Ride(startedAt: DateTime(2026, 9, 4), distanceKm: 25),
      Ride(startedAt: DateTime(2026, 3, 31), distanceKm: 99),
    ], now);

    expect(result.length, 6);
    expect(result.first.month, DateTime(2026, 4));
    expect(result.first.distanceKm, 10);
    expect(result.last.month, DateTime(2026, 9));
    expect(result.last.distanceKm, 25);
  });

  test('current month daily values contain every calendar day', () {
    final result = calculateDailyDistances(
      [
        Ride(startedAt: DateTime(2026, 9, 1), distanceKm: 4),
        Ride(startedAt: DateTime(2026, 9, 5), distanceKm: 6),
      ],
      DateTime(2026, 9, 5, 12),
      StatisticsPeriod.currentMonth,
    );

    expect(result, hasLength(30));
    expect(result[0], 4);
    expect(result[4], 6);
    expect(result[29], 0);
  });
}
