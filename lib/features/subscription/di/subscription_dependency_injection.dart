// lib/features/subscription/di/subscription_dependency_injection.dart
import 'package:get_it/get_it.dart';
import '../repository/subscription_repository.dart';
import '../bloc/subscription_bloc.dart';
import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

/// Dependency injection per le subscription
/// Solo repository reali - niente mock
class SubscriptionDependencyInjection {
  static void registerSubscriptionServices() {
    final getIt = GetIt.instance;

    //print('[CONSOLE] [subscription_dependency_injection]🔧 [DI] Registering subscription services (REAL MODE)...');

    // 🔧 FIX: SOLO Repository Reale
    //print('[CONSOLE] [subscription_dependency_injection]🔧 [DI] Registering REAL SubscriptionRepository...');

    // Verifica che le dipendenze esistano
    if (!getIt.isRegistered<ApiClient>()) {
      throw Exception('ApiClient not registered! Call DependencyInjection.init() first.');
    }
    if (!getIt.isRegistered<Dio>()) {
      throw Exception('Dio not registered! Call DependencyInjection.init() first.');
    }

    getIt.registerLazySingleton<SubscriptionRepository>(() {
      //print('[CONSOLE] [subscription_dependency_injection]🏗️ [DI] Creating REAL SubscriptionRepository instance...');
      return SubscriptionRepository(
        apiClient: getIt<ApiClient>(),
        dio: getIt<Dio>(),
      );
    });

    // BLoC
    getIt.registerFactory<SubscriptionBloc>(() {
      //print('[CONSOLE] [subscription_dependency_injection]🏗️ [DI] Creating SubscriptionBloc instance...');
      return SubscriptionBloc(
        repository: getIt<SubscriptionRepository>(),
      );
    });

    //print('[CONSOLE] [subscription_dependency_injection]✅ [DI] Subscription services registered successfully!');
  }

  /// Verifica se i servizi Subscription sono registrati
  static bool areSubscriptionServicesRegistered() {
    final getIt = GetIt.instance;
    return getIt.isRegistered<SubscriptionRepository>() && getIt.isRegistered<SubscriptionBloc>();
  }

  /// Ottiene informazioni sui servizi Subscription registrati
  static Map<String, dynamic> getSubscriptionServicesInfo() {
    final getIt = GetIt.instance;

    return {
      'subscription_repository_registered': getIt.isRegistered<SubscriptionRepository>(),
      'subscription_bloc_registered': getIt.isRegistered<SubscriptionBloc>(),
      'services_ready': areSubscriptionServicesRegistered(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}