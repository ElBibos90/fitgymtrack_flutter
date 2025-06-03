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

final getIt = GetIt.instance;

class DependencyInjection {
  static Future<void> init() async {
    print('🚨 DEPENDENCY INJECTION STARTED'); // <-- AGGIUNGI QUESTA RIGA
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
    // REPOSITORIES
    // ============================================================================

    print('🔧 [DI] Registering repositories...');

    // Auth Repository
    getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(
      apiClient: getIt<ApiClient>(),
      sessionService: getIt<SessionService>(),
    ));

    // Workout Repository
    getIt.registerLazySingleton<WorkoutRepository>(() => WorkoutRepository(
      apiClient: getIt<ApiClient>(),
      dio: getIt<Dio>(),
    ));

    // ============================================================================
    // WORKOUT BLOCS (SINGLETONS - FIX PRINCIPALE)
    // ============================================================================

    print('🔧 [DI] Registering workout BLoCs as singletons...');

    // 🚀 FIX: Cambiato da registerFactory a registerLazySingleton
    getIt.registerLazySingleton<WorkoutBloc>(() {
      print('🏗️ [DI] Creating WorkoutBloc instance...');
      return WorkoutBloc(
        workoutRepository: getIt<WorkoutRepository>(),
      );
    });

    // 🚀 FIX CRITICO: ActiveWorkoutBloc deve essere SINGLETON
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
    // AUTH BLOCS (FACTORIES - questi possono rimanere factory)
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

    print('✅ [DI] Dependency injection completed successfully!');
  }

  static void reset() {
    print('🔄 [DI] Resetting GetIt...');
    getIt.reset();
  }
}