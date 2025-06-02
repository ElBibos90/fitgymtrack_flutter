// lib/core/di/dependency_injection.dart
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../services/session_service.dart';
import '../network/dio_client.dart';
import '../network/api_client.dart';

// Auth feature
import '../../features/auth/repository/auth_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';

// TODO: Uncomment when we create the physical files
// Workout features
 import '../../features/workouts/repository/workout_repository.dart';
// import '../../features/workouts/bloc/workout_plans_bloc.dart';
// import '../../features/exercises/bloc/exercises_bloc.dart';
// import '../../features/stats/bloc/stats_bloc.dart';

import '../../features/workouts/bloc/workout_bloc.dart';
import '../../features/workouts/bloc/active_workout_bloc.dart';
import '../../features/workouts/bloc/workout_history_bloc.dart';


final getIt = GetIt.instance;

class DependencyInjection {
  static Future<void> init() async {
    // ============================================================================
    // CORE SERVICES
    // ============================================================================

    getIt.registerLazySingleton<SessionService>(() => SessionService());

    getIt.registerLazySingleton(() => DioClient.getInstance(
      sessionService: getIt<SessionService>(),
    ));

    getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt()));

    // ============================================================================
    // REPOSITORIES
    // ============================================================================

    // Auth Repository
    getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(
      apiClient: getIt<ApiClient>(),
      sessionService: getIt<SessionService>(),
    ));

    // ============================================================================
// ============================================================================
// WORKOUT FEATURE
// ============================================================================

    getIt.registerLazySingleton<WorkoutRepository>(() => WorkoutRepository(
      apiClient: getIt<ApiClient>(),
      dio: getIt<Dio>(), // ✅ NUOVO: Passa anche Dio
    ));

// Resto invariato...
    getIt.registerFactory<WorkoutBloc>(() => WorkoutBloc(
      workoutRepository: getIt<WorkoutRepository>(),
    ));

    getIt.registerFactory<ActiveWorkoutBloc>(() => ActiveWorkoutBloc(
      workoutRepository: getIt<WorkoutRepository>(),
    ));

    getIt.registerFactory<WorkoutHistoryBloc>(() => WorkoutHistoryBloc(
      workoutRepository: getIt<WorkoutRepository>(),
    ));

    // ============================================================================
    // AUTH BLOCS
    // ============================================================================

    getIt.registerFactory<AuthBloc>(() => AuthBloc(
      authRepository: getIt<AuthRepository>(),
    ));

    getIt.registerFactory<RegisterBloc>(() => RegisterBloc(
      authRepository: getIt<AuthRepository>(),
    ));

    getIt.registerFactory<PasswordResetBloc>(() => PasswordResetBloc(
      authRepository: getIt<AuthRepository>(),
    ));

  }

  static void reset() {
    getIt.reset();
  }
}