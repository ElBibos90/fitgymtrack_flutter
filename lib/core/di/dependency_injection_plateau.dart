// lib/core/di/dependency_injection_plateau.dart

import 'package:get_it/get_it.dart';
import '../../features/workouts/services/plateau_detector.dart';
import '../../features/workouts/bloc/plateau_bloc.dart';
import '../../features/workouts/models/plateau_models.dart';
import '../../features/workouts/repository/workout_repository.dart';

/// 🎯 DEPENDENCY INJECTION PER SERVIZI PLATEAU
/// ✅ STEP 6 - Registrazione servizi plateau
/// 🔧 FIX: Configurazione con tolleranze ESATTE per rilevamento preciso
class PlateauDependencyInjection {

  /// 🎯 Registra tutti i servizi plateau nel container DI
  static void registerPlateauServices() {
    //print('[CONSOLE] [dependency_injection_plateau]🎯 [PLATEAU DI] Registering plateau services...');

    final getIt = GetIt.instance;

    try {
      // 🔧 FIX CRITICO: Configurazione con tolleranze ESATTE
      _registerPlateauDetector(getIt);
      _registerPlateauBloc(getIt);

      //print('[CONSOLE] [dependency_injection_plateau]✅ [PLATEAU DI] Plateau services registered successfully!');
    } catch (e) {
      //print('[CONSOLE] [dependency_injection_plateau]❌ [PLATEAU DI] Error registering plateau services: $e');
      rethrow;
    }
  }

  /// 🔧 FIX CRITICO: Registra PlateauDetector con configurazione ESATTA
  static void _registerPlateauDetector(GetIt getIt) {
    //print('[CONSOLE] [dependency_injection_plateau]🔧 [PLATEAU DI] Registering PlateauDetector...');

    // 🔧 FIX CRITICO: Usa configurazione con tolleranze ZERO per confronto ESATTO
    final config = PlateauDetectionConfig(
      minSessionsForPlateau: 3,     // Richiede 3 allenamenti consecutivi
      weightTolerance: 0.0,         // 🔧 FIX: ZERO tolleranza - solo valori IDENTICI
      repsTolerance: 0,             // 🔧 FIX: ZERO tolleranza - solo valori IDENTICI
      enableSimulatedPlateau: false, // Disabilitato in produzione
      autoDetectionEnabled: true,   // Auto-detection attiva
    );

    //print('[CONSOLE] [dependency_injection_plateau]🔧 [PLATEAU CONFIG] Using EXACT matching:');
    //print('[CONSOLE] [dependency_injection_plateau]    Min sessions: ${config.minSessionsForPlateau}');
    //print('[CONSOLE] [dependency_injection_plateau]    Weight tolerance: ${config.weightTolerance} (EXACT)');
    //print('[CONSOLE] [dependency_injection_plateau]    Reps tolerance: ${config.repsTolerance} (EXACT)');
    //print('[CONSOLE] [dependency_injection_plateau]    Simulated plateau: ${config.enableSimulatedPlateau}');

    getIt.registerLazySingleton<PlateauDetector>(
          () => PlateauDetector(config: config),
    );

    //print('[CONSOLE] [dependency_injection_plateau]✅ [PLATEAU DI] PlateauDetector registered with EXACT config');
  }

  /// Registra PlateauBloc come singleton
  static void _registerPlateauBloc(GetIt getIt) {
    //print('[CONSOLE] [dependency_injection_plateau]🔧 [PLATEAU DI] Registering PlateauBloc as singleton...');

    // Verifica che le dipendenze siano disponibili
    if (!getIt.isRegistered<WorkoutRepository>()) {
      throw Exception('[PLATEAU DI] WorkoutRepository must be registered before PlateauBloc');
    }

    getIt.registerLazySingleton<PlateauBloc>(
          () {
        //print('[CONSOLE] [dependency_injection_plateau]🏗️ [PLATEAU DI] Creating PlateauBloc instance...');
        return PlateauBloc(
          workoutRepository: getIt<WorkoutRepository>(),
        );
      },
    );

    //print('[CONSOLE] [dependency_injection_plateau]✅ [PLATEAU DI] PlateauBloc registered as singleton');
  }

