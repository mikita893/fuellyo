import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/garage_repository.dart';
import '../domain/domain.dart';

class _VehicleOverview {
  _VehicleOverview(this.vehicle, this.odometerKm, this.prediction, this.reminders);

  final Vehicle vehicle;
  final int odometerKm;
  final RefuelPrediction? prediction;
  final List<MaintenanceReminder> reminders;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final GarageRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<List<_VehicleOverview>> _overview = _load();

  Future<List<_VehicleOverview>> _load() async {
    final now = DateTime.now();
    const mileage = MileageEstimator();
    const predictor = RefuelPredictor();
    const engine = ReminderEngine();

    final result = <_VehicleOverview>[];
    for (final v in await widget.repository.vehicles()) {
      final fuel = await widget.repository.fuelEntries(v.id);
      final tasks = await widget.repository.maintenanceTasks(v.id);
      final readings = fuel.map((e) => OdometerReading(e.date, e.odometerKm)).toList();
      final odo = mileage.estimateOdometer(readings, now);
      result.add(_VehicleOverview(
        v,
        odo,
        predictor.predict(vehicle: v, entries: fuel, now: now),
        engine.evaluateAll(tasks, now: now, currentOdometerKm: odo, dailyKm: mileage.averageDailyKm(readings)),
      ));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FuellYo!'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Tooltip(
              message: 'Wszystkie dane są tylko na tym urządzeniu',
              child: Icon(Icons.lock_outline),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<_VehicleOverview>>(
        future: _overview,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [for (final o in snap.data!) ..._vehicleSection(context, o)],
          );
        },
      ),
    );
  }

  List<Widget> _vehicleSection(BuildContext context, _VehicleOverview o) {
    final date = DateFormat('d MMM', 'pl');
    final text = Theme.of(context).textTheme;
    final p = o.prediction;
    return [
      Text(o.vehicle.name, style: text.headlineSmall),
      Text('${o.vehicle.plateNumber ?? ''}  •  ~${NumberFormat.decimalPattern('pl').format(o.odometerKm)} km'),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: const Icon(Icons.local_gas_station),
          title: Text(p == null
              ? 'Za mało danych do prognozy'
              : 'Zatankuj ok. ${date.format(p.predictedRefuelDate)}'),
          subtitle: p == null
              ? const Text('Dodaj co najmniej dwa tankowania do pełna.')
              : Text('Zasięg ~${p.estimatedRangeKm.round()} km  •  '
                  'spalanie ${p.consumptionLPer100Km.toStringAsFixed(1)} l/100 km'),
        ),
      ),
      const SizedBox(height: 8),
      for (final r in o.reminders)
        Card(
          child: ListTile(
            leading: Icon(_icon(r.status), color: _color(context, r.status)),
            title: Text(r.task.name),
            subtitle: Text([
              if (r.nextDueDate != null) 'do ${date.format(r.nextDueDate!)}',
              if (r.kmLeft != null) r.kmLeft! <= 0 ? 'przekroczono o ${-r.kmLeft!} km' : 'za ${r.kmLeft} km',
            ].join('  •  ')),
          ),
        ),
      const SizedBox(height: 24),
    ];
  }

  IconData _icon(ReminderStatus s) => switch (s) {
        ReminderStatus.ok => Icons.check_circle_outline,
        ReminderStatus.dueSoon => Icons.schedule,
        ReminderStatus.overdue => Icons.warning_amber,
      };

  Color _color(BuildContext context, ReminderStatus s) => switch (s) {
        ReminderStatus.ok => Colors.green,
        ReminderStatus.dueSoon => Colors.orange,
        ReminderStatus.overdue => Theme.of(context).colorScheme.error,
      };
}
