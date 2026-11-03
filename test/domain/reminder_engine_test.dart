import 'package:flutter_test/flutter_test.dart';
import 'package:fuellyo/domain/domain.dart';

void main() {
  final now = DateTime(2026, 11, 3);
  const engine = ReminderEngine();

  final oil = MaintenanceTask(
    id: 'oil',
    vehicleId: 'c',
    kind: MaintenanceKind.oilChange,
    name: 'Wymiana oleju',
    intervalKm: 15000,
    intervalMonths: 12,
    lastDoneDate: DateTime(2026, 1, 15),
    lastDoneOdometerKm: 100000,
  );

  final brakeFluid = MaintenanceTask(
    id: 'brake',
    vehicleId: 'c',
    kind: MaintenanceKind.brakeFluid,
    name: 'Płyn hamulcowy',
    intervalMonths: 24,
    lastDoneDate: DateTime(2024, 10, 1),
    lastDoneOdometerKm: 80000,
  );

  test('ok, gdy daleko do terminu', () {
    final r = engine.evaluate(oil, now: now, currentOdometerKm: 105000);
    expect(r.status, ReminderStatus.ok);
    expect(r.nextDueDate, DateTime(2027, 1, 15));
    expect(r.daysLeft, 73);
    expect(r.kmLeft, 10000);
  });

  test('wkrótce, gdy zostało mniej niż 1000 km', () {
    final r = engine.evaluate(oil, now: now, currentOdometerKm: 114500);
    expect(r.status, ReminderStatus.dueSoon);
  });

  test('przeterminowane po przekroczeniu km', () {
    final r = engine.evaluate(oil, now: now, currentOdometerKm: 115000);
    expect(r.status, ReminderStatus.overdue);
  });

  test('przeterminowane po dacie (zadanie tylko czasowe)', () {
    final r = engine.evaluate(brakeFluid, now: now, currentOdometerKm: 120000);
    expect(r.status, ReminderStatus.overdue);
    expect(r.nextDueDate, DateTime(2026, 10, 1));
  });

  test('szacowana data uwzględnia tempo jazdy', () {
    // 10 000 km przy 200 km/dzień = 50 dni → wcześniej niż termin kalendarzowy
    final r = engine.evaluate(oil, now: now, currentOdometerKm: 105000, dailyKm: 200);
    expect(r.estimatedDueDate, DateTime(2026, 12, 23));
    final slow = engine.evaluate(oil, now: now, currentOdometerKm: 105000, dailyKm: 50);
    expect(slow.estimatedDueDate, DateTime(2027, 1, 15));
  });

  test('evaluateAll sortuje od najpilniejszego', () {
    final list = engine.evaluateAll([oil, brakeFluid], now: now, currentOdometerKm: 105000);
    expect(list.first.task.id, 'brake');
  });

  test('addMonths przycina dzień do końca miesiąca', () {
    expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    expect(addMonths(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
    expect(addMonths(DateTime(2026, 11, 15), -11), DateTime(2025, 12, 15));
  });
}
