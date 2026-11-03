enum MaintenanceKind {
  oilChange,
  oilFilter,
  airFilter,
  cabinFilter,
  fuelFilter,
  brakeFluid,
  timingBelt,
  tires,
  inspection,
  insurance,
  custom,
}

/// Cykliczna czynność serwisowa: co [intervalKm] km i/lub co [intervalMonths] miesięcy
/// – w zależności od tego, co nastąpi pierwsze.
class MaintenanceTask {
  const MaintenanceTask({
    required this.id,
    required this.vehicleId,
    required this.kind,
    required this.name,
    required this.lastDoneDate,
    required this.lastDoneOdometerKm,
    this.intervalKm,
    this.intervalMonths,
  }) : assert(intervalKm != null || intervalMonths != null,
            'Zadanie musi mieć interwał km lub miesięcy');

  final String id;
  final String vehicleId;
  final MaintenanceKind kind;
  final String name;
  final int? intervalKm;
  final int? intervalMonths;
  final DateTime lastDoneDate;
  final int lastDoneOdometerKm;

  MaintenanceTask markDone({required DateTime date, required int odometerKm}) =>
      MaintenanceTask(
        id: id,
        vehicleId: vehicleId,
        kind: kind,
        name: name,
        intervalKm: intervalKm,
        intervalMonths: intervalMonths,
        lastDoneDate: date,
        lastDoneOdometerKm: odometerKm,
      );
}

/// Domyślne interwały – użytkownik może je zmienić per pojazd.
class MaintenanceTemplate {
  const MaintenanceTemplate(this.kind, this.name, {this.intervalKm, this.intervalMonths});

  final MaintenanceKind kind;
  final String name;
  final int? intervalKm;
  final int? intervalMonths;

  static const defaults = <MaintenanceTemplate>[
    MaintenanceTemplate(MaintenanceKind.oilChange, 'Wymiana oleju', intervalKm: 15000, intervalMonths: 12),
    MaintenanceTemplate(MaintenanceKind.oilFilter, 'Filtr oleju', intervalKm: 15000, intervalMonths: 12),
    MaintenanceTemplate(MaintenanceKind.airFilter, 'Filtr powietrza', intervalKm: 30000, intervalMonths: 24),
    MaintenanceTemplate(MaintenanceKind.cabinFilter, 'Filtr kabinowy', intervalKm: 15000, intervalMonths: 12),
    MaintenanceTemplate(MaintenanceKind.fuelFilter, 'Filtr paliwa', intervalKm: 30000, intervalMonths: 24),
    MaintenanceTemplate(MaintenanceKind.brakeFluid, 'Płyn hamulcowy', intervalMonths: 24),
    MaintenanceTemplate(MaintenanceKind.inspection, 'Przegląd techniczny', intervalMonths: 12),
    MaintenanceTemplate(MaintenanceKind.insurance, 'Ubezpieczenie OC', intervalMonths: 12),
  ];
}
