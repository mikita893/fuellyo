import 'package:flutter/widgets.dart';

import '../data/garage_repository.dart';
import '../domain/domain.dart';

/// Wszystko, co ekrany potrzebują wiedzieć o wybranym pojeździe – policzone raz.
class VehicleSnapshot {
  const VehicleSnapshot({
    required this.vehicle,
    required this.fuelEntries,
    required this.tasks,
    required this.repairs,
    required this.reminders,
    required this.prediction,
    required this.odometerKm,
    required this.dailyKm,
    required this.now,
  });

  final Vehicle vehicle;

  /// Od najnowszego.
  final List<FuelEntry> fuelEntries;
  final List<MaintenanceTask> tasks;

  /// Historia napraw, od najnowszej.
  final List<RepairEntry> repairs;

  /// Od najpilniejszego.
  final List<MaintenanceReminder> reminders;
  final RefuelPrediction? prediction;
  final int odometerKm;
  final double? dailyKm;
  final DateTime now;

  List<MaintenanceReminder> get attention => Timeline.ending(reminders);

  List<UpcomingEvent> get upcoming =>
      Timeline.upcoming(now: now, prediction: prediction, reminders: reminders);

  /// Koszty od początku roku: paliwo i naprawy.
  ({double fuel, double repairs}) get yearCosts {
    final from = DateTime(now.year);
    final fuel = fuelEntries
        .where((e) => !e.date.isBefore(from) && !e.date.isAfter(now))
        .fold(0.0, (s, e) => s + (e.totalCost ?? 0));
    return (fuel: fuel, repairs: RepairStats.costBetween(repairs, from, now));
  }

  List<RepairEntry> repairsForTask(String taskId) => repairs.where((r) => r.taskId == taskId).toList();

  /// Średnie spalanie z historii (bez spalania katalogowego), jeśli jest prognoza.
  double? get consumption => prediction?.consumptionLPer100Km;

  /// Szacowany poziom paliwa 0.0–1.0.
  double? get fuelLevel => prediction == null
      ? null
      : (prediction!.estimatedFuelLeftLiters / vehicle.tankCapacityLiters).clamp(0.0, 1.0);
}

