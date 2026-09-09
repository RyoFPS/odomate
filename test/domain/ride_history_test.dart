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
}
