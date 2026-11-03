enum FuelType { petrol, diesel, lpg, hybrid, electric }

/// Pojazd prywatny lub firmowy. Wszystkie dane żyją wyłącznie na urządzeniu.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.fuelType,
    required this.tankCapacityLiters,
    this.plateNumber,
    this.declaredConsumptionLPer100Km,
    this.isCompanyCar = false,
  }) : assert(tankCapacityLiters > 0);

  final String id;
  final String name;
  final String? plateNumber;
  final FuelType fuelType;
  final double tankCapacityLiters;

  /// Spalanie katalogowe – używane, dopóki nie ma wystarczającej historii tankowań.
  final double? declaredConsumptionLPer100Km;

  final bool isCompanyCar;
}
