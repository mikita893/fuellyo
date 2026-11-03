import 'package:flutter_test/flutter_test.dart';
import 'package:fuellyo/domain/domain.dart';

void main() {
  const estimator = MileageEstimator(windowDays: 30);

  test('średni dzienny przebieg z ostatniego okna', () {
    final readings = [
      OdometerReading(DateTime(2026, 1, 1), 1000), // poza oknem
      OdometerReading(DateTime(2026, 10, 1), 50000),
      OdometerReading(DateTime(2026, 10, 21), 51000),
    ];
    expect(estimator.averageDailyKm(readings), closeTo(50, 1e-9));
  });

  test('null przy jednym odczycie', () {
    expect(estimator.averageDailyKm([OdometerReading(DateTime(2026, 1, 1), 1000)]), isNull);
  });

  test('szacuje licznik na dziś', () {
    final readings = [
      OdometerReading(DateTime(2026, 10, 1), 50000),
      OdometerReading(DateTime(2026, 10, 21), 51000),
    ];
    expect(estimator.estimateOdometer(readings, DateTime(2026, 10, 31)), 51500);
  });
}
