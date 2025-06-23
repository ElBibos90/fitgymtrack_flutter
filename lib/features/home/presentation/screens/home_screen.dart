// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../subscription/bloc/subscription_bloc.dart';
import '../../../workouts/presentation/screens/workout_plans_screen.dart';
import '../../../subscription/presentation/screens/subscription_screen.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../subscription/models/subscription_models.dart';
import '../../../workouts/bloc/workout_blocs.dart';
import '../../../workouts/bloc/workout_history_bloc.dart'; // 🆕 Aggiunto per dati reali
import '../../../stats/models/user_stats_models.dart'; // 🔧 FIX: Import corretto per WorkoutHistory

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  // Controller per lazy loading delle tab
  final WorkoutTabController _workoutController = WorkoutTabController();

  // Lista delle pagine
  late final List<Widget> _pages = [
    const DashboardPage(),
    WorkoutPlansScreen(controller: _workoutController),
    const StatsPage(),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  /// 🆕 NUOVO: Inizializza tutti i dati necessari
  void _initializeData() {
    print('[CONSOLE] [home_screen]🔧 Initializing dashboard data...');

    // Carica subscription
    context.read<SubscriptionBloc>().add(
      const LoadSubscriptionEvent(checkExpired: true),
    );

    // 🔧 DEBUG: Verifica lo stato dell'auth
    final authState = context.read<AuthBloc>().state;
    print('[CONSOLE] [home_screen]🔍 Auth state type: ${authState.runtimeType}');

    if (authState is AuthAuthenticated) {
      final userId = authState.user.id;
      print('[CONSOLE] [home_screen]👤 User authenticated with ID: $userId');
      print('[CONSOLE] [home_screen]👤 User details: ${authState.user.username} (${authState.user.email})');

      // 🆕 Carica workout history per dati reali
      print('[CONSOLE] [home_screen]📚 Loading workout history for userId: $userId');
      context.read<WorkoutHistoryBloc>().add(
        GetWorkoutHistory(userId: userId),
      );

      // 🆕 Carica anche statistiche utente
      print('[CONSOLE] [home_screen]📊 Loading user stats for userId: $userId');
      context.read<WorkoutHistoryBloc>().add(
        GetUserStats(userId: userId),
      );
    } else {
      print('[CONSOLE] [home_screen]⚠️ User not authenticated! Auth state: $authState');

      // 🔧 Prova a forzare il check dello stato auth
      print('[CONSOLE] [home_screen]🔄 Forcing auth status check...');
      context.read<AuthBloc>().add(const AuthStatusChecked());

      // 🔧 Retry dopo 1 secondo
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _initializeData();
        }
      });
    }
  }

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

  void navigateToSubscriptionTab() {
    _onTabTapped(3);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 🔧 NUOVO: Listener per cambiamenti dello stato auth
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        print('[CONSOLE] [home_screen]🔄 Auth state changed to: ${state.runtimeType}');
        if (state is AuthAuthenticated) {
          print('[CONSOLE] [home_screen]✅ User became authenticated, reloading data...');
          _reloadUserData(state.user.id);
        } else if (state is AuthUnauthenticated) {
          print('[CONSOLE] [home_screen]❌ User became unauthenticated');
        }
      },
      child: Scaffold(
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
              icon: const Icon(Icons.logout_rounded),
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
              tooltip: 'Logout',
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onTabTapped,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 12.sp,
            ),
            items: _navItems,
          ),
        ),
      ),
    );
  }

  /// 🆕 NUOVO: Ricarica dati specifici dell'utente
  void _reloadUserData(int userId) {
    print('[CONSOLE] [home_screen]📚 Reloading data for userId: $userId');

    context.read<WorkoutHistoryBloc>().add(
      GetWorkoutHistory(userId: userId),
    );

    context.read<WorkoutHistoryBloc>().add(
      GetUserStats(userId: userId),
    );
  }
}

