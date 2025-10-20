// lib/features/workouts/services/workout_offline_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/active_workout_models.dart';
import '../bloc/active_workout_bloc.dart';
import '../repository/workout_repository.dart';

/// 🚀 NUOVO: Servizio per gestione offline degli allenamenti
/// Salva localmente i dati e sincronizza quando la connessione è disponibile
class WorkoutOfflineService {
  static const String _offlineWorkoutKey = 'offline_workout_data';
  static const String _pendingSeriesKey = 'pending_series_queue';
  static const String _syncStatusKey = 'sync_status';
  
  final WorkoutRepository _repository;
  SharedPreferences? _prefs;
  
  WorkoutOfflineService({
    required WorkoutRepository repository,
    SharedPreferences? prefs,
  }) : _repository = repository, _prefs = prefs;

  /// Inizializza SharedPreferences se non è già stato fatto
  Future<void> _ensurePrefsInitialized() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  // ============================================================================
  // 🚀 GESTIONE ALLENAMENTO OFFLINE
  // ============================================================================

  /// Salva l'allenamento corrente localmente
  Future<void> saveOfflineWorkout(WorkoutSessionActive workoutState) async {
    try {
      await _ensurePrefsInitialized();
      
      final offlineData = {
        'allenamento_id': workoutState.activeWorkout.id,
        'scheda_id': workoutState.activeWorkout.schedaId,
        'start_time': workoutState.startTime.toIso8601String(),
        'elapsed_time': workoutState.elapsedTime.inMinutes,
        'exercises': workoutState.exercises.map((e) => e.toJson()).toList(),
        'completed_series': _serializeCompletedSeries(workoutState.completedSeries),
        'last_sync': DateTime.now().toIso8601String(),
        'is_active': true,
      };

      await _prefs!.setString(_offlineWorkoutKey, jsonEncode(offlineData));
      //debugPrint('[CONSOLE] [offline_service] 💾 Workout saved offline');
    } catch (e) {
      //debugPrint('[CONSOLE] [offline_service] ❌ Error saving offline workout: $e');
    }
  }

  /// Carica l'allenamento offline se disponibile
  Future<Map<String, dynamic>?> loadOfflineWorkout() async {
    try {
      await _ensurePrefsInitialized();
      
      final offlineData = _prefs!.getString(_offlineWorkoutKey);
      if (offlineData == null) return null;

      final data = jsonDecode(offlineData) as Map<String, dynamic>;
      
      // Verifica se l'allenamento è ancora attivo (non più vecchio di 24 ore)
      final startTime = DateTime.parse(data['start_time']);
      final isExpired = DateTime.now().difference(startTime).inHours > 24;
      
      if (isExpired) {
        await clearOfflineWorkout();
        return null;
      }

      //debugPrint('[CONSOLE] [offline_service] 📱 Loaded offline workout: ${data['allenamento_id']}');
      return data;
    } catch (e) {
      //debugPrint('[CONSOLE] [offline_service] ❌ Error loading offline workout: $e');
      return null;
    }
  }

  /// Pulisce i dati offline
  Future<void> clearOfflineWorkout() async {
    await _ensurePrefsInitialized();
    await _prefs!.remove(_offlineWorkoutKey);
    await _prefs!.remove(_pendingSeriesKey);
    //debugPrint('[CONSOLE] [offline_service] 🧹 Offline workout cleared');
  }

  // ============================================================================
  // 🚀 GESTIONE SERIE IN CODA
  // ============================================================================

  /// Aggiunge una serie alla coda di sincronizzazione
  Future<void> queueSeriesForSync(SeriesData series, int allenamentoId) async {
    try {
      await _ensurePrefsInitialized();
      final pendingSeries = await getPendingSeries();
      
      final seriesData = {
        'series': series.toJson(),
        'allenamento_id': allenamentoId,
        'timestamp': DateTime.now().toIso8601String(),
        'retry_count': 0,
      };
      
      pendingSeries.add(seriesData);
      await _savePendingSeries(pendingSeries);
      
      //debugPrint('[CONSOLE] [offline_service] 📋 Series queued for sync: ${series.serieId}');
    } catch (e) {
      //debugPrint('[CONSOLE] [offline_service] ❌ Error queuing series: $e');
    }
  }

