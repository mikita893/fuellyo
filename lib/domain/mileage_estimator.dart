import 'date_utils.dart';
import 'fuel_entry.dart';

/// Szacuje średni dzienny przebieg i bieżący stan licznika na podstawie historii odczytów.
class MileageEstimator {
  const MileageEstimator({this.windowDays = 90});

  /// Okno (w dniach przed ostatnim odczytem), z którego liczymy średnią –
  /// żeby świeże nawyki ważyły więcej niż dane sprzed roku.
  final int windowDays;

  /// Średni dzienny przebieg w km albo `null`, gdy danych jest za mało.
  double? averageDailyKm(List<OdometerReading> readings) {
    if (readings.length < 2) return null;
    final sorted = [...readings]..sort((a, b) => a.date.compareTo(b.date));
    final last = sorted.last;
    final windowStart = addDays(last.date, -windowDays);

    var inWindow = sorted.where((r) => !r.date.isBefore(windowStart)).toList();
    if (inWindow.length < 2 || daysBetween(inWindow.first.date, last.date) < 1) {
      inWindow = sorted;
    }

    final first = inWindow.first;
    final days = daysBetween(first.date, last.date);
    if (days < 1) return null;
    final km = last.km - first.km;
    if (km < 0) return null;
    return km / days;
  }

  /// Szacowany stan licznika w dniu [at].
  int estimateOdometer(List<OdometerReading> readings, DateTime at) {
    if (readings.isEmpty) return 0;
    final sorted = [...readings]..sort((a, b) => a.date.compareTo(b.date));
    final last = sorted.last;
    final daily = averageDailyKm(sorted) ?? 0;
    final days = daysBetween(last.date, at);
    if (days <= 0) return last.km;
    return last.km + (daily * days).round();
  }
}
