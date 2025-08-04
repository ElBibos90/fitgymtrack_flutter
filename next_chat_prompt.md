📋 DOCUMENTAZIONE COMPLETA - SISTEMA ACTIVE WORKOUT
Per implementazione Flutter - Specifiche Complete di Funzionalità

🔄 PIANO DI AGGIORNAMENTO - STATO ATTUALE

## ✅ FASE 1: SISTEMA IMPOSTAZIONI AUDIO - COMPLETATA
- ✅ Creato `AudioSettingsService` con gestione centralizzata
- ✅ Integrato in Dependency Injection (`getIt`)
- ✅ Implementato `AudioSettingsWidget` nelle impostazioni
- ✅ Persistenza impostazioni con `shared_preferences`
- ✅ Toggle per: Timer Sounds, Haptic Feedback, Audio Ducking
- ✅ Corretti errori di navigazione (`go_router` vs `Navigator.pushNamed`)
- ✅ Corretti errori di colori (`AppColors.primary` → `AppColors.indigo600`)

## ✅ FASE 2: INTEGRAZIONE AUDIO SETTINGS NEI TIMER - COMPLETATA
- ✅ Integrato `AudioSettingsService` in tutti i timer popup:
  - `IsometricTimerPopup`
  - `RecoveryTimerPopup` 
  - `RestPauseTimerPopup`
- ✅ Implementato Audio Ducking per iOS e Android
- ✅ Configurazione `AudioContext` per ducking automatico
- ✅ Ripristino volume musica dopo completamento timer
- ✅ Toggle vibrazione funzionante
- ✅ Controllo volume basato su impostazioni utente

## 🔧 PROBLEMI RISOLTI
- ✅ **Beep fermano musica**: Risolto con Audio Ducking
- ✅ **Sequenza beep pausa**: Corretta (3+1 lungo)
- ✅ **Toggle audio disabilitato**: Implementato e funzionante
- ✅ **Vibrazione sempre attiva**: Risolto con controllo impostazioni
- ✅ **Volume musica non ripristina**: Risolto su iOS (Android da testare)

## 📱 TESTING STATUS
- ✅ **iOS**: Audio ducking funziona, beep si sentono, volume ripristina correttamente
- ⏳ **Android**: Da testare su dispositivo fisico

## ✅ FASE 3: SISTEMA VERSIONING TARGETED - COMPLETATA
- ✅ Database migration con campi `is_tester`, `platform`, `target_audience`
- ✅ API backend (`version.php`) aggiornata per targeting
- ✅ Flutter `AppUpdateService` con controllo tester e piattaforma
- ✅ Script deploy aggiornato con opzioni targeting
- ✅ API client aggiornato per passare parametri targeting

## 🚧 PROSSIMI STEP
- ⏳ **Timer in background**: Il timer della pausa non avanza quando l'app è in background
- ⏳ **Sezioni "Funzionalità in arrivo"**: Notifiche, Aspetto, Lingua
- ⏳ **Sezione Legale**: Analisi e correzione per renderla "perfetta"
- ⏳ **FAQ**: Aggiornamento con domande reali dell'app

## 🎯 PRIORITÀ IMMEDIATE
1. **Eseguire database migration** per attivare il sistema
2. **Test sistema versioning** con deploy di test
3. **Timer in background** - Implementazione per pause timer
4. **Completamento sezioni impostazioni** rimanenti

---

🎯 PANORAMICA GENERALE
Il sistema Active Workout è un'applicazione avanzata per la gestione di allenamenti in tempo reale con funzionalità sofisticate di tracking, analisi plateau, timer intelligenti e interfacce responsive.

🏗️ ARCHITETTURA E STATI
Stati Principali del Sistema
kotlin// Stati dell'allenamento
sealed class ActiveWorkoutState {
    object Idle
    object Loading  
    data class Success(val workout: ActiveWorkout)
    data class Error(val message: String)
}

// Stati delle serie completate
sealed class CompletedSeriesState {
    object Idle
    object Loading
    data class Success(val series: Map<Int, List<CompletedSeries>>)
    data class Error(val message: String)
}

// Altri stati: SaveSeriesState, CompleteWorkoutState
Gestione Dati Persistenti

Storage valori esercizi: Mappa exerciseValues: Map<Int, Pair<Float, Int>>
Serie completate: Mappa per esercizio con lista delle serie
Dati storici: Cache dell'ultimo allenamento per pre-popolamento valori
Timer states: Gestione timer di recupero e isometrici
Plateau detection: Cache e dismissioni


