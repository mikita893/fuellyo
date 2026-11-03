# Architektura

## Zasady

- **Offline-first i offline-only.** Brak serwera. Jedynym źródłem prawdy jest lokalna baza na telefonie.
- **Domena niezależna od frameworka.** `lib/domain` to czysty Dart – nie importuje Fluttera, bazy ani pluginów. Dzięki temu logikę testujemy szybko i deterministycznie (zawsze przekazujemy `now`).
- **Warstwy:** `ui` → `data` (repozytoria) → `domain`. Domena nie zna warstw wyżej.

## Moduły domeny

| Plik | Odpowiedzialność |
|---|---|
| `vehicle.dart` | Pojazd: paliwo, pojemność baku, spalanie katalogowe, prywatny/firmowy |
| `fuel_entry.dart` | Tankowanie (data, licznik, litry, do pełna?, cena) i odczyt licznika |
| `maintenance_task.dart` | Zadanie serwisowe z interwałem km i/lub miesięcy + domyślne szablony |
| `mileage_estimator.dart` | Średni dzienny przebieg (okno 90 dni) i szacowany stan licznika |
| `reminder_engine.dart` | Status zadań: `ok` / `dueSoon` / `overdue`, szacowana data wymiany |
| `refuel_predictor.dart` | Prognoza tankowania |

## Przypomnienia serwisowe

Dla każdego zadania liczony jest termin kalendarzowy (`ostatnio + N miesięcy`) i kilometrowy (`ostatnio km + N km`). Status:

- `overdue` – minęła data **lub** przekroczono km,
- `dueSoon` – ≤ 30 dni **lub** ≤ 1000 km,
- `ok` – w pozostałych przypadkach.

Szacowana data wymiany = wcześniejsza z: daty kalendarzowej i dnia, w którym przy obecnym tempie jazdy zostanie osiągnięty limit km.

## Prognoza tankowania

1. **Spalanie** = Σ litrów / Σ km na odcinkach „do pełna → do pełna” (dolewki między nimi są wliczane). Brak historii → spalanie katalogowe.
2. **Stan baku po ostatnim wpisie** – od ostatniego „do pełna” (pełny bak) odejmujemy spalone paliwo i dodajemy dolewki.
3. **Stan dziś** – odejmujemy paliwo za szacowany przebieg od ostatniego tankowania.
4. **Data tankowania** – kiedy paliwo spadnie do rezerwy (domyślnie 15% baku).
5. **Pewność**: ≥ 5 odcinków → wysoka, ≥ 2 → średnia, mniej → niska.

## Powiadomienia (planowane)

Po każdej zmianie danych aplikacja przelicza przypomnienia i planuje **lokalne** powiadomienia systemowe (bez push z serwera). Dodatkowo okresowe przeliczenie w tle (WorkManager / BGTaskScheduler), bo przebieg „rośnie” szacunkowo z każdym dniem.
