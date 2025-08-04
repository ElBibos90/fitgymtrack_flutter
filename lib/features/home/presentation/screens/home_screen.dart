// lib/features/home/presentation/screens/home_screen.dart - VERSIONE OTTIMIZZATA

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/utils/api_request_debouncer.dart';
import '../../../subscription/bloc/subscription_bloc.dart';
import '../../../workouts/presentation/screens/workout_plans_screen.dart';
import '../../../subscription/presentation/screens/subscription_screen.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../workouts/bloc/workout_blocs.dart';
import '../../../workouts/bloc/workout_history_bloc.dart';
import '../widgets/dashboard_page.dart';
import '../../../stats/presentation/screens/stats_screen.dart';
import '../../../../core/services/app_update_service.dart';

/// 🚀 PERFORMANCE OPTIMIZED: Home Screen con caricamento sequenziale intelligente
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  // 🚀 PERFORMANCE: Flag per controllo inizializzazione
  bool _isInitialDataLoaded = false;
  bool _isSubscriptionLoaded = false;
  bool _isWorkoutHistoryLoaded = false;

  // Controller per lazy loading delle tab
  final WorkoutTabController _workoutController = WorkoutTabController();

  // 🚀 PERFORMANCE: Map per tenere traccia dello stato di caricamento per tab
  final Map<int, bool> _tabInitialized = {
    0: false, // Dashboard
    1: false, // Workouts
    2: false, // Stats
    3: false, // Subscription
  };

  // ✅ Lista delle pagine con lazy initialization
  late final List<Widget Function()> _pageBuilders = [
        () => DashboardPage(
      onNavigateToWorkouts: () => _onTabTapped(1),
      onNavigateToAchievements: _handleAchievementsNavigation,
      onNavigateToProfile: _handleProfileNavigation,
    ),
        () => WorkoutPlansScreen(controller: _workoutController),
        () => const StatsScreen(),
        () => const SubscriptionScreen(),
  ];

  // Cache delle pagine per evitare ricostruzioni
  final Map<int, Widget> _cachedPages = {};

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
    WidgetsBinding.instance.addObserver(this);
    print('[CONSOLE] [home_screen]🚀 HomeScreen initialized');

    // 🚀 PERFORMANCE: Inizializzazione sequenziale post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeSequentially();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // WorkoutTabController non ha dispose() - solo detach
    ApiRequestDebouncer.clearCache('home_screen'); // Pulisci cache specifica
    super.dispose();
  }

  /// 🚀 PERFORMANCE: Inizializzazione sequenziale intelligente
  Future<void> _initializeSequentially() async {
    if (_isInitialDataLoaded) return;

    try {
      print('[CONSOLE] [home_screen]🚀 Starting sequential initialization...');

      // STEP 1: Verifica stato auth (già disponibile)
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated && authState is! AuthLoginSuccess) {
        print('[CONSOLE] [home_screen]❌ User not authenticated, skipping initialization');
        return;
      }

      int userId;
      if (authState is AuthAuthenticated) {
        userId = authState.user.id;
      } else if (authState is AuthLoginSuccess) {
        userId = authState.user.id;
      } else {
        return;
      }

      print('[CONSOLE] [home_screen]👤 User authenticated: $userId');

      // STEP 2: Carica subscription (priorità alta - necessaria per UI)
      await _loadSubscriptionWithDebouncing();

      // STEP 3: Carica workout history (priorità media - può essere ritardato)
      _loadWorkoutHistoryAsync(userId);

      // STEP 4: Inizializza dashboard (priorità bassa)
      _initializeDashboard();

      _isInitialDataLoaded = true;
      print('[CONSOLE] [home_screen]✅ Sequential initialization completed');

      // 🔧 NUOVO: Controllo aggiornamenti dopo l'inizializzazione
      _checkForAppUpdates();

    } catch (e) {
      print('[CONSOLE] [home_screen]❌ Initialization error: $e');
      // Non bloccare l'app per errori di inizializzazione
    }
  }

  /// 🔧 NUOVO: Controllo aggiornamenti dell'app
  void _checkForAppUpdates() async {
    try {
      print('[CONSOLE] [home_screen]🚀 Starting app update check...');
      final updateInfo = await AppUpdateService.checkForUpdates();
      print('[CONSOLE] [home_screen]📱 Update check result: ${updateInfo?.toString() ?? 'null'}');
      
      if (updateInfo != null && mounted) {
        print('[CONSOLE] [home_screen]✅ Update available, showing dialog...');
        AppUpdateService.showUpdateDialog(context, updateInfo);
      } else {
        print('[CONSOLE] [home_screen]ℹ️ No update available');
      }
    } catch (e) {
      print('[CONSOLE] [home_screen]❌ Update check error: $e');
    }
  }

  /// 🚀 PERFORMANCE: Carica subscription con debouncing
  Future<void> _loadSubscriptionWithDebouncing() async {
    if (_isSubscriptionLoaded) return;

    try {
      print('[CONSOLE] [home_screen]💳 Loading subscription with debouncing...');

      await ApiRequestDebouncer.debounceRequest<void>(
        key: 'subscription_check_expired',
        request: () async {
          context.read<SubscriptionBloc>().add(
            const LoadSubscriptionEvent(checkExpired: true),
          );
        },
      );

      _isSubscriptionLoaded = true;
      print('[CONSOLE] [home_screen]✅ Subscription loaded successfully');
    } catch (e) {
      print('[CONSOLE] [home_screen]❌ Subscription loading error: $e');
    }
  }

  /// 🚀 PERFORMANCE: Carica workout history in background
  void _loadWorkoutHistoryAsync(int userId) {
    print('[CONSOLE] [home_screen]📊 Loading workout history async...');

    // Non bloccare il main thread
    Future.microtask(() async {
      try {
        await ApiRequestDebouncer.debounceRequest<void>(
          key: 'workout_history_$userId',
          request: () async {
            context.read<WorkoutHistoryBloc>().add(
              GetWorkoutHistory(userId: userId),
            );
            // Non ritornare nulla, è void
          },
          delay: const Duration(milliseconds: 100), // Ritardo minimo
        );

        _isWorkoutHistoryLoaded = true;
        print('[CONSOLE] [home_screen]✅ Workout history loaded async');
      } catch (e) {
        print('[CONSOLE] [home_screen]❌ Workout history async error: $e');
      }
    });
  }

  /// 🚀 PERFORMANCE: Inizializza dashboard quando necessario
  void _initializeDashboard() {
    if (_tabInitialized[0] == true) return;

    print('[CONSOLE] [home_screen]📊 Initializing dashboard...');
    _tabInitialized[0] = true;

    // Marca dashboard come pronta
    if (mounted) {
      setState(() {
        // Trigger rebuild per mostrare dashboard
      });
    }
  }

  /// 🚀 PERFORMANCE: Lazy initialization per tab specifica
  void _initializeTabIfNeeded(int index) {
    if (_tabInitialized[index] == true) return;

    print('[CONSOLE] [home_screen]🎯 Initializing tab $index...');

    switch (index) {
      case 1: // Workouts
        _initializeWorkoutsTab();
        break;
      case 2: // Stats
        _initializeStatsTab();
        break;
      case 3: // Subscription
        _initializeSubscriptionTab();
        break;
    }

    _tabInitialized[index] = true;
  }

  void _initializeWorkoutsTab() {
    print('[CONSOLE] [home_screen]💪 Initializing workouts tab...');
    // Lazy load di workout blocs se necessario
  }

  void _initializeStatsTab() {
    print('[CONSOLE] [home_screen]📈 Initializing stats tab...');
    // Lazy load di plateau bloc se necessario
  }

  void _initializeSubscriptionTab() {
    print('[CONSOLE] [home_screen]💳 Initializing subscription tab...');
    // Già caricato nell'inizializzazione sequenziale
  }

  /// 🚀 PERFORMANCE: Ottimizzato tab navigation
  void _onTabTapped(int index) {
    if (_selectedIndex == index) return; // Evita tap duplicati

    print('[CONSOLE] [home_screen]🎯 Tab tapped: $index');

    // Inizializza tab se necessario
    _initializeTabIfNeeded(index);

    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });

    _handleTabVisibilityChange(_previousIndex, index);
  }

  /// Ottieni page per index con lazy loading
  Widget _getPageForIndex(int index) {
    // Usa cache se disponibile
    if (_cachedPages.containsKey(index)) {
      return _cachedPages[index]!;
    }

    // Crea page e mettila in cache
    final page = _pageBuilders[index]();
    _cachedPages[index] = page;

    return page;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if ((state is AuthAuthenticated || state is AuthLoginSuccess) && !_isInitialDataLoaded) {
          // Re-inizializza se auth cambia
          _initializeSequentially();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(
            _pageBuilders.length,
                (index) => _getPageForIndex(index),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(
          Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }

  // ============================================================================
  // UI BUILDING METHODS (da codice esistente ma ottimizzati)
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
            Icons.settings,
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
          ),
          onPressed: _handleSettingsNavigation,
        ),
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.indigo600,
        unselectedItemColor: isDarkMode ? Colors.white54 : AppColors.textSecondary,
        selectedFontSize: 12.sp,
        unselectedFontSize: 12.sp,
        items: _navItems,
      ),
    );
  }

  // ============================================================================
  // EVENT HANDLERS (da codice esistente)
  // ============================================================================

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
    ApiRequestDebouncer.clearAllCache(); // Pulisci cache al logout
  }

  void _handleAchievementsNavigation() {
    print('[CONSOLE] [home_screen]🏆 Navigate to achievements');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Achievement - Feature in arrivo!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleProfileNavigation() {
    print('[CONSOLE] [home_screen]👤 Navigate to profile');
    // ✅ FIXED: Naviga alla ProfileScreen esistente
    context.push('/profile');
  }

  void _handleSettingsNavigation() {
    print('[CONSOLE] [home_screen]⚙️ Navigate to settings');
    context.push('/settings');
  }

  /// ✅ Navigation helpers (da codice esistente)
  void navigateToWorkouts() {
    print('[CONSOLE] [home_screen]🏋️ Navigating to workouts tab via callback');
    _onTabTapped(1);
  }

  void navigateToSubscription() {
    print('[CONSOLE] [home_screen]💳 Navigating to subscription tab via callback');
    _onTabTapped(3);
  }

  void navigateToStats() {
    print('[CONSOLE] [home_screen]📊 Navigating to stats tab via callback');
    _onTabTapped(2);
  }
}