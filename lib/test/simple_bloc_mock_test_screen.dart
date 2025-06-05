// lib/test/simple_bloc_mock_test_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:io';

// BLoC imports
import '../features/workouts/bloc/active_workout_bloc.dart';
import '../features/workouts/repository/mock_workout_repository.dart';
import '../features/workouts/repository/workout_repository.dart';
import '../features/workouts/models/active_workout_models.dart';
import '../features/workouts/models/workout_plan_models.dart';
import '../features/workouts/models/workout_response_types.dart';
import '../features/exercises/models/exercises_response.dart';
import '../features/stats/models/user_stats_models.dart';
import '../core/utils/result.dart' as utils_result;

/// 🎯 SUPER SIMPLE BLoC Mock Test - ZERO DI, ZERO complessità
/// Crea un BLoC isolato che usa SOLO il mock repository
class SimpleBlocMockTestScreen extends StatefulWidget {
  final int schedaId;

  const SimpleBlocMockTestScreen({
    super.key,
    required this.schedaId,
  });

  @override
  State<SimpleBlocMockTestScreen> createState() => _SimpleBlocMockTestScreenState();
}

class _SimpleBlocMockTestScreenState extends State<SimpleBlocMockTestScreen> {
  // 🎯 BLoC isolato creato qui
  late ActiveWorkoutBloc _isolatedMockBloc;

  // Timer state
  Timer? _workoutTimer;
  Duration _elapsedTime = Duration.zero;
  DateTime? _startTime;

  // Mock debug info
  int _eventCount = 0;
  String _lastEvent = "";
  String _lastState = "";

  final int _testUserId = 1;

  @override
  void initState() {
    super.initState();
    debugPrint("🎯 [SIMPLE MOCK] initState - creating ISOLATED mock BLoC");
    _createIsolatedMockBloc();
    _startMockWorkout();
  }

  @override
  void dispose() {
    debugPrint("🎯 [SIMPLE MOCK] dispose - closing isolated BLoC");
    _workoutTimer?.cancel();
    _isolatedMockBloc.close();
    super.dispose();
  }

  /// 🎯 Crea BLoC isolato con SOLO mock repository
  void _createIsolatedMockBloc() {
    // Step 1: Crea mock repository
    final mockRepository = MockWorkoutRepository();
    debugPrint("🎯 [SIMPLE MOCK] Mock repository created: ${mockRepository.runtimeType}");

    // Step 2: Crea adapter che implementa WorkoutRepository
    final mockAdapter = SimpleMockWorkoutRepositoryAdapter(mockRepository);
    debugPrint("🎯 [SIMPLE MOCK] Mock adapter created: ${mockAdapter.runtimeType}");

    // Step 3: Crea BLoC isolato
    _isolatedMockBloc = ActiveWorkoutBloc(workoutRepository: mockAdapter);
    debugPrint("🎯 [SIMPLE MOCK] ✅ Isolated BLoC created - NO DI, NO real backend!");
  }

