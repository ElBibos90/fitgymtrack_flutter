// lib/features/stats/presentation/widgets/period_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/stats_models.dart';
import '../../../../shared/theme/stats_theme.dart';

/// 📅 Modern Period Selector - Selettore Periodo Moderno
class PeriodSelector extends StatelessWidget {
  final StatsPeriod currentPeriod;
  final Function(StatsPeriod) onPeriodChanged;

  const PeriodSelector({
    super.key,
    required this.currentPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: StatsTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
        border: Border.all(
          color: StatsTheme.getBorderColor(context),
          width: 1,
        ),
        boxShadow: StatsTheme.shadowSmall,
      ),
      child: Row(
        children: [
          _buildPeriodButton(context, StatsPeriod.week),
          SizedBox(width: 6.w),
          _buildPeriodButton(context, StatsPeriod.month),
          SizedBox(width: 6.w),
          _buildPeriodButton(context, StatsPeriod.year),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(BuildContext context, StatsPeriod period) {
    final isSelected = period == currentPeriod;
    final periodData = _getPeriodData(period);

    return Expanded(
      child: GestureDetector(
        onTap: () => onPeriodChanged(period),
        child: AnimatedContainer(
          duration: StatsTheme.animationFast,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: isSelected 
                ? StatsTheme.primaryBlue 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(StatsTheme.radiusMedium.r),
            border: isSelected 
                ? Border.all(color: StatsTheme.primaryBlue, width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icona
              Icon(
                periodData.icon,
                color: isSelected 
                    ? Colors.white 
                    : StatsTheme.getTextSecondary(context),
                size: 14.sp,
              ),
              SizedBox(width: 4.w),
              // Testo
              Flexible(
                child: Text(
                  periodData.label,
                  style: StatsTheme.caption.copyWith(
                    color: isSelected 
                        ? Colors.white 
                        : StatsTheme.getTextSecondary(context),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 11.sp,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _PeriodData _getPeriodData(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.week:
        return _PeriodData(
          icon: Icons.calendar_view_week,
          label: 'Settimana',
          description: 'Ultimi 7 giorni',
        );
      case StatsPeriod.month:
        return _PeriodData(
          icon: Icons.calendar_month,
          label: 'Mese',
          description: 'Ultimi 30 giorni',
        );
      case StatsPeriod.year:
        return _PeriodData(
          icon: Icons.calendar_today,
          label: 'Anno',
          description: 'Ultimi 365 giorni',
        );
      default:
        return _PeriodData(
          icon: Icons.calendar_view_day,
          label: 'Periodo',
          description: 'Seleziona periodo',
        );
    }
  }
}

/// 📅 Period Data - Dati Periodo
class _PeriodData {
  final IconData icon;
  final String label;
  final String description;

  _PeriodData({
    required this.icon,
    required this.label,
    required this.description,
  });
}

/// 📅 Simple Period Selector - Selettore Periodo Semplice
class SimplePeriodSelector extends StatelessWidget {
  final StatsPeriod currentPeriod;
  final Function(StatsPeriod) onPeriodChanged;

  const SimplePeriodSelector({
    super.key,
    required this.currentPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: StatsTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
        border: Border.all(
          color: StatsTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSimpleButton(context, StatsPeriod.week, 'Settimana'),
          _buildSimpleButton(context, StatsPeriod.month, 'Mese'),
          _buildSimpleButton(context, StatsPeriod.year, 'Anno'),
        ],
      ),
    );
  }

  Widget _buildSimpleButton(BuildContext context, StatsPeriod period, String label) {
    final isSelected = period == currentPeriod;

    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: AnimatedContainer(
        duration: StatsTheme.animationFast,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected 
              ? StatsTheme.primaryBlue 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(StatsTheme.radiusMedium.r),
        ),
        child: Text(
          label,
          style: StatsTheme.labelMedium.copyWith(
            color: isSelected 
                ? Colors.white 
                : StatsTheme.getTextSecondary(context),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}