// lib/features/subscription/di/subscription_dependency_injection.dart
import 'package:get_it/get_it.dart';
import '../repository/subscription_repository.dart';
import '../repository/mock_subscription_repository.dart';
import '../bloc/subscription_bloc.dart';
import '../models/subscription_models.dart';
import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';
import '../../../core/utils/result.dart' as utils_result;

/// Dependency injection per le subscription
class SubscriptionDependencyInjection {
  static void registerSubscriptionServices({bool useMockRepository = true}) { // Default MOCK per sviluppo
    final getIt = GetIt.instance;

    print('🔧 [DI] Registering subscription services ${useMockRepository ? '(MOCK MODE)' : '(REAL MODE)'}...');

    // Repository (Real vs Mock)
    if (useMockRepository) {
      print('🎯 [DI] Registering MOCK SubscriptionRepository...');

      // Registra il MockSubscriptionRepository direttamente
      getIt.registerLazySingleton<MockSubscriptionRepository>(() {
        print('🏗️ [DI] Creating MockSubscriptionRepository instance...');
        return MockSubscriptionRepository();
      });

      // Crea un adapter che implementa SubscriptionRepository
      getIt.registerLazySingleton<SubscriptionRepository>(() {
        print('🏗️ [DI] Creating MockSubscriptionRepositoryAdapter instance...');
        final mockRepo = getIt<MockSubscriptionRepository>();
        return MockSubscriptionRepositoryAdapter(mockRepo);
      });
    } else {
      print('🔧 [DI] Registering REAL SubscriptionRepository...');
      getIt.registerLazySingleton<SubscriptionRepository>(() {
        print('🏗️ [DI] Creating SubscriptionRepository instance...');
        return SubscriptionRepository(
          apiClient: getIt<ApiClient>(),
          dio: getIt<Dio>(),
        );
      });
    }

    // BLoC
    getIt.registerFactory<SubscriptionBloc>(() {
      print('🏗️ [DI] Creating SubscriptionBloc instance...');
      return SubscriptionBloc(
        repository: getIt<SubscriptionRepository>(),
      );
    });

    print('✅ [DI] Subscription services registered successfully!');
  }
}

// ============================================================================
// 🎯 MOCK SUBSCRIPTION REPOSITORY ADAPTER
// ============================================================================

/// Adapter che implementa SubscriptionRepository ma delega tutto al MockSubscriptionRepository
class MockSubscriptionRepositoryAdapter implements SubscriptionRepository {
  final MockSubscriptionRepository _mockRepository;

  MockSubscriptionRepositoryAdapter(this._mockRepository) {
    print('🎯 [MOCK ADAPTER] Constructor called - subscription mockRepository: ${_mockRepository.runtimeType}');
    print('🎯 [MOCK ADAPTER] This adapter will delegate ALL subscription calls to MockSubscriptionRepository');
    print('🎯 [MOCK ADAPTER] NO REAL SUBSCRIPTION API CALLS WILL BE MADE');
  }

  @override
  Future<utils_result.Result<Subscription>> getCurrentSubscription() {
    print('🎯 [MOCK ADAPTER] getCurrentSubscription called - delegating to mock repository');
    return _mockRepository.getCurrentSubscription();
  }

  @override
  Future<utils_result.Result<ExpiredCheckResponse>> checkExpiredSubscriptions() {
    print('🎯 [MOCK ADAPTER] checkExpiredSubscriptions called - delegating to mock repository');
    return _mockRepository.checkExpiredSubscriptions();
  }

  @override
  Future<utils_result.Result<ResourceLimits>> checkResourceLimits(String resourceType) {
    print('🎯 [MOCK ADAPTER] checkResourceLimits called - delegating to mock repository');
    return _mockRepository.checkResourceLimits(resourceType);
  }

  @override
  Future<utils_result.Result<UpdatePlanResponse>> updatePlan(int planId) {
    print('🎯 [MOCK ADAPTER] updatePlan called - delegating to mock repository');
    return _mockRepository.updatePlan(planId);
  }

  @override
  Future<utils_result.Result<List<SubscriptionPlan>>> getAvailablePlans() {
    print('🎯 [MOCK ADAPTER] getAvailablePlans called - delegating to mock repository');
    return _mockRepository.getAvailablePlans();
  }

  @override
  Future<utils_result.Result<bool>> canCreateWorkout() {
    print('🎯 [MOCK ADAPTER] canCreateWorkout called - delegating to mock repository');
    return _mockRepository.canCreateWorkout();
  }

  @override
  Future<utils_result.Result<bool>> canCreateCustomExercise() {
    print('🎯 [MOCK ADAPTER] canCreateCustomExercise called - delegating to mock repository');
    return _mockRepository.canCreateCustomExercise();
  }
}