// lib/features/workouts/presentation/screens/active_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:developer' as developer;

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

// ============================================================================
// 🎯 MAIN ACTIVE WORKOUT SCREEN - FULLSCREEN ONLY
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

  // 🎮 FULLSCREEN STATE
  int _currentExerciseIndex = 0;
  late PageController _pageController;

  // ⏱️ TIMER SYSTEM
  Timer? _workoutTimer;
  Timer? _recoveryTimer;
  Duration _elapsedTime = Duration.zero;
  int _recoverySeconds = 0;
  bool _isRecoveryActive = false;

  // 💾 EXERCISE DATA
  Map<int, double> _exerciseWeights = {};
  Map<int, int> _exerciseReps = {};

  // 🎨 ANIMATIONS
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  late AnimationController _completionAnimationController;

  @override
  void initState() {
    super.initState();

    developer.log('🚀 ActiveWorkoutScreen 2.0 - Fullscreen Mode INIT', name: 'ActiveWorkoutScreen');

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
  // 🚀 WORKOUT INITIALIZATION
  // ============================================================================

  Future<void> _initializeWorkout() async {
    developer.log('🚀 Initializing fullscreen workout...', name: 'ActiveWorkoutScreen');

    final userId = await _sessionService.getCurrentUserId();

    if (userId != null) {
      if (widget.allenamentoId != null) {
        developer.log('🔄 Loading existing workout: ${widget.allenamentoId}', name: 'ActiveWorkoutScreen');
        _bloc.add(bloc.LoadCompletedSeries(allenamentoId: widget.allenamentoId!));
      } else {
        developer.log('🆕 Starting new fullscreen workout session', name: 'ActiveWorkoutScreen');

        // Reset state before starting
        _bloc.add(const bloc.ResetActiveWorkoutState());
        await Future.delayed(const Duration(milliseconds: 100));

        // Start new workout
        _bloc.add(bloc.StartWorkoutSession(userId: userId, schedaId: widget.schedaId));
      }
    } else {
      developer.log('❌ No user ID found!', name: 'ActiveWorkoutScreen');
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
  // 🧭 NAVIGATION SYSTEM
  // ============================================================================

  void _navigateToExercise(int index, List<WorkoutExercise> exercises) {
    if (index >= 0 && index < exercises.length) {
      setState(() {
        _currentExerciseIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: AppConfig.animationNormal,
        curve: AppConfig.animationCurve,
      );
    }
  }

  void _navigateNext(List<WorkoutExercise> exercises) {
    if (_currentExerciseIndex < exercises.length - 1) {
      _navigateToExercise(_currentExerciseIndex + 1, exercises);
    }
  }

  void _navigatePrevious(List<WorkoutExercise> exercises) {
    if (_currentExerciseIndex > 0) {
      _navigateToExercise(_currentExerciseIndex - 1, exercises);
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

    // Create series data
    final seriesData = models.SeriesData(
      schedaEsercizioId: exercise.id,
      peso: weight,
      ripetizioni: reps,
      serieNumber: seriesNumber,
      serieId: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    // Add local series for immediate feedback
    _bloc.add(bloc.AddLocalSeries(exerciseId: exercise.id, seriesData: seriesData));

    // Save to database
    final currentState = _bloc.state;
    if (currentState is bloc.WorkoutSessionActive) {
      final requestId = 'save_${DateTime.now().millisecondsSinceEpoch}';
      _bloc.add(bloc.SaveCompletedSeries(
        allenamentoId: currentState.activeWorkout.id,
        serie: [seriesData],
        requestId: requestId,
      ));
    }

    // Start recovery timer
    _startRecoveryTimer(seconds: exercise.tempoRecupero ?? 90);

    // Feedback
    HapticFeedback.lightImpact();
    CustomSnackbar.show(
      context,
      message: '✅ Serie ${seriesNumber} completata!',
      isSuccess: true,
    );
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
  // 🎨 UI BUILDERS
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
            return current is! bloc.ActiveWorkoutLoading ||
                previous.runtimeType != current.runtimeType;
          },
          builder: (context, state) {
            return LoadingOverlay(
              isLoading: state is bloc.ActiveWorkoutLoading,
              message: state is bloc.ActiveWorkoutLoading ? state.message : null,
              child: _buildFullscreenContent(state),
            );
          },
        ),
      ),
    );
  }

  void _handleBlocStateChanges(BuildContext context, bloc.ActiveWorkoutState state) {
    developer.log('🔄 State changed: ${state.runtimeType}', name: 'ActiveWorkoutScreen');

    if (state is bloc.WorkoutSessionActive) {
      developer.log('✅ Workout session is active with ${state.exercises.length} exercises', name: 'ActiveWorkoutScreen');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initializeDefaultValues(state.exercises);
          _preloadFromCompletedSeries(state.completedSeries);
          _progressAnimationController.forward();
        }
      });
    } else if (state is bloc.WorkoutSessionCompleted) {
      developer.log('🏁 Workout completed!', name: 'ActiveWorkoutScreen');
      CustomSnackbar.show(
        context,
        message: '🎉 Allenamento completato con successo!',
        isSuccess: true,
      );
      // 🚀 FIX: Exit immediately after showing snackbar, no delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleWorkoutExit();
        }
      });
    } else if (state is bloc.WorkoutSessionCancelled) {
      developer.log('🚪 Workout cancelled!', name: 'ActiveWorkoutScreen');
      // 🚀 FIX: Exit immediately after cancellation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pop();
        }
      });
    } else if (state is bloc.ActiveWorkoutError) {
      developer.log('❌ Error: ${state.message}', name: 'ActiveWorkoutScreen');
      CustomSnackbar.show(
        context,
        message: state.message,
        isSuccess: false,
      );
    }
  }

  Widget _buildFullscreenContent(bloc.ActiveWorkoutState state) {
    if (state is bloc.WorkoutSessionActive) {
      final exercises = state.exercises;
      if (exercises.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        children: [
          // 📊 FIXED HEADER
          _buildFullscreenHeader(state),

          // 🎮 MAIN CONTENT - PageView
          Expanded(
            child: _buildExercisePageView(state),
          ),

          // 🧭 FIXED NAVIGATION
          _buildFullscreenNavigation(exercises, state),
        ],
      );
    }

    return _buildLoadingOrErrorState(state);
  }

  Widget _buildFullscreenHeader(bloc.WorkoutSessionActive state) {
    final exercises = state.exercises;
    final totalExercises = exercises.length;
    final completedExercises = _calculateCompletedExercises(state);
    final progress = totalExercises > 0 ? completedExercises / totalExercises : 0.0;
    final isWorkoutComplete = completedExercises == totalExercises;

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

                // Exercise counter
                Text(
                  'Esercizio ${_currentExerciseIndex + 1} di $totalExercises',
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
                  '$completedExercises/$totalExercises completati',
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

  Widget _buildExercisePageView(bloc.WorkoutSessionActive state) {
    final exercises = state.exercises;

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentExerciseIndex = index;
        });
      },
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final completedSeries = state.completedSeries[exercise.id] ?? [];

        return _buildExerciseContent(exercise, completedSeries);
      },
    );
  }

  Widget _buildExerciseContent(WorkoutExercise exercise, List<models.CompletedSeriesData> completedSeries) {
    final currentWeight = _exerciseWeights[exercise.id] ?? exercise.peso;
    final currentReps = _exerciseReps[exercise.id] ?? exercise.ripetizioni;
    final isCompleted = completedSeries.length >= exercise.serie;
    final nextSeriesNumber = completedSeries.length + 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 🚀 FIX: Responsive layout based on screen height
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
                // 🏋️ EXERCISE INFO CARD - Compact
                _buildCompactExerciseInfoCard(exercise, completedSeries, isCompleted, cardPadding),

                SizedBox(height: spacing),

                // 💪 INPUT CONTROLS (if not completed)
                if (!isCompleted) ...[
                  _buildCompactInputControls(exercise, currentWeight, currentReps, nextSeriesNumber, cardPadding, isSmallScreen),
                  SizedBox(height: spacing),
                ],

                // ⏱️ RECOVERY TIMER
                if (_isRecoveryActive) ...[
                  _buildCompactRecoveryTimer(cardPadding, isSmallScreen),
                  SizedBox(height: spacing),
                ],

                // ✅ COMPLETED SERIES
                if (completedSeries.isNotEmpty) ...[
                  _buildCompactCompletedSeries(completedSeries, cardPadding),
                ],

                // 🏆 COMPLETION CELEBRATION
                if (isCompleted) ...[
                  SizedBox(height: spacing),
                  _buildCompactCompletionCelebration(cardPadding),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactExerciseInfoCard(WorkoutExercise exercise, List<models.CompletedSeriesData> completedSeries, bool isCompleted, double padding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.success.withOpacity(0.1)
            : AppColors.indigo600.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.radiusL.r),
        border: Border.all(
          color: isCompleted ? AppColors.success : AppColors.indigo600,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Exercise name - Responsive font size
          Text(
            exercise.nome,
            style: TextStyle(
              fontSize: 22.sp, // Reduced from 28.sp
              fontWeight: FontWeight.bold,
              color: isCompleted ? AppColors.success : AppColors.indigo600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: AppConfig.spacingM.h),

          // Series counter and progress in row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.success : AppColors.indigo600,
                  borderRadius: BorderRadius.circular(AppConfig.radiusM.r),
                ),
                child: Text(
                  '${completedSeries.length}/${exercise.serie}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Text(
                'Serie',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: AppConfig.spacingM.h),

          // Compact progress bar
          LinearProgressIndicator(
            value: completedSeries.length / exercise.serie,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? AppColors.success : AppColors.indigo600,
            ),
            minHeight: 8.h,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInputControls(WorkoutExercise exercise, double currentWeight, int currentReps, int nextSeriesNumber, double padding, bool isSmallScreen) {
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
              color: AppColors.indigo600,
            ),
          ),

          SizedBox(height: AppConfig.spacingL.h),

          // Compact weight and reps inputs
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

          SizedBox(height: AppConfig.spacingL.h),

          // Complete series button
          CustomButton(
            text: 'Completa Serie',
            onPressed: _isRecoveryActive ? null : () => _completeSeries(exercise, nextSeriesNumber),
            type: ButtonType.primary,
            size: ButtonSize.medium,
            isFullWidth: true,
            icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
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

  Widget _buildCompactCompletedSeries(List<models.CompletedSeriesData> completedSeries, double padding) {
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
            'Completate (${completedSeries.length})',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),

          SizedBox(height: AppConfig.spacingS.h),

          // Show max 3 recent series to save space
          ...completedSeries.take(3).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final series = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: 4.h),
              padding: EdgeInsets.symmetric(horizontal: AppConfig.spacingS.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppConfig.radiusS.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 16.sp,
                  ),
                  SizedBox(width: AppConfig.spacingS.w),
                  Text(
                    '${Formatters.formatWeight(series.peso)} × ${series.ripetizioni}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          if (completedSeries.length > 3)
            Text(
              '+${completedSeries.length - 3} altre serie',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactCompletionCelebration(double padding) {
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
            '🎉 Completato!',
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

  Widget _buildFullscreenNavigation(List<WorkoutExercise> exercises, bloc.WorkoutSessionActive state) {
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
            // Previous button - Icon only for space
            IconButton(
              onPressed: _currentExerciseIndex > 0
                  ? () => _navigatePrevious(exercises)
                  : null,
              icon: Icon(
                Icons.arrow_back,
                color: _currentExerciseIndex > 0
                    ? AppColors.indigo600
                    : Colors.grey.shade400,
                size: 28.sp,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _currentExerciseIndex > 0
                    ? AppColors.indigo600.withOpacity(0.1)
                    : Colors.transparent,
                minimumSize: Size(40.w, 40.h),
              ),
            ),

            SizedBox(width: AppConfig.spacingS.w),

            // Exercise indicators
            Expanded(
              child: Container(
                height: 40.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Show max 7 indicators to avoid overflow
                    if (exercises.length <= 7)
                      ...exercises.asMap().entries.map((entry) =>
                          _buildExerciseIndicator(entry.key, entry.value, state, exercises))
                    else
                      ..._buildCompactIndicators(exercises, state),
                  ],
                ),
              ),
            ),

            SizedBox(width: AppConfig.spacingS.w),

            // Next button - Icon only for space
            IconButton(
              onPressed: _currentExerciseIndex < exercises.length - 1
                  ? () => _navigateNext(exercises)
                  : null,
              icon: Icon(
                Icons.arrow_forward,
                color: _currentExerciseIndex < exercises.length - 1
                    ? AppColors.indigo600
                    : Colors.grey.shade400,
                size: 28.sp,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _currentExerciseIndex < exercises.length - 1
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

  Widget _buildExerciseIndicator(int index, WorkoutExercise exercise, bloc.WorkoutSessionActive state, List<WorkoutExercise> exercises) {
    final completedSeries = state.completedSeries[exercise.id] ?? [];
    final isCompleted = completedSeries.length >= exercise.serie;
    final isCurrent = index == _currentExerciseIndex;

    return GestureDetector(
      onTap: () => _navigateToExercise(index, exercises),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3.w),
        width: isCurrent ? 16.w : 12.w,
        height: isCurrent ? 16.w : 12.w,
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success
              : isCurrent
              ? AppColors.indigo600
              : Colors.grey.shade300,
          shape: BoxShape.circle,
          border: isCurrent
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
      ),
    );
  }

  List<Widget> _buildCompactIndicators(List<WorkoutExercise> exercises, bloc.WorkoutSessionActive state) {
    // For many exercises, show: [•] [•] [•] 3/10 [•] [•] [•]
    return [
      if (_currentExerciseIndex > 0) Icon(Icons.more_horiz, color: Colors.grey, size: 16.sp),
      _buildExerciseIndicator(_currentExerciseIndex, exercises[_currentExerciseIndex], state, exercises),
      SizedBox(width: AppConfig.spacingS.w),
      Text(
        '${_currentExerciseIndex + 1}/${exercises.length}',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      SizedBox(width: AppConfig.spacingS.w),
      if (_currentExerciseIndex < exercises.length - 1) Icon(Icons.more_horiz, color: Colors.grey, size: 16.sp),
    ];
  }

  // ============================================================================
  // 🔧 HELPER METHODS
  // ============================================================================

  int _calculateCompletedExercises(bloc.WorkoutSessionActive state) {
    return state.exercises.where((exercise) {
      final completedSeries = state.completedSeries[exercise.id] ?? [];
      return completedSeries.length >= exercise.serie;
    }).length;
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
    // 🚀 FIX: Only pop if still mounted and not already processing exit
    if (!mounted) return;

    developer.log('🚪 Handling workout exit...', name: 'ActiveWorkoutScreen');

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

    // Exit immediately - check if we can pop
    try {
      if (mounted && Navigator.of(context).canPop()) {
        context.pop();
      }
    } catch (e) {
      developer.log('⚠️ Could not pop: $e', name: 'ActiveWorkoutScreen');
      // Try alternative exit method
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
                    'Hai completato tutti gli esercizi!',
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