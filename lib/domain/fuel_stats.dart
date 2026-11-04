import 'date_utils.dart';
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

  /// Podsumowanie ostatnich [days] dni (łącznie z dniem [now]).
  static ({int count, double liters, double cost}) lastDays(List<FuelEntry> entries, DateTime now, int days) {
    final from = addDays(now, -(days - 1));
    final inRange = entries.where((e) => !dateOnly(e.date).isBefore(from) && !dateOnly(e.date).isAfter(dateOnly(now)));
    return (
      count: inRange.length,
      liters: inRange.fold(0.0, (sum, e) => sum + e.liters),
      cost: inRange.fold(0.0, (sum, e) => sum + (e.totalCost ?? 0)),
    );
  }

  /// Ostatnie stacje (bez powtórzeń), od najnowszej – do podpowiedzi w formularzu.
  static List<String> recentStations(List<FuelEntry> entries, {int limit = 5}) {
    final sorted = [...entries]..sort((a, b) => b.date.compareTo(a.date));
    final seen = <String>{};
    for (final e in sorted) {
      final s = e.station?.trim();
      if (s != null && s.isNotEmpty) seen.add(s);
      if (seen.length >= limit) break;
    }
    return seen.toList();
  }

  /// Uzupełnia brakującą wartość z trójki litry / cena za litr / kwota.
  /// Gdy podane są co najmniej dwie, trzecia jest wyliczana. Zwraca `null`, gdy się nie da.
  static ({double liters, double price, double total})? completeAmounts({
    double? liters,
    double? price,
    double? total,
  }) {
    bool ok(double? v) => v != null && v > 0;
    if (ok(liters) && ok(price)) return (liters: liters!, price: price!, total: liters * price);
    if (ok(total) && ok(price)) return (liters: total! / price!, price: price, total: total);
    if (ok(total) && ok(liters)) return (liters: liters!, price: total! / liters, total: total);
    return null;
  }

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
