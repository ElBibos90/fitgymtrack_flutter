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

    // Carica subscription all'avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[CONSOLE] [home_screen]🔧 Loading subscription on app start...');
      context.read<SubscriptionBloc>().add(
        const LoadSubscriptionEvent(checkExpired: true),
      );
    });
  }

  /// Gestisce il cambio di tab con lazy loading
  void _onTabTapped(int index) {
    print('[CONSOLE] [home_screen]🔄 Tab changed: $_selectedIndex -> $index');

    _previousIndex = _selectedIndex;

    setState(() {
      _selectedIndex = index;
    });

    _handleTabVisibilityChange(_previousIndex, index);
  }

  /// Gestisce la visibilità delle tab per il lazy loading
  void _handleTabVisibilityChange(int previousIndex, int currentIndex) {
    // Tab Workouts (index 1)
    if (currentIndex == 1) {
      _workoutController.onTabVisible();
      print('[CONSOLE] [home_screen]👁️ Workout tab became visible');
    } else if (previousIndex == 1) {
      _workoutController.onTabHidden();
      print('[CONSOLE] [home_screen]👁️ Workout tab became hidden');
    }
  }

  /// Metodo pubblico per navigare alla tab subscription
  void navigateToSubscriptionTab() {
    _onTabTapped(3);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ✅ AppBar con pulsante logout funzionante
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
              // ✅ FIX: Usa l'evento corretto per il logout
              context.read<AuthBloc>().add(const AuthLogoutRequested());
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
        onTap: _onTabTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: isDarkMode ? Colors.grey.shade400 : Colors.grey,
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        items: _navItems,
      ),
    );
  }
}

