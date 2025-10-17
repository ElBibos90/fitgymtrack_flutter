// lib/shared/widgets/workout_header.dart
// 🏋️ WORKOUT HEADER - Header moderno con progress bar e badge superset
// Mobile-optimized: 60px height

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/workout_design_system.dart';
import 'superset_badge.dart';

/// Header workout moderno con progress bar e info workout
class WorkoutHeader extends StatelessWidget {
  final int currentExerciseIndex;
  final int totalExercises;
  final String workoutName;
  final String? workoutType; // null, 'superset', 'circuit'
  final Duration elapsedTime;
  final VoidCallback onBack;
  final VoidCallback? onMenu;
  final Color? backgroundColor;

  const WorkoutHeader({
    super.key,
    required this.currentExerciseIndex,
    required this.totalExercises,
    required this.workoutName,
    this.workoutType,
    required this.elapsedTime,
    required this.onBack,
    this.onMenu,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalExercises > 0
        ? (currentExerciseIndex + 1) / totalExercises
        : 0.0;

    return Container(
      height: WorkoutDesignSystem.headerHeight.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor ?? WorkoutDesignSystem.primary50,
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar con info
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: WorkoutDesignSystem.spacingM.w,
                ),
                child: Row(
                  children: [
                    // Back button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onBack,
                        borderRadius: BorderRadius.circular(
                          WorkoutDesignSystem.radiusFull,
                        ),
                        child: Container(
                          width: 44.w,
                          height: 44.h,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 24.sp,
                            color: WorkoutDesignSystem.gray900,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // Progress counter + badge
                    Text(
                      '${currentExerciseIndex + 1}/$totalExercises',
                      style: TextStyle(
                        fontSize: WorkoutDesignSystem.fontSizeBody.sp,
                        fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
                        color: WorkoutDesignSystem.gray900,
                      ),
                    ),

                    // Badge superset (se presente)
                    if (workoutType != null) ...[
                      SizedBox(width: 8.w),
                      SupersetBadge.compact(workoutType!),
                    ],

                    SizedBox(width: 12.w),

                    // Workout name
                    Expanded(
                      child: Text(
                        workoutName,
                        style: TextStyle(
                          fontSize: WorkoutDesignSystem.fontSizeBody.sp,
                          fontWeight: WorkoutDesignSystem.fontWeightBold,
                          color: WorkoutDesignSystem.gray900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Timer
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: WorkoutDesignSystem.gray100,
                        borderRadius: WorkoutDesignSystem.borderRadiusS,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            size: 14.sp,
                            color: WorkoutDesignSystem.primary600,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            _formatDuration(elapsedTime),
                            style: TextStyle(
                              fontSize: WorkoutDesignSystem.fontSizeCaption.sp,
                              fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
                              fontFamily: WorkoutDesignSystem.fontFamilyNumbers,
                              color: WorkoutDesignSystem.gray900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Menu button (se presente)
                    if (onMenu != null) ...[
                      SizedBox(width: 8.w),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onMenu,
                          borderRadius: BorderRadius.circular(
                            WorkoutDesignSystem.radiusFull,
                          ),
                          child: Container(
                            width: 44.w,
                            height: 44.h,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.more_vert_rounded,
                              size: 24.sp,
                              color: WorkoutDesignSystem.gray900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Progress bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: WorkoutDesignSystem.spacingM.w,
              ),
              child: ClipRRect(
                borderRadius: WorkoutDesignSystem.borderRadiusFull,
                child: SizedBox(
                  height: WorkoutDesignSystem.progressBarHeight.h,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: WorkoutDesignSystem.gray200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor() {
    if (workoutType != null) {
      return WorkoutDesignSystem.getBadgeColor(workoutType!);
    }
    return WorkoutDesignSystem.primary600;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

/// Versione compatta dell'header (senza workout name)
class WorkoutHeaderCompact extends StatelessWidget {
  final int currentExerciseIndex;
  final int totalExercises;
  final String? workoutType;
  final Duration elapsedTime;
  final VoidCallback onBack;
  final VoidCallback? onMenu;

  const WorkoutHeaderCompact({
    super.key,
    required this.currentExerciseIndex,
    required this.totalExercises,
    this.workoutType,
    required this.elapsedTime,
    required this.onBack,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalExercises > 0
        ? (currentExerciseIndex + 1) / totalExercises
        : 0.0;

    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: WorkoutDesignSystem.spacingM.w,
                ),
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      iconSize: 24.sp,
                    ),

                    // Progress + badge
                    Text(
                      '${currentExerciseIndex + 1}/$totalExercises',
                      style: TextStyle(
                        fontSize: WorkoutDesignSystem.fontSizeBody.sp,
                        fontWeight: WorkoutDesignSystem.fontWeightBold,
                      ),
                    ),

                    if (workoutType != null) ...[
                      SizedBox(width: 8.w),
                      SupersetBadge.compact(workoutType!),
                    ],

                    const Spacer(),

                    // Timer
                    Text(
                      _formatDuration(elapsedTime),
                      style: TextStyle(
                        fontSize: WorkoutDesignSystem.fontSizeBody.sp,
                        fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
                        fontFamily: WorkoutDesignSystem.fontFamilyNumbers,
                      ),
                    ),

                    if (onMenu != null)
                      IconButton(
                        onPressed: onMenu,
                        icon: const Icon(Icons.more_vert_rounded),
                        iconSize: 24.sp,
                      ),
                  ],
                ),
              ),
            ),

            // Progress bar
            SizedBox(
              height: WorkoutDesignSystem.progressBarHeight.h,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: WorkoutDesignSystem.gray200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  workoutType != null
                      ? WorkoutDesignSystem.getBadgeColor(workoutType!)
                      : WorkoutDesignSystem.primary600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

