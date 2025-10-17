# 🎯 Sistema "Usa Dati Precedenti" - Documentazione Completa

## 📋 Panoramica
Sistema completo per la gestione dei dati precedenti degli allenamenti con toggle "Usa Dati Precedenti" per tutte le tipologie di esercizi.

## 🎯 Funzionalità Implementate

### ✅ Widget Principali
1. **`UsePreviousDataToggle`** - Toggle switch per abilitare/disabilitare
2. **`PreviousDataStatusBadge`** - Badge di stato per dati caricati
3. **`PreviousDataInfoCard`** - Card informativa con dati precedenti
4. **`ExerciseCardLayoutBWithPreviousData`** - Layout B completo con sistema dati precedenti
5. **`PreviousDataManager`** - Gestione stato e logica business

### ✅ Comportamento per Tipologie

#### **Esercizi Singoli**
- ✅ Toggle "Usa dati precedenti" visibile
- ✅ Caricamento automatico peso/ripetizioni per serie corrente
- ✅ Fallback a sistema "vs ultima" se disabilitato

#### **Superset**
- ✅ Toggle funziona per ogni esercizio del superset
- ✅ Dati precedenti specifici per ogni esercizio
- ✅ Warning per completare tutto il gruppo

#### **Circuit**
- ✅ Toggle funziona per ogni esercizio del circuit
- ✅ Dati precedenti specifici per ogni esercizio
- ✅ Warning per completare tutto il gruppo

## 🔧 Logica Implementata

### **Flag ON: "Usa Dati Precedenti"**
```dart
// Carica automaticamente i dati dell'ultimo allenamento
if (usePreviousData && lastWorkoutSeries.containsKey(currentSeries)) {
  final previousSeries = lastWorkoutSeries[currentSeries]!;
  currentWeight = previousSeries.peso;
  currentReps = previousSeries.ripetizioni;
}
```

### **Flag OFF: Sistema "vs ultima"**
```dart
// Mostra indicatori "vs ultima" senza pre-popolare
VsUltimaIndicator(
  serieNumber: currentSeries,
  currentPeso: currentWeight,
  currentRipetizioni: currentReps,
  lastWorkoutSeries: lastWorkoutSeries[currentSeries],
)
```

## 🎨 UI/UX Design

### **Toggle Switch**
- **Icona**: History icon con colore dinamico
- **Testo**: "Usa dati precedenti" con descrizione
- **Stato**: Verde quando attivo, grigio quando disattivo
- **Animazione**: Transizione fluida 300ms

### **Status Badge**
- **Colore**: Verde per dati caricati
- **Icona**: Check circle
- **Testo**: "Dati precedenti caricati"
- **Visibilità**: Solo quando flag ON e dati disponibili

### **Info Card**
- **Layout**: 3 colonne (Peso, Reps, Data)
- **Colore**: Primary 50 background
- **Border**: Primary 200
- **Link**: "Vedi storico" per espandere

## 📊 Gestione Stato

### **PreviousDataManager**
```dart
class PreviousDataManager extends ChangeNotifier {
  bool _usePreviousData = false;
  Map<int, CompletedSeries> _lastWorkoutSeries = {};
  bool _isLoading = false;
  String? _error;
  
  // Metodi principali
  void toggleUsePreviousData();
  void setUsePreviousData(bool value);
  Future<void> loadPreviousData({required int exerciseId, required int userId});
  CompletedSeries? getSeriesData(int serieNumber);
  Map<String, dynamic> getStatistics();
}
```

### **Provider Pattern**
```dart
// Wrapping del widget con provider
PreviousDataProvider(
  manager: _manager,
  child: YourWidget(),
)

// Accesso al manager
final manager = PreviousDataProvider.of(context);
```

## 🚀 Integrazione

### **1. Widget Base**
```dart
ExerciseCardLayoutBWithPreviousData(
  // Parametri base
  exerciseName: 'Panca Piana',
  muscleGroups: ['Petto', 'Tricipiti'],
  weight: currentWeight,
  reps: currentReps,
  currentSeries: currentSeries,
  totalSeries: totalSeries,
  
  // Sistema dati precedenti
  usePreviousData: usePreviousData,
  onUsePreviousDataChanged: (value) {
    setState(() {
      usePreviousData = value;
      if (value) {
        loadPreviousDataForCurrentSeries();
      }
    });
  },
  onDataChanged: (data) {
    setState(() {
      currentWeight = data['peso'];
      currentReps = data['ripetizioni'];
    });
  },
  
  // Dati storici
  lastWorkoutSeries: usePreviousData ? lastWorkoutSeries : null,
)
```

### **2. Caricamento Dati**
```dart
Future<void> loadPreviousDataForCurrentSeries() async {
  final previousSeries = lastWorkoutSeries[currentSeries];
  if (previousSeries != null) {
    setState(() {
      currentWeight = previousSeries.peso;
      currentReps = previousSeries.ripetizioni;
    });
  }
}
```

### **3. Gestione Serie**
```dart
// Quando cambia la serie corrente
void onSeriesChanged(int newSeries) {
  setState(() {
    currentSeries = newSeries;
    if (usePreviousData) {
      loadPreviousDataForCurrentSeries();
    }
  });
}
```

## 🎯 Comportamento per Tipologie

### **Esercizi Singoli**
- Toggle visibile e funzionale
- Caricamento dati per serie corrente
- Fallback a "vs ultima" se disabilitato

### **Superset**
- Toggle per ogni esercizio del gruppo
- Dati precedenti specifici per esercizio
- Warning per completare tutto il gruppo
- Gestione stato per ogni esercizio

