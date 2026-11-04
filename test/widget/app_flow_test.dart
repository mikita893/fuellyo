import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuellyo/app/garage_store.dart';
import 'package:fuellyo/data/garage_repository.dart';
import 'package:fuellyo/domain/domain.dart';
import 'package:fuellyo/main.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pl'));

  Future<GarageStore> pumpApp(WidgetTester tester, {bool demo = false}) async {
    tester.view.physicalSize = const Size(1170, 2532); // telefon ~390×844
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final store = GarageStore(InMemoryGarageRepository(), clock: () => DateTime(2026, 11, 4, 12));
    if (demo) {
      await store.loadDemo();
    } else {
      await store.load();
    }
    await tester.pumpWidget(FuellYoApp(store: store));
    await tester.pumpAndSettle();
    return store;
  }

  Finder navItem(String label) =>
      find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('ekran powitalny → dane demo → pulpit', (tester) async {
    await pumpApp(tester);
    expect(find.text('Witaj w FuellYo!'), findsOneWidget);

    await tapVisible(tester, find.text('Zobacz na przykładowych danych'));
    expect(find.text('NASTĘPNE TANKOWANIE'), findsOneWidget);
    expect(find.text('Wymaga uwagi'), findsOneWidget);
  });

  testWidgets('dodanie pierwszego auta z formularza', (tester) async {
    final store = await pumpApp(tester);
    await tapVisible(tester, find.text('Dodaj pierwsze auto'));

    await tester.enterText(find.widgetWithText(TextFormField, 'Nazwa'), 'Toyota Corolla');
    await tester.enterText(find.widgetWithText(TextFormField, 'Bak'), '50');
    await tester.enterText(find.widgetWithText(TextFormField, 'Aktualny przebieg'), '42000');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Dodaj pojazd'));

    expect(store.vehicles.single.name, 'Toyota Corolla');
    expect(store.current!.tasks, isNotEmpty);
    expect(find.text('Toyota Corolla'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('wszystkie zakładki renderują się bez błędów', (tester) async {
    await pumpApp(tester, demo: true);
    for (final tab in ['Tankowania', 'Serwis', 'Garaż', 'Pulpit']) {
      await tester.tap(navItem(tab));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('zapis tankowania z arkusza', (tester) async {
    final store = await pumpApp(tester, demo: true);
    final before = store.current!.fuelEntries.length;

    await tester.tap(navItem('Tankowania'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Tankowanie'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Zatankowano'), '38,5');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Zapisz tankowanie'));

    expect(store.current!.fuelEntries.length, before + 1);
    expect(store.current!.fuelEntries.first.liters, 38.5);
  });

  testWidgets('oznaczenie zadania jako wykonane', (tester) async {
    final store = await pumpApp(tester, demo: true);
    final urgent = store.current!.attention.first;

    await tester.tap(navItem('Serwis'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(urgent.task.name).first);
    await tapVisible(tester, find.text('Oznacz jako wykonane'));
    await tapVisible(tester, find.text('Zapisz wykonanie'));

    final after = store.current!.reminders.firstWhere((r) => r.task.id == urgent.task.id);
    expect(after.status, ReminderStatus.ok);
  });
}
