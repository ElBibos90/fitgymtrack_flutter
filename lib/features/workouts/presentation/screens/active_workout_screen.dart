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

  // 🎮 STATO FULLSCREEN
  int _currentExerciseIndex = 0;
  late PageController _pageController;

  // ⏱️ TIMER SISTEMA
  Timer? _workoutTimer;
  Timer? _recoveryTimer;
  Duration _elapsedTime = Duration.zero;
  int _recoverySeconds = 0;
  bool _isRecoveryActive = false;

  // 💾 DATI ALLENAMENTO
  Map<int, double> _exerciseWeights = {};
  Map<int, int> _exerciseReps = {};

  // 🎨 ANIMAZIONI
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    print('🚨 ACTIVE WORKOUT SCREEN INIT STARTED'); // <-- AGGIUNGI QUESTA RIGA
    developer.log('🎬 ActiveWorkoutScreen initState CALLED!', name: 'ActiveWorkoutScreen');

    _bloc = context.read<bloc.ActiveWorkoutBloc>();
    _sessionService = getIt<SessionService>();
    _pageController = PageController(initialPage: 0);

    developer.log('🔗 BLoC obtained: ${_bloc.runtimeType}', name: 'ActiveWorkoutScreen');
    developer.log('🔗 SessionService obtained: ${_sessionService.runtimeType}', name: 'ActiveWorkoutScreen');

    // Animazioni
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

    developer.log('🎨 Animations initialized', name: 'ActiveWorkoutScreen');

    _initializeWorkout();
    _startWorkoutTimer();

    developer.log('✅ InitState completed', name: 'ActiveWorkoutScreen');
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _recoveryTimer?.cancel();
    _progressAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // 🚀 FIX: Metodo migliorato con gestione errori e reset
  Future<void> _initializeWorkout() async {
    developer.log('🚀 Initializing workout...', name: 'ActiveWorkoutScreen');

    final userId = await _sessionService.getCurrentUserId();
    developer.log('👤 Current user ID: $userId', name: 'ActiveWorkoutScreen');

    if (userId != null) {
      if (widget.allenamentoId != null) {
        developer.log('🔄 Loading existing workout: ${widget.allenamentoId}', name: 'ActiveWorkoutScreen');
        _bloc.add(bloc.LoadCompletedSeries(allenamentoId: widget.allenamentoId!));
      } else {
        developer.log('🆕 Starting new workout session - User: $userId, Scheda: ${widget.schedaId}', name: 'ActiveWorkoutScreen');

        // 🚀 FIX: Resetta lo stato prima di iniziare
        _bloc.add(const bloc.ResetActiveWorkoutState());

        // Piccolo delay per assicurare che il reset sia processato
        await Future.delayed(const Duration(milliseconds: 100));

        // Ora inizia il workout
        _bloc.add(bloc.StartWorkoutSession(userId: userId, schedaId: widget.schedaId));
      }
    } else {
      developer.log('❌ No user ID found!', name: 'ActiveWorkoutScreen');
      // Mostra errore o vai al login
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

  /// Inizializza i valori predefiniti per peso e ripetizioni
  void _initializeDefaultValues(List<WorkoutExercise> exercises) {
    for (final exercise in exercises) {
      // Usa i valori dell'esercizio come default se non già impostati
      if (!_exerciseWeights.containsKey(exercise.id)) {
        _exerciseWeights[exercise.id] = exercise.peso;
      }
      if (!_exerciseReps.containsKey(exercise.id)) {
        _exerciseReps[exercise.id] = exercise.ripetizioni;
      }
    }
  }

  /// Pre-popola con dati dall'ultimo allenamento (se disponibili)
  void _preloadFromCompletedSeries(Map<int, List<models.CompletedSeriesData>> completedSeries) {
    for (final entry in completedSeries.entries) {
      final exerciseId = entry.key;
      final series = entry.value;

      if (series.isNotEmpty) {
        // Usa i valori dell'ultima serie completata
        final lastSeries = series.last;
        _exerciseWeights[exerciseId] = lastSeries.peso;
        _exerciseReps[exerciseId] = lastSeries.ripetizioni;
      }
    }
  }

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
          HapticFeedback.mediumImpact();
          if (mounted) {
            CustomSnackbar.show(
              context,
              message: 'Tempo di recupero terminato!',
              isSuccess: true,
            );
          }
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

  // 🎯 NAVIGATION BETWEEN EXERCISES
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

  // 💪 EXERCISE INPUT HANDLERS
  Future<void> _showWeightPicker(int exerciseId, double currentWeight) async {
    final weight = await showDialog<double>(
      context: context,
      builder: (context) => WeightPickerDialog(initialWeight: currentWeight),
    );

    if (weight != null) {
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

    if (reps != null) {
      setState(() {
        _exerciseReps[exerciseId] = reps;
      });
    }
  }

  // 🏋️ COMPLETE SERIES
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

    // Crea SeriesData
    final seriesData = models.SeriesData(
      schedaEsercizioId: exercise.id,
      peso: weight,
      ripetizioni: reps,
      serieNumber: seriesNumber,
      serieId: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    // Aggiunge serie locale per feedback immediato
    _bloc.add(bloc.AddLocalSeries(exerciseId: exercise.id, seriesData: seriesData));

    // Salva nel database (se abbiamo un allenamento attivo)
    final currentState = _bloc.state;
    if (currentState is bloc.WorkoutSessionActive) {
      final requestId = 'save_${DateTime.now().millisecondsSinceEpoch}';
      _bloc.add(bloc.SaveCompletedSeries(
        allenamentoId: currentState.activeWorkout.id,
        serie: [seriesData],
        requestId: requestId,
      ));
    }

    // Avvia timer di recupero
    _startRecoveryTimer(seconds: exercise.tempoRecupero ?? 90);

    // Feedback
    HapticFeedback.lightImpact();
    CustomSnackbar.show(
      context,
      message: 'Serie completata!',
      isSuccess: true,
    );
  }

  // 🏁 COMPLETE WORKOUT
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

  Future<bool?> _showCompleteWorkoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Completa Allenamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Fantastico! Sei sicuro di voler completare questo allenamento?'),
            SizedBox(height: AppConfig.spacingM.h),
            Text(
              'Durata: ${Formatters.formatDuration(_elapsedTime)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.indigo600,
                fontSize: 16.sp,
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
            child: const Text('🏁 Completa!'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esci dall\'Allenamento'),
        content: const Text(
          'Sei sicuro di voler uscire? I progressi non salvati andranno persi.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Continua'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Esci'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldExit = await _showExitDialog(context);
          if (shouldExit == true && context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Allenamento Attivo',
          showBackButton: false,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldExit = await _showExitDialog(context);
              if (shouldExit == true && context.mounted) {
                context.pop();
              }
            },
          ),
        ),
        // 🚀 FIX: BlocConsumer migliorato con buildWhen
        body: BlocConsumer<bloc.ActiveWorkoutBloc, bloc.ActiveWorkoutState>(
          listener: (context, state) {
            developer.log('🔄 State changed: ${state.runtimeType}', name: 'ActiveWorkoutScreen');

            if (state is bloc.WorkoutSessionActive) {
              developer.log('✅ Workout session is active with ${state.exercises.length} exercises', name: 'ActiveWorkoutScreen');
              // Inizializza valori predefiniti quando i dati sono caricati
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _initializeDefaultValues(state.exercises);
                  _preloadFromCompletedSeries(state.completedSeries);
                }
              });
            } else if (state is bloc.WorkoutSessionStarted) {
              developer.log('🎯 Workout session started: ${state.response.allenamentoId}', name: 'ActiveWorkoutScreen');
              // Non fare nulla qui, gli esercizi verranno caricati automaticamente dal BLoC
            } else if (state is bloc.WorkoutSessionCompleted) {
              developer.log('🏁 Workout completed!', name: 'ActiveWorkoutScreen');
              CustomSnackbar.show(
                context,
                message: 'Allenamento completato con successo!',
                isSuccess: true,
              );
              Future.delayed(const Duration(seconds: 2), () {
                if (context.mounted) context.pop();
              });
            } else if (state is bloc.ActiveWorkoutError) {
              developer.log('❌ Active workout error: ${state.message}', name: 'ActiveWorkoutScreen');
              CustomSnackbar.show(
                context,
                message: state.message,
                isSuccess: false,
              );
            } else if (state is bloc.ActiveWorkoutLoading) {
              developer.log('⏳ Loading: ${state.message ?? "no message"}', name: 'ActiveWorkoutScreen');
            }
          },
          buildWhen: (previous, current) {
            // Rebuild solo per stati che influenzano la UI
            return current is! bloc.ActiveWorkoutLoading ||
                previous.runtimeType != current.runtimeType;
          },
          builder: (context, state) {
            developer.log('🎨 Building UI for state: ${state.runtimeType}', name: 'ActiveWorkoutScreen');

            return LoadingOverlay(
              isLoading: state is bloc.ActiveWorkoutLoading,
              message: state is bloc.ActiveWorkoutLoading ? state.message : null,
              child: _buildFullscreenContent(state, isSmallScreen),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFullscreenContent(bloc.ActiveWorkoutState state, bool isSmallScreen) {
    if (state is bloc.WorkoutSessionActive) {
      final exercises = state.exercises;
      if (exercises.isEmpty) {
        return _buildEmptyState();
      }

      _progressAnimationController.forward();

      return Column(
        children: [
          // 📊 HEADER FISSO
          _buildHeader(state, isSmallScreen),

          // 🎮 CONTENT AREA (UN ESERCIZIO)
          Expanded(
            child: _buildExercisePageView(state, isSmallScreen),
          ),

          // 🧭 NAVIGATION FISSO
          _buildNavigationBar(exercises, isSmallScreen, state),
        ],
      );
    }

    return _buildLoadingOrErrorState(state);
  }

  Widget _buildHeader(bloc.WorkoutSessionActive state, bool isSmallScreen) {
    final exercises = state.exercises;
    final totalExercises = exercises.length;
    final completedExercises = exercises.where((exercise) {
      final completedSeries = state.completedSeries[exercise.id] ?? [];
      return completedSeries.length >= exercise.serie;
    }).length;

    final progress = totalExercises > 0 ? completedExercises / totalExercises : 0.0;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? AppConfig.spacingM.w : AppConfig.spacingL.w),
      decoration: BoxDecoration(
        color: AppColors.indigo600,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: AppConfig.elevationS,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Progress text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Esercizio ${_currentExerciseIndex + 1} di $totalExercises',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16.sp : 18.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  Formatters.formatDuration(_elapsedTime),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18.sp : 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConfig.spacingS.h),

            // Progress bar
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: progress * _progressAnimation.value,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6.h,
                );
              },
            ),

            if (completedExercises == totalExercises) ...[
              SizedBox(height: AppConfig.spacingS.h),
              ElevatedButton.icon(
                onPressed: () => _completeWorkout(context, state.activeWorkout.id),
                icon: const Icon(Icons.celebration),
                label: const Text('🏁 Completa Allenamento!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConfig.spacingL.w,
                    vertical: AppConfig.spacingS.h,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExercisePageView(bloc.WorkoutSessionActive state, bool isSmallScreen) {
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

        return _buildExerciseContent(exercise, completedSeries, isSmallScreen);
      },
    );
  }

  Widget _buildExerciseContent(WorkoutExercise exercise, List<models.CompletedSeriesData> completedSeries, bool isSmallScreen) {
    final currentWeight = _exerciseWeights[exercise.id] ?? exercise.peso;
    final currentReps = _exerciseReps[exercise.id] ?? exercise.ripetizioni;
    final isCompleted = completedSeries.length >= exercise.serie;
    final nextSeriesNumber = completedSeries.length + 1;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? AppConfig.spacingM.w : AppConfig.spacingL.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏋️ EXERCISE INFO
          _buildExerciseInfo(exercise, completedSeries, isCompleted, isSmallScreen),

          SizedBox(height: AppConfig.spacingL.h),

          // 💪 INPUT CONTROLS (se non completato)
          if (!isCompleted) ...[
            _buildInputControls(exercise, currentWeight, currentReps, nextSeriesNumber, isSmallScreen),
            SizedBox(height: AppConfig.spacingL.h),
          ],

          // ⏱️ RECOVERY TIMER
          if (_isRecoveryActive) ...[
            _buildRecoveryTimer(isSmallScreen),
            SizedBox(height: AppConfig.spacingL.h),
          ],

          // ✅ COMPLETED SERIES
          if (completedSeries.isNotEmpty) ...[
            _buildCompletedSeries(completedSeries, isSmallScreen),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseInfo(WorkoutExercise exercise, List<models.CompletedSeriesData> completedSeries, bool isCompleted, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConfig.spacingL.w),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.success.withOpacity(0.1) : AppColors.indigo600.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.radiusL.r),
        border: Border.all(
          color: isCompleted ? AppColors.success : AppColors.indigo600,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.nome,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20.sp : 24.sp,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? AppColors.success : AppColors.indigo600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.success : AppColors.indigo600,
                  borderRadius: BorderRadius.circular(AppConfig.radiusL.r),
                ),
                child: Text(
                  '${completedSeries.length}/${exercise.serie}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          if (exercise.descrizione?.isNotEmpty == true) ...[
            SizedBox(height: AppConfig.spacingS.h),
            Text(
              exercise.descrizione!,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],

          SizedBox(height: AppConfig.spacingM.h),

          // Progress bar
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

  Widget _buildInputControls(WorkoutExercise exercise, double currentWeight, int currentReps, int nextSeriesNumber, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(AppConfig.spacingL.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConfig.radiusL.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Serie $nextSeriesNumber',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.indigo600,
            ),
          ),

          SizedBox(height: AppConfig.spacingM.h),

          // Input controls
          if (isSmallScreen)
            _buildCompactInputControls(exercise, currentWeight, currentReps, nextSeriesNumber)
          else
            _buildExpandedInputControls(exercise, currentWeight, currentReps, nextSeriesNumber),
        ],
      ),
    );
  }

  Widget _buildCompactInputControls(WorkoutExercise exercise, double currentWeight, int currentReps, int nextSeriesNumber) {
    return Row(
      children: [
        // Weight
        Expanded(
          child: _buildValueCard(
            label: 'Peso',
            value: '${Formatters.formatWeight(currentWeight)}',
            icon: Icons.fitness_center,
            onTap: () => _showWeightPicker(exercise.id, currentWeight),
          ),
        ),
        SizedBox(width: AppConfig.spacingS.w),

        // Reps
        Expanded(
          child: _buildValueCard(
            label: 'Reps',
            value: '$currentReps',
            icon: Icons.repeat,
            onTap: () => _showRepsPicker(exercise.id, currentReps),
          ),
        ),
        SizedBox(width: AppConfig.spacingS.w),

        // Complete button
        CustomButton(
          text: 'Fatto',
          onPressed: _isRecoveryActive ? null : () => _completeSeries(exercise, nextSeriesNumber),
          type: ButtonType.primary,
          size: ButtonSize.small,
        ),
      ],
    );
  }

  Widget _buildExpandedInputControls(WorkoutExercise exercise, double currentWeight, int currentReps, int nextSeriesNumber) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildValueCard(
                label: 'Peso (kg)',
                value: Formatters.formatWeight(currentWeight),
                icon: Icons.fitness_center,
                onTap: () => _showWeightPicker(exercise.id, currentWeight),
                isExpanded: true,
              ),
            ),
            SizedBox(width: AppConfig.spacingM.w),
            Expanded(
              child: _buildValueCard(
                label: 'Ripetizioni',
                value: '$currentReps',
                icon: Icons.repeat,
                onTap: () => _showRepsPicker(exercise.id, currentReps),
                isExpanded: true,
              ),
            ),
          ],
        ),

        SizedBox(height: AppConfig.spacingL.h),

        CustomButton(
          text: 'Completa Serie $nextSeriesNumber',
          onPressed: _isRecoveryActive ? null : () => _completeSeries(exercise, nextSeriesNumber),
          type: ButtonType.primary,
          isFullWidth: true,
          icon: const Icon(Icons.check),
        ),
      ],
    );
  }

  Widget _buildValueCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    bool isExpanded = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConfig.radiusM.r),
      child: Container(
        padding: EdgeInsets.all(isExpanded ? AppConfig.spacingM.w : AppConfig.spacingS.w),
        decoration: BoxDecoration(
          color: AppColors.indigo600.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConfig.radiusM.r),
          border: Border.all(color: AppColors.indigo600.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.indigo600,
              size: isExpanded ? 24.sp : 20.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: isExpanded ? 12.sp : 10.sp,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isExpanded ? 16.sp : 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.indigo600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryTimer(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConfig.spacingL.w),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.radiusL.r),
        border: Border.all(color: AppColors.warning),
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
                'Tempo di Recupero',
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
              fontSize: isSmallScreen ? 32.sp : 48.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),

          SizedBox(height: AppConfig.spacingM.h),

          LinearProgressIndicator(
            value: 1 - (_recoverySeconds / 90), // Assumendo 90s default
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
            minHeight: 6.h,
          ),

          SizedBox(height: AppConfig.spacingM.h),

          TextButton(
            onPressed: _stopRecoveryTimer,
            child: const Text('Salta Recupero'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedSeries(List<models.CompletedSeriesData> completedSeries, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConfig.spacingM.w),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.radiusL.r),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Serie Completate',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),

          SizedBox(height: AppConfig.spacingS.h),

          ...completedSeries.asMap().entries.map((entry) {
            final index = entry.key;
            final series = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: 4.h),
              padding: EdgeInsets.symmetric(
                horizontal: AppConfig.spacingS.w,
                vertical: 6.h,
              ),
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
                    'Serie ${index + 1}: ${Formatters.formatWeight(series.peso)} × ${series.ripetizioni}',
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
        ],
      ),
    );
  }

  Widget _buildNavigationBar(List<WorkoutExercise> exercises, bool isSmallScreen, bloc.WorkoutSessionActive state) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? AppConfig.spacingM.w : AppConfig.spacingL.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: isSmallScreen
            ? _buildMiniNavigation(exercises, state)
            : _buildFullNavigation(exercises, state),
      ),
    );
  }

  Widget _buildMiniNavigation(List<WorkoutExercise> exercises, bloc.WorkoutSessionActive state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _currentExerciseIndex > 0
              ? () => _navigatePrevious(exercises)
              : null,
          icon: const Icon(Icons.arrow_back),
        ),

        // Progress dots
        Row(
          children: exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            final completedSeries = state.completedSeries[exercise.id] ?? [];
            final isCompleted = completedSeries.length >= exercise.serie;
            final isCurrent = index == _currentExerciseIndex;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : isCurrent
                    ? AppColors.indigo600
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            );
          }).toList(),
        ),

        IconButton(
          onPressed: _currentExerciseIndex < exercises.length - 1
              ? () => _navigateNext(exercises)
              : null,
          icon: const Icon(Icons.arrow_forward),
        ),
      ],
    );
  }

  Widget _buildFullNavigation(List<WorkoutExercise> exercises, bloc.WorkoutSessionActive state) {
    return Row(
      children: [
        CustomButton(
          text: 'Precedente',
          onPressed: _currentExerciseIndex > 0
              ? () => _navigatePrevious(exercises)
              : null,
          type: ButtonType.outline,
          icon: const Icon(Icons.arrow_back),
        ),

        Expanded(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              final completedSeries = state.completedSeries[exercise.id] ?? [];
              final isCompleted = completedSeries.length >= exercise.serie;
              final isCurrent = index == _currentExerciseIndex;

              return GestureDetector(
                onTap: () => _navigateToExercise(index, exercises),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success
                        : isCurrent
                        ? AppColors.indigo600
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        CustomButton(
          text: 'Successivo',
          onPressed: _currentExerciseIndex < exercises.length - 1
              ? () => _navigateNext(exercises)
              : null,
          type: ButtonType.outline,
          icon: const Icon(Icons.arrow_forward),
        ),
      ],
    );
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
}

// 🎛️ WEIGHT PICKER DIALOG
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWeightButton('-5', () => _adjustWeight(-5)),
              _buildWeightButton('-1', () => _adjustWeight(-1)),
              _buildWeightButton('-0.5', () => _adjustWeight(-0.5)),
              _buildWeightButton('+0.5', () => _adjustWeight(0.5)),
              _buildWeightButton('+1', () => _adjustWeight(1)),
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
        minimumSize: Size(40.w, 40.h),
        padding: EdgeInsets.zero,
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

// 🔢 REPS PICKER DIALOG
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

          SizedBox(height: AppConfig.spacingM.h),

          // Common values
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
            children: [5, 8, 10, 12, 15, 20].map((reps) {
              return ElevatedButton(
                onPressed: () => setState(() => _selectedReps = reps),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedReps == reps
                      ? AppColors.indigo600
                      : Colors.grey.shade200,
                  foregroundColor: _selectedReps == reps
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