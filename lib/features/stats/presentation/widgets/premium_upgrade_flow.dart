// lib/features/stats/presentation/widgets/premium_upgrade_flow.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/stats_theme.dart';

/// 💎 Premium Upgrade Flow - Flusso Upgrade Premium
class PremiumUpgradeFlow {
  /// 🚀 Naviga alla schermata upgrade
  static void navigateToUpgrade(BuildContext context) {
    // TODO: Implementare navigazione reale alla schermata subscription
    _showUpgradeDialog(context);
  }

  /// 💎 Mostra dialog di upgrade
  static void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
          ),
          child: Container(
            padding: EdgeInsets.all(StatsTheme.space6.w),
            decoration: BoxDecoration(
              color: StatsTheme.getCardBackground(context),
              borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icona Premium
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    gradient: StatsTheme.premiumGradient,
                    borderRadius: BorderRadius.circular(40.r),
                    boxShadow: [
                      BoxShadow(
                        color: StatsTheme.warningOrange.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.diamond,
                    color: Colors.white,
                    size: 40.sp,
                  ),
                ),
                
                SizedBox(height: StatsTheme.space4.h),
                
                // Titolo
                Text(
                  'Sblocca Premium',
                  style: StatsTheme.h3.copyWith(
                    color: StatsTheme.getTextPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: StatsTheme.space2.h),
                
                // Sottotitolo
                Text(
                  'Accedi a statistiche avanzate e funzionalità esclusive',
                  style: StatsTheme.bodyMedium.copyWith(
                    color: StatsTheme.getTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: StatsTheme.space4.h),
                
                // Benefici Premium
                _buildPremiumBenefits(context),
                
                SizedBox(height: StatsTheme.space4.h),
                
                // Pulsanti
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: StatsTheme.space3.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(StatsTheme.radiusMedium.r),
                            side: BorderSide(
                              color: StatsTheme.getBorderColor(context),
                            ),
                          ),
                        ),
                        child: Text(
                          'Forse più tardi',
                          style: StatsTheme.labelMedium.copyWith(
                            color: StatsTheme.getTextSecondary(context),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: StatsTheme.space3.w),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _navigateToSubscription(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StatsTheme.primaryBlue,
                          padding: EdgeInsets.symmetric(vertical: StatsTheme.space3.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(StatsTheme.radiusMedium.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Vai Premium',
                          style: StatsTheme.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🎯 Benefici Premium
  static Widget _buildPremiumBenefits(BuildContext context) {
    final benefits = [
      _PremiumBenefit(
        icon: Icons.analytics,
        title: 'Analisi Avanzate',
        description: 'Grafici dettagliati e insights personalizzati',
      ),
      _PremiumBenefit(
        icon: Icons.trending_up,
        title: 'Progressi nel Tempo',
        description: 'Monitora i tuoi miglioramenti con grafici interattivi',
      ),
      _PremiumBenefit(
        icon: Icons.emoji_events,
        title: 'Achievements Esclusivi',
        description: 'Sblocca badge e obiettivi premium',
      ),
      _PremiumBenefit(
        icon: Icons.smart_toy,
        title: 'AI Insights',
        description: 'Raccomandazioni intelligenti per i tuoi allenamenti',
      ),
    ];

    return Column(
      children: benefits.map((benefit) => Padding(
        padding: EdgeInsets.only(bottom: StatsTheme.space2.h),
        child: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: StatsTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                benefit.icon,
                color: StatsTheme.primaryBlue,
                size: 16.sp,
              ),
            ),
            
            SizedBox(width: StatsTheme.space3.w),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    benefit.title,
                    style: StatsTheme.labelMedium.copyWith(
                      color: StatsTheme.getTextPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    benefit.description,
                    style: StatsTheme.caption.copyWith(
                      color: StatsTheme.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  /// 🚀 Naviga alla schermata subscription
  static void _navigateToSubscription(BuildContext context) {
    // TODO: Implementare navigazione reale
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Navigazione alla schermata subscription in arrivo!',
          style: StatsTheme.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: StatsTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StatsTheme.radiusMedium.r),
        ),
      ),
    );
  }
}

/// 💎 Premium Benefit
class _PremiumBenefit {
  final IconData icon;
  final String title;
  final String description;

  _PremiumBenefit({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// 💎 Premium Upgrade Button - Pulsante Upgrade Premium
class PremiumUpgradeButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isCompact;

  const PremiumUpgradeButton({
    super.key,
    this.text = 'Vai Premium',
    this.onPressed,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => PremiumUpgradeFlow.navigateToUpgrade(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? StatsTheme.space3.w : StatsTheme.space4.w,
          vertical: isCompact ? StatsTheme.space2.h : StatsTheme.space3.h,
        ),
        decoration: BoxDecoration(
          gradient: StatsTheme.premiumGradient,
          borderRadius: BorderRadius.circular(StatsTheme.radiusMedium.r),
          boxShadow: [
            BoxShadow(
              color: StatsTheme.warningOrange.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.diamond,
              color: Colors.white,
              size: isCompact ? 16.sp : 18.sp,
            ),
            SizedBox(width: StatsTheme.space2.w),
            Text(
              text,
              style: StatsTheme.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 12.sp : 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 💎 Premium Feature Lock - Blocco Funzionalità Premium
class PremiumFeatureLock extends StatelessWidget {
  final Widget child;
  final String featureName;
  final VoidCallback? onUpgrade;

  const PremiumFeatureLock({
    super.key,
    required this.child,
    required this.featureName,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Contenuto principale
        child,
        
        // Overlay premium
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60.w,
                    height: 60.h,
                    decoration: BoxDecoration(
                      gradient: StatsTheme.premiumGradient,
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  
                  SizedBox(height: StatsTheme.space3.h),
                  
                  Text(
                    'Funzionalità Premium',
                    style: StatsTheme.h5.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: StatsTheme.space1.h),
                  
                  Text(
                    'Sblocca $featureName con Premium',
                    style: StatsTheme.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: StatsTheme.space3.h),
                  
                  PremiumUpgradeButton(
                    isCompact: true,
                    onPressed: onUpgrade,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
