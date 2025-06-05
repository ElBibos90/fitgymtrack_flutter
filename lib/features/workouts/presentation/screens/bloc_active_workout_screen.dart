// lib/features/workouts/presentation/screens/bloc_active_workout_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Core imports
import '../../../../core/di/dependency_injection.dart';

// BLoC imports
import '../../../../core/network/api_client.dart';
import '../../bloc/active_workout_bloc.dart';

// Model imports
import '../../models/active_workout_models.dart';
import '../../models/workout_plan_models.dart';

// ✅ FIX: Import per MockWorkoutRepository
import '../../repository/mock_workout_repository.dart';
import '../../repository/workout_repository.dart';

class BlocActiveWorkoutScreen extends StatefulWidget {
  final int schedaId;

  const BlocActiveWorkoutScreen({
    super.key,
    required this.schedaId,
  });

  @override
  State<BlocActiveWorkoutScreen> createState() => _BlocActiveWorkoutScreenState();
}

class _BlocActiveWorkoutScreenState extends State<BlocActiveWorkoutScreen> {
  // Timer state (mantenuto locale per responsività UI)
  Timer? _workoutTimer;
  Duration _elapsedTime = Duration.zero;
  DateTime? _startTime;

  // SharedPreferences state (mantenuto per persistenza locale)
  SharedPreferences? _prefs;
  String _workoutKey = '';

  // BLoC debug state
  String _blocStatus = "Initializing Mock BLoC...";
  int _eventCount = 0;
  String _lastEvent = "";
  String _lastState = "";

  // User ID per il test (simulato)
  final int _testUserId = 1;

  // 🎯 Flag per indicare che stiamo usando mock
  bool _isMockMode = false;

  // ✅ FIX: Riferimento diretto al BLoC mock invece di context.read
  ActiveWorkoutBloc? _mockActiveWorkoutBloc;

  @override
  void initState() {
    super.initState();
    debugPrint("🎯 [V5 MOCK] initState called");
    _workoutKey = 'bloc_mock_workout_${widget.schedaId}';
    _initializeMockWorkout();
  }

  @override
  void dispose() {
    debugPrint("🎯 [V5 MOCK] dispose called");
    _saveWorkoutState();
    _workoutTimer?.cancel();
    super.dispose();
  }

  /// 🎯 NUOVO: Inizializza in modalità mock
  Future<void> _initializeMockWorkout() async {
    try {
      setState(() {
        _blocStatus = "Preparing Mock Repository...";
      });

      _prefs = await SharedPreferences.getInstance();
      await _restoreWorkoutState();

      setState(() {
        _isMockMode = true;
        _blocStatus = "Mock BLoC Ready - Starting Workout...";
      });

      debugPrint("🎯 [V5 MOCK] Mock mode prepared successfully");

      // ✅ FIX: Prendi il BLoC dal Provider wrapper invece di context.read
      _mockActiveWorkoutBloc = context.read<ActiveWorkoutBloc>();
      debugPrint("🎯 [V5 MOCK] Got BLoC from Provider: ${_mockActiveWorkoutBloc.runtimeType}");

      _mockActiveWorkoutBloc!.startWorkout(_testUserId, widget.schedaId);
      _logEvent("StartMockWorkout");

    } catch (e) {
      debugPrint("🎯 [V5 MOCK] Error initializing mock: $e");
      setState(() {
        _blocStatus = "Mock Initialization Error: $e";
      });
    }
  }

  Future<void> _restoreWorkoutState() async {
    try {
      final stateJson = _prefs?.getString(_workoutKey);
      debugPrint("🎯 [V5 MOCK] Restoring state: ${stateJson ?? 'null'}");

      if (stateJson != null) {
        final state = jsonDecode(stateJson) as Map<String, dynamic>;

        final startTimeStr = state['startTime'] as String?;
        if (startTimeStr != null) {
          _startTime = DateTime.parse(startTimeStr);
          _elapsedTime = DateTime.now().difference(_startTime!);
        }

        debugPrint("🎯 [V5 MOCK] State restored with elapsed time: ${_elapsedTime.inSeconds}s");
      } else {
        _startTime = DateTime.now();
      }
    } catch (e) {
      debugPrint("🎯 [V5 MOCK] Error restoring state: $e");
      _startTime = DateTime.now();
    }
  }

