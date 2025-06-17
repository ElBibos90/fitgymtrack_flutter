// lib/features/subscription/presentation/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/config/stripe_config.dart';
import '../../../payments/bloc/stripe_bloc.dart';
import '../../bloc/subscription_bloc.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _hasTriedInitialization = false;
  bool _justCompletedPayment = false;

  @override
  void initState() {
    super.initState();
    //print('[CONSOLE][subscription_screen]💳 [SUBSCRIPTION] Screen loaded - Stripe NOT initialized yet');
  }

  /// 🔧 FIX: Inizializza Stripe SOLO quando l'utente vuole sottoscrivere
  void _initializeStripeForPayment() {
    if (_hasTriedInitialization) {
      //print('[CONSOLE][subscription_screen]💳 [SUBSCRIPTION] Stripe already initialized or tried');
      return;
    }

    //print('[CONSOLE][subscription_screen]💳 [SUBSCRIPTION] User wants to subscribe - initializing Stripe now...');
    _hasTriedInitialization = true;

    final stripeBloc = context.read<StripeBloc>();

    // Se Stripe non è ancora inizializzato, inizializzalo ora
    if (stripeBloc.state is StripeInitial) {
      //print('[CONSOLE][subscription_screen]💳 [SUBSCRIPTION] Stripe not ready, initializing for payment...');
      stripeBloc.add(const InitializeStripeEvent());
    } else {
      //print('[CONSOLE][subscription_screen]💳 [SUBSCRIPTION] Stripe already ready, proceeding with payment...');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: BlocConsumer<StripeBloc, StripeState>(
        listener: (context, state) {
          //print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Stripe state changed: ${state.runtimeType}');

          if (state is StripePaymentReady) {
            //print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Payment Ready - opening Payment Sheet');
            _presentPaymentSheet(context, state);
          } else if (state is StripePaymentSuccess) {
            //print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Payment Success!');
            _justCompletedPayment = true;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: Duration(seconds: 4),
              ),
            );

            // 🔧 FIX: Reload subscription after successful payment
            context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent(checkExpired: false));
          } else if (state is StripeErrorState) {
            //print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Stripe Error: ${state.message}');

            if (_justCompletedPayment && state.message.contains('caricamento subscription')) {
              //print('[CONSOLE][subscription_screen]⚠️ [SUBSCRIPTION] Ignoring subscription loading error after successful payment');
              _justCompletedPayment = false;
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: Duration(seconds: 5),
              ),
            );
          }
        },
        builder: (context, stripeState) {
          return CustomScrollView(
            slivers: [
              // 🎨 MODERN APP BAR
              SliverAppBar(
                expandedHeight: 120.h,
                floating: true,
                pinned: true,
                backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Abbonamento',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),

              // 🎨 CONTENT
              SliverPadding(
                padding: EdgeInsets.all(16.w),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 🔧 Payment Loading Overlay quando necessario
                    if (stripeState is StripePaymentLoading)
                      _buildPaymentLoadingOverlay(stripeState, isDarkMode),

                    // 🚀 Payment Success Banner se abbiamo appena completato un pagamento
                    if (_justCompletedPayment)
                      _buildPaymentSuccessBanner(isDarkMode),

                    // 📊 Current Plan Card - FIXED: Using SubscriptionBloc
                    BlocBuilder<SubscriptionBloc, SubscriptionState>(
                      builder: (context, subscriptionState) {
                        return _buildCurrentPlanCard(subscriptionState, isDarkMode);
                      },
                    ),

                    SizedBox(height: 32.h),

                    // 🚀 Available Plans - FIXED: Using SubscriptionBloc
                    BlocBuilder<SubscriptionBloc, SubscriptionState>(
                      builder: (context, subscriptionState) {
                        return _buildAvailablePlansSection(subscriptionState, stripeState, isDarkMode);
                      },
                    ),

                    SizedBox(height: 32.h),

                    // 💡 Features comparison
                    _buildFeaturesComparison(isDarkMode),

                    SizedBox(height: 100.h), // Bottom padding for navigation
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🚀 Payment Success Banner
  Widget _buildPaymentSuccessBanner(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.success.withValues(alpha:0.2)
            : AppColors.success.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.success.withValues(alpha:0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha:0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pagamento Completato! 🎉',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Il tuo abbonamento Premium è attivo!',
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

  /// 🔧 Payment Loading Overlay
  Widget _buildPaymentLoadingOverlay(StripePaymentLoading state, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.only(bottom: 24.h),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.info.withValues(alpha:0.3),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 40.w,
            height: 40.w,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            state.message ?? 'Preparazione pagamento...',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Il sistema di pagamento si aprirà automaticamente',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔧 FIXED: Current Plan Card using SubscriptionBloc
  Widget _buildCurrentPlanCard(SubscriptionState subscriptionState, bool isDarkMode) {
    // 🔧 FIX: Determina stato da SubscriptionBloc, non da StripeBloc
    bool hasPremium = false;
    String planName = 'Piano Free';
    String planDescription = 'Gratuito';
    List<String> features = [
      'Schede di allenamento (max 3)',
      'Esercizi personalizzati (max 5)',
    ];

    if (subscriptionState is SubscriptionLoaded) {
      final subscription = subscriptionState.subscription;
      hasPremium = subscription.isPremium && !subscription.isExpired;

      if (hasPremium) {
        planName = 'Piano Premium';
        planDescription = 'Attivo';
        features = ['Accesso completo a tutte le funzionalità'];

        //print('[CONSOLE][subscription_screen]✅ [SUBSCRIPTION] User has Premium: ${subscription.planName} - €${subscription.price}');
      } else {
        //print('[CONSOLE][subscription_screen]ℹ️ [SUBSCRIPTION] User has Free plan: ${subscription.planName} - €${subscription.price}');
      }
    } else if (_justCompletedPayment) {
      planName = 'Piano Premium';
      planDescription = 'In attivazione...';
      features = ['Il tuo abbonamento Premium verrà attivato a breve'];
      hasPremium = true;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: hasPremium
            ? LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: hasPremium ? null : (isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: hasPremium
              ? Colors.transparent
              : (isDarkMode ? Colors.grey.shade700 : AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:isDarkMode ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: hasPremium
                      ? Colors.white.withValues(alpha:0.2)
                      : (isDarkMode ? Colors.blue.shade900.withValues(alpha:0.3) : Colors.blue.shade50),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasPremium ? Icons.star : Icons.star_border,
                  color: hasPremium ? Colors.white : Colors.blue,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: hasPremium ? Colors.white : (isDarkMode ? Colors.white : AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      planDescription,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: hasPremium
                            ? Colors.white.withValues(alpha:0.9)
                            : (isDarkMode ? Colors.white70 : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasPremium && !_justCompletedPayment)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'ATTIVO',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (_justCompletedPayment)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha:0.3),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'ATTIVAZIONE',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 16.h),

          Text(
            _justCompletedPayment ? 'Stato attivazione' : (hasPremium ? 'Il tuo piano include:' : 'Il tuo piano non include:'),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: hasPremium ? Colors.white : (isDarkMode ? Colors.white : AppColors.textPrimary),
            ),
          ),

          SizedBox(height: 12.h),

          ...features.map((feature) => Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              children: [
                Icon(
                  hasPremium ? Icons.check_circle : Icons.cancel,
                  size: 16.sp,
                  color: hasPremium
                      ? Colors.white
                      : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: hasPremium
                          ? Colors.white.withValues(alpha:0.9)
                          : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ),
                ),
              ],
            ),
          )),

          // 🔧 FIX: Usage indicators only for Free users
          if (!hasPremium && !_justCompletedPayment && subscriptionState is SubscriptionLoaded) ...[
            SizedBox(height: 8.h),
            _buildUsageIndicator('Schede di allenamento', subscriptionState.subscription.currentCount,
                subscriptionState.subscription.maxWorkouts ?? 3, isDarkMode),
            SizedBox(height: 8.h),
            _buildUsageIndicator('Esercizi personalizzati', subscriptionState.subscription.currentCustomExercises,
                subscriptionState.subscription.maxCustomExercises ?? 5, isDarkMode),
          ],
        ],
      ),
    );
  }

  Widget _buildUsageIndicator(String label, int current, int max, bool isDarkMode) {
    final percentage = current / max;
    final isNearLimit = percentage >= 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            Text(
              '$current/$max',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isNearLimit
                    ? AppColors.warning
                    : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            isNearLimit ? AppColors.warning : AppColors.info,
          ),
        ),
      ],
    );
  }

  /// 🔧 FIXED: Available Plans using SubscriptionBloc
  Widget _buildAvailablePlansSection(SubscriptionState subscriptionState, StripeState stripeState, bool isDarkMode) {
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
        SizedBox(height: 8.h),
        Text(
          'Scegli il piano più adatto alle tue esigenze',
          style: TextStyle(
            fontSize: 16.sp,
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 24.h),

        // Free Plan
        _buildPlanCard(
          subscriptionState: subscriptionState,
          name: 'Free',
          price: 'Gratuito',
          description: 'Per iniziare',
          features: [
            'Schede di allenamento (max 3)',
            'Esercizi personalizzati (max 5)',
          ],
          isPremium: false,
          isDarkMode: isDarkMode,
          onTap: null, // Can't downgrade to free
        ),

        SizedBox(height: 16.h),

        // Premium Plan
        _buildPlanCard(
          subscriptionState: subscriptionState,
          stripeState: stripeState,
          name: 'Premium',
          price: '€4.99/mese',
          description: 'Tutte le funzionalità',
          features: [
            'Schede di allenamento illimitate',
            'Esercizi personalizzati illimitati',
            'Statistiche avanzate',
            'Backup automatico su cloud',
            'Nessuna pubblicità',
            'Supporto prioritario',
          ],
          isPremium: true,
          isDarkMode: isDarkMode,
          onTap: () => _startSubscriptionPayment('premium_monthly'),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required SubscriptionState subscriptionState,
    StripeState? stripeState,
    required String name,
    required String price,
    required String description,
    required List<String> features,
    required bool isPremium,
    required bool isDarkMode,
    VoidCallback? onTap,
  }) {
    // 🔧 FIXED: Determine if this plan is active using SubscriptionBloc
    bool isActive = false;
    bool isDisabled = false;
    String buttonText = 'SOTTOSCRIVI';

    if (subscriptionState is SubscriptionLoaded) {
      final subscription = subscriptionState.subscription;
      final userHasPremium = subscription.isPremium && !subscription.isExpired;

      if (isPremium) {
        // Premium plan
        isActive = userHasPremium;
        isDisabled = userHasPremium || _justCompletedPayment;
        buttonText = userHasPremium ? 'PIANO ATTUALE' : (_justCompletedPayment ? 'IN ATTIVAZIONE' : 'SOTTOSCRIVI');
      } else {
        // Free plan
        isActive = !userHasPremium;
        isDisabled = true; // Can't downgrade to free
        buttonText = !userHasPremium ? 'PIANO ATTUALE' : 'NON DISPONIBILE';
      }
    } else if (_justCompletedPayment && isPremium) {
      isActive = true;
      isDisabled = true;
      buttonText = 'IN ATTIVAZIONE';
    }

    // Handle Stripe states for Premium plan
    if (isPremium && stripeState != null) {
      if (stripeState is StripePaymentLoading) {
        isDisabled = true;
        buttonText = 'PREPARAZIONE...';
      } else if (stripeState is StripeInitializing) {
        isDisabled = true;
        buttonText = 'INIZIALIZZAZIONE...';
      } else if (stripeState is StripeErrorState && !isActive) {
        buttonText = 'RIPROVA';
        isDisabled = false;
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isPremium && !isDisabled
              ? (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600)
              : (isDarkMode ? Colors.grey.shade700 : AppColors.border),
          width: isPremium && !isDisabled ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:isDarkMode ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: isDisabled ? null : onTap,
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isPremium && !isDisabled
                            ? (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600)
                            : (isDarkMode ? Colors.white : AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                ...features.map((feature) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16.sp,
                        color: isDarkMode ? Colors.green.shade400 : AppColors.success,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDarkMode ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

                SizedBox(height: 20.h),

                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: isDisabled ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? AppColors.success
                          : isPremium && !isDisabled
                          ? (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600)
                          : (isDarkMode ? Colors.grey.shade700 : AppColors.textSecondary),
                      foregroundColor: isActive
                          ? Colors.white
                          : isPremium && !isDisabled
                          ? (isDarkMode ? Colors.black : Colors.white)
                          : Colors.white,
                      disabledBackgroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesComparison(bool isDarkMode) {
    final features = [
      {'name': 'Schede di allenamento', 'free': '3', 'premium': 'Illimitate'},
      {'name': 'Esercizi personalizzati', 'free': '5', 'premium': 'Illimitati'},
      {'name': 'Statistiche avanzate', 'free': '❌', 'premium': '✅'},
      {'name': 'Backup cloud', 'free': '❌', 'premium': '✅'},
      {'name': 'Nessuna pubblicità', 'free': '❌', 'premium': '✅'},
      {'name': 'Supporto prioritario', 'free': '❌', 'premium': '✅'},
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Text(
              'Confronta i piani',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),

          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              border: Border(
                top: BorderSide(
                  color: isDarkMode ? Colors.grey.shade700 : AppColors.border,
                ),
                bottom: BorderSide(
                  color: isDarkMode ? Colors.grey.shade700 : AppColors.border,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Funzionalità',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Free',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Features
          ...features.map((feature) => Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.grey.shade700 : AppColors.border,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    feature['name']!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    feature['free']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    feature['premium']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                    ),
                  ),
                ),
              ],
            ),
          )),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  void _startSubscriptionPayment(String planId) {
    final priceId = StripeConfig.subscriptionPlans[planId]?.stripePriceId ?? 'price_1RXVOfHHtQGHyul9qMGFmpmO';

    //print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] User clicked subscribe for plan: $planId');

    // 🔧 FIX: Initialize Stripe if necessary BEFORE creating payment
    _initializeStripeForPayment();

    final stripeBloc = context.read<StripeBloc>();
    final currentState = stripeBloc.state;

    if (currentState is StripeInitial || currentState is StripeInitializing) {
      // Stripe is initializing, wait for it to be ready
      _waitForStripeAndCreatePayment(planId, priceId);
    } else if (currentState is StripeReady) {
      // Stripe is ready, create payment immediately
      _createPaymentIntent(planId, priceId);
    } else {
      // Error state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nel sistema di pagamento. Riprova.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Wait for Stripe to be ready and then create payment
  void _waitForStripeAndCreatePayment(String planId, String priceId) {
    final subscription = context.read<StripeBloc>().stream.listen((state) {
      if (state is StripeReady) {
        _createPaymentIntent(planId, priceId);
      } else if (state is StripeErrorState) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore inizializzazione pagamenti: ${state.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    // Cancel listener after 30 seconds to avoid memory leak
    Future.delayed(const Duration(seconds: 30), () {
      subscription.cancel();
    });
  }

  /// Create payment intent
  void _createPaymentIntent(String planId, String priceId) {
    context.read<StripeBloc>().add(CreateSubscriptionPaymentEvent(
      priceId: priceId,
      metadata: {
        'plan_id': planId,
        'user_platform': 'flutter',
        'source': 'subscription_screen',
      },
    ));
  }

  /// Present Payment Sheet
  Future<void> _presentPaymentSheet(BuildContext context, StripePaymentReady state) async {
    try {
      //print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Presenting Payment Sheet...');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Apertura sistema di pagamento...'),
            ],
          ),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      // Present Payment Sheet
      context.read<StripeBloc>().add(ProcessPaymentEvent(
        clientSecret: state.paymentIntent.clientSecret,
        paymentType: state.paymentType,
      ));

    } catch (e) {
      //print('[CONSOLE][subscription_screen]❌ [SUBSCRIPTION] Error in _presentPaymentSheet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore apertura pagamento: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}