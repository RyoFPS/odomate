import 'models.dart';

class ServiceSchedule {
  static ServiceStatus status(double odometerKm, ServiceItem item) {
    final remaining =
        item.lastServicedOdometerKm + item.intervalKm - odometerKm;
    if (remaining <= 0) return ServiceStatus.due;
    if (remaining <= 200) return ServiceStatus.dueSoon;
    return ServiceStatus.safe;
  }

  static ServiceReminder? reminderType(
    double odometerKm,
    ServiceItem item,
    NotificationState state,
  ) {
    final status = ServiceSchedule.status(odometerKm, item);
    final reminder = status == ServiceStatus.due
        ? ServiceReminder.due
        : status == ServiceStatus.dueSoon
        ? ServiceReminder.dueSoon
        : null;
    return reminder == state.lastReminder ? null : reminder;
  }
}
