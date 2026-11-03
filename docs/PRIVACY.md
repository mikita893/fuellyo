# Prywatność

FuellYo! jest projektowana tak, by twórca aplikacji **nie miał technicznej możliwości** zbierania danych użytkowników.

- Brak kont użytkowników i logowania.
- Brak backendu, API i synchronizacji w chmurze.
- Brak SDK analitycznych, crash-reporterów wysyłających dane, reklam i trackerów.
- Dane (pojazdy, tankowania, serwisy, przebiegi) trzymane są w lokalnej bazie SQLite w prywatnym katalogu aplikacji.
- Powiadomienia są planowane lokalnie przez system operacyjny.
- Eksport/import kopii zapasowej to plik, który użytkownik świadomie zapisuje lub udostępnia.

## Zasady dla kontrybutorów

1. Nie dodawaj zależności, które łączą się z siecią (Firebase, Sentry, analytics itp.).
2. Nowa zależność = sprawdzenie, czy nie wysyła danych w tle.
3. Android: docelowo brak uprawnienia `INTERNET` w manifeście release.
