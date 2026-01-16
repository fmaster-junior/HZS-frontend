# Daily Logging System - Dokumentacija

## Pregled

Implementiran je sveobuhvatan sistem za praćenje dnevnih aktivnosti korisnika sa tri vrste logova:
- **Dnevni Log (Daily Log)** - Osnovni podatak o danu
- **Mentalni Log** - Praćenje mentalnog zdravlja (raspoloženje, skor, beleške)
- **Fizički Log** - Praćenje fizičke aktivnosti (nivo aktivnosti, koraci, treninzi)

## Nove Funkcionalnosti

### 1. Automatsko Podsetanje
- Pri pokretanju aplikacije, sistem proverava da li je korisnik uneo log za današnji dan
- Ako nije, prikazuje se dijalog koji korisnika poziva da unese dnevni log
- Korisnik može odabrati "Kasnije" ili "Da" za trenutni unos

### 2. Ekrani za Unos Logova

#### DailyLogScreen (`dailylogscreen.dart`)
- Glavni ekran za odabir vrste loga koji korisnik želi da unese
- Omogućava izbor datuma (podrazumevano današnji datum)
-Navigacija ka mentalnom ili fizičkom logu

#### MentalLogScreen (`mentallogscreen.dart`)
- **Raspoloženje (Mood)**: Slider od 1-10
- **Mentalni Skor**: Slider od 0-100
- **Beleška**: Tekstualno polje za dodatne komentare
- Podaci se čuvaju u `mental_logs` tabeli
- Automatski ažurira `daily_logs` tabelu sa `mental_mood`

#### PhysicalLogScreen (`physicallogscreen.dart`)
- **Nivo Aktivnosti**: Slider od 1-10
- **Broj Koraka**: Slider do 30,000 koraka
- **Trening**: Checkbox da li je korisnik trenirao
- Podaci se čuvaju u `physical_logs` tabeli
- Automatski ažurira `daily_logs` tabelu sa `physical_score`

#### LogDetailsScreen (`logdetailsscreen.dart`)
- Prikazuje sve logove za izabrani datum
- Organizovano po sekcijama (Mental, Fizički, Dnevni pregled)
- Prikazuje ikone i formatiranje za bolju čitljivost

### 3. Grafički Prikazi

#### Grafikoni na Home Ekranu
- Zamenjeni hardcode podaci sa pravim podacima iz baze
- **Fizički grafikon (Crna boja)**: Prikazuje nivo fizičke aktivnosti za poslednju nedelju
- **Mentalni grafikon (Siva boja)**: Prikazuje mentalni skor za poslednju nedelju
- Podaci se automatski učitavaju pri pokretanju ekrana

#### Kalendar
- Prikazuje datume na kojima korisnik ima unete logove
- Klikom na datum otvara se detaljan prikaz logova za taj dan
- Podaci se automatski osvežavaju nakon unosa novog loga

## Baza Podataka

### Struktura Tabela

#### daily_logs
```sql
- id: uuid (primary key)
- created_at: timestamp
- user_id: uuid (foreign key -> profiles)
- log_date: date
- mental_mood: integer (1-10)
- physical_score: integer (0-100)
```

#### mental_logs
```sql
- id: uuid (primary key)
- created_at: timestamp
- user_id: uuid (foreign key -> profiles)
- mood: integer (1-10)
- score: integer (0-100)
- note: text
- log_date: date
```

#### physical_logs
```sql
- id: uuid (primary key)
- created_at: timestamp
- user_id: uuid (foreign key -> profiles)
- activity_level: integer (1-10)
- steps: bigint
- workout_done: boolean
- log_date: date
```

## Implementirane Metode u DataRepository

### Logging Metode
- `hasDailyLogForDate(userId, date)` - Proverava da li postoji log za datum
- `upsertDailyLog(userId, logDate, {mentalMood, physicalScore})` - Kreira ili ažurira dnevni log
- `createMentalLog(userId, logDate, mood, score, note)` - Kreira mentalni log
- `createPhysicalLog(userId, logDate, activityLevel, steps, workoutDone)` - Kreira fizički log

