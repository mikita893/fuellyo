# FuellYo! ⛽

Aplikacja mobilna dla właścicieli samochodów prywatnych i firmowych (małych flot), która:

1. **Przypomina o serwisie** – wymiana oleju, filtrów (oleju, powietrza, kabinowego, paliwa), płyn hamulcowy, przegląd techniczny, OC i własne zadania. Termin liczony jest **po kilometrach lub czasie – co nastąpi pierwsze**.
2. **Przewiduje, kiedy trzeba zatankować** – na podstawie historii tankowań (spalanie, średni dzienny przebieg, stan baku).

## 🔒 Prywatność: 100% offline

- Wszystkie dane są przechowywane **wyłącznie na urządzeniu**.
- Brak kont, backendu, analityki, reklam i telemetrii – twórca aplikacji nie zbiera żadnych danych.
- Aplikacja nie wymaga uprawnienia do Internetu (docelowo usuwamy je z manifestu Androida).
- Kopia zapasowa = ręczny eksport pliku, który użytkownik sam przechowuje.

Szczegóły: [docs/PRIVACY.md](docs/PRIVACY.md).

## Stack

| Warstwa | Technologia |
|---|---|
| Aplikacja | Flutter (Android + iOS) |
| Domena | czysty Dart (`lib/domain`) – zero zależności od Fluttera, w pełni testowalna |
| Dane lokalne | SQLite przez `drift` *(planowane – na razie repozytorium w pamięci)* |
| Powiadomienia | `flutter_local_notifications` – lokalne, planowane na urządzeniu *(planowane)* |

Architektura: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) · Plan prac: [docs/ROADMAP.md](docs/ROADMAP.md)

## Uruchomienie

Repo zawiera kod aplikacji bez wygenerowanych folderów platform. Za pierwszym razem:

```bash
flutter create . --org com.fuellyo --project-name fuellyo --platforms android,ios
flutter pub get
flutter test
flutter run
```

Przy pierwszym uruchomieniu możesz dodać własne auto albo wybrać **„Zobacz na przykładowych danych”**.

## Struktura

```
lib/
  domain/        # logika biznesowa: przypomnienia, prognoza tankowania, przebieg, statystyki
  data/          # repozytoria (lokalny magazyn)
  app/           # stan aplikacji (GarageStore)
  ui/            # ekrany, arkusze i widżety Fluttera
assets/fonts/    # czcionka Manrope (OFL) – wbudowana, bez pobierania z sieci
test/domain/     # testy jednostkowe logiki
test/widget/     # testy przepływów w UI
docs/            # architektura, prywatność, roadmapa
```