### **Circuit**
- Toggle per ogni esercizio del circuito
- Dati precedenti specifici per esercizio
- Warning per completare tutto il circuito
- Gestione stato per ogni esercizio

## 📱 Mobile Optimization

### **Responsive Design**
- Toggle switch ottimizzato per touch
- Card layout adattivo per schermi piccoli
- Touch targets appropriati (44px min)

### **Performance**
- Lazy loading per dati storici
- Caching intelligente
- Memory management ottimizzato

### **Animazioni**
- Transizioni fluide 300ms
- Microinterazioni per feedback
- Gesture recognition ottimizzato

## 🧪 Testing

### **Test Cases**
1. **Toggle ON**: Verifica caricamento dati precedenti
2. **Toggle OFF**: Verifica sistema "vs ultima"
3. **Cambio Serie**: Verifica aggiornamento dati
4. **Tipologie**: Test con singoli, superset, circuit
5. **Error Handling**: Gestione errori di rete

### **Esempi Test**
```dart
// Test con dati mock
final testWidget = PreviousDataIntegrationExample();
await tester.pumpWidget(MaterialApp(home: testWidget));

// Test toggle
await tester.tap(find.byType(Switch));
await tester.pumpAndSettle();

// Verifica caricamento dati
expect(find.text('Dati precedenti caricati'), findsOneWidget);
```

## 🔧 Configurazione

### **Dipendenze**
```yaml
dependencies:
  flutter_screenutil: ^5.8.0
  cached_network_image: ^3.3.0
  http: ^1.1.0
```

### **Import Necessari**
```dart
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/workout_design_system.dart';
import 'use_previous_data_toggle.dart';
import 'exercise_card_layout_b_with_previous_data.dart';
import 'previous_data_manager.dart';
```

## 📈 Metriche di Successo

### **Performance**
- **Loading Time**: < 300ms per caricamento dati
- **Memory Usage**: < 30MB per widget
- **Animation**: 60fps per transizioni

### **User Experience**
- **Usability**: Toggle intuitivo e chiaro
- **Accessibility**: Supporto completo
- **Responsive**: Adattamento schermi

### **Business**
- **Efficiency**: Riduce tempo inserimento dati
- **Flexibility**: Massima scelta per l'utente
- **Engagement**: Migliora esperienza allenamento

## 🎯 Vantaggi del Sistema

### **Per l'Utente**
1. **Efficienza**: Non deve re-inserire i dati se vuole ripetere
2. **Flessibilità**: Può cambiare se vuole provare qualcosa di nuovo
3. **Controllo**: Decide sempre se usare i dati precedenti
4. **Progressione**: Vede subito i miglioramenti possibili

### **Per lo Sviluppo**
1. **Modularità**: Sistema componibile e riutilizzabile
2. **Scalabilità**: Funziona con tutte le tipologie
3. **Manutenibilità**: Codice organizzato e documentato
4. **Testing**: Facile da testare e debuggare

## 🚀 Prossimi Sviluppi

### **Fase 6.1: Note Duali**
- Sistema note trainer + utente
- Integrazione con sistema dati precedenti
- Sincronizzazione real-time

### **Fase 6.2: Dialog Sostituzione**
- Filtri muscoli
- Ricerca avanzata
- Preview esercizio

### **Fase 6.3: Animazioni**
- Confetti al completamento
- Haptic feedback
- Sound effects

## 🐛 Troubleshooting

### **Problemi Comuni**
1. **Dati non caricano**: Verificare API endpoint e permessi
2. **Toggle non funziona**: Controllare gestione stato
3. **UI non responsive**: Verificare flutter_screenutil setup

### **Debug**
```dart
// Abilita logging
print('[DEBUG] Use previous data: $usePreviousData');
print('[DEBUG] Current series: $currentSeries');
print('[DEBUG] Last workout series: $lastWorkoutSeries');
```

## 📚 Risorse

### **Documentazione**
- [Design System](./workout_design_system.dart)
- [API Reference](../features/workouts/data/services/)
- [Entities](../features/workouts/domain/entities/)

### **Esempi**
- [Integration Example](./previous_data_integration_example.dart)
- [Test Widget](./previous_data_integration_example.dart)
- [Manager Test](./previous_data_manager.dart)

---

**Status**: ✅ Implementazione Completata  
**Versione**: 1.0.0  
**Data**: 17 Ottobre 2025  
**Prossimo**: Note Duali Sistema

## 🎉 Risultati Ottenuti

### ✅ **Sistema Completo**
- **Toggle Switch**: Funzionale per tutte le tipologie
- **Logica Condizionale**: ON = carica dati, OFF = "vs ultima"
- **UI Dinamica**: Si adatta al flag in tempo reale
- **Tipologie**: Singoli, Superset, Circuit supportati
- **Performance**: Ottimizzata per mobile

### ✅ **UX Migliorata**
- **Efficienza**: Riduce tempo inserimento dati
- **Flessibilità**: Massima scelta per l'utente
- **Controllo**: L'utente decide sempre
- **Progressione**: Vede subito i miglioramenti

### ✅ **Tecnico**
- **Modularità**: Sistema componibile e riutilizzabile
- **Scalabilità**: Funziona con tutte le tipologie
- **Manutenibilità**: Codice organizzato e documentato
- **Testing**: Facile da testare e debuggare

Il sistema "Usa Dati Precedenti" è ora **completamente implementato** e pronto per l'integrazione! 🚀