// ============================================================================
// DASHBOARD PAGE - Con banner donazioni sempre visibile
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
          context.read<SubscriptionBloc>().add(
            const LoadSubscriptionEvent(checkExpired: true),
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saluto
              _buildGreeting(context, isDarkMode),
              SizedBox(height: 24.h),

              // Status Abbonamento
              BlocBuilder<SubscriptionBloc, SubscriptionState>(
                builder: (context, state) {
                  return _buildSubscriptionSection(context, state, isDarkMode);
                },
              ),

              SizedBox(height: 32.h),

              // Quick Actions
              _buildQuickActions(context, isDarkMode),

              SizedBox(height: 24.h),

              // Banner donazioni (sempre visibile)
              _buildDonationBanner(context, isDarkMode),

              SizedBox(height: 24.h),

              // Sezione aiuto (solo feedback)
              _buildHelpSection(context, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  /// Saluto personalizzato
  Widget _buildGreeting(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ciao! 👋',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Ecco la situazione del tuo account',
          style: TextStyle(
            fontSize: 16.sp,
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Sezione status abbonamento
  Widget _buildSubscriptionSection(BuildContext context, SubscriptionState state, bool isDarkMode) {
    if (state is SubscriptionLoading) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12.w),
            Text(
              'Caricamento abbonamento...',
              style: TextStyle(
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (state is SubscriptionLoaded) {
      final subscription = state.subscription;
      final isPremium = subscription.isPremium;
      final isExpired = subscription.isExpired;

      Color bgColor = isPremium && !isExpired
          ? Colors.green.shade400
          : (isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight);

      Color textColor = isPremium && !isExpired
          ? Colors.white
          : (isDarkMode ? Colors.white : AppColors.textPrimary);

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isPremium ? 'Piano Premium' : 'Piano Free',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isPremium
                        ? Colors.white.withOpacity(0.2)
                        : AppColors.indigo600.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Attivo',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: isPremium
                          ? Colors.white
                          : AppColors.indigo600,
                    ),
                  ),
                ),
              ],
            ),
            if (!isPremium) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  _buildCompactLimit(
                    title: 'Schede',
                    current: subscription.currentCount,
                    max: subscription.maxWorkouts ?? 3,
                    textColor: textColor,
                  ),
                  SizedBox(width: 20.w),
                  _buildCompactLimit(
                    title: 'Esercizi',
                    current: subscription.currentCustomExercises,
                    max: subscription.maxCustomExercises ?? 5,
                    textColor: textColor,
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    // Default/Error state
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        'Piano Free',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  /// Limiti compatti
  Widget _buildCompactLimit({
    required String title,
    required int current,
    required int max,
    required Color textColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$current/$max',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick Actions
  Widget _buildQuickActions(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Azioni Rapide',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),

        // Prima riga
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context: context,
                title: 'Mie Schede',
                subtitle: 'Gestisci',
                icon: Icons.fitness_center,
                isDarkMode: isDarkMode,
                onTap: () => context.push('/workouts'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildQuickActionCard(
                context: context,
                title: 'Cronologia',
                subtitle: 'Allenamenti',
                icon: Icons.history,
                isDarkMode: isDarkMode,
                onTap: () => context.push('/workouts/history'),
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // Seconda riga
        Row(
          children: [
            Expanded(
              child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
                builder: (context, state) {
                  String subtitle = 'Custom';
                  if (state is SubscriptionLoaded) {
                    subtitle = '${state.subscription.currentCustomExercises} creati';
                  }

                  return _buildQuickActionCard(
                    context: context,
                    title: 'Esercizi',
                    subtitle: subtitle,
                    icon: Icons.add_circle_outline,
                    isDarkMode: isDarkMode,
                    onTap: () => context.push('/exercises'),
                  );
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildQuickActionCard(
                context: context,
                title: 'Impostazioni',
                subtitle: 'Account',
                icon: Icons.settings,
                isDarkMode: isDarkMode,
                onTap: () => context.push('/settings'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Card azione rapida
  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: isDarkMode ? Colors.white70 : AppColors.indigo600,
                  size: 24.sp,
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                  size: 16.sp,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDarkMode ? Colors.grey.shade400 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Banner donazioni sempre visibile
  Widget _buildDonationBanner(BuildContext context, bool isDarkMode) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        // Per utenti Premium - Messaggio di ringraziamento
        if (state is SubscriptionLoaded) {
          final subscription = state.subscription;

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
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Premium Attivo - Grazie!',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Vuoi supportarci ancora di più?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton(
                    onPressed: () {
                      context.push('/stripe-payment?mode=donation');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade700,
                      elevation: 0,
                    ),
                    child: const Text('Fai una Donazione'),
                  ),
                ],
              ),
            );
          }
        }

        // Banner per utenti Free
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDarkMode ? Colors.purple.shade700 : Colors.purple.shade400,
                isDarkMode ? Colors.indigo.shade700 : Colors.indigo.shade400,
              ],
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
                    Icons.favorite,
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
              SizedBox(height: 8.h),
              Text(
                'Il tuo supporto ci aiuta a migliorare l\'app',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/subscription');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: isDarkMode ? Colors.purple.shade700 : Colors.purple.shade600,
                        elevation: 0,
                      ),
                      child: const Text('Scopri Premium'),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.push('/stripe-payment?mode=donation');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                      child: const Text('Dona'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Sezione aiuto con solo feedback
  Widget _buildHelpSection(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark.withOpacity(0.5) : AppColors.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: isDarkMode ? Colors.white70 : AppColors.indigo600,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Bisogno di aiuto?',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Controlla la nostra guida o manda un feedback per qualsiasi domanda.',
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.grey.shade400 : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/feedback'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDarkMode ? Colors.white70 : AppColors.indigo600,
                side: BorderSide(
                  color: isDarkMode ? Colors.grey.shade600 : AppColors.indigo600,
                ),
              ),
              child: const Text('Feedback'),
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder per StatsPage (da implementare)
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 64.sp,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              'Statistiche',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Prossima implementazione...',
              style: TextStyle(
                fontSize: 16.sp,
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}