// lib/features/workouts/presentation/screens/active_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:io';

// Core imports
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/recovery_timer_widget.dart'; // 🚀 STEP 2
import '../../../../core/services/session_service.dart';
import '../../../../core/di/dependency_injection.dart';

// BLoC imports
import '../../bloc/active_workout_bloc.dart';
import '../../models/active_workout_models.dart';
import '../../models/workout_plan_models.dart';

/// 🚀 ActiveWorkoutScreen - VERSIONE BASE FUNZIONANTE
/// ✅ Architettura BLoC (testata e funzionante)
/// ✅ Compatibile API 34 + API 35
/// ✅ UI moderna e responsiva
/// ✅ Gestione stati robusta
/// ❌ NO SystemChrome (causa crash su API 34)
/// ⏳ Prossimo: STEP 2 (Rest Timer) o altri features
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

  // BLoC reference
  late ActiveWorkoutBloc _activeWorkoutBloc;

  // Timer management
  Timer? _workoutTimer;
  Duration _elapsedTime = Duration.zero;
  DateTime? _startTime;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // UI state
  bool _isInitialized = false;
  String _currentStatus = "Inizializzazione...";
  int _currentExerciseIndex = 0;

  // 🚀 STEP 2: Recovery Timer State
  bool _isRecoveryTimerActive = false;
  int _recoverySeconds = 0;
  String? _currentRecoveryExerciseName;

  // User session
  int? _userId;

  @override
  void initState() {
    super.initState();
    debugPrint("🚀 [ACTIVE WORKOUT] initState - Scheda: ${widget.schedaId}");
    _initializeAnimations();
    _initializeWorkout();
  }

  @override
  void dispose() {
    debugPrint("🚀 [ACTIVE WORKOUT] dispose");
    _workoutTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    // 🚀 STEP 2: Stop recovery timer
    _stopRecoveryTimer();
    super.dispose();
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeWorkout() async {
    try {
      setState(() {
        _currentStatus = "Caricamento sessione...";
      });

      // Get user session
      final sessionService = getIt<SessionService>();
      _userId = await sessionService.getCurrentUserId();

      if (_userId == null) {
        throw Exception('Sessione utente non valida');
      }

      setState(() {
        _currentStatus = "Inizializzazione BLoC...";
      });

      // Get BLoC instance
      _activeWorkoutBloc = context.read<ActiveWorkoutBloc>();

      setState(() {
        _currentStatus = "Avvio allenamento...";
      });

      // Start workout
      _activeWorkoutBloc.startWorkout(_userId!, widget.schedaId);

      setState(() {
        _isInitialized = true;
        _currentStatus = "Allenamento avviato";
      });

      _slideController.forward();

    } catch (e) {
      debugPrint("🚀 [ACTIVE WORKOUT] Error initializing: $e");
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
  // 🚀 STEP 2: RECOVERY TIMER MANAGEMENT
  // ============================================================================

  void _startRecoveryTimer(int seconds, String exerciseName) {
    debugPrint("🔄 [RECOVERY] Starting recovery timer: $seconds seconds for $exerciseName");

    setState(() {
      _isRecoveryTimerActive = true;
      _recoverySeconds = seconds;
      _currentRecoveryExerciseName = exerciseName;
    });
  }

  void _stopRecoveryTimer() {
    debugPrint("⏹️ [RECOVERY] Recovery timer stopped");

    setState(() {
      _isRecoveryTimerActive = false;
      _recoverySeconds = 0;
      _currentRecoveryExerciseName = null;
    });
  }

  void _onRecoveryTimerComplete() {
    debugPrint("✅ [RECOVERY] Recovery completed!");

    setState(() {
      _isRecoveryTimerActive = false;
      _recoverySeconds = 0;
      _currentRecoveryExerciseName = null;
    });

    // Mostra feedback positivo
    CustomSnackbar.show(
      context,
      message: "Recupero completato! Pronto per la prossima serie 💪",
      isSuccess: true,
    );
  }

  // ============================================================================
  // TIMER MANAGEMENT
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

        // Update BLoC timer every 10 seconds
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

  // ============================================================================
  // WORKOUT LOGIC
  // ============================================================================

  int _getCompletedSeriesCount(WorkoutSessionActive state, int exerciseId) {
    final series = state.completedSeries[exerciseId] ?? [];
    return series.length;
  }

  int _getCurrentExerciseIndex(WorkoutSessionActive state) {
    // Trova il primo esercizio non completato
    for (int i = 0; i < state.exercises.length; i++) {
      final exercise = state.exercises[i];
      final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
      final completedCount = _getCompletedSeriesCount(state, exerciseId);

      if (completedCount < exercise.serie) {
        return i;
      }
    }

    // Se tutti gli esercizi sono completati, torna all'ultimo
    return state.exercises.length - 1;
  }

  bool _isWorkoutCompleted(WorkoutSessionActive state) {
    for (final exercise in state.exercises) {
      final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
      final completedCount = _getCompletedSeriesCount(state, exerciseId);

      if (completedCount < exercise.serie) {
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

    debugPrint("🚀 [ACTIVE WORKOUT] Completing series ${completedCount + 1} for exercise: ${exercise.nome}");

    // Create series data
    final seriesData = SeriesData(
      schedaEsercizioId: exerciseId,
      peso: exercise.peso,
      ripetizioni: exercise.ripetizioni,
      completata: 1,
      tempoRecupero: exercise.tempoRecupero,
      note: 'Completata da ActiveWorkoutScreen',
      serieNumber: completedCount + 1,
      serieId: 'series_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Add local series for immediate UI feedback
    _activeWorkoutBloc.addLocalSeries(exerciseId, seriesData);

    // Save series to backend
    final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';
    _activeWorkoutBloc.saveSeries(
      state.activeWorkout.id,
      [seriesData],
      requestId,
    );

    // Show success feedback
    CustomSnackbar.show(
      context,
      message: "Serie ${completedCount + 1} completata! 💪",
      isSuccess: true,
    );

    // 🚀 STEP 2: Auto-start recovery timer
    if (exercise.tempoRecupero > 0) {
      _startRecoveryTimer(exercise.tempoRecupero, exercise.nome);
    }

    // Check if workout is completed
    setState(() {
      _currentExerciseIndex = _getCurrentExerciseIndex(state);
    });

    // Auto-complete workout if all exercises are done
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isWorkoutCompleted(state)) {
        _handleCompleteWorkout(state);
      }
    });
  }

  void _handleCompleteWorkout(WorkoutSessionActive state) {
    debugPrint("🚀 [ACTIVE WORKOUT] Completing workout");

    _stopWorkoutTimer();

    final durationMinutes = _elapsedTime.inMinutes;
    _activeWorkoutBloc.completeWorkout(
      state.activeWorkout.id,
      durationMinutes,
      note: 'Completato tramite ActiveWorkoutScreen',
    );
  }

  void _handleCancelWorkout(WorkoutSessionActive state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annulla Allenamento'),
        content: const Text(
          'Sei sicuro di voler annullare questo allenamento?\n\n'
              'Tutti i progressi andranno persi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continua'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _stopWorkoutTimer();
              _activeWorkoutBloc.cancelWorkout(state.activeWorkout.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Annulla Allenamento'),
          ),
        ],
      ),
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

  Color _getTimerColor() {
    final minutes = _elapsedTime.inMinutes;
    if (minutes < 30) return Colors.green;
    if (minutes < 60) return Colors.orange;
    return Colors.red;
  }

  // ============================================================================
  // BUILD METHODS
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildInitializingScreen();
    }

    return BlocListener<ActiveWorkoutBloc, ActiveWorkoutState>(
      bloc: _activeWorkoutBloc,
      listener: _handleBlocStateChanges,
      child: BlocBuilder<ActiveWorkoutBloc, ActiveWorkoutState>(
        bloc: _activeWorkoutBloc,
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: _buildAppBar(state),
            body: _buildBody(state),
            bottomNavigationBar: _buildBottomActions(state),
          );
        },
      ),
    );
  }

  Widget _buildInitializingScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Caricamento...'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(40.r),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 40.sp,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              _currentStatus,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: 200.w,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ActiveWorkoutState state) {
    return AppBar(
      title: Text(
        widget.schedaNome ?? 'Allenamento ${widget.schedaId}',
        style: TextStyle(fontSize: 18.sp),
      ),
      backgroundColor: _getTimerColor(),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (state is WorkoutSessionActive) ...[
          IconButton(
            icon: Icon(Icons.pause, size: 24.sp),
            onPressed: () {
              // TODO: Implement pause functionality
              CustomSnackbar.show(
                context,
                message: "Funzione pausa in sviluppo",
                isSuccess: false,
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.stop, size: 24.sp),
            onPressed: () => _handleCancelWorkout(state),
          ),
        ],
      ],
    );
  }

  Widget _buildBody(ActiveWorkoutState state) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildTimerCard(),
              SizedBox(height: 20.h),
              // 🚀 STEP 2: Recovery Timer Widget
              if (_isRecoveryTimerActive) ...[
                RecoveryTimerWidget(
                  initialSeconds: _recoverySeconds,
                  isActive: _isRecoveryTimerActive,
                  exerciseName: _currentRecoveryExerciseName,
                  onTimerComplete: _onRecoveryTimerComplete,
                  onTimerStopped: _stopRecoveryTimer,
                ),
                SizedBox(height: 20.h),
              ],
              _buildStateContent(state),
              SizedBox(height: 100.h), // Space for bottom actions
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getTimerColor(), _getTimerColor().withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: _getTimerColor().withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.timer,
            color: Colors.white,
            size: 32.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            _formatDuration(_elapsedTime),
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Tempo di allenamento',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateContent(ActiveWorkoutState state) {
    if (state is ActiveWorkoutLoading) {
      return _buildLoadingContent(state);
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

    return _buildDefaultContent(state);
  }

  Widget _buildLoadingContent(ActiveWorkoutLoading state) {
    return Container(
      height: 300.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 3,
            ),
            SizedBox(height: 16.h),
            Text(
              state.message ?? 'Caricamento...',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveContent(WorkoutSessionActive state) {
    if (state.exercises.isEmpty) {
      return _buildNoExercisesContent();
    }

    _currentExerciseIndex = _getCurrentExerciseIndex(state);
    final currentExercise = state.exercises[_currentExerciseIndex];
    final exerciseId = currentExercise.schedaEsercizioId ?? currentExercise.id;
    final completedSeries = _getCompletedSeriesCount(state, exerciseId);
    final isCompleted = completedSeries >= currentExercise.serie;

    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(state),
        SizedBox(height: 20.h),

        // Current exercise card
        _buildExerciseCard(currentExercise, completedSeries, isCompleted),
        SizedBox(height: 20.h),

        // Exercise details
        _buildExerciseDetails(currentExercise),
        SizedBox(height: 20.h),

        // All exercises list
        _buildAllExercisesList(state),
      ],
    );
  }

  Widget _buildProgressIndicator(WorkoutSessionActive state) {
    final totalExercises = state.exercises.length;
    var completedExercises = 0;

    for (final exercise in state.exercises) {
      final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
      final completedSeries = _getCompletedSeriesCount(state, exerciseId);
      if (completedSeries >= exercise.serie) {
        completedExercises++;
      }
    }

    final progress = totalExercises > 0 ? completedExercises / totalExercises : 0.0;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso Allenamento',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '$completedExercises/$totalExercises',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8.h,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExercise exercise, int completedSeries, bool isCompleted) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isCompleted ? Colors.green : Colors.blue,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? Colors.green : Colors.blue).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Exercise name
          Text(
            exercise.nome,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),

          if (exercise.gruppoMuscolare != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                exercise.gruppoMuscolare!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],

          SizedBox(height: 16.h),

          // Series progress
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.fitness_center,
                color: isCompleted ? Colors.green : Colors.blue,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Serie: $completedSeries / ${exercise.serie}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.green : Colors.blue,
                ),
              ),
            ],
          ),

          if (isCompleted) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '✅ Esercizio Completato!',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseDetails(WorkoutExercise exercise) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dettagli Esercizio',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Ripetizioni',
                  '${exercise.ripetizioni}',
                  Icons.repeat,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildDetailItem(
                  'Peso',
                  '${exercise.peso.toStringAsFixed(1)} kg',
                  Icons.fitness_center,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Recupero',
                  '${exercise.tempoRecupero}s',
                  Icons.timer,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildDetailItem(
                  'Attrezzatura',
                  exercise.attrezzatura ?? 'N/A',
                  Icons.hardware,
                ),
              ),
            ],
          ),

          if (exercise.note != null && exercise.note!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'Note: ${exercise.note}',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 20.sp),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllExercisesList(WorkoutSessionActive state) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tutti gli Esercizi (${state.exercises.length})',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12.h),

          ...state.exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
            final completedSeries = _getCompletedSeriesCount(state, exerciseId);
            final isCompleted = completedSeries >= exercise.serie;
            final isCurrent = index == _currentExerciseIndex;

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isCurrent ? Colors.blue.withOpacity(0.1) : Colors.grey[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isCurrent ? Colors.blue : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : (isCurrent ? Colors.blue : Colors.grey[300]),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.fitness_center,
                      color: Colors.white,
                      size: 14.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.nome,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          '$completedSeries/${exercise.serie} serie',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isCurrent)
                    Icon(
                      Icons.play_arrow,
                      color: Colors.blue,
                      size: 20.sp,
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNoExercisesContent() {
    return Container(
      height: 300.h,
      child: Center(
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
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Questa scheda non contiene esercizi.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Torna Indietro'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedContent(WorkoutSessionCompleted state) {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
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
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Text(
                  'Tempo Totale',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _formatDuration(state.totalDuration),
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Ottimo lavoro! 💪\nIl tuo allenamento è stato salvato.',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(ActiveWorkoutError state) {
    return Container(
      height: 300.h,
      child: Center(
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                state.message,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('Indietro'),
                ),
                SizedBox(width: 16.w),
                ElevatedButton(
                  onPressed: () {
                    _activeWorkoutBloc.resetState();
                    _initializeWorkout();
                  },
                  child: const Text('Riprova'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultContent(ActiveWorkoutState state) {
    return Container(
      height: 300.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16.h),
            Text(
              'Stato: ${state.runtimeType.toString()}',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildBottomActions(ActiveWorkoutState state) {
    if (state is! WorkoutSessionActive) return null;

    final currentExercise = state.exercises.isNotEmpty
        ? state.exercises[_currentExerciseIndex]
        : null;

    if (currentExercise == null) return null;

    final exerciseId = currentExercise.schedaEsercizioId ?? currentExercise.id;
    final completedSeries = _getCompletedSeriesCount(state, exerciseId);
    final isCompleted = completedSeries >= currentExercise.serie;
    final isWorkoutCompleted = _isWorkoutCompleted(state);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isWorkoutCompleted) ...[
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: isCompleted ? null : () => _handleCompleteSeries(state, currentExercise),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? Colors.green : Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    isCompleted
                        ? '✅ Esercizio Completato'
                        : '💪 Completa Serie ${completedSeries + 1}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () => _handleCompleteWorkout(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    '🎉 Completa Allenamento',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // BLOC LISTENER
  // ============================================================================

  void _handleBlocStateChanges(BuildContext context, ActiveWorkoutState state) {
    if (state is WorkoutSessionStarted) {
      debugPrint("🚀 [ACTIVE WORKOUT] Workout session started - ID: ${state.response.allenamentoId}");
      _startWorkoutTimer();

      CustomSnackbar.show(
        context,
        message: "Allenamento avviato con successo! 💪",
        isSuccess: true,
      );
    }

    if (state is WorkoutSessionActive) {
      debugPrint("🚀 [ACTIVE WORKOUT] Active session with ${state.exercises.length} exercises");

      if (_workoutTimer == null) {
        _startWorkoutTimer();
      }
    }

    if (state is WorkoutSessionCompleted) {
      debugPrint("🚀 [ACTIVE WORKOUT] Workout completed");
      _stopWorkoutTimer();
      // 🚀 STEP 2: Stop recovery timer on completion
      _stopRecoveryTimer();

      // Show completion dialog
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('🎉 Congratulazioni!'),
              content: Text(
                'Allenamento completato con successo!\n\n'
                    '⏱️ Tempo totale: ${_formatDuration(state.totalDuration)}\n'
                    '💪 Ottimo lavoro!',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to previous screen
                  },
                  child: const Text('Termina'),
                ),
              ],
            ),
          );
        }
      });
    }

    if (state is WorkoutSessionCancelled) {
      debugPrint("🚀 [ACTIVE WORKOUT] Workout cancelled");
      _stopWorkoutTimer();
      // 🚀 STEP 2: Stop recovery timer on cancellation
      _stopRecoveryTimer();

      CustomSnackbar.show(
        context,
        message: "Allenamento annullato",
        isSuccess: false,
      );

      Navigator.of(context).pop();
    }

    if (state is ActiveWorkoutError) {
      debugPrint("🚀 [ACTIVE WORKOUT] Error: ${state.message}");

      CustomSnackbar.show(
        context,
        message: "Errore: ${state.message}",
        isSuccess: false,
      );
    }
  }
}