// lib/features/payments/presentation/screens/stripe_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/config/stripe_config.dart';
import '../../bloc/stripe_bloc.dart';
import '../widgets/stripe_widgets.dart';
import '../../../subscription/presentation/widgets/subscription_widgets.dart';

class StripePaymentScreen extends StatefulWidget {
  final String paymentType; // 'subscription' o 'donation'
  final Map<String, dynamic>? parameters;

  const StripePaymentScreen({
    super.key,
    required this.paymentType,
    this.parameters,
  });

  @override
  State<StripePaymentScreen> createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends State<StripePaymentScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Inizializza Stripe se non è già stato fatto
    context.read<StripeBloc>().add(const InitializeStripeEvent());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.paymentType == 'subscription' ? 'Abbonamento Premium' : 'Donazione',
          style: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<StripeBloc, StripeState>(
        // 🔧 FIX CRITICO: Nuovo listener che gestisce StripePaymentReady per donazioni
        listener: (context, state) {
          print('[CONSOLE][stripe_payment_screen] 🔧 State changed: ${state.runtimeType}');

          // 🔧 FIX: Gestione automatica StripePaymentReady per donazioni
          if (state is StripePaymentReady) {
            print('[CONSOLE][stripe_payment_screen] 🔧 Payment Ready - processing automatically for ${state.paymentType}');

            // Per le donazioni, processa automaticamente il payment
            if (state.paymentType == 'donation') {
              // Presenta automaticamente il payment sheet
              context.read<StripeBloc>().add(ProcessPaymentEvent(
                clientSecret: state.paymentIntent.clientSecret,
                paymentType: state.paymentType,
              ));
            } else if (state is StripeErrorState) {
              final errorMessage = (state as StripeErrorState).message;
              print('[CONSOLE][stripe_payment_screen] ❌ Stripe Error: $errorMessage');

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Errore pagamento'),
                            Text(
                              'DEBUG: $errorMessage',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: Duration(seconds: 8), // Più lungo per leggere l'errore
                ),
              );
            } else {
              // Per le subscription, mantieni il comportamento esistente
              _handleStateChanges(context, state);
            }
          } else if (state is StripePaymentSuccess) {
            print('[CONSOLE][stripe_payment_screen] ✅ Payment Success!');

            // Vai alla pagina di completamento
            _pageController.animateToPage(
              2, // Pagina di successo
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );

            // Mostra messaggio di successo
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
          } else {
            // Per tutti gli altri stati, usa il metodo esistente
            _handleStateChanges(context, state);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Progress indicator per subscription
              if (widget.paymentType == 'subscription')
                _buildProgressIndicator(context, state, isDarkMode),

              // Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildSelectionPage(context, state, isDarkMode),
                    _buildPaymentPage(context, state, isDarkMode),
                    _buildCompletionPage(context, state, isDarkMode),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, StripeState state, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStepIndicator(1, 'Seleziona', _currentPage >= 0, isDarkMode),
          Expanded(child: _buildStepLine(_currentPage >= 1, isDarkMode)),
          _buildStepIndicator(2, 'Paga', _currentPage >= 1, isDarkMode),
          Expanded(child: _buildStepLine(_currentPage >= 2, isDarkMode)),
          _buildStepIndicator(3, 'Completo', _currentPage >= 2, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive, bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600)
                : (isDarkMode ? Colors.grey[700] : AppColors.border),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : (isDarkMode ? Colors.grey[400] : AppColors.textSecondary),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive
                ? (isDarkMode ? Colors.white : AppColors.textPrimary)
                : (isDarkMode ? Colors.grey[400] : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive, bool isDarkMode) {
    return Container(
      height: 2.h,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: isActive
            ? (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600)
            : (isDarkMode ? Colors.grey[700] : AppColors.border),
        borderRadius: BorderRadius.circular(1.r),
      ),
    );
  }

  Widget _buildSelectionPage(BuildContext context, StripeState state, bool isDarkMode) {
    if (widget.paymentType == 'subscription') {
      return _buildSubscriptionSelectionPage(context, state, isDarkMode);
    } else {
      return _buildDonationSelectionPage(context, state, isDarkMode);
    }
  }

  Widget _buildSubscriptionSelectionPage(BuildContext context, StripeState state, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scegli il tuo piano',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Sblocca tutte le funzionalità premium',
            style: TextStyle(
              fontSize: 16.sp,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 32.h),

          // Piani subscription
          Expanded(
            child: ListView(
              children: [
                _buildSubscriptionPlanCard(
                  context,
                  'premium_monthly',
                  StripeConfig.subscriptionPlans['premium_monthly']!,
                  isDarkMode,
                  isPopular: true,
                ),
                SizedBox(height: 16.h),
                _buildSubscriptionPlanCard(
                  context,
                  'premium_yearly',
                  StripeConfig.subscriptionPlans['premium_yearly']!,
                  isDarkMode,
                ),
              ],
            ),
          ),

          // Sezione sicurezza
          _buildSecuritySection(context, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlanCard(BuildContext context, String planId, dynamic plan, bool isDarkMode, {bool isPopular = false}) {
    return SubscriptionPlanCard(
      plan: plan,
      isCurrentPlan: false,
      onSubscribe: () => _startSubscriptionPayment(planId),
      isLoading: false,
    );
  }

  Widget _buildDonationSelectionPage(BuildContext context, StripeState state, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supporta FitGymTrack',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Il tuo supporto ci aiuta a migliorare l\'app per tutti',
            style: TextStyle(
              fontSize: 16.sp,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 32.h),

          // Importi predefiniti
          Text(
            'Seleziona un importo',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 2,
            children: [
              _buildDonationButton(context, 2.99, isDarkMode),
              _buildDonationButton(context, 4.99, isDarkMode),
              _buildDonationButton(context, 9.99, isDarkMode),
              _buildDonationButton(context, 19.99, isDarkMode),
              _buildDonationButton(context, 49.99, isDarkMode),
              _buildCustomDonationButton(context, isDarkMode),
            ],
          ),

          const Spacer(),

          // Sezione sicurezza
          _buildSecuritySection(context, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildDonationButton(BuildContext context, double amount, bool isDarkMode) {
    return ElevatedButton(
      onPressed: () => _startDonationPayment(amount),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        foregroundColor: isDarkMode ? Colors.white : AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: isDarkMode ? Colors.grey[600]! : AppColors.border,
          ),
        ),
      ),
      child: Text(
        '€${amount.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCustomDonationButton(BuildContext context, bool isDarkMode) {
    return OutlinedButton(
      onPressed: () => _showCustomDonationDialog(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
        side: BorderSide(
          color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Text(
        'Altro',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentPage(BuildContext context, StripeState state, bool isDarkMode) {
    if (state is StripePaymentLoading) {
      return _buildLoadingPage(
        context,
        state.message ?? 'Preparazione pagamento...',
        isDarkMode,
      );
    }

    if (state is StripePaymentReady) {
      return Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // Info pagamento
            Container(
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
                  Text(
                    'Riepilogo pagamento',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.paymentType == 'subscription' ? 'Piano Premium' : 'Donazione',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '€${(state.paymentIntent.amount / 100).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 🔧 FIX: Per le donazioni, non mostrare pulsante manuale
            if (widget.paymentType == 'subscription') ...[
              // Pulsante pagamento per subscription
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton.icon(
                  onPressed: () => _processPayment(state.paymentIntent.clientSecret, state.paymentType),
                  icon: const Icon(Icons.payment),
                  label: Text(
                    'Paga €${(state.paymentIntent.amount / 100).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // 🔧 FIX: Per le donazioni, mostra messaggio che il payment si apre automaticamente
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.blue[900] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDarkMode ? Colors.blue[700]! : Colors.blue[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: isDarkMode ? Colors.blue[300] : Colors.blue[600],
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Il sistema di pagamento si aprirà automaticamente',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDarkMode ? Colors.blue[300] : Colors.blue[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 16.h),

            // Note sicurezza
            Text(
              'Il pagamento è gestito in modo sicuro da Stripe. Non conserviamo i dati della tua carta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDarkMode ? Colors.white60 : AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return const Center(child: Text('Stato pagamento non riconosciuto'));
  }

  Widget _buildCompletionPage(BuildContext context, StripeState state, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: StripePaymentStatusWidget(state: state),
    );
  }

  Widget _buildLoadingPage(BuildContext context, String message, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            message,
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

  Widget _buildSecuritySection(BuildContext context, bool isDarkMode) {
    return Container(
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

  // Action methods

  void _startSubscriptionPayment(String planId) {
    final priceId = StripeConfig.subscriptionPlans[planId]?.stripePriceId ?? 'price_1RXVOfHHtQGHyul9qMGFmpmO';

    context.read<StripeBloc>().add(CreateSubscriptionPaymentEvent(
      priceId: priceId,
      metadata: {
        'plan_id': planId,
        'user_platform': 'flutter',
      },
    ));

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _startDonationPayment(double amount) {
    print('[CONSOLE][stripe_payment_screen] 🔧 Starting donation payment for €${amount}');

    // 🔧 DEBUG: Aggiungi listener temporaneo per debug
    final subscription = context.read<StripeBloc>().stream.listen((state) {
      print('[CONSOLE][stripe_payment_screen] 🔍 DEBUG State: ${state.runtimeType}');
      if (state is StripePaymentReady) {
        print('[CONSOLE][stripe_payment_screen] 🔍 DEBUG StripePaymentReady: paymentType=${state.paymentType}, amount=${state.paymentIntent.amount}');
      }
    });

    // Cancella il listener dopo 10 secondi
    Future.delayed(const Duration(seconds: 10), () => subscription.cancel());

    context.read<StripeBloc>().add(CreateDonationPaymentEvent(
      amount: StripeConfig.euroToCents(amount),
      metadata: {
        'donation_type': 'one_time',
        'user_platform': 'flutter',
      },
    ));

    // 🔧 FIX: NON fare nextPage() qui - sarà gestito automaticamente dal listener
    // Il listener farà automaticamente ProcessPaymentEvent quando arriva StripePaymentReady
  }

  void _processPayment(String clientSecret, String paymentType) {
    context.read<StripeBloc>().add(ProcessPaymentEvent(
      clientSecret: clientSecret,
      paymentType: paymentType,
    ));

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showCustomDonationDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Importo personalizzato'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Importo (€)',
              prefixText: '€ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  Navigator.of(dialogContext).pop();
                  _startDonationPayment(amount);
                }
              },
              child: const Text('Continua'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Aiuto'),
          content: const Text(
            'Se hai problemi con il pagamento, contatta il nostro supporto all\'indirizzo support@fitgymtrack.com',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // 🔧 MANTENUTO: Metodo originale per subscription (non modificato)
  void _handleStateChanges(BuildContext context, StripeState state) {
    if (state is StripePaymentSuccess) {
      // Il pagamento è completato, mostra la pagina di successo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message), // ✅ StripePaymentSuccess HA message
          backgroundColor: AppColors.success,
        ),
      );
    } else if (state is StripeErrorState) {
      // Errore nel pagamento
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message), // ✅ StripeErrorState HA message
          backgroundColor: AppColors.error,
        ),
      );
    }
    // 🔧 FIX: Non tentare di accedere a .message per altri tipi di stato
  }
}