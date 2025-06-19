// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/dependency_injection.dart';
import 'core/router/app_router.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/workouts/bloc/plateau_bloc.dart';
import 'features/subscription/bloc/subscription_bloc.dart';
import 'features/payments/bloc/stripe_bloc.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/app_colors.dart';
import 'shared/widgets/custom_snackbar.dart';
import 'features/workouts/bloc/workout_blocs.dart';
import 'features/workouts/presentation/screens/workout_plans_screen.dart';
import 'features/subscription/presentation/screens/subscription_screen.dart';
import 'features/subscription/bloc/subscription_bloc.dart';
import 'features/subscription/models/subscription_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📱 Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('[CONSOLE] [main]🚀 FITGYMTRACK STARTED');

  // Initialize dependency injection
  await DependencyInjection.init();

  runApp(const FitGymTrackApp());
}

class FitGymTrackApp extends StatelessWidget {
  const FitGymTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            // AUTH BLOC PROVIDERS
            BlocProvider<AuthBloc>(
              create: (context) => getIt<AuthBloc>(),
            ),
            BlocProvider<RegisterBloc>(
              create: (context) => getIt<RegisterBloc>(),
            ),
            BlocProvider<PasswordResetBloc>(
              create: (context) => getIt<PasswordResetBloc>(),
            ),

            // WORKOUT BLOC PROVIDERS
            BlocProvider<WorkoutBloc>(
              create: (context) => getIt<WorkoutBloc>(),
            ),
            BlocProvider<ActiveWorkoutBloc>(
              create: (context) => getIt<ActiveWorkoutBloc>(),
            ),
            BlocProvider<WorkoutHistoryBloc>(
              create: (context) => getIt<WorkoutHistoryBloc>(),
            ),

            // PLATEAU BLOC PROVIDER
            BlocProvider<PlateauBloc>(
              create: (context) => getIt<PlateauBloc>(),
            ),

            // SUBSCRIPTION BLOC PROVIDER
            BlocProvider<SubscriptionBloc>(
              create: (context) => getIt<SubscriptionBloc>(),
            ),

            // STRIPE BLOC PROVIDER
            BlocProvider<StripeBloc>(
              create: (context) => getIt<StripeBloc>(),
            ),
          ],
          child: MaterialApp.router(
            title: 'FitGymTrack',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: AppRouter.createRouter(),
          ),
        );
      },
    );
  }
}