🎮 MODALITÀ DI VISUALIZZAZIONE
1. MODALITÀ MODERNA (ModernActiveWorkoutContent)

Layout a lista scrollabile con card espandibili
Separazione esercizi attivi/completati
Indicatori di progresso per gruppo
Timer di recupero overlay

2. MODALITÀ FULLSCREEN (FullscreenWorkoutContent)

RESPONSIVE DESIGN con 3 breakpoint:

Small Screen (<600dp): Layout compatto scrollabile
Medium Screen (600-800dp): Layout intermedio
Large Screen (>800dp): Layout completo con navigation



Layout Small Screen Features:

Header compatto con progresso
Tutto scrollabile con LazyColumn
Mini navigation floating
Controlli ultra-compatti (peso/reps in una riga)
Timer isometrico semplificato

Layout Large Screen Features:

Header con barra progresso completa
Contenuto fisso con navigazione swipe
Navigation bar completa in fondo
Controlli espansi


🏋️ GESTIONE ESERCIZI E GRUPPI
Tipi di Esercizi
1. Esercizi Singoli (Normal)

Visualizzazione individuale
Timer di recupero indipendente
Progresso serie lineare

2. Superset

Raggruppamento: Esercizi con setType="superset" e linkedToPrevious=true
Navigazione: Tabs per switch tra esercizi del gruppo
Colore tema: Viola (PurplePrimary)
Logica: Esecuzione alternata, timer solo alla fine del gruppo
Progress: Progresso basato sul minimo completato nel gruppo

3. Circuit

Raggruppamento: Come superset ma setType="circuit"
Colore tema: Blu (BluePrimary)
Round indicator: Mostra "Round X/Y"
Timer speciale: Timer isometrico integrato per esercizi isometrici

Algoritmo Raggruppamento Esercizi
kotlinfun groupExercisesByType(exercises: List<WorkoutExercise>): List<List<WorkoutExercise>> {
    // Raggruppa in base a setType e linkedToPrevious
    // Crea gruppi consecutivi per superset/circuit
}

⏱️ SISTEMA TIMER AVANZATO
1. Timer di Recupero

Attivazione: Automatica dopo completamento serie
Durata: Basata su exercise.tempoRecupero
Suoni: Beep ultimi 3 secondi + suono finale
Auto-navigazione: Passa al prossimo esercizio quando completato
UI States:

Normale: Timer blu
Ultimi 3 sec: Timer rosso lampeggiante
Completato: Messaggio di transizione



2. Timer Isometrico

Attivazione: Solo per esercizi con isIsometric=true
Durata: Basata su ripetizioni/secondi dell'esercizio
Auto-completamento: Completa automaticamente la serie a fine timer
Formato tempo: mm:ss
Componenti:

IsometricTimer: Versione completa
CompactIsometricTimer: Versione per gruppi
FullscreenIsometricTimerCompact: Versione fullscreen



3. Timer Globale Allenamento

Tracking: Durata totale dall'inizio
Formato: mm:ss nel header
Persistenza: Continua anche con app in background


🎵 SISTEMA AUDIO
SoundManager Integration
kotlinenum class WorkoutSound {
    SERIES_COMPLETE,      // Serie completata
    TIMER_COMPLETE,       // Timer isometrico finito
    REST_COMPLETE,        // Recupero finito
    WORKOUT_COMPLETE,     // Allenamento completato
    COUNTDOWN_BEEP       // Beep countdown (ultimi 3 sec)
}
Quando si attivano:

Serie completata: Suono immediato
Timer isometrico: Beep ultimi 3 sec + suono finale
Recupero: Beep ultimi 3 sec + suono finale
Allenamento completato: Fanfara


📊 SISTEMA PLATEAU DETECTION
PlateauDetector Logic
kotlinclass PlateauDetector {
    fun detectPlateau(
        exerciseId: Int,
        exerciseName: String,
        currentWeight: Float,
        currentReps: Int,
        historicData: Map<Int, List<CompletedSeries>>,
        minSessionsForPlateau: Int = 2
    ): PlateauInfo?
}
Tipi di Plateau
kotlinenum class PlateauType {
    LIGHT_WEIGHT,    // Peso troppo basso
    HEAVY_WEIGHT,    // Peso troppo alto  
    LOW_REPS,        // Ripetizioni basse
    HIGH_REPS,       // Ripetizioni alte
    MODERATE         // Plateau moderato
}
Sistema Suggerimenti
kotlindata class ProgressionSuggestion(
    val type: SuggestionType,
    val description: String,
    val newWeight: Float,
    val newReps: Int,
    val confidence: Float  // 0.0-1.0
)

