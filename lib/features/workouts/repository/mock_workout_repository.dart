// lib/features/workouts/repository/mock_workout_repository.dart
import 'dart:developer' as developer;
import 'dart:convert';
import '../../../core/utils/result.dart' as utils_result; // ✅ FIX: Alias per evitare conflitti
import '../../exercises/models/exercises_response.dart';
import '../models/workout_plan_models.dart';
import '../models/active_workout_models.dart';
import '../models/series_request_models.dart';
import '../models/workout_response_types.dart';
import '../../stats/models/user_stats_models.dart';

/// 🎯 MockWorkoutRepository per Step 5
/// Usa la stessa architettura enterprise ma con dati simulati
/// per isolare il test del pattern BLoC dal backend
class MockWorkoutRepository {

  // Simulazione database in memoria
  final Map<String, dynamic> _mockDatabase = {};
  int _nextWorkoutId = 1000;
  int _nextSeriesId = 2000;

  MockWorkoutRepository() {
    developer.log('🎯 [MOCK REPO] *** MockWorkoutRepository constructor called ***', name: 'MockWorkoutRepository');
    developer.log('🎯 [MOCK REPO] This repository will provide MOCK data and NOT call real backend', name: 'MockWorkoutRepository');
  }

  // ============================================================================
  // MOCK WORKOUT PLANS
  // ============================================================================

  Future<utils_result.Result<List<WorkoutPlan>>> getWorkoutPlans(int userId) async {
    return await utils_result.Result.tryCallAsync(() async {
      developer.log('🎯 [MOCK REPO] Getting mock workout plans for user: $userId', name: 'MockWorkoutRepository');

      // Simula delay di rete
      await Future.delayed(const Duration(milliseconds: 500));

      final mockPlans = [
        WorkoutPlan(
          id: 1,
          nome: 'Scheda Push Mock (BLoC)',
          descrizione: 'Allenamento push simulato per test BLoC',
          dataCreazione: DateTime.now().toIso8601String(),
          esercizi: _generateMockExercises(1),
        ),
        WorkoutPlan(
          id: 2,
          nome: 'Scheda Pull Mock (BLoC)',
          descrizione: 'Allenamento pull simulato per test BLoC',
          dataCreazione: DateTime.now().toIso8601String(),
          esercizi: _generateMockExercises(2),
        ),
        WorkoutPlan(
          id: 3,
          nome: 'Scheda Legs Mock (BLoC)',
          descrizione: 'Allenamento gambe simulato per test BLoC',
          dataCreazione: DateTime.now().toIso8601String(),
          esercizi: _generateMockExercises(3),
        ),
      ];

      developer.log('🎯 [MOCK REPO] Successfully loaded ${mockPlans.length} mock workout plans', name: 'MockWorkoutRepository');
      return mockPlans;
    });
  }

  Future<utils_result.Result<List<WorkoutExercise>>> getWorkoutExercises(int schedaId) async {
    return await utils_result.Result.tryCallAsync(() async {
      developer.log('🎯 [MOCK REPO] Getting mock exercises for workout: $schedaId', name: 'MockWorkoutRepository');

      // Simula delay di rete
      await Future.delayed(const Duration(milliseconds: 300));

      final exercises = _generateMockExercises(schedaId);

      developer.log('🎯 [MOCK REPO] Successfully loaded ${exercises.length} mock exercises', name: 'MockWorkoutRepository');
      return exercises;
    });
  }

  List<WorkoutExercise> _generateMockExercises(int schedaId) {
    final exerciseNames = {
      1: ['Panca Piana Mock', 'Military Press Mock', 'Dips Mock'],
      2: ['Trazioni Mock', 'Rematore Mock', 'Bicep Curl Mock'],
      3: ['Squat Mock', 'Stacchi Mock', 'Leg Press Mock'],
    };

    final names = exerciseNames[schedaId] ?? ['Esercizio Mock $schedaId'];

    return names.asMap().entries.map((entry) {
      final index = entry.key;
      final name = entry.value;

      return WorkoutExercise(
        id: (schedaId * 100) + index + 1,
        schedaEsercizioId: (schedaId * 100) + index + 1,
        nome: name,
        gruppoMuscolare: _getGroupForScheda(schedaId),
        attrezzatura: 'Simulata',
        descrizione: 'Esercizio mock per test BLoC pattern',
        serie: 3,
        ripetizioni: 10,
        peso: 20.0 + (index * 5),
        ordine: index + 1,
        tempoRecupero: 90,
        note: 'Mock exercise per Step 5',
        setType: 'normal',
        linkedToPreviousInt: 0,
        isIsometricInt: 0,
      );
    }).toList();
  }