// ============================================================================
// DASHBOARD PAGE - Variante 1B Compatto
// ============================================================================

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'FitGymTrack',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
            onPressed: () {
              // Assumendo che abbiate AuthBloc
              // context.read<AuthBloc>().logout();
            },
          ),
        ],
      ),
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

              // Status Abbonamento Compatto
              BlocConsumer<SubscriptionBloc, SubscriptionState>(
                listener: (context, state) {
                  if (state is SubscriptionError) {
                    CustomSnackbar.show(
                      context,
                      message: state.message,
                      isSuccess: false,
                    );
                  }
                },
                builder: (context, state) {
                  return _buildSubscriptionSection(context, state, isDarkMode);
                },
              ),

              SizedBox(height: 24.h),

              // Action Principale
              _buildMainAction(context, isDarkMode),

              SizedBox(height: 32.h),

              // Quick Actions
              _buildQuickActions(context, isDarkMode),

              SizedBox(height: 24.h),

              // Sezione info utile (opzionale)
              _buildHelpSection(context, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildSubscriptionSection(BuildContext context, SubscriptionState state, bool isDarkMode) {
    if (state is SubscriptionLoading) {
      return _buildLoadingCard(isDarkMode);
    }

    if (state is SubscriptionError) {
      return _buildErrorCard(context, state.message, isDarkMode);
    }

    if (state is SubscriptionLoaded) {
      return _buildCompactSubscriptionCard(context, state.subscription, isDarkMode);
    }

    // Default per SubscriptionInitial
    return _buildEmptySubscriptionCard(context, isDarkMode);
  }

  Widget _buildCompactSubscriptionCard(BuildContext context, Subscription subscription, bool isDarkMode) {
    final isPremium = subscription.isPremium && !subscription.isExpired;
    final isExpired = subscription.isExpired;
    final isExpiring = subscription.isExpiring;

    // Determina colori e stile
    Color cardColor;
    Color textColor;
    List<Color> gradientColors;

    if (isPremium) {
      gradientColors = isDarkMode
          ? [AppColors.indigo600.withOpacity(0.4), AppColors.indigo700.withOpacity(0.3)]
          : [AppColors.indigo600, AppColors.indigo700];
      textColor = Colors.white;
    } else if (isExpired) {
      gradientColors = isDarkMode
          ? [Colors.red.shade600.withOpacity(0.4), Colors.red.shade700.withOpacity(0.3)]
          : [Colors.red.shade600, Colors.red.shade700];
      textColor = Colors.white;
    } else {
      gradientColors = isDarkMode
          ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
          : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)];
      textColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Header compatto
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
                    color: isPremium || isExpired
                        ? Colors.white.withOpacity(0.2)
                        : (isDarkMode ? Colors.grey.withOpacity(0.3) : AppColors.indigo600.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    isExpired
                        ? 'Scaduto'
                        : isExpiring
                        ? '${subscription.daysRemaining} giorni'
                        : 'Attivo',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: isPremium || isExpired
                          ? Colors.white
                          : (isDarkMode ? Colors.white70 : AppColors.indigo600),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Limiti in layout compatto
            if (!isPremium) ...[
              Row(
                children: [
                  _buildCompactLimit(
                    title: 'Schede',
                    current: subscription.currentCount,
                    max: subscription.maxWorkouts ?? 0,
                    textColor: textColor,
                  ),
                  SizedBox(width: 20.w),
                  _buildCompactLimit(
                    title: 'Esercizi',
                    current: subscription.currentCustomExercises,
                    max: subscription.maxCustomExercises ?? 0,
                    textColor: textColor,
                  ),
                  SizedBox(width: 20.w),
                  _buildCompactUsage(
                    subscription: subscription,
                    textColor: textColor,
                  ),
                ],
              ),
            ] else ...[
              // Per utenti Premium mostra features attive
              Text(
                '✨ Accesso completo a tutte le funzionalità',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: textColor.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLimit(
      {required String title, required int current, required int max, required Color textColor}
      ) {
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
          SizedBox(height: 4.h),
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

  Widget _buildCompactUsage({required Subscription subscription, required Color textColor}) {
    final totalUsage = subscription.maxWorkouts != null && subscription.maxCustomExercises != null
        ? ((subscription.currentCount + subscription.currentCustomExercises) /
        (subscription.maxWorkouts! + subscription.maxCustomExercises!)) * 100
        : 0.0;

    return Expanded(
      child: Column(
        children: [
          Text(
            '${totalUsage.round()}%',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Utilizzo',
            style: TextStyle(
              fontSize: 11.sp,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(bool isDarkMode) {
    return Container(
      height: 120.h,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: isDarkMode ? Colors.white70 : AppColors.indigo600,
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String message, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.red.shade300,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 32.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            'Errore nel caricamento',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.red.shade800,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.white70 : Colors.red.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySubscriptionCard(BuildContext context, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
              : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Piano Free',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.withOpacity(0.3) : AppColors.indigo600.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Attivo',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white70 : AppColors.indigo600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildCompactLimit(
                title: 'Schede',
                current: 0,
                max: 3,
                textColor: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
              SizedBox(width: 20.w),
              _buildCompactLimit(
                title: 'Esercizi',
                current: 0,
                max: 5,
                textColor: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
              SizedBox(width: 20.w),
              _buildCompactUsage(
                subscription: const Subscription(
                  planId: 1,
                  planName: 'Free',
                  price: 0.0,
                  currentCount: 0,
                  currentCustomExercises: 0,
                  maxWorkouts: 3,
                  maxCustomExercises: 5,
                ),
                textColor: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainAction(BuildContext context, bool isDarkMode) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        String title = 'Crea Nuova Scheda';
        String subtitle = 'Inizia il tuo allenamento personalizzato';
        bool showUpgrade = false;

        if (state is SubscriptionLoaded) {
          final subscription = state.subscription;
          final remainingSlots = (subscription.maxWorkouts ?? 3) - subscription.currentCount;

          if (subscription.isPremium && !subscription.isExpired) {
            title = 'Crea Nuova Scheda';
            subtitle = 'Schede illimitate con Premium';
          } else if (remainingSlots > 0) {
            title = 'Crea Nuova Scheda';
            subtitle = '$remainingSlots slot${remainingSlots == 1 ? '' : 's'} rimanente${remainingSlots == 1 ? '' : 'i'} nel piano Free';
          } else {
            showUpgrade = true;
            title = 'Upgrade a Premium';
            subtitle = 'Hai raggiunto il limite di schede Free';
          }
        }

        return GestureDetector(
          onTap: () {
            if (showUpgrade) {
              // Naviga a subscription screen
              context.push('/subscription');
            } else {
              // Naviga a create workout
              context.push('/workouts/create');
            }
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: showUpgrade
                    ? [Colors.orange.shade600, Colors.orange.shade700]
                    : [Colors.green.shade600, Colors.green.shade700],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: (showUpgrade ? Colors.orange : Colors.green).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    showUpgrade ? 'Upgrade Ora' : 'Inizia Ora',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesso Rapido',
          style: TextStyle(
            fontSize: 20.sp,
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
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.indigo600.withOpacity(isDarkMode ? 0.3 : 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color: isDarkMode ? AppColors.indigo600 : AppColors.indigo600,
                size: 20.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context, bool isDarkMode) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        // Mostra upgrade CTA solo per utenti Free
        bool showUpgradeCTA = false;
        if (state is SubscriptionLoaded) {
          showUpgradeCTA = !state.subscription.isPremium || state.subscription.isExpired;
        }

        if (!showUpgradeCTA) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => context.push('/subscription'),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange.shade600, Colors.orange.shade700],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Text(
                  '🚀 Passa a Premium',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '€4.99/mese • Schede illimitate • Statistiche avanzate',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}