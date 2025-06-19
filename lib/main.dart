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
// DASHBOARD PAGE - Variante 1B Compatto (Ripristinata!)
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

              // Banner donazioni (sempre visibile)
              _buildDonationBanner(context, isDarkMode),

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
      return _buildSubscriptionCard(context, subscription, isDarkMode);
    }

    // Default/Error state
    return _buildDefaultSubscriptionCard(context, isDarkMode);
  }

  Widget _buildSubscriptionCard(BuildContext context, Subscription subscription, bool isDarkMode) {
    final isPremium = subscription.isPremium;
    final isExpired = subscription.isExpired;
    final isExpiring = subscription.daysRemaining != null &&
        subscription.daysRemaining! <= 7 &&
        subscription.daysRemaining! > 0;

    Color bgColor;
    Color textColor;

    if (isPremium && !isExpired) {
      bgColor = Colors.green.shade400;
      textColor = Colors.white;
    } else if (isExpired) {
      bgColor = Colors.red.shade400;
      textColor = Colors.white;
    } else if (isExpiring) {
      bgColor = Colors.orange.shade400;
      textColor = Colors.white;
    } else {
      bgColor = isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight;
      textColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    }

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
          // Header
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
                      ? '${subscription.daysRemaining ?? 0} giorni'
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

          if (!isPremium) ...[
            SizedBox(height: 16.h),
            // Limiti in layout compatto
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
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultSubscriptionCard(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
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
            ],
          ),
        ],
      ),
    );
  }

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

  Widget _buildCompactUsage({
    required Subscription subscription,
    required Color textColor,
  }) {
    final workoutPercentage = subscription.maxWorkouts != null && subscription.maxWorkouts! > 0
        ? (subscription.currentCount / subscription.maxWorkouts!) * 100
        : 0.0;

    return Expanded(
      child: Column(
        children: [
          Text(
            '${workoutPercentage.toInt()}%',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
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
            subtitle = '$remainingSlots slot${remainingSlots == 1 ? '' : 's'} rimanente${remainingSlots == 1 ? '' : 'i'}';
          } else {
            title = 'Limite Raggiunto';
            subtitle = 'Passa a Premium per schede illimitate';
            showUpgrade = true;
          }
        }

        return GestureDetector(
          onTap: showUpgrade
              ? () => context.push('/subscription')
              : () => context.push('/workouts/create'),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: showUpgrade
                  ? LinearGradient(
                colors: [Colors.purple.shade400, Colors.indigo.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : LinearGradient(
                colors: [
                  isDarkMode ? Colors.blue.shade700 : Colors.blue.shade400,
                  isDarkMode ? Colors.cyan.shade700 : Colors.cyan.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  child: Icon(
                    showUpgrade ? Icons.upgrade : Icons.add,
                    color: Colors.white,
                    size: 28.sp,
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

  Widget _buildDonationBanner(BuildContext context, bool isDarkMode) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        // Mostra banner donazioni solo per utenti free
        if (state is SubscriptionLoaded) {
          final subscription = state.subscription;
          if (subscription.isPremium && !subscription.isExpired) {
            return const SizedBox.shrink(); // Non mostrare per utenti premium
          }
        }

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
                        context.push('/payment/donation');
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
            'Manda un feedback per qualsiasi informazione, problema o miglioramenti.',
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

// ============================================================================
// NOTA: StatsPage è definito in features/home/presentation/screens/home_screen.dart
// ============================================================================