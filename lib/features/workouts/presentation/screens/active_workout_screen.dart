// lib/features/workouts/presentation/screens/active_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_card.dart';
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
  final int? allenamentoId; // Se null, inizia nuovo allenamento

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

  Timer? _workoutTimer;
  Duration _elapsedTime = Duration.zero;

  // Controllers per timer di recupero
  Timer? _recoveryTimer;
  int _recoverySeconds = 0;
  bool _isRecoveryActive = false;
  int? _currentRecoveryExerciseId;

  // Controllers per input serie
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _repsControllers = {};

  // Animazioni
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _bloc = context.read<bloc.ActiveWorkoutBloc>();
    _sessionService = getIt<SessionService>();

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

    _initializeWorkout();
    _startWorkoutTimer();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _recoveryTimer?.cancel();
    _progressAnimationController.dispose();

    // Dispose controllers
    for (final controller in _weightControllers.values) {
      controller.dispose();
    }
    for (final controller in _repsControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _initializeWorkout() async {
    final userId = await _sessionService.getCurrentUserId();
    if (userId != null) {
      if (widget.allenamentoId != null) {
        // Riprende allenamento esistente
        _bloc.add(bloc.LoadCompletedSeries(allenamentoId: widget.allenamentoId!));
      } else {
        // Inizia nuovo allenamento
        _bloc.add(bloc.StartWorkoutSession(userId: userId, schedaId: widget.schedaId));
      }
    }
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);
        });
        // Aggiorna anche il BLoC
        _bloc.add(bloc.UpdateWorkoutTimer(duration: _elapsedTime));
      }
    });
  }

  void _startRecoveryTimer(int exerciseId, {int seconds = 90}) {
    _stopRecoveryTimer();

    setState(() {
      _recoverySeconds = seconds;
      _isRecoveryActive = true;
      _currentRecoveryExerciseId = exerciseId;
    });

    _recoveryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recoverySeconds--;
        });

        if (_recoverySeconds <= 0) {
          _stopRecoveryTimer();
          // Vibrazione + notifica di fine recupero
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
      _currentRecoveryExerciseId = null;
    });
  }

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
        title: const Text('Completa Allenamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sei sicuro di voler completare questo allenamento?'),
            SizedBox(height: AppConfig.spacingM.h),
            Text(
              'Durata: ${Formatters.formatDuration(_elapsedTime)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.indigo600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            child: const Text('Completa'),
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
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Esci'),
          ),
        ],
      ),
    );
  }

  void _completeSeries(WorkoutExercise exercise, int seriesNumber) {
    final weightController = _weightControllers[exercise.id];
    final repsController = _repsControllers[exercise.id];

    if (weightController == null || repsController == null) return;

    final weight = double.tryParse(weightController.text) ?? 0.0;
    final reps = int.tryParse(repsController.text) ?? 0;

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

    // Avvia timer di recupero
    _startRecoveryTimer(exercise.id, seconds: exercise.tempoRecupero ?? 90);

    // Feedback haptico
    HapticFeedback.lightImpact();

    CustomSnackbar.show(
      context,
      message: 'Serie completata! Tempo di recupero: ${exercise.tempoRecupero ?? 90}s',
      isSuccess: true,
    );

    // Pulisce i campi per la prossima serie
    Future.delayed(const Duration(milliseconds: 100), () {
      weightController.clear();
      repsController.clear();
    });
  }

  Widget _buildExerciseCard(
      WorkoutExercise exercise,
      List<models.CompletedSeriesData> completedSeries,
      bool isActive,
      ) {
    // Assicura controllers per questo esercizio
    _weightControllers.putIfAbsent(exercise.id, () => TextEditingController());
    _repsControllers.putIfAbsent(exercise.id, () => TextEditingController());

    final weightController = _weightControllers[exercise.id]!;
    final repsController = _repsControllers[exercise.id]!;

    // Pre-popola con ultima serie se disponibile e campi vuoti
    if (completedSeries.isNotEmpty &&
        weightController.text.isEmpty &&
        repsController.text.isEmpty) {
      final lastSeries = completedSeries.last;
      weightController.text = lastSeries.peso.toString();
      repsController.text = lastSeries.ripetizioni.toString();
    }

    final isCompleted = completedSeries.length >= exercise.serie;
    final nextSeriesNumber = completedSeries.length + 1;
    final isRecovering = _currentRecoveryExerciseId == exercise.id && _isRecoveryActive;

    return CustomCard(
      margin: EdgeInsets.only(bottom: AppConfig.spacingM.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header esercizio
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.nome,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppColors.success : AppColors.textPrimary,
                      ),
                    ),
                    if (exercise.descrizione?.isNotEmpty == true) ...[
                      SizedBox(height: 4.h),
                      Text(
                        exercise.descrizione!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Progress indicator
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppColors.success : AppColors.indigo600,
                ),
                child: Center(
                  child: Text(
                    '${completedSeries.length}/${exercise.serie}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: AppConfig.spacingM.h),

          // Progress bar
          LinearProgressIndicator(
            value: completedSeries.length / exercise.serie,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? AppColors.success : AppColors.indigo600,
            ),
          ),

          if (!isCompleted) ...[
            SizedBox(height: AppConfig.spacingM.h),

            // Input serie corrente
            Container(
              padding: EdgeInsets.all(AppConfig.spacingM.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppConfig.radiusM.r),
                border: Border.all(
                  color: isActive ? AppColors.indigo600 : AppColors.border,
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Serie $nextSeriesNumber',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.indigo600,
                    ),
                  ),

                  SizedBox(height: AppConfig.spacingS.h),

                  Row(
                    children: [
                      // Input peso
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Peso (kg)',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            TextFormField(
                              controller: weightController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '0.0',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: AppConfig.spacingM.w),

                      // Input ripetizioni
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ripetizioni',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            TextFormField(
                              controller: repsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '0',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: AppConfig.spacingM.w),

                      // Pulsante completa serie
                      CustomButton(
                        text: 'Fatto',
                        onPressed: isRecovering ? null : () {
                          _completeSeries(exercise, nextSeriesNumber);
                        },
                        type: ButtonType.primary,
                        size: ButtonSize.small,
                      ),
                    ],
                  ),

                  // Timer di recupero
                  if (isRecovering) ...[
                    SizedBox(height: AppConfig.spacingS.h),
                    Container(
                      padding: EdgeInsets.all(AppConfig.spacingS.w),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConfig.radiusS.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer,
                            color: AppColors.warning,
                            size: 16.sp,
                          ),
                          SizedBox(width: AppConfig.spacingS.w),
                          Text(
                            'Recupero: ${_recoverySeconds}s',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _stopRecoveryTimer,
                            child: const Text('Stop'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Serie completate
          if (completedSeries.isNotEmpty) ...[
            SizedBox(height: AppConfig.spacingM.h),
            Text(
              'Serie completate',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
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
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
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
                        fontSize: 12.sp,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          actions: [
            BlocBuilder<bloc.ActiveWorkoutBloc, bloc.ActiveWorkoutState>(
              builder: (context, state) {
                if (state is bloc.WorkoutSessionActive) {
                  return IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => _completeWorkout(context, state.activeWorkout.id),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<bloc.ActiveWorkoutBloc, bloc.ActiveWorkoutState>(
          listener: (context, state) {
            if (state is bloc.WorkoutSessionCompleted) {
              CustomSnackbar.show(
                context,
                message: 'Allenamento completato con successo!',
                isSuccess: true,
              );
              // Naviga indietro dopo un breve delay
              Future.delayed(const Duration(seconds: 2), () {
                if (context.mounted) {
                  context.pop();
                }
              });
            } else if (state is bloc.ActiveWorkoutError) {
              CustomSnackbar.show(
                context,
                message: state.message,
                isSuccess: false,
              );
            }
          },
          builder: (context, state) {
            return LoadingOverlay(
              isLoading: state is bloc.ActiveWorkoutLoading,
              message: state is bloc.ActiveWorkoutLoading ? state.message : null,
              child: Column(
                children: [
                  // Header con timer e progresso
                  Container(
                    padding: EdgeInsets.all(AppConfig.spacingM.w),
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
                          // Timer principale
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timer,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                              SizedBox(width: AppConfig.spacingS.w),
                              Text(
                                Formatters.formatDuration(_elapsedTime),
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),

                          if (state is bloc.WorkoutSessionActive) ...[
                            SizedBox(height: AppConfig.spacingM.h),
                            // Progress generale
                            _buildWorkoutProgress(state),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Lista esercizi
                  Expanded(
                    child: _buildExercisesList(state),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWorkoutProgress(bloc.WorkoutSessionActive state) {
    final totalExercises = state.exercises.length;
    final completedExercises = state.exercises.where((exercise) {
      final completedSeries = state.completedSeries[exercise.id] ?? [];
      return completedSeries.length >= exercise.serie;
    }).length;

    final progress = totalExercises > 0 ? completedExercises / totalExercises : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso Allenamento',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            Text(
              '$completedExercises/$totalExercises esercizi',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: AppConfig.spacingS.h),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: progress * _progressAnimation.value,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExercisesList(bloc.ActiveWorkoutState state) {
    if (state is bloc.WorkoutSessionActive) {
      _progressAnimationController.forward();

      return ListView.builder(
        padding: EdgeInsets.all(AppConfig.spacingM.w),
        itemCount: state.exercises.length,
        itemBuilder: (context, index) {
          final exercise = state.exercises[index];
          final completedSeries = state.completedSeries[exercise.id] ?? [];

          // Determina se questo esercizio è attivo (primo non completato)
          final isActive = !state.exercises.take(index).every((ex) {
            final completed = state.completedSeries[ex.id] ?? [];
            return completed.length >= ex.serie;
          }) && completedSeries.length < exercise.serie;

          return _buildExerciseCard(exercise, completedSeries, isActive);
        },
      );
    }

    // Stati di errore o iniziali
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state is bloc.ActiveWorkoutError) ...[
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: AppColors.error,
            ),
            SizedBox(height: AppConfig.spacingM.h),
            Text(
              'Errore',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: AppConfig.spacingS.h),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppConfig.spacingL.h),
            CustomButton(
              text: 'Riprova',
              onPressed: _initializeWorkout,
              type: ButtonType.primary,
            ),
          ] else ...[
            Icon(
              Icons.fitness_center,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppConfig.spacingM.h),
            Text(
              'Preparazione allenamento...',
              style: TextStyle(
                fontSize: 18.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}