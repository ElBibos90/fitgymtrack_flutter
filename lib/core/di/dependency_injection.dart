// lib/core/di/dependency_injection.dart
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../services/session_service.dart';
import '../network/dio_client.dart';
import '../network/api_client.dart';

// Auth feature
import '../../features/auth/repository/auth_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';

// Workout features
import '../../features/workouts/repository/workout_repository.dart';
import '../../features/workouts/bloc/workout_bloc.dart';
import '../../features/workouts/bloc/active_workout_bloc.dart';
import '../../features/workouts/bloc/workout_history_bloc.dart';

import '../di/dependency_injection_plateau.dart';
import '../../features/subscription/di/subscription_dependency_injection.dart';
import '../../features/payments/di/stripe_dependency_injection.dart';

final getIt = GetIt.instance;

class DependencyInjection {
  /// Inizializzazione dei servizi di dependency injection
  /// Ora usa SOLO repository reali - niente più mock
  static Future<void> init() async {
    print('🚨 DEPENDENCY INJECTION STARTED (REAL REPOSITORIES ONLY + STRIPE)');
    print('🔧 [DI] Starting dependency injection initialization...');

    // ============================================================================
    // CORE SERVICES
    // ============================================================================

    print('🔧 [DI] Registering core services...');
    getIt.registerLazySingleton<SessionService>(() => SessionService());

    getIt.registerLazySingleton(() => DioClient.getInstance(
      sessionService: getIt<SessionService>(),
    ));

    getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt()));

    // ============================================================================
    // REPOSITORIES (SOLO REALI)
    // ============================================================================

    print('🔧 [DI] Registering repositories...');

    // Auth Repository
    getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(
      apiClient: getIt<ApiClient>(),
      sessionService: getIt<SessionService>(),
    ));

    // 🔧 FIX: Workout Repository - SOLO REAL
    print('🔧 [DI] Registering REAL WorkoutRepository...');
    getIt.registerLazySingleton<WorkoutRepository>(() => WorkoutRepository(
      apiClient: getIt<ApiClient>(),
      dio: getIt<Dio>(),
    ));

    // ============================================================================
    // WORKOUT BLOCS (SINGLETONS)
    // ============================================================================

    print('🔧 [DI] Registering workout BLoCs as singletons...');

    getIt.registerLazySingleton<WorkoutBloc>(() {
      print('🏗️ [DI] Creating WorkoutBloc instance...');
      return WorkoutBloc(
        workoutRepository: getIt<WorkoutRepository>(),
      );
    });

    getIt.registerLazySingleton<ActiveWorkoutBloc>(() {
      print('🏗️ [DI] Creating ActiveWorkoutBloc instance...');
      return ActiveWorkoutBloc(
        workoutRepository: getIt<WorkoutRepository>(),
      );
    });

    getIt.registerLazySingleton<WorkoutHistoryBloc>(() {
      print('🏗️ [DI] Creating WorkoutHistoryBloc instance...');
      return WorkoutHistoryBloc(
        workoutRepository: getIt<WorkoutRepository>(),
      );
    });

    // ============================================================================
    // AUTH BLOCS (FACTORIES)
    // ============================================================================

    print('🔧 [DI] Registering auth BLoCs as factories...');

    getIt.registerFactory<AuthBloc>(() => AuthBloc(
      authRepository: getIt<AuthRepository>(),
    ));

    getIt.registerFactory<RegisterBloc>(() => RegisterBloc(
      authRepository: getIt<AuthRepository>(),
    ));

    getIt.registerFactory<PasswordResetBloc>(() => PasswordResetBloc(
      authRepository: getIt<AuthRepository>(),
    ));

    // ============================================================================
    // 🎯 PLATEAU SERVICES (STEP 7)
    // ============================================================================

    print('🔧 [DI] Registering plateau services...');
    PlateauDependencyInjection.registerPlateauServices();

    // ============================================================================
    // 💳 SUBSCRIPTION SERVICES
    // ============================================================================

    print('🔧 [DI] Registering subscription services...');
    try {
      // 🔧 FIX: Subscription services con repository reali
      SubscriptionDependencyInjection.registerSubscriptionServices();
      print('✅ [DI] Subscription services registered successfully!');
    } catch (e) {
      print('❌ [DI] ERROR registering subscription services: $e');
      rethrow;
    }

    // ============================================================================
    // 💳 STRIPE PAYMENT SERVICES
    // ============================================================================

    print('🔧 [DI] Registering Stripe payment services...');
    try {
      StripeDependencyInjection.registerStripeServices();
      print('✅ [DI] Stripe services registered successfully!');
    } catch (e) {
      print('❌ [DI] ERROR registering Stripe services: $e');
      rethrow;
    }

    print('✅ [DI] Dependency injection completed successfully!');

    // ============================================================================
    // DIAGNOSTIC INFO
    // ============================================================================

    _printDiagnosticInfo();
  }

  /// Stampa informazioni diagnostiche sui servizi registrati
  static void _printDiagnosticInfo() {
    print('');
    print('🔍 [DI] DIAGNOSTIC INFO:');
    print('🔍 [DI] ════════════════════════════════════════');
    print('🔍 [DI] Core services registered: ${_countCoreServices()}');
    print('🔍 [DI] Repository services: ${_countRepositories()}');
    print('🔍 [DI] BLoC services: ${_countBlocs()}');
    print('🔍 [DI] Plateau services: ${PlateauDependencyInjection.arePlateauServicesRegistered()}');
    print('🔍 [DI] Subscription services: ${SubscriptionDependencyInjection.areSubscriptionServicesRegistered()}');
    print('🔍 [DI] Stripe services: ${StripeDependencyInjection.areStripeServicesRegistered()}');
    print('🔍 [DI] Total services registered: ${_getTotalServicesCount()}');
    print('🔍 [DI] ════════════════════════════════════════');
    print('');
  }

  static int _countCoreServices() {
    int count = 0;
    if (getIt.isRegistered<SessionService>()) count++;
    if (getIt.isRegistered<Dio>()) count++;
    if (getIt.isRegistered<ApiClient>()) count++;
    return count;
  }

  static int _countRepositories() {
    int count = 0;
    if (getIt.isRegistered<AuthRepository>()) count++;
    if (getIt.isRegistered<WorkoutRepository>()) count++;
    return count;
  }

  static int _countBlocs() {
    int count = 0;
    // Nota: i factory non sono conteggiati in allReady()
    // ma possiamo verificare se sono registrati
    try {
      getIt<AuthBloc>();
      count++;
    } catch (e) {}

    if (getIt.isRegistered<WorkoutBloc>()) count++;
    if (getIt.isRegistered<ActiveWorkoutBloc>()) count++;
    if (getIt.isRegistered<WorkoutHistoryBloc>()) count++;

    return count;
  }

  static int _getTotalServicesCount() {
    return _countCoreServices() + _countRepositories() + _countBlocs();
  }

  /// Verifica la salute generale del sistema DI
  static bool checkSystemHealth() {
    try {
      // Verifica servizi core
      getIt<SessionService>();
      getIt<Dio>();
      getIt<ApiClient>();

      // Verifica repository
      getIt<AuthRepository>();
      getIt<WorkoutRepository>();

      // Verifica BLoC principali
      getIt<WorkoutBloc>();
      getIt<ActiveWorkoutBloc>();

      // Verifica sistemi aggiuntivi
      final plateauHealthy = PlateauDependencyInjection.arePlateauServicesRegistered();
      final subscriptionHealthy = SubscriptionDependencyInjection.areSubscriptionServicesRegistered();
      final stripeHealthy = StripeDependencyInjection.areStripeServicesRegistered();

      print('✅ [DI] System health check passed');
      print('🎯 [DI] Plateau system: ${plateauHealthy ? "✅" : "❌"}');
      print('🎯 [DI] Subscription system: ${subscriptionHealthy ? "✅" : "❌"}');
      print('🎯 [DI] Stripe system: ${stripeHealthy ? "✅" : "❌"}');

      return plateauHealthy && subscriptionHealthy && stripeHealthy;

    } catch (e) {
      print('❌ [DI] System health check failed: $e');
      return false;
    }
  }

  /// Ottiene un report completo del sistema
  static Map<String, dynamic> getSystemReport() {
    return {
      'system_healthy': checkSystemHealth(),
      'core_services': _countCoreServices(),
      'repositories': _countRepositories(),
      'blocs': _countBlocs(),
      'total_services': _getTotalServicesCount(),
      'plateau_info': PlateauDependencyInjection.getPlateauServicesInfo(),
      'subscription_info': SubscriptionDependencyInjection.getSubscriptionServicesInfo(),
      'stripe_info': StripeDependencyInjection.getStripeServicesInfo(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Reset completo di GetIt
  static void reset() {
    print('🔄 [DI] Resetting GetIt completely...');
    getIt.reset();
  }

  /// Reinizializza con repository reali
  static Future<void> reinitialize() async {
    print('🔄 [DI] Reinitializing with real repositories and Stripe...');
    reset();
    await Future.delayed(const Duration(milliseconds: 200));
    await init();
  }

  /// Reset selettivo solo dei servizi Stripe (per testing)
  static void resetStripeOnly() {
    print('🔄 [DI] Resetting only Stripe services...');
    StripeDependencyInjection.resetStripeServices();
  }

  /// Reinizializza solo i servizi Stripe
  static Future<void> reinitializeStripeOnly() async {
    print('🔄 [DI] Reinitializing only Stripe services...');
    await StripeDependencyInjection.reinitializeStripeServices();
  }
}