/// Pojedyncze tankowanie.
class FuelEntry {
  const FuelEntry({
    required this.date,
    required this.odometerKm,
    required this.liters,
    this.isFullTank = true,
    this.missedPrevious = false,
    this.pricePerLiter,
    this.station,
    this.note,
  })  : assert(liters > 0),
        assert(odometerKm >= 0);

  final DateTime date;
  final int odometerKm;
  final double liters;

  /// Czy zatankowano „do pełna”. Tylko odcinki pełny→pełny dają wiarygodne spalanie.
  final bool isFullTank;

  /// Użytkownik pominął wpisanie poprzedniego tankowania – odcinek kończący się
  /// tym wpisem nie nadaje się do liczenia spalania.
  final bool missedPrevious;
  final double? pricePerLiter;

  /// Gdzie tankowano (np. „Orlen, Puławska”).
  final String? station;
  final String? note;

  double? get totalCost => pricePerLiter == null ? null : pricePerLiter! * liters;
}

/// Odczyt licznika (z tankowania, serwisu lub ręcznego wpisu).
class OdometerReading {
  const OdometerReading(this.date, this.km);

  final DateTime date;
  final int km;
}
