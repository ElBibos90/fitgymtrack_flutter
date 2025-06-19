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

  @override
  void initState() {
    super.initState();
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
      body: MultiBlocListener(
        listeners: [
          // Listener per StripeBloc
          BlocListener<StripeBloc, StripeState>(
            listener: (context, state) {
              if (state is StripePaymentReady) {
                _presentPaymentSheet(context, state);
              } else if (state is StripePaymentSuccess) {
                _handlePaymentSuccess(context, state);
              } else if (state is StripeErrorState) {
                _handlePaymentError(context, state);
              } else if (state is StripePaymentLoading) {
                setState(() {
                  _isProcessingPayment = true;
                });
              } else {
                setState(() {
                  _isProcessingPayment = false;
                });
              }
            },
          ),
          // Listener per SubscriptionBloc
          BlocListener<SubscriptionBloc, SubscriptionState>(
            listener: (context, state) {
              if (state is SubscriptionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
          builder: (context, state) {
            if (state is SubscriptionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SubscriptionError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64.sp,
                      color: AppColors.error,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Errore nel caricamento',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      state.message,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () {
                        context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent());
                      },
                      child: const Text('Riprova'),
                    ),
                  ],
                ),
              );
            }

            return _buildSubscriptionContent(context, state, isDarkMode);
          },
        ),
      ),
    );
  }

  Widget _buildSubscriptionContent(BuildContext context, SubscriptionState state, bool isDarkMode) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🆕 NUOVA SEZIONE: Selezione tipo pagamento
          _buildPaymentTypeSelection(isDarkMode),

          SizedBox(height: 24.h),

          // Sezione Piano Premium (aggiornata)
          _buildPremiumPlanSection(isDarkMode),

          SizedBox(height: 24.h),

          // Tabella comparativa features (esistente)
          _buildFeaturesComparison(isDarkMode),

          SizedBox(height: 32.h),

          // Bottone subscribe (aggiornato)
          _buildSubscribeButton(state, isDarkMode),

          SizedBox(height: 20.h),

          // Note legali (nuova)
          _buildLegalNotes(isDarkMode),
        ],
      ),
    );
  }

  // 🆕 NUOVA: Sezione per selezione tipo pagamento
  Widget _buildPaymentTypeSelection(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scegli il tuo piano Premium',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 16.h),

          // Card Ricorrente
          _buildPaymentTypeCard(
            paymentType: 'recurring',
            title: 'Ricorrente',
            subtitle: 'Si rinnova automaticamente ogni mese',
            price: '€4.99/mese',
            badge: 'RINNOVO AUTOMATICO',
            badgeColor: Colors.blue,
            features: [
              '✅ Cancella in qualsiasi momento',
              '🔄 Rinnovo automatico',
              '💳 Gestito da Stripe',
            ],
            isDarkMode: isDarkMode,
          ),

          SizedBox(height: 12.h),

          // Card Una Tantum
          _buildPaymentTypeCard(
            paymentType: 'onetime',
            title: 'Una Tantum',
            subtitle: '30 giorni di accesso senza rinnovo',
            price: '€4.99',
            badge: 'NESSUN RINNOVO',
            badgeColor: Colors.green,
            features: [
              '⏰ 30 giorni di accesso',
              '🔒 Nessun rinnovo automatico',
              '💸 Pagamento singolo',
            ],
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeCard({
    required String paymentType,
    required String title,
    required String subtitle,
    required String price,
    required String badge,
    required Color badgeColor,
    required List<String> features,
    required bool isDarkMode,
  }) {
    final isSelected = _selectedPaymentType == paymentType;

    return GestureDetector(
      onTap: () {
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
              ? (isDarkMode ? const Color(0xFF90CAF9).withOpacity(0.1) : AppColors.indigo600)
              : (isDarkMode ? AppColors.backgroundDark : Colors.grey.shade50),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con radio e badge
            Row(
              children: [
                Radio<String>(
                  value: paymentType,
                  groupValue: _selectedPaymentType,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPaymentType = value;
                      });
                    }
                  },
                  activeColor: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: badgeColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.sp,
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
                    color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                  ),
                ),
              ],
            ),

            // Features se selezionato
            if (isSelected) ...[
              SizedBox(height: 12.h),
              ...features.map((feature) => Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  feature,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  // Sezione piano premium aggiornata
  Widget _buildPremiumPlanSection(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 28.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Piano Premium',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          Text(
            'Sblocca tutte le funzionalità avanzate di FitGymTrack e porta i tuoi allenamenti al livello successivo!',
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Tabella features esistente (invariata)
  Widget _buildFeaturesComparison(bool isDarkMode) {
    final features = [
      {'name': 'Schede di allenamento', 'free': 'Limitate', 'premium': 'Illimitate'},
      {'name': 'Esercizi personalizzati', 'free': 'Limitati', 'premium': 'Illimitati'},
      {'name': 'Statistiche avanzate', 'free': '❌', 'premium': '✅'},
      {'name': 'Backup cloud', 'free': '❌', 'premium': '✅'},
      {'name': 'Nessuna pubblicità', 'free': '❌', 'premium': '✅'},
      {'name': 'Supporto prioritario', 'free': '❌', 'premium': '✅'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              border: Border(
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
          )).toList(),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // Bottone subscribe aggiornato
  Widget _buildSubscribeButton(SubscriptionState state, bool isDarkMode) {
    final selectedPlan = StripeConfig.getPlanByPaymentType(_selectedPaymentType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info piano selezionato
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF90CAF9).withOpacity(0.1)
                : AppColors.indigo600,
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
                      selectedPlan.subtitle,
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

        // Bottone principale
        SizedBox(
          width: double.infinity,
          height: 56.h,
          child: ElevatedButton(
            onPressed: _isProcessingPayment ? null : () => _startSubscriptionPayment(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
              foregroundColor: isDarkMode ? AppColors.backgroundDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              elevation: 0,
              disabledBackgroundColor: Colors.grey.shade400,
            ),
            child: _isProcessingPayment
                ? SizedBox(
              width: 24.w,
              height: 24.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? AppColors.backgroundDark : Colors.white,
                ),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.credit_card,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Sottoscrivi Premium ${selectedPlan.formattedPrice}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Note legali
  Widget _buildLegalNotes(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark.withOpacity(0.5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Informazioni importanti',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (_selectedPaymentType == 'recurring') ...[
            Text(
              '• L\'abbonamento si rinnova automaticamente ogni mese\n'
                  '• Puoi cancellare in qualsiasi momento dalle impostazioni\n'
                  '• Dopo la cancellazione, manterrai l\'accesso fino alla fine del periodo pagato\n'
                  '• Nessun costo nascosto o commissioni aggiuntive',
              style: TextStyle(
                fontSize: 11.sp,
                color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ] else ...[
            Text(
              '• Pagamento singolo per 30 giorni di accesso Premium\n'
                  '• Nessun rinnovo automatico - dovrai rinnovare manualmente\n'
                  '• Accesso completo a tutte le funzionalità Premium\n'
                  '• Downgrade automatico a Free dopo 30 giorni',
              style: TextStyle(
                fontSize: 11.sp,
                color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          SizedBox(height: 8.h),
          Text(
            'Pagamenti sicuri elaborati da Stripe. Consulta i nostri Termini di Servizio e Privacy Policy.',
            style: TextStyle(
              fontSize: 10.sp,
              color: isDarkMode ? Colors.white54 : AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 🔧 METODI DI AZIONE (AGGIORNATI)
  // ============================================================================

  void _startSubscriptionPayment() {
    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] User selected payment type: $_selectedPaymentType');

    final selectedPlan = StripeConfig.getPlanByPaymentType(_selectedPaymentType);

    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Selected plan: ${selectedPlan.name}');
    print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Price ID: ${selectedPlan.stripePriceId}');

    // Initialize Stripe if necessary
    _initializeStripeForPayment();

    final stripeBloc = context.read<StripeBloc>();
    final currentState = stripeBloc.state;

    if (currentState is StripeInitial || currentState is StripeInitializing) {
      // Stripe is initializing, wait for it to be ready
      _waitForStripeAndCreatePayment(selectedPlan);
    } else if (currentState is StripeReady) {
      // Stripe is ready, create payment immediately
      _createPaymentIntent(selectedPlan);
    } else {
      // Error state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Errore nel sistema di pagamento. Riprova.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _initializeStripeForPayment() {
    final stripeBloc = context.read<StripeBloc>();
    if (stripeBloc.state is StripeInitial) {
      stripeBloc.add(const InitializeStripeEvent());
    }
  }

  void _waitForStripeAndCreatePayment(SubscriptionPlan plan) {
    final subscription = context.read<StripeBloc>().stream.listen((state) {
      if (state is StripeReady) {
        _createPaymentIntent(plan);
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

  void _createPaymentIntent(SubscriptionPlan plan) {
    context.read<StripeBloc>().add(CreateSubscriptionPaymentEvent(
      priceId: plan.stripePriceId,
      metadata: {
        'plan_id': plan.id,
        'payment_type': plan.paymentType, // 🆕 NUOVO: Passa il tipo di pagamento
        'user_platform': 'flutter',
        'source': 'subscription_screen',
      },
    ));
  }

  Future<void> _presentPaymentSheet(BuildContext context, StripePaymentReady state) async {
    try {
      print('[CONSOLE][subscription_screen]🔧 [SUBSCRIPTION] Presenting Payment Sheet...');

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore apertura pagamento: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handlePaymentSuccess(BuildContext context, StripePaymentSuccess state) {
    setState(() {
      _isProcessingPayment = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(child: Text(state.message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );

    // Reload subscription data
    context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent());

    // Navigate back after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _handlePaymentError(BuildContext context, StripeErrorState state) {
    setState(() {
      _isProcessingPayment = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}