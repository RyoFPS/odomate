import 'models.dart';

class ServiceSchedule {
  static DateTime? dueDate(ServiceItem item) {
    final servicedAt = item.lastServicedAt;
    if (servicedAt == null || item.intervalMonths <= 0) return null;
    final month = servicedAt.month - 1 + item.intervalMonths;
    final year = servicedAt.year + month ~/ 12;
    final targetMonth = month % 12 + 1;
    final lastDay = DateTime(year, targetMonth + 1, 0).day;
    return DateTime(year, targetMonth, servicedAt.day.clamp(1, lastDay));
  }

  static ServiceStatus status(
    double odometerKm,
    ServiceItem item, {
    DateTime? now,
  }) {
    final remaining =
        item.lastServicedOdometerKm + item.intervalKm - odometerKm;
    final due = dueDate(item);
    final today = now == null
        ? DateTime.now()
        : DateTime(now.year, now.month, now.day);
    final daysRemaining = due?.difference(today).inDays;
    if (remaining <= 0 || (daysRemaining != null && daysRemaining <= 0)) {
      return ServiceStatus.due;
    }
    if (remaining <= 200 || (daysRemaining != null && daysRemaining <= 7)) {
      return ServiceStatus.dueSoon;
    }
    return ServiceStatus.safe;
  }

  static ServiceReminder? reminderType(
    double odometerKm,
    ServiceItem item,
    NotificationState state, {
    DateTime? now,
  }) {
    // Item yang tombol pengingatnya dimatikan di halaman Tambah Servis tidak
    // pernah menghasilkan reminder. Gerbang-nya sengaja ditaruh di sini, bukan
    // di pemanggil, supaya semua jalur pengiriman notifikasi ikut menghormatinya
    // tanpa perlu tahu soal kolom `remind`.
    if (!item.remind) return null;
    final status = ServiceSchedule.status(odometerKm, item, now: now);
    final reminder = status == ServiceStatus.due
        ? ServiceReminder.due
        : status == ServiceStatus.dueSoon
        ? ServiceReminder.dueSoon
        : null;
    return reminder == state.lastReminder ? null : reminder;
  }
}
