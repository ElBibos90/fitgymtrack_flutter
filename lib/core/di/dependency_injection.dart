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
import '../../features/workouts/repository/mock_workout_repository.dart';
import '../../features/workouts/bloc/workout_bloc.dart';
import '../../features/workouts/bloc/active_workout_bloc.dart';
import '../../features/workouts/bloc/workout_history_bloc.dart';

// ✅ FIX: Import modelli necessari
import '../../features/workouts/models/workout_plan_models.dart';
import '../../features/workouts/models/active_workout_models.dart';
import '../../features/workouts/models/series_request_models.dart';
import '../../features/workouts/models/workout_response_types.dart';
import '../../features/exercises/models/exercises_response.dart';
import '../../features/stats/models/user_stats_models.dart';
import '../utils/result.dart' as utils_result;

final getIt = GetIt.instance;

class DependencyInjection {
  static Future<void> init({bool useMockRepository = false}) async {
    print('🚨 DEPENDENCY INJECTION STARTED ${useMockRepository ? '(MOCK MODE)' : '(REAL MODE)'}');
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
    // REPOSITORIES (REAL vs MOCK)
    // ============================================================================

    print('🔧 [DI] Registering repositories...');

    // Auth Repository (sempre reale)
    getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(
      apiClient: getIt<ApiClient>(),
      sessionService: getIt<SessionService>(),
    ));

    // 🎯 FIX: Workout Repository con supporto Mock CORRETTO
    if (useMockRepository) {
      print('🎯 [DI] Registering MOCK WorkoutRepository for testing...');

      // Registra SOLO il MockWorkoutRepository come WorkoutRepository
      getIt.registerLazySingleton<WorkoutRepository>(() {
        print('🏗️ [DI] Creating MockWorkoutRepositoryAdapter instance...');
        final mockRepo = MockWorkoutRepository();
        final adapter = MockWorkoutRepositoryAdapter(mockRepo);
        print('✅ [DI] MockWorkoutRepositoryAdapter created - ALL CALLS WILL GO TO MOCK');
        return adapter;
      });
    } else {
      print('🔧 [DI] Registering REAL WorkoutRepository...');
      getIt.registerLazySingleton<WorkoutRepository>(() => WorkoutRepository(
        apiClient: getIt<ApiClient>(),
        dio: getIt<Dio>(),
      ));
    }

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

    print('✅ [DI] Dependency injection completed successfully!');
  }

  /// 🎯 NUOVO: Metodo per inizializzare in modalità mock per i test
  static Future<void> initMock() async {
    await init(useMockRepository: true);
  }

  /// Metodo per resettare e reinizializzare con mock
  static Future<void> resetAndInitMock() async {
    print('🔄 [DI] Resetting and switching to mock mode...');

    // Reset completo
    getIt.reset();

    // ✅ FIX: Delay per assicurare reset completo
    await Future.delayed(const Duration(milliseconds: 200));

    await initMock();
  }

  /// Metodo per resettare e reinizializzare con repository reale
  static Future<void> resetAndInitReal() async {
    print('🔄 [DI] Resetting and switching to real mode...');
    reset();
    await init(useMockRepository: false);
  }

  static void reset() {
    print('🔄 [DI] Resetting GetIt completely...');
    getIt.reset();
  }
}

// ============================================================================
// 🎯 MOCK WORKOUT REPOSITORY ADAPTER (COMPOSITION INVECE DI INHERITANCE)
// ============================================================================

/// Adapter che implementa WorkoutRepository ma delega tutto al MockWorkoutRepository
/// Usa COMPOSITION invece di inheritance per evitare problemi di costruttore
class MockWorkoutRepositoryAdapter implements WorkoutRepository {
  final MockWorkoutRepository _mockRepository;

  MockWorkoutRepositoryAdapter(this._mockRepository) {
    print('🎯 [MOCK ADAPTER] Constructor called - mockRepository: ${_mockRepository.runtimeType}');
    print('🎯 [MOCK ADAPTER] This adapter will delegate ALL calls to MockWorkoutRepository');
    print('🎯 [MOCK ADAPTER] NO REAL API CALLS WILL BE MADE');
  }

