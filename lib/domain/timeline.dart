import 'date_utils.dart';
import 'refuel_predictor.dart';
import 'reminder_engine.dart';

enum UpcomingKind { refuel, task }

/// Jedno nadchodzące wydarzenie na osi czasu ekranu startowego.
class UpcomingEvent {
  const UpcomingEvent({required this.kind, required this.date, required this.title, this.reminder});

  final UpcomingKind kind;
  final DateTime date;
  final String title;
  final MaintenanceReminder? reminder;
}

/// Składa prognozę tankowania i przypomnienia w jedną oś czasu.
class Timeline {
  const Timeline._();

  /// Wydarzenia, które jeszcze nie są po terminie i wypadają w ciągu [horizonDays] dni,
  /// posortowane od najbliższego.
  static List<UpcomingEvent> upcoming({
    required DateTime now,
    RefuelPrediction? prediction,
    required List<MaintenanceReminder> reminders,
    int horizonDays = 180,
  }) {
    final today = dateOnly(now);
    final limit = addDays(today, horizonDays);
    final events = <UpcomingEvent>[
      if (prediction != null)
        UpcomingEvent(kind: UpcomingKind.refuel, date: prediction.predictedRefuelDate, title: 'Tankowanie'),
      for (final r in reminders)
        if (r.status != ReminderStatus.overdue && r.estimatedDueDate != null)
          UpcomingEvent(kind: UpcomingKind.task, date: r.estimatedDueDate!, title: r.task.name, reminder: r),
    ].where((e) => !e.date.isBefore(today) && !e.date.isAfter(limit)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  /// Rzeczy, które się „kończą”: po terminie albo z bliskim terminem / limitem km.
  static List<MaintenanceReminder> ending(List<MaintenanceReminder> reminders) =>
      reminders.where((r) => r.status != ReminderStatus.ok).toList();
}
