// lib/features/stats/presentation/widgets/stats_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isWide;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isWide = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isWide ? double.infinity : null,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDarkMode ? AppColors.border.withValues(alpha: 0.3) : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}