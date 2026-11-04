import 'package:intl/intl.dart';

import '../domain/domain.dart';

/// Formatowanie dat, liczb i kwot po polsku.
class Fmt {
  const Fmt._();

  static final _number = NumberFormat.decimalPattern('pl');
  static final _money = NumberFormat.currency(locale: 'pl', symbol: 'zł', decimalDigits: 2);

  static String km(num value) => '${_number.format(value.round())} km';

  static String number(num value) => _number.format(value.round());

  static String liters(double value) => '${decimal(value)} l';

  static String decimal(double value, [int digits = 1]) =>
      value.toStringAsFixed(digits).replaceAll('.', ',');

  static String money(double value) => _money.format(value);

  /// „12 lis” w tym roku, „12 lis 2027” w innym.
  static String date(DateTime d, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    return d.year == ref.year
        ? DateFormat('d MMM', 'pl').format(d)
        : DateFormat('d MMM yyyy', 'pl').format(d);
  }

  static String shortDate(DateTime d) => DateFormat('d MMM yyyy', 'pl').format(d);

  static String fullDate(DateTime d) => DateFormat('d MMMM yyyy', 'pl').format(d);

  static String weekdayDate(DateTime d) => capitalize(DateFormat('EEEE, d MMMM', 'pl').format(d));

  static String month(int year, int month) => capitalize(DateFormat('LLLL yyyy', 'pl').format(DateTime(year, month)));

  /// „dziś”, „jutro”, „za 5 dni”, „3 dni temu”.
  static String relativeDays(int days) {
    if (days == 0) return 'dziś';
    if (days == 1) return 'jutro';
    if (days == -1) return 'wczoraj';
    if (days > 1) return 'za $days dni';
    return '${-days} dni temu';
  }

  static String relativeTo(DateTime date, DateTime now) => relativeDays(daysBetween(now, date));

  static String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Parsuje liczbę wpisaną z przecinkiem lub kropką.
  static double? parseDecimal(String text) =>
      double.tryParse(text.trim().replaceAll(' ', '').replaceAll(',', '.'));

  static String interval(MaintenanceTask t) {
    final parts = <String>[
      if (t.intervalKm != null) 'co ${km(t.intervalKm!)}',
      if (t.intervalMonths != null) 'co ${_months(t.intervalMonths!)}',
    ];
    return parts.join(' lub ');
  }

  static String _months(int m) {
    if (m % 12 == 0) {
      final y = m ~/ 12;
      return y == 1 ? 'rok' : '$y ${y < 5 ? 'lata' : 'lat'}';
    }
    if (m == 1) return 'miesiąc';
    final mod10 = m % 10, mod100 = m % 100;
    final few = mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14);
    return '$m ${few ? 'miesiące' : 'miesięcy'}';
  }
}
