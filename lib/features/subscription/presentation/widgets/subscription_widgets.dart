// lib/features/subscription/presentation/widgets/subscription_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../models/subscription_models.dart';

/// Card che mostra l'abbonamento corrente
class CurrentSubscriptionCard extends StatelessWidget {
  final Subscription subscription;

  const CurrentSubscriptionCard({
    super.key,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    // 🔧 FIX: Rilevamento tema scuro corretto
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      // 🔧 FIX: Colore card dinamico basato sul tema
      color: isDarkMode
          ? (subscription.isPremium ? AppColors.surfaceDark : const Color(0xFF1A1A1A))
          : (subscription.isPremium ? Colors.white : const Color(0xFFF8FAFC)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: subscription.isPremium
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
              AppColors.indigo600.withOpacity(0.3),
              AppColors.indigo700.withOpacity(0.2),
            ]
                : [
              AppColors.indigo600,
              AppColors.indigo700,
            ],
          )
              : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
              const Color(0xFF2A2A2A),
              const Color(0xFF1F1F1F),
            ]
                : [
              const Color(0xFFF8FAFC),
              const Color(0xFFF1F5F9),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isDarkMode),
              SizedBox(height: 20.h),
              _buildUsageSection(context, isDarkMode),
              SizedBox(height: 16.h),
              _buildFeaturesSection(context, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    // 🔧 FIX: Colori testo dinamici
    final textColor = subscription.isPremium
        ? Colors.white
        : (isDarkMode ? Colors.white : AppColors.textPrimary);

    return Row(
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: subscription.isPremium
                ? Colors.white.withOpacity(0.2)
                : (isDarkMode
                ? AppColors.indigo600.withOpacity(0.8)
                : AppColors.indigo600),
          ),
          child: Icon(
            subscription.isPremium ? Icons.star : Icons.star_border,
            color: Colors.white,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Piano ${subscription.planName}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subscription.formattedPrice,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: textColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        if (subscription.isExpiring)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Scade tra ${subscription.daysRemaining} giorni',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUsageSection(BuildContext context, bool isDarkMode) {
    final textColor = subscription.isPremium
        ? Colors.white
        : (isDarkMode ? Colors.white : AppColors.textPrimary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Utilizzo attuale',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        SizedBox(height: 12.h),
        _buildUsageItem(
          context,
          'Schede di allenamento',
          subscription.workoutsLimitText,
          subscription.workoutsProgress,
          isDarkMode,
        ),
        SizedBox(height: 8.h),
        _buildUsageItem(
          context,
          'Esercizi personalizzati',
          subscription.customExercisesLimitText,
          subscription.customExercisesProgress,
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildUsageItem(BuildContext context, String label, String value, double progress, bool isDarkMode) {
    final textColor = subscription.isPremium
        ? Colors.white
        : (isDarkMode ? Colors.white : AppColors.textPrimary);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: textColor.withOpacity(0.9),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: subscription.isPremium
              ? Colors.white.withOpacity(0.3)
              : (isDarkMode
              ? Colors.grey.withOpacity(0.3)
              : AppColors.border),
          valueColor: AlwaysStoppedAnimation<Color>(
            subscription.isPremium
                ? Colors.white
                : (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context, bool isDarkMode) {
    final textColor = subscription.isPremium
        ? Colors.white
        : (isDarkMode ? Colors.white : AppColors.textPrimary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Il tuo piano non include:',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        SizedBox(height: 8.h),
        _buildFeatureItem('Statistiche avanzate', subscription.advancedStats, isDarkMode),
        _buildFeatureItem('Backup cloud', subscription.cloudBackup, isDarkMode),
        _buildFeatureItem('Nessuna pubblicità', subscription.noAds, isDarkMode),
      ],
    );
  }

  Widget _buildFeatureItem(String feature, bool included, bool isDarkMode) {
    final textColor = subscription.isPremium
        ? Colors.white
        : (isDarkMode ? Colors.white : AppColors.textPrimary);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle : Icons.cancel,
            size: 16.sp,
            color: included
                ? (subscription.isPremium
                ? Colors.white
                : (isDarkMode ? const Color(0xFF4CAF50) : AppColors.success))
                : (subscription.isPremium
                ? Colors.white.withOpacity(0.5)
                : (isDarkMode ? Colors.grey : AppColors.textHint)),
          ),
          SizedBox(width: 8.w),
          Text(
            feature,
            style: TextStyle(
              fontSize: 14.sp,
              color: included
                  ? textColor
                  : textColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card per un piano di abbonamento disponibile
class SubscriptionPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrentPlan;
  final VoidCallback? onSubscribe;
  final bool isLoading;

  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    this.isCurrentPlan = false,
    this.onSubscribe,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = plan.price > 0;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isPremium ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: isPremium
            ? BorderSide(
          color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
          width: 2,
        )
            : BorderSide.none,
      ),
      // 🔧 FIX: Colore card dinamico
      color: isDarkMode
          ? (isPremium ? AppColors.surfaceDark : const Color(0xFF1A1A1A))
          : (isPremium ? Colors.white : const Color(0xFFF8FAFC)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: isPremium
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
              AppColors.indigo600.withOpacity(0.2),
              AppColors.indigo700.withOpacity(0.1),
            ]
                : [
              AppColors.indigo600.withOpacity(0.1),
              AppColors.indigo700.withOpacity(0.05),
            ],
          )
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlanHeader(context, isPremium, isDarkMode),
              SizedBox(height: 16.h),
              _buildFeaturesList(context, isDarkMode),
              SizedBox(height: 20.h),
              _buildSubscribeButton(context, isPremium, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanHeader(BuildContext context, bool isPremium, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (isPremium) ...[
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.star,
                    color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
                    size: 20.sp,
                  ),
                ],
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              plan.formattedPrice,
              style: TextStyle(
                fontSize: 16.sp,
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (isCurrentPlan)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Text(
              'ATTUALE',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturesList(BuildContext context, bool isDarkMode) {
    return Column(
      children: plan.features.map((feature) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 3.h),
          child: Row(
            children: [
              Icon(
                feature.isIncluded ? Icons.check_circle : Icons.cancel,
                size: 18.sp,
                color: feature.isIncluded
                    ? (isDarkMode ? const Color(0xFF4CAF50) : AppColors.success)
                    : (isDarkMode ? Colors.grey : AppColors.textHint),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  feature.displayText,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: feature.isIncluded
                        ? (isDarkMode ? Colors.white : AppColors.textPrimary)
                        : (isDarkMode ? Colors.grey : AppColors.textHint),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubscribeButton(BuildContext context, bool isPremium, bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: isCurrentPlan ? null : onSubscribe,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPremium
              ? (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600)
              : (isDarkMode ? Colors.grey[700] : AppColors.textSecondary),
          foregroundColor: isPremium
              ? (isDarkMode ? Colors.black : Colors.white)
              : Colors.white,
          disabledBackgroundColor: isDarkMode
              ? Colors.grey[800]
              : AppColors.border,
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
              isPremium
                  ? (isDarkMode ? Colors.black : Colors.white)
                  : Colors.white,
            ),
          ),
        )
            : Text(
          isCurrentPlan
              ? 'Piano attuale'
              : isPremium
              ? 'Abbonati ora'
              : 'Passa a Free',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Banner per notificare che l'abbonamento è scaduto
class SubscriptionExpiredBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onUpgrade;

  const SubscriptionExpiredBanner({
    super.key,
    required this.onDismiss,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.error.withOpacity(0.2)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: AppColors.error,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Abbonamento Scaduto',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(
                  Icons.close,
                  color: AppColors.error,
                  size: 20.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Il tuo abbonamento Premium è scaduto. Sei stato automaticamente riportato al piano Free con funzionalità limitate.',
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDismiss,
                child: Text(
                  'Ho capito',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              ElevatedButton(
                onPressed: onUpgrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? const Color(0xFF90CAF9)
                      : AppColors.indigo600,
                  foregroundColor: isDarkMode ? Colors.black : Colors.white,
                ),
                child: const Text('Rinnova ora'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Banner per notificare che è stato raggiunto il limite
class SubscriptionLimitBanner extends StatelessWidget {
  final String resourceType;
  final int currentCount;
  final int maxAllowed;
  final VoidCallback onDismiss;
  final VoidCallback onUpgrade;

  const SubscriptionLimitBanner({
    super.key,
    required this.resourceType,
    required this.currentCount,
    required this.maxAllowed,
    required this.onDismiss,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.warning.withOpacity(0.2)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.warning,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Limite Raggiunto',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(
                  Icons.close,
                  color: AppColors.warning,
                  size: 20.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            _getLimitMessage(),
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDismiss,
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              ElevatedButton(
                onPressed: onUpgrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? const Color(0xFF90CAF9)
                      : AppColors.indigo600,
                  foregroundColor: isDarkMode ? Colors.black : Colors.white,
                ),
                child: const Text('Passa a Premium'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLimitMessage() {
    switch (resourceType) {
      case 'max_workouts':
        return 'Hai raggiunto il limite di $maxAllowed schede di allenamento disponibili con il piano Free. Passa al piano Premium per avere schede illimitate.';
      case 'max_custom_exercises':
        return 'Hai raggiunto il limite di $maxAllowed esercizi personalizzati disponibili con il piano Free. Passa al piano Premium per avere esercizi illimitati.';
      default:
        return 'Hai raggiunto un limite del tuo piano corrente. Passa al piano Premium per sbloccare funzionalità illimitate.';
    }
  }
}

/// Widget per mostrare gli errori
class SubscriptionErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const SubscriptionErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
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
              'Errore',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? const Color(0xFF90CAF9)
                      : AppColors.indigo600,
                  foregroundColor: isDarkMode ? Colors.black : Colors.white,
                ),
                child: const Text('Riprova'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget di loading per le subscription
class SubscriptionLoadingWidget extends StatelessWidget {
  const SubscriptionLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Caricamento abbonamento...',
            style: TextStyle(
              fontSize: 16.sp,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}