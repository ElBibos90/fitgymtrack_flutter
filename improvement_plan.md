# Piano di Improvement: Azioni Rapide Dashboard

## 📊 Stato Attuale delle Azioni Rapide

### ⚠️ **1. Mie Schede** (PROBLEMATICA)
- **Route**: `/workouts` → Esiste ✅
- **Screen**: `WorkoutPlansScreen` → Implementata ✅  
- **Bloc**: `WorkoutBloc` → Funzionante ✅
- **Count dinamico**: Mostra "Gestisci" → OK ✅
- **PROBLEMA**: Porta a una `WorkoutPlansScreen` SEPARATA dalla tab "Allenamenti" ❌
- **ISSUE**: Crea duplicazione invece di navigare alla tab corretta ❌

### ❌ **2. Cronologia** (ROUTE NON ESISTE)
- **Route**: `/workouts/history` → **ROUTE NON TROVATA NEL ROUTER** ❌
- **Screen**: **NON IMPLEMENTATA** ❌
- **Bloc**: `WorkoutHistoryBloc` → Già esistente ✅
- **Count dinamico**: Mostra "Allenamenti" → Statico ❌
- **Modelli**: `WorkoutHistoryEntry`, `CompletedSeriesData` → Esistenti ✅
- **ERRORE**: Click sull'azione genera errore di navigazione ❌

### ❌ **3. Esercizi** (ROUTE NON ESISTE)
- **Route**: `/exercises` → **ROUTE NON TROVATA NEL ROUTER** ❌
- **Screen**: **NON IMPLEMENTATA** ❌  
- **Bloc**: Repository method `getAvailableExercises()` → Esistente ✅
- **Count dinamico**: Mostra count corretto da subscription → OK ✅
- **Modelli**: `ExerciseItem` → Completo ✅
- **ERRORE**: Click sull'azione genera errore di navigazione ❌

### ❌ **4. Impostazioni Account** (ROUTE NON ESISTE)
- **Route**: `/settings` → **ROUTE NON TROVATA NEL ROUTER** ❌
- **Screen**: **NON IMPLEMENTATA** ❌
- **Bloc**: **NON DEFINITO** ❌
- **Count dinamico**: Mostra "Account" → Statico ❌
- **ERRORE**: Click sull'azione genera errore di navigazione ❌

---

## 🚀 Piano di Implementazione

### **FASE 0: Fix Navigazione Mie Schede** ⚠️

#### 🐛 Problema identificato:
Il click su "Mie Schede" porta a `/workouts` che crea una **nuova istanza** di `WorkoutPlansScreen`, invece di navigare alla tab "Allenamenti" esistente nella `HomeScreen`.

#### 🔧 Soluzioni possibili:
**Opzione A - Navigazione Tab (CONSIGLIATA)**: 
```dart
// In DashboardPage, invece di context.push('/workouts'):
onTap: () {
  // Trova l'HomeScreen parent e naviga alla tab 1
  final homeScreen = context.findAncestorStateOfType<_HomeScreenState>();
  homeScreen?.navigateToWorkoutTab(); // Metodo da aggiungere
}
```

**Opzione B - Route Condiviso**:
Rimuovere il route `/workouts` standalone e usare sempre la tab

**Opzione C - Redirect**:
Far sì che `/workouts` reindirizzi alla dashboard con tab=1

#### 🎯 Implementazione consigliata:
1. Aggiungere metodo `navigateToWorkoutTab()` in `HomeScreen`
2. Modificare `onTap` delle azioni rapide per usare navigazione tab
3. Testare che la navigazione funzioni correttamente 

#### 📝 Componenti da creare:
1. **Screen**: `lib/features/workouts/presentation/screens/workout_history_screen.dart`
2. **Widgets**: 
   - `lib/shared/widgets/workout_history_card.dart`
   - `lib/shared/widgets/workout_details_modal.dart`
3. **Route**: Aggiungere in `app_router.dart`
4. **Count dinamico**: Aggiornare dashboard per mostrare numero allenamenti completati

