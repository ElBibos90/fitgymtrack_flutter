// lib/main.dart - VERSIONE OTTIMIZZATA
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/dependency_injection.dart';
import 'core/services/audio_settings_service.dart';
import 'core/services/background_timer_service.dart';
import 'core/router/app_router.dart';
import 'core/utils/api_request_debouncer.dart';
import 'core/services/app_update_service.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/workouts/bloc/plateau_bloc.dart';
import 'features/subscription/bloc/subscription_bloc.dart';
import 'features/payments/bloc/stripe_bloc.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/app_colors.dart';
import 'features/workouts/bloc/workout_blocs.dart';
import 'features/profile/bloc/profile_bloc.dart';
import 'core/config/app_config.dart';
import 'features/payments/services/stripe_service.dart';
import 'core/config/stripe_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📱 Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inizializza dependency injection
  await DependencyInjection.init();

  // 🎵 Inizializza servizio audio settings
  await getIt<AudioSettingsService>().initialize();

  // 🚀 Inizializza servizio background timer
  await getIt<BackgroundTimerService>().initialize();

  // 🔍 DEBUG: Verifica configurazione Stripe all'avvio
  StripeConfig.printTestingInfo();

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => const FitGymTrackApp(),
    ),
  );
}

class FitGymTrackApp extends StatelessWidget {
  const FitGymTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 🔑 CRITICAL: AuthBloc - Gestione autenticazione
        BlocProvider<AuthBloc>(create: (context) => getIt<AuthBloc>()),
        
        // 💳 ESSENTIAL: SubscriptionBloc - Gestione abbonamenti
        BlocProvider<SubscriptionBloc>(create: (context) => getIt<SubscriptionBloc>()),
        
        // 📊 ESSENTIAL: WorkoutHistoryBloc - Storico allenamenti
        BlocProvider<WorkoutHistoryBloc>(create: (context) => getIt<WorkoutHistoryBloc>()),
        
        // 📝 LAZY: RegisterBloc - Registrazione utente
        BlocProvider<RegisterBloc>(create: (context) => getIt<RegisterBloc>()),
        
        // 🔄 LAZY: PasswordResetBloc - Reset password
        BlocProvider<PasswordResetBloc>(create: (context) => getIt<PasswordResetBloc>()),
        
        // 💪 LAZY: WorkoutBloc - Gestione workout
        BlocProvider<WorkoutBloc>(create: (context) => getIt<WorkoutBloc>()),
        
        // ⚡ LAZY: ActiveWorkoutBloc - Workout attivo
        BlocProvider<ActiveWorkoutBloc>(create: (context) => getIt<ActiveWorkoutBloc>()),
        
        // 📈 LAZY: PlateauBloc - Rilevamento plateau
        BlocProvider<PlateauBloc>(create: (context) => getIt<PlateauBloc>()),
        
        // 💰 LAZY: StripeBloc - Pagamenti
        BlocProvider<StripeBloc>(create: (context) => getIt<StripeBloc>()),
        
        // 👤 LAZY: ProfileBloc - Profilo utente
        BlocProvider<ProfileBloc>(create: (context) => getIt<ProfileBloc>()),
      ],
      child: MaterialApp.router(
        title: 'FitGymTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.createRouter(),
      ),
    );
  }
}

/// 🚀 PERFORMANCE: Widget per cleanup automatico
class AppCleanup extends StatefulWidget {
  final Widget child;

  const AppCleanup({super.key, required this.child});

  @override
  State<AppCleanup> createState() => _AppCleanupState();
}

class _AppCleanupState extends State<AppCleanup> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 🧹 CLEANUP: Disponi debouncer quando app si chiude
    ApiRequestDebouncer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // 🚀 PERFORMANCE: Pulisci cache quando app va in background
      ApiRequestDebouncer.clearAllCache();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// 🚀 PERFORMANCE OPTIMIZED: Splash Screen con preload intelligente
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 1), // 🚀 REDUCED da 2s a 1s
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    // 🚀 PERFORMANCE: Preload critical data durante splash
    _preloadCriticalData();
  }

  /// 🚀 PERFORMANCE: Preload solo dati critici durante splash
  void _preloadCriticalData() async {
    try {
      // Solo se user è già autenticato, preload subscription
      final authBloc = context.read<AuthBloc>();
      if (authBloc.state is AuthAuthenticated) {
        // Preload subscription in background (non blocca la UI)
        Future.microtask(() {
          context.read<SubscriptionBloc>().add(
            const LoadSubscriptionEvent(checkExpired: false), // No check expired nello splash
          );
        });
      }

      // 🔧 RIMOSSO: Controllo aggiornamenti spostato nella home screen
    } catch (e) {
      // Non bloccare l'app per errori di preload
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 60,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'FitGymTrack',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track. Train. Transform.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              // 🚀 PERFORMANCE: Loading indicator più leggero
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}