// lib/features/workouts/repository/workout_repository.dart

import '../../../core/network/api_client.dart';
import '../../../core/utils/result.dart';
import '../../exercises/models/exercises_response.dart';
import '../models/workout_plan_models.dart';
import '../models/active_workout_models.dart';
import '../models/series_request_models.dart';
import '../models/workout_response_types.dart';
import '../../stats/models/user_stats_models.dart';
import 'package:dio/dio.dart'; // ✅ NUOVO: Per gestire DELETE manualmente
import 'package:connectivity_plus/connectivity_plus.dart'; // 🌐 NUOVO: Per verifica connessione
import '../services/workout_schede_cache_service.dart';
import '../../../core/di/dependency_injection.dart';

class WorkoutRepository {
  final ApiClient _apiClient;
  final Dio _dio; // ✅ NUOVO: Riferimento diretto a Dio
  late final WorkoutSchedeCacheService _schedeCache; // 🌐 NUOVO: Cache servizio

  WorkoutRepository({required ApiClient apiClient, required Dio dio})
      : _apiClient = apiClient,
        _dio = dio { // ✅ NUOVO: Inizializza Dio
    // 🌐 NUOVO: Inizializza cache servizio
    _schedeCache = getIt<WorkoutSchedeCacheService>();
  }

  // ============================================================================
  // METODI ESISTENTI (invariati)
  // ============================================================================

