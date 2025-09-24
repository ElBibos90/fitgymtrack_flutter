// lib/features/home/presentation/widgets/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/loading_shimmer_widgets.dart';
import '../../../../shared/widgets/error_handling_widgets.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/models/login_response.dart';
import '../../../subscription/bloc/subscription_bloc.dart';
import '../../../subscription/bloc/gym_subscription_bloc.dart';
import '../../../workouts/bloc/workout_history_bloc.dart';
import '../../../stats/models/user_stats_models.dart';
import '../../services/dashboard_service.dart';
import '../../../../core/services/user_role_service.dart';
import 'quick_actions_grid.dart';
import 'greeting_section.dart';
import 'subscription_section.dart';
import 'recent_activity_section.dart';
import 'donation_banner.dart';
import '../../../../features/subscription/presentation/widgets/gym_subscription_section.dart';
import 'help_section.dart';
import '../../../../core/di/dependency_injection.dart';

/// 🎨 MODERN DASHBOARD: Home Screen con layout ottimizzato e design migliorato
class DashboardPage extends StatelessWidget {
  // 🔧 PARAMETRI OPZIONALI per backwards compatibility
  final VoidCallback? onNavigateToWorkouts;
  final VoidCallback? onNavigateToAchievements;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToSubscription;

  const DashboardPage({
    super.key,
    // 🔧 TUTTI i parametri sono OPZIONALI per non rompere codice esistente
    this.onNavigateToWorkouts,
    this.onNavigateToAchievements,
    this.onNavigateToProfile,
    this.onNavigateToSubscription,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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

        // 🎨 MODERN DASHBOARD per utenti autenticati
        // 🎯 NUOVO: Estrai utente per controllo ruoli
        User? currentUser;
        if (authState is AuthAuthenticated) {
          currentUser = authState.user;
        } else if (authState is AuthLoginSuccess) {
          currentUser = authState.user;
        }
        
        return RefreshIndicator(
          onRefresh: () => _handleRefresh(context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 🎨 HEADER SECTION con saluto e informazioni utente
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.only(
                    left: 16.w, 
                    right: 16.w, 
                    top: 16.h, 
                    bottom: 8.h
                  ),
                  child: GreetingSection(),
                ),
              ),

              // 🎨 QUICK ACTIONS SECTION con miglior spacing
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: QuickActionsGrid(
                    showSecondaryActions: true, // ✅ Mostra anche i template
                    crossAxisCount: 3, // ✅ 3 colonne invece di 2
                    childAspectRatio: 0.9, // ✅ Più compatto per 3 colonne
                    user: currentUser, // 🎯 NUOVO: Passa utente per controllo ruoli
                    onNavigateToWorkouts: onNavigateToWorkouts,
                    onNavigateToAchievements: onNavigateToAchievements,
                    onNavigateToProfile: onNavigateToProfile,
                  ),
                ),
              ),

