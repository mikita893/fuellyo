import 'package:flutter_test/flutter_test.dart';
import 'package:fuellyo/domain/domain.dart';

void main() {
  group('RepairStats', () {
    RepairEntry r(String id, DateTime d, {double? cost, String? place}) => RepairEntry(
          id: id,
          vehicleId: 'c',
          title: 'Naprawa $id',
          category: RepairCategory.repair,
          date: d,
          cost: cost,
          place: place,
        );

    final a = r('a', DateTime(2026, 3, 10), cost: 400, place: 'Auto-Serwis Kowalski');
    final b = r('b', DateTime(2026, 10, 2), cost: 1200, place: 'ASO Skoda');
    final c = r('c', DateTime(2026, 10, 20), place: 'Auto-Serwis Kowalski');

    test('grupuje po miesiącach od najnowszego', () {
      final months = RepairStats.byMonth([a, b, c]);
      expect(months.map((m) => m.month), [10, 3]);
      expect(months.first.entries, [c, b]);
      expect(months.first.cost, 1200);
    });

    test('koszt w okresie', () {
      expect(RepairStats.costBetween([a, b, c], DateTime(2026, 1, 1), DateTime(2026, 12, 31)), 1600);
      expect(RepairStats.costBetween([a, b, c], DateTime(2026, 6, 1), DateTime(2026, 12, 31)), 1200);
    });

    test('ostatnie miejsca bez powtórzeń', () {
      expect(RepairStats.recentPlaces([a, b, c]), ['Auto-Serwis Kowalski', 'ASO Skoda']);
    });
  });

  group('FuelStats', () {
    test('uzupełnia kwotę, litry albo cenę', () {
      expect(FuelStats.completeAmounts(liters: 40, price: 6.5)!.total, closeTo(260, 1e-9));
      expect(FuelStats.completeAmounts(total: 260, price: 6.5)!.liters, closeTo(40, 1e-9));
      expect(FuelStats.completeAmounts(total: 260, liters: 40)!.price, closeTo(6.5, 1e-9));
      expect(FuelStats.completeAmounts(liters: 40), isNull);
    });

    test('ostatnie stacje', () {
      final e1 = FuelEntry(date: DateTime(2026, 10, 1), odometerKm: 1, liters: 10, station: 'Orlen');
      final e2 = FuelEntry(date: DateTime(2026, 10, 5), odometerKm: 2, liters: 10, station: 'Shell');
      final e3 = FuelEntry(date: DateTime(2026, 10, 9), odometerKm: 3, liters: 10, station: 'Orlen');
      expect(FuelStats.recentStations([e1, e2, e3]), ['Orlen', 'Shell']);
    });
  });

  group('RefuelPredictor', () {
    test('pomija odcinek z brakującym tankowaniem', () {
      const car = Vehicle(id: 'c', name: 'T', fuelType: FuelType.petrol, tankCapacityLiters: 50);
      final entries = [
        FuelEntry(date: DateTime(2026, 10, 1), odometerKm: 10000, liters: 40),
        FuelEntry(date: DateTime(2026, 10, 11), odometerKm: 10500, liters: 30), // 6,0 l/100
        // brakujące tankowanie pomiędzy – 20 l na 1000 km zaniżyłoby spalanie
        FuelEntry(date: DateTime(2026, 10, 31), odometerKm: 11500, liters: 20, missedPrevious: true),
      ];
      final p = const RefuelPredictor().predict(vehicle: car, entries: entries, now: DateTime(2026, 10, 31))!;
      expect(p.consumptionLPer100Km, closeTo(6.0, 1e-9));
    });
  });

  group('Timeline', () {
    final now = DateTime(2026, 11, 4);
    MaintenanceReminder rem(String name, ReminderStatus s, DateTime? due) => MaintenanceReminder(
          task: MaintenanceTask(
            id: name,
            vehicleId: 'c',
            kind: MaintenanceKind.custom,
            name: name,
            intervalMonths: 12,
            lastDoneDate: DateTime(2026, 1, 1),
            lastDoneOdometerKm: 0,
          ),
          status: s,
          estimatedDueDate: due,
        );

    test('łączy tankowanie i zadania, pomija przeterminowane i odległe', () {
      final events = Timeline.upcoming(
        now: now,
        prediction: RefuelPrediction(
          consumptionLPer100Km: 6,
          dailyKm: 40,
          estimatedFuelLeftLiters: 20,
          estimatedRangeKm: 200,
          predictedRefuelDate: DateTime(2026, 11, 9),
          confidence: PredictionConfidence.high,
        ),
        reminders: [
          rem('OC', ReminderStatus.dueSoon, DateTime(2026, 11, 20)),
          rem('Olej', ReminderStatus.ok, DateTime(2026, 11, 6)),
          rem('Płyn', ReminderStatus.overdue, DateTime(2026, 10, 1)),
          rem('Rozrząd', ReminderStatus.ok, DateTime(2028, 1, 1)),
        ],
      );
      expect(events.map((e) => e.title), ['Olej', 'Tankowanie', 'OC']);
      expect(events[1].kind, UpcomingKind.refuel);
    });
  });
}
