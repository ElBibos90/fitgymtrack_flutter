// lib/features/stats/presentation/widgets/premium_upgrade_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import '../../../../shared/theme/stats_theme.dart';
import 'premium_upgrade_flow.dart';

/// 💎 Premium Upgrade Banner - Banner per Upgrade Premium
class PremiumUpgradeBanner extends StatelessWidget {
  final VoidCallback onUpgrade;
  final String? title;
  final String? description;
  final List<String>? features;

  const PremiumUpgradeBanner({
    super.key,
    required this.onUpgrade,
    this.title,
    this.description,
    this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(StatsTheme.space5),
      decoration: BoxDecoration(
        gradient: StatsTheme.premiumGradient,
        borderRadius: BorderRadius.circular(StatsTheme.radius3),
        boxShadow: [
          BoxShadow(
            color: StatsTheme.warningOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con icona premium
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(StatsTheme.space2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(StatsTheme.radius2),
                ),
                child: Icon(
                  Icons.diamond,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: StatsTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? 'Sblocca Statistiche Premium',
                      style: StatsTheme.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description ?? 'Accedi ad analisi avanzate e insights personalizzati',
                      style: StatsTheme.body2.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: StatsTheme.space4),
          
          // Features list
          if (features != null) ...[
            ...features!.map((feature) => Padding(
              padding: EdgeInsets.only(bottom: StatsTheme.space2),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                  SizedBox(width: StatsTheme.space2),
                  Expanded(
                    child: Text(
                      feature,
                      style: StatsTheme.body2.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            )),
            SizedBox(height: StatsTheme.space4),
          ],
          
          // Upgrade button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => PremiumUpgradeFlow.navigateToUpgrade(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: StatsTheme.warningOrange,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: StatsTheme.space3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(StatsTheme.radius2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star,
                    size: 20.sp,
                  ),
                  SizedBox(width: StatsTheme.space2),
                  Text(
                    'Upgrade a Premium',
                    style: StatsTheme.button.copyWith(
                      color: StatsTheme.warningOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎯 Compact Premium Banner - Versione Compatta
class CompactPremiumBanner extends StatelessWidget {
  final VoidCallback onUpgrade;
  final String? message;

  const CompactPremiumBanner({
    super.key,
    required this.onUpgrade,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(StatsTheme.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            StatsTheme.primaryBlue.withValues(alpha: 0.1),
            StatsTheme.warningOrange.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(StatsTheme.radius3),
        border: Border.all(
          color: StatsTheme.warningOrange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock,
            color: StatsTheme.warningOrange,
            size: 20.sp,
          ),
          SizedBox(width: StatsTheme.space3),
          Expanded(
            child: Text(
              message ?? 'Sblocca questa funzionalità con Premium',
              style: StatsTheme.body2.copyWith(
                color: StatsTheme.getTextPrimary(context),
              ),
            ),
          ),
          TextButton(
            onPressed: onUpgrade,
            child: Text(
              'Upgrade',
              style: StatsTheme.button.copyWith(
                color: StatsTheme.warningOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎨 Premium Feature Card - Card per Funzionalità Premium
class PremiumFeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final VoidCallback onUpgrade;
  final bool isLocked;

  const PremiumFeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onUpgrade,
    this.isLocked = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(StatsTheme.space4),
      decoration: BoxDecoration(
        color: StatsTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(StatsTheme.radius3),
        border: Border.all(
          color: StatsTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: TextStyle(fontSize: 24.sp),
              ),
              SizedBox(width: StatsTheme.space3),
              Expanded(
                child: Text(
                  title,
                  style: StatsTheme.h5.copyWith(
                    color: StatsTheme.getTextPrimary(context),
                  ),
                ),
              ),
              if (isLocked)
                Icon(
                  Icons.lock,
                  color: StatsTheme.warningOrange,
                  size: 16.sp,
                ),
            ],
          ),
          SizedBox(height: StatsTheme.space2),
          Text(
            description,
            style: StatsTheme.body2.copyWith(
              color: StatsTheme.getTextSecondary(context),
            ),
          ),
          if (isLocked) ...[
            SizedBox(height: StatsTheme.space3),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => PremiumUpgradeFlow.navigateToUpgrade(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: StatsTheme.warningOrange,
                  side: BorderSide(color: StatsTheme.warningOrange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(StatsTheme.radius2),
                  ),
                ),
                child: Text(
                  'Sblocca con Premium',
                  style: StatsTheme.caption.copyWith(
                    color: StatsTheme.warningOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}