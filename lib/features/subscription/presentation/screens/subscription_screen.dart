// lib/features/subscription/presentation/screens/subscription_screen.dart - 🔧 FIX OVERLAY LOADING

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

// App imports
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

// Feature imports - subscription
import '../../bloc/subscription_bloc.dart';
import '../../models/subscription_models.dart';
import '../widgets/subscription_widgets.dart';

// Feature imports - payments
import '../../../payments/bloc/stripe_bloc.dart';
import '../../../payments/models/stripe_models.dart';
import '../../../../core/config/stripe_config.dart';

/// 🚀 SubscriptionScreen - FIXED: Overlay Loading Cleanup
/// 🔧 FIX: Risolve il problema dell'overlay "nebbia" dopo pagamenti
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // 🔧 FIX: Stati separati per gestire overlay e cleanup
  bool _justCompletedPayment = false;
  bool _isPaymentProcessing = false; // Nuovo flag per gestire overlay
  StreamSubscription? _stripeSubscription;

  @override
  void initState() {
    super.initState();

    // Carica subscription al primo avvio
    context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent(checkExpired: false));
    
    // 🔧 FIX: Ascolta aggiornamenti del bloc Stripe per ricaricare subscription
    _stripeSubscription = context.read<StripeBloc>().stream.listen((stripeState) {
      if (!mounted) return; // Evita aggiornamenti se il widget è smontato
      
      if (stripeState is StripePaymentSuccess && stripeState.paymentType == 'subscription') {
        print('[CONSOLE][DEBUG] SubscriptionScreen: Payment success, reloading subscription');
        // Ricarica subscription dopo pagamento riuscito
        context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent(
          checkExpired: false,
          forceRefresh: true,
        ));
        
        // 🔧 FIX: Forza un rebuild della schermata per assicurarsi che tutto sia aggiornato
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _justCompletedPayment = true;
              _isPaymentProcessing = false;
            });
            
            // 🔧 FIX: Assicurati che siamo ancora nella tab corretta dopo il pagamento
            // Questo dovrebbe prevenire la sparizione dei tab
            final routerState = GoRouterState.of(context);
            if (routerState.uri.path != '/dashboard') {
              context.go('/dashboard?tab=3'); // Tab 3 = Abbonamento
            }
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      _isPaymentProcessing = false;
    });
  }

  @override
  void dispose() {
    // 🔧 FIX: Cancella la subscription per evitare errori di widget unmounted
    _stripeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: BlocConsumer<StripeBloc, StripeState>(
        listener: (context, state) {
          _handleStripeStateChanges(context, state);
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
                    // 🔧 FIX: Payment Loading Overlay gestito correttamente
                    if (_isPaymentProcessing && stripeState is StripePaymentLoading)
                      _buildPaymentLoadingOverlay(stripeState, isDarkMode),

                    // 🚀 Payment Success Banner se abbiamo appena completato un pagamento
                    if (_justCompletedPayment && !_isPaymentProcessing)
                      _buildPaymentSuccessBanner(isDarkMode),

                    // 📊 Current Plan Card - Using SubscriptionBloc
                    BlocBuilder<SubscriptionBloc, SubscriptionState>(
                      builder: (context, subscriptionState) {
                        return _buildCurrentPlanCard(subscriptionState, isDarkMode);
                      },
                    ),

                    SizedBox(height: 32.h),

                    // 🚀 Available Plans - Using SubscriptionBloc
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

  // ============================================================================
  // 🔧 FIX: STRIPE STATE MANAGEMENT - Gestione corretta degli stati
  // ============================================================================

  void _handleStripeStateChanges(BuildContext context, StripeState state) {
    if (state is StripePaymentLoading) {
      setState(() {
        _isPaymentProcessing = true;
      });
      
    } else if (state is StripePaymentReady) {
      _presentPaymentSheet(context, state);
      
    } else if (state is StripePaymentSuccess) {
      setState(() {
        _isPaymentProcessing = false;
        _justCompletedPayment = true;
      });

      
      // Mostra messaggio di successo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pagamento completato con successo!',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else if (state is StripeErrorState) {
      setState(() {
        _isPaymentProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Errore durante il pagamento: ${state.message}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // ============================================================================
  // PAYMENT SHEET PRESENTATION
  // ============================================================================

  Future<void> _presentPaymentSheet(BuildContext context, StripePaymentReady state) async {
    try {
      context.read<StripeBloc>().add(ProcessPaymentEvent(
        clientSecret: state.paymentIntent.clientSecret,
        paymentType: state.paymentType,
      ));
    } catch (e) {
      setState(() {
        _isPaymentProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nell\'apertura del pagamento: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ============================================================================
  // SUBSCRIPTION ACTIONS
  // ============================================================================

  void _subscribeToPremium(BuildContext context, {bool isRecurring = true}) {
    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Starting Premium subscription (recurring: $isRecurring)...');

    // 🔧 FIX: Usa i piani configurati invece di priceId hardcoded
    final plan = isRecurring 
        ? StripeConfig.recurringPlan 
        : StripeConfig.onetimePlan;

    context.read<StripeBloc>().add(CreateSubscriptionPaymentEvent(
      priceId: plan.stripePriceId,
      metadata: {
        'source': 'subscription_screen',
        'plan': plan.id,
        'payment_type': plan.paymentType,
        'is_recurring': plan.isRecurring.toString(),
      },
    ));
  }

  void _showPlanSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scegli il tuo piano'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.repeat, color: Colors.blue),
              title: Text('Abbonamento Ricorrente'),
              subtitle: Text('€4.99/mese - Si rinnova automaticamente'),
              onTap: () {
                Navigator.of(context).pop();
                _subscribeToPremium(context, isRecurring: true);
              },
            ),
            ListTile(
              leading: Icon(Icons.access_time, color: Colors.green),
              title: Text('Accesso Una Tantum'),
              subtitle: Text('€4.99 - 30 giorni senza rinnovo'),
              onTap: () {
                Navigator.of(context).pop();
                _subscribeToPremium(context, isRecurring: false);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annulla'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // UI BUILDERS
  // ============================================================================

  /// 🔧 FIX: Payment Loading Overlay con cleanup corretto
  Widget _buildPaymentLoadingOverlay(StripePaymentLoading state, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.only(bottom: 24.h),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
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

  /// 🚀 Payment Success Banner
  Widget _buildPaymentSuccessBanner(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.success.withValues(alpha: 0.2) : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
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
          // 🔧 FIX: Pulsante per chiudere manualmente il banner
          IconButton(
            onPressed: () {
              setState(() {
                _justCompletedPayment = false;
              });
            },
            icon: Icon(
              Icons.close,
              color: AppColors.success,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Current Plan Card
  Widget _buildCurrentPlanCard(SubscriptionState subscriptionState, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.card_membership,
                color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Piano Attuale',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          if (subscriptionState is SubscriptionLoaded) ...[
            if (subscriptionState.subscription.isPremium && !subscriptionState.subscription.isExpired) ...[
              // Premium attivo
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.blue.shade400],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    subscriptionState.subscription.formattedPrice,
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
                subscriptionState.subscription.endDate != null
                    ? 'Scade il ${_formatDate(subscriptionState.subscription.endDate!)}'
                    : 'Piano attivo',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ] else ...[
              // Piano Free
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'GRATUITO',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '€0.00',
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
                'Funzionalità di base incluse',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ] else if (subscriptionState is SubscriptionLoading) ...[
            Row(
              children: [
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Caricamento piano...',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Piano non disponibile',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🚀 Available Plans Section
  Widget _buildAvailablePlansSection(SubscriptionState subscriptionState, StripeState stripeState, bool isDarkMode) {
    final isCurrentlyPremium = subscriptionState is SubscriptionLoaded &&
        subscriptionState.subscription.isPremium && !subscriptionState.subscription.isExpired;

    if (isCurrentlyPremium) {
      return _buildPremiumUserMessage(isDarkMode);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Piani Disponibili',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),

        // Premium Plan Card personalizzata
        _buildPremiumPlanCard(stripeState, isDarkMode),
      ],
    );
  }

  /// Widget personalizzato per il piano Premium
  Widget _buildPremiumPlanCard(StripeState stripeState, bool isDarkMode) {
    final isLoading = stripeState is StripePaymentLoading;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
          width: 2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Colors.indigo.withValues(alpha: 0.2), Colors.purple.withValues(alpha: 0.1)]
              : [Colors.indigo.withValues(alpha: 0.1), Colors.purple.withValues(alpha: 0.05)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Premium',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.star,
                color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                size: 24.sp,
              ),
              Spacer(),
              Text(
                '€4.99/mese',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Features
          ...[
            'Schede illimitate',
            'Esercizi personalizzati',
            'Statistiche avanzate',
            'Backup automatico',
            'Supporto prioritario',
          ].map((feature) => Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  feature,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          )),

          SizedBox(height: 20.h),

          // Subscribe button
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _showPlanSelectionDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                foregroundColor: isDarkMode ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode ? Colors.black : Colors.white,
                  ),
                ),
              )
                  : Text(
                'Scegli il tuo piano',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚀 Premium User Message
  Widget _buildPremiumUserMessage(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.star,
            size: 48.sp,
            color: Colors.white,
          ),
          SizedBox(height: 16.h),
          Text(
            'Sei già Premium!',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Stai utilizzando tutti i benefici del piano Premium. Grazie per il supporto!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: () => context.push('/payment/donation'),
            icon: Icon(Icons.favorite, color: Colors.red.shade400),
            label: Text('Fai una donazione'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.purple.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 💡 Features Comparison
  Widget _buildFeaturesComparison(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confronto Funzionalità',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),

          _buildFeatureRow('Schede di allenamento', 'Fino a 3', 'Illimitate', isDarkMode),
          _buildFeatureRow('Esercizi personalizzati', '❌', '✅', isDarkMode),
          _buildFeatureRow('Statistiche avanzate', '❌', '✅', isDarkMode),
          _buildFeatureRow('Backup automatico', '❌', '✅', isDarkMode),
          _buildFeatureRow('Supporto prioritario', '❌', '✅', isDarkMode),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String feature, String free, String premium, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              premium,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.purple.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString; // Fallback se il parsing fallisce
    }
  }
}