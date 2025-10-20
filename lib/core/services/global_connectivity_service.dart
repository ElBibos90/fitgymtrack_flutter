// lib/core/services/global_connectivity_service.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/workouts/services/workout_offline_service.dart';
import '../di/dependency_injection.dart';

/// 🌐 Servizio globale per monitorare la connessione e sincronizzare automaticamente
/// Gestisce la sincronizzazione offline a livello di app, non solo durante l'allenamento
class GlobalConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;
  bool _isInitialized = false;
  bool _isSyncing = false; // 🔧 FIX: Aggiunto flag per evitare sincronizzazioni multiple

  /// Inizializza il servizio globale
  void initialize() {
    if (_isInitialized) return;
    
    //debugPrint('[CONSOLE] [global_connectivity] 🌐 Initializing global connectivity service');
    _initializeConnectivityMonitoring();
    _isInitialized = true;
  }

  /// Inizializza il monitoraggio della connessione
  void _initializeConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        _handleConnectivityChange(result);
      },
      onError: (error) {
        //debugPrint('[CONSOLE] [global_connectivity] ❌ Connectivity monitoring error: $error');
      },
    );
  }

  /// Gestisce i cambiamenti di connessione
  void _handleConnectivityChange(ConnectivityResult result) {
    final isOnline = result != ConnectivityResult.none;
    
    //debugPrint('[CONSOLE] [global_connectivity] 📡 Connectivity changed: ${result.name}');

    // Se eravamo offline e ora siamo online, sincronizza
    if (_wasOffline && isOnline) {
      //debugPrint('[CONSOLE] [global_connectivity] 🔄 Connection restored, syncing all offline data...');
      _syncAllOfflineData();
    }

    _wasOffline = !isOnline;
  }

  /// Sincronizza tutti i dati offline disponibili
  Future<void> _syncAllOfflineData() async {
    try {
      // 🔧 FIX: Evita sincronizzazioni multiple simultanee
      if (_isSyncing) {
        //debugPrint('[CONSOLE] [global_connectivity] ⏳ Global sync already in progress, skipping...');
        return;
      }

      _isSyncing = true;
      //debugPrint('[CONSOLE] [global_connectivity] 🔄 Starting global offline sync...');
      
      // 1. Sincronizza dati dell'allenamento attivo (se presente)
      await _syncActiveWorkoutData();
      
      // 2. Sincronizza serie in coda
      await _syncPendingSeries();
      
      // 3. Sincronizza altri dati offline (se implementati in futuro)
      await _syncOtherOfflineData();
      
      //debugPrint('[CONSOLE] [global_connectivity] ✅ Global offline sync completed');
    } catch (e) {
      //debugPrint('[CONSOLE] [global_connectivity] ❌ Error during global sync: $e');
    } finally {
      // 🔧 FIX: Reset flag dopo un delay per permettere retry se necessario
      Future.delayed(const Duration(seconds: 10), () {
        _isSyncing = false;
      });
    }
  }

  /// Sincronizza i dati dell'allenamento attivo
  Future<void> _syncActiveWorkoutData() async {
    try {
      // Ottieni il servizio offline
      final offlineService = getIt<WorkoutOfflineService>();
      
      // Verifica se ci sono dati offline
      final offlineWorkout = await offlineService.loadOfflineWorkout();
      if (offlineWorkout != null) {
        //debugPrint('[CONSOLE] [global_connectivity] 🔄 Found offline workout, syncing...');
        await offlineService.syncOfflineData();
      }
    } catch (e) {
      //debugPrint('[CONSOLE] [global_connectivity] ❌ Error syncing active workout: $e');
    }
  }

  /// Sincronizza le serie in coda
  Future<void> _syncPendingSeries() async {
    try {
      final offlineService = getIt<WorkoutOfflineService>();
      final stats = await offlineService.getOfflineStats();
      
      final pendingCount = stats['pending_series_count'] ?? 0;
      if (pendingCount > 0) {
        //debugPrint('[CONSOLE] [global_connectivity] 🔄 Found $pendingCount pending series, syncing...');
        await offlineService.syncOfflineData();
      }
    } catch (e) {
      //debugPrint('[CONSOLE] [global_connectivity] ❌ Error syncing pending series: $e');
    }
  }

  /// Sincronizza altri dati offline (placeholder per future implementazioni)
  Future<void> _syncOtherOfflineData() async {
    // TODO: Implementare sincronizzazione di altri dati offline
    // - Cache delle schede
    // - Dati profilo
    // - Statistiche offline
    //debugPrint('[CONSOLE] [global_connectivity] 📝 Other offline data sync (placeholder)');
  }

  /// Verifica lo stato attuale della connessione
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      return result != ConnectivityResult.none;
    } catch (e) {
      //debugPrint('[CONSOLE] [global_connectivity] ❌ Error checking connectivity: $e');
      return false;
    }
  }

  /// Forza la sincronizzazione manuale
  Future<void> forceSync() async {
    //debugPrint('[CONSOLE] [global_connectivity] 🔄 Force sync requested');
    await _syncAllOfflineData();
  }

  /// Dispone le risorse
  void dispose() {
    //debugPrint('[CONSOLE] [global_connectivity] 🧹 Disposing global connectivity service');
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _isInitialized = false;
  }
}

