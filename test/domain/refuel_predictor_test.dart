import 'package:flutter_test/flutter_test.dart';
import 'package:fuellyo/domain/domain.dart';

void main() {
  const car = Vehicle(id: 'c', name: 'Test', fuelType: FuelType.petrol, tankCapacityLiters: 50);
  final day0 = DateTime(2026, 10, 1);
  DateTime day(int n) => addDays(day0, n);

  final history = [
    FuelEntry(date: day(0), odometerKm: 10000, liters: 40),
    FuelEntry(date: day(10), odometerKm: 10500, liters: 30),
    FuelEntry(date: day(20), odometerKm: 11000, liters: 30),
  ];

  const predictor = RefuelPredictor();

  test('liczy spalanie z odcinków do pełna i datę tankowania', () {
    final p = predictor.predict(vehicle: car, entries: history, now: day(20))!;
    expect(p.consumptionLPer100Km, closeTo(6.0, 1e-9));
    expect(p.dailyKm, closeTo(50, 1e-9));
    expect(p.estimatedFuelLeftLiters, closeTo(50, 1e-9));
    // (50 - 7.5 rezerwy) / 6 * 100 = 708 km → 14 dni przy 50 km/dzień
    expect(p.estimatedRangeKm, closeTo(708.33, 0.01));
    expect(p.predictedRefuelDate, day(34));
    expect(p.confidence, PredictionConfidence.medium);
  });

  test('uwzględnia przejechane km od ostatniego tankowania', () {
    final p = predictor.predict(vehicle: car, entries: history, now: day(25))!;
    expect(p.estimatedFuelLeftLiters, closeTo(35, 1e-9));
    expect(p.predictedRefuelDate, day(34));
  });

  test('uwzględnia dolewkę po ostatnim tankowaniu do pełna', () {
    final entries = [
      FuelEntry(date: day(0), odometerKm: 10000, liters: 40),
      FuelEntry(date: day(10), odometerKm: 10500, liters: 30),
      FuelEntry(date: day(16), odometerKm: 10800, liters: 10, isFullTank: false),
    ];
    final p = predictor.predict(vehicle: car, entries: entries, now: day(16))!;
    expect(p.consumptionLPer100Km, closeTo(6.0, 1e-9));
    // 50 - 300 km * 6/100 + 10 = 42 l
    expect(p.estimatedFuelLeftLiters, closeTo(42, 1e-9));
  });

  test('zwraca null, gdy jest za mało historii', () {
    final p = predictor.predict(
      vehicle: car,
      entries: [FuelEntry(date: day(0), odometerKm: 10000, liters: 40)],
      now: day(5),
    );
    expect(p, isNull);
  });
}
