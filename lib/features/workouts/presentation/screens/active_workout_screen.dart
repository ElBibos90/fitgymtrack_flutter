// lib/features/workouts/presentation/screens/active_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart'; // 🔧 FIX 1: ALWAYS ON
import 'dart:async';

// Core imports
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/recovery_timer_popup.dart';
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

import '../../../../shared/widgets/rest_pause_timer_popup.dart';
import '../../../../shared/widgets/rest_pause_data_manager.dart';
import '../../../../shared/widgets/exercise_selection_dialog.dart';
import '../../../exercises/models/exercises_response.dart';
import '../../../exercises/services/image_service.dart';
import '../../../../core/config/app_config.dart';

// 🔧 FIX 2: IMPORT FOR SUPERSET DETECTION
import '../../models/exercise_group_models.dart';

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

  // 🆕 Dialog state
  bool _showExitDialog = false;
  bool _showCompleteDialog = false;

  // 🔧 FIX 2: PLATEAU - Gestione corretta con dismiss e single trigger
  bool _plateauAnalysisTriggered = false;
  final Set<int> _plateauAnalyzedExercises = {}; // Track analyzed exercises
  final Set<int> _dismissedPlateauExercises = {}; // Track dismissed plateaus

  // 🔧 FIX 4: APP LIFECYCLE - Stato background
  bool _isAppInBackground = false;

  @override
  void initState() {
    super.initState();
    //print("🚀 [SINGLE EXERCISE + ALL FIXES] initState - Scheda: ${widget.schedaId}");

    // 🔧 FIX 4: APP LIFECYCLE - Observer registration
    WidgetsBinding.instance.addObserver(this);

    _activeWorkoutBloc = context.read<ActiveWorkoutBloc>();
    _plateauBloc = context.read<PlateauBloc>(); // 🎯 INITIALIZE PLATEAU BLOC
    _initializeAnimations();
    _initializeWorkout();
  }

  bool _isRestPauseExercise(WorkoutExercise exercise) {
    return exercise.isRestPause &&
        exercise.restPauseReps != null &&
        exercise.restPauseReps!.isNotEmpty;
  }

  /// 🚀 STEP 1: Helper per parsare sequenza ripetizioni
  List<int> _parseRestPauseSequence(String? sequence) {
    if (sequence == null || sequence.isEmpty) {
      //print('⚠️ [REST-PAUSE] Empty sequence, returning empty list');
      return [];
    }

    try {
      final parsed = sequence.split('+').map((s) => int.tryParse(s.trim()) ?? 0).toList();
      //print('🔥 [REST-PAUSE] Parsed sequence "$sequence" -> $parsed');
      return parsed.where((n) => n > 0).toList(); // Rimuovi valori invalidi
    } catch (e) {
      //print('💥 [REST-PAUSE] Error parsing sequence "$sequence": $e');
      return [];
    }
  }

  bool _isValidRestPauseSequence(List<int> sequence) {
    final isValid = sequence.isNotEmpty &&
        sequence.length >= 2 &&
        sequence.every((n) => n > 0 && n <= 50); // Massimo 50 reps per micro-serie

    //print('🔥 [REST-PAUSE] Sequence validation: $sequence -> $isValid');
    return isValid;
  }

  @override
  void dispose() {
    //print("🚀 [SINGLE EXERCISE + ALL FIXES] dispose");

    // 🔧 FIX 1: ALWAYS ON - Disable wakelock on dispose
    _disableWakeLock();

    // 🔧 FIX 4: APP LIFECYCLE - Observer removal
    WidgetsBinding.instance.removeObserver(this);

    _workoutTimer?.cancel();
    _slideController.dispose();
    _pulseController.dispose();
    _completeButtonController.dispose();
    _pageController.dispose();
    _stopRecoveryTimer();
    super.dispose();
  }

  // 🔧 FIX 4: APP LIFECYCLE - Handle app state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    //print("🔧 [APP LIFECYCLE] State changed to: $state");

    switch (state) {
      case AppLifecycleState.resumed:
        if (_isAppInBackground) {
          //print("🔧 [APP LIFECYCLE] App resumed from background - refreshing workout state");
          _isAppInBackground = false;
          _handleAppResume();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _isAppInBackground = true;
        //print("🔧 [APP LIFECYCLE] App going to background");
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
      //print("🔧 [APP LIFECYCLE] Valid workout state found - continuing");
      // Riavvia timer se necessario
      if (_workoutTimer == null && _startTime != null) {
        _startWorkoutTimer();
      }
      // Riabilita wake lock
      _enableWakeLock();
    } else {
      //print("🔧 [APP LIFECYCLE] Invalid state detected - refreshing");
      setState(() {
        _currentStatus = "Ripristinando allenamento...";
      });
    }
  }

  // 🔧 FIX 1: ALWAYS ON - WakeLock methods
  Future<void> _enableWakeLock() async {
    try {
      await WakelockPlus.enable();
      //print("🔧 [ALWAYS ON] WakeLock enabled successfully");
    } catch (e) {
      //print("🔧 [ALWAYS ON] Error enabling WakeLock: $e");
    }
  }

  Future<void> _disableWakeLock() async {
    try {
      await WakelockPlus.disable();
      //print("🔧 [ALWAYS ON] WakeLock disabled successfully");
    } catch (e) {
      //print("🔧 [ALWAYS ON] Error disabling WakeLock: $e");
    }
  }

  void _handleRestPauseStart(WorkoutSessionActive state, WorkoutExercise exercise) {
    //print('🔥 [REST-PAUSE] Opening REST-PAUSE widget for: ${exercise.nome}');

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
            currentSeries: _getCompletedSeriesCount(state, exercise.schedaEsercizioId ?? exercise.id) + 1,
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

              //print("🚀 [REST-PAUSE] Series saved with data:");
              //print("🚀 [REST-PAUSE]   - isRestPause: 1");
              //print("🚀 [REST-PAUSE]   - restPauseReps: '${data.actualSequence}'");
              //print("🚀 [REST-PAUSE]   - restPauseRestSeconds: ${data.restSeconds}");
              //print("🚀 [REST-PAUSE]   - ripetizioni: ${data.totalActualReps}");

              // 🔧 FIX: Aggiungi logica auto-rotation per REST-PAUSE
              final updatedState = _getCurrentState();
              if (updatedState != null) {
                // Gestione timer di recupero (se appropriato)
                if (exercise.tempoRecupero > 0 && _shouldStartRecoveryTimer(exercise)) {
                  _startRecoveryTimer(exercise.tempoRecupero, exercise.nome);
                } else if (_isPartOfMultiExerciseGroup(exercise)) {
                  //print("🔧 [REST-PAUSE SUPERSET FIX] Skipping recovery timer for ${exercise.nome} - part of multi-exercise group");
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
                //print("⚠️ [REST-PAUSE] Could not get updated state for auto-rotation");
              }
            },
            onCompleteMicroSeries: (data, index, reps) {
              //print('🔥 [REST-PAUSE] Micro-serie ${index + 1} completata: $reps reps');
              //print('🔥 [REST-PAUSE] Progresso attuale: ${data.actualSequence}');
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

    //print("🚀 [REST-PAUSE] Completing REST-PAUSE series ${completedCount + 1} for exercise: ${exercise.nome}");
    //print("🚀 [REST-PAUSE] Data: ${restPauseData.toString()}");

    // Validazione dati REST-PAUSE
    if (!restPauseData.isValid() || !restPauseData.isCompleted) {
      //print("❌ [REST-PAUSE] Invalid or incomplete data");
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
    //print("🚀 [REST-PAUSE] Series saved:");
    //print("🚀 [REST-PAUSE]   - Weight: ${restPauseData.weight}kg");
    //print("🚀 [REST-PAUSE]   - Total reps: ${restPauseData.totalActualReps}");
    //print("🚀 [REST-PAUSE]   - Sequence: ${restPauseData.actualSequence}");
    //print("🚀 [REST-PAUSE]   - Rest seconds: ${restPauseData.restSeconds}");
    //print("🚀 [REST-PAUSE]   - Duration: ${restPauseData.totalDuration?.inSeconds ?? 0}s");

    // Gestione completamento esercizio e recupero normale
    final newCompletedCount = completedCount + 1;
    if (newCompletedCount >= exercise.serie) {
      //print("🎉 [REST-PAUSE] Esercizio ${exercise.nome} completato!");
    } else {
      // Avvia timer di recupero normale tra serie (se esiste il metodo)
      try {
        // Usa il metodo esistente per recovery timer se disponibile
        if (exercise.tempoRecupero > 0) {
          //print("🔄 [REST-PAUSE] Starting recovery timer: ${exercise.tempoRecupero}s");
          // TODO: Implementare timer recovery se necessario
        }
      } catch (e) {
        //print("⚠️ [REST-PAUSE] Recovery timer not available: $e");
      }
    }
  }


  bool _validateRestPauseData(RestPauseExecutionData data) {
    if (!data.isValid()) {
      //print("❌ [REST-PAUSE] Data validation failed: invalid data");
      return false;
    }

    if (!data.isCompleted) {
      //print("❌ [REST-PAUSE] Data validation failed: not completed");
      return false;
    }

    if (data.totalActualReps <= 0) {
      //print("❌ [REST-PAUSE] Data validation failed: no reps completed");
      return false;
    }

    if (data.actualSequence.isEmpty) {
      //print("❌ [REST-PAUSE] Data validation failed: empty sequence");
      return false;
    }

    return true;
  }

  // ============================================================================
  // 🔧 PERFORMANCE FIX: METODI DI CACHING (unchanged)
  // ============================================================================

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
          final currentSeriesNumber = completedSeriesCount + 1;

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

    // 🔧 PERFORMANCE FIX: Usa cache se disponibile
    if (_cachedWeights.containsKey(exerciseId)) {
      return _cachedWeights[exerciseId]!;
    }

    // 1. PRIORITÀ MASSIMA: Valori modificati dall'utente
    if (_modifiedWeights.containsKey(exerciseId)) {
      final weight = _modifiedWeights[exerciseId]!;
      _cachedWeights[exerciseId] = weight;
      return weight;
    }

    // 2. SERIE-SPECIFIC: Valori storici per la serie corrente
    final currentState = _getCurrentState();
    if (currentState != null) {
      final completedSeriesCount = _getCompletedSeriesCount(currentState, exerciseId);
      final currentSeriesNumber = completedSeriesCount + 1; // Prossima serie da fare

      // 🔧 PERFORMANCE FIX: Log ridotto
      if (DateTime.now().millisecondsSinceEpoch % 5000 < 100) {
        //print('[CONSOLE] [active_workout_screen]🔧 [PERF] Getting weight for exercise $exerciseId, series $currentSeriesNumber (completed: $completedSeriesCount)');
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

    // 🔧 PERFORMANCE FIX: Usa cache se disponibile
    if (_cachedReps.containsKey(exerciseId)) {
      return _cachedReps[exerciseId]!;
    }

    // 1. PRIORITÀ MASSIMA: Valori modificati dall'utente
    if (_modifiedReps.containsKey(exerciseId)) {
      final reps = _modifiedReps[exerciseId]!;
      _cachedReps[exerciseId] = reps;
      return reps;
    }

    // 2. SERIE-SPECIFIC: Valori storici per la serie corrente
    final currentState = _getCurrentState();
    if (currentState != null) {
      final completedSeriesCount = _getCompletedSeriesCount(currentState, exerciseId);
      final currentSeriesNumber = completedSeriesCount + 1; // Prossima serie da fare

      // 🔧 PERFORMANCE FIX: Log ridotto
      if (DateTime.now().millisecondsSinceEpoch % 5000 < 100) {
        //print('[CONSOLE] [active_workout_screen]🔧 [PERF] Getting reps for exercise $exerciseId, series $currentSeriesNumber (completed: $completedSeriesCount)');
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
    //print('[CONSOLE] [active_workout_screen]🔧 [CACHE] Invalidated cache for exercise $exerciseId');
  }

  /// 🔧 PERFORMANCE FIX: Pulisce tutta la cache
  void _clearCache() {
    _cachedWeights.clear();
    _cachedReps.clear();
    //print('[CONSOLE] [active_workout_screen]🔧 [CACHE] Cache cleared');
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
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
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
      _activeWorkoutBloc.startWorkout(_userId!, widget.schedaId);

      // 🔧 FIX 1: ALWAYS ON - Enable wakelock when workout starts
      await _enableWakeLock();

      setState(() {
        _isInitialized = true;
        _currentStatus = "Allenamento avviato";
      });

      _slideController.forward();

    } catch (e) {
      //print("🚀 [SINGLE EXERCISE + ALL FIXES] Error initializing: $e");
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
    //print("🚪 [EXIT] User confirmed exit - cancelling workout");

    final currentState = context.read<ActiveWorkoutBloc>().state;
    if (currentState is WorkoutSessionActive) {
      _activeWorkoutBloc.cancelWorkout(currentState.activeWorkout.id);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleCompleteConfirmed() {
    //print("✅ [COMPLETE] User confirmed completion");

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

    //print("🚀 [GROUPING] Created ${groups.length} exercise groups:");
    for (int i = 0; i < groups.length; i++) {
      //print("  Group $i: ${groups[i].map((e) => e.nome).join(', ')}");
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

  /// Verifica se l'esercizio è parte di un superset/circuit
  bool _isPartOfMultiExerciseGroup(WorkoutExercise exercise) {
    if (_exerciseGroups.isEmpty) return false;

    for (final group in _exerciseGroups) {
      if (group.contains(exercise) && group.length > 1) {
        return true;
      }
    }
    return false;
  }

  /// Verifica se è l'ultimo esercizio del gruppo superset/circuit
  bool _isLastExerciseInGroup(WorkoutExercise exercise) {
    if (_exerciseGroups.isEmpty) return true;

    for (final group in _exerciseGroups) {
      if (group.contains(exercise)) {
        final exerciseIndex = group.indexOf(exercise);
        final currentState = _getCurrentState();

        if (currentState != null && group.length > 1) {
          // 🔧 FIX: Logica corretta per superset/circuit/giant set
          // Il timer dovrebbe partire quando:
          // 1. È l'ultimo esercizio nell'ordine del gruppo (sempre)
          // 2. OPPURE tutti i prossimi esercizi hanno già fatto la serie corrente o più
          // 3. OPPURE questo esercizio ha completato tutte le sue serie previste

          final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
          final currentSeriesCount = _getCompletedSeriesCount(currentState, exerciseId);

          // Caso 1: È l'ultimo nell'ordine fisico → Timer parte sempre
          if (exerciseIndex == group.length - 1) {
            //print("🔧 [TIMER FIX] ${exercise.nome} - Last in group order → Timer starts");
            return true;
          }

          // Caso 3: Ha completato tutte le sue serie → Timer parte sempre
          if (currentSeriesCount >= exercise.serie) {
            //print("🔧 [TIMER FIX] ${exercise.nome} - Completed all series (${currentSeriesCount}/${exercise.serie}) → Timer starts");
            return true;
          }

          // Caso 2: È l'ultimo a dover fare la serie corrente nel giro
          bool isLastForCurrentRound = true;
          for (int i = exerciseIndex + 1; i < group.length; i++) {
            final nextExercise = group[i];
            final nextExerciseId = nextExercise.schedaEsercizioId ?? nextExercise.id;
            final nextSeriesCount = _getCompletedSeriesCount(currentState, nextExerciseId);

            // Se un esercizio successivo deve ancora fare la serie corrente
            if (nextSeriesCount <= currentSeriesCount) {
              isLastForCurrentRound = false;
              break;
            }
          }

          //print("🔧 [TIMER FIX] ${exercise.nome} - Exercise index: $exerciseIndex/${group.length-1}");
          //print("🔧 [TIMER FIX] ${exercise.nome} - Current series: $currentSeriesCount/${exercise.serie}");
          //print("🔧 [TIMER FIX] ${exercise.nome} - Is last for current round: $isLastForCurrentRound");

          return isLastForCurrentRound;
        }

        // Fallback: se è l'ultimo nell'ordine
        return exerciseIndex == group.length - 1;
      }
    }
    return true;
  }

  /// 🔧 FIX 3: Verifica se dovrebbe partire il timer di recupero
  bool _shouldStartRecoveryTimer(WorkoutExercise exercise) {
    // Se non è parte di un gruppo multi-esercizio, sempre true
    if (!_isPartOfMultiExerciseGroup(exercise)) {
      //print("🔧 [TIMER FIX] ${exercise.nome} - Single exercise, starting recovery timer");
      return true;
    }

    // Se è parte di un gruppo, verifica se è l'ultimo del giro corrente
    final isLastOfRound = _isLastExerciseInGroup(exercise);
    //print("🔧 [TIMER FIX] ${exercise.nome} - Multi-exercise group, is last of round: $isLastOfRound");

    // 🚀 NUOVO: Il timer parte sempre per l'ultimo del giro
    return isLastOfRound;
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
    //print("🔄 [RECOVERY POPUP] Starting recovery timer: $seconds seconds for $exerciseName");

    setState(() {
      _isRecoveryTimerActive = true;
      _recoverySeconds = seconds;
      _currentRecoveryExerciseName = exerciseName;
    });
  }

  void _stopRecoveryTimer() {
    //print("⏹️ [RECOVERY POPUP] Recovery timer stopped");

    setState(() {
      _isRecoveryTimerActive = false;
      _recoverySeconds = 0;
      _currentRecoveryExerciseName = null;
    });
  }

  void _onRecoveryTimerComplete() {
    //print("✅ [RECOVERY POPUP] Recovery completed!");

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

  //  print("🔥 [ISOMETRIC] Starting isometric timer: $seconds seconds for ${exercise.nome}");

    setState(() {
      _isIsometricTimerActive = true;
      _isometricSeconds = seconds;
      _currentIsometricExerciseName = exercise.nome;
      _pendingIsometricExercise = exercise;
    });
  }

  void _onIsometricTimerComplete() {
    //print("✅ [ISOMETRIC] Isometric timer completed!");

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
    //print("❌ [ISOMETRIC] Isometric timer cancelled");

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

  //  print("✏️ [EDIT] Modified parameters for ${exercise.nome}: ${weight}kg, $reps ${exercise.isIsometric ? 'seconds' : 'reps'}");

    // 🔧 PERFORMANCE FIX: Rimosso messaggio di aggiornamento parametri per migliorare performance
    // CustomSnackbar.show(
    //   context,
    //   message: "Parametri aggiornati: ${weight.toStringAsFixed(1)}kg, $reps ${exercise.isIsometric ? 'secondi' : 'ripetizioni'}",
    //   isSuccess: true,
    // );

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
      //print("🔧 [PLATEAU FIX] Skipping analysis for exercise $exerciseId - already analyzed or dismissed");
      return;
    }

    final weight = _getEffectiveWeight(exercise);
    final reps = _getEffectiveReps(exercise);

    //print("🔧 [PLATEAU FIX] Triggering analysis for ${exercise.nome}: ${weight}kg x $reps");

    _plateauAnalyzedExercises.add(exerciseId);
    _plateauBloc.analyzeExercisePlateau(exerciseId, exercise.nome, weight, reps);
  }

  /// 🔧 FIX 2: Auto-trigger plateau SOLO UNA VOLTA per tutti gli esercizi
  void _triggerPlateauAnalysisForAllExercises(WorkoutSessionActive state) {
    //print("🔧 [PLATEAU FIX] Starting SINGLE plateau analysis for all exercises");

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

    if (completedCount >= exercise.serie) {
      CustomSnackbar.show(
        context,
        message: "Esercizio già completato!",
        isSuccess: false,
      );
      return;
    }

    //print("🚀 [SINGLE EXERCISE] Completing series ${completedCount + 1} for exercise: ${exercise.nome}");

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

    final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';
    _activeWorkoutBloc.saveSeries(
      state.activeWorkout.id,
      [seriesData],
      requestId,
    );

    // 🔧 PERFORMANCE FIX: Invalida cache dopo completamento serie
    _invalidateCacheForExercise(exerciseId);

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
      //print("🔧 [SUPERSET FIX] Skipping recovery timer for ${exercise.nome} - part of multi-exercise group");
    }

    final updatedState = _getCurrentState();
    if (updatedState != null) {
      _handleAutoRotation(updatedState);
    } else {
      //print("⚠️ [REST-PAUSE] Could not get updated state for auto-rotation");
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
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _currentExerciseInGroup = nextExerciseIndex;
          });

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

    //print("🎉 [AUTO-ROTATION] All exercises in group are completed!");
    return isNewGroup ? 0 : _currentExerciseInGroup;
  }

  WorkoutSessionActive? _getCurrentState() {
    final currentState = context.read<ActiveWorkoutBloc>().state;
    return currentState is WorkoutSessionActive ? currentState : null;
  }

  void _handleCompleteWorkout(WorkoutSessionActive state) {
    print("🚀 [SINGLE EXERCISE] Completing workout");

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
                  backgroundColor: Theme.of(context).colorScheme.background,
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
      //print("🚀 [SINGLE EXERCISE MINIMALE] Workout session started");
      _startWorkoutTimer();

      // 🔧 PERFORMANCE FIX: Rimosso messaggio di avvio allenamento per migliorare performance
      // CustomSnackbar.show(
      //   context,
      //   message: "Allenamento avviato con successo! 💪",
      //   isSuccess: true,
      // );
    }

    if (state is WorkoutSessionActive) {
      //print("🚀 [SINGLE EXERCISE MINIMALE] Active session with ${state.exercises.length} exercises");

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
      //print("🚀 [SINGLE EXERCISE MINIMALE] Workout completed");
      _stopWorkoutTimer();
      _stopRecoveryTimer();
      _completeButtonController.stop();

      // 🔧 FIX 1: ALWAYS ON - Disable wakelock on completion
      _disableWakeLock();

      // 🔧 PERFORMANCE FIX: Pulisce cache a fine allenamento
      _clearCache();
    }

    if (state is WorkoutSessionCancelled) {
      //print("🚀 [SINGLE EXERCISE MINIMALE] Workout cancelled");
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

      Navigator.of(context).pop();
    }

    if (state is ActiveWorkoutError) {
      //print("🚀 [SINGLE EXERCISE MINIMALE] Error: ${state.message}");

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
        //print("🔧 [PLATEAU FIX] Plateau rilevati: ${activePlateaus.length}");

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
          //print("🔧 [PLATEAU FIX] Exercise ${plateau.exerciseId} dismissed - won't retrigger");
        }
      }
    }

    if (state is PlateauError) {
      //print("🔧 [PLATEAU FIX] Error: ${state.message}");
      // Don't show error to user - plateau is optional feature
    }
  }

  // ============================================================================
  // CONTINUE WITH ALL OTHER UI METHODS (unchanged)
  // ============================================================================

  Widget _buildInitializingScreen() {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
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
                backgroundColor: colorScheme.surfaceVariant,
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
          Text(
            'Allenamento',
            style: TextStyle(fontSize: 18.sp),
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
    return Stack(
      children: [
        _buildMainContent(state),

        if (_isRecoveryTimerActive)
          RecoveryTimerPopup(
            initialSeconds: _recoverySeconds,
            isActive: _isRecoveryTimerActive,
            exerciseName: _currentRecoveryExerciseName,
            onTimerComplete: _onRecoveryTimerComplete,
            onTimerStopped: _stopRecoveryTimer,
            onTimerDismissed: () {
              _stopRecoveryTimer();
            },
          ),

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

        // 🔧 FASE 1: Dialog per aggiungere esercizi (placeholder)
        if (false) // Temporaneamente disabilitato
          Container(), // Placeholder per il dialog
      ],
    );
  }

  Widget _buildMainContent(ActiveWorkoutState state) {
    if (state is ActiveWorkoutLoading) {
      return _buildLoadingContent();
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

  Widget _buildActiveContent(WorkoutSessionActive state) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    final completedSeries = _getCompletedSeriesCount(state, exerciseId);
    final isCompleted = _isExerciseCompleted(state, exercise);
    final exerciseType = _getExerciseTypeLabel(exercise);
    final exerciseColor = _getExerciseTypeColor(exercise);

    // 🔧 PERFORMANCE FIX: Pre-carica cache per questo esercizio
    _updateCacheForExercise(exerciseId, exercise);

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: exerciseColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: exerciseColor.withValues(alpha:0.3)),
              ),
              child: Text(
                '$exerciseType: ${exercise.nome}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: exerciseColor,
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // 🎯 NUOVO LAYOUT A DUE COLONNE: Info a sinistra, immagine a destra
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // COLONNA SINISTRA: Nome esercizio e serie
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome esercizio
                      Text(
                        exercise.nome,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 16.h),

                      // 📱 CARD SERIE COMPATTA - Layout Verticale
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha:0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label "Serie"
                            Text(
                              'Serie',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: colorScheme.onSurface.withValues(alpha:0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            SizedBox(height: 4.h),

                            // Numero delle serie
                            Text(
                              '$completedSeries/${exercise.serie}',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? Colors.green : exerciseColor,
                              ),
                            ),

                            SizedBox(height: 8.h),

                            // Puntini indicatori in fila
                            Row(
                              children: List.generate(exercise.serie, (i) {
                                return Container(
                                  margin: EdgeInsets.only(right: i < exercise.serie - 1 ? 4.w : 0),
                                  width: 6.w,
                                  height: 6.w,
                                  decoration: BoxDecoration(
                                    color: i < completedSeries
                                        ? exerciseColor
                                        : colorScheme.surfaceVariant,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 20.w),

                // COLONNA DESTRA: Immagine esercizio
                if (exercise.immagineNome != null) ...[
                  Container(
                    width: 160.w,
                    height: 160.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConfig.radiusM),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppConfig.radiusM),
                      child: ImageService.buildGifImage(
                        imageUrl: ImageService.getImageUrl(exercise.immagineNome),
                        width: 160.w,
                        height: 160.w,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ] else ...[
                  // Placeholder se non c'è immagine
                  Container(
                    width: 160.w,
                    height: 160.w,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppConfig.radiusM),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      size: 48.w,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ],
            ),

            SizedBox(height: 32.h),
        if (_isRestPauseExercise(exercise)) ...[
    Container(
    margin: EdgeInsets.only(bottom: 16.h),
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
    decoration: BoxDecoration(
    color: Colors.deepPurple.withValues(alpha:0.1),
    borderRadius: BorderRadius.circular(8.r),
    border: Border.all(color: Colors.deepPurple, width: 1),
    ),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(Icons.flash_on, color: Colors.deepPurple, size: 16.w),
    SizedBox(width: 4.w),
    Text(
    'REST-PAUSE: ${exercise.restPauseReps}',
    style: TextStyle(
    color: Colors.deepPurple,
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    ),
    ),
    ],
    ),
    ),
        ],

            Row(
              children: [
                Expanded(
                  child: _buildParameterCard(
                    'Peso',
                    '${_getEffectiveWeight(exercise).toStringAsFixed(1)} kg',
                    Icons.fitness_center,
                    exerciseColor,
                    onTap: () => _editExerciseParameters(exercise),
                    isModified: _modifiedWeights.containsKey(exercise.schedaEsercizioId ?? exercise.id),
                    hasPlateauBadge: _hasPlateauForExercise(exerciseId),
                    exerciseId: exerciseId,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildParameterCard(
                    exercise.isIsometric ? 'Secondi' : 'Ripetizioni',
                    '${_getEffectiveReps(exercise)}',
                    exercise.isIsometric ? Icons.timer : Icons.repeat,
                    exercise.isIsometric ? Colors.deepPurple : Colors.green,
                    onTap: () => _editExerciseParameters(exercise),
                    isModified: _modifiedReps.containsKey(exercise.schedaEsercizioId ?? exercise.id),
                    hasPlateauBadge: _hasPlateauForExercise(exerciseId),
                    exerciseId: exerciseId,
                  ),
                ),
              ],
            ),

            SizedBox(height: 32.h),

            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: isCompleted
                    ? null
                    : exercise.isIsometric
                    ? () => _startIsometricTimer(exercise)
                    : _isRestPauseExercise(exercise)
                    ? () => _handleRestPauseStart(state, exercise)  // 🚀 NUOVO: Handler REST-PAUSE
                    : () => _handleCompleteSeries(state, exercise),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? Colors.green
                      : exercise.isIsometric
                      ? Colors.deepPurple
                      : exerciseColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: isCompleted ? 0 : 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (exercise.isIsometric && !isCompleted) ...[
                      Icon(Icons.timer, size: 20.sp),
                      SizedBox(width: 8.w),
                    ],
                    Text(
                      isCompleted
                          ? '✅ Esercizio Completato'
                          : exercise.isIsometric
                          ? '🔥 Avvia Isometrico ${_getEffectiveReps(exercise)}s'
                          : _isRestPauseExercise(exercise)  // 🚀 NUOVA CONDIZIONE
                          ? '⚡ Avvia REST-PAUSE'           // 🚀 NUOVO TESTO
                          : 'Completa Serie ${completedSeries + 1}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiExercisePage(WorkoutSessionActive state, List<WorkoutExercise> group) {
    final colorScheme = Theme.of(context).colorScheme;
    final groupType = group.first.setType;
    final groupColor = _getExerciseTypeColor(group.first);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: groupColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: groupColor.withValues(alpha:0.3)),
              ),
              child: Text(
                '${groupType.toUpperCase()}: ${group.length} esercizi',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: groupColor,
                ),
              ),
            ),

            SizedBox(height: 24.h),

            Container(
              height: 50.h,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Row(
                children: group.asMap().entries.map((entry) {
                  final index = entry.key;
                  final exercise = entry.value;
                  final isSelected = index == _currentExerciseInGroup;
                  final exId = exercise.schedaEsercizioId ?? exercise.id;
                  final exCompleted = _getCompletedSeriesCount(state, exId);
                  final exIsCompleted = _isExerciseCompleted(state, exercise);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentExerciseInGroup = index;
                        });

                        // 🔧 PERFORMANCE FIX: Invalida cache quando cambia esercizio
                        _clearCache();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: isSelected ? groupColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: groupColor.withValues(alpha:0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  exIsCompleted
                                      ? Icons.check_circle
                                      : exercise.isIsometric
                                      ? Icons.timer
                                      : Icons.fitness_center,
                                  color: isSelected ? Colors.white : groupColor,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${exCompleted}/${exercise.serie}',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : groupColor,
                                  ),
                                ),
                                // 🎯 PLATEAU BADGE FOR TABS - Solo punto rosso discreto
                                if (_hasPlateauForExercise(exId)) ...[
                                  SizedBox(width: 2.w),
                                  Container(
                                    width: 6.w,
                                    height: 6.w,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(3.r),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              exercise.nome.length > 10
                                  ? '${exercise.nome.substring(0, 10)}...'
                                  : exercise.nome,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 32.h),

            // 🎯 NUOVO LAYOUT A DUE COLONNE: Info a sinistra, immagine a destra
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // COLONNA SINISTRA: Nome esercizio e serie
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome esercizio
                      Text(
                        currentExercise.nome,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 16.h),

                      // 📱 CARD SERIE COMPATTA - Layout Verticale
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha:0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label "Serie"
                            Text(
                              'Serie',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: colorScheme.onSurface.withValues(alpha:0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            SizedBox(height: 4.h),

                            // Numero delle serie
                            Text(
                              '$completedSeries/${currentExercise.serie}',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? Colors.green : groupColor,
                              ),
                            ),

                            SizedBox(height: 8.h),

                            // Puntini indicatori in fila
                            Row(
                              children: List.generate(currentExercise.serie, (i) {
                                return Container(
                                  margin: EdgeInsets.only(right: i < currentExercise.serie - 1 ? 4.w : 0),
                                  width: 6.w,
                                  height: 6.w,
                                  decoration: BoxDecoration(
                                    color: i < completedSeries
                                        ? groupColor
                                        : colorScheme.surfaceVariant,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 20.w),

                // COLONNA DESTRA: Immagine esercizio
                if (currentExercise.immagineNome != null) ...[
                  Container(
                    width: 160.w,
                    height: 160.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConfig.radiusM),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppConfig.radiusM),
                      child: ImageService.buildGifImage(
                        imageUrl: ImageService.getImageUrl(currentExercise.immagineNome),
                        width: 160.w,
                        height: 160.w,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ] else ...[
                  // Placeholder se non c'è immagine
                  Container(
                    width: 160.w,
                    height: 160.w,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppConfig.radiusM),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      size: 48.w,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ],
            ),

            SizedBox(height: 32.h),

            if (_isRestPauseExercise(currentExercise)) ...[
              Container(
                margin: EdgeInsets.only(bottom: 16.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.deepPurple, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_on, color: Colors.deepPurple, size: 16.w),
                    SizedBox(width: 4.w),
                    Text(
                      'REST-PAUSE: ${currentExercise.restPauseReps}',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: _buildParameterCard(
                    'Peso',
                    '${_getEffectiveWeight(currentExercise).toStringAsFixed(1)} kg',
                    Icons.fitness_center,
                    groupColor,
                    onTap: () => _editExerciseParameters(currentExercise),
                    isModified: _modifiedWeights.containsKey(currentExercise.schedaEsercizioId ?? currentExercise.id),
                    hasPlateauBadge: _hasPlateauForExercise(exerciseId),
                    exerciseId: exerciseId,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildParameterCard(
                    currentExercise.isIsometric ? 'Secondi' : 'Ripetizioni',
                    '${_getEffectiveReps(currentExercise)}',
                    currentExercise.isIsometric ? Icons.timer : Icons.repeat,
                    currentExercise.isIsometric ? Colors.deepPurple : groupColor,
                    onTap: () => _editExerciseParameters(currentExercise),
                    isModified: _modifiedReps.containsKey(currentExercise.schedaEsercizioId ?? currentExercise.id),
                    hasPlateauBadge: _hasPlateauForExercise(exerciseId),
                    exerciseId: exerciseId,
                  ),
                ),
              ],
            ),

            SizedBox(height: 32.h),

            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: isCompleted
                    ? null
                    : currentExercise.isIsometric
                    ? () => _startIsometricTimer(currentExercise)
                    : _isRestPauseExercise(currentExercise)
                    ? () => _handleRestPauseStart(state, currentExercise)  // 🚀 NUOVO: Handler REST-PAUSE
                    : () => _handleCompleteSeries(state, currentExercise),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? Colors.green
                      : currentExercise.isIsometric
                      ? Colors.deepPurple
                      : groupColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: isCompleted ? 0 : 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (currentExercise.isIsometric && !isCompleted) ...[
                      Icon(Icons.timer, size: 20.sp),
                      SizedBox(width: 8.w),
                    ],
                    Text(
                      isCompleted
                          ? '✅ Esercizio Completato'
                          : currentExercise.isIsometric
                          ? '🔥 Avvia Isometrico ${_getEffectiveReps(currentExercise)}s'
                          : _isRestPauseExercise(currentExercise)  // 🚀 NUOVA CONDIZIONE
                          ? '⚡ Avvia REST-PAUSE'                  // 🚀 NUOVO TESTO
                          : 'Completa Serie ${completedSeries + 1}',
                      style: TextStyle(
                        fontSize: 16.sp,  // Nota: font size diverso per multi-exercise
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            if (isGroupComplete)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  '✅ ${groupType.toUpperCase()} COMPLETATO!',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            SizedBox(height: 100.h),
          ],
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
        child: Row(
          children: [
            SizedBox(
              width: 80.w,
              height: 48.h,
              child: ElevatedButton(
                onPressed: canPrev ? _goToPreviousGroup : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canPrev ? colorScheme.secondary : colorScheme.surfaceVariant,
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

            const Spacer(),

            Row(
              children: List.generate(_exerciseGroups.length, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: index == _currentGroupIndex ? 24.w : 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: index == _currentGroupIndex
                        ? colorScheme.primary
                        : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                );
              }),
            ),

            const Spacer(),

            SizedBox(
              width: 80.w,
              height: 48.h,
              child: ElevatedButton(
                onPressed: canNext ? _goToNextGroup : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canNext ? colorScheme.primary : colorScheme.surfaceVariant,
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
}