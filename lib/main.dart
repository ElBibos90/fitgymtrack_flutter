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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📱 Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('[CONSOLE] [main]🚀 FITGYMTRACK STARTED');

  // Initialize dependency injection
  await DependencyInjection.init();

  runApp(const FitGymTrackApp());
}

class FitGymTrackApp extends StatelessWidget {
  const FitGymTrackApp({super.key});

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

            // STRIPE BLOC PROVIDER - Lazy loading
            BlocProvider<StripeBloc>(
              create: (context) => getIt<StripeBloc>(),
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

              Text(
                'Caricamento...',
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _previousIndex = 0; // 🚀 NUOVO: Traccia la tab precedente

  // 🚀 NUOVO: Controller per accedere ai metodi delle tab che supportano lazy loading
  final WorkoutTabController _workoutController = WorkoutTabController();

  // 🚀 AGGIORNATO: Lista delle pagine con il controller
  late final List<Widget> _pages = [
    const DashboardPage(),
    WorkoutPlansScreen(controller: _workoutController), // Usa il controller
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
  void initState() {
    super.initState();

    // 🔧 CRITICAL FIX: Load subscription immediately when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[CONSOLE] [main]🔧 Loading subscription on app start...');
      context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent(checkExpired: true));
    });
  }

  /// 🚀 NUOVO: Gestisce il cambio di tab con lazy loading
  void _onTabTapped(int index) {
    print('[CONSOLE] [main]🔄 Tab changed: $_selectedIndex -> $index');

    _previousIndex = _selectedIndex;

    setState(() {
      _selectedIndex = index;
    });

    // 🚀 NUOVO: Gestisci lazy loading per le tab specifiche
    _handleTabVisibilityChange(_previousIndex, index);
  }

  /// 🚀 NUOVO: Gestisce la visibilità delle tab per il lazy loading
  void _handleTabVisibilityChange(int previousIndex, int currentIndex) {
    // Tab Workouts (index 1)
    if (currentIndex == 1) {
      // L'utente ha selezionato la tab workout
      _workoutController.onTabVisible();
      print('[CONSOLE] [main]👁️ Workout tab became visible');
    } else if (previousIndex == 1) {
      // L'utente ha lasciato la tab workout
      _workoutController.onTabHidden();
      print('[CONSOLE] [main]👁️ Workout tab became hidden');
    }

    // 🚀 FUTURE: Qui possiamo aggiungere lazy loading per altre tab se necessario
    // if (currentIndex == 2) {
    //   // Stats tab
    // } else if (currentIndex == 3) {
    //   // Subscription tab
    // }
  }

  void navigateToSubscriptionTab() {
    _onTabTapped(3); // Usa il nuovo metodo che gestisce lazy loading
  }

  /// 🚀 NUOVO: Metodo pubblico per forzare il reload della tab workout
  void forceWorkoutReload() {
    _workoutController.forceReload();
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
        onTap: _onTabTapped, // 🚀 AGGIORNATO: Usa il nuovo metodo
        items: _navItems,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }
}

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

          // Main action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 🚀 NUOVO: Prima di navigare ai workout, assicurati che la tab sia caricata
                    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?._onTabTapped(1); // Vai alla tab workout
                  },
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
                    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?.navigateToSubscriptionTab();
                  },
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

          // 🔧 FIXED: Premium status banner using SubscriptionBloc
          BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, state) {
              print('[CONSOLE] [main]🔧 Dashboard subscription state: ${state.runtimeType}');

              if (state is SubscriptionLoading) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12.w),
                      const Text('Caricamento abbonamento...'),
                    ],
                  ),
                );
              }

              if (state is SubscriptionLoaded) {
                final subscription = state.subscription;
                print('[CONSOLE] [main]🔧 Dashboard subscription: ${subscription.planName} - Premium: ${subscription.isPremium}');

                // 🎉 PREMIUM USER - Show thank you banner
                if (subscription.isPremium && !subscription.isExpired) {
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.teal.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Premium Attivo',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Grazie per il supporto! Hai accesso a tutte le funzionalità 🎉',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),
                        OutlinedButton(
                          onPressed: () {
                            final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                            homeState?.navigateToSubscriptionTab();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                          ),
                          child: const Text('Gestisci Abbonamento'),
                        ),
                      ],
                    ),
                  );
                }

                // 🚀 FREE USER - Show upgrade banner
                else {
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
              }

              // Error or other states - show minimal banner
              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Text(
                      'Piano Free Attivo',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ElevatedButton(
                      onPressed: () {
                        final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                        homeState?.navigateToSubscriptionTab();
                      },
                      child: const Text('Vai all\'Abbonamento'),
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