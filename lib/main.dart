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
import 'core/utils/stripe_testing_utils.dart'; // 🚀 NUOVO: Import testing utils
import 'core/config/stripe_config.dart';

// 🔧 CONFIGURATION FLAGS
const bool ENABLE_AUTO_DEBUG = false; // 🚨 DISABLED for clean user testing
const bool ENABLE_DEBUG_BUTTONS = true; // Keep manual debug available
const bool ENABLE_STRIPE_TESTING = true; // 🚀 NUOVO: Enable testing features
const bool PRODUCTION_MODE = false; // Will be true for production

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📱 BLOCCA ORIENTAMENTO - SOLO PORTRAIT
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('[CONSOLE]🚀 FITGYMTRACK STARTED - LAZY STRIPE LOADING MODE');
  print('[CONSOLE]📱 App orientation locked to PORTRAIT only');
  print('[CONSOLE]💳 Stripe will be loaded ONLY when user needs payments');

  // 🔧 Inizializzazione dependency injection
  await DependencyInjection.init();

  // 🚀 NUOVO: Sistema di testing Stripe
  if (ENABLE_STRIPE_TESTING) {
    await _runStartupStripeTests();
  }

  // 💳 SILENT configurazione check (no verbose output)
  print('[CONSOLE]🔍 Running silent Stripe configuration check...');
  final stripeCheck = await StripeConfigurationChecker.checkConfiguration();

  // Only print summary for clean testing
  print('[CONSOLE]✅ Stripe Configuration: ${stripeCheck.isValid ? "VALID" : "NEEDS ATTENTION"}');

  // 💳 Verifica salute sistema generale
  final systemHealthy = DependencyInjection.checkSystemHealth();
  print('[CONSOLE]🏥 System health: ${systemHealthy ? "✅ HEALTHY" : "❌ ISSUES"}');

  runApp(FitGymTrackApp(
    stripeConfigValid: stripeCheck.isValid,
    productionMode: PRODUCTION_MODE,
  ));
}

/// 🚀 NUOVO: Esegue test di startup per Stripe
Future<void> _runStartupStripeTests() async {
  print('[CONSOLE]🧪 STARTUP STRIPE TESTING ENABLED');

  try {
    // 1. Quick configuration test
    print('[CONSOLE]🧪 [STARTUP] Testing Stripe configuration...');
    final configValid = StripeTestingUtils.validateConfiguration();
    print('[CONSOLE]🧪 [STARTUP] Configuration valid: ${configValid ? "✅" : "❌"}');

    // 2. Print test cards for reference
    if (configValid) {
      StripeTestingUtils.printTestCards();
    }

    // 3. Quick health check (non-blocking)
    print('[CONSOLE]🧪 [STARTUP] Running quick health check...');
    final isHealthy = await StripeTestingUtils.quickHealthCheck();
    print('[CONSOLE]🧪 [STARTUP] System healthy: ${isHealthy ? "✅" : "❌"}');

    print('[CONSOLE]🧪 [STARTUP] Stripe testing completed');

  } catch (e) {
    print('[CONSOLE]❌ [STARTUP] Stripe testing failed: $e');
  }
}

class FitGymTrackApp extends StatelessWidget {
  final bool stripeConfigValid;
  final bool productionMode;

  const FitGymTrackApp({
    super.key,
    required this.stripeConfigValid,
    this.productionMode = false,
  });

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

            // SUBSCRIPTION BLOC PROVIDER
            BlocProvider<SubscriptionBloc>(
              create: (context) => getIt<SubscriptionBloc>(),
            ),

