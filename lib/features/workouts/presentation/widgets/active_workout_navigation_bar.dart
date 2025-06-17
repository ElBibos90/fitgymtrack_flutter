import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../models/exercise_group_models.dart';
import '../../models/active_workout_models.dart' as models;

class ActiveWorkoutNavigationBar extends StatelessWidget {
  final int currentGroupIndex;
  final List<ExerciseGroup> groups;
  final Map<int, List<models.CompletedSeriesData>> completedSeries;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onGroupSelected;

  const ActiveWorkoutNavigationBar({
    super.key,
    required this.currentGroupIndex,
    required this.groups,
    required this.completedSeries,
    required this.onPrevious,
    required this.onNext,
    required this.onGroupSelected,
  });

  Color _getGroupColor(String groupType) {
    switch (groupType) {
      case 'superset':
        return AppColors.warning;
      case 'circuit':
        return AppColors.purple600;
      case 'normal':
      default:
        return AppColors.indigo600;
    }
  }

  Widget _buildGroupIndicator(int index) {
    final group = groups[index];
    final isCompleted = group.isCompleted(completedSeries);
    final isCurrent = index == currentGroupIndex;

    return GestureDetector(
      onTap: () => onGroupSelected(index),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3.w),
        width: isCurrent ? 16.w : 12.w,
        height: isCurrent ? 16.w : 12.w,
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success
              : isCurrent
                  ? _getGroupColor(group.type)
                  : Colors.grey.shade300,
          shape: BoxShape.circle,
          border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
        ),
      ),
    );
  }

  List<Widget> _buildCompactGroupIndicators() {
    return [
      if (currentGroupIndex > 0)
        Icon(Icons.more_horiz, color: Colors.grey, size: 16.sp),
      _buildGroupIndicator(currentGroupIndex),
      SizedBox(width: AppConfig.spacingS.w),
      Text(
        '${currentGroupIndex + 1}/${groups.length}',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      SizedBox(width: AppConfig.spacingS.w),
      if (currentGroupIndex < groups.length - 1)
        Icon(Icons.more_horiz, color: Colors.grey, size: 16.sp),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppConfig.spacingM.w, vertical: AppConfig.spacingM.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              onPressed: currentGroupIndex > 0 ? onPrevious : null,
              icon: Icon(
                Icons.arrow_back,
                color: currentGroupIndex > 0
                    ? AppColors.indigo600
                    : Colors.grey.shade400,
                size: 28.sp,
              ),
              style: IconButton.styleFrom(
                backgroundColor: currentGroupIndex > 0
                    ? AppColors.indigo600.withValues(alpha:0.1)
                    : Colors.transparent,
                minimumSize: Size(40.w, 40.h),
              ),
            ),
            SizedBox(width: AppConfig.spacingS.w),
            Expanded(
              child: SizedBox(
                height: 40.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (groups.length <= 7)
                      ...groups.asMap().entries
                          .map((entry) => _buildGroupIndicator(entry.key))
                    else
                      ..._buildCompactGroupIndicators(),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppConfig.spacingS.w),
            IconButton(
              onPressed:
                  currentGroupIndex < groups.length - 1 ? onNext : null,
              icon: Icon(
                Icons.arrow_forward,
                color: currentGroupIndex < groups.length - 1
                    ? AppColors.indigo600
                    : Colors.grey.shade400,
                size: 28.sp,
              ),
              style: IconButton.styleFrom(
                backgroundColor: currentGroupIndex < groups.length - 1
                    ? AppColors.indigo600.withValues(alpha:0.1)
                    : Colors.transparent,
                minimumSize: Size(40.w, 40.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
