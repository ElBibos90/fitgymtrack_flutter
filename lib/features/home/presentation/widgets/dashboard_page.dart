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

/// Dashboard principale - UI pulita separata dalla business logic
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
          onRefresh: () => _refreshDashboard(context),
          child: CustomScrollView(
            slivers: [
              // Content principale
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),

                    // 👋 Sezione Saluto
                    const GreetingSection(),

                    SizedBox(height: 20.h),

                    // 🚀 Quick Actions
                    const QuickActionsGrid(),

                    SizedBox(height: 24.h),

                    // 💎 Status Abbonamento
                    const SubscriptionSection(),

                    SizedBox(height: 24.h),

                    // 📊 Attività Recente
                    const RecentActivitySection(),

                    SizedBox(height: 24.h),

                    // 💝 Banner Donazioni
                    const DonationBanner(),

                    SizedBox(height: 20.h),

                    // ❓ Sezione Aiuto
                    const HelpSection(),

                    // Bottom padding
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Aggiorna tutti i dati della dashboard
  Future<void> _refreshDashboard(BuildContext context) async {
    print('[CONSOLE] [dashboard_page]🔄 Refreshing dashboard data...');

    // Ricarica subscription
    context.read<SubscriptionBloc>().add(
      const LoadSubscriptionEvent(checkExpired: true),
    );

    // Ricarica dati utente se autenticato
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final userId = authState.user.id;

      // Ricarica workout history
      context.read<WorkoutHistoryBloc>().add(
        GetWorkoutHistory(userId: userId),
      );

      // Ricarica statistiche
      context.read<WorkoutHistoryBloc>().add(
        GetUserStats(userId: userId),
      );

      print('[CONSOLE] [dashboard_page]✅ Dashboard refresh completed for userId: $userId');
    }

    // Delay minimo per UX
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

/// Pagina dashboard per utenti non autenticati
class UnauthenticatedDashboard extends StatelessWidget {
  const UnauthenticatedDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo o icona app
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              size: 40.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          SizedBox(height: 24.h),

          // Titolo benvenuto
          Text(
            'Benvenuto in FitGymTrack!',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 12.h),

          // Descrizione
          Text(
            'Traccia i tuoi allenamenti, monitora i progressi e raggiungi i tuoi obiettivi fitness.',
            style: TextStyle(
              fontSize: 16.sp,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 32.h),

          // Features preview
          _buildFeatureItem(
            icon: Icons.fitness_center,
            title: 'Allenamenti Personalizzati',
            description: 'Crea schede su misura per te',
            isDarkMode: isDarkMode,
          ),

          SizedBox(height: 16.h),

          _buildFeatureItem(
            icon: Icons.analytics,
            title: 'Statistiche Dettagliate',
            description: 'Monitora i tuoi progressi nel tempo',
            isDarkMode: isDarkMode,
          ),

          SizedBox(height: 16.h),

          _buildFeatureItem(
            icon: Icons.emoji_events,
            title: 'Achievement',
            description: 'Raggiungi traguardi e sblocca riconoscimenti',
            isDarkMode: isDarkMode,
          ),

          SizedBox(height: 32.h),

          // Call to action
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Accedi per iniziare il tuo percorso fitness!',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            icon,
            color: Colors.blue,
            size: 24.sp,
          ),
        ),

        SizedBox(width: 16.w),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}