  String _getGroupForScheda(int schedaId) {
    switch (schedaId) {
      case 1: return 'Push (Petto/Spalle/Tricipiti)';
      case 2: return 'Pull (Dorso/Bicipiti)';
      case 3: return 'Legs (Gambe/Glutei)';
      default: return 'Gruppo Mock';
    }
  }

  // ============================================================================
  // MOCK ACTIVE WORKOUTS
  // ============================================================================

  Future<utils_result.Result<StartWorkoutResponse>> startWorkout(int userId, int schedaId) async {
    return await utils_result.Result.tryCallAsync(() async {
      developer.log('🎯 [MOCK REPO] *** MOCK startWorkout called *** - User: $userId, Scheda: $schedaId', name: 'MockWorkoutRepository');
      developer.log('🎯 [MOCK REPO] This should NOT call the real backend!', name: 'MockWorkoutRepository');

      // Simula delay di rete
      await Future.delayed(const Duration(milliseconds: 800));

      final workoutId = _nextWorkoutId++;
      final sessionId = 'mock_session_${DateTime.now().millisecondsSinceEpoch}_${userId}_$schedaId';

      // Salva nella mock database
      _mockDatabase['workout_$workoutId'] = {
        'id': workoutId,
        'user_id': userId,
        'scheda_id': schedaId,
        'session_id': sessionId,
        'data_inizio': DateTime.now().toIso8601String(),
        'completed_series': <String, dynamic>{},
      };

      final response = StartWorkoutResponse(
        success: true,
        message: 'Mock workout started successfully via BLoC!',
        allenamentoId: workoutId,
        sessionId: sessionId,
      );

      developer.log('🎯 [MOCK REPO] Successfully started mock workout: $workoutId', name: 'MockWorkoutRepository');
      return response;
    });
  }

  Future<utils_result.Result<List<CompletedSeriesData>>> getCompletedSeries(int allenamentoId) async {
    return await utils_result.Result.tryCallAsync(() async {
      developer.log('🎯 [MOCK REPO] Getting mock completed series for workout: $allenamentoId', name: 'MockWorkoutRepository');

      // Simula delay di rete
      await Future.delayed(const Duration(milliseconds: 200));

      final workoutData = _mockDatabase['workout_$allenamentoId'] as Map<String, dynamic>?;
      if (workoutData == null) {
        developer.log('🎯 [MOCK REPO] No workout found for ID: $allenamentoId', name: 'MockWorkoutRepository');
        return <CompletedSeriesData>[];
      }

      final completedSeries = workoutData['completed_series'] as Map<String, dynamic>;
      final seriesList = <CompletedSeriesData>[];

      completedSeries.forEach((key, value) {
        final seriesData = value as List<dynamic>;
        for (final series in seriesData) {
          seriesList.add(CompletedSeriesData.fromJson(series));
        }
      });

      developer.log('🎯 [MOCK REPO] Successfully loaded ${seriesList.length} mock completed series', name: 'MockWorkoutRepository');
      return seriesList;
    });
  }

  Future<utils_result.Result<SaveCompletedSeriesResponse>> saveCompletedSeries(
      int allenamentoId,
      List<SeriesData> serie,
      String requestId,
      ) async {
    return await utils_result.Result.tryCallAsync(() async {
      developer.log('🎯 [MOCK REPO] Saving mock completed series for workout: $allenamentoId', name: 'MockWorkoutRepository');

      // Simula delay di rete (più lungo per simulare salvataggio)
      await Future.delayed(const Duration(milliseconds: 600));

      final workoutData = _mockDatabase['workout_$allenamentoId'] as Map<String, dynamic>?;
      if (workoutData == null) {
        throw Exception('Mock workout not found: $allenamentoId');
      }

      final completedSeries = workoutData['completed_series'] as Map<String, dynamic>;

      for (final seriesData in serie) {
        final exerciseId = seriesData.schedaEsercizioId.toString();

        if (!completedSeries.containsKey(exerciseId)) {
          completedSeries[exerciseId] = <Map<String, dynamic>>[];
        }

        final mockSeriesData = CompletedSeriesData(
          id: 'mock_series_${_nextSeriesId++}',
          schedaEsercizioId: seriesData.schedaEsercizioId,
          peso: seriesData.peso,
          ripetizioni: seriesData.ripetizioni,
          completata: seriesData.completata,
          tempoRecupero: seriesData.tempoRecupero,
          timestamp: DateTime.now().toIso8601String(),
          note: seriesData.note,
          serieNumber: seriesData.serieNumber,
          esercizioId: seriesData.schedaEsercizioId,
          esercizioNome: 'Mock Exercise ${seriesData.schedaEsercizioId}',
          realSerieNumber: seriesData.serieNumber,
        );

        final exerciseSeriesList = completedSeries[exerciseId] as List<Map<String, dynamic>>;
        exerciseSeriesList.add(mockSeriesData.toJson());
      }

      final response = SaveCompletedSeriesResponse(
        success: true,
        message: 'Mock series saved successfully via BLoC Repository!',
      );

      developer.log('🎯 [MOCK REPO] Successfully saved ${serie.length} mock series', name: 'MockWorkoutRepository');
      return response;
    });
  }

