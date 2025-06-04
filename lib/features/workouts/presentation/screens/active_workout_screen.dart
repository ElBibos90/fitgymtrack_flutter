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
import '../../models/exercise_group_models.dart';

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
// 🎯 MAIN ACTIVE WORKOUT SCREEN - FULLSCREEN WITH IMPROVED UI
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
  int _currentGroupIndex = 0;
  late PageController _pageController;
  List<ExerciseGroup> _exerciseGroups = [];

  // ⏱️ TIMER SYSTEM
  Timer? _workoutTimer;
  Timer? _recoveryTimer;
  Duration _elapsedTime = Duration.zero;
  int _recoverySeconds = 0;
  bool _isRecoveryActive = false;

  // 💾 EXERCISE DATA
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

  // Track if we're currently saving a series
  bool _isSavingSeries = false;

  @override
  void initState() {
    super.initState();

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
    _isometricTimer?.cancel();
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // ============================================================================
  // 🚀 WORKOUT INITIALIZATION
  // ============================================================================

  Future<void> _initializeWorkout() async {
    final userId = await _sessionService.getCurrentUserId();

    if (userId != null) {
      if (widget.allenamentoId != null) {
        _bloc.add(bloc.LoadCompletedSeries(allenamentoId: widget.allenamentoId!));
      } else {
        _bloc.add(const bloc.ResetActiveWorkoutState());
        await Future.delayed(const Duration(milliseconds: 100));
        _bloc.add(bloc.StartWorkoutSession(userId: userId, schedaId: widget.schedaId));
      }
    } else {
      _logImportant('❌ No user ID found!');
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
  // 🚀 EXERCISE GROUPING LOGIC
  // ============================================================================

  void _initializeExerciseGroups(List<WorkoutExercise> exercises) {
    if (_exerciseGroups.isNotEmpty) {
      _logImportant('⚠️ [GROUPING] Groups already exist, skipping recreation');
      return;
    }

    _exerciseGroups = ExerciseGroupingUtils.groupExercises(exercises);
    _logImportant('✅ [GROUPING] Created ${_exerciseGroups.length} groups');
  }

  ExerciseGroup? _getCurrentGroup() {
    if (_currentGroupIndex >= 0 && _currentGroupIndex < _exerciseGroups.length) {
      return _exerciseGroups[_currentGroupIndex];
    }
    _logImportant('🔍 [GET_GROUP] Invalid group index: $_currentGroupIndex, total groups: ${_exerciseGroups.length}');
    return null;
  }

  // ============================================================================
  // ⏱️ TIMER SYSTEM
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
  // 🔥 TIMER ISOMETRICO SYSTEM
  // ============================================================================

  void _startIsometricTimer({required int seconds, required int exerciseId}) {
    _logImportant('⏱️ [ISOMETRIC START] Starting timer: ${seconds}s for exercise $exerciseId');

    _stopIsometricTimer();

    setState(() {
      _isometricSeconds = seconds;
      _isIsometricTimerActive = true;
      _currentIsometricExerciseId = exerciseId;
    });

    _logImportant('⏱️ [ISOMETRIC START] Timer state set - seconds: $_isometricSeconds, active: $_isIsometricTimerActive, exerciseId: $_currentIsometricExerciseId');

    _isometricTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _isometricSeconds--;
        });

        if (_isometricSeconds <= 0) {
          _logImportant('⏱️ [ISOMETRIC TIMER] Timer reached 0, stopping...');

          // 🚀 FIX: Salva l'ID PRIMA di fermare il timer
          final exerciseIdToComplete = _currentIsometricExerciseId;
          _stopIsometricTimer();
          _showIsometricCompleteNotification(exerciseIdToComplete: exerciseIdToComplete);
        }
      } else {
        _logImportant('❌ [ISOMETRIC TIMER] Widget not mounted, canceling timer');
        timer.cancel();
      }
    });
  }

  void _stopIsometricTimer() {
    _logImportant('⏱️ [ISOMETRIC STOP] Stopping isometric timer...');
    _logImportant('⏱️ [ISOMETRIC STOP] Previous state - active: $_isIsometricTimerActive, exerciseId: $_currentIsometricExerciseId');

    _isometricTimer?.cancel();
    setState(() {
      _isIsometricTimerActive = false;
      _isometricSeconds = 0;
      _currentIsometricExerciseId = null;
    });

    _logImportant('⏱️ [ISOMETRIC STOP] Timer stopped and state cleared');
  }

  void _showIsometricCompleteNotification() {
    HapticFeedback.mediumImpact();
    if (mounted) {
      CustomSnackbar.show(
        context,
        message: '🔥 Tempo isometrico completato!',
        isSuccess: true,
      );
      _completeIsometricSeries();
    }
  }

  // ============================================================================
  // 🧭 NAVIGATION SYSTEM
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

  // 🚀 NUOVO: Navigazione tra esercizi del gruppo
  void _navigateToExerciseInGroup(int exerciseIndex) {
    final currentGroup = _getCurrentGroup();
    if (currentGroup == null) return;

    if (exerciseIndex >= 0 && exerciseIndex < currentGroup.exercises.length) {
      final updatedGroup = currentGroup.copyWith(
        currentExerciseIndex: exerciseIndex,
      );

      setState(() {
        _exerciseGroups[_currentGroupIndex] = updatedGroup;
      });
    }
  }

  // ============================================================================
  // 💪 EXERCISE DATA MANAGEMENT
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
  // 🏋️ SERIES COMPLETION
  // ============================================================================

  void _completeSeries(WorkoutExercise exercise, int seriesNumber) {
    _logImportant('🚨 COMPLETESERIES CALLED - Exercise: ${exercise.id} (${exercise.nome}), Series: $seriesNumber');

    if (_isSavingSeries) {
      _logImportant('🚨 ALREADY SAVING - BLOCKING REQUEST');
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

    if (exercise.isIsometric) {
      final selectedSeconds = _exerciseReps[exercise.id] ?? exercise.ripetizioni;
      _logImportant('🔥 [ISOMETRIC] Exercise ${exercise.nome} is isometric, starting timer: ${selectedSeconds}s');
      _startIsometricTimer(seconds: selectedSeconds, exerciseId: exercise.id);

      CustomSnackbar.show(
        context,
        message: '🔥 Timer isometrico avviato: ${selectedSeconds}s - Mantieni la posizione!',
        isSuccess: true,
      );
      return;
    }

    _saveSingleSeries(exercise, seriesNumber, weight, reps);
  }

  void _saveSingleSeries(WorkoutExercise exercise, int seriesNumber, double weight, int reps) {
    _logImportant('💾 [SAVE] === STARTING SAVE PROCESS ===');
    _logImportant('💾 [SAVE] Exercise: ${exercise.id} (${exercise.nome})');
    _logImportant('💾 [SAVE] Series: $seriesNumber, Weight: $weight, Reps: $reps');
    _logImportant('💾 [SAVE] Current saving state: $_isSavingSeries');

    if (_isSavingSeries) {
      _logImportant('❌ [SAVE] Already saving, blocking request');
      return;
    }

    setState(() {
      _isSavingSeries = true;
    });

    _logImportant('💾 [SAVE] Set saving state to true');

    final seriesData = models.SeriesData(
      schedaEsercizioId: exercise.id,
      peso: weight,
      ripetizioni: reps,
      serieNumber: seriesNumber,
      serieId: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    _logImportant('💾 [SAVE] Created SeriesData: schedaEsercizioId=${seriesData.schedaEsercizioId}, peso=${seriesData.peso}, reps=${seriesData.ripetizioni}');

    _bloc.add(bloc.AddLocalSeries(exerciseId: exercise.id, seriesData: seriesData));
    _logImportant('💾 [SAVE] Added local series to bloc');

    Future.delayed(const Duration(milliseconds: 200), () {
      _logImportant('💾 [SAVE] Delayed save starting...');
      final currentState = _bloc.state;
      _logImportant('💾 [SAVE] Current bloc state: ${currentState.runtimeType}');

      if (currentState is bloc.WorkoutSessionActive) {
        final requestId = 'save_${DateTime.now().millisecondsSinceEpoch}';
        _logImportant('💾 [SAVE] Sending SaveCompletedSeries with requestId: $requestId');
        _bloc.add(bloc.SaveCompletedSeries(
          allenamentoId: currentState.activeWorkout.id,
          serie: [seriesData],
          requestId: requestId,
        ));
        _logImportant('💾 [SAVE] SaveCompletedSeries event sent to bloc');
      } else {
        _logImportant('❌ [SAVE] Not in active state, skipping server save');
      }

      Timer(const Duration(seconds: 2), () {
        _logImportant('💾 [SAVE] Reset timer triggered');

        if (mounted) {
          setState(() {
            _isSavingSeries = false;
          });
          _logImportant('💾 [SAVE] Reset saving state to false');

          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _logImportant('💾 [SAVE] About to call post-series navigation');
              _handlePostSeriesNavigation();
            }
          });

          setState(() {});

          CustomSnackbar.show(
            context,
            message: '💾 Serie salvata!',
            isSuccess: true,
            duration: const Duration(seconds: 1),
          );
          _logImportant('💾 [SAVE] === SAVE PROCESS COMPLETED ===');
        }
      });
    });

    _startRecoveryTimer(seconds: exercise.tempoRecupero ?? 90);

    HapticFeedback.lightImpact();
    CustomSnackbar.show(
      context,
      message: '✅ Serie ${seriesNumber} completata!',
      isSuccess: true,
    );
  }

  void _handlePostSeriesNavigation() {
    _logImportant('🔄 [NAVIGATION] === STARTING POST-SERIES NAVIGATION ===');

    final currentGroup = _getCurrentGroup();
    if (currentGroup == null) {
      _logImportant('🔄 [NAVIGATION] No current group found - EXITING');
      return;
    }

    if (currentGroup.isSingleExercise) {
      _logImportant('🔄 [NAVIGATION] Single exercise group - EXITING');
      return;
    }

    final nextExerciseIndex = (currentGroup.currentExerciseIndex + 1) % currentGroup.exercises.length;

    final updatedGroup = currentGroup.copyWith(
      currentExerciseIndex: nextExerciseIndex,
    );

    _exerciseGroups[_currentGroupIndex] = updatedGroup;

    if (mounted) {
      setState(() {});

      final nextExercise = updatedGroup.currentExercise;
      CustomSnackbar.show(
        context,
        message: '➡️ Prossimo: ${nextExercise.nome}',
        isSuccess: true,
        duration: const Duration(seconds: 1),
      );
    }
  }

  void _completeIsometricSeries([int? exerciseIdToComplete]) {
    _logImportant('🔥 [ISOMETRIC COMPLETE] Starting completion process...');

    // 🚀 FIX: Usa l'ID passato come parametro o fallback all'ID corrente
    final targetExerciseId = exerciseIdToComplete ?? _currentIsometricExerciseId;

    if (targetExerciseId == null) {
      _logImportant('❌ [ISOMETRIC COMPLETE] No exercise ID available (passed: $exerciseIdToComplete, current: $_currentIsometricExerciseId)');
      return;
    }

    _logImportant('🔥 [ISOMETRIC COMPLETE] Using exercise ID: $targetExerciseId');

    final currentGroup = _getCurrentGroup();
    if (currentGroup == null) {
      _logImportant('❌ [ISOMETRIC COMPLETE] No current group found');
      return;
    }

    final exercise = currentGroup.exercises.firstWhere(
          (e) => e.id == targetExerciseId,
      orElse: () => currentGroup.currentExercise,
    );

    _logImportant('🔥 [ISOMETRIC COMPLETE] Found exercise: ${exercise.nome} (ID: ${exercise.id})');

    final currentState = _bloc.state;
    if (currentState is! bloc.WorkoutSessionActive) {
      _logImportant('❌ [ISOMETRIC COMPLETE] Bloc not in active state: ${currentState.runtimeType}');
      return;
    }

    final seriesNumber = currentGroup.getCurrentExerciseCompletedSeries(currentState.completedSeries) + 1;
    final weight = _exerciseWeights[exercise.id] ?? exercise.peso;
    final reps = _exerciseReps[exercise.id] ?? exercise.ripetizioni;

    _logImportant('🔥 [ISOMETRIC COMPLETE] Completing series $seriesNumber with weight: $weight, reps: $reps');
    _logImportant('🔥 [ISOMETRIC COMPLETE] About to call _saveSingleSeries()');

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
  // 🎨 UI BUILDERS - MAIN BUILD METHOD
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
            if (current is bloc.SeriesSaved) {
              return false;
            }

            if (current is bloc.ActiveWorkoutLoading &&
                previous is bloc.WorkoutSessionActive &&
                _isSavingSeries) {
              return false;
            }

            return true;
          },
          builder: (context, state) {
            final shouldShowLoading = state is bloc.ActiveWorkoutLoading && !_isSavingSeries;

            if (_isSavingSeries && state is bloc.WorkoutSessionActive) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _isSavingSeries) {
                  setState(() {
                    _isSavingSeries = false;
                  });
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
    if (state is bloc.WorkoutSessionActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initializeExerciseGroups(state.exercises);
          _initializeDefaultValues(state.exercises);
          _preloadFromCompletedSeries(state.completedSeries);
          _progressAnimationController.forward();
          setState(() {});
        }
      });
    } else if (state is bloc.SeriesSaved) {
      setState(() {
        _isSavingSeries = false;
      });

      CustomSnackbar.show(
        context,
        message: '💾 Serie salvata!',
        isSuccess: true,
        duration: const Duration(seconds: 1),
      );

    } else if (state is bloc.WorkoutSessionCompleted) {
      _logImportant('🚨 LISTENER: WorkoutSessionCompleted');
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
      _logImportant('🚨 LISTENER: WorkoutSessionCancelled');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pop();
        }
      });
    } else if (state is bloc.ActiveWorkoutError) {
      _logImportant('🚨 LISTENER: ActiveWorkoutError - ${state.message}');

      if (_isSavingSeries) {
        setState(() {
          _isSavingSeries = false;
        });
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

      return Column(
        children: [
          // 📊 FIXED HEADER
          _buildFullscreenHeader(state),

          // 🎮 MAIN CONTENT - PageView FOR GROUPS
          Expanded(
            child: _buildGroupPageView(state),
          ),

          // 🧭 FIXED NAVIGATION
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

                // Group counter
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
        return _buildGroupContent(group, state.completedSeries);
      },
    );
  }

  // ============================================================================
  // 🚀 NUOVO: BARRA DI NAVIGAZIONE ESERCIZI MIGLIORATA
  // ============================================================================

  Widget _buildExerciseNavigationBar(ExerciseGroup group, Map<int, List<models.CompletedSeriesData>> completedSeries) {
    // Solo per gruppi multi-esercizio
    if (group.isSingleExercise) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppConfig.spacingL.h),
      padding: EdgeInsets.all(AppConfig.spacingM.w),
      decoration: BoxDecoration(
        color: _getGroupColor(group.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.radiusL.r),
        border: Border.all(
          color: _getGroupColor(group.type).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con tipo di gruppo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                group.displayName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: _getGroupColor(group.type),
                ),
              ),
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

          SizedBox(height: AppConfig.spacingM.h),

          // Lista esercizi navigabili
          SizedBox(
            height: 50.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: group.exercises.length,
              itemBuilder: (context, index) {
                final exercise = group.exercises[index];
                final isCurrentExercise = index == group.currentExerciseIndex;
                final exerciseCompletedSeries = completedSeries[exercise.id]?.length ?? 0;
                final exerciseIsCompleted = exerciseCompletedSeries >= exercise.serie;

                return GestureDetector(
                  onTap: () => _navigateToExerciseInGroup(index),
                  child: Container(
                    margin: EdgeInsets.only(right: AppConfig.spacingS.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConfig.spacingM.w,
                      vertical: AppConfig.spacingS.h,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrentExercise
                          ? _getGroupColor(group.type)
                          : exerciseIsCompleted
                          ? AppColors.success.withOpacity(0.8)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(AppConfig.radiusM.r),
                      border: isCurrentExercise
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          exercise.nome,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: isCurrentExercise || exerciseIsCompleted
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '$exerciseCompletedSeries/${exercise.serie}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: isCurrentExercise || exerciseIsCompleted
                                ? Colors.white.withOpacity(0.9)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 🎨 GROUP CONTENT - AGGIORNATO CON BARRA NAVIGAZIONE
  // ============================================================================

  Widget _buildGroupContent(ExerciseGroup group, Map<int, List<models.CompletedSeriesData>> completedSeries) {
    final isCompleted = group.isCompleted(completedSeries);
    final currentExercise = group.currentExercise;
    final currentCompletedSeries = group.getCurrentExerciseCompletedSeries(completedSeries);
    final currentGroupSeriesNumber = group.getCurrentGroupSeriesNumber(completedSeries);

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
                // 🚀 Barra di navigazione esercizi (solo per gruppi multi-esercizio)
                _buildExerciseNavigationBar(group, completedSeries),

                // Timer isometrico se attivo
                if (_isIsometricTimerActive && _currentIsometricExerciseId == currentExercise.id) ...[
                  _buildIsometricTimer(currentExercise, cardPadding, isSmallScreen),
                  SizedBox(height: spacing),
                ],

                // Current exercise controls (if not completed)
                if (!isCompleted) ...[
                  _buildCurrentExerciseControls(group, currentExercise, currentGroupSeriesNumber, cardPadding, isSmallScreen),
                  SizedBox(height: spacing),
                ],

                // Recovery timer
                if (_isRecoveryActive) ...[
                  _buildCompactRecoveryTimer(cardPadding, isSmallScreen),
                  SizedBox(height: spacing),
                ],

                // Current exercise completed series
                if (currentCompletedSeries > 0) ...[
                  _buildCurrentExerciseCompletedSeries(currentExercise, completedSeries, cardPadding),
                ],

                // Group completion celebration
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

  // ============================================================================
  // 🎨 RESTO DEI WIDGET BUILDERS - MANTENUTI INVARIATI
  // ============================================================================

  Widget _buildGroupInfoCardWithCurrentExercise(ExerciseGroup group, Map<int, List<models.CompletedSeriesData>> completedSeries, bool isCompleted, double padding) {
    final currentExercise = group.currentExercise;
    final currentCompletedSeries = group.getCurrentExerciseCompletedSeries(completedSeries);
    final totalGroupSeries = group.getCompletedSeries(completedSeries);
    final currentGroupSeries = group.getCurrentGroupSeriesNumber(completedSeries);

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

          if (group.isSingleExercise) ...[
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
                    'Serie ${currentGroupSeries}',
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

  Widget _buildIsometricTimer(WorkoutExercise exercise, double padding, bool isSmallScreen) {
    // 🚀 MIGLIORATO: Usa il valore selezionato dall'utente per calcolare il progresso
    final selectedSeconds = _exerciseReps[exercise.id] ?? exercise.ripetizioni;

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
                  _logImportant('🔥 [ISOMETRIC MANUAL] User manually completed isometric exercise');
                  final exerciseIdToComplete = _currentIsometricExerciseId;
                  _stopIsometricTimer();
                  _completeIsometricSeries(exerciseIdToComplete);
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

  Widget _buildCurrentExerciseControls(ExerciseGroup group, WorkoutExercise currentExercise, int groupSeriesNumber, double padding, bool isSmallScreen) {
    // 🚀 NUOVO: Ottieni il valore selezionato dall'utente per l'esercizio corrente
    final selectedReps = _exerciseReps[currentExercise.id] ?? currentExercise.ripetizioni;

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
            'Serie ${groupSeriesNumber}',
            style: TextStyle(
              fontSize: isSmallScreen ? 18.sp : 20.sp,
              fontWeight: FontWeight.bold,
              color: _getGroupColor(group.type),
            ),
          ),

          SizedBox(height: AppConfig.spacingL.h),

          _buildExerciseInGroupCard(currentExercise, group),

          SizedBox(height: AppConfig.spacingL.h),

          CustomButton(
            text: _isSavingSeries
                ? 'Salvando...'
                : currentExercise.isIsometric
                ? 'Avvia Timer (${selectedReps}s)'
                : 'Completa Serie ${groupSeriesNumber}',
            onPressed: _isRecoveryActive || _isSavingSeries || _isIsometricTimerActive
                ? null
                : () => _completeSeries(currentExercise, groupSeriesNumber),
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
          Text(
            exercise.nome,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: _getGroupColor(group.type),
            ),
          ),

          SizedBox(height: AppConfig.spacingS.h),

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
                  label: exercise.isIsometric ? 'Secondi' : 'Reps',
                  value: '$currentReps',
                  icon: exercise.isIsometric ? Icons.timer : Icons.repeat,
                  onTap: () => _showRepsPicker(exercise.id, currentReps),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

            Expanded(
              child: Container(
                height: 40.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
  // 🔧 HELPER METHODS
  // ============================================================================

  int _calculateCompletedGroups(bloc.WorkoutSessionActive state) {
    final completed = _exerciseGroups.where((group) {
      return group.isCompleted(state.completedSeries);
    }).length;

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
  // 💬 DIALOG METHODS
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

    _logImportant('🚪 Handling workout exit...');

    _workoutTimer?.cancel();
    _recoveryTimer?.cancel();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final currentState = _bloc.state;
    if (currentState is bloc.WorkoutSessionActive) {
      _bloc.add(bloc.CancelWorkoutSession(allenamentoId: currentState.activeWorkout.id));
    }

    try {
      if (mounted && Navigator.of(context).canPop()) {
        context.pop();
      }
    } catch (e) {
      _logImportant('⚠️ Could not pop: $e');
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
  // 🎛️ INPUT DIALOGS
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
    // 🚀 MIGLIORATO: Determina se l'esercizio è isometrico per il titolo del dialog
    final currentGroup = _getCurrentGroup();
    final exercise = currentGroup?.exercises.firstWhere((e) => e.id == exerciseId);
    final isIsometric = exercise?.isIsometric ?? false;

    final reps = await showDialog<int>(
      context: context,
      builder: (context) => RepsPickerDialog(
        initialReps: currentReps,
        isIsometric: isIsometric,
      ),
    );

    if (reps != null && mounted) {
      setState(() {
        _exerciseReps[exerciseId] = reps;
      });
    }
  }
}

// ============================================================================
// 🎛️ WEIGHT PICKER DIALOG
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
// 🔢 REPS PICKER DIALOG
// ============================================================================

class RepsPickerDialog extends StatefulWidget {
  final int initialReps;
  final bool isIsometric;

  const RepsPickerDialog({
    super.key,
    required this.initialReps,
    this.isIsometric = false,
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
      title: Text(widget.isIsometric ? 'Seleziona Secondi' : 'Seleziona Ripetizioni'),
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
            widget.isIsometric ? 'Valori comuni (secondi):' : 'Valori comuni:',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),

          SizedBox(height: AppConfig.spacingS.h),

          Wrap(
            spacing: 8.w,
            children: (widget.isIsometric ? [10, 15, 20, 30, 45, 60, 90] : [5, 8, 10, 12, 15, 20, 25]).map((reps) {
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