#### 🎯 Features da implementare:
- Lista cronologia allenamenti ordinati per data (più recenti primi)
- Card per ogni allenamento con: nome scheda, data, durata, esercizi completati
- Tap su card → Mostra dettagli serie completate  
- Swipe per eliminare allenamento dalla cronologia
- Pull-to-refresh
- Stati vuoti con messaggio motivazionale
- Filtri per data (ultima settimana, ultimo mese, ecc.)

#### 🔧 Implementazione tecnica:
```dart
// Uso WorkoutHistoryBloc esistente
BlocBuilder<WorkoutHistoryBloc, WorkoutHistoryState>(
  builder: (context, state) {
    if (state is WorkoutHistoryLoaded) {
      return ListView.builder(
        itemCount: state.workoutHistory.length,
        itemBuilder: (context, index) => WorkoutHistoryCard(
          workout: state.workoutHistory[index],
          onTap: () => _showWorkoutDetails(state.workoutHistory[index]),
          onDelete: () => _deleteWorkout(state.workoutHistory[index].id),
        ),
      );
    }
    // ... altri stati
  },
)
```

---

### **FASE 2: Gestione Esercizi**

#### 📝 Componenti da creare:
1. **Screen**: `lib/features/exercises/presentation/screens/exercises_screen.dart`
2. **Bloc**: `lib/features/exercises/bloc/exercises_bloc.dart`
3. **Widgets**: 
   - `lib/shared/widgets/exercise_card.dart`
   - `lib/shared/widgets/exercise_filter_chips.dart`
   - `lib/shared/widgets/create_exercise_modal.dart`
4. **Route**: Aggiungere in `app_router.dart`

