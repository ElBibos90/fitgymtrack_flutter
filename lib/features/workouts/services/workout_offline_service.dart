// lib/features/workouts/services/workout_offline_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/active_workout_models.dart';
import '../bloc/active_workout_bloc.dart';
import '../models/series_request_models.dart';
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
      print('[CONSOLE] [offline_service] 💾 Workout saved offline');
    } catch (e) {
      print('[CONSOLE] [offline_service] ❌ Error saving offline workout: $e');
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

      print('[CONSOLE] [offline_service] 📱 Loaded offline workout: ${data['allenamento_id']}');
      return data;
    } catch (e) {
      print('[CONSOLE] [offline_service] ❌ Error loading offline workout: $e');
      return null;
    }
  }

  /// Pulisce i dati offline
  Future<void> clearOfflineWorkout() async {
    await _ensurePrefsInitialized();
    await _prefs!.remove(_offlineWorkoutKey);
    await _prefs!.remove(_pendingSeriesKey);
    print('[CONSOLE] [offline_service] 🧹 Offline workout cleared');
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
      
      print('[CONSOLE] [offline_service] 📋 Series queued for sync: ${series.serieId}');
    } catch (e) {
      print('[CONSOLE] [offline_service] ❌ Error queuing series: $e');
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
      print('[CONSOLE] [offline_service] ❌ Error getting pending series: $e');
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
      print('[CONSOLE] [offline_service] ❌ Error removing series from queue: $e');
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
        print('[CONSOLE] [offline_service] 📡 No internet connection, skipping sync');
        return false;
      }

      print('[CONSOLE] [offline_service] 🔄 Starting sync...');

      // Sincronizza serie pendenti
      final pendingSeries = await getPendingSeries();
      if (pendingSeries.isNotEmpty) {
        await _syncPendingSeries(pendingSeries);
      }

      // Aggiorna timestamp ultima sincronizzazione
      await _updateLastSyncTime();
      
      print('[CONSOLE] [offline_service] ✅ Sync completed successfully');
      return true;
    } catch (e) {
      print('[CONSOLE] [offline_service] ❌ Sync failed: $e');
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
          print('[CONSOLE] [offline_service] ⚠️ Max retries reached for series: ${series.serieId}');
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
            print('[CONSOLE] [offline_service] ✅ Series synced: ${series.serieId}');
          },
          onFailure: (exception, message) {
            // Incrementa contatore tentativi
            seriesData['retry_count'] = retryCount + 1;
            failedSeries.add(seriesData);
            print('[CONSOLE] [offline_service] ❌ Series sync failed: ${series.serieId} - $message');
          },
        );
      } catch (e) {
        print('[CONSOLE] [offline_service] ❌ Error processing series: $e');
        failedSeries.add(seriesData);
      }
    }

    // Salva le serie fallite per retry successivo
    if (failedSeries.isNotEmpty) {
      await _savePendingSeries(failedSeries);
      print('[CONSOLE] [offline_service] ⏳ ${failedSeries.length} series queued for retry');
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
}
