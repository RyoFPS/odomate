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
}
