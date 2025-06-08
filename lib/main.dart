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

// 🔧 CONFIGURATION FLAGS
const bool ENABLE_AUTO_DEBUG = false; // 🚨 DISABLED for clean user testing
const bool ENABLE_DEBUG_BUTTONS = true; // Keep manual debug available
const bool PRODUCTION_MODE = false; // Will be true for production

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📱 BLOCCA ORIENTAMENTO - SOLO PORTRAIT
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('[CONSOLE]🚀 FITGYMTRACK STARTED - CLEAN USER TESTING MODE');
  print('[CONSOLE]📱 App orientation locked to PORTRAIT only');
  print('[CONSOLE]🧪 Auto-debug DISABLED - Testing natural user flow');

  // 🔧 Inizializzazione dependency injection
  await DependencyInjection.init();

  // 💳 SILENT configurazione check (no verbose output)
  print('[CONSOLE]🔍 Running silent Stripe configuration check...');
  final stripeCheck = await StripeConfigurationChecker.checkConfiguration();

  // Only print summary for clean testing
  print('[CONSOLE]✅ Stripe Configuration: ${stripeCheck.isValid ? "VALID" : "NEEDS ATTENTION"}');

  // 💳 Verifica salute sistema generale
  final systemHealthy = DependencyInjection.checkSystemHealth();
  print('[CONSOLE]🏥 System health: ${systemHealthy ? "✅ HEALTHY" : "❌ ISSUES"}');

  // 🧪 BACKGROUND DEBUG - Only if enabled
  if (ENABLE_AUTO_DEBUG) {
    print('[CONSOLE]🚀 Running background diagnostic...');
    _runSuperStripeDebugInBackground();
  } else {
    print('[CONSOLE]🧪 Auto-debug disabled - Clean testing mode active');
  }

  runApp(FitGymTrackApp(
    stripeConfigValid: stripeCheck.isValid,
    productionMode: PRODUCTION_MODE,
  ));
}

/// 🚀 Background diagnostic (only when ENABLE_AUTO_DEBUG = true)
Future<void> _runSuperStripeDebugInBackground() async {
  try {
    print('[CONSOLE]🚀 [BACKGROUND] Running diagnostic...');
    await Future.delayed(const Duration(seconds: 3));

    final dio = getIt<Dio>();
    final report = await StripeSuperDebug.runSuperDiagnostic(
      dio: dio,
      verbose: false, // Silent background mode
    );

    print('[CONSOLE]🚀 [BACKGROUND] Diagnostic completed - Score: ${report.overallScore}/100');
    print('[CONSOLE]🏥 [BACKGROUND] Status: ${report.systemStatus}');

  } catch (e) {
    print('[CONSOLE]❌ [BACKGROUND] Diagnostic failed: $e');
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

            // SUBSCRIPTION & PAYMENT BLOC PROVIDERS
            BlocProvider<SubscriptionBloc>(
              create: (context) => getIt<SubscriptionBloc>(),
            ),

            // 💳 STRIPE BLOC PROVIDER - CLEAN INITIALIZATION
            BlocProvider<StripeBloc>(
              create: (context) {
                final stripeBloc = getIt<StripeBloc>();

                // 🔧 CLEAN initialization - only if config is valid
                if (stripeConfigValid && !StripeConfig.isDemoMode) {
                  print('[CONSOLE]💳 Initializing Stripe for clean testing...');
                  stripeBloc.add(const InitializeStripeEvent());
                } else if (StripeConfig.isDemoMode) {
                  print('[CONSOLE]⚠️ STRIPE: Demo mode - limited functionality');
                } else {
                  print('[CONSOLE]❌ STRIPE: Invalid configuration');
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

// 🚀 CLEAN SplashScreen - No aggressive debug
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _stripeStatus = 'Connecting...';

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

    // 💳 CLEAN Stripe initialization
    _initializeStripeClean();
  }

  Future<void> _initializeStripeClean() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        if (StripeConfig.isDemoMode) {
          setState(() {
            _stripeStatus = 'Demo mode';
          });
        } else if (!StripeConfig.isValidKey(StripeConfig.publishableKey)) {
          setState(() {
            _stripeStatus = 'Configuration needed';
          });
        } else {
          setState(() {
            _stripeStatus = 'Connecting...';
          });
          context.read<StripeBloc>().add(const InitializeStripeEvent());
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _stripeStatus = 'Offline mode';
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

              // 💳 CLEAN Stripe status indicator
              BlocListener<StripeBloc, StripeState>(
                listener: (context, state) {
                  if (state is StripeReady) {
                    setState(() {
                      _stripeStatus = 'Ready';
                    });
                  } else if (state is StripeErrorState) {
                    setState(() {
                      _stripeStatus = 'Offline mode';
                    });
                  } else if (state is StripeInitializing) {
                    setState(() {
                      _stripeStatus = 'Connecting...';
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
                      icon = Icons.info_outline;
                      color = Colors.orange;
                      statusText = 'Offline mode';
                    } else {
                      icon = Icons.payment;
                      color = Colors.blue;
                      statusText = _stripeStatus;
                    }

                    return Row(
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

// 🏠 CLEAN HomeScreen - User-focused dashboard
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
          // 💳 CLEAN Stripe status indicator
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

          // 🔧 DEBUG TOOLS - Only if enabled
          if (ENABLE_DEBUG_BUTTONS) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.bug_report, color: Colors.grey),
              onSelected: (value) {
                switch (value) {
                  case 'quick_test':
                    _runQuickTest(context);
                    break;
                  case 'full_debug':
                    _runFullDebug(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'quick_test',
                  child: Row(
                    children: [
                      Icon(Icons.flash_on, size: 16),
                      SizedBox(width: 8),
                      Text('Quick Test'),
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
    } else {
      title = '⏳ Connecting';
      message = 'Payment system is starting up...\n\n'
          'Please wait a moment.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (state is StripeErrorState)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<StripeBloc>().add(const InitializeStripeEvent());
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 🧪 Manual debug tools
  Future<void> _runQuickTest(BuildContext context) async {
    if (!ENABLE_DEBUG_BUTTONS) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Running quick test...')),
    );

    try {
      final dio = getIt<Dio>();
      final results = await StripeSuperDebug.runQuickTest(dio);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quick test: ${results.statusText} (${results.score}/100)'),
          backgroundColor: results.overallSuccess ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quick test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
              if (state is StripeReady) {
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
              }
              return const SizedBox.shrink();
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