// lib/shared/widgets/muscle_tag.dart
// 💪 MUSCLE TAG - Badge per muscoli target
// Mostra muscoli primari e secondari

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/workout_design_system.dart';

/// Tag per mostrare muscoli target (primari e secondari)
class MuscleTag extends StatelessWidget {
  final String muscleName;
  final bool isPrimary;
  final bool isCompact;

  const MuscleTag({
    super.key,
    required this.muscleName,
    this.isPrimary = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact
            ? WorkoutDesignSystem.spacingXS.w
            : WorkoutDesignSystem.spacingS.w,
        vertical: isCompact
            ? WorkoutDesignSystem.spacingXXS.h
            : WorkoutDesignSystem.spacingXS.h,
      ),
      decoration: BoxDecoration(
        color: isPrimary
            ? WorkoutDesignSystem.primary50
            : WorkoutDesignSystem.gray100,
        borderRadius: WorkoutDesignSystem.borderRadiusS,
        border: Border.all(
          color: isPrimary
              ? WorkoutDesignSystem.primary600.withOpacity(0.3)
              : WorkoutDesignSystem.gray200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCompact) ...[
            Text(
              isPrimary ? '💪' : '🔗',
              style: TextStyle(fontSize: 12.sp),
            ),
            SizedBox(width: WorkoutDesignSystem.spacingXXS.w),
          ],
          Text(
            muscleName,
            style: TextStyle(
              fontSize: isCompact
                  ? WorkoutDesignSystem.fontSizeSmall.sp
                  : WorkoutDesignSystem.fontSizeCaption.sp,
              fontWeight: isPrimary
                  ? WorkoutDesignSystem.fontWeightSemiBold
                  : WorkoutDesignSystem.fontWeightMedium,
              color: isPrimary
                  ? WorkoutDesignSystem.primary600
                  : WorkoutDesignSystem.gray700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista di muscle tags
class MuscleTagList extends StatelessWidget {
  final String primaryMuscle;
  final List<String>? secondaryMuscles;
  final bool isCompact;
  final int maxSecondary;

  const MuscleTagList({
    super.key,
    required this.primaryMuscle,
    this.secondaryMuscles,
    this.isCompact = false,
    this.maxSecondary = 2,
  });

  @override
  Widget build(BuildContext context) {
    final secondaries = secondaryMuscles ?? [];
    final visibleSecondaries = secondaries.take(maxSecondary).toList();
    final hiddenCount = secondaries.length > maxSecondary
        ? secondaries.length - maxSecondary
        : 0;

    return Wrap(
      spacing: WorkoutDesignSystem.spacingXS.w,
      runSpacing: WorkoutDesignSystem.spacingXXS.h,
      children: [
        // Muscolo primario
        MuscleTag(
          muscleName: primaryMuscle,
          isPrimary: true,
          isCompact: isCompact,
        ),

        // Muscoli secondari visibili
        ...visibleSecondaries.map((muscle) => MuscleTag(
              muscleName: muscle,
              isPrimary: false,
              isCompact: isCompact,
            )),

        // Indicatore "e altri X"
        if (hiddenCount > 0)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: WorkoutDesignSystem.spacingXS.w,
              vertical: WorkoutDesignSystem.spacingXXS.h,
            ),
            decoration: BoxDecoration(
              color: WorkoutDesignSystem.gray100,
              borderRadius: WorkoutDesignSystem.borderRadiusS,
            ),
            child: Text(
              '+ $hiddenCount',
              style: TextStyle(
                fontSize: WorkoutDesignSystem.fontSizeSmall.sp,
                fontWeight: WorkoutDesignSystem.fontWeightMedium,
                color: WorkoutDesignSystem.gray700,
              ),
            ),
          ),
      ],
    );
  }
}

/// Versione inline (separati da bullet)
class MuscleTagInline extends StatelessWidget {
  final String primaryMuscle;
  final List<String>? secondaryMuscles;
  final int maxTotal;

  const MuscleTagInline({
    super.key,
    required this.primaryMuscle,
    this.secondaryMuscles,
    this.maxTotal = 3,
  });

  @override
  Widget build(BuildContext context) {
    final muscles = [primaryMuscle, ...(secondaryMuscles ?? [])];
    final visible = muscles.take(maxTotal).toList();
    final hidden = muscles.length > maxTotal
        ? muscles.length - maxTotal
        : 0;

    return Row(
      children: [
        Text(
          '💪',
          style: TextStyle(fontSize: 14.sp),
        ),
        SizedBox(width: WorkoutDesignSystem.spacingXXS.w),
        Expanded(
          child: Text(
            visible.join(' • ') + (hidden > 0 ? ' • +$hidden' : ''),
            style: TextStyle(
              fontSize: WorkoutDesignSystem.fontSizeBody.sp,
              fontWeight: WorkoutDesignSystem.fontWeightMedium,
              color: WorkoutDesignSystem.gray700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

