import 'date_utils.dart';

enum RepairCategory { repair, service, inspection, tires, parts, other }

/// Wpis w historii napraw i serwisów: co, kiedy, gdzie, za ile.
class RepairEntry {
  const RepairEntry({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.category,
    required this.date,
    this.odometerKm,
    this.place,
    this.cost,
    this.note,
    this.taskId,
  });

  final String id;
  final String vehicleId;

  /// Co zrobiono, np. „Wymiana klocków hamulcowych”.
  final String title;
  final RepairCategory category;
  final DateTime date;
  final int? odometerKm;

  /// Gdzie, np. nazwa warsztatu.
  final String? place;
  final double? cost;
  final String? note;

  /// Zadanie z planu serwisowego, którego dotyczy wpis (jeśli jakieś).
  final String? taskId;

  RepairEntry copyWith({
    String? title,
    RepairCategory? category,
    DateTime? date,
    int? odometerKm,
    String? place,
    double? cost,
    String? note,
    String? taskId,
  }) =>
      RepairEntry(
        id: id,
        vehicleId: vehicleId,
        title: title ?? this.title,
        category: category ?? this.category,
        date: date ?? this.date,
        odometerKm: odometerKm ?? this.odometerKm,
        place: place ?? this.place,
        cost: cost ?? this.cost,
        note: note ?? this.note,
        taskId: taskId ?? this.taskId,
      );
}

class RepairMonth {
  const RepairMonth({required this.year, required this.month, required this.entries});

  final int year;
  final int month;
  final List<RepairEntry> entries;

  double get cost => entries.fold(0.0, (s, e) => s + (e.cost ?? 0));
}

class RepairStats {
  const RepairStats._();

  /// Od najnowszego.
  static List<RepairEntry> sorted(List<RepairEntry> entries) =>
      [...entries]..sort((a, b) => b.date.compareTo(a.date));

  /// Grupuje po miesiącach – najnowszy pierwszy.
  static List<RepairMonth> byMonth(List<RepairEntry> entries) {
    final result = <RepairMonth>[];
    for (final e in sorted(entries)) {
      final last = result.isEmpty ? null : result.last;
      if (last != null && last.year == e.date.year && last.month == e.date.month) {
        last.entries.add(e);
      } else {
        result.add(RepairMonth(year: e.date.year, month: e.date.month, entries: [e]));
      }
    }
    return result;
  }

  /// Suma kosztów od [from] (włącznie) do [to] (włącznie).
  static double costBetween(List<RepairEntry> entries, DateTime from, DateTime to) => entries
      .where((e) => !dateOnly(e.date).isBefore(dateOnly(from)) && !dateOnly(e.date).isAfter(dateOnly(to)))
      .fold(0.0, (s, e) => s + (e.cost ?? 0));

  /// Ostatnie znane miejsca (bez powtórzeń), od najnowszego – do podpowiedzi w formularzu.
  static List<String> recentPlaces(List<RepairEntry> entries, {int limit = 5}) {
    final seen = <String>{};
    for (final e in sorted(entries)) {
      final p = e.place?.trim();
      if (p != null && p.isNotEmpty) seen.add(p);
      if (seen.length >= limit) break;
    }
    return seen.toList();
  }
}