  Future<utils_result.Result<CompleteWorkoutResponse>> completeWorkout(
      int allenamentoId,
      int durataTotale, {
        String? note,
      }) async {
    return await utils_result.Result.tryCallAsync(() async {
      developer.log('🎯 [MOCK REPO] Completing mock workout: $allenamentoId, duration: $durataTotale', name: 'MockWorkoutRepository');

      // Simula delay di rete
      await Future.delayed(const Duration(milliseconds: 400));

      final workoutData = _mockDatabase['workout_$allenamentoId'] as Map<String, dynamic>?;
      if (workoutData == null) {
        throw Exception('Mock workout not found: $allenamentoId');
      }

      workoutData['completed'] = true;
      workoutData['durata_totale'] = durataTotale;
      workoutData['note'] = note;
      workoutData['data_completamento'] = DateTime.now().toIso8601String();

      final response = CompleteWorkoutResponse(
        success: true,
        message: 'Mock workout completed successfully via BLoC Repository!',
        allenamentoId: allenamentoId,
        durataTotale: durataTotale,
      );

      developer.log('🎯 [MOCK REPO] Successfully completed mock workout', name: 'MockWorkoutRepository');
      return response;
    });
  }

  // ============================================================================
  // MOCK METHODS (PLACEHOLDER - NON USATI IN STEP 5)
  // ============================================================================

  Future<utils_result.Result<CreateWorkoutPlanResponse>> createWorkoutPlan(CreateWorkoutPlanRequest request) async {
    return utils_result.Result.error('Mock method not implemented');
  }

  Future<utils_result.Result<UpdateWorkoutPlanResponse>> updateWorkoutPlan(UpdateWorkoutPlanRequest request) async {
    return utils_result.Result.error('Mock method not implemented');
  }

  Future<utils_result.Result<DeleteWorkoutPlanResponse>> deleteWorkoutPlan(int schedaId) async {
    return utils_result.Result.error('Mock method not implemented');
  }

  Future<utils_result.Result<List<ExerciseItem>>> getAvailableExercises(int userId) async {
    return utils_result.Result.error('Mock method not implemented');
  }

  Future<utils_result.Result<List<WorkoutHistory>>> getWorkoutHistory(int userId) async {
    return utils_result.Result.error('Mock method not implemented');
  }

  Future<utils_result.Result<List<CompletedSeriesData>>> getWorkoutSeriesDetail(int allenamentoId) async {
    return utils_result.Result.error('Mock method not implemented');
  }

  Future<utils_result.Result<bool>> deleteCompletedSeries(String seriesId) async {
    return utils_result.Result.error('Mock method not implemented');
  }

  Future<utils_result.Result<bool>> updateCompletedSeries(
      String seriesId,
      double weight,
      int reps, {
        int? recoveryTime,
        String? notes,
      }) async {
    return utils_result.Result.error('Mock method not implemented');
  }

  Future<utils_result.Result<bool>> deleteWorkout(int workoutId) async {
    return utils_result.Result.error('Mock method not implemented');
  }

  Future<utils_result.Result<UserStats>> getUserStats(int userId) async {
    return utils_result.Result.error('Mock method not implemented');
  }

  Future<utils_result.Result<PeriodStats>> getPeriodStats(String period) async {
    return utils_result.Result.error('Mock method not implemented');
  }

  // ============================================================================
  // DEBUG METHODS
  // ============================================================================

  /// Debug method per vedere lo stato della mock database
  void printMockDatabase() {
    developer.log('🎯 [MOCK REPO] Mock Database State:', name: 'MockWorkoutRepository');
    developer.log(jsonEncode(_mockDatabase), name: 'MockWorkoutRepository');
  }

  /// Reset della mock database
  void resetMockDatabase() {
    _mockDatabase.clear();
    _nextWorkoutId = 1000;
    _nextSeriesId = 2000;
    developer.log('🎯 [MOCK REPO] Mock database reset', name: 'MockWorkoutRepository');
  }
}