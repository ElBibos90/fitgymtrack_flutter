// lib/features/workouts/presentation/screens/active_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

// Core imports
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/recovery_timer_popup.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/di/dependency_injection.dart';

// BLoC imports
import '../../bloc/active_workout_bloc.dart';
import '../../models/active_workout_models.dart';
import '../../models/workout_plan_models.dart';

/// 🚀 ActiveWorkoutScreen - SINGLE EXERCISE FOCUSED WITH SUPERSET/CIRCUIT GROUPING
/// ✅ Una schermata per esercizio/gruppo - Design pulito e minimale
/// ✅ Raggruppamento automatico superset/circuit
/// ✅ Recovery timer come popup non invasivo
/// ✅ Navigazione tra gruppi logici
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
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // 🚀 STEP 4: Exercise grouping for superset/circuit
  List<List<WorkoutExercise>> _exerciseGroups = [];
  int _currentGroupIndex = 0;
  int _currentExerciseInGroup = 0; // Track which exercise in the current group
  PageController _pageController = PageController();

  // Recovery timer popup state
  bool _isRecoveryTimerActive = false;
  int _recoverySeconds = 0;
  String? _currentRecoveryExerciseName;

  // UI state
  bool _isInitialized = false;
  String _currentStatus = "Inizializzazione...";
  int? _userId;

  @override
  void initState() {
    super.initState();
    debugPrint("🚀 [SINGLE EXERCISE] initState - Scheda: ${widget.schedaId}");
    _initializeAnimations();
    _initializeWorkout();
  }

  @override
  void dispose() {
    debugPrint("🚀 [SINGLE EXERCISE] dispose");
    _workoutTimer?.cancel();
    _slideController.dispose();
    _pulseController.dispose();
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
      debugPrint("🚀 [SINGLE EXERCISE] Error initializing: $e");
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
  // 🚀 STEP 4: EXERCISE GROUPING FOR SUPERSET/CIRCUIT
  // ============================================================================

  /// Raggruppa gli esercizi in base al campo linked_to_previous
  List<List<WorkoutExercise>> _groupExercises(List<WorkoutExercise> exercises) {
    List<List<WorkoutExercise>> groups = [];
    List<WorkoutExercise> currentGroup = [];

    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];

      // Nuovo gruppo se linked_to_previous = 0 (non collegato al precedente)
      if (exercise.linkedToPreviousInt == 0) {
        // Salva il gruppo precedente se non vuoto
        if (currentGroup.isNotEmpty) {
          groups.add(List.from(currentGroup));
          currentGroup.clear();
        }
        currentGroup.add(exercise);
      } else {
        // Esercizio collegato al precedente - aggiunge al gruppo corrente
        currentGroup.add(exercise);
      }
    }

    // Aggiungi l'ultimo gruppo
    if (currentGroup.isNotEmpty) {
      groups.add(currentGroup);
    }

    debugPrint("🚀 [GROUPING] Created ${groups.length} exercise groups:");
    for (int i = 0; i < groups.length; i++) {
      debugPrint("  Group $i: ${groups[i].map((e) => e.nome).join(', ')}");
    }

    return groups;
  }

  /// Determina se un gruppo è completato (tutti gli esercizi del gruppo)
  bool _isGroupCompleted(WorkoutSessionActive state, List<WorkoutExercise> group) {
    for (final exercise in group) {
      if (!_isExerciseCompleted(state, exercise)) {
        return false;
      }
    }
    return true;
  }

  /// Trova il prossimo esercizio incompleto nel gruppo corrente
  WorkoutExercise? _getNextIncompleteExerciseInGroup(WorkoutSessionActive state, List<WorkoutExercise> group) {
    for (final exercise in group) {
      if (!_isExerciseCompleted(state, exercise)) {
        return exercise;
      }
    }
    return null; // Tutti completati
  }

  // ============================================================================
  // NAVIGATION METHODS
  // ============================================================================

  void _goToPreviousGroup() {
    if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        // Set to first incomplete exercise in the new group
        if (_currentGroupIndex < _exerciseGroups.length) {
          final newGroup = _exerciseGroups[_currentGroupIndex];
          _currentExerciseInGroup = _findNextExerciseInRotation(_getCurrentState(), newGroup);
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
        // Set to first incomplete exercise in the new group
        if (_currentGroupIndex < _exerciseGroups.length) {
          final newGroup = _exerciseGroups[_currentGroupIndex];
          _currentExerciseInGroup = _findNextExerciseInRotation(_getCurrentState(), newGroup);
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

    // Create series data
    final seriesData = SeriesData(
      schedaEsercizioId: exerciseId,
      peso: exercise.peso,
      ripetizioni: exercise.ripetizioni,
      completata: 1,
      tempoRecupero: exercise.tempoRecupero,
      note: 'Completata da Single Exercise Screen',
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

    // Start recovery timer
    if (exercise.tempoRecupero > 0) {
      _startRecoveryTimer(exercise.tempoRecupero, exercise.nome);
    }

    // 🚀 STEP 4: Handle auto-rotation for superset/circuit
    _handleAutoRotation(state);

    // Check if workout is completed
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isWorkoutCompleted(state)) {
        _handleCompleteWorkout(state);
      }
    });
  }

  /// 🚀 STEP 4: Handle automatic rotation between exercises in superset/circuit
  void _handleAutoRotation(WorkoutSessionActive state) {
    if (_currentGroupIndex >= _exerciseGroups.length) return;

    final currentGroup = _exerciseGroups[_currentGroupIndex];
    if (currentGroup.length <= 1) return; // No rotation needed for single exercises

    // Find next exercise in rotation
    final nextExerciseIndex = _findNextExerciseInRotation(state, currentGroup);

    if (nextExerciseIndex != _currentExerciseInGroup) {
      // Auto-switch to next exercise in 1 second
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _currentExerciseInGroup = nextExerciseIndex;
          });

          final nextExercise = currentGroup[_currentExerciseInGroup];
          CustomSnackbar.show(
            context,
            message: "🔄 Prossimo: ${nextExercise.nome}",
            isSuccess: true,
          );
        }
      });
    }
  }

  /// Find next exercise in rotation (first incomplete, or first if all completed at same level)
  int _findNextExerciseInRotation(WorkoutSessionActive? state, List<WorkoutExercise> group) {
    if (state == null) return 0;

    // Find the exercise with minimum completed series (round-robin style)
    int minCompletedSeries = 999;
    int nextIndex = 0;

    for (int i = 0; i < group.length; i++) {
      final exercise = group[i];
      final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
      final completedCount = _getCompletedSeriesCount(state, exerciseId);

      if (completedCount < minCompletedSeries && completedCount < exercise.serie) {
        minCompletedSeries = completedCount;
        nextIndex = i;
      }
    }

    return nextIndex;
  }

  WorkoutSessionActive? _getCurrentState() {
    final currentState = context.read<ActiveWorkoutBloc>().state;
    return currentState is WorkoutSessionActive ? currentState : null;
  }

  void _handleCompleteWorkout(WorkoutSessionActive state) {
    debugPrint("🚀 [SINGLE EXERCISE] Completing workout");

    _stopWorkoutTimer();

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
    if (exercise.setType == "superset") {
      return Colors.purple;
    } else if (exercise.setType == "circuit") {
      return Colors.orange;
    }
    return Colors.blue;
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
          );
        },
      ),
    );
  }

  Widget _buildInitializingScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Caricamento...'),
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
        'Allenamento',
        style: TextStyle(fontSize: 18.sp),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
      actions: [
        // Workout Timer
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          margin: EdgeInsets.only(right: 16.w),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            _formatDuration(_elapsedTime),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        // Menu
        IconButton(
          icon: Icon(Icons.more_vert, size: 24.sp),
          onPressed: () {
            // TODO: Show menu
          },
        ),
      ],
    );
  }

  Widget _buildBody(ActiveWorkoutState state) {
    return Stack(
      children: [
        // Main content
        _buildMainContent(state),

        // Recovery Timer Popup Overlay
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.blue,
            strokeWidth: 3,
          ),
          SizedBox(height: 16.h),
          Text(
            'Caricamento allenamento...',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
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

    // 🚀 STEP 4: Group exercises if not already grouped
    if (_exerciseGroups.isEmpty) {
      _exerciseGroups = _groupExercises(state.exercises);
      if (_currentGroupIndex >= _exerciseGroups.length) {
        _currentGroupIndex = 0;
      }
      // Initialize to first incomplete exercise in the current group
      if (_exerciseGroups.isNotEmpty && _currentGroupIndex < _exerciseGroups.length) {
        final currentGroup = _exerciseGroups[_currentGroupIndex];
        _currentExerciseInGroup = _findNextExerciseInRotation(_getCurrentState(), currentGroup);
      }
    }

    return Column(
      children: [
        // Exercise Groups PageView
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentGroupIndex = index;
                // Set to first incomplete exercise in the new group
                if (index < _exerciseGroups.length) {
                  final newGroup = _exerciseGroups[index];
                  _currentExerciseInGroup = _findNextExerciseInRotation(_getCurrentState(), newGroup);
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

        // Bottom Navigation
        _buildBottomNavigation(state),
      ],
    );
  }

  /// 🚀 STEP 4: Build page for a group of exercises (single, superset, or circuit)
  Widget _buildGroupPage(WorkoutSessionActive state, List<WorkoutExercise> group, int groupIndex) {
    if (group.length == 1) {
      // Single exercise (normal)
      return _buildSingleExercisePage(state, group.first);
    } else {
      // Multiple exercises (superset/circuit)
      return _buildMultiExercisePage(state, group);
    }
  }

  /// Build page for single exercise
  Widget _buildSingleExercisePage(WorkoutSessionActive state, WorkoutExercise exercise) {
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
            // Exercise Type Badge
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

            // Exercise Name
            Text(
              exercise.nome,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 40.h),

            // Series Progress
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '$completedSeries/${exercise.serie}',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : Colors.blue,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Progress Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(exercise.serie, (i) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: i < completedSeries
                              ? Colors.blue
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // Exercise Parameters
            Row(
              children: [
                Expanded(
                  child: _buildParameterCard(
                    'Peso',
                    '${exercise.peso.toStringAsFixed(0)} kg',
                    Icons.fitness_center,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildParameterCard(
                    'Ripetizioni',
                    '${exercise.ripetizioni}',
                    Icons.repeat,
                    Colors.green,
                  ),
                ),
              ],
            ),

            SizedBox(height: 32.h),

            // Complete Series Button
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: isCompleted
                    ? null
                    : () => _handleCompleteSeries(state, exercise),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.green : Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: isCompleted ? 0 : 2,
                ),
                child: Text(
                  isCompleted
                      ? '✅ Esercizio Completato'
                      : 'Completa Serie ${completedSeries + 1}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 100.h), // Space for navigation
          ],
        ),
      ),
    );
  }

  /// 🚀 STEP 4: Build page for multiple exercises (superset/circuit) with TABS
  Widget _buildMultiExercisePage(WorkoutSessionActive state, List<WorkoutExercise> group) {
    final groupType = group.first.setType; // superset or circuit
    final groupColor = _getExerciseTypeColor(group.first);
    final isGroupComplete = _isGroupCompleted(state, group);

    // Ensure current exercise index is valid
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
            // Group Type Badge
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

            // 🚀 Exercise Tabs (Horizontal)
            Container(
              height: 50.h,
              decoration: BoxDecoration(
                color: Colors.grey[100],
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
                            // Exercise completion indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  exIsCompleted ? Icons.check_circle : Icons.fitness_center,
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
                              ],
                            ),
                            SizedBox(height: 2.h),
                            // Exercise name (truncated)
                            Text(
                              exercise.nome.length > 10
                                  ? '${exercise.nome.substring(0, 10)}...'
                                  : exercise.nome,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.grey[700],
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

            // Current Exercise Name (Full)
            Text(
              currentExercise.nome,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 40.h),

            // Series Progress (Same as single exercise)
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                      color: Colors.grey[600],
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
                  // Progress Dots
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
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // Exercise Parameters (Same as single exercise)
            Row(
              children: [
                Expanded(
                  child: _buildParameterCard(
                    'Peso',
                    '${currentExercise.peso.toStringAsFixed(0)} kg',
                    Icons.fitness_center,
                    groupColor,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildParameterCard(
                    'Ripetizioni',
                    '${currentExercise.ripetizioni}',
                    Icons.repeat,
                    groupColor,
                  ),
                ),
              ],
            ),

            SizedBox(height: 32.h),

            // Complete Series Button (Same as single exercise)
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: isCompleted
                    ? null
                    : () => _handleCompleteSeries(state, currentExercise),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.green : groupColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: isCompleted ? 0 : 2,
                ),
                child: Text(
                  isCompleted
                      ? '✅ Esercizio Completato'
                      : 'Completa Serie ${completedSeries + 1}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Group completion status
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

            SizedBox(height: 100.h), // Space for navigation
          ],
        ),
      ),
    );
  }

  Widget _buildParameterCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(WorkoutSessionActive state) {
    final canPrev = _canGoToPrevious();
    final canNext = _canGoToNext();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous Button
            SizedBox(
              width: 80.w,
              height: 48.h,
              child: ElevatedButton(
                onPressed: canPrev ? _goToPreviousGroup : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canPrev ? Colors.grey[600] : Colors.grey[300],
                  foregroundColor: Colors.white,
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

            // Group Indicators
            Row(
              children: List.generate(_exerciseGroups.length, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: index == _currentGroupIndex ? 24.w : 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: index == _currentGroupIndex
                        ? Colors.blue
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                );
              }),
            ),

            const Spacer(),

            // Next Button
            SizedBox(
              width: 80.w,
              height: 48.h,
              child: ElevatedButton(
                onPressed: canNext ? _goToNextGroup : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canNext ? Colors.blue : Colors.grey[300],
                  foregroundColor: Colors.white,
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
              color: Colors.grey[800],
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
                color: Colors.grey[600],
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
                color: Colors.grey[600],
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
    return Center(
      child: CircularProgressIndicator(color: Colors.blue),
    );
  }

  // ============================================================================
  // BLOC LISTENER
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
    }

    if (state is WorkoutSessionCancelled) {
      debugPrint("🚀 [SINGLE EXERCISE] Workout cancelled");
      _stopWorkoutTimer();
      _stopRecoveryTimer();

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
}