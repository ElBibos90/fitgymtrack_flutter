// lib/features/workouts/presentation/screens/active_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart'; // 🔧 FIX 1: ALWAYS ON
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Core imports
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/simple_recovery_timer.dart';
import '../../../../shared/widgets/isometric_timer_popup.dart';
import '../../../../shared/widgets/parameter_edit_dialog.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/di/dependency_injection.dart';

// BLoC imports
import '../../../../shared/widgets/rest_pause_execution_widget.dart';
import '../../bloc/active_workout_bloc.dart';
import '../../models/active_workout_models.dart';
import '../../models/workout_plan_models.dart';

// 🎯 PLATEAU IMPORTS - STEP 7 (MINIMALE)
import '../../bloc/plateau_bloc.dart';
import '../../models/plateau_models.dart';
import '../../../../shared/widgets/plateau_widgets.dart';

import '../../../../shared/widgets/rest_pause_data_manager.dart';
import '../../../../core/config/app_config.dart';
import '../widgets/offline_status_widget.dart';
import '../../services/connectivity_service.dart';

// 🎨 NUOVI WIDGET MODERNI (17 Ottobre 2025)
import '../../../../shared/widgets/superset_badge.dart';
import '../../../../shared/widgets/exercise_card_layout_b.dart'; // 🔥 NUOVO LAYOUT B

/// 🚀 ActiveWorkoutScreen - SINGLE EXERCISE FOCUSED WITH SUPERSET/CIRCUIT GROUPING + 🎯 PLATEAU DETECTION MINIMALE
/// ✅ STEP 7 COMPLETATO + Dark Theme + Dialogs + Complete Button + Plateau Integration MINIMALE + 🔧 PERFORMANCE FIX
/// 🔧 FIX 1: ALWAYS ON - WakeLock durante allenamento
/// 🔧 FIX 2: PLATEAU - Solo 1 volta, rispetta dismiss
/// 🔧 FIX 3: SUPERSET PAUSE - No timer tra esercizi linkati
/// 🔧 FIX 4: APP LIFECYCLE - Gestione corretta background/foreground
class ActiveWorkoutScreen extends StatefulWidget {
  final int schedaId;
  final String? schedaNome;

