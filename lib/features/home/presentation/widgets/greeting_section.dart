// lib/features/home/presentation/widgets/greeting_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/services/data_integration_service.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../gym/services/gym_logo_service.dart';
import '../../../gym/widgets/gym_logo_widget.dart';
import '../../services/dashboard_service.dart';

/// Sezione di saluto personalizzato nella dashboard
class GreetingSection extends StatelessWidget {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Determina il nome utente - priorità al nome reale, poi username, poi email
        String userName = 'Utente';
        bool isLoading = false;
        
        if (authState is AuthAuthenticated || authState is AuthLoginSuccess) {
          // Usa lo stesso utente per entrambi gli stati
          final user = authState is AuthAuthenticated ? authState.user : (authState as AuthLoginSuccess).user;
          
          if (user.name != null && user.name!.isNotEmpty) {
            userName = user.name!;
          } else if (user.username.isNotEmpty) {
            userName = user.username;
          } else {
            userName = user.email?.split('@').first ?? 'Utente';
          }
        } else if (authState is AuthLoading) {
          // Durante il caricamento, mostra un indicatore di loading invece di "Utente"
          isLoading = true;
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: _buildGradient(context),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
                          isLoading 
                            ? '${DashboardService.getGreeting()}... 👋'
                            : '${DashboardService.getGreeting()}, $userName! 👋',
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
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Logo della palestra o icona decorativa
                  _buildGymLogoOrIcon(context, authState),
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

  /// Costruisce il logo della palestra o icona di fallback
  Widget _buildGymLogoOrIcon(BuildContext context, AuthState authState) {
    // Se l'utente è autenticato, prova a mostrare il logo della palestra
    if (authState is AuthAuthenticated || authState is AuthLoginSuccess) {
      final user = authState is AuthAuthenticated ? authState.user : (authState as AuthLoginSuccess).user;
      final gymLogoService = getIt<GymLogoService>();
      
      // Verifica se l'utente dovrebbe mostrare un logo palestra
      if (gymLogoService.shouldShowGymLogo(user)) {
        return Container(
          width: 80.w,  // Aumentato da 60.w
          height: 80.w, // Aumentato da 60.w
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(6.w), // Ridotto padding per più spazio logo
            child: GymLogoWidgetWithLoading(
              gymLogoFuture: gymLogoService.getGymLogoForCurrentUser(user),
              width: 68.w,  // Aumentato da 44.w
              height: 68.w, // Aumentato da 44.w
              showFallback: false, // Non mostrare fallback, usa icona decorativa
            ),
          ),
        );
      }
    }
    
    // Fallback: icona decorativa
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(
        _getGreetingIcon(),
        size: 28.sp,
        color: Colors.white,
      ),
    );
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
              color: Colors.white.withValues(alpha: 0.3),
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
          color: Colors.white.withValues(alpha: 0.9),
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
                  color: Colors.white.withValues(alpha: 0.8),
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
        bool isLoading = false;
        
        if (authState is AuthAuthenticated || authState is AuthLoginSuccess) {
          // Usa lo stesso utente per entrambi gli stati
          final user = authState is AuthAuthenticated ? authState.user : (authState as AuthLoginSuccess).user;
          
          if (user.name != null && user.name!.isNotEmpty) {
            userName = user.name!.split(' ').first; // Solo primo nome
          } else if (user.username.isNotEmpty) {
            userName = user.username.split(' ').first; // Solo primo nome
          } else {
            userName = user.email?.split('@').first ?? 'Utente';
          }
        } else if (authState is AuthLoading) {
          // Durante il caricamento, mostra un indicatore di loading
          isLoading = true;
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
                  isLoading 
                    ? '${DashboardService.getGreeting()}...'
                    : '${DashboardService.getGreeting()}, $userName!',
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