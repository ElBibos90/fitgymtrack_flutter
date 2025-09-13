// lib/features/templates/presentation/widgets/template_exercise_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../models/template_models.dart';

class TemplateExerciseCard extends StatelessWidget {
  final TemplateExercise exercise;

  const TemplateExerciseCard({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header esercizio
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.exerciseName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              if (exercise.setType != 'normal')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    exercise.setTypeFormatted,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 8.h),
          
          // Descrizione esercizio
          if (exercise.exerciseDescription.isNotEmpty)
            Text(
              exercise.exerciseDescription,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          
          SizedBox(height: 12.h),
          
          // Informazioni serie e ripetizioni
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.repeat,
                label: '${exercise.sets} x ${exercise.repsFormatted}',
                color: AppColors.primary,
              ),
              SizedBox(width: 8.w),
              _buildInfoChip(
                icon: Icons.timer,
                label: exercise.restTimeFormatted,
                color: AppColors.info,
              ),
              SizedBox(width: 8.w),
              _buildInfoChip(
                icon: Icons.fitness_center,
                label: exercise.muscleGroups,
                color: AppColors.success,
              ),
            ],
          ),
          
          // Note se presenti
          if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16.sp,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      exercise.notes!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.warning,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
