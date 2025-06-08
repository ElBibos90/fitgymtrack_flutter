import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'core/di/dependency_injection.dart';
import 'core/router/app_router.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/workouts/bloc/plateau_bloc.dart';
import 'features/subscription/bloc/subscription_bloc.dart';
import 'features/payments/bloc/stripe_bloc.dart';
import 'shared/theme/app_theme.dart';
import 'features/workouts/bloc/workout_blocs.dart';
import 'features/workouts/presentation/screens/workout_plans_screen.dart';
import 'features/subscription/presentation/screens/subscription_screen.dart';
import 'core/utils/stripe_configuration_checker.dart';
import 'core/utils/stripe_super_debug.dart';
import 'core/config/stripe_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📱 BLOCCA ORIENTAMENTO - SOLO PORTRAIT
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('🚀 FITGYMTRACK STARTED - SUPER STRIPE DEBUG MODE!');
  print('📱 App orientation locked to PORTRAIT only');
  print('💳 Stripe payments system with SUPER enhanced debugging');

  // 🔧 Inizializzazione dependency injection
  await DependencyInjection.init();

  // 💳 SUPER VERIFICA configurazione Stripe all'avvio
  print('🔍 Performing SUPER Stripe configuration check...');
  final stripeCheck = await StripeConfigurationChecker.checkConfiguration();
  StripeConfigurationChecker.printCheckResult(stripeCheck);

  // 🔧 DEBUG: Stampa configurazione Stripe dettagliata
  StripeConfig.printDebugInfo();

  // 💳 Verifica salute sistema generale
  final systemHealthy = DependencyInjection.checkSystemHealth();
  print('🏥 System health check: ${systemHealthy ? "✅ HEALTHY" : "❌ ISSUES"}');

  // 🔍 SUPER DEBUG: Test automatico in background
  _runSuperStripeDebugInBackground();

  runApp(FitGymTrackApp(stripeConfigValid: stripeCheck.isValid));
}

/// Esegue il SUPER diagnostic Stripe in background per il debug
Future<void> _runSuperStripeDebugInBackground() async {
  try {
    print('🚀 [MAIN] Running SUPER Stripe diagnostic in background...');

    // Attendi che l'app sia inizializzata
    await Future.delayed(const Duration(seconds: 3));

    final dio = getIt<Dio>();

    // 🚀 SUPER DEBUG completo
    final report = await StripeSuperDebug.runSuperDiagnostic(
      dio: dio,
      verbose: false, // Non troppo verbose in background
    );

    print('🚀 [MAIN] SUPER Stripe diagnostic completed!');
    print('📊 [MAIN] Overall Score: ${report.overallScore}/100');
    print('🏥 [MAIN] System Status: ${report.systemStatus}');
    print('🔧 [MAIN] Configuration Score: ${report.configurationScore}/100');
    print('🌐 [MAIN] Connectivity Score: ${report.connectivityScore}/100');
    print('🔐 [MAIN] Authentication Score: ${report.authenticationScore}/100');
    print('🎯 [MAIN] Stripe Endpoints Score: ${report.stripeEndpointsScore}/100');

    if (report.systemStatus != 'EXCELLENT' && report.systemStatus != 'GOOD') {
      print('⚠️ [MAIN] Stripe system needs attention!');
      print('💡 [MAIN] Top recommendations:');
      for (int i = 0; i < report.recommendations.length && i < 3; i++) {
        print('   ${i + 1}. ${report.recommendations[i]}');
      }
    } else {
      print('✅ [MAIN] Stripe system is working well!');
    }

  } catch (e) {
    print('❌ [MAIN] Background SUPER Stripe diagnostic failed: $e');
  }
}

class FitGymTrackApp extends StatelessWidget {
  final bool stripeConfigValid;

