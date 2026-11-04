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
    expect(find.text('PALIWO'), findsOneWidget);
    expect(find.text('Kończy się'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Nadchodzi'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Nadchodzi'), findsOneWidget);
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
    for (final tab in ['Tankowania', 'Naprawy', 'Przeglądy', 'O aplikacji', 'Start']) {
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

    // Cena jest podpowiedziana z ostatniego tankowania (6,29) – wpisujemy kwotę, litry liczą się same.
    await tester.enterText(find.widgetWithText(TextFormField, 'Kwota'), '251,60');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '40,00'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Stacja (opcjonalnie)'), 'Orlen, Puławska');
    await tapVisible(tester, find.text('Zapisz tankowanie'));

    final saved = store.current!.fuelEntries.first;
    expect(store.current!.fuelEntries.length, before + 1);
    expect(saved.liters, closeTo(40, 1e-9));
    expect(saved.station, 'Orlen, Puławska');
  });

  testWidgets('oznaczenie zadania jako wykonane', (tester) async {
    final store = await pumpApp(tester, demo: true);
    final urgent = store.current!.attention.first;

    final repairsBefore = store.current!.repairs.length;

    await tester.tap(navItem('Przeglądy'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(urgent.task.name).first);
    await tapVisible(tester, find.text('Oznacz jako wykonane'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Koszt (opcjonalnie)'), '300');
    await tapVisible(tester, find.text('Zapisz wykonanie'));

    final after = store.current!.reminders.firstWhere((r) => r.task.id == urgent.task.id);
    expect(after.status, ReminderStatus.ok);
    expect(store.current!.repairs.length, repairsBefore + 1);
    expect(store.current!.repairs.first.cost, 300);
  });

  testWidgets('dodanie naprawy: co, gdzie, za ile', (tester) async {
    final store = await pumpApp(tester, demo: true);
    final before = store.current!.repairs.length;

    await tester.tap(navItem('Naprawy'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Naprawa'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Co zrobiono'), 'Wymiana żarówki H7');
    await tester.enterText(find.widgetWithText(TextFormField, 'Gdzie (warsztat)'), 'Auto-Serwis Kowalski');
    await tester.enterText(find.widgetWithText(TextFormField, 'Koszt'), '45');
    await tapVisible(tester, find.text('Zapisz naprawę'));

    final saved = store.current!.repairs.first;
    expect(store.current!.repairs.length, before + 1);
    expect(saved.title, 'Wymiana żarówki H7');
    expect(saved.place, 'Auto-Serwis Kowalski');
    expect(saved.cost, 45);
    expect(find.text('Wymiana żarówki H7'), findsOneWidget);
  });
}
