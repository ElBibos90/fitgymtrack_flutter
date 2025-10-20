// lib/features/stats/presentation/widgets/modern_kpi_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/stats_theme.dart';
import '../../models/simple_stats_models.dart';

/// 🎯 Modern KPI Card - Card Moderna per Metriche Principali
class ModernKPICard extends StatelessWidget {
  final KPICard kpiData;
  final VoidCallback? onTap;
  final bool isAnimated;

  const ModernKPICard({
    super.key,
    required this.kpiData,
    this.onTap,
    this.isAnimated = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: isAnimated ? StatsTheme.animationMedium : Duration.zero,
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(StatsTheme.space3.w),
          decoration: BoxDecoration(
            color: StatsTheme.getCardBackground(context),
            borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
            boxShadow: StatsTheme.shadowMedium,
            border: Border.all(
              color: _getBorderColor(context),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con icona e trend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icona
                  Container(
                    padding: EdgeInsets.all(StatsTheme.space1.w),
                    decoration: BoxDecoration(
                      gradient: _getIconGradient(),
                      borderRadius: BorderRadius.circular(StatsTheme.radiusSmall.r),
                    ),
                    child: Icon(
                      _getIconData(),
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                  // Trend indicator
                  if (kpiData.trend != null) _buildTrendIndicator(),
                ],
              ),
              
              SizedBox(height: StatsTheme.space2.h),
              
              // Valore principale
              Flexible(
                child: Text(
                  kpiData.value,
                  style: StatsTheme.metricMedium.copyWith(
                    color: StatsTheme.getTextPrimary(context),
                    fontSize: 20.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(height: StatsTheme.space1.h),
              
              // Titolo
              Flexible(
                child: Text(
                  kpiData.title,
                  style: StatsTheme.labelMedium.copyWith(
                    color: StatsTheme.getTextSecondary(context),
                    fontSize: 12.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Sottotitolo (se presente)
              if (kpiData.subtitle != null) ...[
                SizedBox(height: 2.h),
                Flexible(
                  child: Text(
                    kpiData.subtitle!,
                    style: StatsTheme.caption.copyWith(
                      color: StatsTheme.getTextSecondary(context),
                      fontSize: 10.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator() {
    final isPositive = kpiData.isPositive;
    final trend = kpiData.trend!;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: StatsTheme.space1.w,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: isPositive 
            ? StatsTheme.successGreen.withValues(alpha: 0.1)
            : StatsTheme.warningRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(StatsTheme.radiusSmall.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? StatsTheme.successGreen : StatsTheme.warningRed,
            size: 10.sp,
          ),
          SizedBox(width: 2.w),
          Text(
            '${trend.abs().toStringAsFixed(1)}%',
            style: StatsTheme.caption.copyWith(
              color: isPositive ? StatsTheme.successGreen : StatsTheme.warningRed,
              fontWeight: FontWeight.w600,
              fontSize: 9.sp,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData() {
    switch (kpiData.icon) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'schedule':
        return Icons.schedule;
      case 'repeat':
        return Icons.repeat;
      case 'scale':
        return Icons.scale;
      case 'trending_up':
        return Icons.trending_up;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'speed':
        return Icons.speed;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.analytics;
    }
  }

  LinearGradient _getIconGradient() {
    switch (kpiData.color) {
      case 'primary':
        return StatsTheme.primaryGradient;
      case 'success':
        return StatsTheme.successGradient;
      case 'warning':
        return StatsTheme.warningGradient;
      case 'info':
        return StatsTheme.infoGradient;
      case 'premium':
        return StatsTheme.premiumGradient;
      default:
        return StatsTheme.primaryGradient;
    }
  }

  Color _getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? StatsTheme.neutral700
        : StatsTheme.neutral200;
  }
}

/// 🎯 Compact KPI Card - Versione Compatta
class CompactKPICard extends StatelessWidget {
  final KPICard kpiData;
  final VoidCallback? onTap;

  const CompactKPICard({
    super.key,
    required this.kpiData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(StatsTheme.space3.w),
        decoration: BoxDecoration(
          color: StatsTheme.getCardBackground(context),
          borderRadius: BorderRadius.circular(StatsTheme.radiusMedium.r),
          boxShadow: StatsTheme.shadowSmall,
        ),
        child: Row(
          children: [
            // Icona
            Container(
              padding: EdgeInsets.all(StatsTheme.space2.w),
              decoration: BoxDecoration(
                gradient: _getIconGradient(),
                borderRadius: BorderRadius.circular(StatsTheme.radiusSmall.r),
              ),
              child: Icon(
                _getIconData(),
                color: Colors.white,
                size: 16.sp,
              ),
            ),
            
            SizedBox(width: StatsTheme.space3.w),
            
            // Contenuto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kpiData.value,
                    style: StatsTheme.metricSmall.copyWith(
                      color: StatsTheme.getTextPrimary(context),
                    ),
                  ),
                  Text(
                    kpiData.title,
                    style: StatsTheme.caption.copyWith(
                      color: StatsTheme.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            
            // Trend (se presente)
            if (kpiData.trend != null)
              Icon(
                kpiData.isPositive ? Icons.trending_up : Icons.trending_down,
                color: kpiData.isPositive ? StatsTheme.successGreen : StatsTheme.warningRed,
                size: 16.sp,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData() {
    switch (kpiData.icon) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'schedule':
        return Icons.schedule;
      case 'repeat':
        return Icons.repeat;
      case 'scale':
        return Icons.scale;
      case 'trending_up':
        return Icons.trending_up;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'speed':
        return Icons.speed;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.analytics;
    }
  }

  LinearGradient _getIconGradient() {
    switch (kpiData.color) {
      case 'primary':
        return StatsTheme.primaryGradient;
      case 'success':
        return StatsTheme.successGradient;
      case 'warning':
        return StatsTheme.warningGradient;
      case 'info':
        return StatsTheme.infoGradient;
      case 'premium':
        return StatsTheme.premiumGradient;
      default:
        return StatsTheme.primaryGradient;
    }
  }
}