#### 🎯 Features da implementare:
- Lista esercizi disponibili (sistem + custom dell'utente)
- Filtri per: gruppo muscolare, attrezzatura, tipo (custom/sistema)
- Ricerca per nome
- Indicatore visuale esercizi custom vs. predefiniti
- Tap su esercizio → Mostra dettagli completi
- FAB per creare nuovo esercizio custom (se permesso da subscription)
- Swipe per eliminare esercizi custom
- Gestione stati vuoti

#### 🔧 Implementazione tecnica:
```dart
class ExercisesBloc extends Bloc<ExercisesEvent, ExercisesState> {
  final WorkoutRepository _workoutRepository;
  
  // Eventi: LoadExercises, FilterExercises, CreateExercise, DeleteExercise
  // Stati: ExercisesLoading, ExercisesLoaded, ExercisesError
  
  Future<void> _onLoadExercises(LoadExercises event, Emitter<ExercisesState> emit) async {
    emit(const ExercisesLoading());
    final result = await _workoutRepository.getAvailableExercises(event.userId);
    // ... gestione risultato
  }
}
```

---

### **FASE 3: Impostazioni Account**

#### 📝 Componenti da creare:
1. **Screen**: `lib/features/account/presentation/screens/account_settings_screen.dart`
2. **Bloc**: `lib/features/account/bloc/account_bloc.dart`
3. **Models**: `lib/features/account/models/user_profile.dart`
4. **Repository**: `lib/features/account/repository/account_repository.dart`
5. **Widgets**: 
   - `lib/shared/widgets/settings_list_tile.dart`
   - `lib/shared/widgets/profile_avatar.dart`
6. **Route**: Aggiungere in `app_router.dart`

#### 🎯 Features da implementare:
- **Profilo Utente**: Nome, email, avatar, data registrazione
- **Preferenze App**: 
  - Tema (scuro/chiaro/auto)
  - Notifiche allenamenti
  - Unità di misura (kg/lbs)
  - Timer recupero automatico
- **Gestione Account**:
  - Cambio password
  - Aggiornamento email
  - Eliminazione account  
- **Informazioni App**: Versione, privacy policy, termini servizio
- **Backup/Restore**: Esporta dati, importa backup

#### 🔧 Struttura settings:
```dart
List<SettingsSection> settingsSections = [
  SettingsSection(
    title: 'Profilo',
    items: [
      SettingsItem(title: 'Informazioni personali', icon: Icons.person),
      SettingsItem(title: 'Abbonamento', icon: Icons.card_membership),
    ],
  ),
  SettingsSection(
    title: 'Preferenze',
    items: [
      SettingsItem(title: 'Tema', icon: Icons.palette),
      SettingsItem(title: 'Notifiche', icon: Icons.notifications),
      SettingsItem(title: 'Unità di misura', icon: Icons.straighten),
    ],
  ),
  // ... altre sezioni
];
```

---

### **FASE 4: Aggiornamenti Dashboard**

#### 🔧 Modifiche a `DashboardPage`:
1. **Count dinamici**:
   - Cronologia: Mostra numero allenamenti completati nell'ultimo mese
   - Impostazioni: Aggiungere indicatore notifiche o aggiornamenti disponibili

2. **Logica count cronologia**:
```dart
BlocBuilder<WorkoutHistoryBloc, WorkoutHistoryState>(
  builder: (context, state) {
    String subtitle = 'Allenamenti';
    if (state is WorkoutHistoryLoaded) {
      final thisMonthWorkouts = state.workoutHistory.where((w) => 
        DateTime.parse(w.dataInizio).isAfter(
          DateTime.now().subtract(const Duration(days: 30))
        )
      ).length;
      subtitle = '$thisMonthWorkouts questo mese';
    }
    return _buildQuickActionCard(subtitle: subtitle, ...);
  },
)
```

---

## 📅 Timeline di Implementazione

### **Sprint 0 (1 giorno)**: Fix Route e Navigazione 🚨
- ✅ Aggiungere route placeholder per `/workouts/history`, `/exercises`, `/settings`  
- ✅ Fix navigazione "Mie Schede" per usare tab invece di route separato
- ✅ Testing navigazione base per tutte e 4 le azioni rapide
- ✅ Verifica che nessuna azione generi più errori

### **Sprint 1 (2-3 giorni)**: Cronologia
- ✅ Implementare `WorkoutHistoryScreen` con data reale
- ✅ Creare widgets per cronologia  
- ✅ Sostituire placeholder route con implementazione vera
- ✅ Aggiornare count dinamico dashboard

### **Sprint 2 (3-4 giorni)**: Esercizi  
- ✅ Implementare `ExercisesScreen` e `ExercisesBloc`
- ✅ Creare sistema filtri e ricerca
- ✅ Implementare creazione esercizi custom
- ✅ Sostituire placeholder route

### **Sprint 3 (4-5 giorni)**: Impostazioni Account
- ✅ Implementare `AccountSettingsScreen` e `AccountBloc`
- ✅ Creare tutti i settings e preferenze
- ✅ Implementare gestione profilo utente
- ✅ Sostituire placeholder route

### **Sprint 4 (1 giorno)**: Rifinitura
- ✅ Testing completo delle 4 azioni rapide
- ✅ Aggiornamenti dashboard
- ✅ Ottimizzazioni UI/UX
- ✅ Fix bug e miglioramenti prestazioni

---

## 🎯 Priorità di Implementazione

1. **🚨 CRITICA**: Fix Route e Navigazione (Sprint 0) - Le azioni causano errori!
2. **🔥 ALTA**: Cronologia (funzionalità core per tracking progressi)
3. **🔶 MEDIA**: Esercizi (utile per gestione e customizzazione)  
4. **🔵 BASSA**: Impostazioni Account (nice-to-have, non blocca funzionalità)

## ⚠️ AZIONE IMMEDIATA RICHIESTA

**Prima di implementare qualsiasi altra feature, dobbiamo fixare Sprint 0** perché attualmente 3 delle 4 azioni rapide causano errori di navigazione quando clickate!

## 🛠️ Quick Fix Proposto

Vuoi che implementi subito lo **Sprint 0** per far funzionare la navigazione base? È un task di 30 minuti che risolve tutti gli errori immediati.

## 📋 File PHP da Richiedere

Hai menzionato di avere già file PHP per cronologia e account. Avremo bisogno di:

1. **Per cronologia**: API endpoints per:
   - `GET /api/workout-history/{userId}` 
   - `DELETE /api/workout-history/{workoutId}`
   - `GET /api/workout-history/{workoutId}/details`

2. **Per account**: API endpoints per:
   - `GET /api/user/profile/{userId}`
   - `PUT /api/user/profile/{userId}`
   - `PUT /api/user/password`
   - `GET /api/user/preferences/{userId}`
   - `PUT /api/user/preferences/{userId}`

Pronto per iniziare con la **Fase 1 - Cronologia**? 🚀