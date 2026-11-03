# Wytyczne dla Claude

Projekt prowadzony w trybie „vibe coding”: właściciel pisze prompty i robi review, Claude pisze kod.

- Język UI i dokumentacji: polski. Identyfikatory w kodzie: angielski.
- **Offline-only:** nie dodawaj żadnych zależności sieciowych, analityki ani backendu (patrz `docs/PRIVACY.md`).
- Logika biznesowa tylko w `lib/domain` – czysty Dart, bez importów Fluttera. Funkcje przyjmują `now` jako parametr.
- Każda zmiana w domenie = test w `test/domain`.
- Przed commitem: `flutter analyze` i `flutter test` muszą przechodzić.
- Po zakończeniu etapu zaktualizuj `docs/ROADMAP.md`.
- Małe, opisowe commity; większe zmiany przez PR.