/// Stan aplikacji. Czyta i zapisuje przez [GarageRepository], przelicza domenę.
class GarageStore extends ChangeNotifier {
  GarageStore(this._repo, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final GarageRepository _repo;
  final DateTime Function() _clock;

  static const _mileage = MileageEstimator();
  static const _predictor = RefuelPredictor();
  static const _engine = ReminderEngine();

  bool _loading = true;
  List<Vehicle> _vehicles = const [];
  String? _selectedId;
  VehicleSnapshot? _current;
  int _idCounter = 0;

  bool get isLoading => _loading;
  List<Vehicle> get vehicles => _vehicles;
  VehicleSnapshot? get current => _current;
  DateTime get now => _clock();

  Future<void> load() async {
    _vehicles = await _repo.vehicles();
    if (_selectedId == null || !_vehicles.any((v) => v.id == _selectedId)) {
      _selectedId = _vehicles.isEmpty ? null : _vehicles.first.id;
    }
    _current = _selectedId == null ? null : await _snapshot(_vehicles.firstWhere((v) => v.id == _selectedId));
    _loading = false;
    notifyListeners();
  }

  Future<VehicleSnapshot> _snapshot(Vehicle v) async {
    final now = _clock();
    final fuel = [...await _repo.fuelEntries(v.id)]..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.odometerKm.compareTo(a.odometerKm);
      });
    final tasks = await _repo.maintenanceTasks(v.id);
    final repairs = RepairStats.sorted(await _repo.repairs(v.id));
    final readings = [
      ...fuel.map((e) => OdometerReading(e.date, e.odometerKm)),
      ...await _repo.odometerReadings(v.id),
      for (final r in repairs)
        if (r.odometerKm != null) OdometerReading(r.date, r.odometerKm!),
    ];
    final odometer = _mileage.estimateOdometer(readings, now);
    final daily = _mileage.averageDailyKm(readings);
    return VehicleSnapshot(
      vehicle: v,
      fuelEntries: fuel,
      tasks: tasks,
      repairs: repairs,
      reminders: _engine.evaluateAll(tasks, now: now, currentOdometerKm: odometer, dailyKm: daily),
      prediction: _predictor.predict(vehicle: v, entries: fuel, now: now),
      odometerKm: odometer,
      dailyKm: daily,
      now: now,
    );
  }

  String newId() => '${_clock().microsecondsSinceEpoch}-${_idCounter++}';

  Future<void> selectVehicle(String id) async {
    _selectedId = id;
    await load();
  }

  Future<void> loadDemo() async {
    await seedDemoData(_repo, _clock());
    await load();
  }

  Future<Vehicle> addVehicle(Vehicle vehicle, {required int odometerKm, bool withDefaultPlan = true}) async {
    await _repo.saveVehicle(vehicle);
    final today = dateOnly(_clock());
    await _repo.addOdometerReading(vehicle.id, OdometerReading(today, odometerKm));
    if (withDefaultPlan) {
      for (final t in MaintenanceTemplate.defaults) {
        if (t.kind == MaintenanceKind.fuelFilter && vehicle.fuelType != FuelType.diesel) continue;
        await _repo.saveMaintenanceTask(MaintenanceTask(
          id: newId(),
          vehicleId: vehicle.id,
          kind: t.kind,
          name: t.name,
          intervalKm: t.intervalKm,
          intervalMonths: t.intervalMonths,
          lastDoneDate: today,
          lastDoneOdometerKm: odometerKm,
        ));
      }
    }
    _selectedId = vehicle.id;
    await load();
    return vehicle;
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _repo.saveVehicle(vehicle);
    await load();
  }

  Future<void> deleteVehicle(String id) async {
    await _repo.deleteVehicle(id);
    if (_selectedId == id) _selectedId = null;
    await load();
  }

  Future<void> addFuelEntry(FuelEntry entry) async {
    final id = _selectedId;
    if (id == null) return;
    await _repo.addFuelEntry(id, entry);
    await load();
  }

  Future<void> updateFuelEntry(FuelEntry old, FuelEntry updated) async {
    final id = _selectedId;
    if (id == null) return;
    await _repo.deleteFuelEntry(id, old);
    await _repo.addFuelEntry(id, updated);
    await load();
  }

  Future<void> deleteFuelEntry(FuelEntry entry) async {
    final id = _selectedId;
    if (id == null) return;
    await _repo.deleteFuelEntry(id, entry);
    await load();
  }

  Future<void> updateOdometer(int km, {DateTime? date}) async {
    final id = _selectedId;
    if (id == null) return;
    await _repo.addOdometerReading(id, OdometerReading(dateOnly(date ?? _clock()), km));
    await load();
  }

  Future<void> saveTask(MaintenanceTask task) async {
    await _repo.saveMaintenanceTask(task);
    await load();
  }

  /// Zapisuje wykonanie zadania z planu i dodaje wpis do historii napraw.
  Future<void> markTaskDone(
    MaintenanceTask task, {
    required DateTime date,
    required int odometerKm,
    String? place,
    double? cost,
    String? note,
  }) async {
    await _repo.saveMaintenanceTask(task.markDone(date: dateOnly(date), odometerKm: odometerKm));
    await _repo.saveRepair(RepairEntry(
      id: newId(),
      vehicleId: task.vehicleId,
      title: task.name,
      category: task.kind == MaintenanceKind.inspection || task.kind == MaintenanceKind.insurance
          ? RepairCategory.inspection
          : RepairCategory.service,
      date: dateOnly(date),
      odometerKm: odometerKm,
      place: place,
      cost: cost,
      note: note,
      taskId: task.id,
    ));
    await load();
  }

  /// Zapisuje naprawę. Jeśli jest powiązana z zadaniem z planu, przesuwa też jego termin.
  Future<void> saveRepair(RepairEntry repair) async {
    await _repo.saveRepair(repair);
    final taskId = repair.taskId;
    final odo = repair.odometerKm;
    if (taskId != null && odo != null) {
      final task = _current?.tasks.where((t) => t.id == taskId).firstOrNull;
      if (task != null && !repair.date.isBefore(task.lastDoneDate)) {
        await _repo.saveMaintenanceTask(task.markDone(date: dateOnly(repair.date), odometerKm: odo));
      }
    }
    await load();
  }

  Future<void> deleteRepair(RepairEntry repair) async {
    await _repo.deleteRepair(repair.id);
    await load();
  }

  Future<void> deleteTask(MaintenanceTask task) async {
    await _repo.deleteMaintenanceTask(task.id);
    await load();
  }
}

/// Udostępnia [GarageStore] w drzewie widżetów i przebudowuje zależne widżety po zmianach.
class GarageScope extends InheritedNotifier<GarageStore> {
  const GarageScope({super.key, required GarageStore store, required super.child})
      : super(notifier: store);

  static GarageStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GarageScope>()!.notifier!;

  static GarageStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<GarageScope>()!.notifier!;
}