enum class SuggestionType {
    INCREASE_WEIGHT,
    INCREASE_REPS,  
    ADVANCED_TECHNIQUE,
    REDUCE_REST,
    CHANGE_TEMPO
}
UI Plateau Components

PlateauBadge: Indicatore discreto arancione
PlateauDetailDialog: Dialog con dettagli e suggerimenti
GroupPlateauDialog: Dialog per plateau multipli in superset/circuit
Dismissione: Possibilità di ignorare plateau specifici


🎨 INTERFACCIA UTENTE DETTAGLIATA
Header Components
ModernActiveWorkoutContent Header:

Progresso lineare con percentuale
Contatore esercizi (X/Y)
Durata allenamento (mm:ss)
Pulsante back con conferma

FullscreenWorkoutContent Header:

Progresso "Esercizio X di Y"
Barra progresso animata
Badge "🎉 Completato!" quando finito

Navigation Systems
Small Screen Mini Navigation:

Surface floating in fondo
Frecce sinistra/destra
Pallini indicatori progresso (completati=blu, corrente=verde, futuri=grigio)

Large Screen Navigation Bar:

Pulsanti "Prec" e "Succ"
Pallini cliccabili per jump diretto
Disabilitazione intelligente

Exercise Controls
Weight/Reps Picker:

WeightPickerDialog: Numeri interi + frazioni (0, 0.125, 0.25, etc.)
RepsPickerDialog: Counter con +/- + valori comuni preimpostati
Distinzione "Ripetizioni" vs "Secondi" per isometrici

Value Display Cards:

Card compatte con icone (💪 peso, 🔄 reps, ⏱️ secondi)
Tap per aprire picker
Formato peso con WeightFormatter.formatWeight()

Series Progress
Indicatori Serie:

Pallini circolari: Verde=completate, Blu=corrente, Grigio=future
Progress bar lineare per gruppi
Contatori "X/Y serie"

Complete Button States:

Normale: "Completa Serie X"
Allenamento finito: "🏁 Completa Allenamento!" (lampeggiante verde)
Disabilitato: Timer attivo o serie già completate


📱 RESPONSIVE DESIGN DETTAGLIATO
Small Screen Optimizations

Compact Controls: Peso+Reps+Serie in una riga
Scrollable: Tutto in LazyColumn
Mini Tabs: Superset tabs ultra-compatti
Simplified Timer: Progress bar invece di cronometro grande
Floating Navigation: Non occupa spazio fisso

Medium/Large Screen Features

Fixed Layout: Header+Content+Navigation fissi
Swipe Navigation: Gesture orizzontali tra esercizi
Expanded Controls: Card separate per ogni valore
Full Timer Display: Timer isometrici con cronometro grande
Rich Navigation: Navigation bar completa


🔄 FLUSSI LOGICI COMPLESSI
Completamento Serie
kotlin// Sequenza completa quando si completa una serie:
1. Salva serie nel database
2. Aggiorna stato locale  
3. Riproduce suono
4. Controlla se superset/circuit → naviga al prossimo esercizio
5. Avvia timer di recupero
6. Ri-controlla plateau
7. Prepara UI per prossima serie
Navigazione Superset/Circuit
kotlin// Logica di auto-navigazione nei gruppi:
1. Completa serie esercizio corrente
2. Se non ultimo del gruppo → passa al successivo
3. Se ultimo del gruppo → torna al primo
4. Se tutti completati → avvia timer di recupero
5. A fine recupero → passa al gruppo successivo
Auto-Navigation Flow
kotlin// Timer di recupero intelligente:
1. Timer finisce
2. Controlla se esercizio corrente completato
3. Se completato + ci sono altri esercizi → naviga automaticamente
4. Se completato + è l'ultimo → mostra dialog completamento
5. Se non completato → si ferma per continuare serie

💾 GESTIONE DATI E PERSISTENZA
Pre-loading Sistema

Default Values: Carica peso/reps dall'esercizio
Historic Values: Sovrascrive con dati ultimo allenamento
Series Continuity: Mantiene valori tra serie dello stesso esercizio

Cache Management

ExerciseValues: Mappa peso/reps per esercizio
CompletedSeries: Mappa serie completate per esercizio
PlateauInfo: Cache plateau rilevati
DismissedPlateaus: Set di plateau ignorati

