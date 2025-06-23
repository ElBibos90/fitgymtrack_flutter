// lib/features/home/presentation/screens/home_screen.dart (VERSIONE COMPLETA)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../subscription/bloc/subscription_bloc.dart';
import '../../../workouts/presentation/screens/workout_plans_screen.dart';
import '../../../subscription/presentation/screens/subscription_screen.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../workouts/bloc/workout_blocs.dart';
import '../../../workouts/bloc/workout_history_bloc.dart';
import '../widgets/dashboard_page.dart';

/// Home Screen refactorizzato - FIX COMPLETO per problema Attività Recente
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  // 🔧 FIX: Flag per evitare inizializzazioni multiple
  bool _isDataInitialized = false;

  // Controller per lazy loading delle tab
  final WorkoutTabController _workoutController = WorkoutTabController();

  // Lista delle pagine - Pulita e organizzata
  late final List<Widget> _pages = [
    const DashboardPage(), // 🆕 Widget separato pulito
    WorkoutPlansScreen(controller: _workoutController),
    const StatsPage(), // TODO: Creare StatsPage separata
    const SubscriptionScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_rounded),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.fitness_center_rounded),
      label: 'Allenamenti',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics_rounded),
      label: 'Statistiche',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.workspace_premium_rounded),
      label: 'Premium',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 🔧 FIX: Inizializza solo dopo che il widget è costruito
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndInitializeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: _handleAuthStateChange, // 🔧 FIX: Listener migliorato
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: _buildBottomNavigation(isDarkMode),
      ),
    );
  }

  // ============================================================================
  // 🔧 FIX: AUTH STATE CHANGE HANDLER MIGLIORATO
  // ============================================================================

  void _handleAuthStateChange(BuildContext context, AuthState state) {
    print('[CONSOLE] [home_screen]🔍 Auth state changed: ${state.runtimeType}');

    if (state is AuthLoginSuccess || state is AuthAuthenticated) {
      // 🔧 FIX: Inizializza dati immediatamente quando auth è confermato
      if (!_isDataInitialized) {
        print('[CONSOLE] [home_screen]✅ Auth confirmed, initializing data...');
        _initializeDataImmediately(state);
      }
      // Mantieni anche la logica originale di _reloadUserData
      int userId;
      if (state is AuthAuthenticated) {
        userId = state.user.id;
      } else {
        userId = (state as AuthLoginSuccess).user.id;
      }
      print('[CONSOLE] [home_screen]✅ User authenticated, reloading data for userId: $userId...');
      _reloadUserData(userId);
    } else if (state is AuthUnauthenticated || state is AuthError) {
      // Reset flag se l'utente si disconnette
      _isDataInitialized = false;
      print('[CONSOLE] [home_screen]❌ User unauthenticated, resetting data flag');
    }
  }

  // ============================================================================
  // 🔧 FIX: METODI DI INIZIALIZZAZIONE MIGLIORATI
  // ============================================================================

  /// Controlla lo stato auth e inizializza se necessario
  void _checkAndInitializeData() {
    final authState = context.read<AuthBloc>().state;
    print('[CONSOLE] [home_screen]🔍 Checking auth state: ${authState.runtimeType}');

    if ((authState is AuthAuthenticated || authState is AuthLoginSuccess) && !_isDataInitialized) {
      _initializeDataImmediately(authState);
    } else if (authState is AuthInitial) {
      // Solo se è davvero iniziale, controlla lo stato
      print('[CONSOLE] [home_screen]🔄 Auth state is initial, checking status...');
      context.read<AuthBloc>().add(const AuthStatusChecked());
    }
  }

  /// 🔧 FIX: Inizializzazione immediata e sicura dei dati
  void _initializeDataImmediately(AuthState authState) {
    if (_isDataInitialized) {
      print('[CONSOLE] [home_screen]⚠️ Data already initialized, skipping...');
      return;
    }

    print('[CONSOLE] [home_screen]🚀 Starting immediate data initialization...');
    _isDataInitialized = true;

    // Estrai userId dallo stato auth
    int userId;
    if (authState is AuthAuthenticated) {
      userId = authState.user.id;
    } else if (authState is AuthLoginSuccess) {
      userId = authState.user.id;
    } else {
      print('[CONSOLE] [home_screen]❌ Invalid auth state for data initialization');
      _isDataInitialized = false;
      return;
    }

    print('[CONSOLE] [home_screen]📚 Initializing data for userId: $userId');

    // 1. Carica subscription immediatamente
    context.read<SubscriptionBloc>().add(
      const LoadSubscriptionEvent(checkExpired: true),
    );

    // 2. 🔧 FIX: Carica workout history immediatamente con delay minimo per stabilità
    Future.microtask(() {
      if (mounted) {
        print('[CONSOLE] [home_screen]📊 Loading workout history for userId: $userId');
        context.read<WorkoutHistoryBloc>().add(
          GetWorkoutHistory(userId: userId),
        );

        // 🔧 RIMOSSO: GetUserStats che causa errore 404
        // context.read<WorkoutHistoryBloc>().add(
        //   GetUserStats(userId: userId),
        // );
      }
    });

    print('[CONSOLE] [home_screen]✅ Data initialization completed for userId: $userId');
  }

  /// Inizializza tutti i dati necessari (METODO ORIGINALE MANTENUTO)
  void _initializeData() {
    print('[CONSOLE] [home_screen]🔧 Initializing dashboard data...');

    // Carica subscription
    context.read<SubscriptionBloc>().add(
      const LoadSubscriptionEvent(checkExpired: true),
    );

    // Verifica stato auth - FIX: Gestisci anche AuthLoginSuccess
    final authState = context.read<AuthBloc>().state;
    print('[CONSOLE] [home_screen]🔍 Auth state: ${authState.runtimeType}');

    if (authState is AuthAuthenticated || authState is AuthLoginSuccess) {
      // FIX: Gestisci entrambi gli stati di auth
      int userId;
      if (authState is AuthAuthenticated) {
        userId = authState.user.id;
      } else {
        userId = (authState as AuthLoginSuccess).user.id;
      }

      print('[CONSOLE] [home_screen]✅ User is authenticated, loading data for userId: $userId');
      _reloadUserData(userId);
    } else {
      print('[CONSOLE] [home_screen]⚠️ User not authenticated, current state: ${authState.runtimeType}');

      // FIX: Solo force auth check se è davvero necessario
      if (authState is AuthInitial || authState is AuthUnauthenticated) {
        context.read<AuthBloc>().add(const AuthStatusChecked());

        // Retry dopo delay solo se necessario
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            final newState = context.read<AuthBloc>().state;
            if (newState is AuthInitial || newState is AuthUnauthenticated) {
              _initializeData();
            }
          }
        });
      }
    }
  }

  /// Ricarica dati specifici dell'utente (METODO ORIGINALE MANTENUTO)
  void _reloadUserData(int userId) {
    print('[CONSOLE] [home_screen]📚 Loading data for userId: $userId');

    // Carica workout history
    context.read<WorkoutHistoryBloc>().add(
      GetWorkoutHistory(userId: userId),
    );

    // 🔧 RIMOSSO: GetUserStats che causa errore 404
    // context.read<WorkoutHistoryBloc>().add(
    //   GetUserStats(userId: userId),
    // );

    print('[CONSOLE] [home_screen]✅ Data loading initiated for userId: $userId');
  }

  // ============================================================================
  // UI BUILDING METHODS
  // ============================================================================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      elevation: 0,
      backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.indigo600, AppColors.green600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.fitness_center,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'FitGymTrack',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.logout,
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
          ),
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: _navItems,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.indigo600,
        unselectedItemColor: isDarkMode ? Colors.white54 : AppColors.textSecondary,
        selectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  // ============================================================================
  // EVENT HANDLERS - Business logic separata
  // ============================================================================

  void _onTabTapped(int index) {
    print('[CONSOLE] [home_screen]🔄 Tab changed: $_selectedIndex -> $index');
    _previousIndex = _selectedIndex;
    setState(() {
      _selectedIndex = index;
    });
    _handleTabVisibilityChange(_previousIndex, index);
  }

  void _handleTabVisibilityChange(int previousIndex, int currentIndex) {
    if (currentIndex == 1) {
      _workoutController.onTabVisible();
      print('[CONSOLE] [home_screen]👁️ Workout tab became visible');
    } else if (previousIndex == 1) {
      _workoutController.onTabHidden();
      print('[CONSOLE] [home_screen]👁️ Workout tab became hidden');
    }
  }

  void _handleLogout() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  // ============================================================================
  // NAVIGATION HELPERS - Per quick actions
  // ============================================================================

  /// Naviga alla tab workout (chiamato da DashboardService)
  void navigateToWorkouts() {
    _onTabTapped(1);
  }

  /// Naviga alla tab subscription
  void navigateToSubscription() {
    _onTabTapped(3);
  }

  /// Naviga alla tab stats
  void navigateToStats() {
    _onTabTapped(2);
  }
}

// ============================================================================
// PLACEHOLDER CLASSES - Da implementare nelle prossime fasi
// ============================================================================

/// Placeholder per la pagina statistiche (FASE 3)
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Statistiche - Coming Soon',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}