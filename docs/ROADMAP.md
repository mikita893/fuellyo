# Roadmapa

## 0.1 – Fundament ✅
- [x] Szkielet Fluttera, CI (analyze + test)
- [x] Domena: pojazd, tankowanie, zadania serwisowe, szablony domyślne
- [x] Silnik przypomnień (km / czas / co pierwsze)
- [x] Prognoza tankowania z historii
- [x] Ekran główny na danych demo

## 0.2 – Interfejs ✅
- [x] Dolna nawigacja: Pulpit, Tankowania, Serwis, Garaż
- [x] Pulpit: wskaźnik paliwa i prognoza, szybkie akcje, „wymaga uwagi”, statystyki miesiąca
- [x] Formularz tankowania (do pełna / dolewka, cena, suma do zapłaty)
- [x] Szczegóły zadania: oznaczanie jako wykonane, zmiana interwału, usuwanie
- [x] Dodawanie zadań z szablonów i własnych
- [x] Garaż: wiele pojazdów, dodawanie / edycja / usuwanie, przełączanie auta
- [x] Ekran powitalny i tryb demo
- [x] Ręczna aktualizacja licznika
- [x] Własna czcionka (Manrope), jasny i ciemny motyw, polskie formaty dat i kwot

## 0.3 – Dane lokalne
- [ ] SQLite przez `drift` + migracje
- [ ] Implementacja `GarageRepository` na bazie
- [ ] Edycja istniejących tankowań

## 0.4 – Powiadomienia
- [ ] Lokalne powiadomienia (`flutter_local_notifications`)
- [ ] Przeliczanie w tle (WorkManager / BGTaskScheduler)
- [ ] Ustawienia: rezerwa baku, progi „wkrótce”

## 0.5 – Floty i statystyki
- [ ] Widok floty dla firm (wszystkie auta naraz)
- [ ] Statystyki kosztów i spalania
- [ ] Eksport / import kopii zapasowej (plik), eksport CSV dla księgowości

## 1.0 – Publikacja
- [ ] Ikona, branding, lokalizacja PL/EN
- [ ] Sklepy: Google Play, App Store
