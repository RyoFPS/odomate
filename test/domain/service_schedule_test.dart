import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/domain/service_schedule.dart';

void main() {
  const item = ServiceItem(
    id: 1,
    name: 'Oli mesin',
    intervalKm: 1000,
    lastServicedOdometerKm: 0,
  );

  test('returns dueSoon at 200 km remaining', () {
    expect(ServiceSchedule.status(800, item), ServiceStatus.dueSoon);
    expect(
      ServiceSchedule.reminderType(800, item, const NotificationState()),
      ServiceReminder.dueSoon,
    );
  });

  test('returns due at zero remaining', () {
    expect(ServiceSchedule.status(1000, item), ServiceStatus.due);
    expect(
      ServiceSchedule.reminderType(1000, item, const NotificationState()),
      ServiceReminder.due,
    );
  });

  test('keeps service description for the detail view', () {
    const described = ServiceItem(
      name: 'Oli mesin',
      description: 'Ganti oli dan periksa kebocoran.',
      intervalKm: 1000,
      lastServicedOdometerKm: 0,
    );
    expect(described.description, contains('kebocoran'));
  });

  test('a muted item never produces a reminder', () {
    const muted = ServiceItem(
      name: 'Oli mesin',
      intervalKm: 1000,
      lastServicedOdometerKm: 0,
      remind: false,
    );

    // Statusnya tetap jatuh tempo — yang dimatikan hanya pengingatnya, supaya
    // kartu di halaman Servis masih bisa menandainya merah.
    expect(ServiceSchedule.status(1000, muted), ServiceStatus.due);
    expect(
      ServiceSchedule.reminderType(1000, muted, const NotificationState()),
      isNull,
    );
    expect(
      ServiceSchedule.reminderType(800, muted, const NotificationState()),
      isNull,
    );
  });

  test('date interval makes a service due when the date arrives', () {
    final item = ServiceItem(
      name: 'Oli mesin',
      intervalKm: 2000,
      lastServicedOdometerKm: 0,
      lastServicedAt: DateTime(2026, 8, 18),
      intervalMonths: 2,
    );

    expect(
      ServiceSchedule.status(1000, item, now: DateTime(2026, 10, 18)),
      ServiceStatus.due,
    );
  });

  test('date reminder is due soon within seven days', () {
    final item = ServiceItem(
      name: 'Oli mesin',
      intervalKm: 2000,
      lastServicedOdometerKm: 0,
      lastServicedAt: DateTime(2026, 8, 18),
      intervalMonths: 2,
    );

    expect(
      ServiceSchedule.status(1000, item, now: DateTime(2026, 10, 12)),
      ServiceStatus.dueSoon,
    );
  });

  test('the earlier kilometer or date threshold wins', () {
    final item = ServiceItem(
      name: 'Oli mesin',
      intervalKm: 2000,
      lastServicedOdometerKm: 0,
      lastServicedAt: DateTime(2026, 8, 18),
      intervalMonths: 2,
    );

    expect(
      ServiceSchedule.status(2000, item, now: DateTime(2026, 9, 1)),
      ServiceStatus.due,
    );
  });
}
