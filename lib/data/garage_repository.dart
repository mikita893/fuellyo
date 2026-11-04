import '../domain/domain.dart';

/// Kontrakt lokalnego magazynu danych. Docelowo implementacja na SQLite (drift),
/// dane nigdy nie opuszczają urządzenia – brak backendu i telemetrii.
abstract interface class GarageRepository {
  Future<List<Vehicle>> vehicles();
  Future<List<FuelEntry>> fuelEntries(String vehicleId);
  Future<List<MaintenanceTask>> maintenanceTasks(String vehicleId);
  Future<List<OdometerReading>> odometerReadings(String vehicleId);
  Future<List<RepairEntry>> repairs(String vehicleId);

  Future<void> saveVehicle(Vehicle vehicle);
  Future<void> deleteVehicle(String vehicleId);
  Future<void> addFuelEntry(String vehicleId, FuelEntry entry);
  Future<void> deleteFuelEntry(String vehicleId, FuelEntry entry);
  Future<void> saveMaintenanceTask(MaintenanceTask task);
  Future<void> deleteMaintenanceTask(String taskId);
  Future<void> addOdometerReading(String vehicleId, OdometerReading reading);
  Future<void> saveRepair(RepairEntry repair);
  Future<void> deleteRepair(String repairId);
}

/// Implementacja w pamięci – na start i do testów.
class InMemoryGarageRepository implements GarageRepository {
  final _vehicles = <String, Vehicle>{};
  final _fuel = <String, List<FuelEntry>>{};
  final _tasks = <String, MaintenanceTask>{};
  final _readings = <String, List<OdometerReading>>{};
  final _repairs = <String, RepairEntry>{};

  @override
  Future<List<Vehicle>> vehicles() async => _vehicles.values.toList();

  @override
  Future<List<FuelEntry>> fuelEntries(String vehicleId) async =>
      List.unmodifiable(_fuel[vehicleId] ?? const <FuelEntry>[]);

  @override
  Future<List<MaintenanceTask>> maintenanceTasks(String vehicleId) async =>
      _tasks.values.where((t) => t.vehicleId == vehicleId).toList();

  @override
  Future<List<OdometerReading>> odometerReadings(String vehicleId) async =>
      List.unmodifiable(_readings[vehicleId] ?? const <OdometerReading>[]);

  @override
  Future<void> saveVehicle(Vehicle vehicle) async => _vehicles[vehicle.id] = vehicle;

  @override
  Future<void> deleteVehicle(String vehicleId) async {
    _vehicles.remove(vehicleId);
    _fuel.remove(vehicleId);
    _readings.remove(vehicleId);
    _tasks.removeWhere((_, t) => t.vehicleId == vehicleId);
    _repairs.removeWhere((_, r) => r.vehicleId == vehicleId);
  }

  @override
  Future<List<RepairEntry>> repairs(String vehicleId) async =>
      _repairs.values.where((r) => r.vehicleId == vehicleId).toList();

  @override
  Future<void> saveRepair(RepairEntry repair) async => _repairs[repair.id] = repair;

  @override
  Future<void> deleteRepair(String repairId) async => _repairs.remove(repairId);

  @override
  Future<void> addFuelEntry(String vehicleId, FuelEntry entry) async =>
      (_fuel[vehicleId] ??= []).add(entry);

  @override
  Future<void> deleteFuelEntry(String vehicleId, FuelEntry entry) async =>
      _fuel[vehicleId]?.removeWhere((e) => identical(e, entry));

  @override
  Future<void> saveMaintenanceTask(MaintenanceTask task) async => _tasks[task.id] = task;

  @override
  Future<void> deleteMaintenanceTask(String taskId) async => _tasks.remove(taskId);

  @override
  Future<void> addOdometerReading(String vehicleId, OdometerReading reading) async =>
      (_readings[vehicleId] ??= []).add(reading);
}

