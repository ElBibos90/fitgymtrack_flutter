// lib/features/workouts/presentation/screens/active_workout_screen.dart
// 🚀 FASE 5: VERSIONE CORRETTA CON TUTTI GLI ERRORI SISTEMATI

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';

// Core imports
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/recovery_timer_popup.dart';
import '../../../../shared/widgets/isometric_timer_popup.dart';
import '../../../../shared/widgets/parameter_edit_dialog.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/di/dependency_injection.dart';

// 🚀 FASE 5: NUOVE IMPORTAZIONI REST-PAUSE
import '../../../../shared/widgets/rest_pause_timer_popup.dart';
import '../../../../shared/widgets/rest_pause_execution_widget.dart';
import '../../models/rest_pause_state.dart'; // 🔧 FIX: Import file separato

// BLoC imports
import '../../bloc/active_workout_bloc.dart';
import '../../models/active_workout_models.dart';
import '../../models/workout_plan_models.dart';

// Plateau imports
import '../../bloc/plateau_bloc.dart';
import '../../models/plateau_models.dart';
import '../../../../shared/widgets/plateau_widgets.dart';

// Exercise group imports
import '../../models/exercise_group_models.dart';

/// ActiveWorkoutScreen - SINGLE EXERCISE FOCUSED WITH SUPERSET/CIRCUIT GROUPING + REST-PAUSE SUPPORT
/// ✅ Completo: Dark Theme + Dialogs + Complete Button + Plateau Integration + Performance Fix + 🚀 REST-PAUSE
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
    with TickerProviderStateMixin, WidgetsBindingObserver {

  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  // BLoC references
  late ActiveWorkoutBloc _activeWorkoutBloc;
  late PlateauBloc _plateauBloc;

  // Timer management
  Timer? _workoutTimer;
  Duration _elapsedTime = Duration.zero;
  DateTime? _startTime;

  // Recovery timer
  bool _isRecoveryTimerActive = false;
  int _recoverySeconds = 90;
  String _currentRecoveryExerciseName = "";

  // Isometric timer
  bool _isIsometricTimerActive = false;
  int _isometricSeconds = 30;
  String? _currentIsometricExerciseName;
  WorkoutExercise? _pendingIsometricExercise;

  // 🚀 FASE 5: REST-PAUSE STATO
  RestPauseState? _currentRestPauseState;
  bool _isRestPauseTimerActive = false;
  String? _currentRestPauseExerciseName;

  // Initialization
  bool _isInitialized = false;
  String _currentStatus = "Inizializzazione...";
  int? _userId;

  // Exercise grouping
  List<List<WorkoutExercise>> _exerciseGroups = [];
  int _currentGroup = 0;
  int _currentExerciseInGroup = 0;

  // Dialog states
  bool _showExitDialog = false;
  bool _showCompleteDialog = false;

  // Plateau tracking
  Set<int> _dismissedPlateauExercises = {};

  // Animations
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _completeButtonController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _completeButtonAnimation;

  // Performance cache
  final Map<int, WorkoutExercise> _exerciseCache = {};
  final Map<int, double> _weightCache = {};
  final Map<int, int> _repsCache = {};

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  @override
  void initState() {
    super.initState();

    // Setup animazioni
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _completeButtonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _completeButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _completeButtonController,
      curve: Curves.easeInOut,
    ));

    // Setup BLoCs
    _plateauBloc = context.read<PlateauBloc>();

    // Lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Initialize workout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWorkout();
    });
  }

  @override
  void dispose() {
    // Cleanup timers
    _stopWorkoutTimer();
    _stopRecoveryTimer();

    // 🚀 FASE 5: Cleanup REST-PAUSE
    _resetRestPauseState();

    // Cleanup animations
    _slideController.dispose();
    _pulseController.dispose();
    _completeButtonController.dispose();

    // Disable wakelock
    _disableWakeLock();

    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        print("🔧 [APP LIFECYCLE] App paused - keeping wakelock active");
        break;
      case AppLifecycleState.resumed:
        print("🔧 [APP LIFECYCLE] App resumed - wakelock should still be active");
        if (_isInitialized) {
          _enableWakeLock();
        }
        break;
      case AppLifecycleState.detached:
        print("🔧 [APP LIFECYCLE] App detached - disabling wakelock");
        _disableWakeLock();
        break;
      default:
        break;
    }
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

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

      await _enableWakeLock();

      setState(() {
        _isInitialized = true;
        _currentStatus = "Allenamento avviato";
      });

      _slideController.forward();

    } catch (e) {
      print("🚀 [ACTIVE WORKOUT] Error initializing: $e");
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
  // WAKELOCK MANAGEMENT
  // ============================================================================

  Future<void> _enableWakeLock() async {
    try {
      await WakelockPlus.enable();
      print("🔧 [WAKELOCK] Enabled successfully");
    } catch (e) {
      print("🔧 [WAKELOCK] Error enabling: $e");
    }
  }

  Future<void> _disableWakeLock() async {
    try {
      await WakelockPlus.disable();
      print("🔧 [WAKELOCK] Disabled successfully");
    } catch (e) {
      print("🔧 [WAKELOCK] Error disabling: $e");
    }
  }

  // ============================================================================
  // 🚀 FASE 5: REST-PAUSE UTILITY METHODS
  // ============================================================================

  /// Parsa una stringa sequenza REST-PAUSE in una lista di interi
  List<int> _parseRestPauseSequence(String? sequence) {
    if (sequence == null || sequence.isEmpty) {
      print("🚀 [REST-PAUSE] Empty sequence provided");
      return [];
    }

    try {
      final parts = sequence.split('+');
      final parsed = parts
          .map((s) => int.tryParse(s.trim()) ?? 0)
          .where((rep) => rep > 0)
          .toList();

      print("🚀 [REST-PAUSE] Parsed sequence '$sequence' → $parsed");
      return parsed;
    } catch (e) {
      print("🚀 [REST-PAUSE] Error parsing sequence '$sequence': $e");
      return [];
    }
  }

  /// Verifica se un esercizio è configurato per REST-PAUSE
  bool _isExerciseRestPause(WorkoutExercise exercise) {
    final isEnabled = exercise.isRestPause;
    final hasSequence = exercise.restPauseReps != null && exercise.restPauseReps!.isNotEmpty;

    print("🚀 [REST-PAUSE] Exercise '${exercise.nome}': enabled=$isEnabled, sequence='${exercise.restPauseReps}'");
    return isEnabled && hasSequence;
  }

  /// Inizializza lo stato REST-PAUSE per un esercizio
  RestPauseState? _initializeRestPauseState(WorkoutExercise exercise) {
    if (!_isExerciseRestPause(exercise)) {
      return null;
    }

    final sequence = _parseRestPauseSequence(exercise.restPauseReps);
    if (sequence.isEmpty) {
      print("🚀 [REST-PAUSE] Invalid sequence for exercise '${exercise.nome}'");
      return null;
    }

    final state = RestPauseState(
      sequence: sequence,
      currentMicroSeries: 0,
      restSeconds: exercise.restPauseRestSeconds,
      isInRestPause: false,
      completedReps: [],
      totalRepsCompleted: 0,
    );

    print("🚀 [REST-PAUSE] Initialized state for '${exercise.nome}': ${state.sequence}");
    return state;
  }

  /// Avanza alla prossima micro-serie REST-PAUSE
  RestPauseState? _advanceToNextMicroSeries(RestPauseState currentState, int completedReps) {
    if (!currentState.hasMoreMicroSeries) {
      print("🚀 [REST-PAUSE] No more micro-series available");
      return null;
    }

    final newCompletedReps = [...currentState.completedReps, completedReps];
    final newTotalReps = currentState.totalRepsCompleted + completedReps;

    final nextState = currentState.copyWith(
      currentMicroSeries: currentState.currentMicroSeries + 1,
      completedReps: newCompletedReps,
      totalRepsCompleted: newTotalReps,
      isInRestPause: !currentState.isLastMicroSeries,
    );

    print("🚀 [REST-PAUSE] Advanced to micro-series ${nextState.currentMicroSeries}: completed=${nextState.completedSequenceString}, total=${nextState.totalRepsCompleted}");
    return nextState;
  }

  /// Resetta lo stato REST-PAUSE
  void _resetRestPauseState() {
    setState(() {
      _currentRestPauseState = null;
      _isRestPauseTimerActive = false;
      _currentRestPauseExerciseName = null;
    });
    print("🚀 [REST-PAUSE] State reset");
  }

  /// Avvia il timer mini-recupero REST-PAUSE
  void _startRestPauseTimer(RestPauseState state, String exerciseName) {
    setState(() {
      _isRestPauseTimerActive = true;
      _currentRestPauseExerciseName = exerciseName;
    });

    print("🚀 [REST-PAUSE] Started ${state.restSeconds}s timer for '${exerciseName}'");
  }

  /// Gestisce il completamento del timer mini-recupero
  void _onRestPauseTimerComplete() {
    print("🚀 [REST-PAUSE] Mini-recovery completed");

    setState(() {
      _isRestPauseTimerActive = false;
      if (_currentRestPauseState != null) {
        _currentRestPauseState = _currentRestPauseState!.copyWith(isInRestPause: false);
      }
    });

    CustomSnackbar.show(
      context,
      message: "⚡ Mini-recupero completato! Inizia la prossima micro-serie",
      isSuccess: true,
      duration: const Duration(seconds: 2),
    );
  }

  /// Gestisce l'interruzione del timer mini-recupero
  void _stopRestPauseTimer() {
    print("🚀 [REST-PAUSE] Mini-recovery timer stopped");

    setState(() {
      _isRestPauseTimerActive = false;
      if (_currentRestPauseState != null) {
        _currentRestPauseState = _currentRestPauseState!.copyWith(isInRestPause: false);
      }
    });
  }

  /// Ottiene info sulla prossima micro-serie
  String? _getNextMicroSeriesInfo(RestPauseState state) {
    final nextReps = state.nextTargetReps;
    if (nextReps != null) {
      return 'Prossima micro-serie: ${nextReps} reps';
    }
    return null;
  }

  // ============================================================================
  // TIMER MANAGEMENT
  // ============================================================================

  void _startWorkoutTimer() {
    _startTime = DateTime.now();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _startTime != null) {
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

  void _startRecoveryTimer(int seconds, String exerciseName) {
    setState(() {
      _isRecoveryTimerActive = true;
      _recoverySeconds = seconds;
      _currentRecoveryExerciseName = exerciseName;
    });
  }

  void _stopRecoveryTimer() {
    setState(() {
      _isRecoveryTimerActive = false;
    });
  }

  void _onRecoveryTimerComplete() {
    setState(() {
      _isRecoveryTimerActive = false;
    });

    CustomSnackbar.show(
      context,
      message: "⏰ Tempo di recupero completato!",
      isSuccess: true,
      duration: const Duration(seconds: 2),
    );
  }

  // ============================================================================
  // ISOMETRIC TIMER MANAGEMENT
  // ============================================================================

  void _startIsometricTimer(int seconds, String exerciseName, WorkoutExercise exercise) {
    setState(() {
      _isIsometricTimerActive = true;
      _isometricSeconds = seconds;
      _currentIsometricExerciseName = exerciseName;
      _pendingIsometricExercise = exercise;
    });
  }

  void _onIsometricTimerComplete() {
    print("🔥 [ISOMETRIC] Timer completed");

    setState(() {
      _isIsometricTimerActive = false;
    });

    if (_pendingIsometricExercise != null) {
      final currentState = _getCurrentState();
      if (currentState != null) {
        _handleCompleteSeries(currentState, _pendingIsometricExercise!);
      }
      _pendingIsometricExercise = null;
    }

    CustomSnackbar.show(
      context,
      message: "🔥 Tenuta isometrica completata!",
      isSuccess: true,
      duration: const Duration(seconds: 2),
    );
  }

  void _onIsometricTimerCancelled() {
    print("❌ [ISOMETRIC] Timer cancelled");

    setState(() {
      _isIsometricTimerActive = false;
      _pendingIsometricExercise = null;
    });
  }

  // ============================================================================
  // SERIES COMPLETION LOGIC
  // ============================================================================

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

    // 🚀 FASE 5: GESTIONE REST-PAUSE
    if (_isExerciseRestPause(exercise)) {
      _handleRestPauseSeries(state, exercise, completedCount);
    } else {
      _handleNormalSeries(state, exercise, completedCount);
    }
  }

  /// Gestisce il completamento di una serie normale (senza REST-PAUSE)
  void _handleNormalSeries(WorkoutSessionActive state, WorkoutExercise exercise, int completedCount) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;

    print("🚀 [NORMAL SERIES] Completing series ${completedCount + 1} for exercise: ${exercise.nome}");

    // Gestione isometrica speciale
    if (exercise.isIsometric) {
      _startIsometricTimer(exercise.ripetizioni, exercise.nome, exercise);
      return;
    }

    final effectiveWeight = _getEffectiveWeight(exercise);
    final effectiveReps = _getEffectiveReps(exercise);

    final seriesData = SeriesData(
      schedaEsercizioId: exerciseId,
      peso: effectiveWeight,
      ripetizioni: effectiveReps,
      completata: 1,
      tempoRecupero: exercise.tempoRecupero,
      note: 'Completata da Single Exercise Screen',
      serieNumber: completedCount + 1,
      serieId: 'series_${DateTime.now().millisecondsSinceEpoch}',
    );

    _saveSeriesAndProvideRecovery(state, exercise, seriesData, completedCount);
  }

  /// 🚀 FASE 5: Gestisce il completamento di una serie REST-PAUSE
  void _handleRestPauseSeries(WorkoutSessionActive state, WorkoutExercise exercise, int completedCount) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;

    print("🚀 [REST-PAUSE] Starting REST-PAUSE series ${completedCount + 1} for exercise: ${exercise.nome}");

    // Se non c'è uno stato REST-PAUSE attivo, inizializza
    if (_currentRestPauseState == null) {
      _currentRestPauseState = _initializeRestPauseState(exercise);

      if (_currentRestPauseState == null) {
        print("🚀 [REST-PAUSE] Failed to initialize state - falling back to normal series");
        _handleNormalSeries(state, exercise, completedCount);
        return;
      }

      print("🚀 [REST-PAUSE] Initialized for micro-series 1/${_currentRestPauseState!.sequence.length}");
      _showRestPauseStartMessage(exercise, _currentRestPauseState!);
      return;
    }

    // Stato REST-PAUSE già attivo - gestisci completamento micro-serie
    _handleMicroSeriesCompletion(state, exercise, completedCount);
  }

  /// Mostra messaggio di inizio REST-PAUSE
  void _showRestPauseStartMessage(WorkoutExercise exercise, RestPauseState state) {
    CustomSnackbar.show(
      context,
      message: "🔥 REST-PAUSE attivo! Micro-serie 1/${state.sequence.length}: ${state.currentTargetReps} reps",
      isSuccess: true,
      duration: const Duration(seconds: 3),
    );
  }

  /// Gestisce il completamento di una micro-serie REST-PAUSE
  void _handleMicroSeriesCompletion(WorkoutSessionActive state, WorkoutExercise exercise, int completedCount) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    final currentState = _currentRestPauseState!;

    final effectiveReps = _getEffectiveReps(exercise);

    print("🚀 [REST-PAUSE] Micro-series ${currentState.currentMicroSeries + 1} completed with $effectiveReps reps");

    final nextState = _advanceToNextMicroSeries(currentState, effectiveReps);

    if (nextState == null || !nextState.hasMoreMicroSeries) {
      _completeRestPauseSeries(state, exercise, currentState, effectiveReps, completedCount);
    } else {
      _startMicroSeriesRecovery(nextState, exercise);
    }
  }

  /// Avvia il mini-recupero tra micro-serie
  void _startMicroSeriesRecovery(RestPauseState nextState, WorkoutExercise exercise) {
    setState(() {
      _currentRestPauseState = nextState;
    });

    final currentMicro = nextState.currentMicroSeries;
    final totalMicro = nextState.sequence.length;
    final nextReps = nextState.currentTargetReps;

    CustomSnackbar.show(
      context,
      message: "⚡ Mini-recupero ${nextState.restSeconds}s | Prossima: micro-serie ${currentMicro + 1}/$totalMicro ($nextReps reps)",
      isSuccess: true,
      duration: Duration(seconds: nextState.restSeconds + 1),
    );

    _startRestPauseTimer(nextState, exercise.nome);
  }

  /// Completa definitivamente la serie REST-PAUSE
  void _completeRestPauseSeries(WorkoutSessionActive state, WorkoutExercise exercise, RestPauseState currentState, int lastReps, int completedCount) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;

    final finalCompletedReps = [...currentState.completedReps, lastReps];
    final totalReps = finalCompletedReps.fold(0, (sum, reps) => sum + reps);
    final sequenceString = finalCompletedReps.join('+');

    print("🚀 [REST-PAUSE] Completing full REST-PAUSE series: $sequenceString (total: $totalReps reps)");

    final effectiveWeight = _getEffectiveWeight(exercise);

    final seriesData = SeriesData.restPause(
      schedaEsercizioId: exerciseId,
      peso: effectiveWeight,
      ripetizioni: totalReps,
      restPauseReps: sequenceString,
      restPauseRestSeconds: currentState.restSeconds,
      completata: 1,
      tempoRecupero: exercise.tempoRecupero,
      note: 'REST-PAUSE completato: $sequenceString (${totalReps} reps totali)',
      serieNumber: completedCount + 1,
      serieId: 'rest_pause_${DateTime.now().millisecondsSinceEpoch}',
    );

    _resetRestPauseState();
    _saveSeriesAndProvideRecovery(state, exercise, seriesData, completedCount);

    CustomSnackbar.show(
      context,
      message: "🔥 REST-PAUSE completato! Serie ${completedCount + 1}: $sequenceString (${totalReps} reps)",
      isSuccess: true,
      duration: const Duration(seconds: 4),
    );
  }

  /// Metodo comune per salvare serie e gestire recupero
  void _saveSeriesAndProvideRecovery(WorkoutSessionActive state, WorkoutExercise exercise, SeriesData seriesData, int completedCount) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;

    _activeWorkoutBloc.addLocalSeries(exerciseId, seriesData);

    final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';
    _activeWorkoutBloc.saveSeries(
      state.activeWorkout.id,
      [seriesData],
      requestId,
    );

    _invalidateCacheForExercise(exerciseId);

    final isLastSeries = completedCount + 1 >= exercise.serie;
    if (!isLastSeries && exercise.tempoRecupero > 0) {
      final isLinkedExercise = exercise.linkedToPreviousInt > 0;
      if (!isLinkedExercise) {
        print("🚀 [RECOVERY] Starting ${exercise.tempoRecupero}s recovery timer");
        _startRecoveryTimer(exercise.tempoRecupero, exercise.nome);
      } else {
        print("🔧 [SUPERSET PAUSE] Skipping recovery timer for linked exercise");
      }
    }

    if (seriesData.isRestPause == null || seriesData.isRestPause == 0) {
      CustomSnackbar.show(
        context,
        message: exercise.isIsometric
            ? "🔥 Tenuta isometrica ${completedCount + 1} completata!"
            : "Serie ${completedCount + 1} completata!",
        isSuccess: true,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  int _getCompletedSeriesCount(WorkoutSessionActive state, int exerciseId) {
    final series = state.completedSeries[exerciseId] ?? [];
    return series.length;
  }

  bool _isExerciseCompleted(WorkoutSessionActive state, WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    final completedCount = _getCompletedSeriesCount(state, exerciseId);
    return completedCount >= exercise.serie;
  }

  double _getEffectiveWeight(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    return _weightCache[exerciseId] ?? exercise.peso;
  }

  int _getEffectiveReps(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    return _repsCache[exerciseId] ?? exercise.ripetizioni;
  }

  void _invalidateCacheForExercise(int exerciseId) {
    _exerciseCache.remove(exerciseId);
    _weightCache.remove(exerciseId);
    _repsCache.remove(exerciseId);
  }

  void _updateCacheForExercise(int exerciseId, WorkoutExercise exercise) {
    _exerciseCache[exerciseId] = exercise;
  }

  WorkoutSessionActive? _getCurrentState() {
    final currentState = context.read<ActiveWorkoutBloc>().state;
    return currentState is WorkoutSessionActive ? currentState : null;
  }

  // ============================================================================
  // EXERCISE GROUPING FOR SUPERSET/CIRCUIT
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

    print("🚀 [GROUPING] Created ${groups.length} exercise groups:");
    for (int i = 0; i < groups.length; i++) {
      print("  Group $i: ${groups[i].map((e) => e.nome).join(', ')}");
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

  // ============================================================================
  // DIALOG METHODS
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

  void _handleExitConfirmed() {
    print("🚪 [EXIT] User confirmed exit - cancelling workout");

    final currentState = context.read<ActiveWorkoutBloc>().state;
    if (currentState is WorkoutSessionActive) {
      _activeWorkoutBloc.cancelWorkout(currentState.activeWorkout.id);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleCompleteConfirmed() {
    print("✅ [COMPLETE] User confirmed completion");

    final currentState = context.read<ActiveWorkoutBloc>().state;
    if (currentState is WorkoutSessionActive) {
      _handleCompleteWorkout(currentState);
    }
  }

  void _handleCompleteWorkout(WorkoutSessionActive state) {
    print("🚀 [SINGLE EXERCISE] Completing workout");

    _stopWorkoutTimer();
    _completeButtonController.stop();
    _disableWakeLock();

    final durationMinutes = _elapsedTime.inMinutes;
    _activeWorkoutBloc.completeWorkout(
      state.activeWorkout.id,
      durationMinutes,
      note: 'Completato tramite Single Exercise Screen',
    );
  }

  // ============================================================================
  // UI HELPERS
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
    // 🚀 FASE 5: Supporto REST-PAUSE
    if (exercise.isRestPause) {
      return "REST-PAUSE";
    }
    if (exercise.setType == "superset") {
      return "Superset";
    } else if (exercise.setType == "circuit") {
      return "Circuit";
    }
    return "Esercizio";
  }

  Color _getExerciseTypeColor(WorkoutExercise exercise) {
    final colorScheme = Theme.of(context).colorScheme;

    // 🚀 FASE 5: Colore dedicato per REST-PAUSE
    if (exercise.isRestPause) {
      return Colors.purple;
    }
    if (exercise.setType == "superset") {
      return Colors.purple;
    } else if (exercise.setType == "circuit") {
      return Colors.orange;
    }
    return colorScheme.primary;
  }

  // ============================================================================
  // BUILD METHODS
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
          // Active workout listener
          BlocListener<ActiveWorkoutBloc, ActiveWorkoutState>(
            listener: _handleActiveWorkoutStateChange,
          ),
          // Plateau listener
          BlocListener<PlateauBloc, PlateauState>(
            listener: _handlePlateauStateChange,
          ),
        ],
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: _buildAppBar(context.read<ActiveWorkoutBloc>().state),
          body: _buildBody(context.read<ActiveWorkoutBloc>().state),
        ),
      ),
    );
  }

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
              color: colorScheme.onSurface.withOpacity(0.7),
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
        Container(
          margin: EdgeInsets.only(right: 16.w),
          child: AnimatedBuilder(
            animation: _completeButtonAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: isWorkoutFullyCompleted
                      ? Colors.green.withOpacity(0.2)
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

        // Timer di recupero normale
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

        // Timer isometrico
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

        // 🚀 FASE 5: Timer mini-recupero REST-PAUSE
        if (_isRestPauseTimerActive && _currentRestPauseState != null)
          RestPauseTimerPopup(
            initialSeconds: _currentRestPauseState!.restSeconds,
            isActive: _isRestPauseTimerActive,
            exerciseName: _currentRestPauseExerciseName ?? 'Esercizio',
            currentMicroSeries: _currentRestPauseState!.currentMicroSeries,
            totalMicroSeries: _currentRestPauseState!.sequence.length,
            nextTargetReps: _currentRestPauseState!.currentTargetReps,
            onTimerComplete: _onRestPauseTimerComplete,
            onTimerStopped: _stopRestPauseTimer,
            onTimerDismissed: () {
              _stopRestPauseTimer();
            },
          ),

        // Exit dialog
        if (_showExitDialog) _buildExitDialog(),

        // Complete dialog
        if (_showCompleteDialog) _buildCompleteDialog(),
      ],
    );
  }

  Widget _buildMainContent(ActiveWorkoutState state) {
    // 🔧 FIX: Stati corretti del BLoC
    if (state is ActiveWorkoutLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ActiveWorkoutError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: Colors.red,
            ),
            SizedBox(height: 16.h),
            Text(
              'Errore durante l\'allenamento',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              state.message ?? 'Errore sconosciuto',
              style: TextStyle(fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state is WorkoutSessionActive) {
      if (_exerciseGroups.isEmpty && state.exercises.isNotEmpty) {
        _exerciseGroups = _groupExercises(state.exercises);
        _startWorkoutTimer();
      }

      if (_exerciseGroups.isEmpty) {
        return const Center(
          child: Text('Nessun esercizio trovato nella scheda'),
        );
      }

      final currentGroup = _exerciseGroups[_currentGroup];
      final currentExercise = currentGroup[_currentExerciseInGroup];

      return _buildSingleExerciseContent(state, currentExercise);
    }

    return const Center(child: Text('Stato non riconosciuto'));
  }

  Widget _buildSingleExerciseContent(WorkoutSessionActive state, WorkoutExercise exercise) {
    final colorScheme = Theme.of(context).colorScheme;

    // 🚀 FASE 5: Se l'esercizio è REST-PAUSE e ha uno stato attivo, mostra UI speciale
    if (_currentRestPauseState != null && _isExerciseRestPause(exercise)) {
      return _buildRestPauseContent(state, exercise);
    }

    // UI normale per esercizi non-REST-PAUSE
    return _buildNormalExerciseContent(state, exercise, colorScheme);
  }

  /// 🚀 FASE 5: Contenuto UI REST-PAUSE
  Widget _buildRestPauseContent(WorkoutSessionActive state, WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    final completedSeries = _getCompletedSeriesCount(state, exerciseId);
    final restPauseState = _currentRestPauseState!;

    return RestPauseExecutionWidget(
      exerciseName: exercise.nome,
      currentSeries: completedSeries + 1,
      totalSeries: exercise.serie,
      currentMicroSeries: restPauseState.currentMicroSeries,
      totalMicroSeries: restPauseState.sequence.length,
      targetReps: restPauseState.currentTargetReps,
      completedMicroReps: restPauseState.completedReps,
      totalCompletedReps: restPauseState.totalRepsCompleted,
      isInRestPause: restPauseState.isInRestPause,
      nextMicroRepsInfo: _getNextMicroSeriesInfo(restPauseState),
      onCompleteMicroSeries: () => _handleCompleteSeries(state, exercise),
      onEditWeight: () => _showWeightEditDialog(exercise),
      onEditReps: () => _showRepsEditDialog(exercise),
      currentWeight: _getEffectiveWeight(exercise),
      currentReps: _getEffectiveReps(exercise),
    );
  }

  /// UI normale per esercizi non-REST-PAUSE
  Widget _buildNormalExerciseContent(WorkoutSessionActive state, WorkoutExercise exercise, ColorScheme colorScheme) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    final completedSeries = _getCompletedSeriesCount(state, exerciseId);
    final isCompleted = _isExerciseCompleted(state, exercise);
    final exerciseType = _getExerciseTypeLabel(exercise);
    final exerciseColor = _getExerciseTypeColor(exercise);

    _updateCacheForExercise(exerciseId, exercise);

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header tipo esercizio
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: exerciseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: exerciseColor.withOpacity(0.3)),
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

            // Nome esercizio
            Text(
              exercise.nome,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 40.h),

            // Card serie
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Serie ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$completedSeries/${exercise.serie}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // Card parametri
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showWeightEditDialog(exercise),
                          child: Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'PESO',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: colorScheme.onSurface.withOpacity(0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  '${_getEffectiveWeight(exercise).toStringAsFixed(1)} kg',
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showRepsEditDialog(exercise),
                          child: Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  exercise.isIsometric ? 'SECONDI' : 'RIPETIZIONI',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: colorScheme.onSurface.withOpacity(0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  '${_getEffectiveReps(exercise)}',
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (exercise.note != null && exercise.note!.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Text(
                        exercise.note!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.blue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 40.h),

            // Pulsante completamento
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: isCompleted ? null : () => _handleCompleteSeries(state, exercise),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: isCompleted ? 0 : 3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.fitness_center,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      isCompleted
                          ? 'ESERCIZIO COMPLETATO'
                          : exercise.isIsometric
                          ? 'INIZIA TENUTA ISOMETRICA'
                          : 'COMPLETA SERIE ${completedSeries + 1}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Navigazione esercizi
            if (_exerciseGroups.isNotEmpty) _buildExerciseNavigation(state),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseNavigation(WorkoutSessionActive state) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentGroup = _exerciseGroups[_currentGroup];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            'Esercizi Gruppo ${_currentGroup + 1}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _currentGroup > 0 ? _previousGroup : null,
                icon: Icon(Icons.skip_previous, size: 24.sp),
                style: IconButton.styleFrom(
                  backgroundColor: _currentGroup > 0 ? colorScheme.primary : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(12.w),
                ),
              ),
              IconButton(
                onPressed: currentGroup.length > 1 ? _previousExercise : null,
                icon: Icon(Icons.arrow_back_ios, size: 20.sp),
                style: IconButton.styleFrom(
                  backgroundColor: currentGroup.length > 1 ? colorScheme.primary : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(12.w),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${_currentExerciseInGroup + 1}/${currentGroup.length}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: currentGroup.length > 1 ? _nextExercise : null,
                icon: Icon(Icons.arrow_forward_ios, size: 20.sp),
                style: IconButton.styleFrom(
                  backgroundColor: currentGroup.length > 1 ? colorScheme.primary : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(12.w),
                ),
              ),
              IconButton(
                onPressed: _currentGroup < _exerciseGroups.length - 1 ? _nextGroup : null,
                icon: Icon(Icons.skip_next, size: 24.sp),
                style: IconButton.styleFrom(
                  backgroundColor: _currentGroup < _exerciseGroups.length - 1 ? colorScheme.primary : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(12.w),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _previousGroup() {
    if (_currentGroup > 0) {
      setState(() {
        _currentGroup--;
        _currentExerciseInGroup = 0;
      });
      _resetRestPauseState(); // 🚀 FASE 5: Reset quando si cambia gruppo
    }
  }

  void _nextGroup() {
    if (_currentGroup < _exerciseGroups.length - 1) {
      setState(() {
        _currentGroup++;
        _currentExerciseInGroup = 0;
      });
      _resetRestPauseState(); // 🚀 FASE 5: Reset quando si cambia gruppo
    }
  }

  void _previousExercise() {
    final currentGroup = _exerciseGroups[_currentGroup];
    if (_currentExerciseInGroup > 0) {
      setState(() {
        _currentExerciseInGroup--;
      });
      _resetRestPauseState(); // 🚀 FASE 5: Reset quando si cambia esercizio
    }
  }

  void _nextExercise() {
    final currentGroup = _exerciseGroups[_currentGroup];
    if (_currentExerciseInGroup < currentGroup.length - 1) {
      setState(() {
        _currentExerciseInGroup++;
      });
      _resetRestPauseState(); // 🚀 FASE 5: Reset quando si cambia esercizio
    }
  }

  // Parameter edit dialogs - 🔧 FIX: Parametri corretti!
  void _showWeightEditDialog(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
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
          setState(() {
            _weightCache[exerciseId] = weight;
            _repsCache[exerciseId] = reps;
          });
        },
      ),
    );
  }

  void _showRepsEditDialog(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
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
          setState(() {
            _weightCache[exerciseId] = weight;
            _repsCache[exerciseId] = reps;
          });
        },
      ),
    );
  }

  // Exit and complete dialogs
  Widget _buildExitDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: EdgeInsets.all(20.w),
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 48.sp,
                  color: Colors.orange,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Conferma Uscita',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Sei sicuro di voler uscire dall\'allenamento? Tutti i progressi andranno persi.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: colorScheme.onSurface.withOpacity(0.7),
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

    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: EdgeInsets.all(20.w),
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16.r),
            ),
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
                  'Completa Allenamento',
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
                    color: colorScheme.onSurface.withOpacity(0.7),
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

  // BLoC listeners
  void _handleActiveWorkoutStateChange(BuildContext context, ActiveWorkoutState state) {
    if (state is WorkoutSessionCompleted) {
      Navigator.of(context).pop();
      CustomSnackbar.show(
        context,
        message: "🎉 Allenamento completato con successo!",
        isSuccess: true,
        duration: const Duration(seconds: 3),
      );
    }

    if (state is WorkoutSessionCancelled) {
      Navigator.of(context).pop();
      CustomSnackbar.show(
        context,
        message: "🚪 Allenamento annullato",
        isSuccess: false,
        duration: const Duration(seconds: 2),
      );
    }

    if (state is ActiveWorkoutError) {
      CustomSnackbar.show(
        context,
        message: "❌ Errore: ${state.message ?? 'Errore sconosciuto'}",
        isSuccess: false,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _handlePlateauStateChange(BuildContext context, PlateauState state) {
    if (state is PlateauDetected) {
      for (final plateau in state.plateaus) {
        if (!_dismissedPlateauExercises.contains(plateau.exerciseId)) {
          CustomSnackbar.show(
            context,
            message: "📊 Plateau rilevato per ${plateau.exerciseName}",
            isSuccess: false,
            duration: const Duration(seconds: 2),
          );
        }
      }

      for (final plateau in state.plateaus) {
        if (plateau.isDismissed) {
          _dismissedPlateauExercises.add(plateau.exerciseId);
          print("🔧 [PLATEAU FIX] Exercise ${plateau.exerciseId} dismissed - won't retrigger");
        }
      }
    }

    if (state is PlateauError) {
      print("🔧 [PLATEAU FIX] Error: ${state.message}");
    }
  }
}