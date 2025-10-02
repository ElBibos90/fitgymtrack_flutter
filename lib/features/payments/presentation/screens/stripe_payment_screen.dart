// lib/features/payments/presentation/screens/stripe_payment_screen.dart - 🔧 FIX OVERLAY DONAZIONI

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

// Theme imports
import '../../../../shared/theme/app_colors.dart';

// Feature imports
import '../../bloc/stripe_bloc.dart';
import '../../models/stripe_models.dart';
import '../widgets/stripe_widgets.dart';
import '../../../../shared/widgets/loading_overlay.dart';

/// 🚀 StripePaymentScreen - FIXED: Overlay cleanup for donations
/// 🔧 FIX: Risolve il problema dell'overlay "nebbia" dopo donazioni
class StripePaymentScreen extends StatefulWidget {
  final String paymentType;

  const StripePaymentScreen({
    super.key,
    required this.paymentType,
  });

  @override
  State<StripePaymentScreen> createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends State<StripePaymentScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  // 🔧 FIX: Stati per gestire overlay e cleanup
  bool _isPaymentProcessing = false;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    //print('[CONSOLE][stripe_payment_screen]🔧 [PAYMENT] Screen initialized for ${widget.paymentType}');
  }

  @override
  void dispose() {
    // 🔧 FIX: Rimuovi overlay se la schermata viene smontata
    _isPaymentProcessing = false;
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return LoadingOverlay(
      isLoading: _isPaymentProcessing,
      message: 'Elaborazione pagamento...',
      child: Scaffold(
        backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
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
          // 🔧 FIX: Listener corretto per gestire overlay
          listener: (context, state) {
            _handleStripeStateChanges(context, state);
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
      ),
    );
  }

  // ============================================================================
  // 🔧 FIX: STRIPE STATE MANAGEMENT - Gestione corretta degli stati
  // ============================================================================

  void _handleStripeStateChanges(BuildContext context, StripeState state) {
    //print('[CONSOLE][stripe_payment_screen]🔧 [PAYMENT] State changed: ${state.runtimeType}');

    if (state is StripePaymentLoading) {
      // 🔧 FIX: Attiva overlay quando inizia il processing
      //print('[CONSOLE][stripe_payment_screen]🔧 [PAYMENT] Loading state - showing overlay');
      setState(() {
        _isPaymentProcessing = true;
        _paymentCompleted = false;
      });

    } else if (state is StripePaymentReady) {
      // 🔧 FIX: Gestione automatica per donazioni
      //print('[CONSOLE][stripe_payment_screen]🔧 [PAYMENT] Payment Ready - processing automatically for ${state.paymentType}');

      // Per le donazioni, processa automaticamente il payment
      if (state.paymentType == 'donation') {
        // Presenta automaticamente il payment sheet
        context.read<StripeBloc>().add(ProcessPaymentEvent(
          clientSecret: state.paymentIntent.clientSecret,
          paymentType: state.paymentType,
        ));
      } else {
        // Per le subscription, naviga alla pagina di pagamento
        _pageController.animateToPage(
          1, // Pagina di pagamento
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }

    } else if (state is StripePaymentSuccess) {
      //print('[CONSOLE][DEBUG] Payment success, removing overlay e forzando pagina 2');
      setState(() {
        _isPaymentProcessing = false;
        _paymentCompleted = true;
        _currentPage = 2;
      });
      _pageController.jumpToPage(2);

      // Forza un ulteriore rebuild dopo 100ms
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          //print('[CONSOLE][DEBUG] Forzo setState dopo 100ms');
          setState(() {
            _isPaymentProcessing = false;
            _currentPage = 2;
          });
        }
      });

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

      if (widget.paymentType == 'donation') {
        Future.delayed(const Duration(seconds: 3), () {
          if (context.mounted) {
            //print('[CONSOLE][DEBUG] Forzo jumpToPage(2) e setState nella delayed close');
            _pageController.jumpToPage(2);
            setState(() {
              _isPaymentProcessing = false;
              _currentPage = 2;
            });
            Navigator.of(context).pop();
          }
        });
      }

    } else if (state is StripeErrorState) {
      // 🔧 FIX: Cleanup overlay anche in caso di errore
      //print('[CONSOLE][stripe_payment_screen]🔧 [PAYMENT] Error state: ${state.message}');
      setState(() {
        _isPaymentProcessing = false; // Rimuovi overlay
        _paymentCompleted = false;    // Non completato
      });

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
      // 🔧 FIX: Per qualsiasi altro stato, assicurati che l'overlay sia rimosso
      if (_isPaymentProcessing && !_paymentCompleted) {
        //print('[CONSOLE][stripe_payment_screen]🔧 [PAYMENT] Unknown state, cleaning up overlay');
        setState(() {
          _isPaymentProcessing = false;
        });
      }
    }
  }

  // ============================================================================
  // PAYMENT ACTIONS
  // ============================================================================

  void _startDonationPayment(double amount) {
    //print('[CONSOLE][stripe_payment_screen]🔧 [PAYMENT] Starting donation payment: €$amount');

    final amountInCents = (amount * 100).round();

    context.read<StripeBloc>().add(CreateDonationPaymentEvent(
      amount: amountInCents,
      metadata: {
        'source': 'donation_screen',
        'amount_euros': amount.toString(),
      },
    ));

    // Vai alla pagina di caricamento
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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

  // ============================================================================
  // UI BUILDERS
  // ============================================================================

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
          Expanded(
            child: Row(
              children: [
                _buildStepIndicator(0, 'Selezione', _currentPage >= 0, isDarkMode),
                _buildStepConnector(isDarkMode),
                _buildStepIndicator(1, 'Pagamento', _currentPage >= 1, isDarkMode),
                _buildStepConnector(isDarkMode),
                _buildStepIndicator(2, 'Completato', _currentPage >= 2, isDarkMode),
              ],
            ),
          ),
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
            color: isActive
                ? (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600)
                : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : (isDarkMode ? Colors.white54 : Colors.grey[600]),
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isActive
                ? (isDarkMode ? Colors.white : AppColors.textPrimary)
                : (isDarkMode ? Colors.white54 : Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isDarkMode) {
    return Expanded(
      child: Container(
        height: 2.h,
        margin: EdgeInsets.only(bottom: 20.h),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          borderRadius: BorderRadius.circular(1.r),
        ),
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
            'Piano Premium',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Sblocca tutte le funzionalità avanzate',
            style: TextStyle(
              fontSize: 16.sp,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
          ),

          SizedBox(height: 32.h),

          // Premium features
          _buildFeaturesList(isDarkMode),

          const Spacer(),

          // Pricing
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
              children: [
                Text(
                  '€4.99/mese',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Cancella in qualsiasi momento',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: state is StripePaymentLoading ? null : () => _startSubscriptionPayment(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                foregroundColor: isDarkMode ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: state is StripePaymentLoading
                  ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode ? Colors.black : Colors.white,
                  ),
                ),
              )
                  : Text(
                'Inizia abbonamento Premium',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
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
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Aiutaci a migliorare l\'app che ami',
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
              _buildDonationButton(context, 2.99, isDarkMode, state),
              _buildDonationButton(context, 4.99, isDarkMode, state),
              _buildDonationButton(context, 9.99, isDarkMode, state),
              _buildDonationButton(context, 19.99, isDarkMode, state),
              _buildDonationButton(context, 49.99, isDarkMode, state),
              _buildCustomDonationButton(context, isDarkMode, state),
            ],
          ),

          const Spacer(),

          // Sezione sicurezza
          _buildSecuritySection(context, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(bool isDarkMode) {
    final features = [
      'Schede di allenamento illimitate',
      'Esercizi personalizzati',
      'Statistiche avanzate e analytics',
      'Backup automatico nel cloud',
      'Supporto prioritario',
      'Nuove funzionalità in anteprima',
    ];

    return Column(
      children: features.map((feature) => Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                feature,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildDonationButton(BuildContext context, double amount, bool isDarkMode, StripeState state) {
    final isLoading = state is StripePaymentLoading;

    return ElevatedButton(
      onPressed: isLoading ? null : () => _startDonationPayment(amount),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        foregroundColor: isDarkMode ? Colors.white : AppColors.textPrimary,
        disabledBackgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: isDarkMode ? Colors.grey[600]! : AppColors.border,
          ),
        ),
      ),
      child: isLoading
          ? SizedBox(
        width: 16.w,
        height: 16.w,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
      )
          : Text(
        '€${amount.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCustomDonationButton(BuildContext context, bool isDarkMode, StripeState state) {
    final isLoading = state is StripePaymentLoading;

    return OutlinedButton(
      onPressed: isLoading ? null : () => _showCustomDonationDialog(context),
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
    // 🔧 FIX: RIMOSSO overlay di loading come pagina del PageView
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

            // 🔧 FIX: Per le donazioni, mostra che il payment si apre automaticamente
            if (widget.paymentType == 'donation') ...[
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
            ] else ...[
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

  Widget _buildSecuritySection(BuildContext context, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark.withValues(alpha: 0.5) : AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: isDarkMode ? Colors.green[400] : Colors.green[600],
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Pagamenti sicuri gestiti da Stripe',
              style: TextStyle(
                fontSize: 12.sp,
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // DIALOGS
  // ============================================================================

  void _startSubscriptionPayment() {
    //print('[CONSOLE][stripe_payment_screen]🔧 [PAYMENT] Starting subscription payment');

    // Usa il vero priceId dal config
    const premiumPriceId = 'price_1RXVOfHHtQGHyul9qMGFmpmO'; // Real price ID dal config

    context.read<StripeBloc>().add(CreateSubscriptionPaymentEvent(
      priceId: premiumPriceId,
      metadata: {
        'source': 'payment_screen',
        'plan': 'premium_monthly',
      },
    ));

    // Vai alla pagina di caricamento
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
}