  /// Verifica che tutti i servizi plateau siano registrati
  static bool arePlateauServicesRegistered() {
    final getIt = GetIt.instance;
    return getIt.isRegistered<PlateauDetector>() && getIt.isRegistered<PlateauBloc>();
  }

  /// Ottiene informazioni sui servizi plateau registrati
  static Map<String, dynamic> getPlateauServicesInfo() {
    final getIt = GetIt.instance;

    return {
      'plateau_detector_registered': getIt.isRegistered<PlateauDetector>(),
      'plateau_bloc_registered': getIt.isRegistered<PlateauBloc>(),
      'services_ready': arePlateauServicesRegistered(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// 🎯 Utility per verificare lo stato del sistema plateau
class PlateauSystemChecker {

  /// Verifica che tutti i servizi plateau siano correttamente registrati
  static bool checkPlateauSystemHealth() {
    try {
      final getIt = GetIt.instance;

      // Verifica registrazione servizi
      if (!getIt.isRegistered<PlateauDetector>()) {
        //print('[CONSOLE] [dependency_injection_plateau]❌ [PLATEAU CHECK] PlateauDetector not registered');
        return false;
      }

      if (!getIt.isRegistered<PlateauBloc>()) {
        //print('[CONSOLE] [dependency_injection_plateau]❌ [PLATEAU CHECK] PlateauBloc not registered');
        return false;
      }

      // Verifica dipendenze
      if (!getIt.isRegistered<WorkoutRepository>()) {
        //print('[CONSOLE] [dependency_injection_plateau]❌ [PLATEAU CHECK] WorkoutRepository not registered (required dependency)');
        return false;
      }

      // Test istanziazione servizi
      try {
        final detector = getIt<PlateauDetector>();
        final bloc = getIt<PlateauBloc>();

        //print('[CONSOLE] [dependency_injection_plateau]✅ [PLATEAU CHECK] All services healthy');
        //print('[CONSOLE] [dependency_injection_plateau]    PlateauDetector config: ${detector.config.description}');
        //print('[CONSOLE] [dependency_injection_plateau]    PlateauBloc state: ${bloc.state.runtimeType}');

        return true;
      } catch (e) {
        //print('[CONSOLE] [dependency_injection_plateau]❌ [PLATEAU CHECK] Error instantiating services: $e');
        return false;
      }

    } catch (e) {
      //print('[CONSOLE] [dependency_injection_plateau]❌ [PLATEAU CHECK] Health check failed: $e');
      return false;
    }
  }

  /// Verifica che tutti i servizi plateau siano registrati (versione leggera)
  static bool arePlateauServicesRegistered() {
    final getIt = GetIt.instance;
    return getIt.isRegistered<PlateauDetector>() && getIt.isRegistered<PlateauBloc>();
  }

  /// Ottiene informazioni sui servizi plateau registrati
  static Map<String, dynamic> getPlateauServicesInfo() {
    final getIt = GetIt.instance;

    return {
      'plateau_detector_registered': getIt.isRegistered<PlateauDetector>(),
      'plateau_bloc_registered': getIt.isRegistered<PlateauBloc>(),
      'services_ready': arePlateauServicesRegistered(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// 🎯 Helper per configurazioni plateau comuni
class PlateauConfigurationHelper {

  /// 🔧 FIX CRITICO: Configurazione per produzione con confronto ESATTO
  static PlateauDetectionConfig get productionConfig => PlateauDetectionConfig(
    minSessionsForPlateau: 3,
    weightTolerance: 0.0,         // 🔧 FIX: ESATTO
    repsTolerance: 0,             // 🔧 FIX: ESATTO
    enableSimulatedPlateau: false,
    autoDetectionEnabled: true,
  );

  /// 🔧 FIX: Configurazione per testing/sviluppo con confronto ESATTO
  static PlateauDetectionConfig get developmentConfig => PlateauDetectionConfig(
    minSessionsForPlateau: 2,     // Soglia più bassa per test
    weightTolerance: 0.0,         // 🔧 FIX: ESATTO anche per sviluppo
    repsTolerance: 0,             // 🔧 FIX: ESATTO anche per sviluppo
    enableSimulatedPlateau: true, // Abilita plateau simulati
    autoDetectionEnabled: true,
  );

  /// 🔧 FIX: Configurazione per debugging con confronto ESATTO
  static PlateauDetectionConfig get debugConfig => PlateauDetectionConfig(
    minSessionsForPlateau: 1,     // Molto sensibile per debug
    weightTolerance: 0.0,         // 🔧 FIX: ESATTO per debug
    repsTolerance: 0,             // 🔧 FIX: ESATTO per debug
    enableSimulatedPlateau: true,
    autoDetectionEnabled: true,
  );

  /// Configurazione disabilitata (per disattivare il sistema)
  static PlateauDetectionConfig get disabledConfig => PlateauDetectionConfig(
    minSessionsForPlateau: 999, // Praticamente impossibile
    weightTolerance: 0.0,
    repsTolerance: 0,
    enableSimulatedPlateau: false,
    autoDetectionEnabled: false,
  );

  /// Ottiene la configurazione basata sull'ambiente
  static PlateauDetectionConfig getConfigForEnvironment(String environment) {
    switch (environment.toLowerCase()) {
      case 'production':
      case 'prod':
        return productionConfig;
      case 'development':
      case 'dev':
        return developmentConfig;
      case 'debug':
        return debugConfig;
      case 'disabled':
        return disabledConfig;
      default:
        return productionConfig;
    }
  }

  /// 🔧 FIX: Crea configurazione personalizzata con tolleranze ESATTE
  static PlateauDetectionConfig createExactConfig({
    int minSessions = 3,
    bool enableSimulated = false,
    bool autoDetection = true,
  }) {
    return PlateauDetectionConfig(
      minSessionsForPlateau: minSessions,
      weightTolerance: 0.0,         // 🔧 FIX: SEMPRE esatto
      repsTolerance: 0,             // 🔧 FIX: SEMPRE esatto
      enableSimulatedPlateau: enableSimulated,
      autoDetectionEnabled: autoDetection,
    );
  }

  /// Stampa informazioni sulla configurazione attiva
  static void logActiveConfiguration() {
    final getIt = GetIt.instance;

    if (getIt.isRegistered<PlateauDetector>()) {
      final detector = getIt<PlateauDetector>();
      final config = detector.config;

      //print('[CONSOLE] [dependency_injection_plateau]📋 [ACTIVE CONFIG] Plateau Detection Configuration:');
      //print('[CONSOLE] [dependency_injection_plateau]    Min sessions: ${config.minSessionsForPlateau}');
      //print('[CONSOLE] [dependency_injection_plateau]    Weight tolerance: ${config.weightTolerance} (${config.weightTolerance == 0.0 ? 'EXACT' : 'TOLERANT'})');
      //print('[CONSOLE] [dependency_injection_plateau]    Reps tolerance: ${config.repsTolerance} (${config.repsTolerance == 0 ? 'EXACT' : 'TOLERANT'})');
      //print('[CONSOLE] [dependency_injection_plateau]    Simulated plateau: ${config.enableSimulatedPlateau}');
      //print('[CONSOLE] [dependency_injection_plateau]    Auto detection: ${config.autoDetectionEnabled}');
      //print('[CONSOLE] [dependency_injection_plateau]    Description: ${config.description}');
    } else {
      //print('[CONSOLE] [dependency_injection_plateau]⚠️ [CONFIG] PlateauDetector not registered - cannot show configuration');
    }
  }
}

/// 🎯 Plateau Service Factory - Crea istanze con configurazioni specifiche
class PlateauServiceFactory {

  /// Crea PlateauDetector con configurazione personalizzata
  static PlateauDetector createDetector({
    int minSessions = 3,
    double weightTolerance = 0.0,     // 🔧 FIX: Default ESATTO
    int repsTolerance = 0,            // 🔧 FIX: Default ESATTO
    bool enableSimulated = false,
    bool autoDetection = true,
  }) {
    final config = PlateauDetectionConfig(
      minSessionsForPlateau: minSessions,
      weightTolerance: weightTolerance,
      repsTolerance: repsTolerance,
      enableSimulatedPlateau: enableSimulated,
      autoDetectionEnabled: autoDetection,
    );

    //print('[CONSOLE] [dependency_injection_plateau]🏭 [FACTORY] Creating PlateauDetector with config: ${config.description}');
    return PlateauDetector(config: config);
  }

  /// Crea PlateauBloc con dipendenze specifiche
  static PlateauBloc createBloc({
    required WorkoutRepository workoutRepository,
  }) {
    //print('[CONSOLE] [dependency_injection_plateau]🏭 [FACTORY] Creating PlateauBloc...');
    return PlateauBloc(
      workoutRepository: workoutRepository,
    );
  }
}

/// 🎯 Plateau System Diagnostics - Diagnostica per debugging
class PlateauSystemDiagnostics {

  /// Esegue diagnostica completa del sistema plateau
  static Map<String, dynamic> runFullDiagnostics() {
    final diagnostics = <String, dynamic>{};
    final getIt = GetIt.instance;

    try {
      // Verifica registrazione servizi
      diagnostics['services_registered'] = {
        'plateau_detector': getIt.isRegistered<PlateauDetector>(),
        'plateau_bloc': getIt.isRegistered<PlateauBloc>(),
        'workout_repository': getIt.isRegistered<WorkoutRepository>(),
      };

      // Test configurazione
      if (getIt.isRegistered<PlateauDetector>()) {
        final detector = getIt<PlateauDetector>();
        diagnostics['configuration'] = {
          'min_sessions': detector.config.minSessionsForPlateau,
          'weight_tolerance': detector.config.weightTolerance,
          'reps_tolerance': detector.config.repsTolerance,
          'simulated_enabled': detector.config.enableSimulatedPlateau,
          'auto_detection': detector.config.autoDetectionEnabled,
          'is_exact_matching': detector.config.weightTolerance == 0.0 && detector.config.repsTolerance == 0,
        };
      }

      // Test stato BLoC
      if (getIt.isRegistered<PlateauBloc>()) {
        final bloc = getIt<PlateauBloc>();
        diagnostics['bloc_state'] = {
          'current_state': bloc.state.runtimeType.toString(),
          'is_closed': bloc.isClosed,
        };
      }

      diagnostics['health_check'] = PlateauSystemChecker.checkPlateauSystemHealth();
      diagnostics['timestamp'] = DateTime.now().toIso8601String();
      diagnostics['status'] = 'success';

    } catch (e) {
      diagnostics['status'] = 'error';
      diagnostics['error'] = e.toString();
      diagnostics['timestamp'] = DateTime.now().toIso8601String();
    }

    return diagnostics;
  }

  /// Stampa report diagnostico completo
  static void printDiagnosticsReport() {
    final diagnostics = runFullDiagnostics();

    //print('[CONSOLE] [dependency_injection_plateau]🔍 [DIAGNOSTICS] === PLATEAU SYSTEM DIAGNOSTICS REPORT ===');
    //print('[CONSOLE] [dependency_injection_plateau]Status: ${diagnostics['status']}');
    //print('[CONSOLE] [dependency_injection_plateau]Timestamp: ${diagnostics['timestamp']}');

    if (diagnostics['services_registered'] != null) {
      final services = diagnostics['services_registered'] as Map<String, dynamic>;
      //print('[CONSOLE] [dependency_injection_plateau]Services:');
      services.forEach((service, registered) {
        //print('[CONSOLE] [dependency_injection_plateau]  $service: ${registered ? '✅' : '❌'}');
      });
    }

    if (diagnostics['configuration'] != null) {
      final config = diagnostics['configuration'] as Map<String, dynamic>;
      //print('[CONSOLE] [dependency_injection_plateau]Configuration:');
      config.forEach((key, value) {
        //print('[CONSOLE] [dependency_injection_plateau]  $key: $value');
      });
    }

    //print('[CONSOLE] [dependency_injection_plateau]Health Check: ${diagnostics['health_check'] ? '✅ HEALTHY' : '❌ UNHEALTHY'}');
    //print('[CONSOLE] [dependency_injection_plateau]=== END DIAGNOSTICS REPORT ===');
  }
}