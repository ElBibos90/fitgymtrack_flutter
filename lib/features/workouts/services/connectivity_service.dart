// lib/features/workouts/services/connectivity_service.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../bloc/active_workout_bloc.dart';

/// 🚀 Servizio per monitorare la connessione e sincronizzare automaticamente
class ConnectivityService {
  final ActiveWorkoutBloc _workoutBloc;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;
  bool _isSyncing = false; // 🔧 FIX: Aggiunto flag per evitare sincronizzazioni multiple

  ConnectivityService({required ActiveWorkoutBloc workoutBloc})
      : _workoutBloc = workoutBloc {
    _initializeConnectivityMonitoring();
  }

  /// Inizializza il monitoraggio della connessione
  void _initializeConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        _handleConnectivityChange(result);
      },
      onError: (error) {
        //debugPrint('[CONSOLE] [connectivity_service] ❌ Connectivity monitoring error: $error');
      },
    );
  }

  /// Gestisce i cambiamenti di connessione
  void _handleConnectivityChange(ConnectivityResult result) {
    final isOnline = result != ConnectivityResult.none;
    
    //debugPrint('[CONSOLE] [connectivity_service] 📡 Connectivity changed: ${result.name}');

    // Se eravamo offline e ora siamo online, sincronizza
    if (_wasOffline && isOnline) {
      //debugPrint('[CONSOLE] [connectivity_service] 🔄 Connection restored, syncing offline data...');
      _syncOfflineData();
    }

    _wasOffline = !isOnline;
  }

  /// Sincronizza i dati offline
  Future<void> _syncOfflineData() async {
    try {
      // 🔧 FIX: Evita sincronizzazioni multiple simultanee
      if (_isSyncing) {
        //debugPrint('[CONSOLE] [connectivity_service] ⏳ Sync already in progress, skipping...');
        return;
      }

      _isSyncing = true;

      // Verifica se ci sono dati da sincronizzare
      final stats = await _workoutBloc.getOfflineStats();
      final hasPendingData = stats['pending_series_count'] != null && 
                            stats['pending_series_count'] > 0;

      if (hasPendingData) {
        //debugPrint('[CONSOLE] [connectivity_service] 🔄 Found ${stats['pending_series_count']} pending series, syncing...');
        _workoutBloc.syncOfflineData();
      } else {
        //debugPrint('[CONSOLE] [connectivity_service] ✅ No pending data to sync');
      }
    } catch (e) {
      //debugPrint('[CONSOLE] [connectivity_service] ❌ Error syncing offline data: $e');
    } finally {
      // 🔧 FIX: Reset flag dopo un delay per permettere retry se necessario
      Future.delayed(const Duration(seconds: 5), () {
        _isSyncing = false;
      });
    }
  }

  /// Verifica lo stato attuale della connessione
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      return result != ConnectivityResult.none;
    } catch (e) {
      //debugPrint('[CONSOLE] [connectivity_service] ❌ Error checking connectivity: $e');
      return false;
    }
  }

  /// Dispone le risorse
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}
