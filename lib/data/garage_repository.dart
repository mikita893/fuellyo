import '../domain/domain.dart';

/// Kontrakt lokalnego magazynu danych. Docelowo implementacja na SQLite (drift),
/// dane nigdy nie opuszczają urządzenia – brak backendu i telemetrii.
abstract interface class GarageRepository {
  Future<List<Vehicle>> vehicles();
  Future<List<FuelEntry>> fuelEntries(String vehicleId);
  Future<List<MaintenanceTask>> maintenanceTasks(String vehicleId);

  Future<void> saveVehicle(Vehicle vehicle);
  Future<void> addFuelEntry(String vehicleId, FuelEntry entry);
  Future<void> saveMaintenanceTask(MaintenanceTask task);
}

/// Implementacja w pamięci – na start i do testów.
class InMemoryGarageRepository implements GarageRepository {
  final _vehicles = <String, Vehicle>{};
  final _fuel = <String, List<FuelEntry>>{};
  final _tasks = <String, MaintenanceTask>{};

  @override
  Future<List<Vehicle>> vehicles() async => _vehicles.values.toList();

  @override
  Future<List<FuelEntry>> fuelEntries(String vehicleId) async =>
      List.unmodifiable(_fuel[vehicleId] ?? const []);

  @override
  Future<List<MaintenanceTask>> maintenanceTasks(String vehicleId) async =>
      _tasks.values.where((t) => t.vehicleId == vehicleId).toList();

  @override
  Future<void> saveVehicle(Vehicle vehicle) async => _vehicles[vehicle.id] = vehicle;

  @override
  Future<void> addFuelEntry(String vehicleId, FuelEntry entry) async =>
      (_fuel[vehicleId] ??= []).add(entry);

  @override
  Future<void> saveMaintenanceTask(MaintenanceTask task) async => _tasks[task.id] = task;

  /// Przykładowe dane do podglądu UI.
  static Future<InMemoryGarageRepository> withDemoData(DateTime now) async {
    final repo = InMemoryGarageRepository();
    const car = Vehicle(
      id: 'demo-1',
      name: 'Skoda Octavia',
      plateNumber: 'WX 12345',
      fuelType: FuelType.diesel,
      tankCapacityLiters: 50,
      declaredConsumptionLPer100Km: 5.5,
    );
    await repo.saveVehicle(car);

    // ~40 km dziennie, tankowanie do pełna co ~2 tygodnie.
    var odo = 118000;
    for (var i = 6; i >= 1; i--) {
      final date = addDays(now, -(i * 14 + 3));
      await repo.addFuelEntry(car.id, FuelEntry(date: date, odometerKm: odo, liters: 31.5, pricePerLiter: 6.29));
      odo += 560;
    }

    for (final t in MaintenanceTemplate.defaults) {
      await repo.saveMaintenanceTask(MaintenanceTask(
        id: '${car.id}-${t.kind.name}',
        vehicleId: car.id,
        kind: t.kind,
        name: t.name,
        intervalKm: t.intervalKm,
        intervalMonths: t.intervalMonths,
        lastDoneDate: addMonths(now, -11),
        lastDoneOdometerKm: 104500,
      ));
    }
    return repo;
  }
}
