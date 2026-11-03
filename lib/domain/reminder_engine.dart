import 'date_utils.dart';
import 'maintenance_task.dart';

enum ReminderStatus { ok, dueSoon, overdue }

class MaintenanceReminder {
  const MaintenanceReminder({
    required this.task,
    required this.status,
    this.nextDueDate,
    this.nextDueKm,
    this.kmLeft,
    this.daysLeft,
    this.estimatedDueDate,
  });

  final MaintenanceTask task;
  final ReminderStatus status;
  final DateTime? nextDueDate;
  final int? nextDueKm;
  final int? kmLeft;
  final int? daysLeft;

  /// Najwcześniejsza z dat: termin kalendarzowy lub dzień, w którym
  /// (przy obecnym tempie jazdy) zostanie przekroczony limit km.
  final DateTime? estimatedDueDate;
}

/// Liczy, które czynności serwisowe są aktualne, zbliżają się lub są przeterminowane.
class ReminderEngine {
  const ReminderEngine({this.soonKm = 1000, this.soonDays = 30});

  final int soonKm;
  final int soonDays;

  MaintenanceReminder evaluate(
    MaintenanceTask task, {
    required DateTime now,
    required int currentOdometerKm,
    double? dailyKm,
  }) {
    final today = dateOnly(now);

    DateTime? dueDate;
    int? daysLeft;
    if (task.intervalMonths != null) {
      dueDate = addMonths(dateOnly(task.lastDoneDate), task.intervalMonths!);
      daysLeft = daysBetween(today, dueDate);
    }

    int? dueKm;
    int? kmLeft;
    DateTime? kmDueDate;
    if (task.intervalKm != null) {
      dueKm = task.lastDoneOdometerKm + task.intervalKm!;
      kmLeft = dueKm - currentOdometerKm;
      if (dailyKm != null && dailyKm > 0) {
        final d = kmLeft <= 0 ? 0 : (kmLeft / dailyKm).floor();
        kmDueDate = addDays(today, d);
      }
    }

    final overdue = (daysLeft != null && daysLeft < 0) || (kmLeft != null && kmLeft <= 0);
    final soon = (daysLeft != null && daysLeft <= soonDays) || (kmLeft != null && kmLeft <= soonKm);

    final candidates = [dueDate, kmDueDate].whereType<DateTime>().toList()..sort();

    return MaintenanceReminder(
      task: task,
      status: overdue
          ? ReminderStatus.overdue
          : soon
              ? ReminderStatus.dueSoon
              : ReminderStatus.ok,
      nextDueDate: dueDate,
      nextDueKm: dueKm,
      kmLeft: kmLeft,
      daysLeft: daysLeft,
      estimatedDueDate: candidates.isEmpty ? null : candidates.first,
    );
  }

  /// Ocena wielu zadań, posortowana od najpilniejszego.
  List<MaintenanceReminder> evaluateAll(
    List<MaintenanceTask> tasks, {
    required DateTime now,
    required int currentOdometerKm,
    double? dailyKm,
  }) {
    final result = tasks
        .map((t) => evaluate(t, now: now, currentOdometerKm: currentOdometerKm, dailyKm: dailyKm))
        .toList();
    result.sort((a, b) {
      final byStatus = b.status.index.compareTo(a.status.index);
      if (byStatus != 0) return byStatus;
      final ad = a.estimatedDueDate, bd = b.estimatedDueDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    return result;
  }
}