  /// Ottiene le serie in attesa di sincronizzazione
  Future<List<Map<String, dynamic>>> getPendingSeries() async {
    try {
      await _ensurePrefsInitialized();
      final pendingData = _prefs!.getString(_pendingSeriesKey);
      if (pendingData == null) return [];
      
      final List<dynamic> raw = jsonDecode(pendingData);
      return raw.cast<Map<String, dynamic>>();
    } catch (e) {
      //debugPrint('[CONSOLE] [offline_service] ❌ Error getting pending series: $e');
      return [];
    }
  }

  /// Salva le serie in attesa
  Future<void> _savePendingSeries(List<Map<String, dynamic>> series) async {
    await _ensurePrefsInitialized();
    await _prefs!.setString(_pendingSeriesKey, jsonEncode(series));
  }

  /// Rimuove una serie dalla coda dopo sincronizzazione riuscita
  Future<void> removeSeriesFromQueue(String seriesId) async {
    try {
      final pendingSeries = await getPendingSeries();
      pendingSeries.removeWhere((s) => s['series']['serie_id'] == seriesId);
      await _savePendingSeries(pendingSeries);
    } catch (e) {
      //debugPrint('[CONSOLE] [offline_service] ❌ Error removing series from queue: $e');
    }
  }

  // ============================================================================
  // 🚀 SINCRONIZZAZIONE AUTOMATICA
  // ============================================================================

