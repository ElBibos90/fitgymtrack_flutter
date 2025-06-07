// lib/features/payments/presentation/widgets/stripe_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/config/stripe_config.dart';
import '../../bloc/stripe_bloc.dart';
import '../../models/stripe_models.dart';

/// Widget per mostrare i piani di abbonamento con Stripe
class StripePricingCard extends StatelessWidget {
  final String planName;
  final String description;
  final double price;
  final String interval;
  final List<String> features;
  final bool isPopular;
  final bool isCurrentPlan;
  final VoidCallback? onSubscribe;

  const StripePricingCard({
    super.key,
    required this.planName,
    required this.description,
    required this.price,
    required this.interval,
    required this.features,
    this.isPopular = false,
    this.isCurrentPlan = false,
    this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isPopular
              ? (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600)
              : (isDarkMode ? Colors.grey[700]! : AppColors.border),
          width: isPopular ? 2 : 1,
        ),
        gradient: isPopular
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.indigo600.withOpacity(0.1),
            AppColors.indigo700.withOpacity(0.05),
          ],
        )
            : null,
      ),
      child: Card(
        elevation: isPopular ? 8 : 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con badge popolare
              if (isPopular) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'PIÙ POPOLARE',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],

              // Nome piano
              Text(
                planName,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 8.h),

              // Descrizione
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                ),
              ),

              SizedBox(height: 20.h),

              // Prezzo
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '€${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      '/$interval',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Features
              ...features.map((feature) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20.sp,
                      color: isDarkMode ? const Color(0xFF4CAF50) : AppColors.success,
                    ),
                    SizedBox(width: 12.w),
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

              SizedBox(height: 24.h),

              // Pulsante Subscribe
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: isCurrentPlan ? null : onSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular
                        ? (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600)
                        : (isDarkMode ? Colors.grey[700] : AppColors.textSecondary),
                    foregroundColor: isPopular
                        ? (isDarkMode ? Colors.black : Colors.white)
                        : Colors.white,
                    disabledBackgroundColor: isDarkMode
                        ? Colors.grey[800]
                        : AppColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    isCurrentPlan
                        ? 'Piano attuale'
                        : 'Sottoscrivi ora',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Badge piano corrente
              if (isCurrentPlan) ...[
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Il tuo piano attuale',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget per mostrare lo stato del pagamento
class StripePaymentStatusWidget extends StatelessWidget {
  final StripeState state;

  const StripePaymentStatusWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (state is StripePaymentLoading) {
      final loadingState = state as StripePaymentLoading;
      return _buildLoadingWidget(context, loadingState, isDarkMode);
    }

    if (state is StripePaymentSuccess) {
      final successState = state as StripePaymentSuccess;
      return _buildSuccessWidget(context, successState, isDarkMode);
    }

    if (state is StripeErrorState) {
      final errorState = state as StripeErrorState;
      return _buildErrorWidget(context, errorState, isDarkMode);
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingWidget(BuildContext context, StripePaymentLoading state, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : AppColors.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            state.message ?? 'Elaborazione pagamento...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Per favore attendi, non chiudere l\'app',
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

  Widget _buildSuccessWidget(BuildContext context, StripePaymentSuccess state, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.success),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 32.sp,
              color: AppColors.success,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Pagamento completato!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continua'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, StripeErrorState state, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 32.sp,
              color: AppColors.error,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Pagamento fallito',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            state.stripeError?.userFriendlyMessage ?? state.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                    side: BorderSide(
                      color: isDarkMode ? Colors.grey[700]! : AppColors.border,
                    ),
                  ),
                  child: const Text('Annulla'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    // Potresti voler rilanciare il pagamento qui
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                  ),
                  child: const Text('Riprova'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget per mostrare i metodi di pagamento salvati
class StripePaymentMethodCard extends StatelessWidget {
  final StripePaymentMethod paymentMethod;
  final VoidCallback? onDelete;
  final bool isLoading;

  const StripePaymentMethodCard({
    super.key,
    required this.paymentMethod,
    this.onDelete,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final card = paymentMethod.card;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      color: isDarkMode ? AppColors.surfaceDark : Colors.white,
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 28.h,
          decoration: BoxDecoration(
            color: _getBrandColor(card?.brand ?? ''),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Center(
            child: Text(
              _getBrandDisplayName(card?.brand ?? ''),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Text(
          card?.maskedNumber ?? '**** **** **** ****',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Scade ${card?.formattedExpiry ?? '??/??'}',
          style: TextStyle(
            fontSize: 14.sp,
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        trailing: isLoading
            ? SizedBox(
          width: 20.w,
          height: 20.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
            ),
          ),
        )
            : IconButton(
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }

  Color _getBrandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return const Color(0xFF1A1F71);
      case 'mastercard':
        return const Color(0xFFEB001B);
      case 'amex':
      case 'american_express':
        return const Color(0xFF006FCF);
      default:
        return Colors.grey;
    }
  }

  String _getBrandDisplayName(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return 'VISA';
      case 'mastercard':
        return 'MC';
      case 'amex':
      case 'american_express':
        return 'AMEX';
      default:
        return brand.toUpperCase();
    }
  }
}

/// Widget per mostrare le informazioni della subscription Stripe
class StripeSubscriptionInfoCard extends StatelessWidget {
  final StripeSubscription subscription;
  final VoidCallback? onCancel;
  final VoidCallback? onReactivate;

  const StripeSubscriptionInfoCard({
    super.key,
    required this.subscription,
    this.onCancel,
    this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      color: isDarkMode ? AppColors.surfaceDark : Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.indigo600.withOpacity(0.1),
              AppColors.indigo700.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(subscription.status).withOpacity(0.2),
                    ),
                    child: Icon(
                      _getStatusIcon(subscription.status),
                      color: _getStatusColor(subscription.status),
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Abbonamento Premium',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _getStatusText(subscription.status),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: _getStatusColor(subscription.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Date info
              _buildInfoRow(
                context,
                'Periodo corrente',
                '${_formatDate(subscription.currentPeriodStartDate)} - ${_formatDate(subscription.currentPeriodEndDate)}',
                isDarkMode,
              ),

              SizedBox(height: 12.h),

              _buildInfoRow(
                context,
                'Giorni rimanenti',
                '${subscription.daysRemaining} giorni',
                isDarkMode,
              ),

              SizedBox(height: 12.h),

              _buildInfoRow(
                context,
                'Rinnovo automatico',
                subscription.cancelAtPeriodEnd ? 'Disattivato' : 'Attivo',
                isDarkMode,
              ),

              SizedBox(height: 20.h),

              // Actions
              if (subscription.isActive) ...[
                if (subscription.cancelAtPeriodEnd) ...[
                  // Subscription cancellata ma ancora attiva
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onReactivate,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Riattiva abbonamento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else ...[
                  // Subscription attiva
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancella abbonamento'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: BorderSide(color: AppColors.warning),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'past_due':
        return AppColors.warning;
      case 'canceled':
      case 'cancelled':
        return AppColors.error;
      case 'incomplete':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'past_due':
        return Icons.warning;
      case 'canceled':
      case 'cancelled':
        return Icons.cancel;
      case 'incomplete':
        return Icons.pending;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Attivo';
      case 'past_due':
        return 'Pagamento in ritardo';
      case 'canceled':
      case 'cancelled':
        return 'Cancellato';
      case 'incomplete':
        return 'Incompleto';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}