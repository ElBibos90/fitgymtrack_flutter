// lib/features/subscription/presentation/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/config/stripe_config.dart';
import '../../../payments/bloc/stripe_bloc.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    // 🔧 FIX: Forza inizializzazione Stripe se necessario
    _initializeStripeAndSubscription();
  }

  /// 🔧 Inizializza Stripe e carica subscription
  Future<void> _initializeStripeAndSubscription() async {
    final stripeBloc = context.read<StripeBloc>();

    // Se Stripe non è pronto, inizializzalo
    if (stripeBloc.state is! StripeReady) {
      print('[CONSOLE]🔧 [SUBSCRIPTION] Stripe not ready, initializing...');
      stripeBloc.add(const InitializeStripeEvent());

      // Aspetta un po' per l'inizializzazione
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Carica sempre la subscription corrente
    stripeBloc.add(const LoadCurrentSubscriptionEvent());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: BlocConsumer<StripeBloc, StripeState>(
        listener: (context, state) {
          print('[CONSOLE]🔧 [SUBSCRIPTION] Stripe state changed: ${state.runtimeType}');

          if (state is StripePaymentReady) {
            print('[CONSOLE]🔧 [SUBSCRIPTION] Payment Ready - opening Payment Sheet');
            // 🔧 FIX: Apri Payment Sheet direttamente quando pronto
            _presentPaymentSheet(context, state);
          } else if (state is StripePaymentSuccess) {
            print('[CONSOLE]🔧 [SUBSCRIPTION] Payment Success');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            // 🔧 Ricarica subscription dopo successo
            context.read<StripeBloc>().add(const LoadCurrentSubscriptionEvent());
          } else if (state is StripeErrorState) {
            print('[CONSOLE]🔧 [SUBSCRIPTION] Stripe Error: ${state.message}');
            print('[CONSOLE]🔧 [SUBSCRIPTION] Error code: ${state.errorCode}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          } else if (state is StripePaymentLoading) {
            print('[CONSOLE]🔧 [SUBSCRIPTION] Payment Loading: ${state.message}');
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // 🎨 MODERN APP BAR
              SliverAppBar(
                expandedHeight: 120.h,
                floating: true,
                pinned: true,
                backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
                automaticallyImplyLeading: false, // Remove back button for tab navigation
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
                actions: [
                  // Status indicator
                  Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: _buildStripeStatusIndicator(state, isDarkMode),
                  ),
                ],
              ),

              // 🎨 CONTENT
              SliverPadding(
                padding: EdgeInsets.all(16.w),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 💳 Stripe Status Banner
                    _buildStripeStatusBanner(state, isDarkMode),

                    SizedBox(height: 24.h),

                    // 🔧 Payment Loading Overlay quando necessario
                    if (state is StripePaymentLoading)
                      _buildPaymentLoadingOverlay(state, isDarkMode),

                    // 📊 Current Plan Card
                    _buildCurrentPlanCard(state, isDarkMode),

                    SizedBox(height: 32.h),

                    // 🚀 Available Plans
                    _buildAvailablePlansSection(state, isDarkMode),

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

  /// 🔧 Payment Loading Overlay
  Widget _buildPaymentLoadingOverlay(StripePaymentLoading state, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
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

  Widget _buildStripeStatusIndicator(StripeState state, bool isDarkMode) {
    IconData icon;
    Color color;

    if (state is StripeReady) {
      icon = Icons.check_circle;
      color = AppColors.success;
    } else if (state is StripeErrorState) {
      icon = Icons.warning_amber_rounded;
      color = AppColors.warning;
    } else if (state is StripeInitializing) {
      icon = Icons.sync;
      color = AppColors.info;
    } else {
      icon = Icons.payment;
      color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 20.sp,
      ),
    );
  }

  Widget _buildStripeStatusBanner(StripeState state, bool isDarkMode) {
    if (state is StripeInitializing) {
      // Stripe si sta inizializzando
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.info.withOpacity(0.2) : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.info.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inizializzazione Stripe',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Connessione al sistema di pagamento in corso...',
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
    } else if (state is! StripeReady) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.orange.shade900.withOpacity(0.3) : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.warning.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.warning,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modalità Offline',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'I pagamenti non sono disponibili. L\'app funziona in modalità limitata.',
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

    // Stripe Ready - Show success banner
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.success.withOpacity(0.1) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: AppColors.success,
              size: 16.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modalità Stripe',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Pagamenti reali tramite Stripe (modalità test)',
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

  Widget _buildCurrentPlanCard(StripeState state, bool isDarkMode) {
    // Determine current plan
    bool hasPremium = false;
    String planName = 'Piano Free';
    String planDescription = 'Gratuito';
    List<String> limitations = [
      'Schede di allenamento (max 3)',
      'Esercizi personalizzati (max 5)',
    ];

    if (state is StripeReady && state.subscription != null) {
      hasPremium = state.subscription!.isActive;
      if (hasPremium) {
        planName = 'Piano Premium';
        planDescription = 'Attivo';
        limitations = ['Accesso completo a tutte le funzionalità'];
      }
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
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: hasPremium
                      ? Colors.white.withOpacity(0.2)
                      : (isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50),
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
                            ? Colors.white.withOpacity(0.9)
                            : (isDarkMode ? Colors.white70 : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasPremium)
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

          SizedBox(height: 16.h),

          Text(
            hasPremium ? 'Utilizzo attuale' : 'Il tuo piano non include:',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: hasPremium ? Colors.white : (isDarkMode ? Colors.white : AppColors.textPrimary),
            ),
          ),

          SizedBox(height: 12.h),

          ...limitations.map((limitation) => Padding(
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
                    limitation,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: hasPremium
                          ? Colors.white.withOpacity(0.9)
                          : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ),
                ),
              ],
            ),
          )),

          if (!hasPremium) ...[
            SizedBox(height: 8.h),

            // Progress bars
            _buildUsageIndicator('Schede di allenamento', 2, 3, isDarkMode),
            SizedBox(height: 8.h),
            _buildUsageIndicator('Esercizi personalizzati', 3, 5, isDarkMode),
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

  Widget _buildAvailablePlansSection(StripeState state, bool isDarkMode) {
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
          name: 'Free',
          price: 'Gratuito',
          description: 'Per iniziare',
          features: [
            'Schede di allenamento (max 3)',
            'Esercizi personalizzati (max 5)',
          ],
          isActive: true,
          isDarkMode: isDarkMode,
          onTap: null, // Already active
        ),

        SizedBox(height: 16.h),

        // Premium Plan
        if (state is StripeReady) ...[
          _buildPlanCard(
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
            isActive: false,
            isPremium: true,
            isDarkMode: isDarkMode,
            // 🔧 FIX: Disabilita durante payment loading
            isDisabled: state is StripePaymentLoading,
            onTap: state is StripePaymentLoading
                ? null
                : () => _startSubscriptionPayment('premium_monthly'),
          ),
        ] else if (state is StripeInitializing) ...[
          // Stripe si sta inizializzando
          _buildPlanCard(
            name: 'Premium',
            price: '€4.99/mese',
            description: 'Inizializzazione...',
            features: [
              'Connessione al sistema di pagamento in corso...',
              'Attendere qualche secondo',
            ],
            isActive: false,
            isPremium: true,
            isDarkMode: isDarkMode,
            isDisabled: true,
            onTap: null,
          ),
        ] else if (state is StripePaymentLoading) ...[
          // Show Premium plan as loading during payment creation
          _buildPlanCard(
            name: 'Premium',
            price: '€4.99/mese',
            description: 'Preparazione pagamento...',
            features: [
              'Sto creando il pagamento sicuro tramite Stripe...',
            ],
            isActive: false,
            isPremium: true,
            isDarkMode: isDarkMode,
            isDisabled: true,
            onTap: null,
          ),
        ] else ...[
          // Disabled premium plan when Stripe not ready (error state)
          _buildPlanCard(
            name: 'Premium',
            price: '€4.99/mese',
            description: 'Non disponibile',
            features: [
              'Pagamenti non disponibili in modalità offline',
              'Verifica la connessione internet',
            ],
            isActive: false,
            isDisabled: true,
            isDarkMode: isDarkMode,
            onTap: () {
              // 🔧 Retry Stripe initialization
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tentativo di riconnessione...'),
                  backgroundColor: AppColors.info,
                ),
              );
              context.read<StripeBloc>().add(const InitializeStripeEvent());
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPlanCard({
    required String name,
    required String price,
    required String description,
    required List<String> features,
    required bool isActive,
    required bool isDarkMode,
    bool isPremium = false,
    bool isDisabled = false,
    VoidCallback? onTap,
  }) {
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
                        isDisabled ? Icons.block : Icons.check_circle_outline,
                        size: 16.sp,
                        color: isDisabled
                            ? Colors.grey
                            : (isDarkMode ? Colors.green.shade400 : AppColors.success),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDisabled
                                ? Colors.grey
                                : (isDarkMode ? Colors.white : AppColors.textPrimary),
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
                          ? Colors.grey
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
                      isActive
                          ? 'ATTUALE'
                          : isDisabled
                          ? 'NON DISPONIBILE'
                          : 'SOTTOSCRIVI',
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

    print('[CONSOLE]🔧 [SUBSCRIPTION] Starting payment for plan: $planId');
    print('[CONSOLE]🔧 [SUBSCRIPTION] Price ID: $priceId');
    print('[CONSOLE]🔧 [SUBSCRIPTION] Current Stripe state: ${context.read<StripeBloc>().state.runtimeType}');

    // 🔧 FIX: Solo crea Payment Intent, NON navigare
    context.read<StripeBloc>().add(CreateSubscriptionPaymentEvent(
      priceId: priceId,
      metadata: {
        'plan_id': planId,
        'user_platform': 'flutter',
        'source': 'subscription_screen',
      },
    ));

    print('[CONSOLE]🔧 [SUBSCRIPTION] CreateSubscriptionPaymentEvent sent');
    // 🔧 Il Payment Sheet si aprirà automaticamente nel listener quando pronto
  }

  /// 🔧 FIX: Presenta Payment Sheet direttamente
  Future<void> _presentPaymentSheet(BuildContext context, StripePaymentReady state) async {
    try {
      // Mostra loading snackbar
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

      // Presenta Payment Sheet
      context.read<StripeBloc>().add(ProcessPaymentEvent(
        clientSecret: state.paymentIntent.clientSecret,
        paymentType: state.paymentType,
      ));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore apertura pagamento: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}