  const ActiveWorkoutScreen({
    super.key,
    required this.schedaId,
    this.schedaNome,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver { // 🔧 FIX 4: APP LIFECYCLE

  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  // BLoC references
  late ActiveWorkoutBloc _activeWorkoutBloc;
  late PlateauBloc _plateauBloc; // 🎯 PLATEAU BLOC
  
  // 🚀 NUOVO: Servizio di connettività
  ConnectivityService? _connectivityService;

  // Timer management
  Timer? _workoutTimer;
  Duration _elapsedTime = Duration.zero;
  DateTime? _startTime;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _completeButtonController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _completeButtonAnimation;

  // 🚀 Exercise grouping for superset/circuit
  List<List<WorkoutExercise>> _exerciseGroups = [];
  int _currentGroupIndex = 0;
  int _currentExerciseInGroup = 0;
  PageController _pageController = PageController();

  // Recovery timer popup state
  bool _isRecoveryTimerActive = false;
  int _recoverySeconds = 0;
  String? _currentRecoveryExerciseName;

  // 🔥 Isometric timer popup state
  bool _isIsometricTimerActive = false;
  int _isometricSeconds = 0;
  String? _currentIsometricExerciseName;
  WorkoutExercise? _pendingIsometricExercise;





  // ✏️ Modified parameters storage
  Map<int, double> _modifiedWeights = {};
  Map<int, int> _modifiedReps = {};

  // 🔧 PERFORMANCE FIX: Cache locale per valori UI
  final Map<int, double> _cachedWeights = {};
  final Map<int, int> _cachedReps = {};
  DateTime _lastCacheUpdate = DateTime.now();

  // UI state
  bool _isInitialized = false;
  String _currentStatus = "Inizializzazione...";
  int? _userId;
  
  // 🎯 FASE 5: Sistema "Usa Dati Precedenti" - DEFAULT ON per caricamento automatico
  bool _usePreviousData = true;
  bool _previousDataLoaded = false; // Flag per evitare caricamenti multipli
  Map<int, double> _previousWeights = {}; // Cache dati precedenti
  Map<int, int> _previousReps = {}; // Cache dati precedenti
  Map<int, int> _previousSeriesNumber = {}; // Cache serie number precedenti

  // 🆕 Dialog state
  bool _showExitDialog = false;
  bool _showCompleteDialog = false;

  // ============================================================================
  // 🎯 FASE 5: Sistema "Usa Dati Precedenti"
  // ============================================================================
  
  void _loadPreviousData(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    // //debugPrint('[STORICO] Caricamento dati precedenti per esercizio ID: $exerciseId');
    // //debugPrint('[STORICO] Esercizio: ${exercise.nome}');
    
    // Calcola la serie corrente
    final currentState = _getCurrentState();
    if (currentState == null) {
      // //debugPrint('[STORICO] ERRORE: Stato corrente nullo');
      return;
    }
    
    final completedSeriesCount = _getCompletedSeriesCount(currentState, exerciseId);
    final currentSeriesNumber = (completedSeriesCount + 1).clamp(1, exercise.serie);
    
    // //debugPrint('[STORICO] Serie corrente: $currentSeriesNumber (completate: $completedSeriesCount)');
    // //debugPrint('[STORICO] Serie totali esercizio: ${exercise.serie}');
    
    // 🎯 FASE 5: Carica i dati per la serie corrente (quella che devi fare ora)
    // //debugPrint('[STORICO] Caricamento dati storici per serie corrente: $currentSeriesNumber');
    
    // 🎯 FASE 5: Verifica se il BLoC ha dati storici caricati
    // //debugPrint('[STORICO] 🔍 DEBUG: Verifica dati storici nel BLoC per esercizio $exerciseId, serie $currentSeriesNumber');
    
    // 🎯 FASE 5: Recupera dati reali dallo storico tramite BLoC
    final historicValues = _activeWorkoutBloc.getValuesForSeries(exerciseId, currentSeriesNumber);
    
    // //debugPrint('[STORICO] 🔍 DEBUG: historicValues.isFromHistory = ${historicValues.isFromHistory}');
    // //debugPrint('[STORICO] 🔍 DEBUG: historicValues.weight = ${historicValues.weight}');
    // //debugPrint('[STORICO] 🔍 DEBUG: historicValues.reps = ${historicValues.reps}');
    
    final double lastWeight;
    final int lastReps;
    
    if (historicValues.isFromHistory && historicValues.weight > 0) {
      // Usa i dati storici reali dal database
      lastWeight = historicValues.weight;
      lastReps = historicValues.reps;
      // //debugPrint('[STORICO] ✅ Dati REALI dal database: $lastWeight kg x $lastReps reps (Serie $currentSeriesNumber)');
    } else {
      // Fallback: usa i valori di default dell'esercizio
      lastWeight = exercise.peso;
      lastReps = exercise.ripetizioni;
      // //debugPrint('[STORICO] ⚠️ ATTENZIONE: Nessun dato storico trovato (isFromHistory=${historicValues.isFromHistory}, weight=${historicValues.weight})');
      // //debugPrint('[STORICO] ⚠️ Uso valori default dell\');
    }
    
    setState(() {
      _previousWeights[exerciseId] = lastWeight;
      _previousReps[exerciseId] = lastReps;
      _previousSeriesNumber[exerciseId] = currentSeriesNumber;
    });
    
    // //debugPrint('[STORICO] Dati precedenti caricati: $lastWeight kg x $lastReps reps (Serie $currentSeriesNumber)');
    // //debugPrint('[STORICO] Cache aggiornata per esercizio $exerciseId');
  }
  
  void _clearPreviousData(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    //debugPrint('[PARAM] Pulizia dati precedenti per esercizio ID: $exerciseId');
    
    setState(() {
      _previousWeights.remove(exerciseId);
      _previousReps.remove(exerciseId);
      _previousSeriesNumber.remove(exerciseId);
    });
    
    //debugPrint('[PARAM] Dati precedenti rimossi, tornando ai valori del DB');
  }
  
  void _loadPreviousDataForComparison(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    // //debugPrint('[STORICO] Caricamento dati precedenti per confronto - esercizio ID: $exerciseId');
    // //debugPrint('[STORICO] Esercizio: ${exercise.nome}');
    
    // Calcola la serie corrente
    final currentState = _getCurrentState();
    if (currentState == null) {
      // //debugPrint('[STORICO] ERRORE: Stato corrente nullo per confronto');
      return;
    }
    
    final completedSeriesCount = _getCompletedSeriesCount(currentState, exerciseId);
    final currentSeriesNumber = (completedSeriesCount + 1).clamp(1, exercise.serie);
    
    // //debugPrint('[STORICO] Serie corrente per confronto: $currentSeriesNumber (completate: $completedSeriesCount)');
    // //debugPrint('[STORICO] Serie totali esercizio: ${exercise.serie}');
    
    // 🎯 FASE 5: Carica i dati per la serie corrente (quella che devi fare ora)
    // //debugPrint('[STORICO] Caricamento dati storici per confronto serie corrente: $currentSeriesNumber');
    
    // 🎯 FASE 5: Recupera dati reali dallo storico tramite BLoC (per confronto)
    final historicValues = _activeWorkoutBloc.getValuesForSeries(exerciseId, currentSeriesNumber);
    
    final double lastWeight;
    final int lastReps;
    
    if (historicValues.isFromHistory && historicValues.weight > 0) {
      // Usa i dati storici reali dal database
      lastWeight = historicValues.weight;
      lastReps = historicValues.reps;
      // //debugPrint('[STORICO] Dati REALI dal database per confronto: $lastWeight kg x $lastReps reps (Serie $currentSeriesNumber)');
    } else {
      // Fallback: usa i valori di default dell'esercizio
      lastWeight = exercise.peso;
      lastReps = exercise.ripetizioni;
      // //debugPrint('[STORICO] ATTENZIONE: Nessun dato storico per confronto, uso valori default: $lastWeight kg x $lastReps reps');
    }
    
    setState(() {
      _previousWeights[exerciseId] = lastWeight;
      _previousReps[exerciseId] = lastReps;
      _previousSeriesNumber[exerciseId] = currentSeriesNumber;
    });
    
    // //debugPrint('[STORICO] Dati precedenti caricati per confronto: $lastWeight kg x $lastReps reps (Serie $currentSeriesNumber)');
    // //debugPrint('[STORICO] Cache aggiornata per confronto esercizio $exerciseId');
  }
  
  void _loadPreviousDataForComparisonIfNeeded() {
    // //debugPrint('[STORICO] === INIZIO CARICAMENTO DATI PRECEDENTI ===');
    // //debugPrint('[STORICO] Toggle usePreviousData: $_usePreviousData');
    
    // Ottieni l'esercizio corrente dallo stato del BLoC
    final state = _activeWorkoutBloc.state;
    WorkoutExercise? currentExercise;
    
    if (state is WorkoutSessionActive) {
      // //debugPrint('[STORICO] Stato WorkoutSessionActive trovato con ${state.exercises.length} esercizi');
      // Per esercizio singolo, usa il primo esercizio
      if (state.exercises.isNotEmpty) {
        currentExercise = state.exercises.first;
        // //debugPrint('[STORICO] Esercizio corrente: ${currentExercise.nome} (ID: ${currentExercise.schedaEsercizioId ?? currentExercise.id})');
      } else {
        // //debugPrint('[STORICO] ERRORE: Nessun esercizio trovato nello stato');
      }
    } else {
      // //debugPrint('[STORICO] ERRORE: Stato non è WorkoutSessionActive: ${state.runtimeType}');
    }
    
    if (currentExercise != null) {
      final exerciseId = currentExercise.schedaEsercizioId ?? currentExercise.id;
      // //debugPrint('[STORICO] Esercizio ID: $exerciseId');
      // //debugPrint('[STORICO] Cache già presente: ${_previousWeights.containsKey(exerciseId)}');
      
      // Carica solo se non già caricato
      if (!_previousWeights.containsKey(exerciseId)) {
        if (_usePreviousData) {
          // //debugPrint('[STORICO] Toggle ON: Caricamento dati precedenti per uso diretto');
          _loadPreviousData(currentExercise);
        } else {
          // //debugPrint('[STORICO] Toggle OFF: Caricamento dati per confronto "vs scorsa"');
          _loadPreviousDataForComparison(currentExercise);
        }
      } else {
        // //debugPrint('[STORICO] Dati già presenti in cache, skip caricamento');
      }
    } else {
      // //debugPrint('[STORICO] ERRORE: Nessun esercizio corrente trovato');
    }
    
    // //debugPrint('[STORICO] === FINE CARICAMENTO DATI PRECEDENTI ===');
  }
  
  void _loadPreviousDataForAllExercises(WorkoutSessionActive state) {
    // //debugPrint('[STORICO] === INIZIO CARICAMENTO DATI PRECEDENTI PER TUTTI GLI ESERCIZI ===');
    // //debugPrint('[STORICO] Toggle usePreviousData: $_usePreviousData');
    // //debugPrint('[STORICO] Numero esercizi: ${state.exercises.length}');
    
    // ⏰ IMPORTANTE: Aspetta che il BLoC finisca di caricare lo storico
    // Il BLoC carica lo storico in modo asincrono, quindi aspettiamo un po'
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      // //debugPrint('[STORICO] ⏰ Delay completato, ora carico i dati precedenti dal BLoC');
      
      for (int i = 0; i < state.exercises.length; i++) {
        final exercise = state.exercises[i];
        final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
        
        // //debugPrint('[STORICO] Esercizio ${i + 1}: ${exercise.nome} (ID: $exerciseId)');
        
        // Carica solo se non già caricato
        if (!_previousWeights.containsKey(exerciseId)) {
          if (_usePreviousData) {
            // //debugPrint('[STORICO] Toggle ON: Caricamento dati precedenti per uso diretto');
            _loadPreviousData(exercise);
          } else {
            // //debugPrint('[STORICO] Toggle OFF: Caricamento dati per confronto "vs scorsa"');
            _loadPreviousDataForComparison(exercise);
          }
        } else {
          // //debugPrint('[STORICO] Dati già presenti in cache per esercizio $exerciseId, skip');
        }
      }
      
      // //debugPrint('[STORICO] === FINE CARICAMENTO DATI PRECEDENTI PER TUTTI GLI ESERCIZI ===');
    });
  }
  
  String _getPreviousDataText(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    
    if (_previousWeights.containsKey(exerciseId) && _previousReps.containsKey(exerciseId) && _previousSeriesNumber.containsKey(exerciseId)) {
      final weight = _previousWeights[exerciseId]!;
      final reps = _previousReps[exerciseId]!;
      final seriesNumber = _previousSeriesNumber[exerciseId]!;
      return 'vs scorsa: $weight kg x $reps reps - Serie $seriesNumber';
    }
    
    return 'vs scorsa';
  }
  

  // ============================================================================
  // 🚀 ENHANCED TIMER - Helper methods per superset detection
  // ============================================================================

  WorkoutExercise? _getCurrentExercise() {
    final currentState = _activeWorkoutBloc.state;
    if (currentState is WorkoutSessionActive) {
      if (_exerciseGroups.isNotEmpty && 
          _currentGroupIndex < _exerciseGroups.length &&
          _currentExerciseInGroup < _exerciseGroups[_currentGroupIndex].length) {
        return _exerciseGroups[_currentGroupIndex][_currentExerciseInGroup];
      }
    }
    return null;
  }

  bool _isPartOfMultiExerciseGroup(WorkoutExercise? exercise) {
    if (exercise == null) return false;
    return _exerciseGroups.any((group) => 
        group.length > 1 && group.any((e) => e.id == exercise.id));
  }

  bool _isLastExerciseInGroup(WorkoutExercise? exercise) {
    if (exercise == null) return false;
    for (var group in _exerciseGroups) {
      if (group.length > 1 && group.any((e) => e.id == exercise.id)) {
        return group.last.id == exercise.id;
      }
    }
    return false;
  }

  String? _getCurrentWorkoutType() {
    if (_exerciseGroups.isNotEmpty && _currentGroupIndex < _exerciseGroups.length) {
      final group = _exerciseGroups[_currentGroupIndex];
      if (group.length > 1) {
        // 🔧 FIX: Usa il setType reale del primo esercizio del gruppo
        final groupType = group.first.setType;
        switch (groupType) {
          case 'superset':
            return 'Superset';
          case 'circuit':
            return 'Circuit';
          case 'dropset':
            return 'Dropset';
          case 'giant_set':
            return 'Giant Set';
          default:
            // Fallback per tipi non riconosciuti
            return 'Superset';
        }
      }
    }
    return null;
  }

  // 🔧 FIX 2: PLATEAU - Gestione corretta con dismiss e single trigger
  bool _plateauAnalysisTriggered = false;
  final Set<int> _plateauAnalyzedExercises = {}; // Track analyzed exercises
  final Set<int> _dismissedPlateauExercises = {}; // Track dismissed plateaus

  // 🔧 FIX 4: APP LIFECYCLE - Stato background
  bool _isAppInBackground = false;

  // 🚀 NUOVO: Stato per indicatore di transizione auto-rotazione
  bool _isAutoRotating = false;
  String? _nextExerciseName;
  late AnimationController _rotationIndicatorController;
  late Animation<double> _rotationIndicatorAnimation;

  @override
  void initState() {
    super.initState();
    //debugPrint("🚀 [SINGLE EXERCISE + ALL FIXES] initState - Scheda: ${widget.schedaId}");

    // 🔧 FIX 4: APP LIFECYCLE - Observer registration
    WidgetsBinding.instance.addObserver(this);

    _activeWorkoutBloc = context.read<ActiveWorkoutBloc>();
    _plateauBloc = context.read<PlateauBloc>(); // 🎯 INITIALIZE PLATEAU BLOC
    
    // 🚀 NUOVO: Inizializza servizio di connettività
    _connectivityService = ConnectivityService(workoutBloc: _activeWorkoutBloc);
    
    _initializeAnimations();
    _initializeWorkout();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 🎯 FASE 5: Carica dati precedenti se toggle ON (default), o per confronto se OFF
    // RIMOSSO: Causava loop infinito
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted) {
    //     _loadPreviousDataForComparisonIfNeeded();
    //   }
    // });
  }

  bool _isRestPauseExercise(WorkoutExercise exercise) {
    return exercise.isRestPause &&
        exercise.restPauseReps != null &&
        exercise.restPauseReps!.isNotEmpty;
  }

  /// 🚀 STEP 1: Helper per parsare sequenza ripetizioni
  List<int> _parseRestPauseSequence(String? sequence) {
    if (sequence == null || sequence.isEmpty) {
      //debugPrint('⚠️ [REST-PAUSE] Empty sequence, returning empty list');
      return [];
    }

    try {
      final parsed = sequence.split('+').map((s) => int.tryParse(s.trim()) ?? 0).toList();
      //debugPrint('🔥 [REST-PAUSE] Parsed sequence "$sequence" -> $parsed');
      return parsed.where((n) => n > 0).toList(); // Rimuovi valori invalidi
    } catch (e) {
      //debugPrint('💥 [REST-PAUSE] Error parsing sequence "$sequence": $e');
      return [];
    }
  }

  bool _isValidRestPauseSequence(List<int> sequence) {
    final isValid = sequence.isNotEmpty &&
        sequence.length >= 2 &&
        sequence.every((n) => n > 0 && n <= 50); // Massimo 50 reps per micro-serie

    //debugPrint('🔥 [REST-PAUSE] Sequence validation: $sequence -> $isValid');
    return isValid;
  }

  @override
  void dispose() {
    //debugPrint("🚀 [SINGLE EXERCISE + ALL FIXES] dispose");

    // 🔧 FIX 1: ALWAYS ON - Disable wakelock on dispose
    _disableWakeLock();

    // 🔧 FIX 4: APP LIFECYCLE - Observer removal
    WidgetsBinding.instance.removeObserver(this);

    _workoutTimer?.cancel();
    _slideController.dispose();
    _pulseController.dispose();
    _completeButtonController.dispose();
    _rotationIndicatorController.dispose(); // 🚀 NUOVO: Dispose del controller di rotazione
    _pageController.dispose();
    
    // 🔧 FIX: Ferma timer di recupero solo se il widget è ancora montato
    if (mounted) {
      _stopRecoveryTimer();
    }
    
    // 🚀 NUOVO: Dispose del servizio di connettività
    _connectivityService?.dispose();
    
    super.dispose();
  }

  // 🔧 FIX 4: APP LIFECYCLE - Handle app state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    //debugPrint("🔧 [APP LIFECYCLE] State changed to: $state");

    switch (state) {
      case AppLifecycleState.resumed:
        if (_isAppInBackground) {
          //debugPrint("🔧 [APP LIFECYCLE] App resumed from background - refreshing workout state");
          _isAppInBackground = false;
          _handleAppResume();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _isAppInBackground = true;
        //debugPrint("🔧 [APP LIFECYCLE] App going to background");
        break;
      case AppLifecycleState.detached:
        _disableWakeLock();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  // 🔧 FIX 4: APP LIFECYCLE - Handle app resume
  void _handleAppResume() {
    // Evita schermo azzurro verificando stato corrente
    final currentState = _activeWorkoutBloc.state;
    if (currentState is WorkoutSessionActive) {
      //debugPrint("🔧 [APP LIFECYCLE] Valid workout state found - continuing");
      // Riavvia timer se necessario
      if (_workoutTimer == null && _startTime != null) {
        _startWorkoutTimer();
      }
      // Riabilita wake lock
      _enableWakeLock();
    } else {
      //debugPrint("🔧 [APP LIFECYCLE] Invalid state detected - refreshing");
      setState(() {
        _currentStatus = "Ripristinando allenamento...";
      });
      // 🚀 NUOVO: Prova a ripristinare allenamento offline SOLO se non siamo già in un allenamento
      if (currentState is! OfflineRestoreInProgress && 
          currentState is! OfflineSyncInProgress) {
        _tryRestoreOfflineWorkout();
      }
    }
  }

  // 🚀 NUOVO: Ripristina allenamento offline se disponibile
  Future<void> _tryRestoreOfflineWorkout() async {
    try {
      final stats = await _activeWorkoutBloc.getOfflineStats();
      final hasOfflineWorkout = stats['has_offline_workout'] == true;
      
      if (hasOfflineWorkout) {
        //debugPrint('[CONSOLE] [active_workout_screen] 📱 Found offline workout, attempting restore...');
        _activeWorkoutBloc.restoreOfflineWorkout();
      }
    } catch (e) {
      //debugPrint('[CONSOLE] [active_workout_screen] ❌ Error checking offline workout: $e');
    }
  }

  // 🔧 FIX 1: ALWAYS ON - WakeLock methods
  Future<void> _enableWakeLock() async {
    try {
      await WakelockPlus.enable();
      //debugPrint("🔧 [ALWAYS ON] WakeLock enabled successfully");
    } catch (e) {
      //debugPrint("🔧 [ALWAYS ON] Error enabling WakeLock: $e");
    }
  }

  Future<void> _disableWakeLock() async {
    try {
      await WakelockPlus.disable();
      //debugPrint("🔧 [ALWAYS ON] WakeLock disabled successfully");
    } catch (e) {
      //debugPrint("🔧 [ALWAYS ON] Error disabling WakeLock: $e");
    }
  }

  void _handleRestPauseStart(WorkoutSessionActive state, WorkoutExercise exercise) {
    //debugPrint('🔥 [REST-PAUSE] Opening REST-PAUSE widget for: ${exercise.nome}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.all(8.w),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: RestPauseExecutionWidget(
            exerciseName: exercise.nome,
            restPauseSequence: exercise.restPauseReps ?? "10",
            restSeconds: exercise.restPauseRestSeconds,
            currentWeight: _getEffectiveWeight(exercise),
            currentSeries: (_getCompletedSeriesCount(state, exercise.schedaEsercizioId ?? exercise.id) + 1).clamp(1, exercise.serie),
            totalSeries: exercise.serie,
            onCompleteAllMicroSeries: (data) {
              Navigator.of(context).pop();

              // 🚀 SALVATAGGIO COMPLETO con dati REST-PAUSE
              final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
              final completedCount = _getCompletedSeriesCount(state, exerciseId);

              final seriesData = SeriesData(
                schedaEsercizioId: exerciseId,
                peso: data.weight,
                ripetizioni: data.totalActualReps,
                completata: 1,
                tempoRecupero: exercise.tempoRecupero,
                note: 'REST-PAUSE: ${data.actualSequence} (${data.totalActualReps} reps totali)',
                serieNumber: completedCount + 1,
                serieId: 'rest_pause_${DateTime.now().millisecondsSinceEpoch}',
                // 🚀 CAMPI REST-PAUSE
                isRestPause: 1,
                restPauseReps: data.actualSequence,
                restPauseRestSeconds: data.restSeconds,
              );

              _activeWorkoutBloc.addLocalSeries(exerciseId, seriesData);
              _activeWorkoutBloc.saveSeries(state.activeWorkout.id, [seriesData], 'rest_pause_${DateTime.now().millisecondsSinceEpoch}');

              // 🔧 PERFORMANCE FIX: Invalida cache dopo completamento serie
              _invalidateCacheForExercise(exerciseId);

              // 🔧 PERFORMANCE FIX: Rimosso messaggio di completamento serie per migliorare performance
              // CustomSnackbar.show(
              //   context,
              //   message: "🔥 REST-PAUSE Serie ${completedCount + 1} completata!\nSequenza: ${data.actualSequence}\nTotale: ${data.totalActualReps} reps",
              //   isSuccess: true,
              //   duration: const Duration(seconds: 4),
              // );

              //debugPrint("🚀 [REST-PAUSE] Series saved with data:");
              //debugPrint("🚀 [REST-PAUSE]   - isRestPause: 1");
              //debugPrint("🚀 [REST-PAUSE]   - restPauseReps: '${data.actualSequence}'");
              //debugPrint("🚀 [REST-PAUSE]   - restPauseRestSeconds: ${data.restSeconds}");
              //debugPrint("🚀 [REST-PAUSE]   - ripetizioni: ${data.totalActualReps}");

              // 🔧 FIX: Aggiungi logica auto-rotation per REST-PAUSE
              final updatedState = _getCurrentState();
              if (updatedState != null) {
                // Gestione timer di recupero (se appropriato)
                if (exercise.tempoRecupero > 0 && _shouldStartRecoveryTimer(exercise)) {
                  _startRecoveryTimer(exercise.tempoRecupero, exercise.nome);
                } else if (_isPartOfMultiExerciseGroup(exercise)) {
                  //debugPrint("🔧 [REST-PAUSE SUPERSET FIX] Skipping recovery timer for ${exercise.nome} - part of multi-exercise group");
                }

                // 🚀 AUTO-ROTAZIONE: Passa al prossimo esercizio se in un gruppo
                _handleAutoRotation(updatedState);

                // Controllo completamento allenamento
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted && _isWorkoutCompleted(updatedState)) {
                    _completeButtonController.repeat(reverse: true);
                  }
                });
              } else {
                //debugPrint("⚠️ [REST-PAUSE] Could not get updated state for auto-rotation");
              }
            },
            onCompleteMicroSeries: (data, index, reps) {
              //debugPrint('🔥 [REST-PAUSE] Micro-serie ${index + 1} completata: $reps reps');
              //debugPrint('🔥 [REST-PAUSE] Progresso attuale: ${data.actualSequence}');
            },
          ),
        ),
      ),
    );
  }

  void _handleCompleteRestPauseSeries(
      WorkoutSessionActive state,
      WorkoutExercise exercise,
      RestPauseExecutionData restPauseData
      ) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    final completedCount = _getCompletedSeriesCount(state, exerciseId);

    if (completedCount >= exercise.serie) {
      CustomSnackbar.show(
        context,
        message: "Esercizio già completato!",
        isSuccess: false,
      );
      return;
    }

    //debugPrint("🚀 [REST-PAUSE] Completing REST-PAUSE series ${completedCount + 1} for exercise: ${exercise.nome}");
    //debugPrint("🚀 [REST-PAUSE] Data: ${restPauseData.toString()}");

    // Validazione dati REST-PAUSE
    if (!restPauseData.isValid() || !restPauseData.isCompleted) {
      //debugPrint("❌ [REST-PAUSE] Invalid or incomplete data");
      CustomSnackbar.show(
        context,
        message: "Errore nei dati REST-PAUSE",
        isSuccess: false,
      );
      return;
    }

    // 🚀 STEP 4: Crea SeriesData con campi REST-PAUSE corretti (versione semplificata)
    final seriesData = SeriesData(
      schedaEsercizioId: exerciseId,
      peso: restPauseData.weight,
      ripetizioni: restPauseData.totalActualReps, // Somma di tutte le micro-serie
      completata: 1,
      tempoRecupero: exercise.tempoRecupero,
      note: restPauseData.toNote(), // Note dettagliate con durata
      serieNumber: completedCount + 1,
      serieId: 'rest_pause_${DateTime.now().millisecondsSinceEpoch}',
      // 🚀 CAMPI REST-PAUSE
      isRestPause: 1,
      restPauseReps: restPauseData.actualSequence, // Sequenza effettiva (es. "11+4+4")
      restPauseRestSeconds: restPauseData.restSeconds,
    );

    // Salva nel BLoC
    _activeWorkoutBloc.addLocalSeries(exerciseId, seriesData);

    final requestId = 'rest_pause_req_${DateTime.now().millisecondsSinceEpoch}';
    _activeWorkoutBloc.saveSeries(
      state.activeWorkout.id,
      [seriesData],
      requestId,
    );

    // 🔧 PERFORMANCE FIX: Invalida cache dopo completamento serie
    _invalidateCacheForExercise(exerciseId);

    // 🔧 PERFORMANCE FIX: Rimosso messaggio di completamento REST-PAUSE per migliorare performance
    // CustomSnackbar.show(
    //   context,
    //   message: "🔥 REST-PAUSE Serie ${completedCount + 1} completata!\n" +
    //       "Sequenza: ${restPauseData.actualSequence}\n" +
    //       "Totale: ${restPauseData.totalActualReps} reps",
    //   isSuccess: true,
    //   duration: const Duration(seconds: 4), // Più lungo per mostrare dettagli
    // );

    // Log dettagliato per debug
    //debugPrint("🚀 [REST-PAUSE] Series saved:");
    //debugPrint("🚀 [REST-PAUSE]   - Weight: ${restPauseData.weight}kg");
    //debugPrint("🚀 [REST-PAUSE]   - Total reps: ${restPauseData.totalActualReps}");
    //debugPrint("🚀 [REST-PAUSE]   - Sequence: ${restPauseData.actualSequence}");
    //debugPrint("🚀 [REST-PAUSE]   - Rest seconds: ${restPauseData.restSeconds}");
    //debugPrint("🚀 [REST-PAUSE]   - Duration: ${restPauseData.totalDuration?.inSeconds ?? 0}s");

    // Gestione completamento esercizio e recupero normale
    final newCompletedCount = completedCount + 1;
    if (newCompletedCount >= exercise.serie) {
      //debugPrint("🎉 [REST-PAUSE] Esercizio ${exercise.nome} completato!");
    } else {
      // Avvia timer di recupero normale tra serie (se esiste il metodo)
      try {
        // Usa il metodo esistente per recovery timer se disponibile
        if (exercise.tempoRecupero > 0) {
          //debugPrint("🔄 [REST-PAUSE] Starting recovery timer: ${exercise.tempoRecupero}s");
          // TODO: Implementare timer recovery se necessario
        }
      } catch (e) {
        //debugPrint("⚠️ [REST-PAUSE] Recovery timer not available: $e");
      }
    }
  }


  bool _validateRestPauseData(RestPauseExecutionData data) {
    if (!data.isValid()) {
      //debugPrint("❌ [REST-PAUSE] Data validation failed: invalid data");
      return false;
    }

    if (!data.isCompleted) {
      //debugPrint("❌ [REST-PAUSE] Data validation failed: not completed");
      return false;
    }

    if (data.totalActualReps <= 0) {
      //debugPrint("❌ [REST-PAUSE] Data validation failed: no reps completed");
      return false;
    }

    if (data.actualSequence.isEmpty) {
      //debugPrint("❌ [REST-PAUSE] Data validation failed: empty sequence");
      return false;
    }

    return true;
  }

  // ============================================================================
  // 🔧 PERFORMANCE FIX: METODI DI CACHING (unchanged)
  // ============================================================================

  // 🔥 FASE 6: Note Duali - Aggiorna nota utente
  void _updateUserNote(WorkoutExercise exercise, String note) async {
    try {
      // //debugPrint('🔥 [NOTES] Aggiornamento nota utente per ${exercise.nome}: $note');
      
      final schedaEsercizioId = exercise.schedaEsercizioId ?? exercise.id;
      
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/schede.php?action=update_notes&id=${widget.schedaId}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'scheda_esercizio_id': schedaEsercizioId,
          'note_type': 'user',
          'note_text': note,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // //debugPrint('🔥 [NOTES] Nota utente salvata con successo');
        } else {
          // //debugPrint('🔥 [NOTES] Errore nel salvataggio: ${data['message']}');
        }
      } else {
        // //debugPrint('🔥 [NOTES] Errore HTTP: ${response.statusCode}');
      }
    } catch (e) {
      // //debugPrint('🔥 [NOTES] Errore nella chiamata API: $e');
    }
  }

  /// Aggiorna la cache locale per un esercizio specifico
  void _updateCacheForExercise(int exerciseId, WorkoutExercise exercise) {
    final now = DateTime.now();

    // Solo se sono passati almeno 500ms dall'ultimo update
    if (now.difference(_lastCacheUpdate).inMilliseconds < 500) {
      return;
    }

    // 1. PRIORITÀ: Valori modificati dall'utente
    if (_modifiedWeights.containsKey(exerciseId)) {
      _cachedWeights[exerciseId] = _modifiedWeights[exerciseId]!;
    } else {
      // 2. SERIE-SPECIFIC: Chiama BLoC solo se non in cache
      if (!_cachedWeights.containsKey(exerciseId)) {
        final currentState = _getCurrentState();
        if (currentState != null) {
          final completedSeriesCount = _getCompletedSeriesCount(currentState, exerciseId);
          final currentSeriesNumber = (completedSeriesCount + 1).clamp(1, exercise.serie);

          final seriesSpecificValues = _activeWorkoutBloc.getValuesForSeries(exerciseId, currentSeriesNumber);
          _cachedWeights[exerciseId] = seriesSpecificValues.weight;
          _cachedReps[exerciseId] = seriesSpecificValues.reps;
        }
      }
    }

    if (_modifiedReps.containsKey(exerciseId)) {
      _cachedReps[exerciseId] = _modifiedReps[exerciseId]!;
    }

    _lastCacheUpdate = now;
  }

  /// Ottiene peso efficace con cache
  double _getEffectiveWeight(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;

    // 🔧 FIX: PRIORITÀ ASSOLUTA - Valori modificati dall'utente (sopra TUTTO)
    if (_modifiedWeights.containsKey(exerciseId)) {
      final weight = _modifiedWeights[exerciseId]!;
      _cachedWeights[exerciseId] = weight;
      return weight;
    }

    // 🎯 FASE 5: PRIORITÀ MASSIMA - Dati precedenti se toggle ON
    if (_usePreviousData && _previousWeights.containsKey(exerciseId)) {
      return _previousWeights[exerciseId]!;
    }

    // 🔧 PERFORMANCE FIX: Usa cache se disponibile
    if (_cachedWeights.containsKey(exerciseId)) {
      return _cachedWeights[exerciseId]!;
    }

    // 2. SERIE-SPECIFIC: Valori storici per la serie corrente
    final currentState = _getCurrentState();
    if (currentState != null) {
      final completedSeriesCount = _getCompletedSeriesCount(currentState, exerciseId);
      final currentSeriesNumber = (completedSeriesCount + 1).clamp(1, exercise.serie); // Prossima serie da fare

      // 🔧 PERFORMANCE FIX: Log ridotto
      if (DateTime.now().millisecondsSinceEpoch % 5000 < 100) {
        //debugPrint('[CONSOLE] [active_workout_screen]🔧 [PERF] Getting weight for exercise $exerciseId, series $currentSeriesNumber (completed: $completedSeriesCount)');
      }

      // Usa il metodo serie-specifico del BLoC
      final seriesSpecificValues = _activeWorkoutBloc.getValuesForSeries(exerciseId, currentSeriesNumber);

      if (seriesSpecificValues.weight > 0) {
        _cachedWeights[exerciseId] = seriesSpecificValues.weight;
        return seriesSpecificValues.weight;
      }
    }

    // 3. FALLBACK: Valori BLoC generici
    final currentState2 = _activeWorkoutBloc.state;
    if (currentState2 is WorkoutSessionActive) {
      final exerciseValues = currentState2.exerciseValues[exerciseId];
      if (exerciseValues != null) {
        _cachedWeights[exerciseId] = exerciseValues.weight;
        return exerciseValues.weight;
      }
    }

    // 4. ULTIMO FALLBACK: Default esercizio
    final weight = exercise.peso;
    _cachedWeights[exerciseId] = weight;
    return weight;
  }

  /// Ottiene ripetizioni efficaci con cache
  int _getEffectiveReps(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;

    // 🔧 FIX: PRIORITÀ ASSOLUTA - Valori modificati dall'utente (sopra TUTTO)
    if (_modifiedReps.containsKey(exerciseId)) {
      final reps = _modifiedReps[exerciseId]!;
      _cachedReps[exerciseId] = reps;
      return reps;
    }

    // 🎯 FASE 5: PRIORITÀ MASSIMA - Dati precedenti se toggle ON
    if (_usePreviousData && _previousReps.containsKey(exerciseId)) {
      return _previousReps[exerciseId]!;
    }

    // 🔧 PERFORMANCE FIX: Usa cache se disponibile
    if (_cachedReps.containsKey(exerciseId)) {
      return _cachedReps[exerciseId]!;
    }

    // 2. SERIE-SPECIFIC: Valori storici per la serie corrente
    final currentState = _getCurrentState();
    if (currentState != null) {
      final completedSeriesCount = _getCompletedSeriesCount(currentState, exerciseId);
      final currentSeriesNumber = (completedSeriesCount + 1).clamp(1, exercise.serie); // Prossima serie da fare

      // 🔧 PERFORMANCE FIX: Log ridotto
      if (DateTime.now().millisecondsSinceEpoch % 5000 < 100) {
        //debugPrint('[CONSOLE] [active_workout_screen]🔧 [PERF] Getting reps for exercise $exerciseId, series $currentSeriesNumber (completed: $completedSeriesCount)');
      }

      // Usa il metodo serie-specifico del BLoC
      final seriesSpecificValues = _activeWorkoutBloc.getValuesForSeries(exerciseId, currentSeriesNumber);

      if (seriesSpecificValues.reps > 0) {
        _cachedReps[exerciseId] = seriesSpecificValues.reps;
        return seriesSpecificValues.reps;
      }
    }

    // 3. FALLBACK: Valori BLoC generici
    final currentState2 = _activeWorkoutBloc.state;
    if (currentState2 is WorkoutSessionActive) {
      final exerciseValues = currentState2.exerciseValues[exerciseId];
      if (exerciseValues != null) {
        _cachedReps[exerciseId] = exerciseValues.reps;
        return exerciseValues.reps;
      }
    }

    // 4. ULTIMO FALLBACK: Default esercizio
    final reps = exercise.ripetizioni;
    _cachedReps[exerciseId] = reps;
    return reps;
  }

  /// 🔧 PERFORMANCE FIX: Invalida cache per un esercizio
  void _invalidateCacheForExercise(int exerciseId) {
    _cachedWeights.remove(exerciseId);
    _cachedReps.remove(exerciseId);
    //debugPrint('[CONSOLE] [active_workout_screen]🔧 [CACHE] Invalidated cache for exercise $exerciseId');
  }

  /// 🔧 PERFORMANCE FIX: Pulisce tutta la cache
  void _clearCache() {
    _cachedWeights.clear();
    _cachedReps.clear();
    //debugPrint('[CONSOLE] [active_workout_screen]🔧 [CACHE] Cache cleared');
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _completeButtonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // 🚀 NUOVO: Controller per indicatore di rotazione
    _rotationIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _completeButtonAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _completeButtonController,
      curve: Curves.elasticOut,
    ));

    // 🚀 NUOVO: Animazione per indicatore di rotazione
    _rotationIndicatorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationIndicatorController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeWorkout() async {
    try {
      setState(() {
        _currentStatus = "Caricamento sessione...";
      });

      final sessionService = getIt<SessionService>();
      _userId = await sessionService.getCurrentUserId();

      if (_userId == null) {
        throw Exception('Sessione utente non valida');
      }

      _activeWorkoutBloc = context.read<ActiveWorkoutBloc>();
      
      // 🆕 NUOVO: Controlla se c'è già un allenamento attivo
      final currentState = _activeWorkoutBloc.state;
      if (currentState is WorkoutSessionActive) {
        //debugPrint('[CONSOLE] [active_workout_screen] ✅ Found existing active workout, using it');
        // Usa l'allenamento esistente invece di avviarne uno nuovo
        setState(() {
          _isInitialized = true;
          _currentStatus = "Allenamento ripristinato";
        });
        _slideController.forward();
        
        // 🎯 FASE 5: Carica dati precedenti per tutti gli esercizi
        // RIMOSSO: Ora gestito in _buildActiveContent per evitare duplicati
        // if (_usePreviousData && currentState.exercises.isNotEmpty) {
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     if (mounted) {
        //       _loadPreviousDataForAllExercises(currentState);
        //     }
        //   });
        // }
      } else {
        //debugPrint('[CONSOLE] [active_workout_screen] 🚀 No active workout found, starting new one');
        // Avvia un nuovo allenamento solo se non ce n'è già uno attivo
        _activeWorkoutBloc.startWorkout(_userId!, widget.schedaId);
      }

      // 🔧 FIX 1: ALWAYS ON - Enable wakelock when workout starts
      await _enableWakeLock();

      if (currentState is! WorkoutSessionActive) {
        setState(() {
          _isInitialized = true;
          _currentStatus = "Allenamento avviato";
        });
        _slideController.forward();
      }

    } catch (e) {
      //debugPrint("🚀 [SINGLE EXERCISE + ALL FIXES] Error initializing: $e");
      setState(() {
        _currentStatus = "Errore inizializzazione: $e";
      });

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: "Errore nell'avvio dell'allenamento: $e",
          isSuccess: false,
        );
      }
    }
  }

  // ============================================================================
  // 🆕 DIALOG METHODS (unchanged)
  // ============================================================================

  void _showExitConfirmDialog() {
    setState(() {
      _showExitDialog = true;
    });
  }

  void _showCompleteConfirmDialog() {
    setState(() {
      _showCompleteDialog = true;
    });
  }

  // 🔧 FASE 1: Metodo per mostrare dialog aggiunta esercizio
  void _showAddExerciseDialog() {
    CustomSnackbar.show(
      context,
      message: 'Funzionalità in arrivo!',
      isSuccess: false,
    );
  }



  void _handleExitConfirmed() {
    //debugPrint("🚪 [EXIT] User confirmed exit - cancelling workout");

    final currentState = context.read<ActiveWorkoutBloc>().state;
    if (currentState is WorkoutSessionActive) {
      _activeWorkoutBloc.cancelWorkout(currentState.activeWorkout.id);
    }
    
    // 🔧 FIX: Torna alla dashboard con barra di navigazione
    context.go('/dashboard');
  }

  void _handleCompleteConfirmed() {
    //debugPrint("✅ [COMPLETE] User confirmed completion");

    final currentState = context.read<ActiveWorkoutBloc>().state;
    if (currentState is WorkoutSessionActive) {
      _handleCompleteWorkout(currentState);
    }
  }

  // ============================================================================
  // 🚀 EXERCISE GROUPING FOR SUPERSET/CIRCUIT (unchanged)
  // ============================================================================

  List<List<WorkoutExercise>> _groupExercises(List<WorkoutExercise> exercises) {
    List<List<WorkoutExercise>> groups = [];
    List<WorkoutExercise> currentGroup = [];

    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];

      if (exercise.linkedToPreviousInt == 0) {
        if (currentGroup.isNotEmpty) {
          groups.add(List.from(currentGroup));
          currentGroup.clear();
        }
        currentGroup.add(exercise);
      } else {
        currentGroup.add(exercise);
      }
    }

    if (currentGroup.isNotEmpty) {
      groups.add(currentGroup);
    }

    //debugPrint("🚀 [GROUPING] Created ${groups.length} exercise groups:");
    for (int i = 0; i < groups.length; i++) {
      //debugPrint("  Group $i: ${groups[i].map((e) => e.nome).join(', ')}");
    }

    return groups;
  }

  bool _isGroupCompleted(WorkoutSessionActive state, List<WorkoutExercise> group) {
    for (final exercise in group) {
      if (!_isExerciseCompleted(state, exercise)) {
        return false;
      }
    }
    return true;
  }

  bool _isWorkoutFullyCompleted(WorkoutSessionActive state) {
    for (final group in _exerciseGroups) {
      if (!_isGroupCompleted(state, group)) {
        return false;
      }
    }
    return _exerciseGroups.isNotEmpty;
  }

  WorkoutExercise? _getNextIncompleteExerciseInGroup(WorkoutSessionActive state, List<WorkoutExercise> group) {
    for (final exercise in group) {
      if (!_isExerciseCompleted(state, exercise)) {
        return exercise;
      }
    }
    return null;
  }

  // ============================================================================
  // 🔧 FIX 3: SUPERSET PAUSE - Methods to detect linked exercises
  // ============================================================================



  /// 🔧 FIX 3: Verifica se dovrebbe partire il timer di recupero
  /// 🎯 FASE 5: Timer parte SOLO dopo l'ultimo esercizio del superset/circuit
  bool _shouldStartRecoveryTimer(WorkoutExercise exercise) {
    // Se non è parte di un gruppo multi-esercizio, sempre true
    if (!_isPartOfMultiExerciseGroup(exercise)) {
      // //debugPrint("[TIMER] 🚀 _shouldStartRecoveryTimer: TRUE (single exercise)");
      return true;
    }

    // 🎯 FASE 5: Per superset/circuit, timer parte SOLO se è l'ultimo esercizio
    final isLast = _isLastExerciseInGroup(exercise);
    // //debugPrint("[TIMER] 🚀 _shouldStartRecoveryTimer: ${isLast ? 'TRUE' : 'FALSE'} (multi-exercise group, isLast=$isLast, exercise=${exercise.nome})");
    return isLast;
  }

  // ============================================================================
  // NAVIGATION METHODS (unchanged)
  // ============================================================================

  void _goToPreviousGroup() {
    if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        if (_currentGroupIndex < _exerciseGroups.length) {
          final newGroup = _exerciseGroups[_currentGroupIndex];
          _currentExerciseInGroup = _findNextExerciseInSequentialRotation(
              _getCurrentState(),
              newGroup,
              isNewGroup: true
          );
        }
      });
      _pageController.animateToPage(
        _currentGroupIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _stopRecoveryTimer();

      // 🔧 PERFORMANCE FIX: Pulisce cache quando cambia gruppo
      _clearCache();
    }
  }

  void _goToNextGroup() {
    if (_currentGroupIndex < _exerciseGroups.length - 1) {
      setState(() {
        _currentGroupIndex++;
        if (_currentGroupIndex < _exerciseGroups.length) {
          final newGroup = _exerciseGroups[_currentGroupIndex];
          _currentExerciseInGroup = _findNextExerciseInSequentialRotation(
              _getCurrentState(),
              newGroup,
              isNewGroup: true
          );
        }
      });
      _pageController.animateToPage(
        _currentGroupIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _stopRecoveryTimer();

      // 🔧 PERFORMANCE FIX: Pulisce cache quando cambia gruppo
      _clearCache();
    }
  }

  bool _canGoToPrevious() {
    return _currentGroupIndex > 0;
  }

  bool _canGoToNext() {
    return _currentGroupIndex < _exerciseGroups.length - 1;
  }

  // ============================================================================
  // RECOVERY TIMER POPUP METHODS (unchanged)
  // ============================================================================

  void _startRecoveryTimer(int seconds, String exerciseName) {
    // //debugPrint("[TIMER] 🚀 _startRecoveryTimer called - seconds: $seconds, exercise: $exerciseName");
    setState(() {
      _isRecoveryTimerActive = true;
      _recoverySeconds = seconds;
      _currentRecoveryExerciseName = exerciseName;
    });
    // //debugPrint("[TIMER] 🚀 Timer state updated - _isRecoveryTimerActive: $_isRecoveryTimerActive");
  }

  void _stopRecoveryTimer() {
    //debugPrint("⏹️ [RECOVERY POPUP] Recovery timer stopped");

    // 🔧 FIX: Controlla se il widget è ancora montato prima di chiamare setState
    if (mounted) {
      setState(() {
        _isRecoveryTimerActive = false;
        _recoverySeconds = 0;
        _currentRecoveryExerciseName = null;
      });
    }
  }

  void _onRecoveryTimerComplete() {
    setState(() {
      _isRecoveryTimerActive = false;
      _recoverySeconds = 0;
      _currentRecoveryExerciseName = null;
    });

    // 🔧 PERFORMANCE FIX: Rimosso messaggio di completamento recupero per migliorare performance
    // CustomSnackbar.show(
    //   context,
    //   message: "Recupero completato! Pronto per la prossima serie 💪",
    //   isSuccess: true,
    // );
  }

  // ============================================================================
  // 🔥 ISOMETRIC TIMER METHODS (unchanged)
  // ============================================================================

  void _startIsometricTimer(WorkoutExercise exercise) {
    final seconds = _getEffectiveReps(exercise);

  //  //debugPrint("🔥 [ISOMETRIC] Starting isometric timer: $seconds seconds for ${exercise.nome}");

    setState(() {
      _isIsometricTimerActive = true;
      _isometricSeconds = seconds;
      _currentIsometricExerciseName = exercise.nome;
      _pendingIsometricExercise = exercise;
    });
  }

  void _onIsometricTimerComplete() {
    //debugPrint("✅ [ISOMETRIC] Isometric timer completed!");

    if (_pendingIsometricExercise != null) {
      final state = _getCurrentState();
      if (state != null) {
        _handleCompleteSeries(state, _pendingIsometricExercise!);
      }
    }

    setState(() {
      _isIsometricTimerActive = false;
      _isometricSeconds = 0;
      _currentIsometricExerciseName = null;
      _pendingIsometricExercise = null;
    });

    // 🔧 PERFORMANCE FIX: Rimosso messaggio di completamento tenuta isometrica per migliorare performance
    // CustomSnackbar.show(
    //   context,
    //   message: "🔥 Tenuta isometrica completata! 💪",
    //   isSuccess: true,
    // );
  }

  void _onIsometricTimerCancelled() {
    //debugPrint("❌ [ISOMETRIC] Isometric timer cancelled");

    setState(() {
      _isIsometricTimerActive = false;
      _isometricSeconds = 0;
      _currentIsometricExerciseName = null;
      _pendingIsometricExercise = null;
    });

    // 🔧 PERFORMANCE FIX: Rimosso messaggio di annullamento tenuta isometrica per migliorare performance
    // CustomSnackbar.show(
    //   context,
    //   message: "Tenuta isometrica annullata",
    //   isSuccess: false,
    // );
  }

  // ============================================================================
  // ✏️ PARAMETER EDITING METHODS (updated with plateau fix)
  // ============================================================================

  void _editExerciseParameters(WorkoutExercise exercise) {
    final currentWeight = _getEffectiveWeight(exercise);
    final currentReps = _getEffectiveReps(exercise);

    showDialog(
      context: context,
      builder: (context) => ParameterEditDialog(
        initialWeight: currentWeight,
        initialReps: currentReps,
        exerciseName: exercise.nome,
        isIsometric: exercise.isIsometric,
        onSave: (weight, reps) {
          _saveModifiedParameters(exercise, weight, reps);
        },
      ),
    );
  }

  void _saveModifiedParameters(WorkoutExercise exercise, double weight, int reps) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;

    setState(() {
      _modifiedWeights[exerciseId] = weight;
      _modifiedReps[exerciseId] = reps;
    });

    // 🔧 PERFORMANCE FIX: Invalida cache per questo esercizio
    _invalidateCacheForExercise(exerciseId);

    context.read<ActiveWorkoutBloc>().updateExerciseValues(exerciseId, weight, reps);

    // 🔧 FIX 2: PLATEAU - Trigger analysis SOLO se non già analizzato o dismissed
    _triggerPlateauAnalysisIfNeeded(exercise);
  }

  // ============================================================================
  // 🔧 FIX 2: PLATEAU DETECTION METHODS - CORRECTED
  // ============================================================================

  /// 🔧 FIX 2: Trigger plateau analysis SOLO se necessario
  void _triggerPlateauAnalysisIfNeeded(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;

    // Non triggare se già analizzato o dismissed
    if (_plateauAnalyzedExercises.contains(exerciseId) ||
        _dismissedPlateauExercises.contains(exerciseId)) {
      //debugPrint("🔧 [PLATEAU FIX] Skipping analysis for exercise $exerciseId - already analyzed or dismissed");
      return;
    }

    final weight = _getEffectiveWeight(exercise);
    final reps = _getEffectiveReps(exercise);

    //debugPrint("🔧 [PLATEAU FIX] Triggering analysis for ${exercise.nome}: ${weight}kg x $reps");

    _plateauAnalyzedExercises.add(exerciseId);
    _plateauBloc.analyzeExercisePlateau(exerciseId, exercise.nome, weight, reps);
  }

  /// 🔧 FIX 2: Auto-trigger plateau SOLO UNA VOLTA per tutti gli esercizi
  void _triggerPlateauAnalysisForAllExercises(WorkoutSessionActive state) {
    //debugPrint("🔧 [PLATEAU FIX] Starting SINGLE plateau analysis for all exercises");

    for (final exercise in state.exercises) {
      _triggerPlateauAnalysisIfNeeded(exercise);
    }
  }

  /// Check if exercise has plateau (unchanged)
  bool _hasPlateauForExercise(int exerciseId) {
    final plateauState = _plateauBloc.state;
    if (plateauState is PlateauDetected) {
      return plateauState.hasPlateauForExercise(exerciseId);
    }
    return false;
  }

  /// Get plateau info for exercise (unchanged)
  PlateauInfo? _getPlateauForExercise(int exerciseId) {
    final plateauState = _plateauBloc.state;
    if (plateauState is PlateauDetected) {
      return plateauState.getPlateauForExercise(exerciseId);
    }
    return null;
  }

  // ============================================================================
  // 🔄 FASE 7: SOSTITUZIONE ESERCIZIO
  // ============================================================================
  
  /// Ricarica i gruppi di esercizi dal BLoC dopo una sostituzione
  void _loadExerciseGroups() {
    final state = _activeWorkoutBloc.state;
    if (state is WorkoutSessionActive) {
      //debugPrint('[SOST] 🔄 Ricaricamento gruppi esercizi dal BLoC');
      
      // Ricostruisci i gruppi di esercizi
      _exerciseGroups = _buildExerciseGroups(state.exercises);
      
      //debugPrint('[SOST] ✅ Gruppi ricaricati: ${_exerciseGroups.length} gruppi');
      for (int i = 0; i < _exerciseGroups.length; i++) {
        //debugPrint('[SOST] Gruppo $i: ${_exerciseGroups[i].map((e) => e.nome).join(', ')}');
      }
    }
  }
  
  /// Costruisce i gruppi di esercizi basandosi sui setType
  List<List<WorkoutExercise>> _buildExerciseGroups(List<WorkoutExercise> exercises) {
    List<List<WorkoutExercise>> groups = [];
    List<WorkoutExercise> currentGroup = [];
    
    //debugPrint('[SOST] 🔍 Costruzione gruppi da ${exercises.length} esercizi');
    
    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      //debugPrint('[SOST] 🔍 Esercizio $i: ${exercise.nome} (setType: ${exercise.setType}, linkedToPrevious: ${exercise.linkedToPreviousInt})');
      
      // Se è il primo esercizio o non è linkato al precedente, inizia un nuovo gruppo
      if (i == 0 || exercise.linkedToPreviousInt != 1) {
        if (currentGroup.isNotEmpty) {
          groups.add(List.from(currentGroup));
          //debugPrint('[SOST] ✅ Gruppo completato: ${currentGroup.map((e) => e.nome).join(', ')}');
          currentGroup.clear();
        }
      }
      
      currentGroup.add(exercise);
    }
    
    // Aggiungi l'ultimo gruppo
    if (currentGroup.isNotEmpty) {
      groups.add(currentGroup);
      //debugPrint('[SOST] ✅ Ultimo gruppo: ${currentGroup.map((e) => e.nome).join(', ')}');
    }
    
    //debugPrint('[SOST] ✅ Totale gruppi creati: ${groups.length}');
    return groups;
  }
  
  /// Gestisce la sostituzione di un esercizio durante l'allenamento
  void _handleExerciseSubstitution(
    WorkoutExercise originalExercise,
    WorkoutExercise substitutedExercise,
    int newSeries,
    int newReps,
    double newWeight,
  ) async {
    try {
      //debugPrint('[SOST] 🔄 Inizio sostituzione: ${originalExercise.nome} -> ${substitutedExercise.nome}');
      //debugPrint('[SOST] 🔍 Original ID: ${originalExercise.schedaEsercizioId ?? originalExercise.id}');
      //debugPrint('[SOST] 🔍 New ID: ${substitutedExercise.schedaEsercizioId ?? substitutedExercise.id}');
      
      final originalExerciseId = originalExercise.schedaEsercizioId ?? originalExercise.id;
      final newExerciseId = substitutedExercise.schedaEsercizioId ?? substitutedExercise.id;
      
      // Aggiorna l'esercizio nel BLoC
      _activeWorkoutBloc.add(SubstituteExerciseEvent(
        originalExerciseId: originalExerciseId,
        substitutedExercise: substitutedExercise,
        newSeries: newSeries,
        newReps: newReps,
        newWeight: newWeight,
      ));
      
      // Aspetta che il BLoC emetta il nuovo stato
      await _activeWorkoutBloc.stream.firstWhere(
        (state) => state is WorkoutSessionActive && 
                   state.exercises.any((ex) => ex.id == substitutedExercise.id),
        orElse: () => _activeWorkoutBloc.state,
      ).timeout(
        Duration(seconds: 2),
        onTimeout: () {
          //debugPrint('[SOST] ⚠️ Timeout in attesa del nuovo stato');
          return _activeWorkoutBloc.state;
        },
      );
      
      // Aggiorna cache locale per il nuovo esercizio
      _cachedWeights[newExerciseId] = newWeight;
      _cachedReps[newExerciseId] = newReps;
      
      // Rimuovi cache dell'esercizio originale
      _cachedWeights.remove(originalExerciseId);
      _cachedReps.remove(originalExerciseId);
      
      //debugPrint('[SOST] ✅ Sostituzione completata, cache aggiornata');
      
      // 🔥 FORZA REBUILD AGGIUNTIVO: Ricarica i gruppi di esercizi
      _loadExerciseGroups();
      
      // Mostra feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Esercizio sostituito: ${substitutedExercise.nome}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 🔥 FORZA REBUILD MULTIPLO: Prova diversi approcci
        setState(() {});
        
        // Aspetta un po' e forza di nuovo
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {});
          }
        });
        
        // Aspetta ancora e forza di nuovo
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {});
          }
        });
      }
      
    } catch (e) {
      //debugPrint('Errore sostituzione esercizio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Errore durante la sostituzione: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================================
  // WORKOUT LOGIC (updated with fixes)
  // ============================================================================

  void _startWorkoutTimer() {
    if (_startTime == null) {
      _startTime = DateTime.now();
    }

    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final newElapsed = DateTime.now().difference(_startTime!);
        setState(() {
          _elapsedTime = newElapsed;
        });

        if (_elapsedTime.inSeconds % 10 == 0) {
          _activeWorkoutBloc.updateTimer(_elapsedTime);
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _stopWorkoutTimer() {
    _workoutTimer?.cancel();
    _workoutTimer = null;
  }

  int _getCompletedSeriesCount(WorkoutSessionActive state, int exerciseId) {
    final series = state.completedSeries[exerciseId] ?? [];
    return series.length;
  }

  bool _isExerciseCompleted(WorkoutSessionActive state, WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    final completedCount = _getCompletedSeriesCount(state, exerciseId);
    return completedCount >= exercise.serie;
  }

  bool _isWorkoutCompleted(WorkoutSessionActive state) {
    for (final group in _exerciseGroups) {
      if (!_isGroupCompleted(state, group)) {
        return false;
      }
    }
    return true;
  }

  void _handleCompleteSeries(WorkoutSessionActive state, WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    final completedCount = _getCompletedSeriesCount(state, exerciseId);

    //debugPrint("[SERIE] 🚀 _handleCompleteSeries - exercise: ${exercise.nome}, completedCount: $completedCount, totalSeries: ${exercise.serie}");

    if (completedCount >= exercise.serie) {
      //debugPrint("[SERIE] 🚀 Esercizio già completato! Bloccando ulteriori serie.");
      CustomSnackbar.show(
        context,
        message: "Esercizio già completato!",
        isSuccess: false,
      );
      return;
    }

    //debugPrint("[SERIE] 🚀 Completando serie ${completedCount + 1} per esercizio: ${exercise.nome}");

    final effectiveWeight = _getEffectiveWeight(exercise);
    final effectiveReps = _getEffectiveReps(exercise);

    final seriesData = SeriesData(
      schedaEsercizioId: exerciseId,
      peso: effectiveWeight,
      ripetizioni: effectiveReps,
      completata: 1,
      tempoRecupero: exercise.tempoRecupero,
      note: exercise.isIsometric
          ? 'Tenuta isometrica completata da Single Exercise Screen'
          : 'Completata da Single Exercise Screen',
      serieNumber: completedCount + 1,
      serieId: 'series_${DateTime.now().millisecondsSinceEpoch}',
    );

    _activeWorkoutBloc.addLocalSeries(exerciseId, seriesData);

    // Verifica se l'esercizio è completato dopo questa serie
    final newCompletedCount = completedCount + 1;
    if (newCompletedCount >= exercise.serie) {
      //debugPrint("[SERIE] 🚀 ESERCIZIO COMPLETATO! ${exercise.nome} - Serie completate: $newCompletedCount/${exercise.serie}");
    }

    final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';
    _activeWorkoutBloc.saveSeries(
      state.activeWorkout.id,
      [seriesData],
      requestId,
    );

    // 🚀 NUOVO: Salva stato offline dopo ogni serie
    _activeWorkoutBloc.saveOfflineState();

    // 🔧 PERFORMANCE FIX: Invalida cache dopo completamento serie
    _invalidateCacheForExercise(exerciseId);

    // 🎯 FASE 5: Aggiorna dati precedenti per la prossima serie
    // IMPORTANTE: Dobbiamo aspettare che il BLoC aggiorni lo stato prima di caricare i dati
    // Usiamo un delay minimo per dare tempo al BLoC di processare l'aggiornamento
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        if (_usePreviousData) {
          // //debugPrint('[STORICO] Aggiornamento dati precedenti dopo completamento serie');
          _loadPreviousData(exercise);
        } else {
          // //debugPrint('[STORICO] Aggiornamento dati per confronto dopo completamento serie');
          _loadPreviousDataForComparison(exercise);
        }
      }
    });

    // 🔧 PERFORMANCE FIX: Rimosso messaggio di completamento serie per migliorare performance
    // CustomSnackbar.show(
    //   context,
    //   message: exercise.isIsometric
    //       ? "🔥 Tenuta isometrica ${completedCount + 1} completata!"
    //       : "Serie ${completedCount + 1} completata! 💪",
    //   isSuccess: true,
    // );

    // 🔧 FIX 2: PLATEAU - Trigger analysis SOLO se necessario
    _triggerPlateauAnalysisIfNeeded(exercise);

    // 🔧 FIX 3: SUPERSET PAUSE - Start recovery timer SOLO se appropriato
    if (exercise.tempoRecupero > 0 && _shouldStartRecoveryTimer(exercise)) {
      _startRecoveryTimer(exercise.tempoRecupero, exercise.nome);
    } else if (_isPartOfMultiExerciseGroup(exercise)) {
      //debugPrint("🔧 [SUPERSET FIX] Skipping recovery timer for ${exercise.nome} - part of multi-exercise group");
    }

    final updatedState = _getCurrentState();
    if (updatedState != null) {
      _handleAutoRotation(updatedState);
    } else {
      //debugPrint("⚠️ [REST-PAUSE] Could not get updated state for auto-rotation");
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isWorkoutCompleted(state)) {
        _completeButtonController.repeat(reverse: true);
      }
    });
  }

  void _handleAutoRotation(WorkoutSessionActive state) {
    if (_currentGroupIndex >= _exerciseGroups.length) return;

    final currentGroup = _exerciseGroups[_currentGroupIndex];
    if (currentGroup.length <= 1) return;

    if (_isGroupCompleted(state, currentGroup)) {
      return;
    }

    final nextExerciseIndex = _findNextExerciseInSequentialRotation(state, currentGroup);

    if (nextExerciseIndex != _currentExerciseInGroup) {
      // 🚀 NUOVO: Feedback immediato per l'utente
      final nextExercise = currentGroup[nextExerciseIndex];
      final groupType = currentGroup.first.setType;
      
      // Attiva l'indicatore di transizione
      setState(() {
        _isAutoRotating = true;
        _nextExerciseName = nextExercise.nome;
      });
      
      // Avvia l'animazione dell'indicatore
      _rotationIndicatorController.forward();
      
      // Mostra messaggio di transizione immediato
      CustomSnackbar.show(
        context,
        message: "🔄 Passaggio a: ${nextExercise.nome}",
        isSuccess: true,
        duration: const Duration(seconds: 2),
      );

      // Poi esegui la transizione dopo il delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _currentExerciseInGroup = nextExerciseIndex;
            _isAutoRotating = false;
            _nextExerciseName = null;
          });
          
          // Reset dell'animazione
          _rotationIndicatorController.reset();

          final nextExercise = currentGroup[_currentExerciseInGroup];
          final groupType = currentGroup.first.setType;

          // 🔧 PERFORMANCE FIX: Rimosso messaggio di rotazione esercizi per migliorare performance
          // CustomSnackbar.show(
          //   context,
          //   message: "🔄 ${groupType.toUpperCase()}: ${nextExercise.nome}",
          //   isSuccess: true,
          // );
        }
      });
    }
  }

  int _findNextExerciseInSequentialRotation(
      WorkoutSessionActive? state,
      List<WorkoutExercise> group,
      {bool isNewGroup = false}
      ) {
    if (state == null) return 0;

    int startIndex = isNewGroup ? 0 : (_currentExerciseInGroup + 1) % group.length;

    for (int attempts = 0; attempts < group.length; attempts++) {
      int checkIndex = (startIndex + attempts) % group.length;
      final exercise = group[checkIndex];
      final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
      final completedCount = _getCompletedSeriesCount(state, exerciseId);

      if (completedCount < exercise.serie) {
        return checkIndex;
      }
    }

    //debugPrint("🎉 [AUTO-ROTATION] All exercises in group are completed!");
    return isNewGroup ? 0 : _currentExerciseInGroup;
  }

  WorkoutSessionActive? _getCurrentState() {
    final currentState = context.read<ActiveWorkoutBloc>().state;
    return currentState is WorkoutSessionActive ? currentState : null;
  }

  void _handleCompleteWorkout(WorkoutSessionActive state) {
    //debugPrint("🚀 [SINGLE EXERCISE] Completing workout");

    _stopWorkoutTimer();
    _completeButtonController.stop();

    // 🔧 FIX 1: ALWAYS ON - Disable wakelock when workout completes
    _disableWakeLock();

    final durationMinutes = _elapsedTime.inMinutes;
    _activeWorkoutBloc.completeWorkout(
      state.activeWorkout.id,
      durationMinutes,
      note: 'Completato tramite Single Exercise Screen',
    );
  }

  // ============================================================================
  // UI HELPERS (unchanged)
  // ============================================================================

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
    } else {
      return "${twoDigits(minutes)}:${twoDigits(seconds)}";
    }
  }

  String _getExerciseTypeLabel(WorkoutExercise exercise) {
    if (exercise.setType == "superset") {
      return "Superset";
    } else if (exercise.setType == "circuit") {
      return "Circuit";
    }
    return "Esercizio";
  }


  Color _getExerciseTypeColor(WorkoutExercise exercise) {
    final colorScheme = Theme.of(context).colorScheme;

    if (exercise.setType == "superset") {
      return Colors.purple;
    } else if (exercise.setType == "circuit") {
      return Colors.orange;
    }
    return colorScheme.primary;
  }

  // ============================================================================
  // BUILD METHODS (unchanged except for build method header)
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildInitializingScreen();
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _showExitConfirmDialog();
        }
      },
      child: MultiBlocListener(
        listeners: [
          // 🔧 FIX 2: PLATEAU BLOC LISTENER - Updated with dismiss tracking
          BlocListener<PlateauBloc, PlateauState>(
            listener: _handlePlateauStateChanges,
          ),
          // Original ActiveWorkout BlocListener
          BlocListener<ActiveWorkoutBloc, ActiveWorkoutState>(
            bloc: _activeWorkoutBloc,
            listener: _handleBlocStateChanges,
          ),
        ],
        child: BlocBuilder<ActiveWorkoutBloc, ActiveWorkoutState>(
          bloc: _activeWorkoutBloc,
          builder: (context, state) {
            return Stack(
              children: [
                Scaffold(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  appBar: _buildAppBar(state),
                  body: _buildBody(state),
                ),

                if (_showExitDialog)
                  _buildExitDialog(),

                if (_showCompleteDialog)
                  _buildCompleteDialog(),
              ],
            );
          },
        ),
      ),
    );
  }

  // [All other UI building methods remain unchanged - _buildInitializingScreen, _buildAppBar, etc.]
  // [Continuing with the same content as before...]

  // ============================================================================
  // BLOC LISTENERS (updated with plateau fix)
  // ============================================================================

  void _handleBlocStateChanges(BuildContext context, ActiveWorkoutState state) {
    if (state is WorkoutSessionStarted) {
      //debugPrint("🚀 [SINGLE EXERCISE MINIMALE] Workout session started");
      _startWorkoutTimer();

      // 🔧 PERFORMANCE FIX: Rimosso messaggio di avvio allenamento per migliorare performance
      // CustomSnackbar.show(
      //   context,
      //   message: "Allenamento avviato con successo! 💪",
      //   isSuccess: true,
      // );
    }

    if (state is WorkoutSessionActive) {
      //debugPrint("🚀 [SINGLE EXERCISE MINIMALE] Active session with ${state.exercises.length} exercises");

      if (_workoutTimer == null) {
        _startWorkoutTimer();
      }

      // 🔧 FIX 2: PLATEAU - Auto-trigger SOLO UNA VOLTA
      if (!_plateauAnalysisTriggered) {
        _plateauAnalysisTriggered = true;
        Future.delayed(const Duration(seconds: 2), () {
          _triggerPlateauAnalysisForAllExercises(state);
        });
      }
    }

    if (state is WorkoutSessionCompleted) {
      //debugPrint("🚀 [SINGLE EXERCISE MINIMALE] Workout completed");
      _stopWorkoutTimer();
      _stopRecoveryTimer();
      _completeButtonController.stop();

      // 🔧 FIX 1: ALWAYS ON - Disable wakelock on completion
      _disableWakeLock();

      // 🔧 PERFORMANCE FIX: Pulisce cache a fine allenamento
      _clearCache();

      // 🆕 NUOVO: Naviga alla home dopo il completamento
      CustomSnackbar.show(
        context,
        message: "✅ Allenamento completato con successo!",
        isSuccess: true,
        duration: const Duration(seconds: 2),
      );

      // Naviga alla dashboard dopo un breve delay usando GoRouter
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/dashboard');
        }
      });
    }

    // 🌐 NUOVO: Gestione completamento offline
    if (state is WorkoutSessionCompletedOffline) {
      //debugPrint("🌐 [OFFLINE] Workout completed offline");
      _stopWorkoutTimer();
      _stopRecoveryTimer();
      _completeButtonController.stop();

      // 🔧 FIX 1: ALWAYS ON - Disable wakelock on completion
      _disableWakeLock();

      // 🔧 PERFORMANCE FIX: Pulisce cache a fine allenamento
      _clearCache();

      // Mostra messaggio di completamento offline
      CustomSnackbar.show(
        context,
        message: "✅ ${state.message}",
        isSuccess: true,
        duration: const Duration(seconds: 4),
      );

      // Naviga alla home dopo un breve delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/dashboard');
        }
      });
    }

    if (state is WorkoutSessionCancelled) {
      //debugPrint("🚀 [SINGLE EXERCISE MINIMALE] Workout cancelled");
      _stopWorkoutTimer();
      _stopRecoveryTimer();
      _completeButtonController.stop();

      // 🔧 FIX 1: ALWAYS ON - Disable wakelock on cancellation
      _disableWakeLock();

      // 🔧 PERFORMANCE FIX: Pulisce cache quando si annulla
      _clearCache();

      CustomSnackbar.show(
        context,
        message: "Allenamento annullato",
        isSuccess: false,
      );

      context.go('/dashboard');
    }

    if (state is ActiveWorkoutError) {
      //debugPrint("🚀 [SINGLE EXERCISE MINIMALE] Error: ${state.message}");

      CustomSnackbar.show(
        context,
        message: "Errore: ${state.message}",
        isSuccess: false,
      );
    }
  }

  // 🔧 FIX 2: PLATEAU BLOC LISTENER - Updated with dismiss tracking
  void _handlePlateauStateChanges(BuildContext context, PlateauState state) {
    if (state is PlateauDetected) {
      final activePlateaus = state.activePlateaus;
      if (activePlateaus.isNotEmpty) {
        //debugPrint("🔧 [PLATEAU FIX] Plateau rilevati: ${activePlateaus.length}");

        // 🔧 PERFORMANCE FIX: Rimosso messaggio di plateau per migliorare performance
        // CustomSnackbar.show(
        //   context,
        //   message: "🎯 Plateau rilevato - Tap badge per suggerimenti!",
        //   isSuccess: false,
        //   duration: const Duration(seconds: 2),
        // );
      }

      // Track dismissed plateaus from state
      for (final plateau in state.plateaus) {
        if (plateau.isDismissed) {
          _dismissedPlateauExercises.add(plateau.exerciseId);
          //debugPrint("🔧 [PLATEAU FIX] Exercise ${plateau.exerciseId} dismissed - won't retrigger");
        }
      }
    }

    if (state is PlateauError) {
      //debugPrint("🔧 [PLATEAU FIX] Error: ${state.message}");
      // Don't show error to user - plateau is optional feature
    }
  }

  // ============================================================================
  // CONTINUE WITH ALL OTHER UI METHODS (unchanged)
  // ============================================================================

  Widget _buildInitializingScreen() {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Caricamento...'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(40.r),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: colorScheme.onPrimary,
                  size: 40.sp,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              _currentStatus,
              style: TextStyle(
                fontSize: 16.sp,
                color: colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: 200.w,
              child: LinearProgressIndicator(
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ActiveWorkoutState state) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isWorkoutFullyCompleted = false;

    if (state is WorkoutSessionActive && _exerciseGroups.isNotEmpty) {
      isWorkoutFullyCompleted = _isWorkoutFullyCompleted(state);

      if (isWorkoutFullyCompleted && !_completeButtonController.isAnimating) {
        _completeButtonController.repeat(reverse: true);
      } else if (!isWorkoutFullyCompleted && _completeButtonController.isAnimating) {
        _completeButtonController.stop();
        _completeButtonController.reset();
      }
    }

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible( // 🔧 FIX: Evita overflow AppBar
                child: Text(
            'Allenamento',
            style: TextStyle(fontSize: 18.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 🎨 NUOVO: Badge superset (17 Ottobre 2025)
              if (_getCurrentWorkoutType() != null) ...[
                SizedBox(width: 8.w),
                SupersetBadge.compact(_getCurrentWorkoutType()!),
              ],
            ],
          ),
          Text(
            _formatDuration(_elapsedTime),
            style: TextStyle(
              fontSize: 12.sp,
              color: colorScheme.onSurface.withValues(alpha:0.7),
            ),
          ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, size: 24.sp),
        onPressed: _showExitConfirmDialog,
      ),
      actions: [
        // 🔧 FASE 1: Pulsante Aggiungi Esercizio
        IconButton(
          icon: Icon(
            Icons.add_circle_outline,
            size: 24.sp,
            color: colorScheme.onSurface,
          ),
          onPressed: _showAddExerciseDialog,
          tooltip: 'Aggiungi esercizio',
        ),
        SizedBox(width: 8.w),
        Container(
          margin: EdgeInsets.only(right: 16.w),
          child: AnimatedBuilder(
            animation: _completeButtonAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: isWorkoutFullyCompleted
                      ? Colors.green.withValues(alpha:0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.done,
                    size: 24.sp,
                    color: isWorkoutFullyCompleted
                        ? Colors.green
                        : colorScheme.onSurface,
                  ),
                  onPressed: _showCompleteConfirmDialog,
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.all(8.w),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ActiveWorkoutState state) {
    return Column(
      children: [
        // 🚀 NUOVO: Widget per stato offline
        const OfflineStatusWidget(),
        
        // 🚀 TIMER SEMPLICE E VISIBILE
        if (_isRecoveryTimerActive)
          SimpleRecoveryTimer(
            initialSeconds: _recoverySeconds,
            isActive: _isRecoveryTimerActive,
            exerciseName: _currentRecoveryExerciseName,
            onTimerComplete: _onRecoveryTimerComplete,
            onTimerStopped: () {
              if (mounted) _stopRecoveryTimer();
            },
            onTimerDismissed: () {
              if (mounted) _stopRecoveryTimer();
            },
          ),
        
        // Contenuto principale
        Expanded(
          child: Stack(
            children: [
              _buildMainContent(state),

        if (_isIsometricTimerActive && _currentIsometricExerciseName != null)
          IsometricTimerPopup(
            initialSeconds: _isometricSeconds,
            isActive: _isIsometricTimerActive,
            exerciseName: _currentIsometricExerciseName!,
            onIsometricComplete: _onIsometricTimerComplete,
            onIsometricCancelled: _onIsometricTimerCancelled,
            onIsometricDismissed: () {
              setState(() {
                _isIsometricTimerActive = false;
                _pendingIsometricExercise = null;
              });
            },
          ),

        // 🚀 NUOVO: Indicatore di transizione auto-rotazione
        if (_isAutoRotating && _nextExerciseName != null)
          _buildAutoRotationIndicator(),

        // 🔧 FASE 1: Dialog per aggiungere esercizi (placeholder)
        if (false) // Temporaneamente disabilitato
          Container(), // Placeholder per il dialog
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(ActiveWorkoutState state) {
    if (state is ActiveWorkoutLoading) {
      return _buildLoadingContent();
    }

    // 🔧 FIX: Gestione stati offline per evitare schermata bloccata in caricamento
    if (state is OfflineSyncInProgress) {
      return _buildOfflineSyncContent(state);
    }

    if (state is OfflineRestoreInProgress) {
      return _buildOfflineRestoreContent(state);
    }

    if (state is WorkoutSessionActive) {
      return _buildActiveContent(state);
    }

    if (state is WorkoutSessionCompleted) {
      return _buildCompletedContent(state);
    }

    if (state is ActiveWorkoutError) {
      return _buildErrorContent(state);
    }

    return _buildDefaultContent();
  }

  Widget _buildLoadingContent() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
            strokeWidth: 3,
          ),
          SizedBox(height: 16.h),
          Text(
            'Caricamento allenamento...',
            style: TextStyle(
              fontSize: 16.sp,
              color: colorScheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 FIX: Metodi per gestire stati offline e evitare schermata bloccata
  Widget _buildOfflineSyncContent(OfflineSyncInProgress state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
            strokeWidth: 3,
          ),
          SizedBox(height: 16.h),
          Text(
            state.message,
            style: TextStyle(
              fontSize: 16.sp,
              color: colorScheme.onBackground,
            ),
          ),
          if (state.pendingCount > 0) ...[
            SizedBox(height: 8.h),
            Text(
              'Serie in attesa: ${state.pendingCount}',
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfflineRestoreContent(OfflineRestoreInProgress state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
            strokeWidth: 3,
          ),
          SizedBox(height: 16.h),
          Text(
            state.message,
            style: TextStyle(
              fontSize: 16.sp,
              color: colorScheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveContent(WorkoutSessionActive state) {
    // 🎯 FASE 5: Carica dati precedenti quando l'allenamento diventa attivo (solo una volta)
    if (_usePreviousData && state.exercises.isNotEmpty && !_previousDataLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadPreviousDataForAllExercises(state);
          _previousDataLoaded = true; // Marca come caricato
        }
      });
    }
    
    if (state.exercises.isEmpty) {
      return _buildNoExercisesContent();
    }

    if (_exerciseGroups.isEmpty) {
      _exerciseGroups = _groupExercises(state.exercises);
      if (_currentGroupIndex >= _exerciseGroups.length) {
        _currentGroupIndex = 0;
      }
      if (_exerciseGroups.isNotEmpty && _currentGroupIndex < _exerciseGroups.length) {
        final currentGroup = _exerciseGroups[_currentGroupIndex];
        _currentExerciseInGroup = _findNextExerciseInSequentialRotation(
            _getCurrentState(),
            currentGroup,
            isNewGroup: true
        );
      }
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentGroupIndex = index;
                if (index < _exerciseGroups.length) {
                  final newGroup = _exerciseGroups[index];
                  _currentExerciseInGroup = _findNextExerciseInSequentialRotation(
                      _getCurrentState(),
                      newGroup,
                      isNewGroup: true
                  );
                }
              });
            },
            itemCount: _exerciseGroups.length,
            itemBuilder: (context, index) {
              final group = _exerciseGroups[index];
              return _buildGroupPage(state, group, index);
            },
          ),
        ),

        _buildBottomNavigation(state),
      ],
    );
  }

  Widget _buildGroupPage(WorkoutSessionActive state, List<WorkoutExercise> group, int groupIndex) {
    if (group.length == 1) {
      return _buildSingleExercisePage(state, group.first);
    } else {
      return _buildMultiExercisePage(state, group);
    }
  }

  Widget _buildSingleExercisePage(WorkoutSessionActive state, WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    final completedSeries = _getCompletedSeriesCount(state, exerciseId);
    final isCompleted = _isExerciseCompleted(state, exercise);

    // 🔧 PERFORMANCE FIX: Pre-carica cache per questo esercizio
    _updateCacheForExercise(exerciseId, exercise);

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: SlideTransition(
        position: _slideAnimation,
        child: BlocBuilder<ActiveWorkoutBloc, ActiveWorkoutState>(
          builder: (context, blocState) {
            // 🔧 FIX: Ricalcola i valori quando lo stato del BLoC cambia
            final currentWeight = _getEffectiveWeight(exercise);
            final currentReps = _getEffectiveReps(exercise);
            
            return ExerciseCardLayoutB(
              exerciseName: exercise.nome,
              muscleGroups: exercise.gruppoMuscolare?.split(',').map((m) => m.trim()).toList() ?? [],
              exerciseImageUrl: exercise.imageUrl,
              // [NEW_PROGR] Log URL immagine per esercizio singolo
              // ignore: avoid_print
              onImageLoadError: (url, error) => print('[NEW_PROGR] Errore caricamento immagine singolo: $url, Errore: $error'),
              weight: currentWeight,
              reps: currentReps,
          currentSeries: (completedSeries + 1).clamp(1, exercise.serie),
          totalSeries: exercise.serie,
          restSeconds: exercise.tempoRecupero,
          isModified: _modifiedWeights.containsKey(exercise.schedaEsercizioId ?? exercise.id) ||
                     _modifiedReps.containsKey(exercise.schedaEsercizioId ?? exercise.id),
          isCompleted: isCompleted, // 🚀 NUOVO: Stato completamento esercizio
          isTimerActive: _isRecoveryTimerActive, // 🚀 NUOVO: Stato timer di recupero
          isIsometric: exercise.isIsometric, // 🔥 NUOVO: Stato isometrico esercizio
          onEditParameters: () => _editExerciseParameters(exercise),
          // 🔥 FASE 6: Note Duali
          trainerNote: exercise.notes?['trainer'],
          userNote: exercise.notes?['user'],
          systemNote: exercise.notes?['system'],
          onUserNoteChanged: (note) => _updateUserNote(exercise, note),
          // 🎯 FASE 5: Sistema "Usa Dati Precedenti"
          usePreviousData: _usePreviousData,
              onUsePreviousDataChanged: (usePrevious) {
                setState(() {
                  _usePreviousData = usePrevious;
                  _previousDataLoaded = false; // Reset flag per ricaricare
                });
                //debugPrint('[PARAM] Toggle usePreviousData: $usePrevious');

                if (usePrevious) {
                  // 🎯 FASE 5: Carica dati precedenti
                  //debugPrint('[PARAM] Caricamento dati precedenti per esercizio: ${exercise.nome}');
                  _loadPreviousData(exercise);
                } else {
                  // 🎯 FASE 5: Torna ai valori del DB ma mantieni dati per confronto
                  //debugPrint('[PARAM] Torno ai valori del DB per esercizio: ${exercise.nome}');
                  _loadPreviousDataForComparison(exercise); // Carica dati per confronto
                }
              },
          isLoadingPreviousData: false, // TODO: Implementare loading
          previousDataStatusMessage: _usePreviousData ? null : _getPreviousDataText(exercise), // 🎯 FASE 5: Testo dinamico solo se toggle OFF
          onCompleteSeries: isCompleted
              ? () {} // Disabilitato se completato
                    : exercise.isIsometric
                    ? () => _startIsometricTimer(exercise)
                    : _isRestPauseExercise(exercise)
              ? () => _handleRestPauseStart(state, exercise)
                    : () => _handleCompleteSeries(state, exercise),
          // 🔄 FASE 7: Sostituzione Esercizio
          currentExercise: exercise,
          onExerciseSubstituted: (substitutedExercise, newSeries, newReps, newWeight) {
            _handleExerciseSubstitution(exercise, substitutedExercise, newSeries, newReps, newWeight);
          },
            );
          },
        ),
      ),
    );
  }

  /// 🏋️ Superset/Circuit page with automatic group switching
  /// 🏋️ Superset/Circuit page with automatic group switching
  Widget _buildMultiExercisePage(WorkoutSessionActive state, List<WorkoutExercise> group) {
    final groupType = group.first.setType;
    final isGroupComplete = _isGroupCompleted(state, group);

    if (_currentExerciseInGroup >= group.length) {
      _currentExerciseInGroup = 0;
    }

    final currentExercise = group[_currentExerciseInGroup];
    final exerciseId = currentExercise.schedaEsercizioId ?? currentExercise.id;
    final completedSeries = _getCompletedSeriesCount(state, exerciseId);
    final isCompleted = _isExerciseCompleted(state, currentExercise);

    // 🔧 PERFORMANCE FIX: Pre-carica cache per l'esercizio corrente
    _updateCacheForExercise(exerciseId, currentExercise);

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: SlideTransition(
        position: _slideAnimation,
        child: BlocBuilder<ActiveWorkoutBloc, ActiveWorkoutState>(
          builder: (context, blocState) {
            // 🔧 FIX: Ricalcola i valori quando lo stato del BLoC cambia
            final currentWeight = _getEffectiveWeight(currentExercise);
            final currentReps = _getEffectiveReps(currentExercise);
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // 🔥 NUOVO LAYOUT B UNIFICATO - SUPERSET/CIRCUIT (17 Ottobre 2025)
                ExerciseCardLayoutB(
                  exerciseName: currentExercise.nome,
                  muscleGroups: currentExercise.gruppoMuscolare?.split(',').map((m) => m.trim()).toList() ?? [],
                  exerciseImageUrl: currentExercise.imageUrl,
                  // [NEW_PROGR] Log URL immagine per superset/circuit
                  // ignore: avoid_print
                  onImageLoadError: (url, error) => print('[NEW_PROGR] Errore caricamento immagine superset: $url, Errore: $error'),
                  weight: currentWeight,
                  reps: currentReps,
              currentSeries: (completedSeries + 1).clamp(1, currentExercise.serie),
              totalSeries: currentExercise.serie,
              restSeconds: currentExercise.tempoRecupero,
              isModified: _modifiedWeights.containsKey(currentExercise.schedaEsercizioId ?? currentExercise.id) ||
                         _modifiedReps.containsKey(currentExercise.schedaEsercizioId ?? currentExercise.id),
              isCompleted: _isExerciseCompleted(state, currentExercise), // 🚀 NUOVO: Stato completamento esercizio
              isTimerActive: _isRecoveryTimerActive, // 🚀 NUOVO: Stato timer di recupero
              isIsometric: currentExercise.isIsometric, // 🔥 NUOVO: Stato isometrico esercizio
              onEditParameters: () => _editExerciseParameters(currentExercise),
              // 🔥 FASE 6: Note Duali
              trainerNote: currentExercise.notes?['trainer'],
              userNote: currentExercise.notes?['user'],
              systemNote: currentExercise.notes?['system'],
              onUserNoteChanged: (note) => _updateUserNote(currentExercise, note),
              onCompleteSeries: isCompleted
                  ? () {} // Disabilitato se completato
                    : currentExercise.isIsometric
                    ? () => _startIsometricTimer(currentExercise)
                    : _isRestPauseExercise(currentExercise)
                  ? () => _handleRestPauseStart(state, currentExercise)
                    : () => _handleCompleteSeries(state, currentExercise),
              // 🔄 FASE 7: Sostituzione Esercizio
              currentExercise: currentExercise,
              onExerciseSubstituted: (substitutedExercise, newSeries, newReps, newWeight) {
                _handleExerciseSubstitution(currentExercise, substitutedExercise, newSeries, newReps, newWeight);
              },
              // Superset/Circuit specific
              groupType: groupType,
              groupExerciseNames: group.map((ex) => ex.nome).toList(),
              currentExerciseIndex: _currentExerciseInGroup,
              showWarning: true, // Mostra warning per superset/circuit
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  /// Parameter card with plateau badge
  Widget _buildParameterCard(
      String label,
      String value,
      IconData icon,
      Color color, {
        VoidCallback? onTap,
        bool isModified = false,
        bool hasPlateauBadge = false,
        int? exerciseId,
      }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha:0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: isModified ? Border.all(
            color: Colors.orange,
            width: 2,
          ) : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 32.sp,
                ),
                if (isModified) ...[
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.edit,
                    color: Colors.orange,
                    size: 16.sp,
                  ),
                ],
                if (onTap != null && !isModified) ...[
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.edit,
                    color: colorScheme.onSurface.withValues(alpha:0.3),
                    size: 16.sp,
                  ),
                ],
                // 🎯 PLATEAU BADGE
                if (hasPlateauBadge && exerciseId != null) ...[
                  SizedBox(width: 4.w),
                  BlocBuilder<PlateauBloc, PlateauState>(
                    builder: (context, plateauState) {
                      if (plateauState is PlateauDetected) {
                        final plateauInfo = plateauState.getPlateauForExercise(exerciseId);
                        return PlateauBadge(plateauInfo: plateauInfo);
                      }
                      return PlateauBadge();
                    },
                  ),
                ],
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurface.withValues(alpha:0.7),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: isModified ? Colors.orange : colorScheme.onSurface,
              ),
            ),
            if (isModified) ...[
              SizedBox(height: 4.h),
              Text(
                'Modificato',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(WorkoutSessionActive state) {
    final colorScheme = Theme.of(context).colorScheme;
    final canPrev = _canGoToPrevious();
    final canNext = _canGoToNext();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              // Bottone Precedente
              SizedBox(
                width: 80.w,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: canPrev ? _goToPreviousGroup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canPrev ? colorScheme.secondary : colorScheme.surfaceContainerHighest,
                    foregroundColor: canPrev ? colorScheme.onSecondary : colorScheme.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: canPrev ? 1 : 0,
                  ),
                  child: Text(
                    'Prec',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Spazio centrale per i dots
              Expanded(
                child: Center(
                  child: _buildProgressDots(),
                ),
              ),

              // Bottone Successivo
              SizedBox(
                width: 80.w,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: canNext ? _goToNextGroup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canNext ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                    foregroundColor: canNext ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: canNext ? 1 : 0,
                  ),
                  child: Text(
                    'Succ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicatore numerico
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '${_currentGroupIndex + 1}',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
          
          SizedBox(width: 8.w),
          
          // Separatore
          Text(
            '/',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          
          SizedBox(width: 8.w),
          
          // Totale gruppi
          Text(
            '${_exerciseGroups.length}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoExercisesContent() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning,
            size: 64.sp,
            color: Colors.orange,
          ),
          SizedBox(height: 16.h),
          Text(
            'Nessun esercizio trovato',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onBackground,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Torna Indietro'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedContent(WorkoutSessionCompleted state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              size: 80.sp,
              color: Colors.green,
            ),
            SizedBox(height: 24.h),
            Text(
              '🎉 Allenamento Completato!',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              'Tempo Totale: ${_formatDuration(state.totalDuration)}',
              style: TextStyle(
                fontSize: 18.sp,
                color: colorScheme.onBackground,
              ),
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  'Termina Allenamento',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(ActiveWorkoutError state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: 64.sp,
              color: Colors.red,
            ),
            SizedBox(height: 16.h),
            Text(
              'Errore',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              state.message,
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                _activeWorkoutBloc.resetState();
                _initializeWorkout();
              },
              child: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultContent() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: CircularProgressIndicator(color: colorScheme.primary),
    );
  }

  // ============================================================================
  // 🆕 DIALOG WIDGETS (unchanged)
  // ============================================================================

  Widget _buildExitDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Colors.black.withValues(alpha:0.5),
      child: Center(
        child: Card(
          margin: EdgeInsets.all(32.w),
          color: colorScheme.surface,
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning,
                  size: 48.sp,
                  color: Colors.orange,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Uscire dall\'allenamento?',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'L\'allenamento verrà cancellato e tutti i progressi andranno persi.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: colorScheme.onSurface.withValues(alpha:0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _showExitDialog = false;
                          });
                        },
                        child: Text(
                          'Annulla',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showExitDialog = false;
                          });
                          _handleExitConfirmed();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Esci'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Colors.black.withValues(alpha:0.5),
      child: Center(
        child: Card(
          margin: EdgeInsets.all(32.w),
          color: colorScheme.surface,
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 48.sp,
                  color: Colors.green,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Completare l\'allenamento?',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'L\'allenamento verrà salvato con il tempo di ${_formatDuration(_elapsedTime)}.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: colorScheme.onSurface.withValues(alpha:0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _showCompleteDialog = false;
                          });
                        },
                        child: Text(
                          'Annulla',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showCompleteDialog = false;
                          });
                          _handleCompleteConfirmed();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Completa'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoRotationIndicator() {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _rotationIndicatorAnimation,
      builder: (context, child) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.black.withValues(alpha: 0.3 * _rotationIndicatorAnimation.value),
            child: Center(
              child: Transform.scale(
                scale: 0.8 + (0.2 * _rotationIndicatorAnimation.value),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icona di rotazione animata
                      AnimatedBuilder(
                        animation: _rotationIndicatorController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationIndicatorController.value * 2 * 3.14159,
                            child: Icon(
                              Icons.refresh,
                              size: 48.sp,
                              color: Colors.blue,
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Testo di transizione
                      Text(
                        'Passaggio a:',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      SizedBox(height: 8.h),
                      
                      Text(
                        _nextExerciseName ?? '',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Barra di progresso
                      Container(
                        width: 200.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _rotationIndicatorAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}