  Future<Result<List<WorkoutPlan>>> getWorkoutPlans(int userId) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository] Getting workout plans for user: $userId');

      // 🌐 NUOVO: Verifica connessione prima di tentare l'API
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity.isNotEmpty && connectivity.first != ConnectivityResult.none;

      if (!isOnline) {
        print('[CONSOLE] [workout_repository] 📡 No internet connection, trying cache...');
        
        // Prova a caricare dal cache
        final cachedSchede = await _schedeCache.getCachedSchede();
        if (cachedSchede != null && cachedSchede.isNotEmpty) {
          //print('[CONSOLE] [workout_repository] ✅ Loaded ${cachedSchede.length} schede from cache (offline mode)');
          // 🌐 NUOVO: In modalità offline, restituisci le schede senza esercizi per evitare errori
          return cachedSchede;
        } else {
          print('[CONSOLE] [workout_repository] ❌ No cached schede available');
          throw Exception('Connessione internet non disponibile e nessuna scheda in cache');
        }
      }

      // Caricamento online normale
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

          // 🌐 NUOVO: Salva nel cache per uso futuro offline
          try {
            await _schedeCache.cacheSchede(completeWorkoutPlans);
            print('[CONSOLE] [workout_repository] 💾 Schede cached for offline use');
          } catch (e) {
            print('[CONSOLE] [workout_repository] ⚠️ Error caching schede: $e');
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
      //print('[CONSOLE] [workout_repository] Getting exercises for workout: $schedaId');

      // 🌐 NUOVO: Verifica connessione prima di tentare l'API
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity.isNotEmpty && connectivity.first != ConnectivityResult.none;

      if (!isOnline) {
        print('[CONSOLE] [workout_repository] 📡 No internet connection for exercises, cannot load');
        throw Exception('Connessione internet non disponibile per caricare gli esercizi');
      }

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
  // ✅ FIX 1: DELETE SCHEDA con form-data nel body (POST)
  // ============================================================================

  Future<Result<DeleteWorkoutPlanResponse>> deleteWorkoutPlan(int schedaId) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE]Deleting workout plan: $schedaId');

      // ✅ NUOVO: Richiesta POST per eliminazione
      final response = await _dio.post(
        '/schede_standalone.php',
        data: {
          'action': 'delete',
          'scheda_id': schedaId,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      //print('[CONSOLE]POST DELETE response: ${response.data}');

      // ✅ FIX: Gestione risposta null o vuota
      if (response.data == null) {
        // Se la risposta è null, assumiamo che l'eliminazione sia andata a buon fine
        return const DeleteWorkoutPlanResponse(
          success: true,
          message: 'Scheda eliminata con successo',
          schedaId: null,
        );
      }

      if (response.data is Map<String, dynamic>) {
        return DeleteWorkoutPlanResponse.fromJson(response.data);
      } else {
        // Se la risposta non è null ma non è un Map, assumiamo successo
        return const DeleteWorkoutPlanResponse(
          success: true,
          message: 'Scheda eliminata con successo',
          schedaId: null,
        );
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
        // ✅ CONTROLLO SUCCESS PRIMA DEL PARSING
        final success = response['success'] as bool? ?? false;
        
        if (!success) {
          // Se success è false, lancia un'eccezione con il messaggio di errore
          final message = response['message'] as String? ?? 'Errore nell\'aggiornamento della scheda';
          throw Exception(message);
        }
        
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
        // ✅ CONTROLLO SUCCESS PRIMA DEL PARSING
        final success = response['success'] as bool? ?? false;
        
        if (!success) {
          // Se success è false, lancia un'eccezione con il messaggio di errore
          final message = response['message'] as String? ?? 'Errore nella creazione della scheda';
          throw Exception(message);
        }
        
        return CreateWorkoutPlanResponse.fromJson(response);
      } else {
        throw Exception('Formato risposta non valido');
      }
    });
  }

  Future<Result<List<ExerciseItem>>> getAvailableExercises(int userId) async {
    return await Result.tryCallAsync(() async {
      final response = await _apiClient.getAvailableExercises(userId);

      if (response != null && response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;

        if (success) {
          final eserciziList = response['esercizi'] as List<dynamic>? ?? [];
          
          final exercises = eserciziList
              .cast<Map<String, dynamic>>()
              .map((json) => ExerciseItem.fromJson(json))
              .toList();

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
      //print('[CONSOLE] [workout_repository] Starting workout for user: $userId, scheda: $schedaId');

      // 🌐 NUOVO: Verifica connessione prima di avviare l'allenamento
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity.isNotEmpty && connectivity.first != ConnectivityResult.none;

      if (!isOnline) {
        //print('[CONSOLE] [workout_repository] 📡 No internet connection, cannot start workout online');
        throw Exception('Connessione internet non disponibile. Non è possibile avviare un nuovo allenamento offline.');
      }

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

  /// 🌐 NUOVO: Controlla se ci sono allenamenti in sospeso per l'utente
  Future<Result<Map<String, dynamic>?>> checkPendingWorkout(int userId) async {
    return await Result.tryCallAsync(() async {
      //print('[CONSOLE] [workout_repository] Checking for pending workouts for user: $userId');

      // 🌐 NUOVO: Verifica connessione prima di controllare il database
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity.isNotEmpty && connectivity.first != ConnectivityResult.none;

      if (!isOnline) {
        //print('[CONSOLE] [workout_repository] 📡 No internet connection, cannot check pending workouts');
        return null; // Non possiamo controllare offline
      }

      final response = await _apiClient.checkPendingWorkout(userId);

      if (response != null && response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;

        if (success) {
          final hasPending = response['has_pending'] as bool? ?? false;
          if (hasPending) {
            final pendingData = response['pending_workout'] as Map<String, dynamic>?;
            //print('[CONSOLE] [workout_repository] ✅ Found pending workout: ${pendingData?['allenamento_id']}');
            return pendingData;
          } else {
            //print('[CONSOLE] [workout_repository] ℹ️ No pending workouts found');
            return null;
          }
        } else {
          print('[CONSOLE] [workout_repository] ❌ Error checking pending workouts: ${response['message']}');
          return null;
        }
      } else {
        print('[CONSOLE] [workout_repository] ❌ Invalid response format');
        return null;
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

      // 🌐 NUOVO: Verifica connessione prima del completamento
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity.isNotEmpty && connectivity.first != ConnectivityResult.none;

      if (!isOnline) {
        print('[CONSOLE] [workout_repository] 📡 Offline mode: Cannot complete workout online');
        throw Exception('Connessione internet non disponibile. L\'allenamento verrà completato quando tornerai online.');
      }

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

      // Aggiungiamo un timeout personalizzato per evitare caricamenti infiniti
      final response = await _apiClient.getWorkoutSeriesDetail(allenamentoId)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Timeout: La richiesta ha impiegato troppo tempo');
            },
          );

      //print('[DEBUG] [workout_repository] Response: $response');

      if (response != null && response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;

        if (success) {
          final serieList = response['serie'] as List<dynamic>? ?? [];
          //print('[DEBUG] [workout_repository] Serie list: $serieList');
          
          final seriesDetails = serieList
              .cast<Map<String, dynamic>>()
              .map((json) {
                try {
                  return CompletedSeriesData.fromJson(json);
                } catch (e) {
                  //print('[DEBUG] [workout_repository] Error parsing series data: $e');
                  //print('[DEBUG] [workout_repository] JSON: $json');
                  rethrow;
                }
              })
              .toList();

          //print('[DEBUG] [workout_repository] Successfully loaded ${seriesDetails.length} series details');
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