### Metode za Grafike
- `fetchMentalLogsRange(userId, startDate, endDate)` - Preuzima mentalne logove za period
- `fetchPhysicalLogsRange(userId, startDate, endDate)` - Preuzima fizičke logove za period
- `fetchDatesWithLogs(userId)` - Vraća sve datume sa logovima za kalendar
- `fetchLogForDate(userId, date)` - Preuzima sve logove za određeni datum

## Ažurirani Cubiti

### AppCubit
- Dodat `weeklyMentalData` u state
- Nova metoda `loadWeeklyMentalData(userId)` - Učitava nedeljne podatke o mentalnom zdravlju

### FitnessCubit
- Dodat `datesWithLogs` u state
- Nova metoda `loadWeeklyPhysicalData(userId)` - Učitava nedeljne podatke o fizičkoj aktivnosti
- Nova metoda `loadDatesWithLogs(userId)` - Učitava datume sa logovima

## Korišćenje

### Pokretanje Aplikacije
1. Instalirati zavisnosti: `flutter pub get`
2. Pokrenuti aplikaciju: `flutter run`

### Unos Dnevnog Loga
1. Aplikacija automatski poziva korisnika da unese log ako nije uneo za današnji dan
2. Ili, korisnik može ručno navigirati do `DailyLogScreen`
3. Odabrati datum (podrazumevano je današnji)
4. Kliknuti na "Mentalni Log" ili "Fizički Log"
5. Popuniti podatke i sačuvati

### Pregled Logova
1. Na home ekranu, kliknuti na datum u kalendaru
2. Otvara se `LogDetailsScreen` sa svim podacima za taj datum
3. Podaci su organizovani po kategorijama

### Pregled Napretka
- Home ekran prikazuje grafike sa nedeljnim podacima
- Grafikoni se automatski ažuriraju nakon unosa novih logova
- Crna linija = Fizička aktivnost
- Siva linija = Mentalno zdravlje

## Tehnička Dokumentacija

### Dodate Zavisnosti
```yaml
intl: ^0.20.2  # Za formatiranje datuma na srpskom
```

### Novi Fajlovi
- `lib/dailylogscreen.dart` - Glavni ekran za dnevni log
- `lib/mentallogscreen.dart` - Ekran za unos mentalnog loga
- `lib/physicallogscreen.dart` - Ekran za unos fizičkog loga
- `lib/logdetailsscreen.dart` - Ekran za prikaz detalja loga

### Izmenjeni Fajlovi
- `lib/datarepo.dart` - Dodate metode za rad sa logovima
- `lib/main.dart` - Dodat RepositoryProvider
- `lib/homescreen.dart` - Dodata provera dnevnog loga i učitavanje podataka
- `lib/app_cubit.dart` - Dodat weeklyMentalData state i metode
- `lib/fitness_cubit.dart` - Dodat datesWithLogs state i metode
- `pubspec.yaml` - Dodata intl zavisnost

## Buduća Unapređenja

### Moguća Proširenja
1. **Statistika** - Detaljniji prikazi napretka tokom vremena
2. **Izvoz Podataka** - Mogućnost izvoza logova u CSV/PDF
3. **Podsetnici** - Push notifikacije za podsetnik na unos loga
4. **Analitika** - AI analiza trendova i preporuke
5. **Grafički Kalendar** - Vizuelna indikacija kvaliteta dana u kalendaru
6. **Ciljevi** - Postavljanje ličnih ciljeva i praćenje njihovog ispunjenja

### Optimizacije
1. Keširanje podataka za brže učitavanje
2. Batch loading logova za velike periode
3. Offline podrška sa sinhronizacijom

## Testiranje

### Testni Scenariji
1. **Prvi unos loga** - Proveriti da li se dialog prikazuje pri prvom pokretanju
2. **Ponavljanje unosa** - Proveriti da li se može uneti log za isti dan više puta
3. **Istorijski unos** - Proveriti da li se mogu unositi logovi za prošle datume
4. **Prikaz podataka** - Proveriti da li se grafici pravilno ažuriraju
5. **Navigacija** - Proveriti flou kroz sve ekrane

## Kontakt i Podrška

Za dodatna pitanja ili probleme, kontaktirajte razvojni tim.

---

**Verzija**: 1.0.0  
**Datum**: Januar 2026  
**Autor**: AI Programming Assistant