  const FitGymTrackApp({super.key, required this.stripeConfigValid});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            // AUTH BLOC PROVIDERS
            BlocProvider<AuthBloc>(
              create: (context) => getIt<AuthBloc>(),
            ),
            BlocProvider<RegisterBloc>(
              create: (context) => getIt<RegisterBloc>(),
            ),
            BlocProvider<PasswordResetBloc>(
              create: (context) => getIt<PasswordResetBloc>(),
            ),

            // WORKOUT BLOC PROVIDERS
            BlocProvider<WorkoutBloc>(
              create: (context) => getIt<WorkoutBloc>(),
            ),
            BlocProvider<ActiveWorkoutBloc>(
              create: (context) => getIt<ActiveWorkoutBloc>(),
            ),
            BlocProvider<WorkoutHistoryBloc>(
              create: (context) => getIt<WorkoutHistoryBloc>(),
            ),
            BlocProvider<PlateauBloc>(
              create: (context) => getIt<PlateauBloc>(),
            ),

            // SUBSCRIPTION & PAYMENT BLOC PROVIDERS
            BlocProvider<SubscriptionBloc>(
              create: (context) => getIt<SubscriptionBloc>(),
            ),

            // 💳 STRIPE BLOC PROVIDER CON INIZIALIZZAZIONE SUPER
            BlocProvider<StripeBloc>(
              create: (context) {
                final stripeBloc = getIt<StripeBloc>();
                // 🔧 SUPER FORZA inizializzazione immediata se configurazione è valida
                if (stripeConfigValid && !StripeConfig.isDemoMode) {
                  print('💳 SUPER Forcing Stripe initialization...');
                  stripeBloc.add(const InitializeStripeEvent());
                } else if (StripeConfig.isDemoMode) {
                  print('⚠️ STRIPE: Demo mode detected - Stripe will work with limited functionality');
                } else {
                  print('❌ STRIPE: Invalid configuration - Stripe disabled');
                }
                return stripeBloc;
              },
            ),
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
      },
    );
  }
}