/// Wypełnia repozytorium przykładowymi danymi (tryb demo).
Future<void> seedDemoData(GarageRepository repo, DateTime now) async {
  const car = Vehicle(
    id: 'demo-octavia',
    name: 'Skoda Octavia',
    plateNumber: 'WX 12345',
    fuelType: FuelType.diesel,
    tankCapacityLiters: 50,
    declaredConsumptionLPer100Km: 5.5,
  );
  const van = Vehicle(
    id: 'demo-transit',
    name: 'Ford Transit',
    plateNumber: 'WZ 9876K',
    fuelType: FuelType.diesel,
    tankCapacityLiters: 80,
    declaredConsumptionLPer100Km: 9.0,
    isCompanyCar: true,
  );
  await repo.saveVehicle(car);
  await repo.saveVehicle(van);

  // Octavia: ~40 km dziennie, tankowanie do pełna co 2 tygodnie.
  const prices = [6.19, 6.25, 6.09, 6.29, 6.35, 6.29];
  const stations = ['Orlen, Puławska 112', 'Shell, Al. Krakowska', 'Orlen, Puławska 112', 'BP, Wołoska', 'Circle K, Marynarska', 'Orlen, Puławska 112'];
  var odo = 118000;
  for (var i = 6; i >= 1; i--) {
    await repo.addFuelEntry(
      car.id,
      FuelEntry(
        date: addDays(now, -(i * 14 + 3)),
        odometerKm: odo,
        liters: 30.8 + (i % 3) * 0.9,
        pricePerLiter: prices[6 - i],
        station: stations[6 - i],
      ),
    );
    odo += 560;
  }

  // Transit: ~120 km dziennie.
  var vanOdo = 64000;
  for (var i = 5; i >= 1; i--) {
    await repo.addFuelEntry(
      van.id,
      FuelEntry(
        date: addDays(now, -(i * 5 + 1)),
        odometerKm: vanOdo,
        liters: 55,
        pricePerLiter: 6.29,
        station: 'Orlen, S8 Janki',
      ),
    );
    vanOdo += 600;
  }

  final repairs = [
    RepairEntry(
      id: 'demo-r1',
      vehicleId: car.id,
      title: 'Wymiana klocków hamulcowych (przód)',
      category: RepairCategory.repair,
      date: addDays(now, -24),
      odometerKm: 120400,
      place: 'Auto-Serwis Kowalski',
      cost: 480,
      note: 'Tarcze do wymiany przy następnej okazji',
    ),
    RepairEntry(
      id: 'demo-r2',
      vehicleId: car.id,
      title: 'Wymiana opon na zimowe',
      category: RepairCategory.tires,
      date: addDays(now, -9),
      odometerKm: 121100,
      place: 'Vulco Mokotów',
      cost: 160,
    ),
    RepairEntry(
      id: 'demo-r3',
      vehicleId: car.id,
      title: 'Wymiana akumulatora',
      category: RepairCategory.parts,
      date: addMonths(now, -5),
      odometerKm: 114200,
      place: 'Auto-Serwis Kowalski',
      cost: 590,
    ),
    RepairEntry(
      id: 'demo-r4',
      vehicleId: car.id,
      title: 'Wymiana oleju i filtra oleju',
      category: RepairCategory.service,
      date: addDays(addMonths(now, -10), -10),
      odometerKm: 107000,
      place: 'ASO Skoda Mokotów',
      cost: 650,
      taskId: '${car.id}-${MaintenanceKind.oilChange.name}',
    ),
    RepairEntry(
      id: 'demo-r5',
      vehicleId: van.id,
      title: 'Naprawa sprzęgła',
      category: RepairCategory.repair,
      date: addDays(now, -40),
      odometerKm: 62500,
      place: 'Truck-Serwis Janki',
      cost: 2850,
    ),
  ];
  for (final r in repairs) {
    await repo.saveRepair(r);
  }

  // Różne stany zadań, żeby było widać statusy.
  final history = <MaintenanceKind, (int monthsAgo, int km)>{
    MaintenanceKind.oilChange: (10, 107000),
    MaintenanceKind.oilFilter: (10, 107000),
    MaintenanceKind.airFilter: (14, 98000),
    MaintenanceKind.cabinFilter: (13, 104000),
    MaintenanceKind.fuelFilter: (14, 98000),
    MaintenanceKind.brakeFluid: (20, 92000),
    MaintenanceKind.inspection: (11, 105000),
    MaintenanceKind.insurance: (3, 114000),
  };
  for (final v in [car, van]) {
    for (final t in MaintenanceTemplate.defaults) {
      final (monthsAgo, km) = history[t.kind] ?? (6, 100000);
      await repo.saveMaintenanceTask(MaintenanceTask(
        id: '${v.id}-${t.kind.name}',
        vehicleId: v.id,
        kind: t.kind,
        name: t.name,
        intervalKm: t.intervalKm,
        intervalMonths: t.intervalMonths,
        lastDoneDate: addDays(addMonths(now, -monthsAgo), -10),
        lastDoneOdometerKm: v == car ? km : km - 50000,
      ));
    }
  }
}
