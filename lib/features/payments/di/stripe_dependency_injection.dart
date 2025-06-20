// lib/features/payments/di/stripe_dependency_injection.dart
import 'package:get_it/get_it.dart';
import '../repository/stripe_repository.dart';
import '../services/stripe_service.dart';
import '../bloc/stripe_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/session_service.dart';
import 'package:dio/dio.dart';

/// Dependency injection per Stripe payments
class StripeDependencyInjection {
  static void registerStripeServices() {
    final getIt = GetIt.instance;

    //print('[CONSOLE] [stripe_dependency_injection]🔧 [STRIPE DI] Registering Stripe services...');

    // ============================================================================
    // STRIPE REPOSITORY
    // ============================================================================

    //print('[CONSOLE] [stripe_dependency_injection]🔧 [STRIPE DI] Registering StripeRepository...');

    // Verifica che le dipendenze esistano
    if (!getIt.isRegistered<ApiClient>()) {
      throw Exception('ApiClient not registered! Call DependencyInjection.init() first.');
    }
    if (!getIt.isRegistered<Dio>()) {
      throw Exception('Dio not registered! Call DependencyInjection.init() first.');
    }
    if (!getIt.isRegistered<SessionService>()) {
      throw Exception('SessionService not registered! Call DependencyInjection.init() first.');
    }

    getIt.registerLazySingleton<StripeRepository>(() {
      //print('[CONSOLE] [stripe_dependency_injection]🏗️ [STRIPE DI] Creating StripeRepository instance...');
      return StripeRepository(
        apiClient: getIt<ApiClient>(),
        dio: getIt<Dio>(),
        sessionService: getIt<SessionService>(),
      );
    });

    // ============================================================================
    // STRIPE BLOC
    // ============================================================================

    //print('[CONSOLE] [stripe_dependency_injection]🔧 [STRIPE DI] Registering StripeBloc...');

    getIt.registerFactory<StripeBloc>(() {
      //print('[CONSOLE] [stripe_dependency_injection]🏗️ [STRIPE DI] Creating StripeBloc instance...');
      return StripeBloc(
        repository: getIt<StripeRepository>(),
      );
    });

    //print('[CONSOLE] [stripe_dependency_injection]✅ [STRIPE DI] Stripe services registered successfully!');
  }

  /// Verifica se i servizi Stripe sono registrati
  static bool areStripeServicesRegistered() {
    final getIt = GetIt.instance;
    return getIt.isRegistered<StripeRepository>() && getIt.isRegistered<StripeBloc>();
  }

  /// Ottiene informazioni sui servizi Stripe registrati
  static Map<String, dynamic> getStripeServicesInfo() {
    final getIt = GetIt.instance;

    return {
      'stripe_repository_registered': getIt.isRegistered<StripeRepository>(),
      'stripe_bloc_registered': getIt.isRegistered<StripeBloc>(),
      'stripe_service_initialized': StripeService.isInitialized,
      'services_ready': areStripeServicesRegistered(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Verifica la salute del sistema Stripe
  static bool checkStripeSystemHealth() {
    try {
      final getIt = GetIt.instance;

      // Verifica registrazione servizi
      if (!getIt.isRegistered<StripeRepository>()) {
        //print('[CONSOLE] [stripe_dependency_injection]❌ [STRIPE CHECK] StripeRepository not registered');
        return false;
      }

      if (!getIt.isRegistered<StripeBloc>()) {
        //print('[CONSOLE] [stripe_dependency_injection]❌ [STRIPE CHECK] StripeBloc not registered');
        return false;
      }

      // Verifica dipendenze
      if (!getIt.isRegistered<ApiClient>()) {
        //print('[CONSOLE] [stripe_dependency_injection]❌ [STRIPE CHECK] ApiClient not registered (required dependency)');
        return false;
      }

      if (!getIt.isRegistered<Dio>()) {
        //print('[CONSOLE] [stripe_dependency_injection]❌ [STRIPE CHECK] Dio not registered (required dependency)');
        return false;
      }

      if (!getIt.isRegistered<SessionService>()) {
        //print('[CONSOLE] [stripe_dependency_injection]❌ [STRIPE CHECK] SessionService not registered (required dependency)');
        return false;
      }

      // Test istanziazione
      final stripeRepository = getIt<StripeRepository>();
      final stripeBloc = getIt<StripeBloc>();

      //print('[CONSOLE] [stripe_dependency_injection]✅ [STRIPE CHECK] All Stripe services are healthy');
      //print('[CONSOLE] [stripe_dependency_injection]🎯 [STRIPE CHECK] StripeService initialized: ${StripeService.isInitialized}');
      //print('[CONSOLE] [stripe_dependency_injection]🎯 [STRIPE CHECK] StripeBloc state: ${stripeBloc.state.runtimeType}');

      return true;

    } catch (e) {
      //print('[CONSOLE] [stripe_dependency_injection]💥 [STRIPE CHECK] Error checking Stripe system health: $e');
      return false;
    }
  }

  /// Report dettagliato dello stato del sistema Stripe
  static Map<String, dynamic> getSystemReport() {
    final getIt = GetIt.instance;

    return {
      'system_healthy': checkStripeSystemHealth(),
      'services_info': getStripeServicesInfo(),
      'repository_registered': getIt.isRegistered<StripeRepository>(),
      'bloc_registered': getIt.isRegistered<StripeBloc>(),
      'api_client_registered': getIt.isRegistered<ApiClient>(),
      'dio_registered': getIt.isRegistered<Dio>(),
      'session_service_registered': getIt.isRegistered<SessionService>(),
      'stripe_service_diagnostic': StripeService.getDiagnosticInfo(),
      'check_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Reset dei servizi Stripe (per testing)
  static void resetStripeServices() {
    final getIt = GetIt.instance;

    //print('[CONSOLE] [stripe_dependency_injection]🔄 [STRIPE DI] Resetting Stripe services...');

    if (getIt.isRegistered<StripeBloc>()) {
      // Reset del BLoC se possibile
      try {
        final stripeBloc = getIt<StripeBloc>();
        stripeBloc.add(const ResetStripeStateEvent());
      } catch (e) {
        //print('[CONSOLE] [stripe_dependency_injection]⚠️ [STRIPE DI] Could not reset StripeBloc: $e');
      }
      getIt.unregister<StripeBloc>();
    }

    if (getIt.isRegistered<StripeRepository>()) {
      getIt.unregister<StripeRepository>();
    }

    // Reset del servizio Stripe
    StripeService.reset();

    //print('[CONSOLE] [stripe_dependency_injection]✅ [STRIPE DI] Stripe services reset');
  }

  /// Reinizializza i servizi Stripe
  static Future<void> reinitializeStripeServices() async {
    //print('[CONSOLE] [stripe_dependency_injection]🔄 [STRIPE DI] Reinitializing Stripe services...');

    resetStripeServices();
    await Future.delayed(const Duration(milliseconds: 200));
    registerStripeServices();

    //print('[CONSOLE] [stripe_dependency_injection]✅ [STRIPE DI] Stripe services reinitialized');
  }
}