              // 🎨 SUBSCRIPTION SECTION con card design
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: _buildSectionCard(
                    context,
                    child: UserRoleService.canSeeSubscriptionTab(currentUser)
                        ? SubscriptionSection(
                            onNavigateToSubscription: onNavigateToSubscription,
                          )
                        : BlocProvider(
                            create: (context) => getIt<GymSubscriptionBloc>(),
                            child: GymSubscriptionSection(
                              userId: currentUser?.id ?? 0,
                            ),
                          ),
                    title: 'Abbonamento',
                    icon: Icons.card_membership_rounded,
                  ),
                ),
              ),

              // 🎨 RECENT ACTIVITY SECTION con card design
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: _buildSectionCard(
                    context,
                    child: RecentActivitySection(),
                    title: 'Attività Recenti',
                    icon: Icons.history_rounded,
                  ),
                ),
              ),

              // 🎨 DONATION BANNER con miglior styling (solo per utenti standalone)
              if (UserRoleService.canSeeDonationBanner(currentUser))
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: DonationBanner(),
                  ),
                ),

              // 🎨 HELP SECTION con card design
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: _buildSectionCard(
                    context,
                    child: HelpSection(),
                    title: 'Aiuto e Supporto',
                    icon: Icons.help_outline_rounded,
                  ),
                ),
              ),

              // 🎨 Spazio finale ottimizzato
              SliverToBoxAdapter(
                child: SizedBox(height: 120.h),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🎨 BUILDS SECTION CARD: Crea una card moderna per ogni sezione
  Widget _buildSectionCard(
    BuildContext context, {
    required Widget child,
    required String title,
    required IconData icon,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode 
            ? AppColors.surfaceDark.withValues(alpha: 0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode 
              ? AppColors.border.withValues(alpha: 0.2)
              : AppColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎨 SECTION HEADER
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? AppColors.indigo600.withValues(alpha: 0.1)
                  : AppColors.indigo50.withValues(alpha: 0.3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.indigo600.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    icon,
                    size: 20.sp,
                    color: AppColors.indigo600,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          // 🎨 SECTION CONTENT
          Container(
            padding: EdgeInsets.all(20.w),
            child: child,
          ),
        ],
      ),
    );
  }

  /// Gestisce il refresh della dashboard
  Future<void> _handleRefresh(BuildContext context) async {
    print('[CONSOLE] [dashboard_page]🔄 Refreshing dashboard data...');

    // Ricarica i dati dello stato di autenticazione
    final authBloc = context.read<AuthBloc>();
    if (authBloc.state is AuthAuthenticated) {
      final authState = authBloc.state as AuthAuthenticated;

      // 🔧 FIX: Rimosso caricamento ridondante subscription
      // La subscription viene già caricata nella home screen

      // Ricarica workout history
      context.read<WorkoutHistoryBloc>().add(
        GetWorkoutHistory(userId: authState.user.id),
      );
    }
  }
}

/// ✅ Dashboard per utenti non autenticati - MIGLIORATA
class UnauthenticatedDashboard extends StatelessWidget {
  const UnauthenticatedDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [
                  AppColors.indigo600.withValues(alpha: 0.1),
                  AppColors.surfaceDark,
                ]
              : [
                  AppColors.indigo50.withValues(alpha: 0.3),
                  Colors.white,
                ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🎨 MODERN ICON CONTAINER
              Container(
                width: 120.w,
                height: 120.w,
                                 decoration: BoxDecoration(
                   gradient: LinearGradient(
                     colors: [
                       AppColors.indigo600,
                       AppColors.indigo700,
                     ],
                   ),
                   borderRadius: BorderRadius.circular(60.r),
                   boxShadow: [
                     BoxShadow(
                       color: AppColors.indigo600.withValues(alpha: 0.3),
                       blurRadius: 20,
                       offset: const Offset(0, 8),
                     ),
                   ],
                 ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  size: 60.sp,
                  color: Colors.white,
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // 🎨 MODERN TITLE
              Text(
                'Benvenuto in FitGymTrack!',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 16.h),
              
              // 🎨 MODERN SUBTITLE
              Text(
                'Accedi per iniziare il tuo percorso di allenamento e raggiungere i tuoi obiettivi fitness',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: isDarkMode 
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 40.h),
              
              // 🎨 MODERN BUTTON
              Container(
                width: double.infinity,
                height: 56.h,
                                 decoration: BoxDecoration(
                   gradient: LinearGradient(
                     colors: [
                       AppColors.indigo600,
                       AppColors.indigo700,
                     ],
                   ),
                   borderRadius: BorderRadius.circular(16.r),
                   boxShadow: [
                     BoxShadow(
                       color: AppColors.indigo600.withValues(alpha: 0.3),
                       blurRadius: 12,
                       offset: const Offset(0, 4),
                     ),
                   ],
                 ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16.r),
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: Center(
                      child: Text(
                        'Accedi Ora',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}