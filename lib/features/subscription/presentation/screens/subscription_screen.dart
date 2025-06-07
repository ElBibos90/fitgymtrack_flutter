// lib/features/subscription/presentation/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../bloc/subscription_bloc.dart';
import '../../models/subscription_models.dart';
import '../widgets/subscription_widgets.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    // Carica l'abbonamento all'avvio
    context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abbonamento'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.indigo600,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              child: _buildContent(context, state),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onRefresh() async {
    context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent());
  }

  void _handleStateChanges(BuildContext context, SubscriptionState state) {
    if (state is SubscriptionUpdateSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (state is SubscriptionError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context, SubscriptionState state) {
    if (state is SubscriptionLoading) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: const SubscriptionLoadingWidget(),
      );
    }

    if (state is SubscriptionError) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: SubscriptionErrorWidget(
          message: state.message,
          onRetry: () {
            context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent());
          },
        ),
      );
    }

    if (state is SubscriptionLoaded) {
      return _buildLoadedContent(context, state);
    }

    if (state is SubscriptionUpdating) {
      return _buildUpdatingContent(context, state);
    }

    // Stato iniziale
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: const SubscriptionLoadingWidget(),
    );
  }

  Widget _buildLoadedContent(BuildContext context, SubscriptionLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner per abbonamento scaduto
        if (state.showExpiredNotification)
          SubscriptionExpiredBanner(
            onDismiss: () {
              context.read<SubscriptionBloc>().add(
                const DismissExpiredNotificationEvent(),
              );
            },
            onUpgrade: () => _handleUpgradeToPremium(context),
          ),

        // Banner per limite raggiunto
        if (state.showLimitNotification && state.workoutLimits != null)
          SubscriptionLimitBanner(
            resourceType: 'max_workouts',
            currentCount: state.workoutLimits!.currentCount,
            maxAllowed: state.workoutLimits!.maxAllowed ?? 0,
            onDismiss: () {
              context.read<SubscriptionBloc>().add(
                const DismissLimitNotificationEvent(),
              );
            },
            onUpgrade: () => _handleUpgradeToPremium(context),
          ),

        // Abbonamento corrente
        CurrentSubscriptionCard(subscription: state.subscription),

        SizedBox(height: 32.h),

        // Sezione piani disponibili
        _buildAvailablePlansSection(context, state),

        SizedBox(height: 32.h),

        // Sezione di supporto
        _buildSupportSection(context),

        SizedBox(height: 32.h),
      ],
    );
  }

  Widget _buildUpdatingContent(BuildContext context, SubscriptionUpdating state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CurrentSubscriptionCard(subscription: state.currentSubscription),
        SizedBox(height: 32.h),
        Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.indigo600),
              ),
              SizedBox(height: 16.h),
              Text(
                'Aggiornamento del piano in corso...',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailablePlansSection(BuildContext context, SubscriptionLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Piani disponibili',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Scegli il piano più adatto alle tue esigenze',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 20.h),

        // Piano Free
        SubscriptionPlanCard(
          plan: _getFreePlan(),
          isCurrentPlan: !state.subscription.isPremium,
          onSubscribe: () => _handleDowngradeToFree(context),
        ),

        SizedBox(height: 16.h),

        // Piano Premium
        SubscriptionPlanCard(
          plan: _getPremiumPlan(),
          isCurrentPlan: state.subscription.isPremium,
          onSubscribe: () => _handleUpgradeToPremium(context),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.purple600.withOpacity(0.1),
              AppColors.purple700.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: AppColors.purple600,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Supporta FitGymTrack',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Il tuo supporto ci aiuta a continuare a migliorare l\'app e ad aggiungere nuove funzionalità.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _handleDonation(context),
                    icon: Icon(
                      Icons.favorite_border,
                      size: 18.sp,
                    ),
                    label: const Text('Fai una donazione'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.purple600,
                      side: BorderSide(color: AppColors.purple600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Metodi per gestire le azioni

  void _handleUpgradeToPremium(BuildContext context) {
    // Mostra dialog informativo
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Upgrade a Premium'),
          content: const Text(
            'Per ora, il sistema di pagamento è in modalità demo. Vuoi simulare l\'upgrade al piano Premium?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Simula l'upgrade usando il mock
                context.read<SubscriptionBloc>().add(const UpdatePlanEvent(2));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo600,
              ),
              child: const Text('Simula Upgrade'),
            ),
          ],
        );
      },
    );
  }

  void _handleDowngradeToFree(BuildContext context) {
    // Mostra dialog di conferma
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Conferma downgrade'),
          content: const Text(
            'Sei sicuro di voler passare al piano Free? Perderai l\'accesso alle funzionalità Premium.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<SubscriptionBloc>().add(const UpdatePlanEvent(1));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo600,
              ),
              child: const Text('Conferma'),
            ),
          ],
        );
      },
    );
  }

  void _handleDonation(BuildContext context) {
    // Mostra dialog informativo
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.favorite,
                color: AppColors.purple600,
              ),
              SizedBox(width: 8.w),
              const Text('Grazie!'),
            ],
          ),
          content: const Text(
            'Il sistema di donazione è in sviluppo. Grazie per il tuo interesse nel supportarci!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple600,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Metodi helper per i piani

  SubscriptionPlan _getFreePlan() {
    return const SubscriptionPlan(
      id: 1,
      name: 'Free',
      price: 0.0,
      maxWorkouts: 3,
      maxCustomExercises: 5,
      advancedStats: false,
      cloudBackup: false,
      noAds: false,
    );
  }

  SubscriptionPlan _getPremiumPlan() {
    return const SubscriptionPlan(
      id: 2,
      name: 'Premium',
      price: 4.99,
      maxWorkouts: null, // illimitate
      maxCustomExercises: null, // illimitati
      advancedStats: true,
      cloudBackup: true,
      noAds: true,
    );
  }
}