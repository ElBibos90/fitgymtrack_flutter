// lib/features/subscription/presentation/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../core/config/stripe_config.dart';
import '../../../payments/bloc/stripe_bloc.dart';
import '../../bloc/subscription_bloc.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // 🆕 NUOVO: Stato per il tipo di pagamento selezionato
  String _selectedPaymentType = 'recurring'; // Default: ricorrente
  bool _isProcessingPayment = false;
  bool _justCompletedPayment = false;

  @override
  void initState() {
    super.initState();
    print('[CONSOLE][subscription_screen]🔧 [INIT] SubscriptionScreen initialized');
    // Carica i dati dell'abbonamento
    context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Premium Subscription',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : AppColors.textPrimary,
        ),
      ),
      body: BlocConsumer<StripeBloc, StripeState>(
        listener: (context, state) {
          print('[CONSOLE][subscription_screen]🔧 [STRIPE STATE] ${state.runtimeType}');

          if (state is StripePaymentLoading || state is StripeInitializing) {
            print('[CONSOLE][subscription_screen]🔧 [STRIPE] Loading...');
            setState(() {
              _isProcessingPayment = true;
            });
          }

          if (state is StripePaymentReady) {
            print('[CONSOLE][subscription_screen]🔧 [STRIPE] Payment Ready - opening Payment Sheet');
            print('[CONSOLE][subscription_screen]🔧 [STRIPE] Payment Type: ${state.paymentType}');
            print('[CONSOLE][subscription_screen]🔧 [STRIPE] Amount: ${state.paymentIntent.amount}');
            _presentPaymentSheet(context, state);
          } else if (state is StripePaymentSuccess) {
            print('[CONSOLE][subscription_screen]🔧 [STRIPE] Payment Success!');
            Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/subscription');

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
            context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent(checkExpired: false));
          } else if (state is StripeErrorState) {
            print('[CONSOLE][subscription_screen]🔧 [STRIPE ERROR] ${state.message}');
            setState(() {
              _isProcessingPayment = false;
            });

            if (_justCompletedPayment && state.message.contains('caricamento subscription')) {
              print('[CONSOLE][subscription_screen]⚠️ [STRIPE] Ignoring subscription loading error after successful payment');
              _justCompletedPayment = false;
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(child: Text('Errore nel sistema di pagamento: ${state.message}')),
                  ],
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: Duration(seconds: 8), // Più lungo per debug
              ),
            );
          } else {
            setState(() {
              _isProcessingPayment = false;
            });
          }
        },
        builder: (context, stripeState) {
          return BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, subscriptionState) {
              print('[CONSOLE][subscription_screen]🔧 [SUB STATE] ${subscriptionState.runtimeType}');

              if (subscriptionState is SubscriptionLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Premium info
                    _buildPremiumHeader(subscriptionState, isDarkMode),

                    SizedBox(height: 24.h),

                    // 🆕 Payment Type Selection
                    _buildPaymentTypeSelection(isDarkMode),

                    SizedBox(height: 24.h),

                    // Features comparison
                    _buildFeaturesComparison(subscriptionState, isDarkMode),

                    SizedBox(height: 24.h),

                    // Subscribe button
                    _buildSubscribeButton(subscriptionState, stripeState, isDarkMode),

                    SizedBox(height: 24.h),

                    // Security info
                    _buildSecuritySection(isDarkMode),

                    SizedBox(height: 40.h),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🆕 BUILD PAYMENT TYPE SELECTION
  Widget _buildPaymentTypeSelection(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scegli il tipo di abbonamento',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Seleziona come preferisci gestire il tuo abbonamento Premium',
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 20.h),

          // 🔄 RECURRING CARD
          _buildPaymentTypeCard(
            paymentType: 'recurring',
            title: 'Premium Ricorrente',
            subtitle: '€4.99/mese',
            badge: 'RINNOVO AUTO',
            badgeColor: AppColors.success,
            description: 'Si rinnova automaticamente ogni mese. Cancella quando vuoi.',
            isDarkMode: isDarkMode,
          ),

          SizedBox(height: 16.h),

          // 💸 ONETIME CARD
          _buildPaymentTypeCard(
            paymentType: 'onetime',
            title: 'Premium Una Tantum',
            subtitle: '€4.99 per 30 giorni',
            badge: 'NESSUN RINNOVO',
            badgeColor: AppColors.info,
            description: '30 giorni di accesso Premium senza rinnovo automatico.',
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  // 🔧 PAYMENT TYPE CARD FIXATA
  Widget _buildPaymentTypeCard({
    required String paymentType,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required String description,
    required bool isDarkMode,
  }) {
    final isSelected = _selectedPaymentType == paymentType;

    return GestureDetector(
      onTap: () {
        print('[CONSOLE][subscription_screen]🔧 [PAYMENT TYPE] Selected: $paymentType');
        setState(() {
          _selectedPaymentType = paymentType;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600)
                : (isDarkMode ? Colors.grey.shade700 : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12.r),
          color: isSelected
              ? (isDarkMode ? const Color(0xFF90CAF9).withOpacity(0.1) : AppColors.indigo50)
              : (isDarkMode ? AppColors.backgroundDark : Colors.white),
        ),
        child: Row(
          children: [
            // Radio button
            Radio<String>(
              value: paymentType,
              groupValue: _selectedPaymentType,
              onChanged: (value) {
                if (value != null) {
                  print('[CONSOLE][subscription_screen]🔧 [RADIO] Changed to: $value');
                  setState(() {
                    _selectedPaymentType = value;
                  });
                }
              },
              activeColor: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),

            SizedBox(width: 8.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),

                  SizedBox(height: 4.h),

                  // Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: badgeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(SubscriptionState state, bool isDarkMode) {
    final hasPremium = state is SubscriptionLoaded && state.subscription.isPremium;

    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasPremium
              ? [AppColors.success, AppColors.success.withOpacity(0.8)]
              : [AppColors.indigo600, AppColors.indigo700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: (hasPremium ? AppColors.success : AppColors.indigo600).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            hasPremium ? Icons.stars : Icons.workspace_premium,
            size: 48.sp,
            color: Colors.white,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPremium ? 'Premium Attivo' : 'Sblocca Premium',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  hasPremium
                      ? 'Stai usando tutti i benefici Premium'
                      : 'Accedi a tutte le funzionalità avanzate',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.9),
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
        ],
      ),
    );
  }

  Widget _buildFeaturesComparison(SubscriptionState state, bool isDarkMode) {
    final hasPremium = state is SubscriptionLoaded && state.subscription.isPremium;

    final features = [
      {'name': 'Schede di allenamento', 'free': 'Fino a 3', 'premium': 'Illimitate'},
      {'name': 'Esercizi personalizzati', 'free': 'Fino a 10', 'premium': 'Illimitati'},
      {'name': 'Statistiche avanzate', 'free': 'Base', 'premium': 'Dettagliate'},
      {'name': 'Backup su cloud', 'free': '❌', 'premium': '✅'},
      {'name': 'Nessuna pubblicità', 'free': '❌', 'premium': '✅'},
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confronto funzionalità',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.surfaceDark : Colors.white,
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
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      topRight: Radius.circular(12.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
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
                          'Gratuito',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Premium',
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
                ),
                // Features rows
                ...features.asMap().entries.map((entry) {
                  final feature = entry.value;
                  return Container(
                    padding: EdgeInsets.all(16.w),
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
                          child: Text(
                            feature['name']!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
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
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton(SubscriptionState subscriptionState, StripeState stripeState, bool isDarkMode) {
    final hasPremium = subscriptionState is SubscriptionLoaded && subscriptionState.subscription.isPremium;
    final selectedPlan = StripeConfig.getPlanByPaymentType(_selectedPaymentType);

    if (hasPremium && !_justCompletedPayment) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        child: Text(
          'Hai già un abbonamento Premium attivo!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info piano selezionato
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF90CAF9).withOpacity(0.1)
                  : AppColors.indigo50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedPaymentType == 'recurring' ? Icons.refresh : Icons.payment,
                  color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPlan.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        selectedPlan.description,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  selectedPlan.formattedPrice,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Subscribe button
          ElevatedButton(
            onPressed: _isProcessingPayment ? null : () => _handleSubscriptionPayment(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 2,
            ),
            child: _isProcessingPayment
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20.sp,
                  height: 20.sp,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Elaborazione...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
                : Text(
              _selectedPaymentType == 'recurring'
                  ? 'Sottoscrivi Premium (€4.99/mese)'
                  : 'Acquista 30 Giorni (€4.99)',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // Legal note
          Text(
            _selectedPaymentType == 'recurring'
                ? 'Il rinnovo automatico può essere annullato in qualsiasi momento.'
                : 'Nessun addebito futuro. L\'accesso Premium scade automaticamente dopo 30 giorni.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDarkMode ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.green[50],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: AppColors.success,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pagamento sicuro',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Powered by Stripe - standard bancario di sicurezza',
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

  // 🔧 HANDLE SUBSCRIPTION PAYMENT CON DEBUG AVANZATO
  void _handleSubscriptionPayment() {
    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] User selected payment type: $_selectedPaymentType');

    final selectedPlan = StripeConfig.getPlanByPaymentType(_selectedPaymentType);
    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Selected plan: ${selectedPlan.name}');
    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Price ID: ${selectedPlan.stripePriceId}');
    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Payment Type: ${selectedPlan.paymentType}');

    setState(() {
      _isProcessingPayment = true;
    });

    // 🔧 DEBUG: Verifica configurazione Stripe
    if (!StripeConfig.isValidKey(StripeConfig.publishableKey)) {
      print('[CONSOLE][subscription_screen]❌ [SUBSCRIPTION] Stripe configuration invalid!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configurazione Stripe non valida'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() {
        _isProcessingPayment = false;
      });
      return;
    }

    // 🔧 DEBUG: Verifica stato Stripe Bloc
    final stripeState = context.read<StripeBloc>().state;
    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Current Stripe state: ${stripeState.runtimeType}');

    // Inizializza Stripe se necessario
    if (stripeState is StripeInitial) {
      print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Initializing Stripe first...');
      context.read<StripeBloc>().add(const InitializeStripeEvent());
      _waitForStripeAndCreatePayment(selectedPlan);
    } else if (stripeState is StripeReady) {
      print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Stripe ready, creating payment intent...');
      _createPaymentIntent(selectedPlan);
    } else {
      print('[CONSOLE][subscription_screen]❌ [SUBSCRIPTION] Unexpected Stripe state: ${stripeState.runtimeType}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stato Stripe non valido: ${stripeState.runtimeType}'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  void _waitForStripeAndCreatePayment(SubscriptionPlan plan) {
    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Waiting for Stripe initialization...');

    final subscription = context.read<StripeBloc>().stream.listen((state) {
      print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Stripe state changed during wait: ${state.runtimeType}');

      if (state is StripeReady) {
        print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Stripe ready, proceeding with payment creation...');
        _createPaymentIntent(plan);
      } else if (state is StripeErrorState) {
        print('[CONSOLE][subscription_screen]❌ [SUBSCRIPTION] Stripe initialization error: ${state.message}');
        setState(() {
          _isProcessingPayment = false;
        });
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

  void _createPaymentIntent(SubscriptionPlan plan) {
    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Creating payment intent...');
    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Plan ID: ${plan.id}');
    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Price ID: ${plan.stripePriceId}');
    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Payment Type: ${plan.paymentType}');

    final metadata = {
      'plan_id': plan.id,
      'payment_type': plan.paymentType, // 🆕 NUOVO: Passa il tipo di pagamento
      'subscription_payment_type': plan.paymentType, // 🆕 CRITICAL: Campo che il backend cerca
      'user_platform': 'flutter',
      'source': 'subscription_screen',
    };

    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Metadata: $metadata');

    context.read<StripeBloc>().add(CreateSubscriptionPaymentEvent(
      priceId: plan.stripePriceId,
      metadata: metadata,
    ));
  }

  Future<void> _presentPaymentSheet(BuildContext context, StripePaymentReady state) async {
    try {
      print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Presenting Payment Sheet...');
      print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Client Secret: ${state.paymentIntent.clientSecret.substring(0, 20)}...');

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
              const Text('Apertura sistema di pagamento...'),
            ],
          ),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // Present Payment Sheet
      context.read<StripeBloc>().add(ProcessPaymentEvent(
        clientSecret: state.paymentIntent.clientSecret,
        paymentType: state.paymentType,
      ));

    } catch (e) {
      print('[CONSOLE][subscription_screen]❌ [SUBSCRIPTION] Error in _presentPaymentSheet: $e');
      setState(() {
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