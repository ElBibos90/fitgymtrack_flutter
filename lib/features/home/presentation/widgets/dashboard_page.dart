// lib/features/home/presentation/widgets/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/loading_shimmer_widgets.dart';
import '../../../../shared/widgets/error_handling_widgets.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../subscription/bloc/subscription_bloc.dart';
import '../../../workouts/bloc/workout_history_bloc.dart';
import '../../../stats/models/user_stats_models.dart';
import '../../services/dashboard_service.dart';
import 'quick_actions_grid.dart';
import 'greeting_section.dart';
import 'subscription_section.dart';
import 'recent_activity_section.dart';
import 'donation_banner.dart';
import 'help_section.dart';

/// Dashboard principale - ✅ BACKWARDS COMPATIBLE con callback opzionali
class DashboardPage extends StatelessWidget {
  // 🔧 PARAMETRI OPZIONALI per backwards compatibility
  final VoidCallback? onNavigateToWorkouts;
  final VoidCallback? onNavigateToAchievements;
  final VoidCallback? onNavigateToProfile;

  const DashboardPage({
    super.key,
    // 🔧 TUTTI i parametri sono OPZIONALI per non rompere codice esistente
    this.onNavigateToWorkouts,
    this.onNavigateToAchievements,
    this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Mostra loading se non è autenticato o in stato iniziale
        if (authState is AuthInitial || authState is AuthLoading) {
          return const ShimmerDashboard();
        }

        // Mostra dashboard non autenticata
        if (authState is AuthUnauthenticated || authState is AuthError) {
          return const UnauthenticatedDashboard();
        }

        // Dashboard normale per utenti autenticati
        return RefreshIndicator(
          onRefresh: () => _handleRefresh(context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header con saluto e informazioni utente
              SliverToBoxAdapter(
                child: GreetingSection(),
              ),

              // ✅ Quick Actions Grid con callback functions SE disponibili
              SliverToBoxAdapter(
                child: QuickActionsGrid(
                  onNavigateToWorkouts: onNavigateToWorkouts,
                  onNavigateToAchievements: onNavigateToAchievements,
                  onNavigateToProfile: onNavigateToProfile,
                ),
              ),

              // Sezione subscription/abbonamento
              SliverToBoxAdapter(
                child: SubscriptionSection(),
              ),

              // Sezione attività recente
              SliverToBoxAdapter(
                child: RecentActivitySection(),
              ),

              // Banner donazione
              SliverToBoxAdapter(
                child: DonationBanner(),
              ),

              // Sezione aiuto e supporto
              SliverToBoxAdapter(
                child: HelpSection(),
              ),

              // Spazio finale per padding
              SliverToBoxAdapter(
                child: SizedBox(height: 100.h),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Gestisce il refresh della dashboard
  Future<void> _handleRefresh(BuildContext context) async {
    print('[CONSOLE] [dashboard_page]🔄 Refreshing dashboard data...');

    // Ricarica i dati dello stato di autenticazione
    final authBloc = context.read<AuthBloc>();
    if (authBloc.state is AuthAuthenticated) {
      final authState = authBloc.state as AuthAuthenticated;

      // Ricarica subscription
      context.read<SubscriptionBloc>().add(
        const LoadSubscriptionEvent(checkExpired: true),
      );

      // Ricarica workout history
      context.read<WorkoutHistoryBloc>().add(
        GetWorkoutHistory(userId: authState.user.id),
      );
    }
  }
}

/// ✅ Dashboard per utenti non autenticati - NON MODIFICATA
class UnauthenticatedDashboard extends StatelessWidget {
  const UnauthenticatedDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64.sp,
              color: AppColors.indigo600,
            ),
            SizedBox(height: 24.h),
            Text(
              'Benvenuto in FitGymTrack!',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'Accedi per iniziare il tuo percorso di allenamento',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () {
                // Naviga al login
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Accedi'),
            ),
          ],
        ),
      ),
    );
  }
}