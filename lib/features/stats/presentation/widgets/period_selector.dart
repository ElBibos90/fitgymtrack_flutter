// lib/features/stats/presentation/widgets/period_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/stats_models.dart';
import '../../../../shared/theme/app_colors.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDarkMode ? AppColors.border.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          _buildPeriodButton(context, StatsPeriod.week),
          _buildPeriodButton(context, StatsPeriod.month),
          _buildPeriodButton(context, StatsPeriod.year),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(BuildContext context, StatsPeriod period) {
    final isSelected = period == currentPeriod;

    return Expanded(
      child: GestureDetector(
        onTap: () => onPeriodChanged(period),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.indigo600 : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            _getPeriodLabel(period),
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  String _getPeriodLabel(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.week:
        return 'Settimana';
      case StatsPeriod.month:
        return 'Mese';
      case StatsPeriod.year:
        return 'Anno';
      default:
        return 'Periodo';
    }
  }
}