  void _startMockWorkout() {
    debugPrint("🎯 [SIMPLE MOCK] Starting mock workout...");
    _startTime = DateTime.now();
    _startWorkoutTimer();

    // Avvia workout via BLoC isolato
    _isolatedMockBloc.startWorkout(_testUserId, widget.schedaId);
    _logEvent("StartIsolatedMockWorkout");
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _logEvent(String eventName) {
    _eventCount++;
    _lastEvent = eventName;
    debugPrint("🎯 [SIMPLE MOCK] Event #$_eventCount: $eventName");
  }

  void _logState(String stateName) {
    _lastState = stateName;
    debugPrint("🎯 [SIMPLE MOCK] State: $stateName");
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  int _getCompletedSeriesCount(WorkoutSessionActive state, int exerciseId) {
    final series = state.completedSeries[exerciseId] ?? [];
    return series.length;
  }

  int _getCurrentExerciseIndex(WorkoutSessionActive state) {
    for (int i = 0; i < state.exercises.length; i++) {
      final exercise = state.exercises[i];
      final completedCount = _getCompletedSeriesCount(state, exercise.schedaEsercizioId ?? exercise.id);
      if (completedCount < exercise.serie) {
        return i;
      }
    }
    return 0;
  }

  void _handleCompleteSeries(WorkoutSessionActive state, WorkoutExercise exercise, int completedCount) {
    debugPrint("🎯 [SIMPLE MOCK] handleCompleteSeries - exercise: ${exercise.nome}");

    // Crea SeriesData
    final seriesData = SeriesData(
      schedaEsercizioId: exercise.schedaEsercizioId ?? exercise.id,
      peso: exercise.peso,
      ripetizioni: exercise.ripetizioni,
      completata: 1,
      tempoRecupero: exercise.tempoRecupero,
      note: 'Simple Mock BLoC Test',
      serieNumber: completedCount + 1,
      serieId: 'simple_mock_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Aggiungi serie locale per feedback immediato
    _isolatedMockBloc.addLocalSeries(exercise.schedaEsercizioId ?? exercise.id, seriesData);
    _logEvent("AddLocalSeries");

    // Salva via mock API
    final requestId = 'simple_mock_req_${DateTime.now().millisecondsSinceEpoch}';
    _isolatedMockBloc.saveSeries(state.activeWorkout.id, [seriesData], requestId);
    _logEvent("SaveMockSeries");

    // Feedback UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎯 Simple Mock Serie ${completedCount + 1} completata!'),
        backgroundColor: Colors.green,
      ),
    );

    // Controlla se workout completato
    _checkWorkoutCompletion(state);
  }

  void _checkWorkoutCompletion(WorkoutSessionActive state) {
    var allExercisesCompleted = true;

    for (final exercise in state.exercises) {
      final completedCount = _getCompletedSeriesCount(state, exercise.schedaEsercizioId ?? exercise.id);
      if (completedCount < exercise.serie) {
        allExercisesCompleted = false;
        break;
      }
    }

    if (allExercisesCompleted) {
      final durationMinutes = _elapsedTime.inMinutes;
      _isolatedMockBloc.completeWorkout(
        state.activeWorkout.id,
        durationMinutes,
        note: 'Completed via Simple Mock BLoC test',
      );
      _logEvent("CompleteSimpleMockWorkout");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('🎯 Simple Mock BLoC ${widget.schedaId}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _isolatedMockBloc.startWorkout(_testUserId, widget.schedaId);
              _logEvent("RefreshSimpleMock");
            },
          ),
        ],
      ),
      body: BlocProvider<ActiveWorkoutBloc>.value(
        value: _isolatedMockBloc,
        child: BlocListener<ActiveWorkoutBloc, ActiveWorkoutState>(
          listener: (context, state) {
            _logState(state.runtimeType.toString());

            if (state is WorkoutSessionStarted) {
              debugPrint("🎯 [SIMPLE MOCK] Workout started - ID: ${state.response.allenamentoId}");
            } else if (state is WorkoutSessionActive) {
              debugPrint("🎯 [SIMPLE MOCK] Active session with ${state.exercises.length} exercises");
            } else if (state is WorkoutSessionCompleted) {
              _workoutTimer?.cancel();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('🎉 Simple Mock Completato!'),
                  content: Text(
                      'Simple Mock BLoC test completato!\n\n'
                          '⏱️ Tempo: ${_formatDuration(_elapsedTime)}\n'
                          '🎯 Eventi: $_eventCount\n'
                          '🤖 Repository: Simple Mock\n'
                          '🔥 NO BACKEND CALLS!'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } else if (state is ActiveWorkoutError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Error: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: BlocBuilder<ActiveWorkoutBloc, ActiveWorkoutState>(
            builder: (context, state) {
              return SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      // Timer + Status
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '⏱️ ${_formatDuration(_elapsedTime)}',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '🎯 SIMPLE MOCK | Events: $_eventCount',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // State content
                      _buildStateContent(state),

                      SizedBox(height: 20.h),

                      // Debug info
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎯 SIMPLE MOCK DEBUG:',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Platform: ${Platform.isAndroid ? "Android" : Platform.operatingSystem}',
                              style: TextStyle(fontSize: 10.sp, color: Colors.green[600]),
                            ),
                            Text(
                              'State: ${state.runtimeType.toString()}',
                              style: TextStyle(fontSize: 10.sp, color: Colors.green[600]),
                            ),
                            Text(
                              'Last Event: $_lastEvent',
                              style: TextStyle(fontSize: 10.sp, color: Colors.green[600]),
                            ),
                            Text(
                              '🔥 Repository: ISOLATED MOCK (No DI, No Backend)',
                              style: TextStyle(fontSize: 10.sp, color: Colors.green[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent(ActiveWorkoutState state) {
    if (state is ActiveWorkoutLoading) {
      return Container(
        height: 200.h,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text('Loading Simple Mock...'),
            ],
          ),
        ),
      );
    }

    if (state is WorkoutSessionActive) {
      if (state.exercises.isEmpty) {
        return Container(
          height: 200.h,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                const Text('No exercises found'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _isolatedMockBloc.startWorkout(_testUserId, widget.schedaId);
                    _logEvent("RetryLoadExercises");
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      final currentIndex = _getCurrentExerciseIndex(state);
      final currentExercise = state.exercises[currentIndex];
      final completedSeries = _getCompletedSeriesCount(state, currentExercise.schedaEsercizioId ?? currentExercise.id);

      return Column(
        children: [
          // Current exercise card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  currentExercise.nome,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Simple Mock ID: ${currentExercise.id}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[500],
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Serie: $completedSeries / ${currentExercise.serie}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Complete series button
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: completedSeries >= currentExercise.serie
                  ? null
                  : () => _handleCompleteSeries(state, currentExercise, completedSeries),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                completedSeries >= currentExercise.serie
                    ? '✅ Esercizio Completato'
                    : '🎯 Completa Serie ${completedSeries + 1}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (state is ActiveWorkoutError) {
      return Container(
        height: 200.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Simple Mock Error'),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _isolatedMockBloc.resetState();
                  _isolatedMockBloc.startWorkout(_testUserId, widget.schedaId);
                  _logEvent("ResetAndRetry");
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Initial state
    return Container(
      height: 200.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 16),
            Text('Simple Mock State: ${state.runtimeType.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _isolatedMockBloc.startWorkout(_testUserId, widget.schedaId);
                _logEvent("ManualStart");
              },
              child: const Text('Start Workout'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 🎯 SIMPLE MOCK ADAPTER (MINIMAL IMPLEMENTATION)
// ============================================================================

/// Super simple adapter che implementa WorkoutRepository e delega al mock
class SimpleMockWorkoutRepositoryAdapter implements WorkoutRepository {
  final MockWorkoutRepository _mockRepository;

  SimpleMockWorkoutRepositoryAdapter(this._mockRepository) {
    debugPrint("🎯 [SIMPLE ADAPTER] Created - ALL CALLS GO TO MOCK!");
  }

  @override
  Future<utils_result.Result<List<WorkoutPlan>>> getWorkoutPlans(int userId) {
    debugPrint("🎯 [SIMPLE ADAPTER] getWorkoutPlans - MOCK CALL");
    return _mockRepository.getWorkoutPlans(userId);
  }

  @override
  Future<utils_result.Result<List<WorkoutExercise>>> getWorkoutExercises(int schedaId) {
    debugPrint("🎯 [SIMPLE ADAPTER] getWorkoutExercises - MOCK CALL");
    return _mockRepository.getWorkoutExercises(schedaId);
  }

  @override
  Future<utils_result.Result<StartWorkoutResponse>> startWorkout(int userId, int schedaId) {
    debugPrint("🎯 [SIMPLE ADAPTER] *** startWorkout - MOCK CALL (NO BACKEND) ***");
    return _mockRepository.startWorkout(userId, schedaId);
  }

  @override
  Future<utils_result.Result<List<CompletedSeriesData>>> getCompletedSeries(int allenamentoId) {
    debugPrint("🎯 [SIMPLE ADAPTER] getCompletedSeries - MOCK CALL");
    return _mockRepository.getCompletedSeries(allenamentoId);
  }

  @override
  Future<utils_result.Result<SaveCompletedSeriesResponse>> saveCompletedSeries(
      int allenamentoId, List<SeriesData> serie, String requestId) {
    debugPrint("🎯 [SIMPLE ADAPTER] saveCompletedSeries - MOCK CALL");
    return _mockRepository.saveCompletedSeries(allenamentoId, serie, requestId);
  }

  @override
  Future<utils_result.Result<CompleteWorkoutResponse>> completeWorkout(
      int allenamentoId, int durataTotale, {String? note}) {
    debugPrint("🎯 [SIMPLE ADAPTER] completeWorkout - MOCK CALL");
    return _mockRepository.completeWorkout(allenamentoId, durataTotale, note: note);
  }

  // Tutti gli altri metodi ritornano errore (non usati nel test)
  @override
  Future<utils_result.Result<CreateWorkoutPlanResponse>> createWorkoutPlan(CreateWorkoutPlanRequest request) async =>
      utils_result.Result<CreateWorkoutPlanResponse>.error('Not implemented in simple mock');

  @override
  Future<utils_result.Result<UpdateWorkoutPlanResponse>> updateWorkoutPlan(UpdateWorkoutPlanRequest request) async =>
      utils_result.Result<UpdateWorkoutPlanResponse>.error('Not implemented in simple mock');

  @override
  Future<utils_result.Result<DeleteWorkoutPlanResponse>> deleteWorkoutPlan(int schedaId) async =>
      utils_result.Result<DeleteWorkoutPlanResponse>.error('Not implemented in simple mock');

  @override
  Future<utils_result.Result<List<ExerciseItem>>> getAvailableExercises(int userId) async =>
      utils_result.Result<List<ExerciseItem>>.error('Not implemented in simple mock');

  @override
  Future<utils_result.Result<List<WorkoutHistory>>> getWorkoutHistory(int userId) async =>
      utils_result.Result<List<WorkoutHistory>>.error('Not implemented in simple mock');

  @override
  Future<utils_result.Result<List<CompletedSeriesData>>> getWorkoutSeriesDetail(int allenamentoId) async =>
      utils_result.Result<List<CompletedSeriesData>>.error('Not implemented in simple mock');

  @override
  Future<utils_result.Result<bool>> deleteCompletedSeries(String seriesId) async =>
      utils_result.Result<bool>.error('Not implemented in simple mock');

  @override
  Future<utils_result.Result<bool>> updateCompletedSeries(String seriesId, double weight, int reps,
      {int? recoveryTime, String? notes}) async =>
      utils_result.Result<bool>.error('Not implemented in simple mock');

  @override
  Future<utils_result.Result<bool>> deleteWorkout(int workoutId) async =>
      utils_result.Result<bool>.error('Not implemented in simple mock');

  @override
  Future<utils_result.Result<UserStats>> getUserStats(int userId) async =>
      utils_result.Result<UserStats>.error('Not implemented in simple mock');

  @override
  Future<utils_result.Result<PeriodStats>> getPeriodStats(String period) async =>
      utils_result.Result<PeriodStats>.error('Not implemented in simple mock');
}