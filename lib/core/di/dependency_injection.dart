// lib/core/di/dependency_injection.dart
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/session_service.dart';
import '../services/audio_settings_service.dart';
import '../services/background_timer_service.dart';
import '../services/global_connectivity_service.dart';
import '../../features/workouts/services/workout_schede_cache_service.dart';
import '../network/dio_client.dart';
import '../network/api_client.dart';

// Auth feature
import '../../features/auth/repository/auth_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';

// Workout features
import '../../features/workouts/repository/workout_repository.dart';
import '../../features/workouts/services/workout_offline_service.dart';
import '../../features/workouts/bloc/workout_bloc.dart';
import '../../features/workouts/bloc/active_workout_bloc.dart';
import '../../features/workouts/bloc/workout_history_bloc.dart';

import '../di/dependency_injection_plateau.dart';
import '../../features/subscription/di/subscription_dependency_injection.dart';
import '../../features/payments/di/stripe_dependency_injection.dart';

import '../../features/feedback/repository/feedback_repository.dart';

import '../../features/profile/repository/profile_repository.dart';
import '../../features/profile/bloc/profile_bloc.dart';

// Stats feature
import '../../features/stats/repository/stats_repository.dart';
import '../../features/stats/bloc/stats_bloc.dart';

// Template features
import '../../features/templates/services/template_service.dart';
import '../../features/templates/bloc/template_bloc.dart';

// Notification features
import '../../features/notifications/repositories/notification_repository.dart';
import '../../features/notifications/bloc/notification_bloc.dart';

// Courses features
import '../../features/courses/repository/courses_repository.dart';
import '../../features/courses/bloc/courses_bloc.dart';

final getIt = GetIt.instance;

