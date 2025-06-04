# 🏋️‍♂️ FitGymTrack - FASE B: Superset/Circuit Grouping

## 📋 **STATO ATTUALE (FASE A ✅ COMPLETATA)**

### **🎯 ActiveWorkoutScreen 2.0 Funzionante:**
- ✅ **Allenamento Fullscreen** con PageView per esercizi singoli
- ✅ **Sistema Serie** - Salvataggio locale + server corretto
- ✅ **Timer Recupero** - 90 secondi tra serie con controllo utente
- ✅ **Progress Tracking** - Contatori 1/3, 2/3, 3/3 funzionanti
- ✅ **BLoC Stabile** - Stati gestiti correttamente (WorkoutSessionActive)
- ✅ **Logging System** - debugPrint() funzionante, developer.log() sostituito

### **🛠️ File Principali Coinvolti:**
```
lib/features/workouts/
├── bloc/active_workout_bloc.dart ✅ STABILE
├── models/
│   ├── active_workout_models.dart
│   └── workout_plan_models.dart ✅ CONTIENE DATI SUPERSET
├── presentation/screens/
│   └── active_workout_screen.dart ✅ FUNZIONANTE - DA ESTENDERE
└── repository/workout_repository.dart ✅ API FUNZIONANTI
```

---

## 🎯 **OBIETTIVO FASE B**

### **🔗 Superset/Circuit Grouping**
Attualmente: **1 esercizio = 1 pagina** nel PageView
**Target FASE B:** **Raggruppare esercizi collegati in 1 pagina**

### **📊 Struttura Dati Esistente (da API):**
```json
{
  "id": 64,
  "nome": "Alzate frontali con manubri",
  "set_type": "superset",        // ← CHIAVE GROUPING
  "linked_to_previous": 0,       // ← 0 = primo del gruppo
  "ordine": 0
},
{
  "id": 89,
  "nome": "Affondi (sec)",
  "set_type": "superset",        // ← STESSO GRUPPO
  "linked_to_previous": 1,       // ← 1 = collegato al precedente
  "ordine": 1
}
```

### **🎨 UI Target:**
```
┌─────────────────────────────────────┐
│ SUPERSET A (1/3 completati)        │
├─────────────────────────────────────┤
│ 💪 Alzate frontali (2/3 serie)     │
│ [Peso: 5kg] [Reps: 10] [Completa]  │
├─────────────────────────────────────┤  
│ 🦵 Affondi (1/3 serie)             │
│ [Peso: 10kg] [Reps: 10] [Completa] │
├─────────────────────────────────────┤
│ ⏱️ Recupero: 90s [Skip]             │
└─────────────────────────────────────┘
```

---

## 📊 **DATI ESISTENTI**

### **WorkoutExercise Model:**
```dart
class WorkoutExercise {
  final int id;
  final String nome;
  final String setType;        // "normal", "superset", "circuit"
  final int linkedToPrevious;  // 0 = primo, 1 = collegato
  final int ordine;
  final int serie;
  final int ripetizioni;
  final double peso;
  final int? tempoRecupero;
  
  // ... resto della classe
}
```

### **Esempi di Raggruppamento:**
```dart
// SUPERSET: Alzate + Affondi
[
  { id: 64, setType: "superset", linkedToPrevious: 0, ordine: 0 },
  { id: 89, setType: "superset", linkedToPrevious: 1, ordine: 1 }
]

// NORMAL: Esercizio singolo
[
  { id: 55, setType: "normal", linkedToPrevious: 0, ordine: 2 }
]

// CIRCUIT: 3 esercizi collegati
[
  { id: 100, setType: "circuit", linkedToPrevious: 0, ordine: 3 },
  { id: 101, setType: "circuit", linkedToPrevious: 1, ordine: 4 },
  { id: 102, setType: "circuit", linkedToPrevious: 1, ordine: 5 }
]
```

---

## 🏗️ **ARCHITETTURA ATTUALE**

### **ActiveWorkoutScreen Structure:**
```dart
class _ActiveWorkoutScreenState {
  // FUNZIONANTE ✅
  int _currentExerciseIndex = 0;        // Index corrente PageView
  PageController _pageController;       // Controller PageView
  Map<int, double> _exerciseWeights;    // Pesi per esercizio
  Map<int, int> _exerciseReps;         // Ripetizioni per esercizio
  bool _isSavingSeries = false;        // Flag salvataggio
  Timer? _recoveryTimer;               // Timer recupero
  
  // DA ESTENDERE 🚀
  // Gestione gruppi di esercizi
  // UI per superset/circuit
  // Timer condiviso tra esercizi gruppo
}
```

