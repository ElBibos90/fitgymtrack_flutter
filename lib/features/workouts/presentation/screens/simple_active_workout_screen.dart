// lib/features/workouts/presentation/screens/simple_active_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dio/dio.dart'; // ✅ NUOVO: Per HTTP calls

class SimpleActiveWorkoutScreen extends StatefulWidget {
  final int schedaId;

  const SimpleActiveWorkoutScreen({
    super.key,
    required this.schedaId,
  });

  @override
  State<SimpleActiveWorkoutScreen> createState() => _SimpleActiveWorkoutScreenState();
}

class _SimpleActiveWorkoutScreenState extends State<SimpleActiveWorkoutScreen> {
  // Stato base
  bool _isLoading = false;
  int _completedSeries = 0;

  // Timer state
  Timer? _workoutTimer;
  Duration _elapsedTime = Duration.zero;
  DateTime? _startTime;

  // SharedPreferences state
  SharedPreferences? _prefs;
  bool _isRestoringState = false;
  String _workoutKey = '';

  // ✅ NUOVO: HTTP state
  late Dio _dio;
  bool _httpInitialized = false;
  String _httpStatus = "Initializing...";
  int _apiCalls = 0;
  String _lastApiResponse = "";

  // Esercizi che verranno caricati via HTTP
  List<Map<String, dynamic>> _exercises = [];
  int _currentExerciseIndex = 0;

  @override
  void initState() {
    super.initState();
    //print("🔥 [V4 HTTP] initState called");
    _workoutKey = 'workout_${widget.schedaId}';
    _initializeHttp();
    _initializeWorkout();
  }

  @override
  void dispose() {
    //print("🔥 [V4 HTTP] dispose called");
    _saveWorkoutState();
    _workoutTimer?.cancel();
    super.dispose();
  }