// SplashScreen with Super Debug
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _stripeInitialized = false;
  String _stripeStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
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

    // 💳 SUPER Forza inizializzazione Stripe
    _superInitializeStripe();
  }

  Future<void> _superInitializeStripe() async {
    try {
      print('💳 [SPLASH] SUPER Stripe initialization starting...');

      // Aspetta un po' per essere sicuri che il BLoC sia pronto
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Verifica configurazione prima di inizializzare
        if (StripeConfig.isDemoMode) {
          setState(() {
            _stripeStatus = 'Demo mode - Limited functionality';
          });
          print('⚠️ [SPLASH] Stripe in demo mode');
        } else if (!StripeConfig.isValidKey(StripeConfig.publishableKey)) {
          setState(() {
            _stripeStatus = 'Invalid configuration';
          });
          print('❌ [SPLASH] Invalid Stripe configuration');
        } else {
          context.read<StripeBloc>().add(const InitializeStripeEvent());
          setState(() {
            _stripeStatus = 'Connecting to Stripe...';
          });
          print('💳 [SPLASH] SUPER Stripe initialization event sent');
        }
      }

    } catch (e) {
      print('⚠️ [SPLASH] Could not initialize Stripe: $e');
      if (mounted) {
        setState(() {
          _stripeStatus = 'Initialization failed';
        });
      }
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
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.fitness_center,
                  size: 60.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              SizedBox(height: 24.h),

              Text(
                'FitGymTrack',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                'Il tuo personal trainer digitale',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w300,
                ),
              ),

              SizedBox(height: 40.h),

              SizedBox(
                width: 40.w,
                height: 40.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),

              SizedBox(height: 16.h),

              // 💳 SUPER Indicatore Stripe con più dettagli
              BlocListener<StripeBloc, StripeState>(
                listener: (context, state) {
                  if (state is StripeReady && !_stripeInitialized) {
                    print('💳 [SPLASH] SUPER Stripe ready!');
                    setState(() {
                      _stripeInitialized = true;
                      _stripeStatus = 'Payments ready';
                    });
                  } else if (state is StripeErrorState) {
                    print('💳 [SPLASH] SUPER Stripe error: ${state.message}');
                    setState(() {
                      _stripeStatus = 'Payment system offline';
                    });
                  } else if (state is StripeInitializing) {
                    setState(() {
                      _stripeStatus = 'Initializing payments...';
                    });
                  }
                },
                child: BlocBuilder<StripeBloc, StripeState>(
                  builder: (context, state) {
                    IconData icon;
                    Color color;
                    String statusText;

                    if (state is StripeReady) {
                      icon = Icons.check_circle;
                      color = Colors.green;
                      statusText = 'Payments ready';
                    } else if (state is StripeErrorState) {
                      icon = Icons.error_outline;
                      color = Colors.orange;
                      statusText = 'Offline mode';
                    } else if (state is StripeInitializing) {
                      icon = Icons.hourglass_empty;
                      color = Colors.blue;
                      statusText = 'Connecting...';
                    } else {
                      icon = Icons.payment;
                      color = Colors.grey;
                      statusText = _stripeStatus;
                    }

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              color: color,
                              size: 16.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Mostra info configurazione in modalità debug
                        if (StripeConfig.isDemoMode || !StripeConfig.isValidKey(StripeConfig.publishableKey)) ...[
                          SizedBox(height: 4.h),
                          Text(
                            StripeConfig.isDemoMode
                                ? 'Demo configuration'
                                : 'Config needs attention',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// HomeScreen per la dashboard con SUPER DEBUG
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const WorkoutsPage(),
    const StatsPage(),
    const SubscriptionScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.fitness_center),
      label: 'Allenamenti',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      label: 'Statistiche',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.card_membership),
      label: 'Abbonamento',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FitGymTrack',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          // 💳 SUPER Indicatore stato Stripe intelligente
          BlocBuilder<StripeBloc, StripeState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  state is StripeReady
                      ? Icons.payment
                      : state is StripeErrorState
                      ? Icons.payment_outlined
                      : Icons.hourglass_empty,
                  color: state is StripeReady
                      ? Colors.green
                      : state is StripeErrorState
                      ? Colors.orange
                      : Colors.grey,
                ),
                onPressed: () => _showStripeStatusDialog(context, state),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifiche in arrivo!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().logout();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: _navItems,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }

  /// Mostra dialog dettagliato dello stato Stripe
  void _showStripeStatusDialog(BuildContext context, StripeState state) {
    String title;
    String message;
    Color color;
    List<Widget> actions = [];

    if (state is StripeReady) {
      title = '✅ Stripe Ready';
      message = 'Payment system is fully operational.\n\n'
          'Customer: ${state.customer?.id ?? 'Not set'}\n'
          'Subscription: ${state.subscription?.id ?? 'None'}';
      color = Colors.green;

      actions.add(
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.go('/payment/donation');
          },
          child: const Text('Test Payment'),
        ),
      );
    } else if (state is StripeErrorState) {
      title = '⚠️ Stripe Offline';
      message = 'Payment system is not available.\n\n'
          'Error: ${state.message}\n\n'
          'The app will work in offline mode.';
      color = Colors.orange;

      actions.add(
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<StripeBloc>().add(const InitializeStripeEvent());
          },
          child: const Text('Retry'),
        ),
      );
    } else {
      title = '⏳ Stripe Initializing';
      message = 'Payment system is starting up...\n\n'
          'Please wait a moment.';
      color = Colors.blue;
    }

    actions.addAll([
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          _runSuperDebugAndShow(context);
        },
        child: const Text('Run Debug'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    ]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: actions,
      ),
    );
  }

  /// 🚀 Esegue il SUPER debug Stripe e mostra il risultato
  Future<void> _runSuperDebugAndShow(BuildContext context) async {
    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Running SUPER Stripe diagnostic...',
                style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      final dio = getIt<Dio>();
      final report = await StripeSuperDebug.runSuperDiagnostic(
        dio: dio,
        verbose: true,
      );

      // Chiudi loading
      Navigator.of(context).pop();

      // Mostra risultato SUPER
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('🚀 SUPER Stripe Diagnostic'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📊 Overall Score: ${report.overallScore}/100',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('🏥 System Status: ${report.systemStatus}',
                    style: TextStyle(
                      color: report.systemStatus == 'EXCELLENT' || report.systemStatus == 'GOOD'
                          ? Colors.green
                          : report.systemStatus == 'NEEDS_ATTENTION'
                          ? Colors.orange
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 16),

                Text('📋 Configuration: ${report.configurationScore}/100'),
                Text('🌐 Connectivity: ${report.connectivityScore}/100'),
                Text('🔐 Authentication: ${report.authenticationScore}/100'),
                Text('🎯 Endpoints: ${report.stripeEndpointsScore}/100'),

                const SizedBox(height: 16),

                if (report.recommendations.isNotEmpty) ...[
                  const Text('💡 Top Recommendations:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...report.recommendations.take(3).map((rec) =>
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('• ${rec.replaceAll(RegExp(r'[🔑⚠️🌐📁🔐🎯]'), '').trim()}',
                            style: const TextStyle(fontSize: 12)),
                      )),
                ],

                const SizedBox(height: 16),

                if (report.quickFixes.isNotEmpty) ...[
                  const Text('🔧 Quick Fixes:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...report.quickFixes.take(3).map((fix) =>
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('• $fix', style: const TextStyle(fontSize: 12)),
                      )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                StripeSuperDebug.printFullReport(report);
              },
              child: const Text('Print Full Report'),
            ),
            if (report.stripeEndpointsScore >= 75)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/payment/donation');
                },
                child: const Text('🚀 Test Real Payment'),
              ),
          ],
        ),
      );

    } catch (e) {
      // Chiudi loading
      Navigator.of(context).pop();

      // Mostra errore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SUPER Debug failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ============================================================================
// PAGINE con SUPER DEBUG INTEGRATION
// ============================================================================

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benvenuto!',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 8.h),

          Text(
            'Pronti per un altro allenamento?',
            style: TextStyle(
              fontSize: 16.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),

          SizedBox(height: 24.h),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              children: [
                _buildStatCard(
                  context,
                  'Allenamenti\nCompleti',
                  '12',
                  Icons.fitness_center,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Questa\nSettimana',
                  '3',
                  Icons.calendar_today,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Tempo\nTotale',
                  '8h 45m',
                  Icons.schedule,
                  Colors.orange,
                ),
                _buildStatCard(
                  context,
                  'Prossimo\nAllenamento',
                  'Oggi',
                  Icons.notifications_active,
                  Colors.purple,
                ),
              ],
            ),
          ),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/workouts'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Inizia Allenamento'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/subscription'),
                  icon: const Icon(Icons.card_membership),
                  label: const Text('Abbonamento'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // 🧪 PULSANTE QUICK TEST STRIPE SUPER - PRINCIPALE
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _runSuperQuickTestAndShow(context),
              icon: const Icon(Icons.flash_on),
              label: const Text('🧪 SUPER Quick Test ⚡'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          SizedBox(height: 8.h),

          // 🔍 PULSANTE SUPER DEBUG COMPLETO - SECONDARIO
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _runSuperDebugAndShow(context),
              icon: const Icon(Icons.bug_report),
              label: const Text('🚀 SUPER Debug Completo'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32.sp,
              color: color,
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🧪 Esegue il SUPER quick test e mostra il risultato
  Future<void> _runSuperQuickTestAndShow(BuildContext context) async {
    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Running SUPER quick test...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      final dio = getIt<Dio>();
      final results = await StripeSuperDebug.runQuickTest(dio);

      // Chiudi loading
      Navigator.of(context).pop();

      // Mostra risultato
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('🧪 SUPER Quick Test'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Status: ${results.statusText}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: results.overallSuccess ? Colors.green : Colors.red,
                ),
              ),
              Text('Score: ${results.score}/100'),
              const SizedBox(height: 16),

              Text('🔧 Configuration: ${results.configValid ? "✅" : "❌"}'),
              Text('🌐 API Connectivity: ${results.apiReachable ? "✅" : "❌"}'),
              Text('🔐 Authentication: ${results.authWorking ? "✅" : "❌"}'),
              Text('🎯 Stripe System: ${results.stripeWorking ? "✅" : "❌"}'),

              if (results.stripeError != null) ...[
                const SizedBox(height: 8),
                Text('Error: ${results.stripeError}',
                    style: const TextStyle(fontSize: 12, color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (!results.overallSuccess)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _runSuperDebugAndShow(context);
                },
                child: const Text('Full Debug'),
              ),
            if (results.stripeWorking)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/payment/donation');
                },
                child: const Text('🚀 Test Payment'),
              ),
          ],
        ),
      );

    } catch (e) {
      // Chiudi loading
      Navigator.of(context).pop();

      // Mostra errore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SUPER Quick test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🚀 Esegue il SUPER debug completo e mostra il risultato
  Future<void> _runSuperDebugAndShow(BuildContext context) async {
    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Running SUPER diagnostic...', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text('This may take a few moments...', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );

    try {
      final dio = getIt<Dio>();
      final report = await StripeSuperDebug.runSuperDiagnostic(
        dio: dio,
        verbose: true,
      );

      // Chiudi loading
      Navigator.of(context).pop();

      // Mostra risultato dettagliato
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('🚀 SUPER Diagnostic Report'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📊 Overall Score: ${report.overallScore}/100',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('🏥 System Status: ${report.systemStatus}',
                    style: TextStyle(
                      color: report.systemStatus == 'EXCELLENT' || report.systemStatus == 'GOOD'
                          ? Colors.green
                          : report.systemStatus == 'NEEDS_ATTENTION'
                          ? Colors.orange
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 16),

                const Text('📋 Detailed Scores:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('   Configuration: ${report.configurationScore}/100'),
                Text('   Connectivity: ${report.connectivityScore}/100'),
                Text('   Authentication: ${report.authenticationScore}/100'),
                Text('   Stripe Endpoints: ${report.stripeEndpointsScore}/100'),

                const SizedBox(height: 16),

                const Text('🎯 Endpoint Results:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...report.endpointResults.entries.map((entry) {
                  final status = entry.value.isWorking ? "✅" : entry.value.isReachable ? "⚠️" : "❌";
                  return Text('   $status ${entry.key}: ${entry.value.statusMessage}');
                }),

                const SizedBox(height: 16),

                if (report.recommendations.isNotEmpty) ...[
                  const Text('💡 Recommendations:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...report.recommendations.take(5).map((rec) =>
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('• ${rec.replaceAll(RegExp(r'[🔑⚠️🌐📁🔐🎯]'), '').trim()}',
                            style: const TextStyle(fontSize: 11)),
                      )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                StripeSuperDebug.printFullReport(report);
              },
              child: const Text('Print Console'),
            ),
            if (report.stripeEndpointsScore >= 50)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/payment/donation');
                },
                child: const Text('🚀 Test Payment'),
              ),
          ],
        ),
      );

    } catch (e) {
      // Chiudi loading
      Navigator.of(context).pop();

      // Mostra errore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SUPER Debug failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class WorkoutsPage extends StatelessWidget {
  const WorkoutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkoutPlansScreen();
  }
}

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Statistiche',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text('Prossima implementazione...'),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Profilo',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text('Prossima implementazione...'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/subscription'),
            icon: const Icon(Icons.card_membership),
            label: const Text('Vai all\'Abbonamento'),
          ),
        ],
      ),
    );
  }
}