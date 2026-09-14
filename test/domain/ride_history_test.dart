import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/domain/ride_history.dart';

void main() {
  final now = DateTime(2026, 9, 10, 12);

  test('filters by local today, seven days, and current month boundaries', () {
    final rides = [
      Ride(startedAt: DateTime(2026, 9, 10), distanceKm: 0),
      Ride(startedAt: DateTime(2026, 9, 4)),
      Ride(startedAt: DateTime(2026, 9, 3)),
      Ride(startedAt: DateTime(2026, 8, 31)),
    ];

    expect(filterRides(rides, now, RideHistoryPeriod.today).length, 1);
    expect(filterRides(rides, now, RideHistoryPeriod.lastSevenDays).length, 2);
    expect(filterRides(rides, now, RideHistoryPeriod.currentMonth).length, 3);
    expect(filterRides(rides, now, RideHistoryPeriod.all), rides);
  });

  test('filters using the local date of UTC timestamps', () {
    final ride = Ride(startedAt: DateTime.utc(2026, 9, 9, 17));

    expect(filterRides([ride], now, RideHistoryPeriod.today), [ride]);
  });

  test('formats completed duration and active ride status', () {
    expect(
      formatRideDuration(
        Ride(
          startedAt: DateTime(2026, 9, 10, 10),
          endedAt: DateTime(2026, 9, 10, 11, 5),
        ),
      ),
      '1h 05m',
    );
    expect(
      formatRideDuration(Ride(startedAt: DateTime(2026, 9, 10, 11, 30))),
      'Active',
    );
  });

  test('falls back safely for an invalid completed timestamp', () {
    expect(
      formatRideDuration(
        Ride(
          startedAt: DateTime(2026, 9, 10, 11),
          endedAt: DateTime(2026, 9, 10, 10),
        ),
      ),
      'Active',
    );
  });

  test('puts the previous window one period back, cut to the same span', () {
    // Rentang yang sudah berjalan dipakai sebagai panjang pembanding, jadi
    // pukul 12.00 pembanding "hari ini" berhenti di kemarin pukul 12.00.
    expect(previousRideHistoryWindow(now, RideHistoryPeriod.today), (
      start: DateTime(2026, 9, 9),
      end: DateTime(2026, 9, 9, 12),
    ));
    expect(previousRideHistoryWindow(now, RideHistoryPeriod.lastSevenDays), (
      start: DateTime(2026, 8, 28),
      end: DateTime(2026, 9, 3, 12),
    ));
    expect(previousRideHistoryWindow(now, RideHistoryPeriod.currentMonth), (
      start: DateTime(2026, 8, 1),
      end: DateTime(2026, 8, 10, 12),
    ));
    expect(previousRideHistoryWindow(now, RideHistoryPeriod.all), isNull);
  });

  test('leaves out the part of the previous period with no equivalent', () {
    final rides = [
      Ride(startedAt: DateTime(2026, 9, 9, 6), distanceKm: 10),
      // Kemarin sore belum ada padanannya kalau sekarang baru pukul 12.00.
      Ride(startedAt: DateTime(2026, 9, 9, 18), distanceKm: 99),
    ];

    expect(previousPeriodDistance(rides, now, RideHistoryPeriod.today), 10);
  });

  test('compares seven days against the seven days before them', () {
    final rides = [
      Ride(startedAt: DateTime(2026, 9, 3, 6), distanceKm: 5),
      // Di luar pembanding, yang berhenti 3 September pukul 12.00.
      Ride(startedAt: DateTime(2026, 9, 3, 18), distanceKm: 50),
      // Masuk rentang sekarang, bukan pembanding.
      Ride(startedAt: DateTime(2026, 9, 5), distanceKm: 100),
    ];

    expect(
      previousPeriodDistance(rides, now, RideHistoryPeriod.lastSevenDays),
      5,
    );
  });

  test('compares this month against the same stretch of last month', () {
    final rides = [
      Ride(startedAt: DateTime(2026, 8, 5), distanceKm: 20),
      Ride(startedAt: DateTime(2026, 8, 20), distanceKm: 99),
    ];

    expect(
      previousPeriodDistance(rides, now, RideHistoryPeriod.currentMonth),
      20,
    );
  });

  test('has nothing to compare the unbounded period against', () {
    expect(
      previousPeriodDistance(const [], now, RideHistoryPeriod.all),
      isNull,
    );
  });

  test('leaves the change undefined when the previous period was empty', () {
    expect(distanceChangePercent(110, 100), 10);
    expect(distanceChangePercent(80, 100), -20);
    expect(distanceChangePercent(50, 0), isNull);
  });
}