  // ✅ NUOVO: Initialize HTTP client
  void _initializeHttp() {
    try {
      _dio = Dio();
      _dio.options.connectTimeout = const Duration(seconds: 10);
      _dio.options.receiveTimeout = const Duration(seconds: 10);
      _dio.options.sendTimeout = const Duration(seconds: 10);

      // Add request/response interceptors for debugging
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          //print("🔥 [V4 HTTP] Request: ${options.method} ${options.uri}");
          handler.next(options);
        },
        onResponse: (response, handler) {
          //print("🔥 [V4 HTTP] Response: ${response.statusCode}");
          handler.next(response);
        },
        onError: (error, handler) {
          //print("🔥 [V4 HTTP] Error: ${error.message}");
          handler.next(error);
        },
      ));

      setState(() {
        _httpInitialized = true;
        _httpStatus = "HTTP Client Ready ✅";
      });

      //print("🔥 [V4 HTTP] HTTP client initialized successfully");
    } catch (e) {
      //print("🔥 [V4 HTTP] Error initializing HTTP: $e");
      setState(() {
        _httpStatus = "HTTP Error ❌";
      });
    }
  }

  Future<void> _initializeWorkout() async {
    setState(() {
      _isRestoringState = true;
    });

    try {
      _prefs = await SharedPreferences.getInstance();
      await _restoreWorkoutState();

      // ✅ NUOVO: Load exercises via HTTP
      await _loadExercisesFromApi();

    } catch (e) {
      //print("🔥 [V4 HTTP] Error initializing: $e");
    } finally {
      setState(() {
        _isRestoringState = false;
      });
      _startWorkoutTimer();
    }
  }

  // ✅ NUOVO: Load exercises from mock API
  Future<void> _loadExercisesFromApi() async {
    try {
      //print("🔥 [V4 HTTP] Loading exercises from API...");
      setState(() {
        _httpStatus = "Loading exercises...";
      });

      // Use JSONPlaceholder as a mock API - simulating exercise data
      final response = await _dio.get('https://jsonplaceholder.typicode.com/posts');

      _apiCalls++;

      if (response.statusCode == 200) {
        final posts = response.data as List;

        // Convert posts to mock exercises
        _exercises = posts.take(3).map((post) {
          final exerciseNames = ['Panca Piana', 'Squat', 'Stacchi'];
          final index = posts.indexOf(post);
          return {
            'id': post['id'],
            'nome': exerciseNames[index % 3],
            'serie': 3,
            'userId': post['userId'],
          };
        }).toList();

        setState(() {
          _httpStatus = "Exercises loaded ✅ (${_exercises.length})";
          _lastApiResponse = "SUCCESS ${response.statusCode}";
        });

        //print("🔥 [V4 HTTP] Successfully loaded ${_exercises.length} exercises");
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      //print("🔥 [V4 HTTP] Error loading exercises: $e");

      // Fallback to local exercises
      _exercises = [
        {'id': 1, 'nome': 'Panca Piana (Local)', 'serie': 3, 'userId': 0},
        {'id': 2, 'nome': 'Squat (Local)', 'serie': 3, 'userId': 0},
        {'id': 3, 'nome': 'Stacchi (Local)', 'serie': 3, 'userId': 0},
      ];

      setState(() {
        _httpStatus = "HTTP Failed - Using Local ⚠️";
        _lastApiResponse = "ERROR: $e";
      });
    }
  }

  // ✅ NUOVO: Save series to mock API
  Future<void> _saveSeriesViaApi(int seriesNumber) async {
    try {
      //print("🔥 [V4 HTTP] Saving series to API...");

      final currentExercise = _exercises[_currentExerciseIndex];
      final seriesData = {
        'exerciseId': currentExercise['id'],
        'exerciseName': currentExercise['nome'],
        'seriesNumber': seriesNumber,
        'timestamp': DateTime.now().toIso8601String(),
        'workoutId': widget.schedaId,
      };

      // POST to JSONPlaceholder (mock save)
      final response = await _dio.post(
        'https://jsonplaceholder.typicode.com/posts',
        data: seriesData,
      );

      _apiCalls++;

      if (response.statusCode == 201) {
        setState(() {
          _lastApiResponse = "SAVE SUCCESS ${response.statusCode}";
        });
        //print("🔥 [V4 HTTP] Series saved successfully via API");
      } else {
        throw Exception('Save failed: HTTP ${response.statusCode}');
      }

    } catch (e) {
      //print("🔥 [V4 HTTP] Error saving series via API: $e");
      setState(() {
        _lastApiResponse = "SAVE ERROR: $e";
      });
      // Continue anyway - don't block user flow
    }
  }

  Future<void> _restoreWorkoutState() async {
    try {
      final stateJson = _prefs?.getString(_workoutKey);
      //print("🔥 [V4 HTTP] Restoring state: ${stateJson ?? 'null'}");

      if (stateJson != null) {
        final state = jsonDecode(stateJson) as Map<String, dynamic>;

        setState(() {
          _completedSeries = state['completedSeries'] ?? 0;
          _currentExerciseIndex = state['currentExerciseIndex'] ?? 0;
          final startTimeStr = state['startTime'] as String?;
          if (startTimeStr != null) {
            _startTime = DateTime.parse(startTimeStr);
            _elapsedTime = DateTime.now().difference(_startTime!);
          }
        });

        //print("🔥 [V4 HTTP] State restored: $_completedSeries series, exercise $_currentExerciseIndex");
      } else {
        _startTime = DateTime.now();
      }
    } catch (e) {
      //print("🔥 [V4 HTTP] Error restoring state: $e");
      _startTime = DateTime.now();
    }
  }

  Future<void> _saveWorkoutState() async {
    try {
      if (_prefs == null) return;

      final state = {
        'completedSeries': _completedSeries,
        'currentExerciseIndex': _currentExerciseIndex,
        'startTime': _startTime?.toIso8601String(),
        'lastSaved': DateTime.now().toIso8601String(),
        'apiCalls': _apiCalls, // ✅ NUOVO: Track API calls
      };

      await _prefs!.setString(_workoutKey, jsonEncode(state));
      //print("🔥 [V4 HTTP] State saved with $_apiCalls API calls");
    } catch (e) {
      //print("🔥 [V4 HTTP] Error saving state: $e");
    }
  }

  Future<void> _clearWorkoutState() async {
    try {
      await _prefs?.remove(_workoutKey);
      //print("🔥 [V4 HTTP] State cleared");
    } catch (e) {
      //print("🔥 [V4 HTTP] Error clearing state: $e");
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
      } else {
        timer.cancel();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoringState) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Caricamento allenamento...'),
            ],
          ),
        ),
      );
    }

    // ✅ NUOVO: Show error if no exercises loaded
    if (_exercises.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text('Allenamento ${widget.schedaId} v4'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Errore nel caricamento esercizi'),
              const SizedBox(height: 16),
              Text('HTTP Status: $_httpStatus'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadExercisesFromApi(),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Allenamento ${widget.schedaId} v4'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadExercisesFromApi(),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              _saveWorkoutState();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('💾 Salvato!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Timer compatto con HTTP status
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.purple,
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
                  Text(
                    '$_httpStatus | API Calls: $_apiCalls',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white.withValues(alpha:0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Esercizio corrente (caricato via HTTP)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
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
                    _exercises[_currentExerciseIndex]['nome'],
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),

                  SizedBox(height: 8.h),

                  Text(
                    'ID: ${_exercises[_currentExerciseIndex]['id']} | UserID: ${_exercises[_currentExerciseIndex]['userId']}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey[500],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  Text(
                    'Serie completate: $_completedSeries / ${_exercises[_currentExerciseIndex]['serie']}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Pulsante principale
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleCompleteSeries,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(
                  'Completa Serie ${_completedSeries + 1} 🌐',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Debug info con HTTP details
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEBUG v4 HTTP:',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'API: ${Platform.isAndroid ? "Android" : Platform.operatingSystem} | '
                        'HTTP: ${_httpInitialized ? "OK" : "FAIL"} | '
                        'Exercises: ${_exercises.length}',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Last Response: $_lastApiResponse',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Extra space per scroll
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCompleteSeries() async {
    //print("🔥 [V4 HTTP] handleCompleteSeries called");

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ NUOVO: Save via API first
      await _saveSeriesViaApi(_completedSeries + 1);

      // Then update local state
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _completedSeries++;
        _isLoading = false;
      });

      await _saveWorkoutState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Serie $_completedSeries salvata! 🌐💾'),
            backgroundColor: Colors.green,
          ),
        );
      }

      final currentExercise = _exercises[_currentExerciseIndex];
      if (_completedSeries >= currentExercise['serie']) {
        _moveToNextExercise();
      }

    } catch (e) {
      //print("🔥 [V4 HTTP] Error: $e");

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _moveToNextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _completedSeries = 0;
      });

      _saveWorkoutState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prossimo: ${_exercises[_currentExerciseIndex]['nome']}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } else {
      _workoutTimer?.cancel();
      _clearWorkoutState();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Complimenti!'),
            content: Text('Allenamento completato!\n\n⏱️ Tempo: ${_formatDuration(_elapsedTime)}\n🌐 API Calls: $_apiCalls'),
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
      }
    }
  }
}