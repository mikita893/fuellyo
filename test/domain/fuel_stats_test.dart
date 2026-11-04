import 'package:flutter_test/flutter_test.dart';
import 'package:fuellyo/domain/domain.dart';

void main() {
  final a = FuelEntry(date: DateTime(2026, 10, 5), odometerKm: 1000, liters: 40, pricePerLiter: 6);
  final b = FuelEntry(date: DateTime(2026, 10, 20), odometerKm: 1500, liters: 30, pricePerLiter: 7);
  final c = FuelEntry(date: DateTime(2026, 11, 2), odometerKm: 2100, liters: 35);

  test('grupuje po miesiącach od najnowszego', () {
    final months = FuelStats.byMonth([a, c, b]);
    expect(months.length, 2);
    expect(months.first.month, 11);
    expect(months.last.entries, [b, a]);
    expect(months.last.liters, 70);
    expect(months.last.cost, closeTo(450, 1e-9));
    // tankowanie bez ceny nie zawyża kosztu
    expect(months.first.cost, 0);
  });

  test('podsumowanie wybranego miesiąca', () {
    final oct = FuelStats.forMonth([a, b, c], DateTime(2026, 10, 31));
    expect(oct.entries.length, 2);
    expect(FuelStats.forMonth([a, b, c], DateTime(2026, 9, 1)).entries, isEmpty);
  });

  test('dystans od poprzedniego tankowania', () {
    final d = FuelStats.distanceSincePrevious([c, a, b]);
    expect(d[a], isNull);
    expect(d[b], 500);
    expect(d[c], 600);
  });

  test('podsumowanie ostatnich dni', () {
    final sum = FuelStats.lastDays([a, b, c], DateTime(2026, 11, 3), 30);
    // okno 30 dni: od 5 paź do 3 lis włącznie
    expect(sum.count, 3);
    final week = FuelStats.lastDays([a, b, c], DateTime(2026, 11, 3), 7);
    expect(week.count, 1);
    expect(week.liters, 35);
    expect(week.cost, 0);
  });
}
