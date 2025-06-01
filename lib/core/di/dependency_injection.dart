// lib/core/di/dependency_injection.dart
import 'package:get_it/get_it.dart';
import '../services/session_service.dart';
import '../network/dio_client.dart';
import '../network/api_client.dart';

// Auth feature
import '../../features/auth/repository/auth_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';

// TODO: Uncomment when we create the physical files
// Workout features
// import '../../features/workouts/repository/workout_repository.dart';
// import '../../features/workouts/bloc/workout_plans_bloc.dart';
// import '../../features/workouts/bloc/active_workout_bloc.dart';
// import '../../features/exercises/bloc/exercises_bloc.dart';
// import '../../features/stats/bloc/stats_bloc.dart';

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

    // TODO: Uncomment when we create WorkoutRepository
    // Workout Repository
    // getIt.registerLazySingleton<WorkoutRepository>(() => WorkoutRepository(
    //   apiClient: getIt<ApiClient>(),
    //   sessionService: getIt<SessionService>(),
    // ));

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

    // TODO: Uncomment when we create the BLoC files
    // ============================================================================
    // WORKOUT BLOCS
    // ============================================================================

    // getIt.registerFactory<WorkoutPlansBloc>(() => WorkoutPlansBloc(
    //   workoutRepository: getIt<WorkoutRepository>(),
    // ));

    // getIt.registerFactory<ActiveWorkoutBloc>(() => ActiveWorkoutBloc(
    //   workoutRepository: getIt<WorkoutRepository>(),
    // ));

    // ============================================================================
    // EXERCISE BLOCS
    // ============================================================================

    // getIt.registerFactory<ExercisesBloc>(() => ExercisesBloc(
    //   workoutRepository: getIt<WorkoutRepository>(),
    // ));

    // ============================================================================
    // STATS BLOCS
    // ============================================================================

    // getIt.registerFactory<StatsBloc>(() => StatsBloc(
    //   workoutRepository: getIt<WorkoutRepository>(),
    // ));
  }

  static void reset() {
    getIt.reset();
  }
}