  Future<void> _saveWorkoutState() async {
    try {
      if (_prefs == null) return;

      final state = {
        'startTime': _startTime?.toIso8601String(),
        'lastSaved': DateTime.now().toIso8601String(),
        'eventCount': _eventCount,
        'isMockMode': _isMockMode,
      };

      await _prefs!.setString(_workoutKey, jsonEncode(state));
      debugPrint("🎯 [V5 MOCK] State saved with $_eventCount events");
    } catch (e) {
      debugPrint("🎯 [V5 MOCK] Error saving state: $e");
    }
  }

  Future<void> _clearWorkoutState() async {
    try {
      await _prefs?.remove(_workoutKey);
      debugPrint("🎯 [V5 MOCK] State cleared");
    } catch (e) {
      debugPrint("🎯 [V5 MOCK] Error clearing state: $e");
    }
  }

  void _startWorkoutTimer() {
    if (_startTime == null) {
      _startTime = DateTime.now();
    }

    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });

        // Auto-save ogni 30 secondi
        if (_elapsedTime.inSeconds % 30 == 0) {
          _saveWorkoutState();
        }

        // Update BLoC timer ogni 5 secondi per test
        if (_elapsedTime.inSeconds % 5 == 0 && _mockActiveWorkoutBloc != null) {
          _mockActiveWorkoutBloc!.updateTimer(_elapsedTime);
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _logEvent(String eventName) {
    _eventCount++;
    _lastEvent = eventName;
    debugPrint("🎯 [V5 MOCK] Event #$_eventCount: $eventName");
    setState(() {
      _blocStatus = "Mock Event: $eventName (#$_eventCount)";
    });
  }

  void _logState(String stateName) {
    _lastState = stateName;
    debugPrint("🎯 [V5 MOCK] State: $stateName");
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
    // Trova l'esercizio con meno serie completate
    int currentIndex = 0;
    int minCompletedSeries = 999;

    for (int i = 0; i < state.exercises.length; i++) {
      final exercise = state.exercises[i];
      final completedCount = _getCompletedSeriesCount(state, exercise.schedaEsercizioId ?? exercise.id);

      if (completedCount < exercise.serie && completedCount < minCompletedSeries) {
        minCompletedSeries = completedCount;
        currentIndex = i;
      }
    }

    return currentIndex;
  }

  void _handleCompleteSeries(
      WorkoutSessionActive state,
      WorkoutExercise exercise,
      int completedCount
      ) {
    debugPrint("🎯 [V5 MOCK] handleCompleteSeries called via Mock BLoC");

    if (_mockActiveWorkoutBloc == null) {
      debugPrint("🎯 [V5 MOCK] ERROR: _mockActiveWorkoutBloc is null!");
      return;
    }

    // Crea SeriesData per il BLoC Mock
    final seriesData = SeriesData(
      schedaEsercizioId: exercise.schedaEsercizioId ?? exercise.id,
      peso: exercise.peso,
      ripetizioni: exercise.ripetizioni,
      completata: 1,
      tempoRecupero: exercise.tempoRecupero,
      note: 'Mock BLoC Test Series',
      serieNumber: completedCount + 1,
      serieId: 'mock_${DateTime.now().millisecondsSinceEpoch}',
    );

    // 🎯 Aggiunge serie locale per feedback immediato
    _mockActiveWorkoutBloc!.addLocalSeries(
        exercise.schedaEsercizioId ?? exercise.id,
        seriesData
    );
    _logEvent("AddMockLocalSeries");

    // 🎯 Salva via Mock API
    final requestId = 'mock_req_${DateTime.now().millisecondsSinceEpoch}';
    _mockActiveWorkoutBloc!.saveSeries(
      state.activeWorkout.id,
      [seriesData],
      requestId,
    );
    _logEvent("SaveMockSeries");

    // Mostra feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mock Serie ${completedCount + 1} via BLoC! 🎯🤖'),
        backgroundColor: Colors.purple,
      ),
    );

    // Controlla se l'allenamento è completato
    final totalExercises = state.exercises.length;
    var completedExercises = 0;

    for (final ex in state.exercises) {
      final exCompletedSeries = _getCompletedSeriesCount(state, ex.schedaEsercizioId ?? ex.id);
      if (exCompletedSeries >= ex.serie) {
        completedExercises++;
      }
    }

    if (completedExercises >= totalExercises) {
      // Completa allenamento mock
      final durationMinutes = _elapsedTime.inMinutes;
      _mockActiveWorkoutBloc!.completeWorkout(
        state.activeWorkout.id,
        durationMinutes,
        note: 'Completed via Mock BLoC test',
      );
      _logEvent("CompleteMockWorkout");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MockBlocWorkoutWrapper(
      schedaId: widget.schedaId,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            'BLoC Mock ${widget.schedaId} v5',
            style: TextStyle(fontSize: 18.sp),
          ),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, size: 20.sp),
              onPressed: () {
                if (_mockActiveWorkoutBloc != null) {
                  _mockActiveWorkoutBloc!.startWorkout(_testUserId, widget.schedaId);
                  _logEvent("RefreshMockWorkout");
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.save, size: 20.sp),
              onPressed: () {
                _saveWorkoutState();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('💾 Mock stato salvato!')),
                );
              },
            ),
          ],
        ),
        body: _mockActiveWorkoutBloc == null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.purple),
              SizedBox(height: 16.h),
              Text(
                'Waiting for Mock BLoC...',
                style: TextStyle(fontSize: 16.sp),
              ),
            ],
          ),
        )
            : BlocListener<ActiveWorkoutBloc, ActiveWorkoutState>(
          bloc: _mockActiveWorkoutBloc,
          listener: (context, state) {
            _logState(state.runtimeType.toString());

            if (state is WorkoutSessionStarted) {
              debugPrint("🎯 [V5 MOCK] Mock workout session started - ID: ${state.response.allenamentoId}");
              _startWorkoutTimer();
            } else if (state is WorkoutSessionActive) {
              debugPrint("🎯 [V5 MOCK] Mock active session with ${state.exercises.length} exercises");
              if (_workoutTimer == null) {
                _startWorkoutTimer();
              }
            } else if (state is WorkoutSessionCompleted) {
              _workoutTimer?.cancel();
              _clearWorkoutState();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('🎉 Mock Test Completo!'),
                  content: Text(
                      'Mock Allenamento BLoC completato!\n\n'
                          '⏱️ Tempo: ${_formatDuration(_elapsedTime)}\n'
                          '🎯 Eventi BLoC: $_eventCount\n'
                          '🤖 Repository: Mock Mode'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
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
                  content: Text('❌ Mock Error: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: BlocBuilder<ActiveWorkoutBloc, ActiveWorkoutState>(
            bloc: _mockActiveWorkoutBloc,
            builder: (context, state) {
              return SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      // Timer + BLoC status
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '⏱️ ${_formatDuration(_elapsedTime)}',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '🤖 MOCK MODE | Events: $_eventCount',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // State-specific content
                      _buildStateContent(state),

                      SizedBox(height: 16.h),

                      // ✅ FIX: Debug info più compatto per evitare overflow
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DEBUG v5 Mock BLoC:',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'API: ${Platform.isAndroid ? "Android" : Platform.operatingSystem} | '
                                  'State: ${state.runtimeType.toString().substring(0, 12)}...',
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Last: $_lastEvent | Mode: Mock Repository',
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // ✅ FIX: Spazio aggiuntivo ridotto per evitare overflow
                      SizedBox(height: 16.h),
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
        height: 160.h, // ✅ FIX: Altezza ridotta
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.purple),
              SizedBox(height: 16.h),
              Text(
                state.message ?? 'Loading Mock...',
                style: TextStyle(fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (state is WorkoutSessionActive) {
      if (state.exercises.isEmpty) {
        return Container(
          height: 160.h, // ✅ FIX: Altezza ridotta
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.orange),
                SizedBox(height: 12.h),
                const Text('No mock exercises found'),
                SizedBox(height: 12.h),
                ElevatedButton(
                  onPressed: () {
                    if (_mockActiveWorkoutBloc != null) {
                      _mockActiveWorkoutBloc!.startWorkout(_testUserId, widget.schedaId);
                      _logEvent("RetryLoadMockExercises");
                    }
                  },
                  child: const Text('Retry Mock'),
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
          // Esercizio corrente
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
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
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 6.h),

                Text(
                  'Mock ID: ${currentExercise.id}',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.grey[500],
                  ),
                ),

                SizedBox(height: 8.h),

                Text(
                  'Serie: $completedSeries / ${currentExercise.serie}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.purple[600],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h), // ✅ FIX: Spazio ridotto

          // Pulsante completa serie
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: completedSeries >= currentExercise.serie
                  ? null
                  : () => _handleCompleteSeries(state, currentExercise, completedSeries),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                completedSeries >= currentExercise.serie
                    ? 'Mock Complete 🎯'
                    : 'Mock Serie ${completedSeries + 1} 🎯',
                style: TextStyle(
                  fontSize: 16.sp,
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
        height: 160.h, // ✅ FIX: Altezza ridotta
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              SizedBox(height: 12.h),
              Text(
                'Mock BLoC Error',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: () {
                  if (_mockActiveWorkoutBloc != null) {
                    _mockActiveWorkoutBloc!.resetState();
                    _mockActiveWorkoutBloc!.startWorkout(_testUserId, widget.schedaId);
                    _logEvent("ResetAndRetryMock");
                  }
                },
                child: const Text('Retry Mock'),
              ),
            ],
          ),
        ),
      );
    }

    // Stato iniziale o altri stati
    return Container(
      height: 160.h, // ✅ FIX: Altezza ridotta
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.purple),
            SizedBox(height: 12.h),
            Text(
              'Mock BLoC: ${state.runtimeType.toString().substring(0, 15)}...',
              style: TextStyle(fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () {
                if (_mockActiveWorkoutBloc != null) {
                  _mockActiveWorkoutBloc!.startWorkout(_testUserId, widget.schedaId);
                  _logEvent("ManualStartMock");
                }
              },
              child: const Text('Start Mock Workout'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 🎯 MOCK BLOC WORKOUT WRAPPER (SIMPLIFIED AND FIXED)
// ============================================================================

/// Wrapper semplificato che crea un BLoC mock senza interferire con il DI globale
class MockBlocWorkoutWrapper extends StatefulWidget {
  final int schedaId;
  final Widget child;

  const MockBlocWorkoutWrapper({
    super.key,
    required this.schedaId,
    required this.child,
  });

  @override
  State<MockBlocWorkoutWrapper> createState() => _MockBlocWorkoutWrapperState();
}

class _MockBlocWorkoutWrapperState extends State<MockBlocWorkoutWrapper> {
  bool _isInitializing = true;
  String _initStatus = "Creating Mock Repository...";
  ActiveWorkoutBloc? _mockActiveWorkoutBloc;

  @override
  void initState() {
    super.initState();
    _createMockBLoC();
  }

  @override
  void dispose() {
    _mockActiveWorkoutBloc?.close();
    super.dispose();
  }

  /// Crea un BLoC mock senza interferire con il DI globale
  Future<void> _createMockBLoC() async {
    try {
      debugPrint("🎯 [MOCK WRAPPER] Creating isolated mock BLoC...");

      setState(() {
        _initStatus = "Creating Mock Repository...";
      });

      // ✅ FIX: Crea repository mock con il nuovo adapter
      final mockRepository = MockWorkoutRepository();

      setState(() {
        _initStatus = "Creating Mock Adapter...";
      });

      // ✅ FIX: Usa il nuovo MockWorkoutRepositoryAdapter
      final mockAdapter = MockWorkoutRepositoryAdapter(mockRepository);

      setState(() {
        _initStatus = "Creating Mock BLoC...";
      });

      // Crea BLoC con l'adapter mock
      _mockActiveWorkoutBloc = ActiveWorkoutBloc(
        workoutRepository: mockAdapter,
      );

      setState(() {
        _isInitializing = false;
        _initStatus = "Mock Ready!";
      });

      debugPrint("🎯 [MOCK WRAPPER] Mock BLoC created successfully with isolated mock repository");

    } catch (e) {
      debugPrint("🎯 [MOCK WRAPPER] Error creating mock BLoC: $e");
      setState(() {
        _isInitializing = false;
        _initStatus = "Mock Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.purple[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.purple),
              SizedBox(height: 16.h),
              Text(
                _initStatus,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.purple[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                '🤖 Mock DI Initialization',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.purple[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ FIX: Controllo di sicurezza per BLoC non inizializzato
    if (_mockActiveWorkoutBloc == null) {
      return Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16.h),
              Text(
                'Mock BLoC Creation Failed',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  _initStatus,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.red[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to Test Menu'),
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitializing = true;
                    _initStatus = "Retrying Mock Creation...";
                  });
                  _createMockBLoC();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry Mock Creation'),
              ),
            ],
          ),
        ),
      );
    }

    // Provide il BLoC mock isolato al widget child
    return BlocProvider<ActiveWorkoutBloc>.value(
      value: _mockActiveWorkoutBloc!,
      child: widget.child,
    );
  }
}