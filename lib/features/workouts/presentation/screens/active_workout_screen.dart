// lib/features/workouts/presentation/screens/active_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../../bloc/active_workout_bloc.dart';
import '../../models/active_workout_models.dart';
import '../../models/workout_plan_models.dart';

// 🎯 PLATEAU IMPORTS - STEP 7
import '../../bloc/plateau_bloc.dart';
import '../../models/plateau_models.dart';
import '../../../../shared/widgets/plateau_widgets.dart';

/// 🚀 ActiveWorkoutScreen - SINGLE EXERCISE FOCUSED WITH SUPERSET/CIRCUIT GROUPING + 🎯 PLATEAU DETECTION
/// ✅ STEP 7 COMPLETATO + Dark Theme + Dialogs + Complete Button + Plateau Integration
/// ✅ Una schermata per esercizio/gruppo - Design pulito e minimale
/// ✅ Raggruppamento automatico superset/circuit
/// ✅ Recovery timer come popup non invasivo
/// ✅ Navigazione tra gruppi logici
/// 🌙 Dark theme support
/// 🚪 Dialog conferma uscita
/// ✅ Pulsante completa allenamento lampeggiante
/// 🎯 Sistema plateau detection integrato!
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
    with TickerProviderStateMixin {

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
  final Set<int> _loggedExercises = {};

  // ✏️ Modified parameters storage
  Map<int, double> _modifiedWeights = {};
  Map<int, int> _modifiedReps = {};

  // UI state
  bool _isInitialized = false;
  String _currentStatus = "Inizializzazione...";
  int? _userId;

  // 🆕 Dialog state
  bool _showExitDialog = false;
  bool _showCompleteDialog = false;

  @override
  void initState() {
    super.initState();
    debugPrint("🚀 [SINGLE EXERCISE + PLATEAU] initState - Scheda: ${widget.schedaId}");
    _activeWorkoutBloc = context.read<ActiveWorkoutBloc>();
    _plateauBloc = context.read<PlateauBloc>(); // 🎯 INITIALIZE PLATEAU BLOC
    _initializeAnimations();
    _initializeWorkout();
  }

  @override
  void dispose() {
    debugPrint("🚀 [SINGLE EXERCISE + PLATEAU] dispose");
    _workoutTimer?.cancel();
    _slideController.dispose();
    _pulseController.dispose();
    _completeButtonController.dispose();
    _pageController.dispose();
    _stopRecoveryTimer();
    super.dispose();
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

      setState(() {
        _isInitialized = true;
        _currentStatus = "Allenamento avviato";
      });

      _slideController.forward();

    } catch (e) {
      debugPrint("🚀 [SINGLE EXERCISE + PLATEAU] Error initializing: $e");
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
  // 🆕 DIALOG METHODS
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
    debugPrint("🚪 [EXIT] User confirmed exit - cancelling workout");

    final currentState = context.read<ActiveWorkoutBloc>().state;
    if (currentState is WorkoutSessionActive) {
      _activeWorkoutBloc.cancelWorkout(currentState.activeWorkout.id);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleCompleteConfirmed() {
    debugPrint("✅ [COMPLETE] User confirmed completion");

    final currentState = context.read<ActiveWorkoutBloc>().state;
    if (currentState is WorkoutSessionActive) {
      _handleCompleteWorkout(currentState);
    }
  }

  // ============================================================================
  // 🚀 EXERCISE GROUPING FOR SUPERSET/CIRCUIT
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

    debugPrint("🚀 [GROUPING] Created ${groups.length} exercise groups:");
    for (int i = 0; i < groups.length; i++) {
      debugPrint("  Group $i: ${groups[i].map((e) => e.nome).join(', ')}");
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
  // NAVIGATION METHODS
  // ============================================================================

  void _goToPreviousGroup() {
    if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        if (_currentGroupIndex < _exerciseGroups.length) {
          final newGroup = _exerciseGroups[_currentGroupIndex];
          _currentExerciseInGroup = _findNextExerciseInSequentialRotation(_getCurrentState(), newGroup);
        }
      });
      _pageController.animateToPage(
        _currentGroupIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _stopRecoveryTimer();
    }
  }

  void _goToNextGroup() {
    if (_currentGroupIndex < _exerciseGroups.length - 1) {
      setState(() {
        _currentGroupIndex++;
        if (_currentGroupIndex < _exerciseGroups.length) {
          final newGroup = _exerciseGroups[_currentGroupIndex];
          _currentExerciseInGroup = _findNextExerciseInSequentialRotation(_getCurrentState(), newGroup);
        }
      });
      _pageController.animateToPage(
        _currentGroupIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _stopRecoveryTimer();
    }
  }

  bool _canGoToPrevious() {
    return _currentGroupIndex > 0;
  }

  bool _canGoToNext() {
    return _currentGroupIndex < _exerciseGroups.length - 1;
  }

  // ============================================================================
  // RECOVERY TIMER POPUP METHODS
  // ============================================================================

  void _startRecoveryTimer(int seconds, String exerciseName) {
    debugPrint("🔄 [RECOVERY POPUP] Starting recovery timer: $seconds seconds for $exerciseName");

    setState(() {
      _isRecoveryTimerActive = true;
      _recoverySeconds = seconds;
      _currentRecoveryExerciseName = exerciseName;
    });
  }

  void _stopRecoveryTimer() {
    debugPrint("⏹️ [RECOVERY POPUP] Recovery timer stopped");

    setState(() {
      _isRecoveryTimerActive = false;
      _recoverySeconds = 0;
      _currentRecoveryExerciseName = null;
    });
  }

  void _onRecoveryTimerComplete() {
    debugPrint("✅ [RECOVERY POPUP] Recovery completed!");

    setState(() {
      _isRecoveryTimerActive = false;
      _recoverySeconds = 0;
      _currentRecoveryExerciseName = null;
    });

    CustomSnackbar.show(
      context,
      message: "Recupero completato! Pronto per la prossima serie 💪",
      isSuccess: true,
    );
  }

  // ============================================================================
  // 🔥 ISOMETRIC TIMER METHODS
  // ============================================================================

  void _startIsometricTimer(WorkoutExercise exercise) {
    final seconds = _getEffectiveReps(exercise);

    debugPrint("🔥 [ISOMETRIC] Starting isometric timer: $seconds seconds for ${exercise.nome}");

    setState(() {
      _isIsometricTimerActive = true;
      _isometricSeconds = seconds;
      _currentIsometricExerciseName = exercise.nome;
      _pendingIsometricExercise = exercise;
    });
  }

  void _onIsometricTimerComplete() {
    debugPrint("✅ [ISOMETRIC] Isometric timer completed!");

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

    CustomSnackbar.show(
      context,
      message: "🔥 Tenuta isometrica completata! 💪",
      isSuccess: true,
    );
  }

  void _onIsometricTimerCancelled() {
    debugPrint("❌ [ISOMETRIC] Isometric timer cancelled");

    setState(() {
      _isIsometricTimerActive = false;
      _isometricSeconds = 0;
      _currentIsometricExerciseName = null;
      _pendingIsometricExercise = null;
    });

    CustomSnackbar.show(
      context,
      message: "Tenuta isometrica annullata",
      isSuccess: false,
    );
  }

  // ============================================================================
  // ✏️ PARAMETER EDITING METHODS
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

    context.read<ActiveWorkoutBloc>().updateExerciseValues(exerciseId, weight, reps);

    debugPrint("✏️ [EDIT] Modified parameters for ${exercise.nome}: ${weight}kg, $reps ${exercise.isIsometric ? 'seconds' : 'reps'}");

    CustomSnackbar.show(
      context,
      message: "Parametri aggiornati: ${weight.toStringAsFixed(1)}kg, $reps ${exercise.isIsometric ? 'secondi' : 'ripetizioni'}",
      isSuccess: true,
    );

    // 🎯 PLATEAU: Trigger analysis after parameter modification
    _triggerPlateauAnalysisForExercise(exercise);
  }

  double _getEffectiveWeight(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;

    // 1. PRIORITÀ MASSIMA: Valori modificati dall'utente
    if (_modifiedWeights.containsKey(exerciseId)) {
      return _modifiedWeights[exerciseId]!;
    }

    // 2. SERIE-SPECIFIC: Valori storici per la serie corrente
    final currentState = _getCurrentState();
    if (currentState != null) {
      final completedSeriesCount = _getCompletedSeriesCount(currentState, exerciseId);
      final currentSeriesNumber = completedSeriesCount + 1; // Prossima serie da fare

      debugPrint('🔧 [FIX] Getting weight for exercise $exerciseId, series $currentSeriesNumber (completed: $completedSeriesCount)');

      // Usa il metodo serie-specifico del BLoC
      final seriesSpecificValues = _activeWorkoutBloc.getValuesForSeries(exerciseId, currentSeriesNumber);

      if (seriesSpecificValues.weight > 0) {
        debugPrint('✅ [SERIES] Using series-specific weight: ${seriesSpecificValues.weight}kg (series $currentSeriesNumber)');
        return seriesSpecificValues.weight;
      }
    }

    // 3. FALLBACK: Valori BLoC generici (per retrocompatibilità)
    final currentState2 = _activeWorkoutBloc.state;
    if (currentState2 is WorkoutSessionActive) {
      final exerciseValues = currentState2.exerciseValues[exerciseId];
      if (exerciseValues != null) {
        if (!_loggedExercises.contains(exerciseId)) {
          _loggedExercises.add(exerciseId);
          debugPrint('💡 [FALLBACK] Using BLoC generic value for exercise $exerciseId: ${exerciseValues.weight}kg (${exerciseValues.isFromHistory ? "FROM HISTORY" : "DEFAULT"})');
        }
        return exerciseValues.weight;
      }
    }

    // 4. ULTIMO FALLBACK: Default esercizio
    debugPrint('⚠️ [FALLBACK] Using exercise default weight: ${exercise.peso}kg');
    return exercise.peso;
  }

  int _getEffectiveReps(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;

    // 1. PRIORITÀ MASSIMA: Valori modificati dall'utente
    if (_modifiedReps.containsKey(exerciseId)) {
      return _modifiedReps[exerciseId]!;
    }

    // 2. SERIE-SPECIFIC: Valori storici per la serie corrente
    final currentState = _getCurrentState();
    if (currentState != null) {
      final completedSeriesCount = _getCompletedSeriesCount(currentState, exerciseId);
      final currentSeriesNumber = completedSeriesCount + 1; // Prossima serie da fare

      debugPrint('🔧 [FIX] Getting reps for exercise $exerciseId, series $currentSeriesNumber (completed: $completedSeriesCount)');

      // Usa il metodo serie-specifico del BLoC
      final seriesSpecificValues = _activeWorkoutBloc.getValuesForSeries(exerciseId, currentSeriesNumber);

      if (seriesSpecificValues.reps > 0) {
        debugPrint('✅ [SERIES] Using series-specific reps: ${seriesSpecificValues.reps} (series $currentSeriesNumber)');
        return seriesSpecificValues.reps;
      }
    }

    // 3. FALLBACK: Valori BLoC generici (per retrocompatibilità)
    final currentState2 = _activeWorkoutBloc.state;
    if (currentState2 is WorkoutSessionActive) {
      final exerciseValues = currentState2.exerciseValues[exerciseId];
      if (exerciseValues != null) {
        return exerciseValues.reps;
      }
    }

    // 4. ULTIMO FALLBACK: Default esercizio
    debugPrint('⚠️ [FALLBACK] Using exercise default reps: ${exercise.ripetizioni}');
    return exercise.ripetizioni;
  }

  // ============================================================================
  // 🎯 PLATEAU DETECTION METHODS - STEP 7
  // ============================================================================

  /// Trigger plateau analysis for a single exercise
  void _triggerPlateauAnalysisForExercise(WorkoutExercise exercise) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    final weight = _getEffectiveWeight(exercise);
    final reps = _getEffectiveReps(exercise);

    debugPrint("🎯 [PLATEAU] Triggering analysis for ${exercise.nome}: ${weight}kg x $reps");

    _plateauBloc.analyzeExercisePlateau(exerciseId, exercise.nome, weight, reps);
  }

  /// Trigger plateau analysis for current group
  void _triggerPlateauAnalysisForCurrentGroup() {
    if (_exerciseGroups.isEmpty || _currentGroupIndex >= _exerciseGroups.length) return;

    final currentGroup = _exerciseGroups[_currentGroupIndex];
    final groupName = _generateGroupName(currentGroup);
    final groupType = currentGroup.first.setType;

    final Map<int, double> groupWeights = {};
    final Map<int, int> groupReps = {};

    for (final exercise in currentGroup) {
      final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
      groupWeights[exerciseId] = _getEffectiveWeight(exercise);
      groupReps[exerciseId] = _getEffectiveReps(exercise);
    }

    debugPrint("🎯 [PLATEAU] Triggering group analysis for $groupName ($groupType)");

    _plateauBloc.analyzeGroupPlateau(groupName, groupType, currentGroup, groupWeights, groupReps);
  }

  /// Check if exercise has plateau
  bool _hasPlateauForExercise(int exerciseId) {
    final plateauState = _plateauBloc.state;
    if (plateauState is PlateauDetected) {
      return plateauState.hasPlateauForExercise(exerciseId);
    }
    return false;
  }

  /// Get plateau info for exercise
  PlateauInfo? _getPlateauForExercise(int exerciseId) {
    final plateauState = _plateauBloc.state;
    if (plateauState is PlateauDetected) {
      return plateauState.getPlateauForExercise(exerciseId);
    }
    return null;
  }

  String _generateGroupName(List<WorkoutExercise> exercises) {
    if (exercises.length == 1) {
      return exercises.first.nome;
    }

    final groupType = exercises.first.setType;
    switch (groupType) {
      case 'superset':
        return 'Superset: ${exercises.map((e) => e.nome).join(' + ')}';
      case 'circuit':
        return 'Circuit: ${exercises.length} esercizi';
      default:
        return 'Gruppo: ${exercises.length} esercizi';
    }
  }

  // ============================================================================
  // WORKOUT LOGIC
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

    debugPrint("🚀 [SINGLE EXERCISE] Completing series ${completedCount + 1} for exercise: ${exercise.nome}");

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

    CustomSnackbar.show(
      context,
      message: exercise.isIsometric
          ? "🔥 Tenuta isometrica ${completedCount + 1} completata!"
          : "Serie ${completedCount + 1} completata! 💪",
      isSuccess: true,
    );

    // 🎯 PLATEAU: Trigger analysis after series completion
    _triggerPlateauAnalysisForExercise(exercise);

    if (exercise.tempoRecupero > 0) {
      _startRecoveryTimer(exercise.tempoRecupero, exercise.nome);
    }

    _handleAutoRotation(state);

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

          CustomSnackbar.show(
            context,
            message: "🔄 ${groupType.toUpperCase()}: ${nextExercise.nome}",
            isSuccess: true,
          );
        }
      });
    }
  }

  int _findNextExerciseInSequentialRotation(WorkoutSessionActive? state, List<WorkoutExercise> group) {
    if (state == null) return 0;

    int nextIndex = (_currentExerciseInGroup + 1) % group.length;

    for (int attempts = 0; attempts < group.length; attempts++) {
      final exercise = group[nextIndex];
      final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
      final completedCount = _getCompletedSeriesCount(state, exerciseId);

      if (completedCount < exercise.serie) {
        return nextIndex;
      }

      nextIndex = (nextIndex + 1) % group.length;
    }

    debugPrint("🎉 [AUTO-ROTATION] All exercises in group are completed!");
    return _currentExerciseInGroup;
  }

  WorkoutSessionActive? _getCurrentState() {
    final currentState = context.read<ActiveWorkoutBloc>().state;
    return currentState is WorkoutSessionActive ? currentState : null;
  }

  void _handleCompleteWorkout(WorkoutSessionActive state) {
    debugPrint("🚀 [SINGLE EXERCISE] Completing workout");

    _stopWorkoutTimer();
    _completeButtonController.stop();

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
          // 🎯 PLATEAU BLOC LISTENER - STEP 7
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
        _currentExerciseInGroup = _findNextExerciseInSequentialRotation(_getCurrentState(), currentGroup);
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
                  _currentExerciseInGroup = _findNextExerciseInSequentialRotation(_getCurrentState(), newGroup);
                }
              });
              _stopRecoveryTimer();
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

            // 🎯 PLATEAU INDICATOR - STEP 7
            BlocBuilder<PlateauBloc, PlateauState>(
              builder: (context, plateauState) {
                if (plateauState is PlateauDetected && _hasPlateauForExercise(exerciseId)) {
                  final plateauInfo = _getPlateauForExercise(exerciseId);
                  if (plateauInfo != null) {
                    return Column(
                      children: [
                        PlateauIndicator(
                          plateauInfo: plateauInfo,
                          onDismiss: () => _plateauBloc.dismissPlateau(exerciseId),
                        ),
                        SizedBox(height: 24.h),
                      ],
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),

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
                  Text(
                    'Serie',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '$completedSeries/${exercise.serie}',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : exerciseColor,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(exercise.serie, (i) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: i < completedSeries
                              ? exerciseColor
                              : colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

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
                    hasPlateauBadge: _hasPlateauForExercise(exerciseId), // 🎯 PLATEAU BADGE
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
                    hasPlateauBadge: _hasPlateauForExercise(exerciseId), // 🎯 PLATEAU BADGE
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
                color: groupColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: groupColor.withOpacity(0.3)),
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
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: isSelected ? groupColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: groupColor.withOpacity(0.3),
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
                                // 🎯 PLATEAU BADGE FOR TABS
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

            Text(
              currentExercise.nome,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 40.h),

            // 🎯 PLATEAU INDICATOR FOR CURRENT EXERCISE - STEP 7
            BlocBuilder<PlateauBloc, PlateauState>(
              builder: (context, plateauState) {
                if (plateauState is PlateauDetected && _hasPlateauForExercise(exerciseId)) {
                  final plateauInfo = _getPlateauForExercise(exerciseId);
                  if (plateauInfo != null) {
                    return Column(
                      children: [
                        PlateauIndicator(
                          plateauInfo: plateauInfo,
                          onDismiss: () => _plateauBloc.dismissPlateau(exerciseId),
                        ),
                        SizedBox(height: 24.h),
                      ],
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),

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
                  Text(
                    'Serie',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '$completedSeries/${currentExercise.serie}',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : groupColor,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(currentExercise.serie, (i) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: i < completedSeries
                              ? groupColor
                              : colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

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
                    hasPlateauBadge: _hasPlateauForExercise(exerciseId), // 🎯 PLATEAU BADGE
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
                    hasPlateauBadge: _hasPlateauForExercise(exerciseId), // 🎯 PLATEAU BADGE
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

            SizedBox(height: 16.h),

            if (isGroupComplete)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
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

  Widget _buildParameterCard(
      String label,
      String value,
      IconData icon,
      Color color, {
        VoidCallback? onTap,
        bool isModified = false,
        bool hasPlateauBadge = false, // 🎯 PLATEAU BADGE PARAMETER
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
              color: colorScheme.shadow.withOpacity(0.1),
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
                    color: colorScheme.onSurface.withOpacity(0.3),
                    size: 16.sp,
                  ),
                ],
                // 🎯 PLATEAU BADGE IN PARAMETER CARD - STEP 7
                if (hasPlateauBadge) ...[
                  SizedBox(width: 4.w),
                  PlateauBadge(
                    onTap: () {
                      // Optional: Show plateau details
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
                color: colorScheme.onSurface.withOpacity(0.7),
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
            color: colorScheme.shadow.withOpacity(0.1),
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
  // 🆕 DIALOG WIDGETS
  // ============================================================================

  Widget _buildExitDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Colors.black.withOpacity(0.5),
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

    return Container(
      color: Colors.black.withOpacity(0.5),
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

  // ============================================================================
  // BLOC LISTENERS
  // ============================================================================

  void _handleBlocStateChanges(BuildContext context, ActiveWorkoutState state) {
    if (state is WorkoutSessionStarted) {
      debugPrint("🚀 [SINGLE EXERCISE] Workout session started");
      _startWorkoutTimer();

      CustomSnackbar.show(
        context,
        message: "Allenamento avviato con successo! 💪",
        isSuccess: true,
      );
    }

    if (state is WorkoutSessionActive) {
      debugPrint("🚀 [SINGLE EXERCISE] Active session with ${state.exercises.length} exercises");

      if (_workoutTimer == null) {
        _startWorkoutTimer();
      }
    }

    if (state is WorkoutSessionCompleted) {
      debugPrint("🚀 [SINGLE EXERCISE] Workout completed");
      _stopWorkoutTimer();
      _stopRecoveryTimer();
      _completeButtonController.stop();
    }

    if (state is WorkoutSessionCancelled) {
      debugPrint("🚀 [SINGLE EXERCISE] Workout cancelled");
      _stopWorkoutTimer();
      _stopRecoveryTimer();
      _completeButtonController.stop();

      CustomSnackbar.show(
        context,
        message: "Allenamento annullato",
        isSuccess: false,
      );

      Navigator.of(context).pop();
    }

    if (state is ActiveWorkoutError) {
      debugPrint("🚀 [SINGLE EXERCISE] Error: ${state.message}");

      CustomSnackbar.show(
        context,
        message: "Errore: ${state.message}",
        isSuccess: false,
      );
    }
  }

  // 🎯 PLATEAU BLOC LISTENER - STEP 7
  void _handlePlateauStateChanges(BuildContext context, PlateauState state) {
    if (state is PlateauDetected) {
      final activePlateaus = state.activePlateaus;
      if (activePlateaus.isNotEmpty) {
        debugPrint("🎯 [PLATEAU] Plateau rilevati: ${activePlateaus.length}");

        // Show subtle notification about plateau detection
        CustomSnackbar.show(
          context,
          message: "🎯 Rilevato plateau - Controlla i suggerimenti!",
          isSuccess: false,
          duration: const Duration(seconds: 2),
        );
      }
    }

    if (state is PlateauError) {
      debugPrint("🎯 [PLATEAU] Error: ${state.message}");
      // Don't show error to user - plateau is optional feature
    }
  }
}