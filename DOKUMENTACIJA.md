# Dokumentacija projekta HZS - Frontend

Ovaj dokument pruža detaljan pregled arhitekture, funkcionalnosti i tehničkih detalja RealTalk mobilne aplikacije. Aplikacija je razvijena u Flutter framework-u i služi za praćenje mentalnog i fizičkog zdravlja korisnika.

## Sadržaj
1. [Tehnološki stek](#tehnološki-stek)
2. [Arhitektura projekta](#arhitektura-projekta)
3. [Struktura baze podataka](#struktura-baze-podataka)
4. [Komunikacija sa bazom podataka (Data Repository)](#komunikacija-sa-bazom-podataka-data-repository)
5. [Upravljanje stanjem (State Management)](#upravljanje-stanjem-state-management)
6. [Autentifikacija](#autentifikacija)
7. [Glavni moduli i ekrani](#glavni-moduli-i-ekrani)
8. [Sistem obaveštenja](#sistem-obaveštenja)
9. [Tok podataka i životni ciklus](#tok-podataka-i-životni-ciklus)
10. [Best Practices i konvencije](#best-practices-i-konvencije)

---

## Tehnološki stek

Projekat se oslanja na moderne biblioteke koje omogućavaju stabilnost i skalabilnost:
- **Framework:** Flutter (Dart)
- **Backend-as-a-Service:** Supabase (Baza podataka, Autentifikacija)
- **State Management:** Flutter BLoC (Cubit varijanta)
- **Grafikoni:** fl_chart (za vizuelni prikaz napretka)
- **Obaveštenja:** awesome_notifications
- **Lokalizacija:** intl
- **Kalendar:** streak_calendar

---

## Struktura baze podataka

Aplikacija koristi Supabase PostgreSQL bazu sa sledećim tabelama:

### Tabela: `profiles`

Čuva osnovne informacije o korisnicima.

**Kolone:**
| Kolona | Tip | Ograničenja | Opis |
|--------|-----|-------------|------|
| `id` | UUID | PRIMARY KEY, REFERENCES auth.users(id) | Korisnikov UUID iz Supabase Auth |
| `username` | TEXT | UNIQUE, NOT NULL | Korisničko ime (jedinstveno) |
| `full_name` | TEXT | NOT NULL | Puno ime i prezime |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Datum registracije |
| `streak` | INTEGER | DEFAULT 0 | Broj uzastopnih dana aktivnosti |
| `average_mood` | FLOAT | DEFAULT 0 | Prosečan mentalni skor (0-100) |
| `average_physical` | FLOAT | DEFAULT 0 | Prosečan fizički skor (0-100) |
| `growth` | INTEGER | DEFAULT 0 | Procenat rasta u odnosu na prošlu nedelju |

**Row Level Security (RLS) politike:**
```sql
-- Korisnici mogu videti samo svoj profil
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

-- Korisnici mogu ažurirati samo svoj profil
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);
```

---

### Tabela: `daily_logs`

Dnevni sumarni zapisi aktivnosti korisnika.

**Kolone:**
| Kolona | Tip | Ograničenja | Opis |
|--------|-----|-------------|------|
| `id` | UUID | PRIMARY KEY, DEFAULT uuid_generate_v4() | Jedinstveni ID zapisa |
| `user_id` | UUID | REFERENCES profiles(id), NOT NULL | Korisnik kojem pripada log |
| `log_date` | DATE | NOT NULL | Datum loga (YYYY-MM-DD) |
| `mental_mood` | INTEGER | CHECK (mental_mood >= 0 AND mental_mood <= 100) | Mentalni skor za dan |
| `physical_score` | INTEGER | CHECK (physical_score >= 0 AND physical_score <= 100) | Fizički skor za dan |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Vreme kreiranja zapisa |

**Unique constraint:**
```sql
UNIQUE (user_id, log_date)  -- Jedan log po korisniku po danu
```

**RLS politike:**
```sql
CREATE POLICY "Users can manage own logs" ON daily_logs
  FOR ALL USING (auth.uid() = user_id);
```

---

### Tabela: `mental_logs`

Detaljni zapisi o mentalnom zdravlju.

**Kolone:**
| Kolona | Tip | Ograničenja | Opis |
|--------|-----|-------------|------|
| `id` | UUID | PRIMARY KEY | Jedinstveni ID |
| `user_id` | UUID | REFERENCES profiles(id) | Korisnik |
| `log_date` | DATE | NOT NULL | Datum zapisa |
| `mood` | INTEGER | CHECK (mood >= 1 AND mood <= 10) | Ocena raspoloženja (1-10) |
| `score` | INTEGER | CHECK (score >= 0 AND score <= 100) | Kalkulisani mentalni skor |
| `note` | TEXT | | Tekstualna beleška (opciono) |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Vreme kreiranja |

**Indeksi:**
```sql
CREATE INDEX idx_mental_logs_user_date ON mental_logs(user_id, log_date);
```

---

### Tabela: `physical_logs`

Zapisi o fizičkoj aktivnosti.

**Kolone:**
| Kolona | Tip | Ograničenja | Opis |
|--------|-----|-------------|------|
| `id` | UUID | PRIMARY KEY | Jedinstveni ID |
| `user_id` | UUID | REFERENCES profiles(id) | Korisnik |
| `log_date` | DATE | NOT NULL | Datum aktivnosti |
| `activity_level` | INTEGER | CHECK (activity_level >= 1 AND activity_level <= 4) | Nivo aktivnosti (1-4) |
| `steps` | INTEGER | CHECK (steps >= 0) | Broj koraka |
| `workout_done` | BOOLEAN | DEFAULT FALSE | Da li je trening završen |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Vreme kreiranja |

**Activity level mapping:**
- 1 = Sedenje većinu dana
- 2 = Lagana šetnja
- 3 = Umerena vežba
- 4 = Intenzivan trening

**Indeksi:**
```sql
CREATE INDEX idx_physical_logs_user_date ON physical_logs(user_id, log_date);
```

---

### Tabela: `notifications`

Sistem obaveštenja između korisnika.

**Kolone:**
| Kolona | Tip | Ograničenja | Opis |
|--------|-----|-------------|------|
| `id` | UUID | PRIMARY KEY | Jedinstveni ID notifikacije |
| `sender_id` | UUID | REFERENCES profiles(id) | Ko je poslao |
| `recipient_id` | UUID | REFERENCES profiles(id) | Ko prima |
| `sender_name` | TEXT | | Ime pošiljaoca (denormalizovano) |
| `message` | TEXT | | Poruka notifikacije |
| `status` | TEXT | DEFAULT 'waiting' | Status: 'waiting', 'accepted', 'declined' |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Vreme kreiranja |

**RLS politike:**
```sql
-- Korisnici mogu videti notifikacije poslate njima
CREATE POLICY "Users can view received notifications" ON notifications
  FOR SELECT USING (auth.uid() = recipient_id);

-- Korisnici mogu kreirati notifikacije
CREATE POLICY "Users can create notifications" ON notifications
  FOR INSERT WITH CHECK (auth.uid() = sender_id);
```

---

### Database Functions (PostgreSQL)

**Automatsko ažuriranje streak-a:**
```sql
CREATE OR REPLACE FUNCTION update_user_streak()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles
  SET streak = (
    SELECT COUNT(DISTINCT log_date)
    FROM daily_logs
    WHERE user_id = NEW.user_id
      AND log_date >= CURRENT_DATE - INTERVAL '30 days'
  )
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_streak
AFTER INSERT ON daily_logs
FOR EACH ROW
EXECUTE FUNCTION update_user_streak();
```

**Automatsko čišćenje starih notifikacija:**
```sql
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void AS $$
BEGIN
  DELETE FROM notifications
  WHERE created_at < NOW() - INTERVAL '3 days'
    AND status = 'waiting';
END;
$$ LANGUAGE plpgsql;

-- Zakazano čišćenje svaki dan u ponoć
SELECT cron.schedule('cleanup-notifications', '0 0 * * *', 'SELECT cleanup_old_notifications()');
```

---

## Arhitektura projekta

Aplikacija prati modularni pristup gde je logika jasno razdvojena od korisničkog interfejsa. Folder `lib` sadrži sve ključne komponente:
- `main.dart`: Ulazna tačka aplikacije, inicijalizacija servisa (Supabase, Notifications).
- `auth.dart`: Logika za prijavu, registraciju i sesije.
- `datarepo.dart`: Centralni repozitorijum za sve upite ka bazi podataka.
- `app_cubit.dart` & `fitness_cubit.dart`: Upravljači stanjem za glavne aspekte aplikacije.
- `UI/`: Folder sa pomoćnim komponentama i SVG bibliotekama.

---

## Komunikacija sa bazom podataka (Data Repository)

Klasa `DataRepository` u [lib/datarepo.dart](lib/datarepo.dart) je "srce" aplikacije kada je u pitanju komunikacija sa spoljnim svetom. Koristi **SupabaseClient** za izvršavanje operacija.

### Inicijalizacija
```dart
final SupabaseClient supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
```
Klasa kreira Supabase klijent sa URL-om i anonimnim API ključem koji omogućava autorizovane upite ka bazi.

### Ključne funkcije:

#### 1. Profil korisnika

**`fetchUserProfile(String userId)`**
- **Parametri:** 
  - `userId` (String) - UUID korisnika iz Supabase Auth sistema
- **Povratna vrednost:** `Future<Map<String, dynamic>?>` - Mapa sa podacima korisnika ili `null` ako profil ne postoji
- **Opis:** Izvršava SQL upit ka tabeli `profiles` koristeći `.select().eq('id', userId).single()`. Vraća sve kolone za korisnika: `full_name`, `created_at`, `streak`, `average_mood`, `average_physical`.
- **Rukovanje greškama:** Hvata bilo koji izuzetak i vraća `null` umesto da baci grešku, čime se sprečava pad aplikacije.

**`updateUserProfile(String userId, {double? averageMood, double? averagePhysical, int? streak, int? growth})`**
- **Parametri:**
  - `userId` (String) - ID korisnika
  - `averageMood` (double?, opciono) - Novi prosečan mentalni skor (0-100)
  - `averagePhysical` (double?, opciono) - Prosečan fizički skor
  - `streak` (int?, opciono) - Broj uzastopnih dana aktivnosti
  - `growth` (int?, opciono) - Procent rasta u odnosu na prošlu nedelju
- **Povratna vrednost:** `Future<void>`
- **Opis:** Dinamički gradi update upit sa samo onim poljima koja su prosleđena (nisu `null`). Izvršava: `supabase.from('profiles').update({...}).eq('id', userId)`.

#### 2. Logovanje mentalnog zdravlja

**`logMentalHealth(String userId, int score, String note)`**
- **Parametri:**
  - `userId` - ID korisnika
  - `score` (int) - Mentalni skor (0-100)
  - `note` (String) - Tekstualna beleška o trenutnom stanju
- **Povratna vrednost:** `Future<void>`
- **Opis:** Jednostavan insert u tabelu `mental_logs`. Automatski dodaje trenutni timestamp kao `log_date` kroz `DateTime.now().toIso8601String()`. Koristi se za brze dnevne unose.
- **Struktura zapisa:** `{user_id, score, note, log_date}`

**`createMentalLog(String userId, DateTime logDate, int mood, int score, String note)`**
- **Parametri:**
  - `userId` - ID korisnika
  - `logDate` (DateTime) - Datum za koji se log kreira
  - `mood` (int) - Ocena raspoloženja (1-10)
  - `score` (int) - Kalkulisani mentalni skor (0-100)
  - `note` (String) - Detaljne beleške
- **Povratna vrednost:** `Future<void>`
- **Opis:** Detaljniji unos koji formira `log_date` kao ISO 8601 string (`YYYY-MM-DD`). Uključuje ekstenzivno logovanje (print statements) za debugging. Hvata greške i ponovo ih baca (rethrow) da bi pozivajući kod mogao da ih obради.
- **Struktura zapisa:** `{user_id, log_date, mood, score, note}`

**`fetchMentalLogsRange(String userId, DateTime startDate, DateTime endDate)`**
- **Parametri:**
  - `userId` - ID korisnika
  - `startDate` (DateTime) - Početni datum opsega
  - `endDate` (DateTime) - Krajnji datum opsega
- **Povratna vrednost:** `Future<List<Map<String, dynamic>>>` - Lista mentalnih logova sortiranih po datumu
- **Opis:** Izvršava SQL upit sa:
  - `.eq('user_id', userId)` - filtrira po korisniku
  - `.gte('log_date', start)` - >= startDate (greater than or equal)
  - `.lte('log_date', end)` - <= endDate (less than or equal)
  - `.order('log_date', ascending: true)` - sortira hronološki
- **Upotreba:** Napaja grafikone mentalnog napretka na HomeScreen-u za nedeljni prikaz.

#### 3. Praćenje fizičke aktivnosti

**`logPhysicalActivity(String userId, int steps)`**
- **Parametri:**
  - `userId` - ID korisnika
  - `steps` (int) - Broj koraka za trenutni dan
- **Povratna vrednost:** `Future<void>`
- **Opis:** Brz insert u `physical_logs` tabelu sa brojem koraka i trenutnim timestamp-om.
- **Struktura zapisa:** `{user_id, steps, log_date}`

**`createPhysicalLog(String userId, DateTime logDate, int activityLevel, int steps, bool workoutDone)`**
- **Parametri:**
  - `userId` - ID korisnika
  - `logDate` (DateTime) - Datum aktivnosti
  - `activityLevel` (int) - Nivo aktivnosti (1-4): 1=Sedenje, 2=Lagana šetnja, 3=Umeren trening, 4=Intenzivan trening
  - `steps` (int) - Ukupan broj koraka
  - `workoutDone` (bool) - Da li je trening završen
- **Povratna vrednost:** `Future<void>`
- **Opis:** Kompletan unos fizičke aktivnosti sa svim metrikama. Formatira datum kao `YYYY-MM-DD`. Loguje rezultat inserta i greške sa stack trace-om za debugging.
- **Struktura zapisa:** `{user_id, log_date, activity_level, steps, workout_done}`
- **Napomena:** `activity_level` se u grafikonima množi sa 25 da se dobije skor 0-100.

**`fetchPhysicalLogsRange(String userId, DateTime startDate, DateTime endDate)`**
- **Parametri:** Identični kao kod `fetchMentalLogsRange`
- **Povratna vrednost:** `Future<List<Map<String, dynamic>>>` - Lista fizičkih logova
- **Opis:** Isti princip kao mentalni logovi - filtrirani upit sa range-om datuma. Sortiran hronološki.

#### 4. Dnevni logovi i sinkronizacija

**`hasDailyLogForDate(String userId, DateTime date)`**
- **Parametri:**
  - `userId` - ID korisnika
  - `date` (DateTime) - Datum za proveru
- **Povratna vrednost:** `Future<bool>` - `true` ako log postoji, `false` ako ne postoji
- **Opis:** Koristi `.maybeSingle()` koji vraća `null` ako nema rezultata (umesto da baci grešku). Formatira datum kao `YYYY-MM-DD` pre upita. Hvata greške i vraća `false` da spreči pad aplikacije.
- **Upotreba:** Pre prikazivanja dnevne ankete, proverava se da li je korisnik već popunio podatke.

**`upsertDailyLog(String userId, DateTime logDate, {int? mentalMood, int? physicalScore})`**
- **Parametri:**
  - `userId` - ID korisnika
  - `logDate` (DateTime) - Datum log-a
  - `mentalMood` (int?, opciono) - Mentalni skor za dan
  - `physicalScore` (int?, opciono) - Fizički skor za dan
- **Povratna vrednost:** `Future<void>`
- **Opis:** Implementira "upsert" (update or insert) logiku:
  1. Prvo proverava da li postoji zapis za taj datum (`.maybeSingle()`)
  2. Ako postoji - izvršava `.update()` sa ID-jem postojećeg zapisa
  3. Ako ne postoji - izvršava `.insert()` sa novim podacima
  4. Koristi `.select()` nakon operacije da dobije potvrdu
- **Ekstenzivno logovanje:** Svaki korak je logovan (print) za praćenje toka podataka.
- **Dinamički payload:** Koristi `if (mentalMood != null)` sintaksu da bi ubacio samo non-null vrednosti.

#### 5. Kalendar i Notifikacije

**`fetchDatesWithLogs(String userId)`**
- **Parametri:** `userId` - ID korisnika
- **Povratna vrednost:** `Future<List<DateTime>>` - Lista datuma sa logovima
- **Opis:** Dohvata sve `log_date` vrednosti iz `daily_logs` tabele za korisnika. Sortira po datumu silazno (najnoviji prvi). Parsira string datume u DateTime objekte pomoću `DateTime.parse()`.
- **Upotreba:** Koristi se u ProfileScreen-u da bi se na kalendaru označile tačke (tacke) za dane kada je korisnik bio aktivan.

**`fetchLogForDate(String userId, DateTime date)`**
- **Parametri:**
  - `userId` - ID korisnika
  - `date` (DateTime) - Specifičan datum
- **Povratna vrednost:** `Future<Map<String, dynamic>?>` - Mapa sa ključevima `daily`, `mental`, `physical`
- **Opis:** Agregira podatke iz tri tabele za jedan datum:
  - Iz `daily_logs` - dnevni sumarni podaci
  - Iz `mental_logs` - mentalni detalji
  - Iz `physical_logs` - fizički detalji
- **Struktura povratka:** `{'daily': {...}, 'mental': {...}, 'physical': {...}}`
- **Upotreba:** Prikazivanje detalja za odabrani dan na kalendaru.

**`fetchNotifications()`**
- **Parametri:** Nema
- **Povratna vrednost:** `Future<List<Map<String, dynamic>>>` - Lista notifikacija
- **Opis:** Preuzima sve notifikacije iz tabele `notifications` sortirane po vremenu kreiranja (najnovije prvo). Vraća ih kao listu mapa.

**`acceptNotification(String notifId)`**
- **Parametri:** `notifId` - UUID notifikacije
- **Povratna vrednost:** `Future<void>`
- **Opis:** Ažurira status notifikacije na `'accepted'`. Koristi se kada korisnik prihvati matching zahtev ili poruku.

**`cleanOldNotifications()`**
- **Parametri:** Nema
- **Povratna vrednost:** `Future<void>`
- **Opis:** Briše notifikacije starije od 3 dana sa statusom `'waiting'`. Računa datum kao `DateTime.now().subtract(Duration(days: 3))` i izvršava `.delete().lt('created_at', threeDaysAgo).eq('status', 'waiting')`.
- **Upotreba:** Automatski clean-up koji se poziva pri otvaranju notification ekrana.

---

## Upravljanje stanjem (State Management)

Aplikacija koristi **Cubit** pattern (pojednostavljena verzija BLoC-a) koji omogućava reaktivno ažuriranje UI-ja bez kompleksnosti punog BLoC-a. Cubit emituje nove verzije stanja i UI se automatski ažurira kroz BlocBuilder widgete.

### Arhitektura State Management-a

Svaki Cubit nasljeđuje `Cubit<StateClass>` iz `flutter_bloc` paketa i upravlja jednom komponentom aplikacije. State objekti su **immutable** - svaka promena kreira novi state objekat pomoću `.copyWith()` metode.

### AppCubit - Globalno stanje aplikacije

**Lokacija:** [lib/app_cubit.dart](lib/app_cubit.dart)

**Klasa AppState** - Immutable kontejner za stanje:
```dart
class AppState {
  final int mentalScore;           // Trenutni mentalni skor (0-100)
  final int currentPollIndex;       // Pozicija u dnevnoj anketi (0-3)
  final String lastDateCompleted;   // Datum poslednje završene ankete
  final bool isLoading;            // Indicator učitavanja
  final String fullName;           // Puno ime korisnika
  final String joinDate;           // Datum registracije (YYYY-MM-DD)
  final int streak;                // Broj uzastopnih dana
  final double averageMood;        // Prosečan mood score
  final List<double> weeklyMentalData;    // 7 vrednosti za grafikon
  final List<double> weeklyPhysicalData;  // 7 vrednosti za grafikon
}
```

**Computed property - `isPollLocked`:**
- **Opis:** Getter koji vraća `true` ako je anketa već popunjena danas
- **Logika:** Poredi `lastDateCompleted` sa današnjim datumom (`DateTime.now().toString().split(' ')[0]`)
- **Upotreba:** UI prikazuje "Već si popunio anketu danas" kada je `isPollLocked == true`

#### Ključne metode AppCubit-a:

**`loadUserData(String userId)`**
- **Parametri:** `userId` - ID korisnika
- **Povratna vrednost:** `Future<void>`
- **Tok izvršavanja:**
  1. Emituje stanje sa `isLoading: true`
  2. Poziva `_repo.fetchUserProfile(userId)` da preuzme podatke
  3. Ako je profil uspešno učitan:
     - Ekstraktuje `full_name` iz responsa
     - Parsira `created_at` da dobije samo datum (`.substring(0, 10)`)
     - Postavlja `streak`, `averageMood` sa default 0 ako su null
  4. Emituje novo stanje sa `isLoading: false` i svim podacima
- **Upotreba:** Poziva se odmah nakon prijave korisnika u AuthWrapper-u

**`submitVote(int value, String userId)`**
- **Parametri:**
  - `value` (int) - Vrednost odgovora (1-5 obično)
  - `userId` - ID korisnika
- **Povratna vrednost:** `Future<void>`
- **Logika:**
  1. Kalkuliše novi skor: `newScore = (currentScore + value * 3).clamp(0, 100)`
  2. Inkrementira `currentPollIndex` (prelazi na sledeće pitanje)
  3. Ako je anketa završena (`nextIndex >= questions.length`):
     - Postavlja `lastDateCompleted` na današnji datum (zaključava anketu)
     - Šalje rezultat u bazu: `_repo.logMentalHealth(userId, newScore, "Daily Poll")`
  4. Emituje novo stanje sa ažuriranim vrednostima
- **Pitanja:** `["Mood?", "Energy?", "Focus?", "Calm?"]` - 4 pitanja koja daju maksimalno 60 poena (4 * 5 * 3)

**`resetPoll()`**
- **Opis:** Resetuje anketu na početak (postavlja `currentPollIndex` na 0)
- **Upotreba:** Debug funkcija ili za novu anketu sledećeg dana

**`loadWeeklyMentalData(String userId)`**
- **Parametri:** `userId` - ID korisnika
- **Povratna vrednost:** `Future<void>`
- **Algoritam:**
  1. Izračunava početak nedelje: `now.subtract(Duration(days: now.weekday - 1))` (ponedeljak)
  2. Kraj nedelje: `startOfWeek.add(Duration(days: 6))` (nedelja)
  3. Dohvata sve logove u tom opsegu: `fetchMentalLogsRange()`
  4. Pravi mapu `{datum_string -> score}` iz rezultata
  5. Kreira listu od 7 vrednosti (ponedeljak do nedelja):
     - Za svaki dan proverava da li ima log u mapi
     - Ako ima - uzima vrednost, ako nema - stavlja 0
  6. Emituje stanje sa `weeklyMentalData: weeklyData`
- **Upotreba:** Napaja LineChart widget na HomeScreen-u

**`loadWeeklyPhysicalData(String userId)`**
- **Opis:** Identičan algoritam kao `loadWeeklyMentalData` ali za fizičke podatke
- **Razlika:** Koristi `activity_level * 25` umesto direktnog score-a (konverzija 1-4 skale na 0-100)

---

### FitnessCubit - Upravljanje fitnes podacima

**Lokacija:** [lib/fitness_cubit.dart](lib/fitness_cubit.dart)

**Klasa FitnessState:**
```dart
class FitnessState {
  final List<DateTime> selectedDates;  // Datumi odabrani na kalendaru
  final List<double> weeklyData;       // Nedeljni podaci za grafikon
  final bool isLoading;               // Loading indicator
  final List<DateTime> datesWithLogs; // Datumi sa logovima (za marker)
}
```

**Factory constructor - `FitnessState.initial()`:**
- Kreira default stanje: prazna lista datuma, svi nedeljni podaci = 0

#### Ključne metode FitnessCubit-a:

**`selectDate(DateTime date)`**
- **Parametri:** `date` - Odabrani datum
- **Povratna vrednost:** `void`
- **Opis:** Mock funkcija koja generiše test podatke na osnovu dana u mesecu. U proizvodnoj verziji bi trebala da učita realne podatke za taj datum.
- **Mock algoritam:** `weeklyData[i] = (date.day + i) % 15 + 5` - generise vrednosti 5-20

**`syncSteps(String userId, int steps)`**
- **Parametri:**
  - `userId` - ID korisnika
  - `steps` (int) - Broj koraka za sinhronizaciju
- **Povratna vrednost:** `Future<void>`
- **Tok:**
  1. Postavlja `isLoading: true`
  2. Poziva `_repo.logPhysicalActivity(userId, steps)`
  3. Postavlja `isLoading: false`
- **Upotreba:** Sinhronizuje korake sa serverom (npr. sa pedometra ili health API-ja)

**`loadWeeklyPhysicalData(String userId)`**
- **Opis:** Isti algoritam kao u AppCubit-u
- **Konverzija:** `activity_level * 10` (umesto * 25) za skaliranje na grafikon
- **Struktura:** Ponedeljak do nedelja, 7 vrednosti

**`loadDatesWithLogs(String userId)`**
- **Parametri:** `userId` - ID korisnika
- **Povratna vrednost:** `Future<void>`
- **Tok:**
  1. Poziva `_repo.fetchDatesWithLogs(userId)`
  2. Prima listu DateTime objekata
  3. Emituje stanje sa `datesWithLogs: dates`
- **Upotreba:** StreakCalendar widget koristi ovu listu da obeležи tačke na datumima kada je korisnik bio aktivan

---

### AuthCubit - Autentifikacija

**Lokacija:** [lib/auth.dart](lib/auth.dart)

**Klasa AuthState:**
```dart
class AuthState {
  final bool isLoggedIn;      // Da li je korisnik prijavljen
  final bool isLoading;       // Učitavanje u toku
  final String? userId;       // UUID korisnika
  final String? userName;     // Korisničko ime
  final String? email;        // Email adresa
  final String? joinDate;     // Datum pridruživanja
  final String? errorMessage; // Poruka o grešci
}
```

**Inicijalizacija u konstruktoru:**
- Pri kreiranju, automatski poziva `_checkCurrentSession()` da vidi da li postoji aktivna sesija

#### Ključne metode AuthCubit-a:

**`_checkCurrentSession()`** (privatna)
- **Opis:** Automatska provera sesije pri startovanju aplikacije
- **Tok:**
  1. Postavlja `isLoading: true`
  2. Dohvata trenutnu sesiju: `_supabase.auth.currentSession`
  3. Ako sesija postoji:
     - Ekstraktuje user podatke iz `session.user`
     - Postavlja `isLoggedIn: true`
     - Popunjava `userId`, `email`, `userName` (iz metadata ili emaila)
     - Formatira `joinDate` iz `user.createdAt`
  4. Ako sesija ne postoji - postavlja `isLoggedIn: false`
- **Upotreba:** Omogućava "remember me" funkcionalnost - korisnik ostaje ulogovan

**`signIn(String email, String password)`**
- **Parametri:**
  - `email` (String) - Email adresa
  - `password` (String) - Lozinka
- **Povratna vrednost:** `Future<void>`
- **Tok:**
  1. Emituje stanje sa `isLoading: true, errorMessage: null`
  2. Poziva `_supabase.auth.signInWithPassword(email, password)`
  3. Ako je uspešno:
     - Ekstraktuje user objekt iz responsa
     - Emituje AuthState sa `isLoggedIn: true` i svim user podacima
  4. Ako neuspešno:
     - Emituje stanje sa `errorMessage` (npr. "Pogrešan email ili lozinka")
- **Error handling:** Try-catch hvata Supabase greške i pretvara ih u user-friendly poruke

---

### Kako Cubit-ovi komuniciraju:

1. **Dependency Injection:** Svi Cubit-ovi primaju `DataRepository` instance kroz konstruktor
2. **BlocProvider:** U [lib/main.dart](lib/main.dart), svi Cubit-ovi se kreiraju i stavljaju u widget tree:
```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (context) => AppCubit(repo)),
    BlocProvider(create: (context) => FitnessCubit(repo)),
    BlocProvider(create: (context) => AuthCubit()),
  ],
  child: MyApp(),
)
```
3. **Pristup iz widget-a:** `context.read<AppCubit>()` za pozivanje metoda, `context.watch<AppCubit>()` za praćenje promena
4. **Automatsko ažuriranje:** Kada Cubit emituje novo stanje, svi `BlocBuilder` i `BlocConsumer` widget-i se automatski rebuild-uju

---

## Autentifikacija

Implementirana je u [lib/auth.dart](lib/auth.dart). Koristi Supabase Auth sistem za upravljanje korisnicima i sesijama.

### Arhitektura autentifikacije

Supabase obezbeđuje:
- **JWT tokene** za autentifikaciju API zahteva
- **Automatsku persistenciju sesije** (korisnik ostaje ulogovan)
- **Supabase RLS (Row Level Security)** politike za sigurnost na nivou baze

### Podržane operacije:

#### 1. **Sign Up (Registracija)**

**Funkcija:** `signUp(String email, String password, String displayName, String fullName)`

**Parametri:**
- `email` (String) - Email adresa (mora biti validna i jedinstvena)
- `password` (String) - Lozinka (minimum 6 karaktera po defaultu)
- `displayName` (String) - Korisničko ime (prikazuje se u UI-ju)
- `fullName` (String) - Puno ime i prezime korisnika

**Tok izvršavanja:**
1. Emituje stanje sa `isLoading: true, errorMessage: null`
2. Poziva `_supabase.auth.signUp()` sa:
   - `email` i `password` za autentifikaciju
   - `data: {username, display_name, full_name}` - metadata koji se čuva u `auth.users` tabeli
3. Ako je signUp uspešan:
   - Dohvata `user` objekat iz responsa
   - Kreira profil u `profiles` tabeli:
     ```dart
     await _supabase.from('profiles').upsert({
       'id': user.id,
       'username': displayName,
       'full_name': fullName,
     }, onConflict: 'id');
     ```
   - `upsert` sa `onConflict: 'id'` - ako profil već postoji, ažurira ga; ako ne postoji, kreira novi
   - Hvata greške pri insert-u ali ne prekida tok (database trigger može automatski kreirati profil)
4. Emituje AuthState sa `isLoggedIn: true` i svim user podacima
5. Error handling:
   - `AuthException` - specifične greške (npr. "Email already exists")
   - Generički `catch` - neočekivane greške sa user-friendly porukom

**Struktura `profiles` tabele:**
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  username TEXT UNIQUE,
  full_name TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  streak INT DEFAULT 0,
  average_mood FLOAT DEFAULT 0,
  average_physical FLOAT DEFAULT 0
);
```

**Napomena o sigurnosti:** Anon API ključ je bezbedan jer Supabase RLS politike kontrolišu pristup podacima.

#### 2. **Sign In (Prijava)**

**Funkcija:** `signIn(String email, String password)`

**Parametri:**
- `email` (String) - Registrovan email
- `password` (String) - Odgovarajuća lozinka

**Tok izvršavanja:**
1. Postavlja `isLoading: true, errorMessage: null`
2. Poziva `_supabase.auth.signInWithPassword(email, password)`
3. Ako je response.user != null:
   - Ekstraktuje user podatke:
     - `userId`: `user.id` - UUID iz Supabase Auth
     - `email`: `user.email` - verifikovan email
     - `userName`: Prvo pokušava `user.userMetadata?['display_name']`, ako ne postoji koristi deo emaila pre @ (`email.split('@').first`)
     - `joinDate`: Formatira `user.createdAt` pomoću `_formatDate()` u format `YYYY.MM.DD.`
   - Emituje AuthState sa `isLoggedIn: true`
4. Ako je response.user == null:
   - Emituje `errorMessage: 'Sign in failed. Please try again.'`
5. Error handling:
   - `AuthException catch (e)` - prikazuje originalnu Supabase poruku (`e.message`)
   - Generički catch - prikazuje "An unexpected error occurred"

**Automatska sesija:** Nakon uspešnog signIn-a, Supabase automatski čuva JWT token lokalno.

#### 3. **Current Session Check (Provera sesije)**

**Funkcija:** `_checkCurrentSession()` (privatna)

**Poziv:** Automatski se poziva u konstruktoru `AuthCubit()`

**Tok izvršavanja:**
1. Postavlja `isLoading: true`
2. Dohvata trenutnu sesiju: `final session = _supabase.auth.currentSession`
3. Ako sesija postoji (nije `null`):
   - Znači da korisnik ima validan JWT token
   - Ekstraktuje user podatke iz `session.user`
   - Emituje AuthState sa `isLoggedIn: true`
4. Ako sesija ne postoji:
   - Korisnik mora da se uloguje
   - Emituje `AuthState(isLoggedIn: false)`
5. Hvata sve greške i postavlja `isLoggedIn: false`

**Persistence mehanizam:**
- Supabase Flutter SDK čuva token u:
  - **Android/iOS:** Secure storage (Keychain na iOS, EncryptedSharedPreferences na Android)
  - **Web:** localStorage
- Token se automatski osvežava kada istekne (refresh token mehanizam)

**Rezultat:** Aplikacija "pamti" korisnika između pokretanja bez potrebe za ponovnim loginom.

#### 4. **Sign Out (Odjava)**

**Funkcija:** `signOut()`

**Tok izvršavanja:**
1. Postavlja `isLoading: true`
2. Poziva `_supabase.auth.signOut()`
   - Briše lokalno sačuvan JWT token
   - Invalidira refresh token na serveru
3. Emituje `AuthState(isLoggedIn: false)` - resetuje sve user podatke
4. Error handling: Ako signOut ne uspe, zadržava trenutno stanje i prikazuje grešku

**Efekat:** Korisnik se vraća na LoginScreen, svi Cubit-ovi se resetuju.

#### 5. **Pomoćne funkcije**

**`clearError()`**
- Briše trenutnu error poruku
- Koristi se nakon što korisnik vidi grešku i zatvori dialog
- Emituje stanje sa `errorMessage: null`

**`_formatDate(String? dateStr)`** (privatna)
- **Parametri:** `dateStr` - ISO 8601 string (npr. "2024-01-15T10:30:00Z")
- **Povratna vrednost:** `String` - Formatiran datum "YYYY.MM.DD." ili "Unknown"
- **Algoritam:**
  1. Proverava da li je dateStr null - vraća "Unknown"
  2. Parsira string sa `DateTime.parse(dateStr)`
  3. Ekstraktuje year, month, day
  4. Formatira sa `.padLeft(2, '0')` da bi mesec i dan uvek bili 2 cifre (npr. 03 umesto 3)
  5. Vraća format: "2024.01.15."
- **Try-catch:** Ako parsiranje ne uspe, vraća "Unknown"

### Bezbednost i Best Practices:

1. **Lozinke nikada nisu sačuvane lokalno** - samo JWT token
2. **RLS politike na Supabase-u** osiguravaju da korisnici mogu videti samo svoje podatke:
   ```sql
   CREATE POLICY "Users can view own profile" ON profiles
   FOR SELECT USING (auth.uid() = id);
   ```
3. **Automatski refresh tokena** - SDK održava sesiju bez korisničke intervencije
4. **Error messages** su user-friendly ali ne otkrivaju sigurnosne detalje
5. **Email verifikacija** može biti omogućena u Supabase settings-ima (nije obavezna po defaultu)

---

## Glavni moduli i ekrani

### Arhitektura navigacije

Aplikacija koristi **indexed bottom navigation bar** sistem sa 5 glavnih ekrana. Implementirano u [lib/main.dart](lib/main.dart) preko `MainFooterPage` StatefulWidget-a.

**Navigaciona struktura:**
```dart
int _currentIndex = 2;  // Početna pozicija je Home (index 2)
final List<Widget> _screens = [
  InfoScreen(),      // Index 0
  ProfileScreen(),   // Index 1
  HomeScreen(),      // Index 2 - Default
  SearchScreen(),    // Index 3
  SettingsScreen(),  // Index 4
];
```

**Bottom Navigation Bar konfiguracija:**
- `type: BottomNavigationBarType.fixed` - Potrebno za više od 3 itema
- `backgroundColor: Colors.grey[400]` - Tamno siva footer pozadina
- `selectedItemColor: Colors.black` - Crna boja za aktivnu ikonicu
- `showSelectedLabels: false` - Sakriveni labeli za čist dizajn

### 1. Početna strana (HomeScreen)

**Lokacija:** [lib/homescreen.dart](lib/homescreen.dart)

**Svrha:** Centralno mesto gde korisnik vidi svoj progres, popunjava dnevne log-ove i analizira trendove.

#### Lifecycle i inicijalizacija:

**`initState()` metoda:**
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  _checkDailyLog();
  _loadWeeklyData();
});
```
- **addPostFrameCallback:** Izvršava se nakon što se widget tree sagradi (frame je renderovan)
- **Redosled poziva:** Prvo proverava dnevni log, zatim učitava nedeljne podatke

#### Ključne funkcije:

**`_checkDailyLog()`**
- **Svrha:** Proverava da li je korisnik popunio dnevni log za danas
- **Tok:**
  1. Proverava flag `hasCheckedDailyLog` da spreči multiple pozive
  2. Dohvata `userId` iz AuthCubit-a
  3. Poziva `repo.hasDailyLogForDate(userId, DateTime.now())`
  4. Ako log NE postoji:
     - Postavlja flag na `true`
     - Prikazuje `_showDailyLogPrompt()` dialog
- **Guard clause:** `if (authState.userId == null) return;` - bezbedno izlazi ako nema userId

**`_showDailyLogPrompt()`**
- **UI:** AlertDialog sa dva dugmeta
- **Opcije:**
  - "Kasnije" - samo zatvara dialog
  - "Da" - navigira na MentalLogScreen i zatim poziva `_loadWeeklyData()` po povratku (`.then((_) => _loadWeeklyData())`)
- **barrierDismissible: false** - Korisnik mora kliknuti dugme (ne može kliknuti van dialoga)

**`_loadWeeklyData()`**
- **Svrha:** Učitava sve podatke potrebne za grafikone i kalendar
- **Pozivi:**
  1. `AppCubit.loadWeeklyMentalData(userId)` - Mentalni podaci za grafikon
  2. `FitnessCubit.loadWeeklyPhysicalData(userId)` - Fizički podaci za grafikon
  3. `FitnessCubit.loadDatesWithLogs(userId)` - Datumi sa logovima za kalendar markere
- **await:** Svaki poziv čeka prethodni (sequential execution)

#### Komponente UI-ja:

**1. Header sekcija** (`_buildHeader`)
- Prikazuje ime korisnika i datum pridruživanja
- Dohvata iz AuthCubit state-a

**2. Kalendar** (`_buildCalendarCard`)
- **Widget:** `StreakCalendar` iz `streak_calendar` paketa
- **BlocBuilder:** Sluša `FitnessState` za `selectedDates` i `datesWithLogs`
- **datesWithLogs:** Lista datuma sa tačkicama (zelene tačke za dane sa logovima)
- **onDateSelected:** Navigira na `LogDetailsScreen(date: selectedDate)` da prikaže detalje za taj dan

**3. Progress grafikoni** (`_buildProgressChart`)
- **Dual BlocBuilder:** Kombinuje podatke iz `FitnessState` i `AppState`
- **LineChart widget** (fl_chart paket):
  - **Crna linija:** Fizički progres (`fitnessState.weeklyData`)
  - **Siva linija:** Mentalni progres (`mentalState.weeklyMentalData`)
  - **X-osa:** 7 dana (pon-ned)
  - **Y-osa:** 0-100 skala
- **Real-time updates:** Kada Cubit emituje novo stanje, grafikon se automatski ažurira

**4. Quick Action dugmad** (`_buildQuickActions`)
- "Mentalni Log" - navigira na `MentalScreen()`
- "Fizički Log" - navigira na `PhysicalScreen()`
- Dizajnirani kao veliki kartice sa ikonama

---

### 2. Profil (ProfileScreen)

**Lokacija:** [lib/profilescreen.dart](lib/profilescreen.dart)

**Svrha:** Vizuelna reprezentacija uspeha i statistika korisnika.

#### Komponente:

**1. Korisnički header**
- Avatar (placeholder ikonica)
- Username i datum pridruživanja
- Informacije iz AuthState-a

**2. Statistike kartice**
- **Streak:** Broj uzastopnih dana aktivnosti
  - Ikonica: 🔥 (vatra za motivaciju)
  - Dohvaćeno iz `profiles` tabele
- **Prosečan Mood:** 
  - Format: "8.5/10" ili "N/A" ako nema podataka
  - Kalkulisano iz svih mental_logs zapisa
- **Prosečna Fizička Aktivnost:**
  - Sličan format kao mood
  - Baziran na activity_level vrednostima

**3. Kalendar progresa**
- **StreakCalendar widget** sa marked dates
- **Zelene tačke:** Dani sa logovima
- **Prazni dani:** Bez logova
- **onClick:** Prikazuje detalje za odabrani dan
- **BlocBuilder:** Sluša `FitnessState.datesWithLogs`

**4. Istorija aktivnosti**
- Lista poslednje 3-5 aktivnosti
- Prikazuje datum i tip loga (mentalni/fizički)

#### Funkcije:

**`loadProfileData()`**
- Poziva `AppCubit.loadUserData(userId)` pri otvaranju ekrana
- Učitava sve profile podatke iz baze
- Ažurira state sa fresh dataima

---

### 3. Logovanje detalja (Mental & Physical Screens)

#### MentalLogScreen

**Lokacija:** [lib/mentallogscreen.dart](lib/mentallogscreen.dart)

**Parametri:**
- `logDate` (DateTime) - Datum za koji se unosi log

**Funkcionalnost:**
1. **Mood Slider** - Ocena raspoloženja (1-10)
   - Visual feedback sa emoji-ima
   - Default: 5 (neutralno)
2. **Anketa pitanja:**
   - "Kako se osećaš danas?" (1-5 rating)
   - "Nivo energije?" (1-5)
   - "Fokus i koncentracija?" (1-5)
   - "Mir i opuštenost?" (1-5)
3. **Score kalkulacija:**
   ```dart
   int score = (mood * 4) + (energija + fokus + spokojstvo) * 3;
   // Maksimalno: 40 + 45 = 85 bodova
   ```
4. **Tekstualna beleška:**
   - Multi-line TextField
   - Opciono - korisnik može ostaviti prazan
5. **Submit akcija:**
   - Poziva `repo.createMentalLog(userId, logDate, mood, score, note)`
   - Ažurira `daily_logs` sa `repo.upsertDailyLog(userId, logDate, mentalMood: score)`
   - Prikazuje SnackBar sa potvrdom
   - Navigira nazad na HomeScreen

**Validacije:**
- Svi slideri moraju biti pomereni (nije moguće submitovati default vrednosti)
- Datum ne može biti u budućnosti

#### PhysicalLogScreen

**Lokacija:** [lib/physicallogscreen.dart](lib/physicallogscreen.dart)

**Parametri:**
- `logDate` (DateTime) - Datum fizičke aktivnosti

**Funkcionalnost:**
1. **Activity Level picker** (1-4):
   - 1 = "Sedenje većinu dana" 🪑
   - 2 = "Lagana šetnja" 🚶
   - 3 = "Umerena vežba" 🏃
   - 4 = "Intenzivan trening" 💪
   - Implementiran kao segmented control ili radio buttons
2. **Steps Counter:**
   - Numerički input za broj koraka
   - Validacija: >= 0 i <= 100000
   - Placeholder: "npr. 8500"
3. **Workout Checkbox:**
   - "Završio/la sam planirani trening danas"
   - Boolean vrednost
4. **Submit akcija:**
   - Poziva `repo.createPhysicalLog(userId, logDate, activityLevel, steps, workoutDone)`
   - Ažurira `daily_logs` sa `repo.upsertDailyLog(userId, logDate, physicalScore: activityLevel * 25)`
   - SnackBar poruka: "Fizička aktivnost sačuvana! 💪"
   - Navigacija nazad

**Formula za skor:**
```dart
int physicalScore = activityLevel * 25;  // Konverzija 1-4 na 25-100 skalu
```

---

### 4. Search/Matching Screen

**Lokacija:** [lib/matchingscreen.dart](lib/matchingscreen.dart)

**Svrha:** Pronalaženje drugih korisnika sa sličnim ciljevima i statistikama.

**Funkcionalnost:**
- Prikazuje listu potencijalnih match-eva
- Sortira po kompatibilnosti (npr. sličan average mood)
- "Pošalji poziv" dugme koje kreira notifikaciju za drugog korisnika

**Matching algoritam:**
```dart
double calculateCompatibility(userA, userB) {
  double moodDiff = (userA.averageMood - userB.averageMood).abs();
  double physicalDiff = (userA.averagePhysical - userB.averagePhysical).abs();
  return 100 - (moodDiff + physicalDiff) / 2;  // Viši = bolji match
}
```

---

### 5. Settings Screen

**Lokacija:** [lib/settingscreen.dart](lib/settingscreen.dart)

**Opcije:**
1. **Notifikacije:**
   - Toggle za push obaveštenja
   - Vreme podsetnika (npr. 20:00 svake večeri)
2. **Tema:**
   - Light/Dark mode (trenutno samo light)
3. **Privatnost:**
   - Vidljivost profila za druge korisnike
4. **Logout:**
   - Dugme za odjavu
   - Poziva `AuthCubit.signOut()`
5. **About:**
   - Verzija aplikacije
   - Credits
   - Politika privatnosti link

---

## Sistem obaveštenja

Aplikacija koristi `awesome_notifications` paket za lokalna push obaveštenja. Implementirano u [lib/main.dart](lib/main.dart).

### Inicijalizacija

**U `main()` funkciji:**
```dart
AwesomeNotifications().initialize(
  null,  // icon može biti null za default
  [
    NotificationChannel(
      channelKey: 'mental_health_channel',
      channelName: 'Mental Health Notifications',
      channelDescription: 'Motivational alerts based on score',
      defaultColor: Colors.grey,
      ledColor: Colors.white,
      importance: NotificationImportance.High,
    ),
  ],
);
```

### Konfiguracija kanala:

**NotificationChannel parametri:**
- **channelKey:** `'mental_health_channel'` - Jedinstveni identifikator
- **channelName:** `'Mental Health Notifications'` - Ime prikazano u system settings
- **channelDescription:** Opis svrhe notifikacija
- **defaultColor:** `Colors.grey` - Boja notifikacije na Android-u
- **ledColor:** `Colors.white` - Boja LED indikatora (stariji Android uređaji)
- **importance:** `NotificationImportance.High` - Prioritet:
  - High = Pojavljuje se kao heads-up notification
  - Default = Normalna notifikacija u notification tray
  - Low = Minimalna vidljivost

### Tipovi obaveštenja:

#### 1. **Motivaciona obaveštenja bazirana na skoru**

**Trigger:** Nakon popunjavanja dnevne ankete na osnovu mentalnog skora

**Logika:**
```dart
void checkAndSendNotification(int mentalScore) {
  String title = "";
  String body = "";
  
  if (mentalScore >= 80) {
    title = "Odličan dan! 🎉";
    body = "Nastavi ovako, sjajno napreduješ!";
  } else if (mentalScore >= 60) {
    title = "Dobar posao! 👍";
    body = "Solidno si se danas snašao/la.";
  } else if (mentalScore >= 40) {
    title = "Može bolje 💪";
    body = "Sutra je novi dan, ne odustaj!";
  } else {
    title = "Tu smo za tebe ❤️";
    body = "Nemoj biti prestrg prema sebi, korak po korak.";
  }
  
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      channelKey: 'mental_health_channel',
      title: title,
      body: body,
      notificationLayout: NotificationLayout.Default,
    ),
  );
}
```

**Poziv:** Nakon `submitVote()` u AppCubit-u kada je anketa završena

#### 2. **Dnevni podsetnik**

**Svrha:** Podseća korisnika da popuni dnevni log ako nije do određenog vremena

**Zakazivanje:**
```dart
void scheduleDailyReminder() {
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 1,  // Fiksan ID za dnevni podsetnik
      channelKey: 'mental_health_channel',
      title: "Vreme za dnevni check-in! 📝",
      body: "Nisi još popunio/la današnji log. Izdvoj 2 minuta!",
      notificationLayout: NotificationLayout.Default,
    ),
    schedule: NotificationCalendar(
      hour: 20,     // 8 PM
      minute: 0,
      second: 0,
      repeats: true,  // Ponavlja se svaki dan
    ),
  );
}
```

**Postavke:**
- **Vreme:** 20:00 (8 PM) svako veče
- **repeats: true** - Automatski se zakazuje za sledeći dan
- **Condition:** Proverava se `hasDailyLogForDate()` pre slanja

#### 3. **Matching notifikacije**

**Svrha:** Obaveštava korisnika kada neko prihvati njegov poziv ili pošalje novi

**Trigger:** Realtime listener na `notifications` tabeli u Supabase-u

**Implementacija:**
```dart
void listenToNotifications(String userId) {
  supabase
    .from('notifications')
    .stream(primaryKey: ['id'])
    .eq('recipient_id', userId)
    .eq('status', 'waiting')
    .listen((List<Map<String, dynamic>> data) {
      for (var notification in data) {
        _showMatchingNotification(notification);
      }
    });
}

void _showMatchingNotification(Map<String, dynamic> notif) {
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: notif['id'].hashCode,
      channelKey: 'mental_health_channel',
      title: "Novi poziv! 🤝",
      body: "${notif['sender_name']} te želi dodati kao prijatelja!",
      payload: {'notification_id': notif['id']},
    ),
    actionButtons: [
      NotificationActionButton(
        key: 'ACCEPT',
        label: 'Prihvati',
        color: Colors.green,
      ),
      NotificationActionButton(
        key: 'DECLINE',
        label: 'Odbij',
        color: Colors.red,
      ),
    ],
  );
}
```

**Action buttons:**
- Korisnik može kliknuti "Prihvati" ili "Odbij" direktno iz notifikacije
- Poziva `repo.acceptNotification(notifId)` ili `repo.declineNotification(notifId)`

### Permissions handling:

**Request permissions:**
```dart
Future<void> requestNotificationPermissions() async {
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }
}
```

**Poziv:** U `initState()` metodi MainActivity ili pri prvom pokretanju aplikacije

### Platform specifičnosti:

**Android:**
- Notifikacije rade iz kutije nakon inicijalizacije kanala
- `importance: High` omogućava heads-up display
- LED color radi na uređajima koji imaju LED indikator

**iOS:**
- Zahteva dodatne permissions kroz `Info.plist`
- Ne podržava action buttons na starijim verzijama iOS-a
- Requires APNs (Apple Push Notification service) za remote notifications

### Best practices:

1. **Ne spamovati notifikacije** - Maksimalno 1-2 dnevno
2. **Personalizovati poruke** - Koristiti ime korisnika i relevantne podatke
3. **Omogućiti isključivanje** - Toggle u Settings-u
4. **Testirati time zones** - Koristiti lokalno vreme korisnika
5. **Clear old notifications** - Pozivati `AwesomeNotifications().cancelAllSchedules()` kad je potrebno

### Debugging:

**Print notification delivery:**
```dart
AwesomeNotifications().actionStream.listen((action) {
  print('Notification action: ${action.buttonKeyPressed}');
  print('Payload: ${action.payload}');
});
```

**Check permission status:**
```dart
bool allowed = await AwesomeNotifications().isNotificationAllowed();
print('Notifications allowed: $allowed');
```

---

## Tok podataka i životni ciklus

### Početak sesije (Cold Start)

**1. Pokretanje aplikacije (`main()` funkcija):**
```
main()
  ├─> WidgetsFlutterBinding.ensureInitialized()
  ├─> initializeDateFormatting('sr_RS')
  ├─> Supabase.initialize() [with timeout 6s]
  ├─> AwesomeNotifications().initialize()
  ├─> DataRepository instance creation
  └─> runApp() sa MultiBlocProvider
```

**2. Provider hijerarhija:**
```
MultiRepositoryProvider
  └─> RepositoryProvider<DataRepository>
      └─> MultiBlocProvider
          ├─> BlocProvider<AppCubit>
          ├─> BlocProvider<FitnessCubit>
          └─> BlocProvider<AuthCubit>
              └─> MyApp (MaterialApp)
```

**3. AuthCubit inicijalizacija:**
```
AuthCubit()
  └─> _checkCurrentSession()
      ├─> Supabase.auth.currentSession check
      ├─> Ako session EXISTS:
      │   └─> emit(AuthState(isLoggedIn: true, ...))
      └─> Ako session NULL:
          └─> emit(AuthState(isLoggedIn: false))
```

**4. Routing odluka (AuthWrapper):**
```
BlocBuilder<AuthCubit, AuthState>
  ├─> state.isLoading && !isLoggedIn
  │   └─> CircularProgressIndicator
  ├─> !state.isLoggedIn
  │   └─> LoginScreen()
  └─> state.isLoggedIn
      └─> MainFooterPage()
          └─> screens[_currentIndex]
```

---

### Login flow

**User akcija: Unos email-a i password-a i klik na "Prijavi se"**

```
LoginScreen
  └─> onPressed: () => context.read<AuthCubit>().signIn(email, pass)
      └─> AuthCubit.signIn()
          ├─> emit(state.copyWith(isLoading: true))
          ├─> _supabase.auth.signInWithPassword()
          ├─> Ako uspeh:
          │   └─> emit(AuthState(isLoggedIn: true, userId: ..., ...))
          └─> Ako greška:
              └─> emit(state.copyWith(errorMessage: "..."))
                  └─> UI prikazuje SnackBar sa greškom

AuthWrapper.build() (BlocBuilder rebuild)
  └─> state.isLoggedIn == true
      └─> Navigator pushReplacement → MainFooterPage
          └─> HomeScreen.initState()
              ├─> _checkDailyLog()
              │   ├─> repo.hasDailyLogForDate(userId, today)
              │   └─> Ako FALSE: _showDailyLogPrompt()
              └─> _loadWeeklyData()
                  ├─> AppCubit.loadWeeklyMentalData(userId)
                  ├─> FitnessCubit.loadWeeklyPhysicalData(userId)
                  └─> FitnessCubit.loadDatesWithLogs(userId)
```

---

### Dnevni log flow

**Scenario: Korisnik otvara aplikaciju ujutro, nema još log za danas**

```
HomeScreen.initState()
  └─> _checkDailyLog()
      └─> repo.hasDailyLogForDate(userId, DateTime.now())
          └─> SQL: SELECT * FROM daily_logs WHERE user_id = ? AND log_date = ?
              └─> Result: NULL (nema loga)
                  └─> _showDailyLogPrompt()
                      └─> AlertDialog("Nisi popunio dnevni log...")
                          ├─> "Kasnije" → close dialog
                          └─> "Da" → Navigator.push(MentalLogScreen)

MentalLogScreen
  ├─> User interakcija:
  │   ├─> Podešava mood slider (1-10)
  │   ├─> Odgovara na 4 pitanja (svako 1-5)
  │   └─> Unosi tekstualnu belešku
  └─> onSubmit()
      ├─> Kalkuliše score: (mood * 4) + sum(pitanja * 3)
      ├─> repo.createMentalLog(userId, date, mood, score, note)
      │   └─> SQL INSERT INTO mental_logs (...)
      ├─> repo.upsertDailyLog(userId, date, mentalMood: score)
      │   ├─> SQL SELECT (provera existing)
      │   └─> SQL INSERT or UPDATE daily_logs
      └─> Navigator.pop() → HomeScreen
          └─> _loadWeeklyData() (refresh data)
              └─> UI automatski ažurira grafikone (BlocBuilder rebuild)
```

---

### Fizički log flow

```
HomeScreen → Quick Action "Fizički Log" button
  └─> Navigator.push(PhysicalScreen)
      └─> PhysicalScreen
          ├─> User bira activity_level (1-4)
          ├─> User unosi steps (broj)
          ├─> User čekira workout_done checkbox
          └─> onSubmit()
              ├─> repo.createPhysicalLog(userId, date, activityLevel, steps, workoutDone)
              │   └─> SQL INSERT INTO physical_logs (...)
              ├─> repo.upsertDailyLog(userId, date, physicalScore: activityLevel * 25)
              │   └─> SQL UPDATE daily_logs SET physical_score = ?
              └─> Navigator.pop()
                  └─> HomeScreen refresh
                      └─> Grafikon ažuriran sa novim podacima
```

---

### Real-time updates (Calendar markers)

```
ProfileScreen.initState()
  └─> FitnessCubit.loadDatesWithLogs(userId)
      └─> repo.fetchDatesWithLogs(userId)
          └─> SQL: SELECT log_date FROM daily_logs WHERE user_id = ?
              └─> Returns: [DateTime(2024-01-10), DateTime(2024-01-11), ...]
                  └─> emit(state.copyWith(datesWithLogs: dates))
                      └─> BlocBuilder<FitnessState> rebuild
                          └─> StreakCalendar.markedDates ažuriran
                              └─> UI prikazuje zelene tačke na tim datumima
```

---

### State synchronization pattern

**Problem:** Isti podaci se koriste na više ekrana

**Rešenje:** Centralizovan Cubit

```
AppCubit (single source of truth)
  └─> weeklyMentalData: [50, 60, 55, 70, 65, 80, 75]

Subscribers:
  ├─> HomeScreen
  │   └─> BlocBuilder<AppCubit> → prikazuje LineChart
  └─> ProfileScreen
      └─> BlocBuilder<AppCubit> → prikazuje prosek

Ažuriranje:
  MentalLogScreen.submit()
    └─> repo.createMentalLog() → baza ažurirana
        └─> AppCubit.loadWeeklyMentalData() → novi fetch iz baze
            └─> emit(new state) → SVI subscribers automatski rebuild-uju
```

---

## Best Practices i konvencije

### 1. Error Handling

**Svi DataRepository pozivi koriste try-catch:**
```dart
Future<void> someFunction() async {
  try {
    final result = await supabase.from('table').select();
    return result;
  } catch (e, stackTrace) {
    print('Error in someFunction: $e');
    print('Stack trace: $stackTrace');
    rethrow;  // Ili return null/default vrednost
  }
}
```

**Pravila:**
- **Logging funkcije** - print error i stack trace
- **UI funkcije** - catch i prikaži user-friendly poruku (SnackBar, Dialog)
- **Nikad ne ignorišite greške** - barem logujte ih

---

### 2. Null Safety

**Dart 3.0 null safety je obavezna:**
```dart
String? userId;  // Može biti null
String username;  // Ne može biti null

// Provera pre korišćenja
if (userId != null) {
  fetchData(userId);
}

// Null-aware operators
final name = user?.name ?? 'Guest';  // Default vrednost
final length = text?.length;  // Vraća null ako je text null
```

**Guard clauses u funkcijama:**
```dart
Future<void> loadData(String? userId) async {
  if (userId == null) return;  // Early return
  // ... nastavak logike
}
```

---

### 3. State Immutability

**NIKAD ne mutirati state direktno:**
```dart
// ❌ LOŠE
state.weeklyData[0] = 100;

// ✅ DOBRO
final newData = List<double>.from(state.weeklyData);
newData[0] = 100;
emit(state.copyWith(weeklyData: newData));
```

**Razlog:** BloC ne detektuje promene ako je isti objekat (by reference)

---

### 4. Async/Await Best Practices

**Redosled async operacija:**
```dart
// Sequential (čeka svaki poziv)
await operation1();
await operation2();

// Parallel (izvršava istovremeno)
await Future.wait([
  operation1(),
  operation2(),
]);
```

**Kada koristiti parallel:**
- Nezavisne operacije (npr. fetchMentalLogs i fetchPhysicalLogs)

**Kada koristiti sequential:**
- Dependentne operacije (npr. createLog pa onda updateProfile)

---

### 5. Widget lifecycle

**initState() - Poziva se samo jednom:**
```dart
@override
void initState() {
  super.initState();
  // ✅ Inicijalizacija state-a
  // ✅ Setup listeners
  // ✅ PostFrameCallback za data loading
  
  // ❌ Ne pristupati inherited widgets direktno (context.read)
  // Koristi addPostFrameCallback ili didChangeDependencies
}
```

**dispose() - Cleanup:**
```dart
@override
void dispose() {
  _controller.dispose();
  _subscription.cancel();
  super.dispose();
}
```

---

### 6. BlocBuilder vs BlocListener vs BlocConsumer

**BlocBuilder:**
```dart
BlocBuilder<AppCubit, AppState>(
  builder: (context, state) {
    return Text('Score: ${state.mentalScore}');
  },
)
```
**Kada:** Rebuild UI na osnovu state promena

**BlocListener:**
```dart
BlocListener<AuthCubit, AuthState>(
  listener: (context, state) {
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
  },
  child: MyWidget(),
)
```
**Kada:** Izvršiti side-effect (navigacija, SnackBar) bez rebuild-a

**BlocConsumer:**
```dart
BlocConsumer<AppCubit, AppState>(
  listener: (context, state) { /* side effects */ },
  builder: (context, state) { /* UI */ },
)
```
**Kada:** Trebaju oba (i rebuild i side-effects)

---

### 7. Performance optimizacije

**Selective rebuilds sa buildWhen:**
```dart
BlocBuilder<AppCubit, AppState>(
  buildWhen: (previous, current) {
    return previous.mentalScore != current.mentalScore;
  },
  builder: (context, state) {
    return Text('${state.mentalScore}');
  },
)
```
**Efekat:** Builder se poziva samo kad se `mentalScore` promeni, ne za sve promene state-a

**Debounce user input:**
```dart
Timer? _debounce;

void _onSearchChanged(String query) {
  _debounce?.cancel();
  _debounce = Timer(Duration(milliseconds: 300), () {
    // Izvrši pretragu nakon 300ms bez novih inputa
    context.read<SearchCubit>().search(query);
  });
}
```

---

### 8. Konstante i konfiguracija

**Ekstraktujte magic numbers:**
```dart
// ❌ LOŠE
if (score >= 80) { ... }

// ✅ DOBRO
class ScoreThresholds {
  static const int excellent = 80;
  static const int good = 60;
  static const int average = 40;
}

if (score >= ScoreThresholds.excellent) { ... }
```

**Centralizovane boje i stilovi:**
```dart
class AppColors {
  static const primaryGray = Color(0xFFD3D3D3);
  static const darkGray = Color(0xFF808080);
  static const accentBlack = Colors.black;
}

class AppTextStyles {
  static const header = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
}
```

---

### 9. Testing strategije

**Unit testovi za Cubit:**
```dart
test('submitVote increases mental score', () async {
  final cubit = AppCubit(mockRepo);
  
  await cubit.submitVote(5, 'user-id');
  
  expect(cubit.state.mentalScore, equals(65)); // 50 + 5*3
});
```

**Widget testovi:**
```dart
testWidgets('Shows login screen when not logged in', (tester) async {
  await tester.pumpWidget(MyApp());
  
  expect(find.byType(LoginScreen), findsOneWidget);
});
```

**Integration testovi:**
- Koristiti Supabase test environment
- Cleanup test data nakon svakog testa

---

### 10. Imenovanje konvencija

**Fajlovi:**
- `lowercase_with_underscores.dart`
- Ekrani: `*_screen.dart` (npr. `home_screen.dart`)
- Cubiti: `*_cubit.dart`
- Modeli: `*_model.dart`

**Klase:**
- `PascalCase` (npr. `HomeScreen`, `AppCubit`)

**Varijable i funkcije:**
- `camelCase` (npr. `mentalScore`, `loadUserData`)

**Konstante:**
- `lowerCamelCase` ili `SCREAMING_SNAKE_CASE` za global
  ```dart
  const maxScore = 100;
  const String API_KEY = 'abc123';
  ```

**Privatne članove:**
- Prefix sa `_` (npr. `_repo`, `_checkSession`)

---

*Napomena: Ova dokumentacija je generisana za verziju 1.0.0 frontend dela HZS aplikacije.*
