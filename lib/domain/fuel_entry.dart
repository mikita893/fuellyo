/// Pojedyncze tankowanie.
class FuelEntry {
  const FuelEntry({
    required this.date,
    required this.odometerKm,
    required this.liters,
    this.isFullTank = true,
    this.pricePerLiter,
  })  : assert(liters > 0),
        assert(odometerKm >= 0);

  final DateTime date;
  final int odometerKm;
  final double liters;

  /// Czy zatankowano „do pełna”. Tylko odcinki pełny→pełny dają wiarygodne spalanie.
  final bool isFullTank;
  final double? pricePerLiter;

  double? get totalCost => pricePerLiter == null ? null : pricePerLiter! * liters;
}

/// Odczyt licznika (z tankowania, serwisu lub ręcznego wpisu).
class OdometerReading {
  const OdometerReading(this.date, this.km);

  final DateTime date;
  final int km;
}
