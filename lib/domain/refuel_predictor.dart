import 'date_utils.dart';
import 'fuel_entry.dart';
import 'mileage_estimator.dart';
import 'vehicle.dart';

enum PredictionConfidence { low, medium, high }

class RefuelPrediction {
  const RefuelPrediction({
    required this.consumptionLPer100Km,
    required this.dailyKm,
    required this.estimatedFuelLeftLiters,
    required this.estimatedRangeKm,
    required this.predictedRefuelDate,
    required this.confidence,
  });

  final double consumptionLPer100Km;
  final double dailyKm;
  final double estimatedFuelLeftLiters;

  /// Zasięg do momentu osiągnięcia rezerwy.
  final double estimatedRangeKm;
  final DateTime predictedRefuelDate;
  final PredictionConfidence confidence;
}

/// Przewiduje, kiedy trzeba będzie zatankować – wyłącznie na podstawie lokalnej historii.
///
/// Algorytm:
/// 1. Spalanie = suma litrów / suma km na odcinkach „do pełna → do pełna”
///    (z pominięciem odcinków z brakującym tankowaniem).
/// 2. Stan baku po ostatnim tankowaniu „do pełna” odtwarzamy, uwzględniając
///    późniejsze dolewki.
/// 3. Od ostatniego tankowania do dziś odejmujemy paliwo za szacowany przebieg
///    (średni dzienny przebieg × liczba dni).
/// 4. Data tankowania = kiedy paliwo spadnie do poziomu rezerwy.
class RefuelPredictor {
  const RefuelPredictor({
    this.reserveFraction = 0.15,
    this.mileageEstimator = const MileageEstimator(),
  });

  /// Jaka część baku to „rezerwa”, przy której przypominamy o tankowaniu.
  final double reserveFraction;
  final MileageEstimator mileageEstimator;

  RefuelPrediction? predict({
    required Vehicle vehicle,
    required List<FuelEntry> entries,
    required DateTime now,
  }) {
    if (entries.isEmpty) return null;
    final sorted = [...entries]..sort((a, b) => a.odometerKm.compareTo(b.odometerKm));

    final (consumption, segments) = _averageConsumption(sorted);
    final cons = consumption ?? vehicle.declaredConsumptionLPer100Km;
    if (cons == null || cons <= 0) return null;

    final dailyKm = mileageEstimator.averageDailyKm(
      sorted.map((e) => OdometerReading(e.date, e.odometerKm)).toList(),
    );
    if (dailyKm == null || dailyKm <= 0) return null;

    final capacity = vehicle.tankCapacityLiters;
    final fuelAtLastEntry = _fuelAfterLastEntry(sorted, cons, capacity);
    if (fuelAtLastEntry == null) return null;

    final last = sorted.last;
    final daysSince = daysBetween(last.date, now).clamp(0, 1 << 30);
    final kmSince = dailyKm * daysSince;
    final fuelNow = (fuelAtLastEntry - cons * kmSince / 100).clamp(0.0, capacity);

    final reserve = capacity * reserveFraction;
    final usable = (fuelNow - reserve).clamp(0.0, capacity);
    final rangeKm = usable / cons * 100;
    final daysLeft = (rangeKm / dailyKm).floor();

    return RefuelPrediction(
      consumptionLPer100Km: cons,
      dailyKm: dailyKm,
      estimatedFuelLeftLiters: fuelNow,
      estimatedRangeKm: rangeKm,
      predictedRefuelDate: addDays(now, daysLeft),
      confidence: segments >= 5
          ? PredictionConfidence.high
          : segments >= 2
              ? PredictionConfidence.medium
              : PredictionConfidence.low,
    );
  }

  /// Zwraca (średnie spalanie l/100km, liczba odcinków pełny→pełny).
  (double?, int) _averageConsumption(List<FuelEntry> sorted) {
    var liters = 0.0;
    var km = 0;
    var segments = 0;
    int? prevFullIdx;
    for (var i = 0; i < sorted.length; i++) {
      if (!sorted[i].isFullTank) continue;
      if (prevFullIdx != null) {
        final distance = sorted[i].odometerKm - sorted[prevFullIdx].odometerKm;
        var gap = false;
        for (var j = prevFullIdx + 1; j <= i; j++) {
          if (sorted[j].missedPrevious) gap = true;
        }
        if (distance > 0 && !gap) {
          for (var j = prevFullIdx + 1; j <= i; j++) {
            liters += sorted[j].liters;
          }
          km += distance;
          segments++;
        }
      }
      prevFullIdx = i;
    }
    if (km == 0) return (null, 0);
    return (liters / km * 100, segments);
  }

  /// Ile paliwa było w baku zaraz po ostatnim wpisie.
  double? _fuelAfterLastEntry(List<FuelEntry> sorted, double cons, double capacity) {
    final lastFull = sorted.lastIndexWhere((e) => e.isFullTank);
    if (lastFull == -1) return null;
    var fuel = capacity;
    for (var i = lastFull + 1; i < sorted.length; i++) {
      final driven = sorted[i].odometerKm - sorted[i - 1].odometerKm;
      fuel = (fuel - cons * driven / 100).clamp(0.0, capacity);
      fuel = (fuel + sorted[i].liters).clamp(0.0, capacity);
    }
    return fuel;
  }
}
