import 'fuel_entry.dart';

/// Podsumowanie tankowań w jednym miesiącu kalendarzowym.
class MonthlyFuelSummary {
  const MonthlyFuelSummary({required this.year, required this.month, required this.entries});

  final int year;
  final int month;

  /// Tankowania w tym miesiącu, od najnowszego.
  final List<FuelEntry> entries;

  double get liters => entries.fold(0.0, (sum, e) => sum + e.liters);

  /// Suma kosztów tankowań z podaną ceną.
  double get cost => entries.fold(0.0, (sum, e) => sum + (e.totalCost ?? 0));

  DateTime get firstDay => DateTime(year, month);
}

class FuelStats {
  const FuelStats._();

  /// Grupuje tankowania po miesiącach – najnowszy miesiąc pierwszy.
  static List<MonthlyFuelSummary> byMonth(List<FuelEntry> entries) {
    final sorted = [...entries]..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.odometerKm.compareTo(a.odometerKm);
      });
    final result = <MonthlyFuelSummary>[];
    for (final e in sorted) {
      final last = result.isEmpty ? null : result.last;
      if (last != null && last.year == e.date.year && last.month == e.date.month) {
        last.entries.add(e);
      } else {
        result.add(MonthlyFuelSummary(year: e.date.year, month: e.date.month, entries: [e]));
      }
    }
    return result;
  }

  /// Podsumowanie miesiąca, w którym wypada [day] (pusty, jeśli brak tankowań).
  static MonthlyFuelSummary forMonth(List<FuelEntry> entries, DateTime day) =>
      MonthlyFuelSummary(
        year: day.year,
        month: day.month,
        entries: entries.where((e) => e.date.year == day.year && e.date.month == day.month).toList(),
      );

  /// Kilometry przejechane od poprzedniego tankowania (wg licznika) dla każdego wpisu.
  /// Pierwszy wpis w historii nie ma wartości.
  static Map<FuelEntry, int> distanceSincePrevious(List<FuelEntry> entries) {
    final sorted = [...entries]..sort((a, b) => a.odometerKm.compareTo(b.odometerKm));
    final result = Map<FuelEntry, int>.identity();
    for (var i = 1; i < sorted.length; i++) {
      result[sorted[i]] = sorted[i].odometerKm - sorted[i - 1].odometerKm;
    }
    return result;
  }
}