            // 💳 STRIPE BLOC PROVIDER - LAZY LOADING ONLY
            BlocProvider<StripeBloc>(
              create: (context) {
                print('[CONSOLE]💳 StripeBloc created - waiting for user action');
                // 🔧 FIX: NON inizializzare Stripe automaticamente
                // Stripe verrà inizializzato solo quando l'utente ne avrà bisogno
                return getIt<StripeBloc>();
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

// 🚀 CLEAN SplashScreen - No Stripe loading
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

              // 💳 NO STRIPE STATUS - Solo loading app
              Text(
                'Caricamento app...',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🏠 CLEAN HomeScreen - User-focused dashboard con testing integrato
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

  /// 🔧 FIX: Method to navigate to subscription tab
  void navigateToSubscriptionTab() {
    setState(() {
      _selectedIndex = 3; // Subscription tab index
    });
  }

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
          // 💳 STRIPE STATUS - Solo quando inizializzato
          BlocBuilder<StripeBloc, StripeState>(
            builder: (context, state) {
              // 🔧 FIX: Mostra indicator solo se Stripe è stato inizializzato
              if (state is StripeInitial) {
                // Stripe non ancora inizializzato - non mostrare nulla
                return const SizedBox.shrink();
              }

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

          // 🔧 DEBUG TOOLS - Only if enabled
          if (ENABLE_DEBUG_BUTTONS) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.bug_report, color: Colors.grey),
              onSelected: (value) {
                switch (value) {
                  case 'init_stripe':
                    _initStripeManually(context);
                    break;
                  case 'full_debug':
                    _runFullDebug(context);
                    break;
                  case 'stripe_test': // 🚀 NUOVO
                    _runStripeTests(context);
                    break;
                  case 'post_payment_test': // 🚀 NUOVO
                    _runPostPaymentTest(context);
                    break;
                  case 'diagnostic_report': // 🚀 NUOVO
                    _generateDiagnosticReport(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'init_stripe',
                  child: Row(
                    children: [
                      Icon(Icons.payment, size: 16),
                      SizedBox(width: 8),
                      Text('Init Stripe'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'full_debug',
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16),
                      SizedBox(width: 8),
                      Text('Full Debug'),
                    ],
                  ),
                ),
                // 🚀 NUOVO: Opzioni di testing
                if (ENABLE_STRIPE_TESTING) ...[
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'stripe_test',
                    child: Row(
                      children: [
                        Icon(Icons.science, size: 16),
                        SizedBox(width: 8),
                        Text('Stripe Test'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'post_payment_test',
                    child: Row(
                      children: [
                        Icon(Icons.timeline, size: 16),
                        SizedBox(width: 8),
                        Text('Post-Payment Test'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'diagnostic_report',
                    child: Row(
                      children: [
                        Icon(Icons.assessment, size: 16),
                        SizedBox(width: 8),
                        Text('Diagnostic Report'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],

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

  /// 💳 Manual Stripe initialization for testing
  void _initStripeManually(BuildContext context) {
    print('[CONSOLE]🧪 [DEBUG] Manual Stripe initialization triggered');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Initializing Stripe manually...')),
    );

    context.read<StripeBloc>().add(const InitializeStripeEvent());
  }

  /// 🚀 NUOVO: Run comprehensive Stripe tests
  Future<void> _runStripeTests(BuildContext context) async {
    if (!ENABLE_STRIPE_TESTING) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Running comprehensive Stripe tests...')),
    );

    try {
      final result = await StripeTestingUtils.runFullSystemTest(verbose: true);

      final message = 'Stripe Test: ${result.success ? "PASS" : "FAIL"} (${result.overallScore}/100)';
      final backgroundColor = result.success ? Colors.green : Colors.red;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );

      // Show detailed results dialog
      if (context.mounted) {
        _showTestResultDialog(context, 'Stripe System Test', result.success, [
          'Overall Score: ${result.overallScore}/100',
          'Configuration: ${result.configurationValid ? "✅" : "❌"}',
          'Service Init: ${result.serviceInitialized ? "✅" : "❌"}',
          'Repository: ${result.repositoryConnected ? "✅" : "❌"}',
          'Google Pay: ${result.googlePaySupported ? "✅" : "❌"}',
          'Duration: ${result.testDuration.inMilliseconds}ms',
        ]);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stripe test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🚀 NUOVO: Run post-payment flow test
  Future<void> _runPostPaymentTest(BuildContext context) async {
    if (!ENABLE_STRIPE_TESTING) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testing post-payment flow...')),
    );

    try {
      final result = await StripeTestingUtils.simulatePostPaymentFlow(verbose: true);

      final message = 'Post-Payment Test: ${result.success ? "PASS" : "FAIL"} (${result.score}/100)';
      final backgroundColor = result.success ? Colors.green : Colors.orange;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );

      // Show detailed results dialog
      if (context.mounted) {
        _showTestResultDialog(context, 'Post-Payment Test', result.success, [
          'Score: ${result.score}/100',
          'Subscription Loading: ${result.subscriptionLoadingWorked ? "✅" : "❌"}',
          'Race Protection: ${result.customerRaceProtectionWorked ? "✅" : "❌"}',
          'Error Handling: ${result.errorHandlingWorked ? "✅" : "❌"}',
          'Duration: ${result.testDuration.inMilliseconds}ms',
        ]);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post-payment test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🚀 NUOVO: Generate comprehensive diagnostic report
  Future<void> _generateDiagnosticReport(BuildContext context) async {
    if (!ENABLE_STRIPE_TESTING) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating diagnostic report...')),
    );

    try {
      final report = await StripeTestingUtils.generateDiagnosticReport();

      // Print report to console
      StripeTestingUtils.printDiagnosticReport(report);

      final message = 'Diagnostic Report: ${report.overallHealthScore}/100 (Check console for details)';
      final backgroundColor = report.overallHealthScore >= 75 ? Colors.green : Colors.orange;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 4),
        ),
      );

      // Show summary dialog
      if (context.mounted) {
        _showDiagnosticSummaryDialog(context, report);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Diagnostic report failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🚀 NUOVO: Show test result dialog
  void _showTestResultDialog(BuildContext context, String title, bool success, List<String> details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: details.map((detail) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(detail, style: const TextStyle(fontSize: 14)),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 🚀 NUOVO: Show diagnostic summary dialog
  void _showDiagnosticSummaryDialog(BuildContext context, StripeDiagnosticReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diagnostic Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overall Health: ${report.overallHealthScore}/100',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('System Test: ${report.systemTestResult.overallScore}/100'),
            Text('Post-Payment: ${report.postPaymentTestResult.score}/100'),
            const SizedBox(height: 8),
            Text('Generated in: ${report.generationDuration.inMilliseconds}ms'),
            const SizedBox(height: 8),
            const Text('Check console for full details',
                style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 💳 CLEAN status dialog
  void _showStripeStatusDialog(BuildContext context, StripeState state) {
    String title;
    String message;

    if (state is StripeReady) {
      title = '✅ Payments Ready';
      message = 'Payment system is operational.\n\n'
          'You can make payments and manage your subscription.';
    } else if (state is StripeErrorState) {
      title = '⚠️ Offline Mode';
      message = 'Payment system is not available.\n\n'
          'App works in offline mode.\n'
          'You can still use workouts and stats.';
    } else if (state is StripeInitializing) {
      title = '⏳ Connecting';
      message = 'Payment system is starting up...\n\n'
          'Please wait a moment.';
    } else {
      title = '💤 Payments Not Loaded';
      message = 'Payment system will be loaded when you need it.\n\n'
          'Go to Subscription tab to enable payments.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (state is StripeErrorState || state is StripeInitial)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<StripeBloc>().add(const InitializeStripeEvent());
              },
              child: const Text('Load Now'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 🧪 Full debug
  Future<void> _runFullDebug(BuildContext context) async {
    if (!ENABLE_DEBUG_BUTTONS) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Running full diagnostic...')),
    );

    try {
      final dio = getIt<Dio>();
      final report = await StripeSuperDebug.runSuperDiagnostic(dio: dio, verbose: true);

      StripeSuperDebug.printFullReport(report);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Full diagnostic: ${report.systemStatus} (${report.overallScore}/100)'),
          backgroundColor: report.overallScore >= 75 ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Full diagnostic failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// 🏠 CLEAN Dashboard - Focus on user experience
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

          // 🚀 MAIN ACTION BUTTONS - User-focused with fixed navigation
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
                  onPressed: () {
                    // 🔧 FIX: Navigate to subscription tab instead of route
                    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?.navigateToSubscriptionTab();
                  },
                  icon: const Icon(Icons.card_membership),
                  label: const Text('Vai all\'Abbonamento'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // 🎯 PREMIUM UPGRADE CALL-TO-ACTION - Navigate to tab instead of route
          BlocBuilder<StripeBloc, StripeState>(
            builder: (context, state) {
              // 🔧 FIX: Mostra CTA solo se Stripe NON è in errore
              if (state is StripeErrorState) {
                return const SizedBox.shrink();
              }

              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Text(
                      '🚀 Passa a Premium',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Sblocca tutte le funzionalità per €4.99/mese',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),
                    ElevatedButton(
                      onPressed: () {
                        // 🔧 FIX: Navigate to subscription tab instead of separate route
                        final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                        homeState?.navigateToSubscriptionTab();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.purple.shade600,
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                      ),
                      child: const Text('Scopri Premium'),
                    ),
                  ],
                ),
              );
            },
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
}

// Altre pagine rimangono uguali
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