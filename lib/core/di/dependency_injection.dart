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

final getIt = GetIt.instance;

class DependencyInjection {
  /// Inizializzazione dei servizi di dependency injection
  /// Ora usa SOLO repository reali - niente più mock
  static Future<void> init() async {
    print('🚨 DEPENDENCY INJECTION STARTED (REAL REPOSITORIES ONLY)');
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

    print('✅ [DI] Dependency injection completed successfully!');
  }

  /// Reset completo di GetIt
  static void reset() {
    print('🔄 [DI] Resetting GetIt completely...');
    getIt.reset();
  }

  /// Reinizializza con repository reali
  static Future<void> reinitialize() async {
    print('🔄 [DI] Reinitializing with real repositories...');
    reset();
    await Future.delayed(const Duration(milliseconds: 200));
    await init();
  }
}