// lib/features/subscription/presentation/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../bloc/subscription_bloc.dart';
import '../../models/subscription_models.dart';
import '../widgets/subscription_widgets.dart';
import '../../../payments/bloc/stripe_bloc.dart';
import '../../../../core/di/dependency_injection.dart';

class SubscriptionScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SubscriptionScreen({super.key, this.onBack});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _useStripePayments = true; // Toggle per usare Stripe o simulazione

  @override
  void initState() {
    super.initState();
    // Carica l'abbonamento all'avvio
    context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 🔧 FIX: AppBar senza pulsante back
      appBar: AppBar(
        title: Text(
          'Abbonamento',
          style: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        // 🔧 FIX: Rimuoviamo completamente il pulsante back
        automaticallyImplyLeading: false,
        actions: [
          // 🔧 FIX: Toggle per testare entrambi i sistemi
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
            onSelected: (value) {
              if (value == 'toggle_payment') {
                setState(() {
                  _useStripePayments = !_useStripePayments;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _useStripePayments
                          ? 'Modalità Stripe attivata (pagamenti reali)'
                          : 'Modalità simulazione attivata',
                    ),
                    backgroundColor: _useStripePayments ? AppColors.success : AppColors.warning,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_payment',
                child: Row(
                  children: [
                    Icon(
                      _useStripePayments ? Icons.credit_card : Icons.code,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _useStripePayments ? 'Usa simulazione' : 'Usa Stripe',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 💳 Banner modalità pagamento
                  _buildPaymentModeBanner(context, isDarkMode),

                  SizedBox(height: 16.h),

                  // Contenuto principale
                  _buildContent(context, state, isDarkMode),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentModeBanner(BuildContext context, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _useStripePayments
            ? AppColors.success.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _useStripePayments
              ? AppColors.success.withOpacity(0.3)
              : AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _useStripePayments ? Icons.security : Icons.science,
            color: _useStripePayments ? AppColors.success : AppColors.warning,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _useStripePayments ? 'Modalità Stripe' : 'Modalità Simulazione',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  _useStripePayments
                      ? 'Pagamenti reali tramite Stripe (modalità test)'
                      : 'Simulazione dei pagamenti per sviluppo',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildContent(BuildContext context, SubscriptionState state, bool isDarkMode) {
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
      return _buildLoadedContent(context, state, isDarkMode);
    }

    if (state is SubscriptionUpdating) {
      return _buildUpdatingContent(context, state, isDarkMode);
    }

    // Stato iniziale
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: const SubscriptionLoadingWidget(),
    );
  }

  Widget _buildLoadedContent(BuildContext context, SubscriptionLoaded state, bool isDarkMode) {
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

        // 🔧 FIX: Abbonamento corrente con supporto dark theme migliorato
        CurrentSubscriptionCard(subscription: state.subscription),

        SizedBox(height: 32.h),

        // Sezione piani disponibili
        _buildAvailablePlansSection(context, state, isDarkMode),

        SizedBox(height: 32.h),

        // Sezione di supporto
        _buildSupportSection(context, isDarkMode),

        SizedBox(height: 32.h),
      ],
    );
  }

  Widget _buildUpdatingContent(BuildContext context, SubscriptionUpdating state, bool isDarkMode) {
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
                  color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailablePlansSection(BuildContext context, SubscriptionLoaded state, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Piani disponibili',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Scegli il piano più adatto alle tue esigenze',
          style: TextStyle(
            fontSize: 16.sp,
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
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

        // Piano Premium con scelta del metodo di pagamento
        SubscriptionPlanCard(
          plan: _getPremiumPlan(),
          isCurrentPlan: state.subscription.isPremium,
          onSubscribe: () => _handleUpgradeToPremium(context),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      // 🔧 FIX: Colore card basato sul tema
      color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
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
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Il tuo supporto ci aiuta a continuare a migliorare l\'app e ad aggiungere nuove funzionalità.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
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
    if (_useStripePayments) {
      // 💳 Usa Stripe per pagamenti reali
      _showStripeUpgradeDialog(context);
    } else {
      // 🔧 Usa simulazione per sviluppo
      _showSimulationUpgradeDialog(context);
    }
  }

  void _showStripeUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final isDarkMode = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.credit_card,
                color: AppColors.indigo600,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Upgrade a Premium',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stai per essere reindirizzato al sistema di pagamento sicuro Stripe per completare l\'upgrade al piano Premium.',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: AppColors.success,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Pagamento sicuro tramite Stripe',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Prezzo: €4.99/mese',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Annulla',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // 💳 Naviga alla schermata di pagamento Stripe
                context.push('/payment/subscription', extra: {
                  'plan_id': 'premium_monthly',
                  'price_id': 'price_1RXVOfHHtQGHyul9qMGFmpmO',
                });
              },
              icon: const Icon(Icons.payment),
              label: const Text('Continua con Stripe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSimulationUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final isDarkMode = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.science,
                color: AppColors.warning,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Simulazione Upgrade',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'Modalità simulazione attiva. Vuoi simulare l\'upgrade al piano Premium senza effettuare un pagamento reale?',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Annulla',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<SubscriptionBloc>().add(const UpdatePlanEvent(2));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simula Upgrade'),
            ),
          ],
        );
      },
    );
  }

  void _handleDowngradeToFree(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final isDarkMode = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          title: Text(
            'Conferma downgrade',
            style: TextStyle(
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Sei sicuro di voler passare al piano Free? Perderai l\'accesso alle funzionalità Premium.',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Annulla',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
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
    if (_useStripePayments) {
      // 💳 Usa Stripe per donazioni reali
      context.push('/payment/donation');
    } else {
      // 🔧 Simulazione
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          final isDarkMode = Theme.of(dialogContext).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
            title: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: AppColors.purple600,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Grazie!',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            content: Text(
              _useStripePayments
                  ? 'Sarai reindirizzato al sistema di donazione Stripe.'
                  : 'Modalità simulazione: Il sistema di donazione è in sviluppo. Grazie per il tuo interesse nel supportarci!',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              ),
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