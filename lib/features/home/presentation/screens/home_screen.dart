// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../subscription/bloc/subscription_bloc.dart';
import '../../../workouts/presentation/screens/workout_plans_screen.dart';
import '../../../subscription/presentation/screens/subscription_screen.dart';

// Import della DashboardPage dall'artefatto precedente
import '../../../../main.dart'; // Temporaneo per DashboardPage

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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppColors.indigo600,
        unselectedItemColor: isDarkMode ? Colors.grey.shade400 : Colors.grey,
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        items: _navItems,
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
      appBar: AppBar(
        title: const Text('Statistiche'),
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        foregroundColor: isDarkMode ? Colors.white : AppColors.textPrimary,
        elevation: 0,
      ),
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