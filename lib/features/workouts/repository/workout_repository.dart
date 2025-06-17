// lib/features/workouts/repository/workout_repository.dart


import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/utils/result.dart';
import '../../exercises/models/exercises_response.dart';
import '../models/workout_plan_models.dart';
import '../models/active_workout_models.dart';
import '../models/series_request_models.dart';
import '../models/workout_response_types.dart';
import '../../stats/models/user_stats_models.dart';
import 'package:dio/dio.dart'; // ✅ NUOVO: Per gestire DELETE manualmente

class WorkoutRepository {
  final ApiClient _apiClient;
  final Dio _dio; // ✅ NUOVO: Riferimento diretto a Dio

  WorkoutRepository({required ApiClient apiClient, required Dio dio})
      : _apiClient = apiClient,
        _dio = dio; // ✅ NUOVO: Inizializza Dio

  // ============================================================================
  // METODI ESISTENTI (invariati)
  // ============================================================================

  Future<Result<List<WorkoutPlan>>> getWorkoutPlans(int userId) async {
    // ... metodo invariato ...
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository]Getting workout plans for user: $userId');

      final response = await _apiClient.getWorkouts(userId);

      if (response != null && response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;

        if (success) {
          final schedeList = response['schede'] as List<dynamic>? ?? [];
          final workoutPlansBasic = schedeList
              .cast<Map<String, dynamic>>()
              .map((json) => WorkoutPlan.fromJson(json))
              .toList();

          //print('[CONSOLE] [workout_repository]Basic workout plans loaded: ${workoutPlansBasic.length}');

          final List<WorkoutPlan> completeWorkoutPlans = [];

          for (final basicPlan in workoutPlansBasic) {
            try {
              final exercisesResult = await getWorkoutExercises(basicPlan.id);

              List<WorkoutExercise> exercises = [];
              exercisesResult.fold(
                onSuccess: (fetchedExercises) {
                  exercises = fetchedExercises;
                  //print('[CONSOLE] [workout_repository]Loaded ${exercises.length} exercises for plan ${basicPlan.nome}');
                },
                onFailure: (exception, message) {
                  //print('[CONSOLE] [workout_repository]Failed to load exercises for plan ${basicPlan.nome}: $message');
                  exercises = [];
                },
              );

              final completePlan = basicPlan.copyWith(esercizi: exercises);
              completeWorkoutPlans.add(completePlan);

            } catch (e) {
              //print('[CONSOLE] [workout_repository]Error loading exercises for plan ${basicPlan.nome}: $e');
              completeWorkoutPlans.add(basicPlan);
            }
          }

          //print('[CONSOLE] [workout_repository]Successfully loaded ${completeWorkoutPlans.length} complete workout plans');

          for (final plan in completeWorkoutPlans) {
            //print('[CONSOLE] [workout_repository]Plan "${plan.nome}": ${plan.esercizi.length} exercises');
          }

          return completeWorkoutPlans;
        } else {
          throw Exception(response['message'] ?? 'Errore nel caricamento delle schede');
        }
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  Future<Result<List<WorkoutExercise>>> getWorkoutExercises(int schedaId) async {
    return await Result.tryCallAsync(() async {
      //print(' [workout_repository]Getting exercises for workout: $schedaId');

      final response = await _apiClient.getWorkoutExercises(schedaId);

      if (response != null && response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;

        if (success) {
          final eserciziList = response['esercizi'] as List<dynamic>? ?? [];
          final exercises = eserciziList
              .cast<Map<String, dynamic>>()
              .map((json) => WorkoutExercise.fromJson(json))
              .toList();

          //print('[CONSOLE]Successfully loaded ${exercises.length} exercises');
          return exercises;
        } else {
          throw Exception(response['message'] ?? 'Errore nel caricamento degli esercizi');
        }
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  // ============================================================================
  // ✅ FIX 1: DELETE SCHEDA con form-data nel body
  // ============================================================================

  Future<Result<DeleteWorkoutPlanResponse>> deleteWorkoutPlan(int schedaId) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE]Deleting workout plan: $schedaId');

      // ✅ NUOVO: Richiesta DELETE manuale con form-data nel body
      final response = await _dio.delete(
        '/schede_standalone.php',
        data: 'scheda_id=$schedaId', // Form-urlencoded nel body
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      //print('[CONSOLE]DELETE response: ${response.data}');

      if (response.data != null && response.data is Map<String, dynamic>) {
        return DeleteWorkoutPlanResponse.fromJson(response.data);
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  // ============================================================================
  // ✅ FIX 2: UPDATE con gestione corretta rimozioni
  // ============================================================================

  Future<Result<UpdateWorkoutPlanResponse>> updateWorkoutPlan(UpdateWorkoutPlanRequest request) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE]Updating workout plan: ${request.schedaId}');

      final requestJson = request.toJson();

      //print('[CONSOLE]Update Request JSON: ${jsonEncode(requestJson)}');
      //print('[CONSOLE]Scheda ID: ${request.schedaId}');
      //print('[CONSOLE]User ID: ${request.userId}');
      //print('[CONSOLE]Nome: ${request.nome}');
      //print('[CONSOLE]Numero esercizi: ${request.esercizi.length}');

      // ✅ NUOVO: Log degli esercizi da rimuovere
      if (request.rimuovi != null && request.rimuovi!.isNotEmpty) {
        //print('[CONSOLE] [workout_repository]Esercizi da rimuovere: ${request.rimuovi!.length}');
        for (final toRemove in request.rimuovi!) {
          //print('[CONSOLE] [workout_repository]Rimuovi esercizio ID: ${toRemove.id} (questo è esercizio_id, non scheda_esercizio_id)');
        }
      }

      final eserciziJson = requestJson['esercizi'] as List<dynamic>;
      for (int i = 0; i < eserciziJson.length; i++) {
        final esercizioJson = eserciziJson[i] as Map<String, dynamic>;
        //print('[CONSOLE] [workout_repository]Esercizio $i JSON: ${jsonEncode(esercizioJson)}');
      }

      final response = await _apiClient.updateWorkoutStandalone(requestJson, action: "update");

      if (response != null && response is Map<String, dynamic>) {
        return UpdateWorkoutPlanResponse.fromJson(response);
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  // ============================================================================
  // ALTRI METODI (invariati)
  // ============================================================================

  Future<Result<CreateWorkoutPlanResponse>> createWorkoutPlan(CreateWorkoutPlanRequest request) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository]Creating workout plan: ${request.nome}');

      final requestJson = request.toJson();
      //print('[CONSOLE] [workout_repository]Create Request JSON: ${jsonEncode(requestJson)}');

      final response = await _apiClient.createWorkoutStandalone(requestJson);

      if (response != null && response is Map<String, dynamic>) {
        return CreateWorkoutPlanResponse.fromJson(response);
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  Future<Result<List<ExerciseItem>>> getAvailableExercises(int userId) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository]Getting available exercises for user: $userId');

      final response = await _apiClient.getAvailableExercises(userId);

      if (response != null && response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;

        if (success) {
          final eserciziList = response['esercizi'] as List<dynamic>? ?? [];
          final exercises = eserciziList
              .cast<Map<String, dynamic>>()
              .map((json) => ExerciseItem.fromJson(json))
              .toList();

          //print('[CONSOLE] [workout_repository]Successfully loaded ${exercises.length} available exercises');
          return exercises;
        } else {
          throw Exception(response['message'] ?? 'Errore nel caricamento degli esercizi disponibili');
        }
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  // ============================================================================
  // ACTIVE WORKOUTS MANAGEMENT (invariati)
  // ============================================================================

  Future<Result<StartWorkoutResponse>> startWorkout(int userId, int schedaId) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository]Starting workout for user: $userId, scheda: $schedaId');

      final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}_${userId}_$schedaId';

      final request = StartWorkoutRequest(
        userId: userId,
        schedaId: schedaId,
        sessionId: sessionId,
      );

      final response = await _apiClient.startWorkout(request.toJson());

      if (response != null && response is Map<String, dynamic>) {
        return StartWorkoutResponse.fromJson(response);
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  Future<Result<List<CompletedSeriesData>>> getCompletedSeries(int allenamentoId) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository]Getting completed series for workout: $allenamentoId');

      final response = await _apiClient.getCompletedSeries(allenamentoId);

      if (response != null && response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;

        if (success) {
          final serieList = response['serie'] as List<dynamic>? ?? [];
          final completedSeries = serieList
              .cast<Map<String, dynamic>>()
              .map((json) => CompletedSeriesData.fromJson(json))
              .toList();

          //print('[CONSOLE] [workout_repository]Successfully loaded ${completedSeries.length} completed series');
          return completedSeries;
        } else {
          throw Exception(response['message'] ?? 'Errore nel recupero delle serie completate');
        }
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  Future<Result<SaveCompletedSeriesResponse>> saveCompletedSeries(
      int allenamentoId,
      List<SeriesData> serie,
      String requestId,
      ) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository]Saving completed series for workout: $allenamentoId');

      final request = SaveCompletedSeriesRequest(
        allenamentoId: allenamentoId,
        serie: serie,
        requestId: requestId,
      );

      final response = await _apiClient.saveCompletedSeries(request.toJson());

      if (response != null && response is Map<String, dynamic>) {
        return SaveCompletedSeriesResponse.fromJson(response);
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  Future<Result<CompleteWorkoutResponse>> completeWorkout(
      int allenamentoId,
      int durataTotale, {
        String? note,
      }) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository]Completing workout: $allenamentoId, duration: $durataTotale');

      final request = CompleteWorkoutRequest(
        allenamentoId: allenamentoId,
        durataTotale: durataTotale,
        note: note,
      );

      final response = await _apiClient.completeWorkout(request.toJson());

      if (response != null && response is Map<String, dynamic>) {
        return CompleteWorkoutResponse.fromJson(response);
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }


  // ============================================================================
  // WORKOUT HISTORY MANAGEMENT (invariati)
  // ============================================================================

  Future<Result<List<WorkoutHistory>>> getWorkoutHistory(int userId) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository]Getting workout history for user: $userId');

      final response = await _apiClient.getWorkoutHistory(userId);

      if (response != null && response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;

        if (success) {
          final allenamenti = response['allenamenti'] as List<dynamic>? ?? [];
          final workoutHistory = allenamenti
              .cast<Map<String, dynamic>>()
              .map((json) => WorkoutHistory.fromMap(json))
              .toList();

          //print('[CONSOLE] [workout_repository]Successfully loaded ${workoutHistory.length} workout history entries');
          return workoutHistory;
        } else {
          throw Exception(response['message'] ?? 'Errore nel recupero della cronologia allenamenti');
        }
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  Future<Result<List<CompletedSeriesData>>> getWorkoutSeriesDetail(int allenamentoId) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository]Getting series details for workout: $allenamentoId');

      final response = await _apiClient.getWorkoutSeriesDetail(allenamentoId);

      if (response != null && response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;

        if (success) {
          final serieList = response['serie'] as List<dynamic>? ?? [];
          final seriesDetails = serieList
              .cast<Map<String, dynamic>>()
              .map((json) => CompletedSeriesData.fromJson(json))
              .toList();

          //print('[CONSOLE] [workout_repository]Successfully loaded ${seriesDetails.length} series details');
          return seriesDetails;
        } else {
          throw Exception(response['message'] ?? 'Errore nel recupero delle serie completate');
        }
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  Future<Result<bool>> deleteCompletedSeries(String seriesId) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository]Deleting completed series: $seriesId');

      final request = DeleteSeriesRequest(serieId: seriesId);
      final response = await _apiClient.deleteCompletedSeries(request.toJson());

      if (response != null && response is Map<String, dynamic>) {
        final seriesResponse = SeriesOperationResponse.fromJson(response);
        return seriesResponse.success;
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  Future<Result<bool>> updateCompletedSeries(
      String seriesId,
      double weight,
      int reps, {
        int? recoveryTime,
        String? notes,
      }) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository]Updating completed series: $seriesId');

      final request = UpdateSeriesRequest(
        serieId: seriesId,
        peso: weight,
        ripetizioni: reps,
        tempoRecupero: recoveryTime,
        note: notes,
      );

      final response = await _apiClient.updateCompletedSeries(request.toJson());

      if (response != null && response is Map<String, dynamic>) {
        final seriesResponse = SeriesOperationResponse.fromJson(response);
        return seriesResponse.success;
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  Future<Result<bool>> deleteWorkout(int workoutId) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository]Deleting workout: $workoutId');

      final response = await _apiClient.deleteWorkoutFromHistory({
        'allenamento_id': workoutId,
      });

      if (response != null && response is Map<String, dynamic>) {
        final seriesResponse = SeriesOperationResponse.fromJson(response);
        return seriesResponse.success;
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  // ============================================================================
  // STATISTICS & ANALYTICS (invariati)
  // ============================================================================

  Future<Result<UserStats>> getUserStats(int userId) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository]Getting user stats for: $userId');

      final response = await _apiClient.getUserStats();

      if (response != null && response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;

        if (success) {
          final statsData = response['stats'] as Map<String, dynamic>;
          final userStats = UserStats.fromJson(statsData);
          return userStats;
        } else {
          throw Exception(response['message'] ?? 'Errore nel caricamento delle statistiche');
        }
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  Future<Result<PeriodStats>> getPeriodStats(String period) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository]Getting period stats for: $period');

      final response = await _apiClient.getPeriodStats(period);

      if (response != null && response is Map<String, dynamic>) {
        return PeriodStats.fromJson(response);
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }
}