class DependencyInjection {
  /// Inizializzazione dei servizi di dependency injection
  /// Ora usa SOLO repository reali - niente più mock
  static Future<void> init() async {
    //print('[CONSOLE] [dependency_injection]🚨 DEPENDENCY INJECTION STARTED (REAL REPOSITORIES ONLY + STRIPE)');
    //print('[CONSOLE] [dependency_injection]🔧 [DI] Starting dependency injection initialization...');

    // ============================================================================
    // CORE SERVICES
    // ============================================================================

    //print('[CONSOLE] [dependency_injection]🔧 [DI] Registering core services...');
    getIt.registerLazySingleton<SessionService>(() => SessionService());

    // 🎵 Audio Settings Service
    getIt.registerLazySingleton<AudioSettingsService>(() => AudioSettingsService());

    // 🚀 Background Timer Service
    getIt.registerLazySingleton<BackgroundTimerService>(() => BackgroundTimerService());

    // 🌐 Global Connectivity Service
    getIt.registerLazySingleton<GlobalConnectivityService>(() => GlobalConnectivityService());

    // 📋 Workout Schede Cache Service
    getIt.registerLazySingleton<WorkoutSchedeCacheService>(() => WorkoutSchedeCacheService());

    getIt.registerLazySingleton<Dio>(() => DioClient.getInstance(
      sessionService: getIt<SessionService>(),
    ));

    getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt<Dio>()));

    // ============================================================================
    // ROUTE OBSERVER
    // ============================================================================

    getIt.registerLazySingleton<RouteObserver<ModalRoute<void>>>(() => RouteObserver<ModalRoute<void>>());

    // ============================================================================
    // REPOSITORIES (SOLO REALI)
    // ============================================================================

    //print('[CONSOLE] [dependency_injection]🔧 [DI] Registering repositories...');

    // Auth Repository
    getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(
      apiClient: getIt<ApiClient>(),
      sessionService: getIt<SessionService>(),
    ));

    // 🔧 FIX: Workout Repository - SOLO REAL
    //print('[CONSOLE] [dependency_injection]🔧 [DI] Registering REAL WorkoutRepository...');
    getIt.registerLazySingleton<WorkoutRepository>(() => WorkoutRepository(
      apiClient: getIt<ApiClient>(),
      dio: getIt<Dio>(),
    ));

    print('[CONSOLE] [dependency_injection]🔧 [DI] Registering feedback repository...');

    getIt.registerLazySingleton<FeedbackRepository>(() {
      return FeedbackRepository(
        apiClient: getIt<ApiClient>(),
        dio: getIt<Dio>(),
      );
    });

    // Profile Repository
    getIt.registerLazySingleton<ProfileRepository>(() => ProfileRepository(
      apiClient: getIt<ApiClient>(),
    ));

    // Stats Repository
    getIt.registerLazySingleton<StatsRepository>(() => StatsRepository(
      getIt<ApiClient>(),
    ));

    // Notification Repository
    getIt.registerLazySingleton<NotificationRepository>(() => NotificationRepository(
      dio: getIt<Dio>(),
    ));

    // ============================================================================
    // COURSES REPOSITORY
    // ============================================================================
    getIt.registerLazySingleton<CoursesRepository>(() => CoursesRepository(
      getIt<Dio>(),
    ));

    // ============================================================================
    // WORKOUT BLOCS (SINGLETONS)
    // ============================================================================

    //print('[CONSOLE] [dependency_injection]🔧 [DI] Registering workout BLoCs as singletons...');

    getIt.registerLazySingleton<WorkoutBloc>(() {
      //print('[CONSOLE] [dependency_injection]🏗️ [DI] Creating WorkoutBloc instance...');
      return WorkoutBloc(
        workoutRepository: getIt<WorkoutRepository>(),
      );
    });

    // 🚀 NUOVO: Registra il servizio offline (sincrono)
    getIt.registerLazySingleton<WorkoutOfflineService>(() {
      return WorkoutOfflineService(
        repository: getIt<WorkoutRepository>(),
        prefs: null, // Sarà inizializzato quando necessario
      );
    });

    getIt.registerLazySingleton<ActiveWorkoutBloc>(() {
      //print('[CONSOLE] [dependency_injection]🏗️ [DI] Creating ActiveWorkoutBloc instance...');
      return ActiveWorkoutBloc(
        workoutRepository: getIt<WorkoutRepository>(),
        offlineService: getIt<WorkoutOfflineService>(),
      );
    });

    getIt.registerLazySingleton<WorkoutHistoryBloc>(() {
      //print('[CONSOLE] [dependency_injection]🏗️ [DI] Creating WorkoutHistoryBloc instance...');
      return WorkoutHistoryBloc(
        workoutRepository: getIt<WorkoutRepository>(),
      );
    });

    getIt.registerLazySingleton<ProfileBloc>(() {
      //print('[CONSOLE] [dependency_injection]🏗️ [DI] Creating ProfileBloc instance...');
      return ProfileBloc(
        repository: getIt<ProfileRepository>(),
      );
    });

    getIt.registerLazySingleton<StatsBloc>(() {
      //print('[CONSOLE] [dependency_injection]🏗️ [DI] Creating StatsBloc instance...');
      return StatsBloc(
        getIt<StatsRepository>(),
      );
    });

    // ============================================================================
    // AUTH BLOCS (FACTORIES)
    // ============================================================================

    //print('[CONSOLE] [dependency_injection]🔧 [DI] Registering auth BLoCs as factories...');

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

    //print('[CONSOLE] [dependency_injection]🔧 [DI] Registering plateau services...');
    PlateauDependencyInjection.registerPlateauServices();

    // ============================================================================
    // 💳 SUBSCRIPTION SERVICES
    // ============================================================================

    //print('[CONSOLE] [dependency_injection]🔧 [DI] Registering subscription services...');
    try {
      // 🔧 FIX: Subscription services con repository reali
      SubscriptionDependencyInjection.registerSubscriptionServices();
      //print('[CONSOLE] [dependency_injection]✅ [DI] Subscription services registered successfully!');
    } catch (e) {
      //print('[CONSOLE] [dependency_injection]❌ [DI] ERROR registering subscription services: $e');
      rethrow;
    }

    // ============================================================================
    // 💳 STRIPE PAYMENT SERVICES
    // ============================================================================

    //print('[CONSOLE] [dependency_injection]🔧 [DI] Registering Stripe payment services...');
    try {
      StripeDependencyInjection.registerStripeServices();
      //print('[CONSOLE] [dependency_injection]✅ [DI] Stripe services registered successfully!');
    } catch (e) {
      //print('[CONSOLE] [dependency_injection]❌ [DI] ERROR registering Stripe services: $e');
      rethrow;
    }

    // ============================================================================
    // 📋 TEMPLATE SERVICES
    // ============================================================================

    //print('[CONSOLE] [dependency_injection]🔧 [DI] Registering Template services...');
    try {
      // Template Service
      getIt.registerLazySingleton<TemplateService>(() => TemplateService());
      
      // Template Bloc
      getIt.registerFactory<TemplateBloc>(() => TemplateBloc(
        templateService: getIt<TemplateService>(),
      ));
      
      //print('[CONSOLE] [dependency_injection]✅ [DI] Template services registered successfully!');
    } catch (e) {
      //print('[CONSOLE] [dependency_injection]❌ [DI] ERROR registering Template services: $e');
      rethrow;
    }

    // ============================================================================
    // 🔔 NOTIFICATION SERVICES
    // ============================================================================

    //print('[CONSOLE] [dependency_injection]🔧 [DI] Registering Notification services...');
    try {
      // Notification Bloc
      getIt.registerLazySingleton<NotificationBloc>(() => NotificationBloc(
        repository: getIt<NotificationRepository>(),
      ));

      // ============================================================================
      // COURSES BLOC
      // ============================================================================
      getIt.registerFactory<CoursesBloc>(() => CoursesBloc(
        repository: getIt<CoursesRepository>(),
      ));
      
      //print('[CONSOLE] [dependency_injection]✅ [DI] Notification services registered successfully!');
    } catch (e) {
      //print('[CONSOLE] [dependency_injection]❌ [DI] ERROR registering Notification services: $e');
      rethrow;
    }

    //print('[CONSOLE] [dependency_injection]✅ [DI] Dependency injection completed successfully!');

    // ============================================================================
    // DIAGNOSTIC INFO
    // ============================================================================

    _printDiagnosticInfo();
  }

  /// Stampa informazioni diagnostiche sui servizi registrati
  static void _printDiagnosticInfo() {
    //print('[CONSOLE] [dependency_injection]');
    //print('[CONSOLE] [dependency_injection]🔍 [DI] DIAGNOSTIC INFO:');
    //print('[CONSOLE] [dependency_injection]🔍 [DI] ════════════════════════════════════════');
    //print('[CONSOLE] [dependency_injection]🔍 [DI] Core services registered: ${_countCoreServices()}');
    //print('[CONSOLE] [dependency_injection]🔍 [DI] Repository services: ${_countRepositories()}');
    //print('[CONSOLE] [dependency_injection]🔍 [DI] BLoC services: ${_countBlocs()}');
    //print('[CONSOLE] [dependency_injection]🔍 [DI] Plateau services: ${PlateauDependencyInjection.arePlateauServicesRegistered()}');
    //print('[CONSOLE] [dependency_injection]🔍 [DI] Subscription services: ${SubscriptionDependencyInjection.areSubscriptionServicesRegistered()}');
    //print('[CONSOLE] [dependency_injection]🔍 [DI] Stripe services: ${StripeDependencyInjection.areStripeServicesRegistered()}');
    //print('[CONSOLE] [dependency_injection]🔍 [DI] Total services registered: ${_getTotalServicesCount()}');
    //print('[CONSOLE] [dependency_injection]🔍 [DI] ════════════════════════════════════════');
    //print('[CONSOLE] [dependency_injection]');
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
    if (getIt.isRegistered<FeedbackRepository>()) count++;
    if (getIt.isRegistered<ProfileRepository>()) count++;
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
    if (getIt.isRegistered<ProfileBloc>()) count++;

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

      //print('[CONSOLE] [dependency_injection]✅ [DI] System health check passed');
      //print('[CONSOLE] [dependency_injection]🎯 [DI] Plateau system: ${plateauHealthy ? "✅" : "❌"}');
      //print('[CONSOLE] [dependency_injection]🎯 [DI] Subscription system: ${subscriptionHealthy ? "✅" : "❌"}');
      //print('[CONSOLE] [dependency_injection]🎯 [DI] Stripe system: ${stripeHealthy ? "✅" : "❌"}');

      return plateauHealthy && subscriptionHealthy && stripeHealthy;

    } catch (e) {
      //print('[CONSOLE] [dependency_injection]❌ [DI] System health check failed: $e');
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
    //print('[CONSOLE] [dependency_injection]🔄 [DI] Resetting GetIt completely...');
    getIt.reset();
  }

  /// Reinizializza con repository reali
  static Future<void> reinitialize() async {
    //print('[CONSOLE] [dependency_injection]🔄 [DI] Reinitializing with real repositories and Stripe...');
    reset();
    await Future.delayed(const Duration(milliseconds: 200));
    await init();
  }

  /// Reset selettivo solo dei servizi Stripe (per testing)
  static void resetStripeOnly() {
    //print('[CONSOLE] [dependency_injection]🔄 [DI] Resetting only Stripe services...');
    StripeDependencyInjection.resetStripeServices();
  }

  /// Reinizializza solo i servizi Stripe
  static Future<void> reinitializeStripeOnly() async {
    //print('[CONSOLE] [dependency_injection]🔄 [DI] Reinitializing only Stripe services...');
    await StripeDependencyInjection.reinitializeStripeServices();
  }
}