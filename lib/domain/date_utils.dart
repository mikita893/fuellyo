/// Pomocnicze operacje na datach (bez godzin) używane w całej domenie.
library;

/// Zwraca datę bez części czasowej.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Dodaje [days] dni kalendarzowych (odporne na zmianę czasu letni/zimowy).
DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

/// Dodaje [months] miesięcy, przycinając dzień do ostatniego dnia miesiąca
/// (np. 31 stycznia + 1 miesiąc = 28/29 lutego, a nie 3 marca).
DateTime addMonths(DateTime d, int months) {
  final totalMonths = d.year * 12 + (d.month - 1) + months;
  final year = totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = d.day > lastDay ? lastDay : d.day;
  return DateTime(year, month, day);
}

/// Liczba pełnych dni między datami (b - a), liczona po datach kalendarzowych.
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;
