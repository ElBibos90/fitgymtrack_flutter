// lib/features/home/presentation/screens/home_screen.dart (VERSIONE FISSATA)

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

/// Home Screen refactorizzato - ✅ FIX COMPLETO per navigazione corretta
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

  // ✅ FIX: Lista delle pagine con callback functions per DashboardPage
  late final List<Widget> _pages = [
    DashboardPage(
      // 🆕 CALLBACK FUNCTIONS per navigazione corretta
      onNavigateToWorkouts: () => _onTabTapped(1),       // Tab Workouts
      onNavigateToAchievements: _handleAchievementsNavigation, // Placeholder per achievements
      onNavigateToProfile: _handleProfileNavigation,     // Placeholder per profilo
    ),
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
      icon: Icon(Icons.card_membership_rounded),
      label: 'Abbonamento',
    ),
  ];

  @override
  void initState() {
    super.initState();
    print('[CONSOLE] [home_screen]🚀 HomeScreen initialized');

    // Carica subscription all'avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SubscriptionBloc>().add(
          const LoadSubscriptionEvent(checkExpired: true),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated && !_isDataInitialized) {
          _isDataInitialized = true;
          _initializeData();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: _buildBottomNavigation(
          Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }

  /// Inizializza i dati per utente autenticato
  void _initializeData() {
    final authBloc = context.read<AuthBloc>();
    if (authBloc.state is AuthAuthenticated) {
      final authState = authBloc.state as AuthAuthenticated;
      print('[CONSOLE] [home_screen]📚 Initializing data for user: ${authState.user.id}');
      _reloadUserData(authState.user.id);
    }
  }

  /// Ricarica dati specifici dell'utente
  void _reloadUserData(int userId) {
    print('[CONSOLE] [home_screen]📚 Loading data for userId: $userId');

    // Carica workout history
    context.read<WorkoutHistoryBloc>().add(
      GetWorkoutHistory(userId: userId),
    );

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
  // ✅ FIX: NAVIGATION HELPERS - Per quick actions con logging
  // ============================================================================

  /// 🆕 Gestisce navigazione agli achievements (placeholder)
  void _handleAchievementsNavigation() {
    print('[CONSOLE] [home_screen]🏆 Achievement navigation requested');
    // TODO: Implementare navigazione agli achievements
    // Per ora mostra un messaggio
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Achievement - Feature in arrivo!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 🆕 Gestisce navigazione al profilo (placeholder)
  void _handleProfileNavigation() {
    print('[CONSOLE] [home_screen]👤 Profile navigation requested');
    // TODO: Implementare navigazione al profilo
    // Per ora mostra un messaggio
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profilo - Feature in arrivo!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// ✅ Naviga alla tab workout (chiamato da DashboardService via callback)
  void navigateToWorkouts() {
    print('[CONSOLE] [home_screen]🏋️ Navigating to workouts tab via callback');
    _onTabTapped(1);
  }

  /// ✅ Naviga alla tab subscription (chiamato da DashboardService via callback)
  void navigateToSubscription() {
    print('[CONSOLE] [home_screen]💳 Navigating to subscription tab via callback');
    _onTabTapped(3);
  }

  /// ✅ Naviga alla tab stats (chiamato da DashboardService via callback)
  void navigateToStats() {
    print('[CONSOLE] [home_screen]📊 Navigating to stats tab via callback');
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