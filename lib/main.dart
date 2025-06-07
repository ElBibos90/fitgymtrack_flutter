import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📱 BLOCCA ORIENTAMENTO - SOLO PORTRAIT
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('🚨 MAIN STARTED - Using REAL repositories only + STRIPE PAYMENTS!');
  print('📱 App orientation locked to PORTRAIT only');
  print('💳 Stripe payments system enabled');

  // 🔧 FIX: Inizializzazione semplificata - solo repository reali + Stripe
  await DependencyInjection.init();

  // 💳 Verifica configurazione Stripe all'avvio
  print('🔍 Checking Stripe configuration...');
  final stripeCheck = await StripeConfigurationChecker.checkConfiguration();
  StripeConfigurationChecker.printCheckResult(stripeCheck);

  // 💳 Verifica salute sistema generale
  final systemHealthy = DependencyInjection.checkSystemHealth();
  print('🏥 System health check: ${systemHealthy ? "✅ HEALTHY" : "❌ ISSUES"}');

  runApp(FitGymTrackApp(stripeConfigValid: stripeCheck.isValid));
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

            // 💳 STRIPE BLOC PROVIDER CON INIZIALIZZAZIONE FORZATA
            BlocProvider<StripeBloc>(
              create: (context) {
                final stripeBloc = getIt<StripeBloc>();
                // 🔧 FORZA inizializzazione immediata se configurazione è valida
                if (stripeConfigValid) {
                  print('💳 Forcing Stripe initialization...');
                  stripeBloc.add(const InitializeStripeEvent());
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

// SplashScreen
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

    // 💳 Forza inizializzazione Stripe
    _forceInitializeStripe();
  }

  Future<void> _forceInitializeStripe() async {
    try {
      print('💳 [SPLASH] Forcing Stripe initialization...');

      // Aspetta un po' per essere sicuri che il BLoC sia pronto
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        context.read<StripeBloc>().add(const InitializeStripeEvent());
        print('💳 [SPLASH] Stripe initialization event sent');
      }

    } catch (e) {
      print('⚠️ [SPLASH] Could not initialize Stripe: $e');
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

              // 💳 Indicatore Stripe più semplice
              BlocListener<StripeBloc, StripeState>(
                listener: (context, state) {
                  if (state is StripeReady && !_stripeInitialized) {
                    print('💳 [SPLASH] Stripe ready!');
                    setState(() {
                      _stripeInitialized = true;
                    });
                  } else if (state is StripeErrorState) {
                    print('💳 [SPLASH] Stripe error: ${state.message}');
                  }
                },
                child: BlocBuilder<StripeBloc, StripeState>(
                  builder: (context, state) {
                    if (state is StripeReady) {
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Pagamenti Stripe pronti',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    } else if (state is StripeErrorState) {
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.orange,
                                size: 16.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Modalità offline',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      return Text(
                        'Inizializzazione pagamenti...',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      );
                    }
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

// HomeScreen per la dashboard
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
          // 💳 Indicatore stato Stripe semplificato
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
                onPressed: () {
                  String message;
                  Color color;

                  if (state is StripeReady) {
                    message = '✅ Stripe configurato e funzionante';
                    color = Colors.green;
                  } else if (state is StripeErrorState) {
                    message = '⚠️ Errore Stripe: ${state.message}';
                    color = Colors.orange;
                  } else {
                    message = '⏳ Inizializzazione Stripe in corso...';
                    color = Colors.blue;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: color,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
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
}

// ============================================================================
// PAGINE
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

          // 💳 Pulsante per testare pagamenti Stripe - SEMPLIFICATO E MIGLIORATO
          SizedBox(
            width: double.infinity,
            child: BlocBuilder<StripeBloc, StripeState>(
              builder: (context, state) {
                final isReady = state is StripeReady;
                final isError = state is StripeErrorState;
                final isLoading = state is StripeInitializing;

                return ElevatedButton.icon(
                  onPressed: isReady
                      ? () {
                    print('💳 [DASHBOARD] Navigating to Stripe payment...');
                    context.go('/payment/donation');
                  }
                      : isError
                      ? () {
                    // 🔧 Retry inizializzazione
                    print('💳 [DASHBOARD] Retrying Stripe initialization...');
                    context.read<StripeBloc>().add(const InitializeStripeEvent());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔄 Tentativo di riconnessione Stripe...'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                      : null,
                  icon: isLoading
                      ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Icon(
                    isReady
                        ? Icons.payment
                        : isError
                        ? Icons.refresh
                        : Icons.payment_outlined,
                  ),
                  label: Text(
                    isReady
                        ? 'Testa Pagamento Stripe ✓'
                        : isError
                        ? 'Riprova Stripe'
                        : isLoading
                        ? 'Inizializzazione...'
                        : 'Stripe non pronto',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    backgroundColor: isReady
                        ? Colors.green
                        : isError
                        ? Colors.orange
                        : null,
                    foregroundColor: isReady || isError ? Colors.white : null,
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 16.h),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/stats'),
              icon: const Icon(Icons.analytics),
              label: const Text('Vedi Statistiche'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
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