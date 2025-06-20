// lib/features/subscription/presentation/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';  // 🚀 NUOVO: Per StreamSubscription e Timer
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
  bool _isProcessingPayment = false;
  bool _paymentSheetOpened = false;  // 🚀 NUOVO: Previene chiamate multiple
  String _selectedPaymentType = 'recurring';

  @override
  void initState() {
    super.initState();
    print('[CONSOLE][subscription_screen]💳 [SUBSCRIPTION] Screen loaded');
    // Carica subscription status
    context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent());
  }

  @override
  void dispose() {
    // Reset flags on dispose
    _paymentSheetOpened = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: BlocConsumer<StripeBloc, StripeState>(
        listener: (context, state) {
          print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Stripe state: ${state.runtimeType}');

          if (state is StripePaymentLoading || state is StripeInitializing) {
            setState(() {
              _isProcessingPayment = true;
            });
          }

          if (state is StripePaymentReady && !_paymentSheetOpened) {  // 🚀 FIX: Previene chiamate multiple
            print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Payment Ready - opening Payment Sheet (ONCE)');
            _paymentSheetOpened = true;  // Marca come aperto
            _presentPaymentSheet(context, state);
          } else if (state is StripePaymentSuccess) {
            print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Payment Success!');

            // 🚀 RESET FLAGS
            _paymentSheetOpened = false;

            setState(() {
              _isProcessingPayment = false;
              _justCompletedPayment = true;
            });

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

            // Reload subscription after successful payment
            context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent());

          } else if (state is StripeErrorState) {
            print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Stripe Error: ${state.message}');

            // 🚀 RESET FLAGS
            _paymentSheetOpened = false;

            setState(() {
              _isProcessingPayment = false;
            });

            if (_justCompletedPayment && state.message.contains('caricamento subscription')) {
              print('[CONSOLE][subscription_screen]⚠️ [SUBSCRIPTION] Ignoring subscription loading error after payment');
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
          } else {
            // 🚀 RESET FLAGS per altri stati
            if (state is! StripePaymentLoading && state is! StripeInitializing) {
              setState(() {
                _isProcessingPayment = false;
              });
            }
          }
        },
        builder: (context, stripeState) {
          return BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, subscriptionState) {
              if (subscriptionState is SubscriptionLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // 🚀 FIX 2: DETERMINA SE UTENTE HA PREMIUM
              bool userHasPremium = false;
              if (subscriptionState is SubscriptionLoaded) {
                final subscription = subscriptionState.subscription;
                userHasPremium = subscription.isPremium && !subscription.isExpired;
              }

              return CustomScrollView(
                slivers: [
                  // APP BAR
                  SliverAppBar(
                    expandedHeight: 120.h,
                    floating: true,
                    pinned: true,
                    backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        'Premium Subscription',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      centerTitle: true,
                    ),
                  ),

                  // CONTENT
                  SliverPadding(
                    padding: EdgeInsets.all(16.w),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        // 🔧 Payment Loading Overlay
                        if (_isProcessingPayment)
                          _buildPaymentLoadingOverlay(isDarkMode),

                        // 🚀 Payment Success Banner
                        if (_justCompletedPayment)
                          _buildPaymentSuccessBanner(isDarkMode),

                        // 📊 Current Plan Card
                        _buildCurrentPlanCard(subscriptionState, isDarkMode),

                        SizedBox(height: 32.h),

                        // 🚀 FIX 2: NASCONDI OPZIONI ABBONAMENTO SE PREMIUM ATTIVO
                        if (!userHasPremium) ...[
                          // Titolo Abbonamenti Disponibili
                          Text(
                            'Scegli il tuo piano',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : AppColors.textPrimary,
                            ),
                          ),

                          SizedBox(height: 16.h),

                          // Payment Type Selector
                          _buildPaymentTypeSelector(isDarkMode),

                          SizedBox(height: 20.h),

                          // Available Plans
                          _buildAvailablePlansSection(subscriptionState, stripeState, isDarkMode),

                        ] else ...[
                          // Messaggio per utenti Premium
                          _buildPremiumUserMessage(isDarkMode),
                        ],

                        SizedBox(height: 32.h),

                        // 💡 Features comparison (sempre visibile)
                        _buildFeaturesComparison(isDarkMode),

                        SizedBox(height: 100.h), // Bottom padding
                      ]),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// 🔧 Payment Loading Overlay
  Widget _buildPaymentLoadingOverlay(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDarkMode ? Colors.blue.shade400 : AppColors.indigo600,
        ),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? Colors.blue.shade400 : AppColors.indigo600,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Preparazione pagamento...',
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
        color: isDarkMode ? AppColors.success.withOpacity(0.2) : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.success),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 32.sp,
            color: AppColors.success,
          ),
          SizedBox(height: 8.h),
          Text(
            'Pagamento completato con successo!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
          Text(
            'Il tuo abbonamento Premium è ora attivo',
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

  /// 🚀 FIX 2: Messaggio per utenti Premium
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
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: Text(
              'Piano attivo',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Current Plan Card
  Widget _buildCurrentPlanCard(SubscriptionState subscriptionState, bool isDarkMode) {
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
          color: hasPremium ? Colors.transparent : (isDarkMode ? Colors.grey.shade700 : AppColors.border),
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
                            ? Colors.white.withOpacity(0.9)
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
                    color: Colors.white.withOpacity(0.2),
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
                    color: Colors.orange.withOpacity(0.3),
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
            _justCompletedPayment ? 'Stato attivazione' : (hasPremium ? 'Il tuo piano include:' : 'Il tuo piano include:'),
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
                  hasPremium ? Icons.check_circle : Icons.info_outline,
                  size: 16.sp,
                  color: hasPremium ? Colors.white : (isDarkMode ? Colors.white70 : AppColors.textSecondary),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: hasPremium ? Colors.white : (isDarkMode ? Colors.white70 : AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// Payment Type Selector
  Widget _buildPaymentTypeSelector(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPaymentTypeOption(
              title: 'Ricorrente',
              subtitle: 'Si rinnova automaticamente',
              value: 'recurring',
              icon: Icons.refresh,
              isDarkMode: isDarkMode,
            ),
          ),
          Expanded(
            child: _buildPaymentTypeOption(
              title: 'Una tantum',
              subtitle: '30 giorni, poi scade',
              value: 'onetime',
              icon: Icons.payment,
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required bool isDarkMode,
  }) {
    final isSelected = _selectedPaymentType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentType = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? Colors.blue.shade700 : AppColors.indigo600)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? Colors.white70 : AppColors.textSecondary),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.white : AppColors.textPrimary),
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                color: isSelected
                    ? Colors.white.withOpacity(0.8)
                    : (isDarkMode ? Colors.white70 : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Available Plans Section
  Widget _buildAvailablePlansSection(SubscriptionState subscriptionState, StripeState? stripeState, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium Plan Card
        _buildPlanCard(
          subscriptionState: subscriptionState,
          stripeState: stripeState,
          name: 'Premium',
          price: '€4,99',
          description: _selectedPaymentType == 'recurring' ? 'al mese' : 'per 30 giorni',
          features: [
            'Schede di allenamento illimitate',
            'Esercizi personalizzati illimitati',
            'Statistiche avanzate',
            'Backup cloud',
            'Nessuna pubblicità',
          ],
          isPremium: true,
          isDarkMode: isDarkMode,
          onTap: () => _handleSubscriptionPayment(),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required SubscriptionState subscriptionState,
    required StripeState? stripeState,
    required String name,
    required String price,
    required String description,
    required List<String> features,
    required bool isPremium,
    required bool isDarkMode,
    VoidCallback? onTap,
  }) {
    bool isActive = false;
    bool isDisabled = false;
    String buttonText = 'SOTTOSCRIVI';

    if (subscriptionState is SubscriptionLoaded) {
      final subscription = subscriptionState.subscription;
      final userHasPremium = subscription.isPremium && !subscription.isExpired;

      if (isPremium) {
        isActive = userHasPremium;
        isDisabled = userHasPremium || _justCompletedPayment;
        buttonText = userHasPremium ? 'PIANO ATTUALE' : (_justCompletedPayment ? 'IN ATTIVAZIONE' : 'SOTTOSCRIVI');
      }
    } else if (_justCompletedPayment && isPremium) {
      isActive = true;
      isDisabled = true;
      buttonText = 'IN ATTIVAZIONE';
    }

    if (isPremium && stripeState != null) {
      if (stripeState is StripePaymentLoading || stripeState is StripeInitializing) {
        isDisabled = true;
        buttonText = 'PREPARAZIONE...';
      } else if (stripeState is StripeErrorState && !isActive) {
        buttonText = 'RIPROVA';
        isDisabled = false;
      }
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
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
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
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
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
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
                        Icons.check_circle,
                        size: 16.sp,
                        color: isDarkMode ? Colors.green.shade400 : AppColors.success,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

                SizedBox(height: 20.h),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isDisabled ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? AppColors.success
                          : (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600),
                      disabledBackgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
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

  /// Features Comparison
  Widget _buildFeaturesComparison(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confronto funzionalità',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),

        _buildComparisonTable(isDarkMode),
      ],
    );
  }

  Widget _buildComparisonTable(bool isDarkMode) {
    final features = [
      {'name': 'Schede di allenamento', 'free': 'Fino a 3', 'premium': 'Illimitate'},
      {'name': 'Esercizi personalizzati', 'free': 'Fino a 5', 'premium': 'Illimitati'},
      {'name': 'Statistiche avanzate', 'free': 'Base', 'premium': 'Dettagliate'},
      {'name': 'Backup cloud', 'free': '❌', 'premium': '✅'},
      {'name': 'Nessuna pubblicità', 'free': '❌', 'premium': '✅'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Funzionalità',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Gratuito',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
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
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Features rows
          ...features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;
            final isLast = index == features.length - 1;

            return Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: isLast ? null : Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey.shade700 : AppColors.border,
                    width: 1,
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
            );
          }),
        ],
      ),
    );
  }

  /// Handle Subscription Payment - SIMPLIFIED
  void _handleSubscriptionPayment() {
    if (_isProcessingPayment || _paymentSheetOpened) {
      print('[CONSOLE][subscription_screen]⚠️ [SUBSCRIPTION] Payment already in progress, ignoring');
      return;
    }

    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Starting payment process for $_selectedPaymentType');

    // 🚀 SIMPLIFIED: Direct initialization and payment creation
    final stripeBloc = context.read<StripeBloc>();

    if (stripeBloc.state is! StripeReady) {
      print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Initializing Stripe...');
      _hasTriedInitialization = true;
      stripeBloc.add(const InitializeStripeEvent());

      // Listen ONCE for Stripe ready, then create payment
      late StreamSubscription subscription;
      subscription = stripeBloc.stream.listen((state) {
        if (state is StripeReady && !_paymentSheetOpened) {
          subscription.cancel(); // ✅ Cancel listener immediately
          _createPaymentIntent();
        } else if (state is StripeErrorState) {
          subscription.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore inizializzazione: ${state.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      });

      // Auto-cancel after 30 seconds
      Timer(const Duration(seconds: 30), () {
        subscription.cancel();
      });
    } else {
      // Stripe already ready, create payment immediately
      _createPaymentIntent();
    }
  }

  void _createPaymentIntent() {
    // 🚀 FIX: Safe access to subscription plans
    final subscriptionPlans = StripeConfig.subscriptionPlans;

    if (subscriptionPlans.isEmpty) {
      print('[CONSOLE][subscription_screen]❌ [SUBSCRIPTION] No subscription plans configured');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: Piani abbonamento non configurati'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Try multiple possible keys for premium plan
    SubscriptionPlan? selectedPlan;

    // Try common keys
    final possibleKeys = [
      'premium_monthly',
      'premium',
      'premium_monthly_recurring',
      'premium_plan',
    ];

    for (final key in possibleKeys) {
      selectedPlan = subscriptionPlans[key];
      if (selectedPlan != null) {
        print('[CONSOLE][subscription_screen]✅ [SUBSCRIPTION] Found plan with key: $key');
        break;
      }
    }

    // Fallback: take first available plan
    if (selectedPlan == null && subscriptionPlans.isNotEmpty) {
      selectedPlan = subscriptionPlans.values.first;
      print('[CONSOLE][subscription_screen]⚠️ [SUBSCRIPTION] Using fallback plan: ${selectedPlan.name}');
    }

    if (selectedPlan == null) {
      print('[CONSOLE][subscription_screen]❌ [SUBSCRIPTION] No plans available');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: Nessun piano disponibile'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Creating payment for plan: ${selectedPlan.name} (${selectedPlan.stripePriceId})');

    context.read<StripeBloc>().add(CreateSubscriptionPaymentEvent(
      priceId: selectedPlan.stripePriceId,
      metadata: {
        'plan_id': selectedPlan.id,
        'payment_type': _selectedPaymentType,
        'user_platform': 'flutter',
        'source': 'subscription_screen',
      },
    ));
  }

  Future<void> _presentPaymentSheet(BuildContext context, StripePaymentReady state) async {
    try {
      print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Presenting Payment Sheet (SINGLE CALL)...');

      // 🚀 REMOVED: SnackBar che potrebbe causare conflitti
      // Directly present payment sheet without intermediary UI

      context.read<StripeBloc>().add(ProcessPaymentEvent(
        clientSecret: state.paymentIntent.clientSecret,
        paymentType: state.paymentType,
      ));

    } catch (e) {
      print('[CONSOLE][subscription_screen]❌ [SUBSCRIPTION] Error presenting Payment Sheet: $e');

      // Reset flags on error
      setState(() {
        _paymentSheetOpened = false;
        _isProcessingPayment = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore apertura pagamento: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}