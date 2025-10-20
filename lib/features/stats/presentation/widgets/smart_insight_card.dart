// lib/features/stats/presentation/widgets/smart_insight_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/stats_theme.dart';
import '../../models/simple_stats_models.dart';

/// 🧠 Smart Insight Card - Card per Insights Intelligenti
class SmartInsightCard extends StatelessWidget {
  final SmartInsight insight;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const SmartInsightCard({
    super.key,
    required this.insight,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: StatsTheme.animationMedium,
      curve: Curves.easeOutCubic,
      child: Dismissible(
        key: Key(insight.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss?.call(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: StatsTheme.space4.w),
          decoration: BoxDecoration(
            color: StatsTheme.warningRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
          ),
          child: Icon(
            Icons.delete_outline,
            color: StatsTheme.warningRed,
            size: 24.sp,
          ),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: EdgeInsets.only(bottom: StatsTheme.space3.h),
            padding: EdgeInsets.all(StatsTheme.space4.w),
            decoration: BoxDecoration(
              color: StatsTheme.getCardBackground(context),
              borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
              boxShadow: StatsTheme.shadowMedium,
              border: Border.all(
                color: _getBorderColor(),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icona
                Container(
                  padding: EdgeInsets.all(StatsTheme.space3.w),
                  decoration: BoxDecoration(
                    gradient: _getIconGradient(),
                    borderRadius: BorderRadius.circular(StatsTheme.radiusMedium.r),
                  ),
                  child: Icon(
                    _getIconData(),
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                
                SizedBox(width: StatsTheme.space4.w),
                
                // Contenuto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titolo
                      Text(
                        insight.title,
                        style: StatsTheme.labelLarge.copyWith(
                          color: StatsTheme.getTextPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: StatsTheme.space2.h),
                      
                      // Descrizione
                      Text(
                        insight.description,
                        style: StatsTheme.bodyMedium.copyWith(
                          color: StatsTheme.getTextSecondary(context),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: StatsTheme.space3.h),
                      
                      // Footer con tipo e priorità
                      Row(
                        children: [
                          // Badge tipo
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: StatsTheme.space2.w,
                              vertical: StatsTheme.space1.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor().withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(StatsTheme.radiusSmall.r),
                            ),
                            child: Text(
                              _getTypeLabel(),
                              style: StatsTheme.caption.copyWith(
                                color: _getTypeColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Indicatore priorità
                          if (insight.priority >= 4)
                            Container(
                              padding: EdgeInsets.all(StatsTheme.space1.w),
                              decoration: BoxDecoration(
                                color: StatsTheme.warningOrange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(StatsTheme.radiusSmall.r),
                              ),
                              child: Icon(
                                Icons.priority_high,
                                color: StatsTheme.warningOrange,
                                size: 12.sp,
                              ),
                            ),
                          
                          // Indicatore non letto
                          if (!insight.isRead)
                            Container(
                              margin: EdgeInsets.only(left: StatsTheme.space2.w),
                              width: 8.w,
                              height: 8.h,
                              decoration: BoxDecoration(
                                color: StatsTheme.primaryBlue,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData() {
    switch (insight.type) {
      case 'achievement':
        return Icons.emoji_events;
      case 'recommendation':
        return Icons.lightbulb_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'tip':
        return Icons.tips_and_updates_outlined;
      default:
        return Icons.insights;
    }
  }

  LinearGradient _getIconGradient() {
    switch (insight.type) {
      case 'achievement':
        return StatsTheme.premiumGradient;
      case 'recommendation':
        return StatsTheme.infoGradient;
      case 'warning':
        return StatsTheme.warningGradient;
      case 'tip':
        return StatsTheme.successGradient;
      default:
        return StatsTheme.primaryGradient;
    }
  }

  Color _getTypeColor() {
    switch (insight.type) {
      case 'achievement':
        return StatsTheme.warningOrange;
      case 'recommendation':
        return StatsTheme.infoCyan;
      case 'warning':
        return StatsTheme.warningRed;
      case 'tip':
        return StatsTheme.successGreen;
      default:
        return StatsTheme.primaryBlue;
    }
  }

  String _getTypeLabel() {
    switch (insight.type) {
      case 'achievement':
        return 'Achievement';
      case 'recommendation':
        return 'Consiglio';
      case 'warning':
        return 'Attenzione';
      case 'tip':
        return 'Suggerimento';
      default:
        return 'Insight';
    }
  }

  Color _getBorderColor() {
    return _getTypeColor().withValues(alpha: 0.2);
  }
}

/// 🧠 Smart Insights List - Lista Insights
class SmartInsightsList extends StatelessWidget {
  final List<SmartInsight> insights;
  final Function(SmartInsight)? onInsightTap;
  final Function(SmartInsight)? onInsightDismiss;

  const SmartInsightsList({
    super.key,
    required this.insights,
    this.onInsightTap,
    this.onInsightDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: StatsTheme.space4.w),
          child: Row(
            children: [
              Icon(
                Icons.psychology,
                color: StatsTheme.primaryBlue,
                size: 20.sp,
              ),
              SizedBox(width: StatsTheme.space2.w),
              Text(
                'Insights Intelligenti',
                style: StatsTheme.h4.copyWith(
                  color: StatsTheme.getTextPrimary(context),
                ),
              ),
              const Spacer(),
              Text(
                '${insights.length}',
                style: StatsTheme.labelMedium.copyWith(
                  color: StatsTheme.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: StatsTheme.space4.h),
        
        // Lista insights
        ...insights.map((insight) => SmartInsightCard(
          insight: insight,
          onTap: () => onInsightTap?.call(insight),
          onDismiss: () => onInsightDismiss?.call(insight),
        )),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(StatsTheme.space8.w),
      margin: EdgeInsets.symmetric(horizontal: StatsTheme.space4.w),
      decoration: BoxDecoration(
        color: StatsTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
        boxShadow: StatsTheme.shadowSmall,
      ),
      child: Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            color: StatsTheme.getTextSecondary(context),
            size: 48.sp,
          ),
          SizedBox(height: StatsTheme.space4.h),
          Text(
            'Nessun insight disponibile',
            style: StatsTheme.h4.copyWith(
              color: StatsTheme.getTextPrimary(context),
            ),
          ),
          SizedBox(height: StatsTheme.space2.h),
          Text(
            'Continua ad allenarti per ricevere insights personalizzati!',
            style: StatsTheme.bodyMedium.copyWith(
              color: StatsTheme.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
