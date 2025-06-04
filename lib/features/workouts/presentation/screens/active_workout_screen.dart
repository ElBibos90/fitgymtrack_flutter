// lib/features/workouts/presentation/screens/active_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/di/dependency_injection.dart';

import '../../bloc/active_workout_bloc.dart' as bloc;
import '../../models/active_workout_models.dart' as models;
import '../../models/workout_plan_models.dart';
import '../../models/exercise_group_models.dart'; // 🚀 NUOVO IMPORT

// 🛠️ Helper function for logging
void _log(String message, {String name = 'ActiveWorkoutScreen'}) {
  // Commento la maggior parte dei log per pulire il debug
  // if (kDebugMode) {
  //   debugPrint('[$name] $message');
  // }
}

// 🛠️ Helper function for important/error logging only
void _logImportant(String message, {String name = 'ActiveWorkoutScreen'}) {
  if (kDebugMode) {
    debugPrint('🔥 [$name] $message');
  }
}

// ============================================================================
// 🎯 MAIN ACTIVE WORKOUT SCREEN - FULLSCREEN WITH GROUPING
// ============================================================================

class ActiveWorkoutScreen extends StatefulWidget {
  final int schedaId;
  final int? allenamentoId;

  const ActiveWorkoutScreen({
    super.key,
    required this.schedaId,
    this.allenamentoId,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>
    with TickerProviderStateMixin {

  late bloc.ActiveWorkoutBloc _bloc;
  late SessionService _sessionService;

  // 🎮 FULLSCREEN STATE - AGGIORNATO PER GRUPPI
  int _currentGroupIndex = 0;              // 🚀 NUOVO: Index del gruppo corrente
  late PageController _pageController;
  List<ExerciseGroup> _exerciseGroups = []; // 🚀 NUOVO: Lista dei gruppi

  // ⏱️ TIMER SYSTEM
  Timer? _workoutTimer;
  Timer? _recoveryTimer;
  Duration _elapsedTime = Duration.zero;
  int _recoverySeconds = 0;
  bool _isRecoveryActive = false;

  // 💾 EXERCISE DATA - Mantenuto per compatibilità
  Map<int, double> _exerciseWeights = {};
  Map<int, int> _exerciseReps = {};

  // 🚀 NUOVO: Timer isometrico
  Timer? _isometricTimer;
  int _isometricSeconds = 0;
  bool _isIsometricTimerActive = false;
  int? _currentIsometricExerciseId;

  // 🎨 ANIMATIONS
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  late AnimationController _completionAnimationController;

  // 🚀 NEW: Track if we're currently saving a series
  bool _isSavingSeries = false;

  @override
  void initState() {
    super.initState();

    // _log('🚀 ActiveWorkoutScreen 2.0 - FASE B: Fullscreen Mode with Grouping INIT'); // Commentato

    _bloc = context.read<bloc.ActiveWorkoutBloc>();
    _sessionService = getIt<SessionService>();
    _pageController = PageController(initialPage: 0);

    _setupAnimations();
    _setupKeepScreenOn();
    _initializeWorkout();
    _startWorkoutTimer();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _recoveryTimer?.cancel();
    _isometricTimer?.cancel();                    // 🚀 NUOVO
    _progressAnimationController.dispose();
    _completionAnimationController.dispose();
    _pageController.dispose();

    // 📱 Restore normal system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  // ============================================================================
  // 🏗️ SETUP METHODS
  // ============================================================================

  void _setupAnimations() {
    _progressAnimationController = AnimationController(
      duration: AppConfig.animationNormal,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: AppConfig.animationCurve,
    ));

    _completionAnimationController = AnimationController(
      duration: AppConfig.animationSlow,
      vsync: this,
    );
  }

  void _setupKeepScreenOn() {
    // 📱 Keep screen on during workout
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Also prevent screen from turning off
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // ============================================================================
  // 🚀 WORKOUT INITIALIZATION - AGGIORNATO PER GRUPPI
  // ============================================================================

  Future<void> _initializeWorkout() async {
    // _log('🚀 Initializing fullscreen workout with grouping...'); // Commentato

    final userId = await _sessionService.getCurrentUserId();

    if (userId != null) {
      if (widget.allenamentoId != null) {
        // _log('🔄 Loading existing workout: ${widget.allenamentoId}'); // Commentato
        _bloc.add(bloc.LoadCompletedSeries(allenamentoId: widget.allenamentoId!));
      } else {
        // _log('🆕 Starting new fullscreen workout session with grouping'); // Commentato

        // Reset state before starting
        _bloc.add(const bloc.ResetActiveWorkoutState());
        await Future.delayed(const Duration(milliseconds: 100));

        // Start new workout
        _bloc.add(bloc.StartWorkoutSession(userId: userId, schedaId: widget.schedaId));
      }
    } else {
      _logImportant('❌ No user ID found!'); // Solo log importante
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Sessione scaduta. Effettua nuovamente il login.',
          isSuccess: false,
        );
        context.go('/login');
      }
    }
  }

  // ============================================================================
  // 🚀 NUOVO: EXERCISE GROUPING LOGIC
  // ============================================================================

  void _initializeExerciseGroups(List<WorkoutExercise> exercises) {
    // 🚀 FIX: Non ricreare i gruppi se già esistono
    if (_exerciseGroups.isNotEmpty) {
      _logImportant('⚠️ [GROUPING] Groups already exist, skipping recreation');
      return;
    }

    _exerciseGroups = ExerciseGroupingUtils.groupExercises(exercises);

    _logImportant('✅ [GROUPING] Created ${_exerciseGroups.length} groups'); // Solo log importante
    // for (int i = 0; i < _exerciseGroups.length; i++) {
    //   final group = _exerciseGroups[i];
    //   _log('  Group $i: ${group.displayName} (${group.type}, ${group.exercises.length} exercises)');
    // }

    // Log statistiche solo se necessario
    // final stats = ExerciseGroupingUtils.getGroupingStats(_exerciseGroups);
    // _log('📊 [GROUPING] Stats: $stats');
  }

  ExerciseGroup? _getCurrentGroup() {
    if (_currentGroupIndex >= 0 && _currentGroupIndex < _exerciseGroups.length) {
      final group = _exerciseGroups[_currentGroupIndex];
      // _logImportant('🔍 [GET_GROUP] Current group index: $_currentGroupIndex, group: ${group.displayName}'); // Solo quando necessario
      return group;
    }
    _logImportant('🔍 [GET_GROUP] Invalid group index: $_currentGroupIndex, total groups: ${_exerciseGroups.length}');
    return null;
  }

  // ============================================================================
  // ⏱️ TIMER SYSTEM - Invariato
  // ============================================================================

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);
        });
        _bloc.add(bloc.UpdateWorkoutTimer(duration: _elapsedTime));
      }
    });
  }

  void _startRecoveryTimer({int seconds = 90}) {
    _stopRecoveryTimer();

    setState(() {
      _recoverySeconds = seconds;
      _isRecoveryActive = true;
    });

    _recoveryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recoverySeconds--;
        });

        if (_recoverySeconds <= 0) {
          _stopRecoveryTimer();
          _showRecoveryCompleteNotification();
        }
      }
    });
  }

  void _stopRecoveryTimer() {
    _recoveryTimer?.cancel();
    setState(() {
      _isRecoveryActive = false;
      _recoverySeconds = 0;
    });
  }

  void _showRecoveryCompleteNotification() {
    HapticFeedback.mediumImpact();
    if (mounted) {
      CustomSnackbar.show(
        context,
        message: '⏰ Tempo di recupero terminato!',
        isSuccess: true,
      );
    }
  }

  // ============================================================================
  // 🔥 NUOVO: TIMER ISOMETRICO SYSTEM
  // ============================================================================

  void _startIsometricTimer({required int seconds, required int exerciseId}) {
    _stopIsometricTimer();

    setState(() {
      _isometricSeconds = seconds;
      _isIsometricTimerActive = true;
      _currentIsometricExerciseId = exerciseId;
    });

    _logImportant('⏱️ [ISOMETRIC] Starting timer: ${seconds}s for exercise $exerciseId'); // Solo log importante

    _isometricTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _isometricSeconds--;
        });

        if (_isometricSeconds <= 0) {
          _stopIsometricTimer();
          _showIsometricCompleteNotification();
        }
      }
    });
  }

  void _stopIsometricTimer() {
    _isometricTimer?.cancel();
    setState(() {
      _isIsometricTimerActive = false;
      _isometricSeconds = 0;
      _currentIsometricExerciseId = null;
    });
  }

  void _showIsometricCompleteNotification() {
    HapticFeedback.mediumImpact();
    if (mounted) {
      CustomSnackbar.show(
        context,
        message: '🔥 Tempo isometrico completato!',
        isSuccess: true,
      );

      // 🔥 NUOVO: Auto-completa la serie isometrica
      _completeIsometricSeries();
    }
  }

  // ============================================================================
  // 🧭 NAVIGATION SYSTEM - AGGIORNATO PER GRUPPI
  // ============================================================================

  void _navigateToGroup(int groupIndex) {
    if (groupIndex >= 0 && groupIndex < _exerciseGroups.length) {
      setState(() {
        _currentGroupIndex = groupIndex;
      });
      _pageController.animateToPage(
        groupIndex,
        duration: AppConfig.animationNormal,
        curve: AppConfig.animationCurve,
      );
    }
  }

  void _navigateNext() {
    if (_currentGroupIndex < _exerciseGroups.length - 1) {
      _navigateToGroup(_currentGroupIndex + 1);
    }
  }

  void _navigatePrevious() {
    if (_currentGroupIndex > 0) {
      _navigateToGroup(_currentGroupIndex - 1);
    }
  }

  // ============================================================================
  // 💪 EXERCISE DATA MANAGEMENT - Invariato
  // ============================================================================

  void _initializeDefaultValues(List<WorkoutExercise> exercises) {
    for (final exercise in exercises) {
      if (!_exerciseWeights.containsKey(exercise.id)) {
        _exerciseWeights[exercise.id] = exercise.peso;
      }
      if (!_exerciseReps.containsKey(exercise.id)) {
        _exerciseReps[exercise.id] = exercise.ripetizioni;
      }
    }
  }

  void _preloadFromCompletedSeries(Map<int, List<models.CompletedSeriesData>> completedSeries) {
    for (final entry in completedSeries.entries) {
      final exerciseId = entry.key;
      final series = entry.value;

      if (series.isNotEmpty) {
        final lastSeries = series.last;
        _exerciseWeights[exerciseId] = lastSeries.peso;
        _exerciseReps[exerciseId] = lastSeries.ripetizioni;
      }
    }
  }

  // ============================================================================
  // 🏋️ SERIES COMPLETION - AGGIORNATO PER ESERCIZI SINGOLI + ISOMETRICO
  // ============================================================================

  void _completeSeries(WorkoutExercise exercise, int seriesNumber) {
    _logImportant('🚨 COMPLETESERIES CALLED - Exercise: ${exercise.id} (${exercise.nome}), Series: $seriesNumber'); // Solo log importante

    // 🚀 FIX: Prevent multiple saves
    if (_isSavingSeries) {
      _logImportant('🚨 ALREADY SAVING - BLOCKING REQUEST'); // Solo log importante
      return;
    }

    final weight = _exerciseWeights[exercise.id] ?? exercise.peso;
    final reps = _exerciseReps[exercise.id] ?? exercise.ripetizioni;

    if (weight <= 0 || reps <= 0) {
      CustomSnackbar.show(
        context,
        message: 'Inserisci peso e ripetizioni validi',
        isSuccess: false,
      );
      return;
    }

    // 🔥 NUOVO: Se l'esercizio è isometrico, avvia il timer
    if (exercise.isIsometric) {
      _logImportant('🔥 [ISOMETRIC] Exercise ${exercise.nome} is isometric, starting timer: ${exercise.ripetizioni}s'); // Solo log importante
      _startIsometricTimer(seconds: exercise.ripetizioni, exerciseId: exercise.id);

      // Non salvare subito la serie, aspetta che il timer finisca
      CustomSnackbar.show(
        context,
        message: '🔥 Timer isometrico avviato: ${exercise.ripetizioni}s',
        isSuccess: true,
      );
      return;
    }

    // Per esercizi normali, procedi con il salvataggio immediato
    _saveSingleSeries(exercise, seriesNumber, weight, reps);
  }

  void _saveSingleSeries(WorkoutExercise exercise, int seriesNumber, double weight, int reps) {
    _logImportant('💾 [SAVE] Saving series for exercise: ${exercise.id}, series: $seriesNumber'); // Solo log importante

    setState(() {
      _isSavingSeries = true;
    });

    // 🚀 FIX: Flag per tracciare se dobbiamo navigare
    bool shouldNavigateAfterSave = true;

    // Create series data
    final seriesData = models.SeriesData(
      schedaEsercizioId: exercise.id,
      peso: weight,
      ripetizioni: reps,
      serieNumber: seriesNumber,
      serieId: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    // _log('🚨 ADDING LOCAL SERIES'); // Commentato
    _bloc.add(bloc.AddLocalSeries(exerciseId: exercise.id, seriesData: seriesData));

    // Save to server after delay
    Future.delayed(const Duration(milliseconds: 200), () {
      // _log('🚨 DELAYED SAVE STARTED'); // Commentato
      final currentState = _bloc.state;

      if (currentState is bloc.WorkoutSessionActive) {
        final requestId = 'save_${DateTime.now().millisecondsSinceEpoch}';
        // _log('🚨 SENDING SAVE REQUEST: $requestId'); // Commentato
        _bloc.add(bloc.SaveCompletedSeries(
          allenamentoId: currentState.activeWorkout.id,
          serie: [seriesData],
          requestId: requestId,
        ));
      } else {
        // _log('🚨 NOT IN ACTIVE STATE - SKIPPING SERVER SAVE'); // Commentato
      }

      // 🚀 FIX: Reset flag e navigazione SEMPRE dopo 2 secondi
      Timer(const Duration(seconds: 2), () {
        _logImportant('🚨 TIMER RESET TRIGGERED'); // Solo log importante
        _logImportant('🚨 shouldNavigate=$shouldNavigateAfterSave, mounted=$mounted'); // Debug

        if (mounted) {
          setState(() {
            _isSavingSeries = false;
          });

          // 🚀 FIX: Navigazione SEMPRE se shouldNavigateAfterSave è true
          if (shouldNavigateAfterSave) {
            _logImportant('🔄 [NAVIGATION] About to call navigation in 100ms');
            Future.delayed(const Duration(milliseconds: 100), () {
              _logImportant('🔄 [NAVIGATION] Delayed navigation triggered, mounted=$mounted');
              if (mounted) {
                _logImportant('🔄 [NAVIGATION] Calling _handlePostSeriesNavigation()');
                _handlePostSeriesNavigation();
              } else {
                _logImportant('🔄 [NAVIGATION] Widget not mounted, skipping navigation');
              }
            });
          } else {
            _logImportant('🔄 [NAVIGATION] Navigation disabled, skipping');
          }

          setState(() {});

          CustomSnackbar.show(
            context,
            message: '💾 Serie salvata!',
            isSuccess: true,
            duration: const Duration(seconds: 1),
          );
        } else {
          _logImportant('🚨 TIMER RESET: Widget not mounted');
        }
      });
    });

    // Start recovery timer using exercise recovery time
    _startRecoveryTimer(seconds: exercise.tempoRecupero ?? 90);

    // Feedback
    HapticFeedback.lightImpact();
    CustomSnackbar.show(
      context,
      message: '✅ Serie ${seriesNumber} completata!',
      isSuccess: true,
    );
  }

  // 🚀 NUOVO: Gestisce la navigazione automatica dopo il completamento di una serie
  void _handlePostSeriesNavigation() {
    _logImportant('🔄 [NAVIGATION] === STARTING POST-SERIES NAVIGATION ===');

    final currentGroup = _getCurrentGroup();
    _logImportant('🔄 [NAVIGATION] Current group: ${currentGroup?.displayName ?? "NULL"}');

    if (currentGroup == null) {
      _logImportant('🔄 [NAVIGATION] No current group found - EXITING');
      return;
    }

    if (currentGroup.isSingleExercise) {
      _logImportant('🔄 [NAVIGATION] Single exercise group - EXITING');
      return;
    }

    _logImportant('🔄 [NAVIGATION] Group type: ${currentGroup.type}, exercises: ${currentGroup.exercises.length}');
    _logImportant('🔄 [NAVIGATION] Current exercise index: ${currentGroup.currentExerciseIndex}');

    // 🚀 FIX: Per superset/circuit, passa sempre al prossimo esercizio dopo ogni serie
    final nextExerciseIndex = (currentGroup.currentExerciseIndex + 1) % currentGroup.exercises.length;

    _logImportant('🔄 [NAVIGATION] Moving from exercise ${currentGroup.currentExerciseIndex} to ${nextExerciseIndex}');

    // Aggiorna il gruppo con il nuovo esercizio corrente
    final updatedGroup = currentGroup.copyWith(
      currentExerciseIndex: nextExerciseIndex,
    );

    _logImportant('🔄 [NAVIGATION] Updated group created, updating _exerciseGroups[${_currentGroupIndex}]');
    _exerciseGroups[_currentGroupIndex] = updatedGroup;

    // Force UI update con setState separato
    if (mounted) {
      _logImportant('🔄 [NAVIGATION] Calling setState to update UI');
      setState(() {
        // Forza l'aggiornamento dell'UI
      });

      // Show notification about next exercise
      final nextExercise = updatedGroup.currentExercise;
      _logImportant('🔄 [NAVIGATION] Navigation completed to: ${nextExercise.nome}');

      CustomSnackbar.show(
        context,
        message: '➡️ Prossimo: ${nextExercise.nome}',
        isSuccess: true,
        duration: const Duration(seconds: 1),
      );

      _logImportant('🔄 [NAVIGATION] === NAVIGATION COMPLETED SUCCESSFULLY ===');
    } else {
      _logImportant('🔄 [NAVIGATION] Widget not mounted during setState - FAILED');
    }
  }

  // 🔥 NUOVO: Completa serie isometrica (chiamato quando il timer finisce)
  void _completeIsometricSeries() {
    if (_currentIsometricExerciseId == null) return;

    final currentGroup = _getCurrentGroup();
    if (currentGroup == null) return;

    final exercise = currentGroup.exercises.firstWhere(
          (e) => e.id == _currentIsometricExerciseId,
      orElse: () => currentGroup.currentExercise,
    );

    final currentState = _bloc.state;
    if (currentState is! bloc.WorkoutSessionActive) return;

    final seriesNumber = currentGroup.getCurrentExerciseCompletedSeries(currentState.completedSeries) + 1;
    final weight = _exerciseWeights[exercise.id] ?? exercise.peso;
    final reps = _exerciseReps[exercise.id] ?? exercise.ripetizioni;

    _log('🔥 [ISOMETRIC] Completing isometric series for ${exercise.nome}');
    _saveSingleSeries(exercise, seriesNumber, weight, reps);
  }

  // ============================================================================
  // 🏁 WORKOUT COMPLETION
  // ============================================================================

  Future<void> _completeWorkout(BuildContext context, int allenamentoId) async {
    final confirmed = await _showCompleteWorkoutDialog(context);
    if (confirmed == true) {
      final durationMinutes = _elapsedTime.inMinutes;
      _bloc.add(bloc.CompleteWorkoutSession(
        allenamentoId: allenamentoId,
        durataTotale: durationMinutes,
      ));
    }
  }

  // ============================================================================
  // 🎨 UI BUILDERS - AGGIORNATI PER GRUPPI
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldExit = await _showExitDialog(context);
          if (shouldExit == true) {
            _handleWorkoutExit();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: BlocConsumer<bloc.ActiveWorkoutBloc, bloc.ActiveWorkoutState>(
          listener: _handleBlocStateChanges,
          buildWhen: (previous, current) {
            // _log('🔄 [UI] buildWhen: ${previous.runtimeType} -> ${current.runtimeType}, isSaving: $_isSavingSeries'); // Commentato

            if (current is bloc.SeriesSaved) {
              // _log('✅ [UI] SeriesSaved - not rebuilding UI, listener will handle'); // Commentato
              return false;
            }

            if (current is bloc.ActiveWorkoutLoading &&
                previous is bloc.WorkoutSessionActive &&
                _isSavingSeries) {
              // _log('⚠️ [UI] Preventing loading during series save'); // Commentato
              return false;
            }

            // _log('✅ [UI] Allowing UI rebuild'); // Commentato
            return true;
          },
          builder: (context, state) {
            final shouldShowLoading = state is bloc.ActiveWorkoutLoading && !_isSavingSeries;

            // _log('🎨 [UI] Building with state: ${state.runtimeType}, showLoading: $shouldShowLoading, isSaving: $_isSavingSeries'); // Commentato

            // 🚀 SUPER FIX: Force reset flag if API succeeded but state didn't change
            if (_isSavingSeries && state is bloc.WorkoutSessionActive) {
              // _log('🚨 [UI] EMERGENCY: Saving flag still true but in active state - forcing reset!'); // Commentato
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _isSavingSeries) {
                  setState(() {
                    _isSavingSeries = false;
                  });
                  // _log('🔧 [UI] EMERGENCY: Force reset _isSavingSeries to false'); // Commentato
                }
              });
            }

            return LoadingOverlay(
              isLoading: shouldShowLoading,
              message: shouldShowLoading && state is bloc.ActiveWorkoutLoading ? state.message : null,
              child: _buildFullscreenContent(state),
            );
          },
        ),
      ),
    );
  }

  void _handleBlocStateChanges(BuildContext context, bloc.ActiveWorkoutState state) {
    // _log('🚨 LISTENER STATE CHANGED: ${state.runtimeType}'); // Commentato

    if (state is bloc.WorkoutSessionActive) {
      // _log('🚨 LISTENER: WorkoutSessionActive with ${state.exercises.length} exercises'); // Commentato

      // 🚀 NUOVO: Inizializza i gruppi di esercizi
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initializeExerciseGroups(state.exercises);
          _initializeDefaultValues(state.exercises);
          _preloadFromCompletedSeries(state.completedSeries);
          _progressAnimationController.forward();

          // Force rebuild to update counters if needed
          setState(() {});
        }
      });
    } else if (state is bloc.SeriesSaved) {
      // Reset saving flag se per caso arriva ancora
      setState(() {
        _isSavingSeries = false;
      });

      // 🔥 NUOVO: Se era un esercizio isometrico, completa ora la serie
      if (_isIsometricTimerActive && _currentIsometricExerciseId != null) {
        // _log('🔥 [ISOMETRIC] Series saved, but isometric timer still active - completing isometric series'); // Commentato
        _completeIsometricSeries();
      }

      CustomSnackbar.show(
        context,
        message: '💾 Serie salvata!',
        isSuccess: true,
        duration: const Duration(seconds: 1),
      );

    } else if (state is bloc.WorkoutSessionCompleted) {
      _logImportant('🚨 LISTENER: WorkoutSessionCompleted'); // Solo log importante
      CustomSnackbar.show(
        context,
        message: '🎉 Allenamento completato con successo!',
        isSuccess: true,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleWorkoutExit();
        }
      });
    } else if (state is bloc.WorkoutSessionCancelled) {
      _logImportant('🚨 LISTENER: WorkoutSessionCancelled'); // Solo log importante
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pop();
        }
      });
    } else if (state is bloc.ActiveWorkoutError) {
      _logImportant('🚨 LISTENER: ActiveWorkoutError - ${state.message}'); // Solo log importante

      // Reset saving flag on error
      if (_isSavingSeries) {
        setState(() {
          _isSavingSeries = false;
        });
        _logImportant('🚨 LISTENER: Reset _isSavingSeries flag due to error'); // Solo log importante
      }

      CustomSnackbar.show(
        context,
        message: state.message,
        isSuccess: false,
      );
    }
  }

  Widget _buildFullscreenContent(bloc.ActiveWorkoutState state) {
    if (state is bloc.WorkoutSessionActive) {
      if (_exerciseGroups.isEmpty) {
        return _buildEmptyState();
      }

      _log('🎨 [UI] Building content with ${_exerciseGroups.length} groups');

      return Column(
        children: [
          // 📊 FIXED HEADER - AGGIORNATO PER GRUPPI
          _buildFullscreenHeader(state),

          // 🎮 MAIN CONTENT - PageView FOR GROUPS
          Expanded(
            child: _buildGroupPageView(state),
          ),

          // 🧭 FIXED NAVIGATION - AGGIORNATO PER GRUPPI
          _buildFullscreenNavigation(state),
        ],
      );
    }

    return _buildLoadingOrErrorState(state);
  }

  Widget _buildFullscreenHeader(bloc.WorkoutSessionActive state) {
    final totalGroups = _exerciseGroups.length;
    final completedGroups = _calculateCompletedGroups(state);
    final progress = totalGroups > 0 ? completedGroups / totalGroups : 0.0;
    final isWorkoutComplete = completedGroups == totalGroups;

    _log('📊 [HEADER] Total Groups: $totalGroups, Completed: $completedGroups, Progress: $progress');

    return Container(
      padding: EdgeInsets.all(AppConfig.spacingL.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.indigo600,
            AppColors.indigo700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: AppConfig.elevationM,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                IconButton(
                  onPressed: () async {
                    final shouldExit = await _showExitDialog(context);
                    if (shouldExit == true) {
                      _handleWorkoutExit();
                    }
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                ),

                // 🚀 AGGIORNATO: Group counter
                Text(
                  'Gruppo ${_currentGroupIndex + 1} di $totalGroups',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Complete workout button
                if (isWorkoutComplete)
                  IconButton(
                    onPressed: () => _completeWorkout(context, state.activeWorkout.id),
                    icon: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.celebration,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  )
                else
                  SizedBox(width: 48.w),
              ],
            ),

            SizedBox(height: AppConfig.spacingM.h),

            // Timer and progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatDuration(_elapsedTime),
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                // 🚀 AGGIORNATO: Group progress
                Text(
                  '$completedGroups/$totalGroups gruppi completati',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConfig.spacingM.h),

            // Progress bar
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: progress * _progressAnimation.value,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isWorkoutComplete ? AppColors.success : Colors.white,
                  ),
                  minHeight: 8.h,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 NUOVO: PageView per gruppi invece che esercizi singoli
  Widget _buildGroupPageView(bloc.WorkoutSessionActive state) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentGroupIndex = index;
        });
      },
      itemCount: _exerciseGroups.length,
      itemBuilder: (context, index) {
        final group = _exerciseGroups[index];
        _log('🏋️ [GROUP] Building group ${index}: ${group.displayName} (${group.type})');

        return _buildGroupContent(group, state.completedSeries);
      },
    );
  }

  // 🚀 NUOVO: Content per un gruppo di esercizi - MOSTRA SOLO ESERCIZIO CORRENTE
  Widget _buildGroupContent(ExerciseGroup group, Map<int, List<models.CompletedSeriesData>> completedSeries) {
    final isCompleted = group.isCompleted(completedSeries);
    final currentExercise = group.currentExercise;  // 🚀 NUOVO: Solo esercizio corrente
    final currentCompletedSeries = group.getCurrentExerciseCompletedSeries(completedSeries);
    final currentGroupSeriesNumber = group.getCurrentGroupSeriesNumber(completedSeries);  // 🚀 FIX: Serie del gruppo
    final totalSeries = currentExercise.serie;

    // _log('🎨 [GROUP CONTENT] Group: ${group.displayName}, currentExercise: ${currentExercise.nome}, groupSeries=${currentGroupSeriesNumber}, exerciseCompleted=${currentCompletedSeries}/${totalSeries}'); // Commentato

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxHeight < 600;
        final spacing = isSmallScreen ? AppConfig.spacingM.h : AppConfig.spacingL.h;
        final cardPadding = isSmallScreen ? AppConfig.spacingL.w : AppConfig.spacingXL.w;

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppConfig.spacingM.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - AppConfig.spacingM.h * 2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🚀 NUOVO: Group info card con esercizio corrente
                _buildGroupInfoCardWithCurrentExercise(group, completedSeries, isCompleted, cardPadding),

                SizedBox(height: spacing),

                // 🔥 NUOVO: Timer isometrico se attivo per questo esercizio
                if (_isIsometricTimerActive && _currentIsometricExerciseId == currentExercise.id) ...[
                  _buildIsometricTimer(currentExercise, cardPadding, isSmallScreen),
                  SizedBox(height: spacing),
                ],

                // 💪 CURRENT EXERCISE CONTROLS (if not completed)
                if (!isCompleted) ...[
                  _buildCurrentExerciseControls(group, currentExercise, currentGroupSeriesNumber, cardPadding, isSmallScreen),  // 🚀 FIX: Usa serie del gruppo
                  SizedBox(height: spacing),
                ],

                // ⏱️ RECOVERY TIMER
                if (_isRecoveryActive) ...[
                  _buildCompactRecoveryTimer(cardPadding, isSmallScreen),
                  SizedBox(height: spacing),
                ],

                // ✅ CURRENT EXERCISE COMPLETED SERIES
                if (currentCompletedSeries > 0) ...[
                  _buildCurrentExerciseCompletedSeries(currentExercise, completedSeries, cardPadding),
                ],

                // 🏆 COMPLETION CELEBRATION
                if (isCompleted) ...[
                  SizedBox(height: spacing),
                  _buildGroupCompletionCelebration(group, cardPadding),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // 🚀 NUOVO: Group info card con focus sull'esercizio corrente
  Widget _buildGroupInfoCardWithCurrentExercise(ExerciseGroup group, Map<int, List<models.CompletedSeriesData>> completedSeries, bool isCompleted, double padding) {
    final currentExercise = group.currentExercise;
    final currentCompletedSeries = group.getCurrentExerciseCompletedSeries(completedSeries);
    final totalGroupSeries = group.getCompletedSeries(completedSeries);
    final currentGroupSeries = group.getCurrentGroupSeriesNumber(completedSeries);  // 🚀 FIX: Serie corrente del gruppo

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.success.withOpacity(0.1)
            : _getGroupColor(group.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.radiusL.r),
        border: Border.all(
          color: isCompleted ? AppColors.success : _getGroupColor(group.type),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Group name and current exercise indicator
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      group.displayName,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppColors.success : _getGroupColor(group.type),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!group.isSingleExercise) ...[
                      SizedBox(height: 4.h),
                      Text(
                        '${group.currentExerciseIndex + 1}/${group.exercises.length}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (group.type != 'normal')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getGroupColor(group.type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    group.type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: _getGroupColor(group.type),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: AppConfig.spacingL.h),

          // Current exercise name
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppConfig.spacingM.w),
            decoration: BoxDecoration(
              color: _getGroupColor(group.type).withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppConfig.radiusM.r),
            ),
            child: Column(
              children: [
                Text(
                  currentExercise.nome,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: _getGroupColor(group.type),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // 🔥 NUOVO: Indicatore isometrico
                if (currentExercise.isIsometric) ...[
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '🔥 ISOMETRICO',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: AppConfig.spacingM.h),

          // 🚀 FIX: Mostra informazioni corrette per il gruppo
          if (group.isSingleExercise) ...[
            // Per esercizi singoli, mostra il progresso dell'esercizio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.success : _getGroupColor(group.type),
                    borderRadius: BorderRadius.circular(AppConfig.radiusM.r),
                  ),
                  child: Text(
                    '${currentCompletedSeries}/${currentExercise.serie}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Serie Esercizio',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConfig.spacingS.h),
            LinearProgressIndicator(
              value: currentCompletedSeries / currentExercise.serie,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? AppColors.success : _getGroupColor(group.type),
              ),
              minHeight: 6.h,
            ),
          ] else ...[
            // Per gruppi, mostra il progresso del gruppo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.success : _getGroupColor(group.type),
                    borderRadius: BorderRadius.circular(AppConfig.radiusM.r),
                  ),
                  child: Text(
                    'Serie ${currentGroupSeries}',  // 🚀 FIX: Mostra la serie corrente del gruppo
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Serie Gruppo',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConfig.spacingS.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progresso Totale:',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${totalGroupSeries}/${group.totalSeries}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            LinearProgressIndicator(
              value: totalGroupSeries / group.totalSeries,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? AppColors.success : _getGroupColor(group.type).withOpacity(0.7),
              ),
              minHeight: 4.h,
            ),
          ],
        ],
      ),
    );
  }

  // 🔥 NUOVO: Timer isometrico
  Widget _buildIsometricTimer(WorkoutExercise exercise, double padding, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.radiusL.r),
        border: Border.all(color: AppColors.warning, width: 3),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                color: AppColors.warning,
                size: 28.sp,
              ),
              SizedBox(width: AppConfig.spacingS.w),
              Text(
                '🔥 TIMER ISOMETRICO',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),

          SizedBox(height: AppConfig.spacingL.h),

          Text(
            '${_isometricSeconds}s',
            style: TextStyle(
              fontSize: isSmallScreen ? 48.sp : 64.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),

          SizedBox(height: AppConfig.spacingM.h),

          // Progress bar (countdown)
          LinearProgressIndicator(
            value: 1 - (_isometricSeconds / exercise.ripetizioni),
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
            minHeight: 8.h,
          ),

          SizedBox(height: AppConfig.spacingL.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: _stopIsometricTimer,
                icon: Icon(Icons.stop, color: AppColors.error),
                label: Text(
                  'Ferma',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _stopIsometricTimer();
                  _completeIsometricSeries();
                },
                icon: Icon(Icons.check_circle, color: AppColors.success),
                label: Text(
                  'Completa',
                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🚀 NUOVO: Controls per l'esercizio corrente
  Widget _buildCurrentExerciseControls(ExerciseGroup group, WorkoutExercise currentExercise, int groupSeriesNumber, double padding, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConfig.radiusL.r),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Serie ${groupSeriesNumber}',  // 🚀 FIX: Usa il numero di serie del gruppo
            style: TextStyle(
              fontSize: isSmallScreen ? 18.sp : 20.sp,
              fontWeight: FontWeight.bold,
              color: _getGroupColor(group.type),
            ),
          ),

          SizedBox(height: AppConfig.spacingL.h),

          // Current exercise controls
          _buildExerciseInGroupCard(currentExercise, group),

          SizedBox(height: AppConfig.spacingL.h),

          // Complete series button
          CustomButton(
            text: _isSavingSeries
                ? 'Salvando...'
                : currentExercise.isIsometric
                ? 'Avvia Timer (${currentExercise.ripetizioni}s)'
                : 'Completa Serie ${groupSeriesNumber}',  // 🚀 FIX: Mostra numero serie del gruppo
            onPressed: _isRecoveryActive || _isSavingSeries || _isIsometricTimerActive
                ? null
                : () => _completeSeries(currentExercise, groupSeriesNumber),  // 🚀 FIX: Passa numero serie del gruppo
            type: ButtonType.primary,
            size: ButtonSize.medium,
            isFullWidth: true,
            isLoading: _isSavingSeries,
            icon: _isSavingSeries
                ? null
                : currentExercise.isIsometric
                ? const Icon(Icons.timer, color: Colors.white, size: 20)
                : const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // 🚀 NUOVO: Completed series per l'esercizio corrente
  Widget _buildCurrentExerciseCompletedSeries(WorkoutExercise currentExercise, Map<int, List<models.CompletedSeriesData>> completedSeries, double padding) {
    final exerciseSeries = completedSeries[currentExercise.id] ?? [];

    if (exerciseSeries.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.radiusL.r),
        border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Serie Completate (${exerciseSeries.length})',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),

          SizedBox(height: AppConfig.spacingS.h),

          Text(
            currentExercise.nome,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),

          ...exerciseSeries.asMap().entries.map((entry) {
            final index = entry.key;
            final series = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: 2.h, left: 8.w),
              padding: EdgeInsets.symmetric(horizontal: AppConfig.spacingS.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppConfig.radiusS.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 14.sp,
                  ),
                  SizedBox(width: AppConfig.spacingS.w),
                  Text(
                    'Serie ${index + 1}: ${Formatters.formatWeight(series.peso)} × ${series.ripetizioni}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // 🚀 NUOVO: Controls per esercizi del gruppo
  Widget _buildGroupExercisesControls(ExerciseGroup group, Map<int, List<models.CompletedSeriesData>> completedSeries, int nextSeriesNumber, double padding, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConfig.radiusL.r),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Serie $nextSeriesNumber',
            style: TextStyle(
              fontSize: isSmallScreen ? 18.sp : 20.sp,
              fontWeight: FontWeight.bold,
              color: _getGroupColor(group.type),
            ),
          ),

          SizedBox(height: AppConfig.spacingL.h),

          // Esercizi del gruppo
          ...group.exercises.map((exercise) => _buildExerciseInGroupCard(exercise, group)).toList(),

          SizedBox(height: AppConfig.spacingL.h),

          // Complete series button
          CustomButton(
            text: _isSavingSeries ? 'Salvando...' : 'Completa Serie ${nextSeriesNumber}',
            onPressed: _isRecoveryActive || _isSavingSeries ? null : () => _completeGroupSeries(group, nextSeriesNumber),
            type: ButtonType.primary,
            size: ButtonSize.medium,
            isFullWidth: true,
            isLoading: _isSavingSeries,
            icon: _isSavingSeries ? null : const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // 🚀 NUOVO: Card per esercizio all'interno di un gruppo
  Widget _buildExerciseInGroupCard(WorkoutExercise exercise, ExerciseGroup group) {
    final currentWeight = _exerciseWeights[exercise.id] ?? exercise.peso;
    final currentReps = _exerciseReps[exercise.id] ?? exercise.ripetizioni;

    return Container(
      margin: EdgeInsets.only(bottom: AppConfig.spacingM.h),
      padding: EdgeInsets.all(AppConfig.spacingM.w),
      decoration: BoxDecoration(
        color: _getGroupColor(group.type).withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConfig.radiusM.r),
        border: Border.all(color: _getGroupColor(group.type).withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name
          Text(
            exercise.nome,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: _getGroupColor(group.type),
            ),
          ),

          SizedBox(height: AppConfig.spacingS.h),

          // Weight and reps controls
          Row(
            children: [
              Expanded(
                child: _buildCompactValueCard(
                  label: 'Peso',
                  value: Formatters.formatWeight(currentWeight),
                  icon: Icons.fitness_center,
                  onTap: () => _showWeightPicker(exercise.id, currentWeight),
                ),
              ),
              SizedBox(width: AppConfig.spacingM.w),
              Expanded(
                child: _buildCompactValueCard(
                  label: 'Reps',
                  value: '$currentReps',
                  icon: Icons.repeat,
                  onTap: () => _showRepsPicker(exercise.id, currentReps),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 🎨 UI HELPER METHODS - Alcuni mantenuti, altri adattati
  // ============================================================================

  // 🚀 STUB: Metodo obsoleto per compatibilità (non dovrebbe essere chiamato con la nuova logica)
  void _completeGroupSeries(ExerciseGroup group, int seriesNumber) {
    _log('⚠️ [DEPRECATED] _completeGroupSeries called - should not happen with new logic');
    // Con la nuova logica, completa solo l'esercizio corrente
    _completeSeries(group.currentExercise, seriesNumber);
  }

  Widget _buildCompactValueCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConfig.radiusM.r),
      child: Container(
        padding: EdgeInsets.all(AppConfig.spacingM.w),
        decoration: BoxDecoration(
          color: AppColors.indigo600.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConfig.radiusM.r),
          border: Border.all(color: AppColors.indigo600.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.indigo600,
              size: 24.sp,
            ),
            SizedBox(height: AppConfig.spacingXS.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.indigo600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactRecoveryTimer(double padding, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.radiusL.r),
        border: Border.all(color: AppColors.warning, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                color: AppColors.warning,
                size: 24.sp,
              ),
              SizedBox(width: AppConfig.spacingS.w),
              Text(
                'Recupero',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),

          SizedBox(height: AppConfig.spacingM.h),

          Text(
            '${_recoverySeconds}s',
            style: TextStyle(
              fontSize: isSmallScreen ? 36.sp : 48.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),

          SizedBox(height: AppConfig.spacingM.h),

          LinearProgressIndicator(
            value: 1 - (_recoverySeconds / 90),
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
            minHeight: 6.h,
          ),

          SizedBox(height: AppConfig.spacingM.h),

          TextButton(
            onPressed: _stopRecoveryTimer,
            child: Text(
              'Salta',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 NUOVO: Completed series per gruppo - RIMOSSO (non più usato con la nuova logica)
  Widget _buildGroupCompletedSeries(ExerciseGroup group, Map<int, List<models.CompletedSeriesData>> completedSeries, double padding) {
    // Questo metodo non è più utilizzato con la nuova logica
    // che mostra solo l'esercizio corrente
    return const SizedBox.shrink();
  }

  // 🚀 NUOVO: Group completion celebration
  Widget _buildGroupCompletionCelebration(ExerciseGroup group, double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.8),
            AppColors.success,
          ],
        ),
        borderRadius: BorderRadius.circular(AppConfig.radiusL.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.celebration,
            color: Colors.white,
            size: 32.sp,
          ),
          SizedBox(height: AppConfig.spacingS.h),
          Text(
            '🎉 ${group.displayName} Completato!',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 🚀 AGGIORNATO: Navigation per gruppi
  Widget _buildFullscreenNavigation(bloc.WorkoutSessionActive state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppConfig.spacingM.w, vertical: AppConfig.spacingM.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous button
            IconButton(
              onPressed: _currentGroupIndex > 0 ? _navigatePrevious : null,
              icon: Icon(
                Icons.arrow_back,
                color: _currentGroupIndex > 0
                    ? AppColors.indigo600
                    : Colors.grey.shade400,
                size: 28.sp,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _currentGroupIndex > 0
                    ? AppColors.indigo600.withOpacity(0.1)
                    : Colors.transparent,
                minimumSize: Size(40.w, 40.h),
              ),
            ),

            SizedBox(width: AppConfig.spacingS.w),

            // Group indicators
            Expanded(
              child: Container(
                height: 40.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Show max 7 indicators to avoid overflow
                    if (_exerciseGroups.length <= 7)
                      ..._exerciseGroups.asMap().entries.map((entry) =>
                          _buildGroupIndicator(entry.key, entry.value, state))
                    else
                      ..._buildCompactGroupIndicators(state),
                  ],
                ),
              ),
            ),

            SizedBox(width: AppConfig.spacingS.w),

            // Next button
            IconButton(
              onPressed: _currentGroupIndex < _exerciseGroups.length - 1 ? _navigateNext : null,
              icon: Icon(
                Icons.arrow_forward,
                color: _currentGroupIndex < _exerciseGroups.length - 1
                    ? AppColors.indigo600
                    : Colors.grey.shade400,
                size: 28.sp,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _currentGroupIndex < _exerciseGroups.length - 1
                    ? AppColors.indigo600.withOpacity(0.1)
                    : Colors.transparent,
                minimumSize: Size(40.w, 40.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupIndicator(int index, ExerciseGroup group, bloc.WorkoutSessionActive state) {
    final isCompleted = group.isCompleted(state.completedSeries);
    final isCurrent = index == _currentGroupIndex;

    return GestureDetector(
      onTap: () => _navigateToGroup(index),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3.w),
        width: isCurrent ? 16.w : 12.w,
        height: isCurrent ? 16.w : 12.w,
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success
              : isCurrent
              ? _getGroupColor(group.type)
              : Colors.grey.shade300,
          shape: BoxShape.circle,
          border: isCurrent
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
      ),
    );
  }

  List<Widget> _buildCompactGroupIndicators(bloc.WorkoutSessionActive state) {
    return [
      if (_currentGroupIndex > 0) Icon(Icons.more_horiz, color: Colors.grey, size: 16.sp),
      _buildGroupIndicator(_currentGroupIndex, _exerciseGroups[_currentGroupIndex], state),
      SizedBox(width: AppConfig.spacingS.w),
      Text(
        '${_currentGroupIndex + 1}/${_exerciseGroups.length}',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      SizedBox(width: AppConfig.spacingS.w),
      if (_currentGroupIndex < _exerciseGroups.length - 1) Icon(Icons.more_horiz, color: Colors.grey, size: 16.sp),
    ];
  }

  // ============================================================================
  // 🔧 HELPER METHODS - AGGIORNATI PER GRUPPI
  // ============================================================================

  int _calculateCompletedGroups(bloc.WorkoutSessionActive state) {
    // _log('🧮 [CALC] Starting group calculation with ${_exerciseGroups.length} total groups'); // Commentato

    final completed = _exerciseGroups.where((group) {
      final isCompleted = group.isCompleted(state.completedSeries);
      // _log('🧮 [CALC] Group ${group.displayName}: $isCompleted'); // Commentato
      return isCompleted;
    }).length;

    // _log('🧮 [CALC] FINAL RESULT: $completed/${_exerciseGroups.length} groups completed'); // Commentato
    return completed;
  }

  Color _getGroupColor(String groupType) {
    switch (groupType) {
      case 'superset':
        return AppColors.warning;
      case 'circuit':
        return AppColors.purple600;
      case 'normal':
      default:
        return AppColors.indigo600;
    }
  }

  // ============================================================================
  // 🔧 ALTRI HELPER METHODS - Mantenuti invariati
  // ============================================================================

  Widget _buildLoadingOrErrorState(bloc.ActiveWorkoutState state) {
    if (state is bloc.ActiveWorkoutError) {
      return _buildErrorState(state.message);
    }
    return _buildLoadingState();
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: AppColors.error,
          ),
          SizedBox(height: AppConfig.spacingL.h),
          Text(
            'Errore',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
          SizedBox(height: AppConfig.spacingS.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppConfig.spacingXL.h),
          CustomButton(
            text: 'Riprova',
            onPressed: _initializeWorkout,
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.indigo600),
          SizedBox(height: AppConfig.spacingL.h),
          Text(
            'Preparazione allenamento...',
            style: TextStyle(
              fontSize: 18.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppConfig.spacingL.h),
          Text(
            'Nessun esercizio trovato',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 💬 DIALOG METHODS - Invariati
  // ============================================================================

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: AppConfig.spacingS.w),
            const Text('Esci dall\'Allenamento'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sei sicuro di voler uscire? L\'allenamento corrente verrà annullato.',
            ),
            SizedBox(height: AppConfig.spacingM.h),
            Container(
              padding: EdgeInsets.all(AppConfig.spacingM.w),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConfig.radiusM.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.error, size: 20.sp),
                  SizedBox(width: AppConfig.spacingS.w),
                  Expanded(
                    child: Text(
                      'I progressi non salvati andranno persi',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continua Allenamento'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('🚪 Esci'),
          ),
        ],
      ),
    );
  }

  void _handleWorkoutExit() {
    if (!mounted) return;

    _logImportant('🚪 Handling workout exit...'); // Solo log importante

    // Cancel timers
    _workoutTimer?.cancel();
    _recoveryTimer?.cancel();

    // Reset system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Cancel workout if active
    final currentState = _bloc.state;
    if (currentState is bloc.WorkoutSessionActive) {
      _bloc.add(bloc.CancelWorkoutSession(allenamentoId: currentState.activeWorkout.id));
    }

    // Exit immediately
    try {
      if (mounted && Navigator.of(context).canPop()) {
        context.pop();
      }
    } catch (e) {
      _logImportant('⚠️ Could not pop: $e'); // Solo log importante
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<bool?> _showCompleteWorkoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: AppColors.success),
            SizedBox(width: AppConfig.spacingS.w),
            const Text('Completa Allenamento'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Fantastico! Sei sicuro di voler completare questo allenamento?'),
            SizedBox(height: AppConfig.spacingM.h),
            Container(
              padding: EdgeInsets.all(AppConfig.spacingM.w),
              decoration: BoxDecoration(
                color: AppColors.indigo600.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConfig.radiusM.r),
              ),
              child: Column(
                children: [
                  Text(
                    'Durata: ${Formatters.formatDuration(_elapsedTime)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.indigo600,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: AppConfig.spacingS.h),
                  Text(
                    'Hai completato tutti i gruppi!',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Continua'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('🏁 Completa!'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 🎛️ INPUT DIALOGS - Invariati
  // ============================================================================

  Future<void> _showWeightPicker(int exerciseId, double currentWeight) async {
    final weight = await showDialog<double>(
      context: context,
      builder: (context) => WeightPickerDialog(initialWeight: currentWeight),
    );

    if (weight != null && mounted) {
      setState(() {
        _exerciseWeights[exerciseId] = weight;
      });
    }
  }

  Future<void> _showRepsPicker(int exerciseId, int currentReps) async {
    final reps = await showDialog<int>(
      context: context,
      builder: (context) => RepsPickerDialog(initialReps: currentReps),
    );

    if (reps != null && mounted) {
      setState(() {
        _exerciseReps[exerciseId] = reps;
      });
    }
  }
}

// ============================================================================
// 🎛️ WEIGHT PICKER DIALOG - Invariato
// ============================================================================

class WeightPickerDialog extends StatefulWidget {
  final double initialWeight;

  const WeightPickerDialog({
    super.key,
    required this.initialWeight,
  });

  @override
  State<WeightPickerDialog> createState() => _WeightPickerDialogState();
}

class _WeightPickerDialogState extends State<WeightPickerDialog> {
  late double _selectedWeight;

  @override
  void initState() {
    super.initState();
    _selectedWeight = widget.initialWeight;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleziona Peso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${Formatters.formatWeight(_selectedWeight)}',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.indigo600,
            ),
          ),

          SizedBox(height: AppConfig.spacingL.h),

          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildWeightButton('-5', () => _adjustWeight(-5)),
              _buildWeightButton('-2.5', () => _adjustWeight(-2.5)),
              _buildWeightButton('-1', () => _adjustWeight(-1)),
              _buildWeightButton('-0.5', () => _adjustWeight(-0.5)),
              _buildWeightButton('+0.5', () => _adjustWeight(0.5)),
              _buildWeightButton('+1', () => _adjustWeight(1)),
              _buildWeightButton('+2.5', () => _adjustWeight(2.5)),
              _buildWeightButton('+5', () => _adjustWeight(5)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedWeight),
          child: const Text('Conferma'),
        ),
      ],
    );
  }

  Widget _buildWeightButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(50.w, 40.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w),
      ),
      child: Text(label),
    );
  }

  void _adjustWeight(double delta) {
    setState(() {
      _selectedWeight = (_selectedWeight + delta).clamp(0.0, 999.0);
    });
  }
}

// ============================================================================
// 🔢 REPS PICKER DIALOG - Invariato
// ============================================================================

class RepsPickerDialog extends StatefulWidget {
  final int initialReps;

  const RepsPickerDialog({
    super.key,
    required this.initialReps,
  });

  @override
  State<RepsPickerDialog> createState() => _RepsPickerDialogState();
}

class _RepsPickerDialogState extends State<RepsPickerDialog> {
  late int _selectedReps;

  @override
  void initState() {
    super.initState();
    _selectedReps = widget.initialReps;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleziona Ripetizioni'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_selectedReps',
            style: TextStyle(
              fontSize: 48.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.indigo600,
            ),
          ),

          SizedBox(height: AppConfig.spacingL.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRepsButton('-5', () => _adjustReps(-5)),
              _buildRepsButton('-1', () => _adjustReps(-1)),
              _buildRepsButton('+1', () => _adjustReps(1)),
              _buildRepsButton('+5', () => _adjustReps(5)),
            ],
          ),

          SizedBox(height: AppConfig.spacingL.h),

          Text(
            'Valori comuni:',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),

          SizedBox(height: AppConfig.spacingS.h),

          Wrap(
            spacing: 8.w,
            children: [5, 8, 10, 12, 15, 20, 25].map((reps) {
              final isSelected = _selectedReps == reps;
              return ElevatedButton(
                onPressed: () => setState(() => _selectedReps = reps),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? AppColors.indigo600
                      : Colors.grey.shade200,
                  foregroundColor: isSelected
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
                child: Text('$reps'),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedReps),
          child: const Text('Conferma'),
        ),
      ],
    );
  }

  Widget _buildRepsButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(50.w, 40.h),
        padding: EdgeInsets.zero,
      ),
      child: Text(label),
    );
  }

  void _adjustReps(int delta) {
    setState(() {
      _selectedReps = (_selectedReps + delta).clamp(1, 999);
    });
  }
}