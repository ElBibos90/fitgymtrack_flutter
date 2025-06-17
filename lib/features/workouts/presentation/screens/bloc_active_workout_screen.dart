// lib/features/workouts/presentation/screens/bloc_active_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Core imports
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/session_service.dart';

// BLoC imports
import '../../bloc/active_workout_bloc.dart';

// Model imports
import '../../models/active_workout_models.dart';
import '../../models/workout_plan_models.dart';

/// Screen per testare il BLoC pattern con repository reali
/// Versione semplificata senza mock - usa direttamente il WorkoutRepository
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

  // SharedPreferences state
  SharedPreferences? _prefs;
  String _workoutKey = '';

  // Debug state
  String _blocStatus = "Initializing Real BLoC...";
  int _eventCount = 0;
  String _lastEvent = "";
  String _lastState = "";

  // User ID (ottenuto dalla sessione)
  int? _userId;

  @override
  void initState() {
    super.initState();
    //print("🎯 [REAL BLOC] initState called");
    _workoutKey = 'bloc_real_workout_${widget.schedaId}';
    _initializeRealWorkout();
  }

  @override
  void dispose() {
    //print("🎯 [REAL BLOC] dispose called");
    _saveWorkoutState();
    _workoutTimer?.cancel();
    super.dispose();
  }

  /// Inizializza con repository reali
  Future<void> _initializeRealWorkout() async {
    try {
      setState(() {
        _blocStatus = "Connecting to Real API...";
      });

      _prefs = await SharedPreferences.getInstance();
      await _restoreWorkoutState();

      // Ottieni userId dalla sessione
      final sessionService = getIt.get<SessionService>();
      _userId = await sessionService.getCurrentUserId();

      if (_userId == null) {
        setState(() {
          _blocStatus = "Error: User not logged in";
        });
        return;
      }

      setState(() {
        _blocStatus = "Real BLoC Ready - Starting Workout...";
      });

      //print("🎯 [REAL BLOC] Real mode prepared successfully for user $_userId");

      // Usa il BLoC dal context (già fornito dal Provider)
      context.read<ActiveWorkoutBloc>().startWorkout(_userId!, widget.schedaId);
      _logEvent("StartRealWorkout");

    } catch (e) {
      //print("🎯 [REAL BLOC] Error initializing real workflow: $e");
      setState(() {
        _blocStatus = "Real Initialization Error: $e";
      });
    }
  }

  Future<void> _restoreWorkoutState() async {
    try {
      final stateJson = _prefs?.getString(_workoutKey);
      //print("🎯 [REAL BLOC] Restoring state: ${stateJson ?? 'null'}");

      if (stateJson != null) {
        final state = jsonDecode(stateJson) as Map<String, dynamic>;

        final startTimeStr = state['startTime'] as String?;
        if (startTimeStr != null) {
          _startTime = DateTime.parse(startTimeStr);
          _elapsedTime = DateTime.now().difference(_startTime!);
        }

        //print("🎯 [REAL BLOC] State restored with elapsed time: ${_elapsedTime.inSeconds}s");
      } else {
        _startTime = DateTime.now();
      }
    } catch (e) {
      //print("🎯 [REAL BLOC] Error restoring state: $e");
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
        'isRealMode': true,
      };

      await _prefs!.setString(_workoutKey, jsonEncode(state));
      //print("🎯 [REAL BLOC] State saved with $_eventCount events");
    } catch (e) {
      //print("🎯 [REAL BLOC] Error saving state: $e");
    }
  }

  Future<void> _clearWorkoutState() async {
    try {
      await _prefs?.remove(_workoutKey);
      //print("🎯 [REAL BLOC] State cleared");
    } catch (e) {
      //print("🎯 [REAL BLOC] Error clearing state: $e");
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

        // Update BLoC timer ogni 5 secondi
        if (_elapsedTime.inSeconds % 5 == 0) {
          context.read<ActiveWorkoutBloc>().updateTimer(_elapsedTime);
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _logEvent(String eventName) {
    _eventCount++;
    _lastEvent = eventName;
    //print("🎯 [REAL BLOC] Event #$_eventCount: $eventName");
    setState(() {
      _blocStatus = "Real Event: $eventName (#$_eventCount)";
    });
  }

  void _logState(String stateName) {
    _lastState = stateName;
    //print("🎯 [REAL BLOC] State: $stateName");
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
    //print("🎯 [REAL BLOC] handleCompleteSeries called via Real BLoC");

    // Crea SeriesData per il BLoC
    final seriesData = SeriesData(
      schedaEsercizioId: exercise.schedaEsercizioId ?? exercise.id,
      peso: exercise.peso,
      ripetizioni: exercise.ripetizioni,
      completata: 1,
      tempoRecupero: exercise.tempoRecupero,
      note: 'Real BLoC Test Series',
      serieNumber: completedCount + 1,
      serieId: 'real_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Aggiunge serie locale per feedback immediato
    context.read<ActiveWorkoutBloc>().addLocalSeries(
        exercise.schedaEsercizioId ?? exercise.id,
        seriesData
    );
    _logEvent("AddRealLocalSeries");

    // Salva via Real API
    final requestId = 'real_req_${DateTime.now().millisecondsSinceEpoch}';
    context.read<ActiveWorkoutBloc>().saveSeries(
      state.activeWorkout.id,
      [seriesData],
      requestId,
    );
    _logEvent("SaveRealSeries");

    // Mostra feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Real Serie ${completedCount + 1} via BLoC! 💪🔥'),
        backgroundColor: Colors.green,
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
      // Completa allenamento reale
      final durationMinutes = _elapsedTime.inMinutes;
      context.read<ActiveWorkoutBloc>().completeWorkout(
        state.activeWorkout.id,
        durationMinutes,
        note: 'Completed via Real BLoC',
      );
      _logEvent("CompleteRealWorkout");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Real BLoC ${widget.schedaId}',
          style: TextStyle(fontSize: 18.sp),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 20.sp),
            onPressed: () {
              if (_userId != null) {
                context.read<ActiveWorkoutBloc>().startWorkout(_userId!, widget.schedaId);
                _logEvent("RefreshRealWorkout");
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.save, size: 20.sp),
            onPressed: () {
              _saveWorkoutState();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('💾 Real stato salvato!')),
              );
            },
          ),
        ],
      ),
      body: BlocListener<ActiveWorkoutBloc, ActiveWorkoutState>(
        listener: (context, state) {
          _logState(state.runtimeType.toString());

          if (state is WorkoutSessionStarted) {
            //print("🎯 [REAL BLOC] Real workout session started - ID: ${state.response.allenamentoId}");
            _startWorkoutTimer();
          } else if (state is WorkoutSessionActive) {
            //print("🎯 [REAL BLOC] Real active session with ${state.exercises.length} exercises");
            if (_workoutTimer == null) {
              _startWorkoutTimer();
            }
          } else if (state is WorkoutSessionCompleted) {
            _workoutTimer?.cancel();
            _clearWorkoutState();
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('🎉 Real Workout Completo!'),
                content: Text(
                    'Real Allenamento BLoC completato!\n\n'
                        '⏱️ Tempo: ${_formatDuration(_elapsedTime)}\n'
                        '🎯 Eventi BLoC: $_eventCount\n'
                        '💪 Repository: Real Mode'
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
                content: Text('❌ Real Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<ActiveWorkoutBloc, ActiveWorkoutState>(
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
                        color: Colors.green,
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
                            '💪 REAL MODE | Events: $_eventCount',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white.withValues(alpha:0.8),
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

                    // Debug info
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
                            'DEBUG Real BLoC:',
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
                            'Last: $_lastEvent | Mode: Real Repository',
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

                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStateContent(ActiveWorkoutState state) {
    if (state is ActiveWorkoutLoading) {
      return Container(
        height: 160.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16.h),
              Text(
                state.message ?? 'Loading Real Workout...',
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
          height: 160.h,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.orange),
                SizedBox(height: 12.h),
                const Text('No real exercises found'),
                SizedBox(height: 12.h),
                ElevatedButton(
                  onPressed: () {
                    if (_userId != null) {
                      context.read<ActiveWorkoutBloc>().startWorkout(_userId!, widget.schedaId);
                      _logEvent("RetryLoadRealExercises");
                    }
                  },
                  child: const Text('Retry Real'),
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
                  color: Colors.black.withValues(alpha:0.1),
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
                  'Real ID: ${currentExercise.id}',
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
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Pulsante completa serie
          SizedBox(
            width: double.infinity,
            height: 48.h,
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
                    ? 'Real Complete 💪'
                    : 'Real Serie ${completedSeries + 1} 💪',
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
        height: 160.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              SizedBox(height: 12.h),
              Text(
                'Real BLoC Error',
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
                  if (_userId != null) {
                    context.read<ActiveWorkoutBloc>().resetState();
                    context.read<ActiveWorkoutBloc>().startWorkout(_userId!, widget.schedaId);
                    _logEvent("ResetAndRetryReal");
                  }
                },
                child: const Text('Retry Real'),
              ),
            ],
          ),
        ),
      );
    }

    // Stato iniziale o altri stati
    return Container(
      height: 160.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 12.h),
            Text(
              'Real BLoC: ${state.runtimeType.toString().substring(0, 15)}...',
              style: TextStyle(fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () {
                if (_userId != null) {
                  context.read<ActiveWorkoutBloc>().startWorkout(_userId!, widget.schedaId);
                  _logEvent("ManualStartReal");
                }
              },
              child: const Text('Start Real Workout'),
            ),
          ],
        ),
      ),
    );
  }
}