  // ============================================================================
  // METODI PRINCIPALI (delegati al mock)
  // ============================================================================

  @override
  Future<utils_result.Result<List<WorkoutPlan>>> getWorkoutPlans(int userId) {
    print('🎯 [MOCK ADAPTER] getWorkoutPlans called - delegating to mock repository');
    return _mockRepository.getWorkoutPlans(userId);
  }

  @override
  Future<utils_result.Result<List<WorkoutExercise>>> getWorkoutExercises(int schedaId) {
    print('🎯 [MOCK ADAPTER] getWorkoutExercises called - delegating to mock repository');
    return _mockRepository.getWorkoutExercises(schedaId);
  }

  @override
  Future<utils_result.Result<StartWorkoutResponse>> startWorkout(int userId, int schedaId) {
    print('🎯 [MOCK ADAPTER] *** startWorkout called - delegating to MOCK repository (NOT real backend) ***');
    return _mockRepository.startWorkout(userId, schedaId);
  }

  @override
  Future<utils_result.Result<List<CompletedSeriesData>>> getCompletedSeries(int allenamentoId) {
    print('🎯 [MOCK ADAPTER] getCompletedSeries called - delegating to mock repository');
    return _mockRepository.getCompletedSeries(allenamentoId);
  }

  @override
  Future<utils_result.Result<SaveCompletedSeriesResponse>> saveCompletedSeries(
      int allenamentoId, List<SeriesData> serie, String requestId) {
    print('🎯 [MOCK ADAPTER] saveCompletedSeries called - delegating to mock repository');
    return _mockRepository.saveCompletedSeries(allenamentoId, serie, requestId);
  }

  @override
  Future<utils_result.Result<CompleteWorkoutResponse>> completeWorkout(
      int allenamentoId, int durataTotale, {String? note}) {
    print('🎯 [MOCK ADAPTER] completeWorkout called - delegating to mock repository');
    return _mockRepository.completeWorkout(allenamentoId, durataTotale, note: note);
  }

  // ============================================================================
  // METODI PLACEHOLDER (non usati nel test Step 5)
  // ============================================================================

  @override
  Future<utils_result.Result<CreateWorkoutPlanResponse>> createWorkoutPlan(CreateWorkoutPlanRequest request) =>
      _mockRepository.createWorkoutPlan(request);

  @override
  Future<utils_result.Result<UpdateWorkoutPlanResponse>> updateWorkoutPlan(UpdateWorkoutPlanRequest request) =>
      _mockRepository.updateWorkoutPlan(request);

  @override
  Future<utils_result.Result<DeleteWorkoutPlanResponse>> deleteWorkoutPlan(int schedaId) =>
      _mockRepository.deleteWorkoutPlan(schedaId);

  @override
  Future<utils_result.Result<List<ExerciseItem>>> getAvailableExercises(int userId) =>
      _mockRepository.getAvailableExercises(userId);

  @override
  Future<utils_result.Result<List<WorkoutHistory>>> getWorkoutHistory(int userId) =>
      _mockRepository.getWorkoutHistory(userId);

  @override
  Future<utils_result.Result<List<CompletedSeriesData>>> getWorkoutSeriesDetail(int allenamentoId) =>
      _mockRepository.getWorkoutSeriesDetail(allenamentoId);

  @override
  Future<utils_result.Result<bool>> deleteCompletedSeries(String seriesId) =>
      _mockRepository.deleteCompletedSeries(seriesId);

  @override
  Future<utils_result.Result<bool>> updateCompletedSeries(String seriesId, double weight, int reps,
      {int? recoveryTime, String? notes}) =>
      _mockRepository.updateCompletedSeries(seriesId, weight, reps,
          recoveryTime: recoveryTime, notes: notes);

  @override
  Future<utils_result.Result<bool>> deleteWorkout(int workoutId) =>
      _mockRepository.deleteWorkout(workoutId);

  @override
  Future<utils_result.Result<UserStats>> getUserStats(int userId) =>
      _mockRepository.getUserStats(userId);

  @override
  Future<utils_result.Result<PeriodStats>> getPeriodStats(String period) =>
      _mockRepository.getPeriodStats(period);
}