### **PageView Attuale:**
```dart
PageView.builder(
  controller: _pageController,
  itemCount: exercises.length,           // 1 pagina = 1 esercizio
  itemBuilder: (context, index) {
    final exercise = exercises[index];   // Esercizio singolo
    return _buildExerciseContent(exercise);
  },
);
```

---

## 🎯 **PIANO FASE B**

### **Step 1: Algoritmo Grouping**
```dart
// NUOVO: Raggruppa esercizi in base a setType + linkedToPrevious
List<ExerciseGroup> _groupExercises(List<WorkoutExercise> exercises) {
  // Logica raggruppamento
}

class ExerciseGroup {
  final String type;              // "normal", "superset", "circuit"
  final List<WorkoutExercise> exercises;
  final int totalSeries;          // Serie totali del gruppo
  final int completedSeries;     // Serie completate del gruppo
}
```

### **Step 2: Nuova UI Componenti**
```dart
// NUOVO: Widget per gruppi
Widget _buildExerciseGroupContent(ExerciseGroup group);
Widget _buildSupersetCard(ExerciseGroup group);
Widget _buildCircuitCard(ExerciseGroup group);
Widget _buildNormalCard(ExerciseGroup group);
```

### **Step 3: Gestione Stato Gruppi**
```dart
// ESTENDERE: State management per gruppi
Map<int, List<CompletedSeriesData>> _groupCompletedSeries;
Map<int, bool> _groupCompletionStatus;
Timer? _groupRecoveryTimer;
```

### **Step 4: PageView Aggiornato**
```dart
// MODIFICARE: PageView per gruppi invece che esercizi singoli
PageView.builder(
  itemCount: exerciseGroups.length,     // 1 pagina = 1 gruppo
  itemBuilder: (context, index) {
    final group = exerciseGroups[index]; // Gruppo di esercizi
    return _buildExerciseGroupContent(group);
  },
);
```

---

## 🚀 **PRIORITÀ IMPLEMENTAZIONE**

### **🥇 Fase B.1: Algoritmo Grouping**
- [ ] Creare `ExerciseGroup` class
- [ ] Implementare `_groupExercises()` method
- [ ] Test logica raggruppamento

### **🥈 Fase B.2: UI Superset Basic**
- [ ] Widget `_buildSupersetCard()` 
- [ ] Layout 2 esercizi in colonna
- [ ] Gestione serie alternate

### **🥉 Fase B.3: Timer & Progress Gruppi**
- [ ] Timer recupero condiviso gruppo
- [ ] Progress tracking livello gruppo
- [ ] Serie completion logic

### **🏆 Fase B.4: Circuit & Polish**
- [ ] Circuit widget (3+ esercizi)
- [ ] Animazioni transizioni
- [ ] Edge cases handling

---

## 📝 **NOTE IMPLEMENTAZIONE**

### **⚠️ Challenges Previsti:**
1. **Timer Recupero:** Condiviso vs individuale
2. **Progress Calculation:** Serie gruppo vs serie singolo esercizio
3. **Navigation:** Index gruppi vs index esercizi
4. **State Management:** Mapping esercizi → gruppi
5. **UI Responsiveness:** Layout dinamico per 2-4 esercizi

### **✅ Vantaggi Architettura Esistente:**
- BLoC già stabile e funzionante
- Sistema serie locale + server robusto
- Logging system completo
- UI componenti riutilizzabili
- Timer system già implementato

---

## 🎯 **SUCCESS CRITERIA FASE B**

### **🏁 Obiettivi Misurabili:**
1. ✅ **Grouping Logic:** Algoritmo raggruppa correttamente superset/circuit
2. ✅ **UI Responsive:** Layout dinamico per 1-4 esercizi per gruppo
3. ✅ **Series Tracking:** Contatori corretti a livello gruppo
4. ✅ **Timer Integration:** Recupero condiviso tra esercizi gruppo
5. ✅ **Backward Compatibility:** Esercizi "normal" funzionano come prima
6. ✅ **Data Persistence:** Salvataggio serie su tutti gli esercizi gruppo

---

## 📁 **FILE DA MODIFICARE/CREARE**

### **🔧 Modifiche Principali:**
- `active_workout_screen.dart` → Aggiungere grouping logic + UI
- Possibile nuovo file: `exercise_group_models.dart`
- Possibile nuovo file: `exercise_group_widgets.dart`

### **🔒 File Stabili (NON toccare):**
- `active_workout_bloc.dart` ✅ 
- `workout_repository.dart` ✅
- `active_workout_models.dart` ✅

---

**🚀 READY FOR FASE B IMPLEMENTATION!**

**Next Steps:** 
1. Aprire nuova chat con questo documento
2. Iniziare con Fase B.1: Algoritmo Grouping
3. Test incrementale ad ogni step