  /// Sincronizza tutti i dati pendenti quando la connessione è disponibile
  Future<bool> syncPendingData() async {
    try {
      // Verifica connessione
      final results = await Connectivity().checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result == ConnectivityResult.none) {
        //debugPrint('[CONSOLE] [offline_service] 📡 No internet connection, skipping sync');
        return false;
      }

      //debugPrint('[CONSOLE] [offline_service] 🔄 Starting sync...');

      // Sincronizza serie pendenti
      final pendingSeries = await getPendingSeries();
      if (pendingSeries.isNotEmpty) {
        await _syncPendingSeries(pendingSeries);
      }

      // 🔧 FIX: Non rimuovere l'allenamento offline se è ancora attivo
      // Questo evita il loop infinito di caricamento
      final offlineWorkout = await loadOfflineWorkout();
      if (offlineWorkout != null) {
        final startTime = DateTime.parse(offlineWorkout['start_time']);
        final isExpired = DateTime.now().difference(startTime).inHours > 24;
        
        // Rimuovi solo se scaduto o se l'allenamento è stato completato
        if (isExpired) {
          await clearOfflineWorkout();
          //debugPrint('[CONSOLE] [offline_service] 🧹 Offline workout expired and cleared');
        } else {
          //debugPrint('[CONSOLE] [offline_service] ✅ Offline workout still active, keeping for restore');
        }
      }

      // Aggiorna timestamp ultima sincronizzazione
      await _updateLastSyncTime();
      
      //debugPrint('[CONSOLE] [offline_service] ✅ Sync completed successfully');
      return true;
    } catch (e) {
      //debugPrint('[CONSOLE] [offline_service] ❌ Sync failed: $e');
      return false;
    }
  }

  /// Sincronizza le serie pendenti con retry automatico
  Future<void> _syncPendingSeries(List<Map<String, dynamic>> pendingSeries) async {
    final List<Map<String, dynamic>> failedSeries = [];

    for (final seriesData in pendingSeries) {
      try {
        final series = SeriesData.fromJson(seriesData['series']);
        final allenamentoId = seriesData['allenamento_id'] as int;
        final retryCount = seriesData['retry_count'] as int;

        // Limita i tentativi a 3
        if (retryCount >= 3) {
          //debugPrint('[CONSOLE] [offline_service] ⚠️ Max retries reached for series: ${series.serieId}');
          continue;
        }

        // Tenta la sincronizzazione
        final result = await _repository.saveCompletedSeries(
          allenamentoId,
          [series],
          'offline_sync_${DateTime.now().millisecondsSinceEpoch}',
        );

        result.fold(
          onSuccess: (_) {
            // Rimuovi dalla coda se sincronizzazione riuscita
            removeSeriesFromQueue(series.serieId ?? '');
            //debugPrint('[CONSOLE] [offline_service] ✅ Series synced: ${series.serieId}');
          },
          onFailure: (exception, message) {
            // Incrementa contatore tentativi
            seriesData['retry_count'] = retryCount + 1;
            failedSeries.add(seriesData);
            //debugPrint('[CONSOLE] [offline_service] ❌ Series sync failed: ${series.serieId} - $message');
          },
        );
      } catch (e) {
        //debugPrint('[CONSOLE] [offline_service] ❌ Error processing series: $e');
        failedSeries.add(seriesData);
      }
    }

    // Salva le serie fallite per retry successivo
    if (failedSeries.isNotEmpty) {
      await _savePendingSeries(failedSeries);
      //debugPrint('[CONSOLE] [offline_service] ⏳ ${failedSeries.length} series queued for retry');
    }
  }

  // ============================================================================
  // 🚀 UTILITY METHODS
  // ============================================================================

  /// Serializza le serie completate per il salvataggio locale
  Map<String, dynamic> _serializeCompletedSeries(Map<int, List<CompletedSeriesData>> completedSeries) {
    final Map<String, dynamic> serialized = {};
    
    for (final entry in completedSeries.entries) {
      serialized[entry.key.toString()] = entry.value.map((s) => s.toJson()).toList();
    }
    
    return serialized;
  }

  /// Deserializza le serie completate dal salvataggio locale
  Map<int, List<CompletedSeriesData>> _deserializeCompletedSeries(Map<String, dynamic> serialized) {
    final Map<int, List<CompletedSeriesData>> completedSeries = {};
    
    for (final entry in serialized.entries) {
      final exerciseId = int.parse(entry.key);
      final seriesList = (entry.value as List<dynamic>)
          .map((s) => CompletedSeriesData.fromJson(s as Map<String, dynamic>))
          .toList();
      completedSeries[exerciseId] = seriesList;
    }
    
    return completedSeries;
  }

  /// Aggiorna il timestamp dell'ultima sincronizzazione
  Future<void> _updateLastSyncTime() async {
    await _ensurePrefsInitialized();
    final syncData = {
      'last_sync': DateTime.now().toIso8601String(),
      'status': 'success',
    };
    await _prefs!.setString(_syncStatusKey, jsonEncode(syncData));
  }

  /// Verifica se ci sono dati pendenti di sincronizzazione
  Future<bool> hasPendingData() async {
    final pendingSeries = await getPendingSeries();
    return pendingSeries.isNotEmpty;
  }

  /// Ottiene statistiche sui dati offline
  Future<Map<String, dynamic>> getOfflineStats() async {
    await _ensurePrefsInitialized();
    final pendingSeries = await getPendingSeries();
    final offlineWorkout = await loadOfflineWorkout();
    
    return {
      'pending_series_count': pendingSeries.length,
      'has_offline_workout': offlineWorkout != null,
      'last_sync': _prefs!.getString(_syncStatusKey),
    };
  }

  /// Sincronizza tutti i dati offline disponibili
  Future<void> syncOfflineData() async {
    try {
      //debugPrint('[CONSOLE] [offline_service] 🔄 Starting offline data sync...');
      
      // Verifica connettività
      final connectivity = Connectivity();
      final results = await connectivity.checkConnectivity();
      final isConnected = results.isNotEmpty && results.first != ConnectivityResult.none;
      
      if (!isConnected) {
        //debugPrint('[CONSOLE] [offline_service] ❌ No internet connection available');
        return;
      }

      // Sincronizza serie in coda
      final pendingSeries = await getPendingSeries();
      if (pendingSeries.isNotEmpty) {
        await _syncPendingSeries(pendingSeries);
      }
      
      // 🌐 NUOVO: Sincronizza completamenti offline
      await _syncOfflineCompletions();
      
      // Aggiorna timestamp sincronizzazione
      await _updateLastSyncTime();
      
      //debugPrint('[CONSOLE] [offline_service] ✅ Offline data sync completed');
    } catch (e) {
      //debugPrint('[CONSOLE] [offline_service] ❌ Error during offline sync: $e');
    }
  }

  // ============================================================================
  // 🌐 GESTIONE COMPLETAMENTO OFFLINE
  // ============================================================================

  static const String _offlineCompletionsKey = 'offline_completions_queue';

  /// Salva un allenamento per completamento offline
  Future<void> saveOfflineWorkoutForCompletion(
    int allenamentoId,
    int durataTotale,
    String? note,
  ) async {
    try {
      await _ensurePrefsInitialized();
      
      final completionData = {
        'allenamento_id': allenamentoId,
        'durata_totale': durataTotale,
        'note': note,
        'timestamp': DateTime.now().toIso8601String(),
        'retry_count': 0,
      };

      final pendingCompletions = await getOfflineCompletions();
      pendingCompletions.add(completionData);
      
      await _saveOfflineCompletions(pendingCompletions);
      
      //debugPrint('[CONSOLE] [offline_service] 💾 Workout queued for offline completion: $allenamentoId');
    } catch (e) {
      //debugPrint('[CONSOLE] [offline_service] ❌ Error saving offline completion: $e');
    }
  }

  /// Ottiene i completamenti offline in attesa
  Future<List<Map<String, dynamic>>> getOfflineCompletions() async {
    try {
      await _ensurePrefsInitialized();
      final completionsData = _prefs!.getString(_offlineCompletionsKey);
      if (completionsData == null) return [];
      
      final List<dynamic> raw = jsonDecode(completionsData);
      return raw.cast<Map<String, dynamic>>();
    } catch (e) {
      //debugPrint('[CONSOLE] [offline_service] ❌ Error getting offline completions: $e');
      return [];
    }
  }

  /// Salva i completamenti offline
  Future<void> _saveOfflineCompletions(List<Map<String, dynamic>> completions) async {
    await _ensurePrefsInitialized();
    await _prefs!.setString(_offlineCompletionsKey, jsonEncode(completions));
  }

  /// Sincronizza i completamenti offline
  Future<void> _syncOfflineCompletions() async {
    try {
      final pendingCompletions = await getOfflineCompletions();
      if (pendingCompletions.isEmpty) return;

      //debugPrint('[CONSOLE] [offline_service] 🔄 Syncing ${pendingCompletions.length} offline completions...');

      final List<Map<String, dynamic>> failedCompletions = [];

      for (final completionData in pendingCompletions) {
        try {
          final allenamentoId = completionData['allenamento_id'] as int;
          final durataTotale = completionData['durata_totale'] as int;
          final note = completionData['note'] as String?;
          final retryCount = completionData['retry_count'] as int;

          // Limita i tentativi a 3
          if (retryCount >= 3) {
            //debugPrint('[CONSOLE] [offline_service] ⚠️ Max retries reached for completion: $allenamentoId');
            continue;
          }

          // Tenta il completamento
          final result = await _repository.completeWorkout(
            allenamentoId,
            durataTotale,
            note: note,
          );

          result.fold(
            onSuccess: (_) {
              //debugPrint('[CONSOLE] [offline_service] ✅ Workout completion synced: $allenamentoId');
            },
            onFailure: (exception, message) {
              // Incrementa contatore tentativi
              completionData['retry_count'] = retryCount + 1;
              failedCompletions.add(completionData);
              //debugPrint('[CONSOLE] [offline_service] ❌ Workout completion sync failed: $allenamentoId - $message');
            },
          );
        } catch (e) {
          //debugPrint('[CONSOLE] [offline_service] ❌ Error processing completion: $e');
          failedCompletions.add(completionData);
        }
      }

      // Salva i completamenti falliti per retry successivo
      if (failedCompletions.isNotEmpty) {
        await _saveOfflineCompletions(failedCompletions);
        //debugPrint('[CONSOLE] [offline_service] ⏳ ${failedCompletions.length} completions queued for retry');
      } else {
        // Rimuovi tutti i completamenti se sincronizzati con successo
        await _saveOfflineCompletions([]);
        //debugPrint('[CONSOLE] [offline_service] ✅ All offline completions synced successfully');
      }
    } catch (e) {
      //debugPrint('[CONSOLE] [offline_service] ❌ Error syncing offline completions: $e');
    }
  }
}