API Integration
kotlin// Chiamate API principali:
- startWorkout() → Inizia sessione
- getWorkoutExercises() → Carica esercizi
- saveCompletedSeries() → Salva ogni serie
- completeWorkout() → Finalizza allenamento
- getCompletedSeries() → Recupera serie esistenti

🔧 COMPONENTI RIUTILIZZABILI
Dialog Components

WeightPickerDialog: Selezione peso con frazioni
RepsPickerDialog: Selezione ripetizioni con common values
ExitWorkoutDialog: Conferma uscita con warning
CompleteWorkoutDialog: Conferma completamento
PlateauDetailDialog: Dettagli plateau con suggerimenti

Timer Components

RecoveryTimer: Timer recupero tra serie
IsometricTimer: Timer per esercizi isometrici
CompactIsometricTimer: Versione compatta per gruppi

Exercise Display Components

ExerciseProgressItem: Item singolo esercizio
SupersetGroupCard: Card per gruppi superset/circuit
ModernWorkoutGroupCard: Versione moderna gruppi
SequenceExerciseItem: Item in sequenza circuit

UI Helper Components

ValueChip: Chip per valori (peso/reps)
SeriesButton: Pulsante numerato per serie
PlateauBadge: Badge indicatore plateau
WorkoutProgressIndicator: Indicatore progresso generale


🎯 FUNZIONALITÀ AVANZATE
Keep Screen On

Attivazione automatica durante allenamento
Flag WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON

Swipe Gestures (Large Screen)

detectHorizontalDragGestures per navigazione
Threshold configurabile per sensibilità
Supporto solo in modalità fullscreen

Animation System

Progress bar animate con animateFloatAsState
Fade in/out per timer
Slide transitions per cambio esercizio
Blink animation per completamento allenamento

Error Handling

Retry automatico per chiamate API
Graceful degradation senza dati storici
Validazione input utente
Messaggi errore user-friendly


📊 ALGORITMI E CALCOLI
Progresso Allenamento
kotlinfun calculateWorkoutProgress(): Float {
    val completedExercises = exercises.count { 
        isExerciseCompleted(it.id, it.serie) 
    }
    return completedExercises.toFloat() / totalExercises.toFloat()
}
Grouping Algorithm
kotlinfun groupExercisesByType(): List<List<WorkoutExercise>> {
    // Raggruppa esercizi consecutivi con stesso setType e linkedToPrevious
    // Crea liste separate per ogni gruppo (superset/circuit)
}
Plateau Detection Algorithm
kotlin// Analizza dati storici per rilevare plateau:
1. Confronta peso/reps attuali con sessioni precedenti
2. Conta sessioni consecutive con stessi valori  
3. Se >= minSessionsForPlateau → crea PlateauInfo
4. Genera suggerimenti basati su tipo di plateau
5. Calcola confidenza suggerimenti

🏁 FLUSSO COMPLETAMENTO ALLENAMENTO
Condizioni di Completamento
kotlinval isAllWorkoutCompleted = exerciseGroups.all { group ->
    group.all { exercise ->
        val completedSeries = seriesMap[exercise.id] ?: emptyList()
        completedSeries.size >= exercise.serie
    }
}
Sequenza di Completamento

Rilevamento: Controllo automatico dopo ogni serie
UI Feedback: Pulsante lampeggiante + messaggio
Dialog Conferma: "🎉 Fantastico! Hai completato tutti gli esercizi!"
API Call: completeWorkout() con durata totale
Suono: Fanfara di completamento
Success Screen: Schermata riassuntiva con statistiche


🔍 DETTAGLI IMPLEMENTATIVI CRITICI
State Management

Single Source of Truth: ViewModel centralizzato
Reactive Updates: StateFlow per tutti gli stati
Immutable Updates: Copy dei dati per evitare side effects

Memory Management

Lazy Loading: Carica solo dati necessari
Cache Invalidation: Pulizia cache per nuovi allenamenti
Coroutine Scoping: ViewModelScope per operazioni async

Performance Optimizations

Remember: Uso strategico di remember per valori calcolati
LazyColumn: Per liste lunghe di esercizi
Throttling: Limita chiamate API duplicate


Questo documento copre tutte le funzionalità implementate nel sistema Active Workout. Ogni sezione contiene i dettagli necessari per una implementazione fedele in Flutter, mantenendo la stessa esperienza utente e logica di business sofisticata.