// ============================================================================
// DASHBOARD PAGE CON DATI REALI - NO MOCK! 🚀
// ============================================================================

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: () async {
          print('[CONSOLE] [dashboard]🔄 Pull-to-refresh triggered');

          // 🆕 Refresh sia subscription che workout data
          context.read<SubscriptionBloc>().add(
            const LoadSubscriptionEvent(checkExpired: true),
          );

          // 🔧 DEBUG: Verifica userId durante refresh
          final authState = context.read<AuthBloc>().state;
          print('[CONSOLE] [dashboard]🔍 Refresh - Auth state: ${authState.runtimeType}');

          if (authState is AuthAuthenticated) {
            final userId = authState.user.id;
            print('[CONSOLE] [dashboard]📚 Refresh - Reloading data for userId: $userId');

            context.read<WorkoutHistoryBloc>().add(
              RefreshWorkoutHistory(userId: userId),
            );
          } else {
            print('[CONSOLE] [dashboard]⚠️ Refresh - User not authenticated!');
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saluto personalizzato
              _buildGreeting(context, isDarkMode),
              SizedBox(height: 24.h),

              // Status Abbonamento (già reale)
              BlocBuilder<SubscriptionBloc, SubscriptionState>(
                builder: (context, state) {
                  return _buildSubscriptionSection(context, state, isDarkMode);
                },
              ),

              SizedBox(height: 32.h),

              // Quick Actions
              _buildQuickActions(context, isDarkMode),

              SizedBox(height: 24.h),

              // 🆕 SOSTITUITO: Ultima Attività con DATI REALI (no mock!)
              BlocBuilder<WorkoutHistoryBloc, WorkoutHistoryState>(
                builder: (context, state) {
                  return _buildRecentActivityReal(context, state, isDarkMode);
                },
              ),

              SizedBox(height: 24.h),

              // Banner donazioni
              _buildDonationBanner(context, isDarkMode),

              SizedBox(height: 24.h),

              // Sezione aiuto
              _buildHelpSection(context, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 Saluto personalizzato ottimizzato
  Widget _buildGreeting(BuildContext context, bool isDarkMode) {
    final hour = DateTime.now().hour;
    String greeting = 'Ciao! 👋';
    String subtitle = 'Pronto per allenarti oggi?';

    if (hour < 12) {
      greeting = 'Buongiorno! ☀️';
      subtitle = 'Iniziamo la giornata con energia!';
    } else if (hour < 18) {
      greeting = 'Buon pomeriggio! 🌤️';
      subtitle = 'Tempo per il tuo allenamento!';
    } else {
      greeting = 'Buonasera! 🌙';
      subtitle = 'Perfetto per un workout serale!';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDarkMode
            ? Border.all(color: Colors.grey.shade700, width: 0.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16.sp,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Sezione status abbonamento elegante
  Widget _buildSubscriptionSection(BuildContext context, SubscriptionState state, bool isDarkMode) {
    if (state is SubscriptionLoading) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state is SubscriptionLoaded) {
      final subscription = state.subscription;

      if (subscription.isPremium) {
        return _buildPremiumCard(context, subscription, isDarkMode);
      } else {
        return _buildFreeCard(context, isDarkMode);
      }
    }

    return _buildErrorCard(context, isDarkMode);
  }

  /// 🎨 Card Premium elegante
  Widget _buildPremiumCard(BuildContext context, Subscription subscription, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
            const Color(0xFF667EEA),
            const Color(0xFF764BA2),
          ]
              : [
            const Color(0xFF667EEA),
            const Color(0xFF764BA2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 28.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Premium Attivo',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            subscription.endDate != null
                ? 'Scade il ${_formatDate(subscription.endDate!)}'
                : 'Abbonamento attivo',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?.navigateToSubscriptionTab();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Gestisci Premium',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🎨 Card Free migliorata
  Widget _buildFreeCard(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Piano Free',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              final homeState = context.findAncestorStateOfType<_HomeScreenState>();
              homeState?.navigateToSubscriptionTab();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              minimumSize: Size(double.infinity, 44.h),
            ),
            child: Text(
              'Scopri Premium',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Card errore
  Widget _buildErrorCard(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Piano Free Attivo',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
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
  }

  /// 🚀 Quick Actions migliorata
  Widget _buildQuickActions(BuildContext context, bool isDarkMode) {
    final actions = [
      _QuickAction(
        icon: Icons.play_circle_fill_rounded,
        title: 'Inizia',
        color: const Color(0xFF48BB78),
        onTap: () => _navigateToWorkouts(context),
      ),
      _QuickAction(
        icon: Icons.fitness_center_rounded,
        title: 'Piani',
        color: const Color(0xFF667EEA),
        onTap: () => _navigateToWorkouts(context),
      ),
      _QuickAction(
        icon: Icons.trending_up_rounded,
        title: 'Progressi',
        color: const Color(0xFFED8936),
        onTap: () => _navigateToStats(context),
      ),
      _QuickAction(
        icon: Icons.settings_rounded,
        title: 'Settings',
        color: const Color(0xFF9F7AEA),
        onTap: () => _showSettingsDialog(context), // 🆕 Migliorato
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Azioni Rapide',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            childAspectRatio: 1.3,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(context, action, isDarkMode);
          },
        ),
      ],
    );
  }

  /// 🎨 Singola action card ottimizzata
  Widget _buildActionCard(BuildContext context, _QuickAction action, bool isDarkMode) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: isDarkMode
              ? Border.all(color: Colors.grey.shade700, width: 0.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                action.icon,
                color: action.color,
                size: 24.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Flexible(
              child: Text(
                action.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🆕 SOSTITUITO: Sezione Ultima Attività con DATI REALI (no mock!)
  Widget _buildRecentActivityReal(BuildContext context, WorkoutHistoryState state, bool isDarkMode) {
    // 🔧 DEBUG: Log dello stato ricevuto
    print('[CONSOLE] [dashboard]📊 WorkoutHistoryState: ${state.runtimeType}');

    if (state is WorkoutHistoryLoading) {
      print('[CONSOLE] [dashboard]⏳ WorkoutHistory loading...');
      return _buildRecentActivitySkeleton(context, isDarkMode);
    }

    if (state is WorkoutHistoryLoaded) {
      print('[CONSOLE] [dashboard]✅ WorkoutHistory loaded with ${state.workoutHistory.length} workouts');

      // 🔧 DEBUG: Log dei workout ricevuti
      for (int i = 0; i < state.workoutHistory.length && i < 3; i++) {
        final workout = state.workoutHistory[i];
        print('[CONSOLE] [dashboard]🏋️ Workout $i: ${workout.schedaNome} - ${workout.dataAllenamento} (ID: ${workout.id})');
      }

      final recentWorkouts = state.workoutHistory.take(3).toList();

      if (recentWorkouts.isEmpty) {
        print('[CONSOLE] [dashboard]📭 No workouts found - showing empty state');
        return _buildRecentActivityEmpty(context, isDarkMode);
      }

      print('[CONSOLE] [dashboard]📋 Showing ${recentWorkouts.length} recent workouts');
      return _buildRecentActivityWithData(context, recentWorkouts, isDarkMode);
    }

    if (state is WorkoutHistoryError) {
      print('[CONSOLE] [dashboard]❌ WorkoutHistory error: ${state.message}');
      return _buildRecentActivityError(context, state.message, isDarkMode);
    }

    // Stato iniziale - mostra scheletro
    print('[CONSOLE] [dashboard]🔄 WorkoutHistory initial state - showing skeleton');
    return _buildRecentActivitySkeleton(context, isDarkMode);
  }

  /// 🎨 Attività con dati reali
  Widget _buildRecentActivityWithData(BuildContext context, List<WorkoutHistory> workouts, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDarkMode
            ? Border.all(color: Colors.grey.shade700, width: 0.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ultima Attività',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToStats(context),
                child: Text(
                  'Vedi tutto',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF667EEA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Mostra i workout reali
          ...workouts.asMap().entries.map((entry) {
            final index = entry.key;
            final workout = entry.value;
            return _buildRealActivityItem(
              context,
              workout,
              isDarkMode,
              isLast: index == workouts.length - 1,
            );
          }),
        ],
      ),
    );
  }

  /// 🎨 Singolo item attività REALE
  Widget _buildRealActivityItem(BuildContext context, WorkoutHistory workout, bool isDarkMode, {bool isLast = false}) {
    // Determina icona e colore basati sul tipo di workout
    IconData icon = Icons.fitness_center_rounded;
    Color color = const Color(0xFF667EEA);

    if (workout.schedaNome.toLowerCase().contains('push')) {
      icon = Icons.fitness_center_rounded;
      color = const Color(0xFF48BB78);
    } else if (workout.schedaNome.toLowerCase().contains('pull')) {
      icon = Icons.sports_gymnastics_rounded;
      color = const Color(0xFFED8936);
    } else if (workout.schedaNome.toLowerCase().contains('leg')) {
      icon = Icons.directions_run_rounded;
      color = const Color(0xFF9F7AEA);
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${workout.schedaNome} Completato',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  _formatWorkoutTime(workout.dataAllenamento),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDarkMode ? Colors.grey.shade400 : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Loading skeleton per attività
  Widget _buildRecentActivitySkeleton(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: isDarkMode
            ? Border.all(color: Colors.grey.shade700, width: 0.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ultima Attività',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Container(
                width: 60.w,
                height: 12.h,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Skeleton items
          ...List.generate(2, (index) => Container(
            margin: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        width: 100.w,
                        height: 10.h,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// 🎨 Stato vuoto per attività
  Widget _buildRecentActivityEmpty(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: isDarkMode
            ? Border.all(color: Colors.grey.shade700, width: 0.5)
            : null,
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 48.sp,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          SizedBox(height: 16.h),
          Text(
            'Nessun allenamento ancora',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Inizia il tuo primo workout!',
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.grey.shade400 : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => _navigateToWorkouts(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            ),
            child: const Text('Inizia Allenamento'),
          ),
        ],
      ),
    );
  }

  /// 🎨 Stato errore per attività
  Widget _buildRecentActivityError(BuildContext context, String errorMessage, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: isDarkMode
            ? Border.all(color: Colors.grey.shade700, width: 0.5)
            : null,
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48.sp,
            color: Colors.orange,
          ),
          SizedBox(height: 16.h),
          Text(
            'Errore nel caricamento',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDarkMode ? Colors.grey.shade400 : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                context.read<WorkoutHistoryBloc>().add(
                  GetWorkoutHistory(userId: authState.user.id),
                );
              }
            },
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }

  /// Banner donazioni ottimizzato
  Widget _buildDonationBanner(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF093FB),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF093FB).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Supporta FitGymTrack',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Aiutaci a migliorare l\'app per tutti',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 36.h,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implementare donazioni
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Fai una Donazione',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sezione aiuto ottimizzata
  Widget _buildHelpSection(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.r),
        border: isDarkMode
            ? Border.all(color: Colors.grey.shade700, width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.08),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aiuto & Feedback',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            height: 36.h,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implementare feedback
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: isDarkMode ? Colors.white : AppColors.textPrimary,
                elevation: 0,
                side: BorderSide(
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Text(
                'Invia Feedback',
                style: TextStyle(fontSize: 12.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation helpers
  void _navigateToWorkouts(BuildContext context) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    homeState?._onTabTapped(1);
  }

  void _navigateToStats(BuildContext context) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    homeState?._onTabTapped(2);
  }

  // 🆕 Settings dialog migliorato
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Impostazioni'),
        content: const Text('Funzionalità in arrivo!\n\nProssimamente:\n• Gestione tema\n• Notifiche\n• Backup dati'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  // Utility per formattare il tempo del workout
  String _formatWorkoutTime(String dataAllenamento) {
    try {
      final dateTime = DateTime.parse(dataAllenamento);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} giorn${difference.inDays == 1 ? 'o' : 'i'} fa';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} or${difference.inHours == 1 ? 'a' : 'e'} fa';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minut${difference.inMinutes == 1 ? 'o' : 'i'} fa';
      } else {
        return 'Ora';
      }
    } catch (e) {
      return dataAllenamento; // Fallback
    }
  }

  // Utility per formattare le date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
        'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

// ============================================================================
// MODELLI HELPER PER LE QUICK ACTIONS
// ============================================================================

class _QuickAction {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}

// ============================================================================
// PLACEHOLDER PER STATSPAGE
// ============================================================================

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Stats Page - Da implementare'),
    );
  }
}