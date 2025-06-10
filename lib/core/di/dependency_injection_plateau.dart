// lib/core/di/dependency_injection_plateau.dart
import 'package:get_it/get_it.dart';

// 🎯 STEP 6: Plateau system dependency injection
import '../../features/workouts/bloc/plateau_bloc.dart';
import '../../features/workouts/services/plateau_detector.dart';
import '../../features/workouts/models/plateau_models.dart';
import '../../features/workouts/repository/workout_repository.dart';

/// 🎯 STEP 6: Estensione del sistema DI per il plateau detection
/// Registra tutti i servizi e BLoC necessari per il sistema plateau
class PlateauDependencyInjection {

  /// Registra i servizi plateau nel container DI
  static void registerPlateauServices() {
    final getIt = GetIt.instance;

    print('[CONSOLE] [dependency_injection_plateau]🎯 [PLATEAU DI] Registering plateau services...');

    // ============================================================================
    // PLATEAU DETECTOR SERVICE
    // ============================================================================

    print('[CONSOLE] [dependency_injection_plateau]🔧 [PLATEAU DI] Registering PlateauDetector...');
    getIt.registerLazySingleton<PlateauDetector>(() {
      final config = createDefaultPlateauConfig();
      print('[CONSOLE] [dependency_injection_plateau]🎯 [PLATEAU DI] PlateauDetector config: ${config.toJson()}');
      return PlateauDetector(config: config);
    });

    // ============================================================================
    // PLATEAU BLOC (SINGLETON)
    // ============================================================================

    print('[CONSOLE] [dependency_injection_plateau]🔧 [PLATEAU DI] Registering PlateauBloc as singleton...');
    getIt.registerLazySingleton<PlateauBloc>(() {
      print('[CONSOLE] [dependency_injection_plateau]🏗️ [PLATEAU DI] Creating PlateauBloc instance...');
      return PlateauBloc(
        workoutRepository: getIt<WorkoutRepository>(),
      );
    });

    print('[CONSOLE] [dependency_injection_plateau]✅ [PLATEAU DI] Plateau services registered successfully!');
  }

  /// Aggiorna la configurazione del plateau detector
  static void updatePlateauConfig(PlateauDetectionConfig newConfig) {
    final getIt = GetIt.instance;

    if (getIt.isRegistered<PlateauDetector>()) {
      print('[CONSOLE] [dependency_injection_plateau]🔄 [PLATEAU DI] Updating PlateauDetector configuration...');

      // Riregistra con nuova configurazione
      getIt.unregister<PlateauDetector>();
      getIt.registerLazySingleton<PlateauDetector>(() => PlateauDetector(config: newConfig));

      // Aggiorna anche il BLoC
      if (getIt.isRegistered<PlateauBloc>()) {
        final plateauBloc = getIt<PlateauBloc>();
        plateauBloc.updateConfig(newConfig);
      }

      print('[CONSOLE] [dependency_injection_plateau]✅ [PLATEAU DI] PlateauDetector configuration updated');
    }
  }

  /// Reset dei servizi plateau (per testing)
  static void resetPlateauServices() {
    final getIt = GetIt.instance;

    print('[CONSOLE] [dependency_injection_plateau]🔄 [PLATEAU DI] Resetting plateau services...');

    if (getIt.isRegistered<PlateauBloc>()) {
      final plateauBloc = getIt<PlateauBloc>();
      plateauBloc.resetState();
      getIt.unregister<PlateauBloc>();
    }

    if (getIt.isRegistered<PlateauDetector>()) {
      getIt.unregister<PlateauDetector>();
    }

    print('[CONSOLE] [dependency_injection_plateau]✅ [PLATEAU DI] Plateau services reset');
  }

  /// Verifica se i servizi plateau sono registrati
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

  /// Configurazione per produzione
  static PlateauDetectionConfig get productionConfig => PlateauDetectionConfig(
    minSessionsForPlateau: 3,
    weightTolerance: 1.0,
    repsTolerance: 1,
    enableSimulatedPlateau: false,
    autoDetectionEnabled: true,
  );

  /// Configurazione per testing/sviluppo
  static PlateauDetectionConfig get developmentConfig => PlateauDetectionConfig(
    minSessionsForPlateau: 2, // Soglia più bassa per test
    weightTolerance: 1.5,
    repsTolerance: 1,
    enableSimulatedPlateau: true, // Abilita plateau simulati
    autoDetectionEnabled: true,
  );

  /// Configurazione per debugging (molto sensibile)
  static PlateauDetectionConfig get debugConfig => PlateauDetectionConfig(
    minSessionsForPlateau: 1, // Molto sensibile
    weightTolerance: 0.5,
    repsTolerance: 0,
    enableSimulatedPlateau: true,
    autoDetectionEnabled: true,
  );

  /// Configurazione disabilitata
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
}

/// 🎯 Utility per verificare lo stato del sistema plateau
class PlateauSystemChecker {

  /// Verifica che tutti i servizi plateau siano correttamente registrati
  static bool checkPlateauSystemHealth() {
    try {
      final getIt = GetIt.instance;

      // Verifica registrazione servizi
      if (!getIt.isRegistered<PlateauDetector>()) {
        print('[CONSOLE] [dependency_injection_plateau]❌ [PLATEAU CHECK] PlateauDetector not registered');
        return false;
      }

      if (!getIt.isRegistered<PlateauBloc>()) {
        print('[CONSOLE] [dependency_injection_plateau]❌ [PLATEAU CHECK] PlateauBloc not registered');
        return false;
      }

      // Verifica dipendenze
      if (!getIt.isRegistered<WorkoutRepository>()) {
        print('[CONSOLE] [dependency_injection_plateau]❌ [PLATEAU CHECK] WorkoutRepository not registered (required dependency)');
        return false;
      }

      // Test istanziazione
      final plateauDetector = getIt<PlateauDetector>();
      final plateauBloc = getIt<PlateauBloc>();

      print('[CONSOLE] [dependency_injection_plateau]✅ [PLATEAU CHECK] All plateau services are healthy');
      print('[CONSOLE] [dependency_injection_plateau]🎯 [PLATEAU CHECK] PlateauDetector config: ${plateauDetector.config.toJson()}');
      print('[CONSOLE] [dependency_injection_plateau]🎯 [PLATEAU CHECK] PlateauBloc state: ${plateauBloc.state.runtimeType}');

      return true;

    } catch (e) {
      print('[CONSOLE] [dependency_injection_plateau]💥 [PLATEAU CHECK] Error checking plateau system health: $e');
      return false;
    }
  }

  /// Report dettagliato dello stato del sistema
  static Map<String, dynamic> getSystemReport() {
    final getIt = GetIt.instance;

    return {
      'system_healthy': checkPlateauSystemHealth(),
      'services_info': PlateauDependencyInjection.getPlateauServicesInfo(),
      'detector_registered': getIt.isRegistered<PlateauDetector>(),
      'bloc_registered': getIt.isRegistered<PlateauBloc>(),
      'workout_repository_registered': getIt.isRegistered<WorkoutRepository>(),
      'check_timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// 🎯 STEP 6: Crea configurazione plateau di default
PlateauDetectionConfig createDefaultPlateauConfig({bool enableTesting = false}) {
  if (enableTesting) {
    return PlateauConfigurationHelper.developmentConfig;
  } else {
    return PlateauConfigurationHelper.productionConfig;
  }
}