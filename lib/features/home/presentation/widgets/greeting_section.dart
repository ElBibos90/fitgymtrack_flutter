// lib/features/home/presentation/widgets/greeting_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/ui_animations.dart';
import '../../../../shared/services/data_integration_service.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../workouts/bloc/workout_history_bloc.dart';
import '../../services/dashboard_service.dart';

/// Sezione di saluto personalizzato nella dashboard
class GreetingSection extends StatelessWidget {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Determina il nome utente
        String userName = 'Utente';
        if (authState is AuthAuthenticated) {
          userName = authState.user.username.isNotEmpty
              ? authState.user.username
              : (authState.user.email?.split('@').first ?? 'Utente');
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: _buildGradient(context),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saluto principale
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DashboardService.getGreeting()}, $userName! 👋',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          DashboardService.getMotivationalMessage(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Icona decorativa
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      _getGreetingIcon(),
                      size: 28.sp,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Quick stats row
              _buildQuickStatsRow(context),
            ],
          ),
        );
      },
    );
  }

  /// Costruisce il gradiente basato sull'ora del giorno
  Gradient _buildGradient(BuildContext context) {
    final hour = DateTime.now().hour;

    // Mattina (6-12): Gradiente arancione/giallo
    if (hour >= 6 && hour < 12) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF9A56), Color(0xFFFFAD56)],
      );
    }
    // Pomeriggio (12-18): Gradiente blu/azzurro
    else if (hour >= 12 && hour < 18) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      );
    }
    // Sera (18-22): Gradiente viola/rosa
    else if (hour >= 18 && hour < 22) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF9F7AEA), Color(0xFFED64A6)],
      );
    }
    // Notte/alba (22-6): Gradiente blu scuro
    else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D3748), Color(0xFF4A5568)],
      );
    }
  }

  /// Icona appropriata per l'ora del giorno
  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      return Icons.wb_sunny_rounded; // Mattina
    } else if (hour >= 12 && hour < 18) {
      return Icons.wb_sunny_outlined; // Pomeriggio
    } else if (hour >= 18 && hour < 22) {
      return Icons.wb_twilight_rounded; // Sera
    } else {
      return Icons.nightlight_round; // Notte
    }
  }

  /// Row con statistiche rapide usando dati reali
  Widget _buildQuickStatsRow(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return _buildWelcomeStats();
        }

        // Calcola dati dashboard solo quando necessario
        final dashboardData = DataIntegrationService.calculateDashboardData(context);
        final workoutStreak = DataIntegrationService.calculateWorkoutStreak(context);
        final totalMinutes = DataIntegrationService.getTotalWorkoutMinutes(context);

        return Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.fitness_center,
                label: dashboardData.totalWorkouts > 0 ? 'Ultimo workout' : 'Inizia',
                value: dashboardData.totalWorkouts > 0
                    ? dashboardData.lastWorkoutFormatted
                    : 'il tuo primo!',
              ),
            ),

            Container(
              width: 1,
              height: 30.h,
              color: Colors.white.withOpacity(0.3),
              margin: EdgeInsets.symmetric(horizontal: 16.w),
            ),

            Expanded(
              child: _buildStatItem(
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: workoutStreak > 0 ? '$workoutStreak giorni' : 'Inizia oggi!',
              ),
            ),
          ],
        );
      },
    );
  }

  /// Statistiche di benvenuto per utenti non autenticati
  Widget _buildWelcomeStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.rocket_launch,
            label: 'Ready to',
            value: 'Get Started!',
          ),
        ),
      ],
    );
  }

  /// Singolo item delle statistiche
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: Colors.white.withOpacity(0.9),
        ),
        SizedBox(width: 6.w),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.white.withOpacity(0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Versione compatta del greeting per spazi ridotti
class CompactGreetingSection extends StatelessWidget {
  const CompactGreetingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String userName = 'Utente';
        if (authState is AuthAuthenticated) {
          userName = authState.user.username.isNotEmpty
              ? authState.user.username.split(' ').first // Solo primo nome
              : (authState.user.email?.split('@').first ?? 'Utente');
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.waving_hand,
                size: 20.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${DashboardService.getGreeting()}, $userName!',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}