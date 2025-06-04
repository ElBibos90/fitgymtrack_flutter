import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/formatters.dart';

class ActiveWorkoutTimerControls extends StatelessWidget {
  final Duration elapsedTime;
  final int currentGroupIndex;
  final int totalGroups;
  final int completedGroups;
  final Animation<double> progressAnimation;
  final Future<void> Function() onExit;
  final VoidCallback? onComplete;

  const ActiveWorkoutTimerControls({
    super.key,
    required this.elapsedTime,
    required this.currentGroupIndex,
    required this.totalGroups,
    required this.completedGroups,
    required this.progressAnimation,
    required this.onExit,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalGroups > 0 ? completedGroups / totalGroups : 0.0;
    final isWorkoutComplete = completedGroups == totalGroups;

    return Container(
      padding: EdgeInsets.all(AppConfig.spacingL.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.indigo600,
            AppColors.indigo700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: AppConfig.elevationM,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onExit,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                Text(
                  'Gruppo ${currentGroupIndex + 1} di $totalGroups',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isWorkoutComplete)
                  IconButton(
                    onPressed: onComplete,
                    icon: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.celebration,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  )
                else
                  SizedBox(width: 48.w),
              ],
            ),
            SizedBox(height: AppConfig.spacingM.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatDuration(elapsedTime),
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$completedGroups/$totalGroups gruppi completati',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConfig.spacingM.h),
            AnimatedBuilder(
              animation: progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: progress * progressAnimation.value,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isWorkoutComplete ? AppColors.success : Colors.white,
                  ),
                  minHeight: 8.h,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
