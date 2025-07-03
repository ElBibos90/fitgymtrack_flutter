import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../../features/workouts/models/workout_plan_models.dart';

class CombinedExerciseGroupWidget extends StatelessWidget {
  final List<WorkoutExercise> exercises;
  final String groupType;
  final Color? groupColor;
  final VoidCallback? onEditGroup;

  const CombinedExerciseGroupWidget({
    super.key,
    required this.exercises,
    required this.groupType,
    this.groupColor,
    this.onEditGroup,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = groupColor ?? _getGroupColor(groupType);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del gruppo
          _buildGroupHeader(context, color, isDarkMode),
          
          // Lista esercizi
          _buildExercisesList(context, color, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(BuildContext context, Color color, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.r),
          topRight: Radius.circular(10.r),
        ),
      ),
      child: Row(
        children: [
          // Icona del tipo di gruppo
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              _getGroupIcon(groupType),
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Informazioni del gruppo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGroupDisplayName(groupType),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${exercises.length} esercizi combinati',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Pulsante modifica
          if (onEditGroup != null)
            IconButton(
              onPressed: onEditGroup,
              icon: Icon(
                Icons.edit,
                color: color,
                size: 20.sp,
              ),
              tooltip: 'Modifica gruppo',
            ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(BuildContext context, Color color, bool isDarkMode) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      separatorBuilder: (context, index) => _buildExerciseSeparator(context, color),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final isLast = index == exercises.length - 1;
        
        return _buildExerciseItem(
          context, 
          exercise, 
          index + 1, 
          color, 
          isDarkMode, 
          isLast,
        );
      },
    );
  }

  Widget _buildExerciseSeparator(BuildContext context, Color color) {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      color: color.withValues(alpha: 0.2),
    );
  }

  Widget _buildExerciseItem(
    BuildContext context,
    WorkoutExercise exercise,
    int position,
    Color color,
    bool isDarkMode,
    bool isLast,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          bottomLeft: isLast ? Radius.circular(10.r) : Radius.zero,
          bottomRight: isLast ? Radius.circular(10.r) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          // Numero posizione
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                position.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Informazioni esercizio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.nome,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                
                SizedBox(height: 4.h),
                
                // Parametri esercizio
                Row(
                  children: [
                    _buildParameterChip(
                      context,
                      '${exercise.serie} serie',
                      color.withValues(alpha: 0.2),
                      color,
                    ),
                    SizedBox(width: 8.w),
                    _buildParameterChip(
                      context,
                      exercise.isIsometric 
                          ? '${exercise.ripetizioni}s'
                          : '${exercise.ripetizioni} reps',
                      color.withValues(alpha: 0.2),
                      color,
                    ),
                    if (exercise.peso > 0) ...[
                      SizedBox(width: 8.w),
                      _buildParameterChip(
                        context,
                        '${exercise.peso.toStringAsFixed(1)}kg',
                        color.withValues(alpha: 0.2),
                        color,
                      ),
                    ],
                  ],
                ),
                
                // Informazioni aggiuntive
                if (exercise.gruppoMuscolare != null || exercise.attrezzatura != null) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      if (exercise.gruppoMuscolare != null) ...[
                        Icon(
                          Icons.fitness_center,
                          size: 12.sp,
                          color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          exercise.gruppoMuscolare!,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (exercise.gruppoMuscolare != null && exercise.attrezzatura != null) ...[
                        SizedBox(width: 8.w),
                        Text(
                          '•',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: 8.w),
                      ],
                      if (exercise.attrezzatura != null) ...[
                        Icon(
                          Icons.sports_gymnastics,
                          size: 12.sp,
                          color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          exercise.attrezzatura!,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Indicatori speciali
          Column(
            children: [
              if (exercise.isIsometric)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'ISOMETRICO',
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              if (exercise.isRestPause)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'REST-PAUSE',
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParameterChip(
    BuildContext context,
    String text,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Color _getGroupColor(String groupType) {
    switch (groupType.toLowerCase()) {
      case 'superset':
        return Colors.purple;
      case 'circuit':
        return Colors.orange;
      case 'triset':
        return Colors.teal;
      default:
        return AppColors.indigo600;
    }
  }

  IconData _getGroupIcon(String groupType) {
    switch (groupType.toLowerCase()) {
      case 'superset':
        return Icons.swap_horiz;
      case 'circuit':
        return Icons.repeat;
      case 'triset':
        return Icons.view_list;
      default:
        return Icons.fitness_center;
    }
  }

  String _getGroupDisplayName(String groupType) {
    switch (groupType.toLowerCase()) {
      case 'superset':
        return 'SUPERSET';
      case 'circuit':
        return 'CIRCUIT';
      case 'triset':
        return 'TRISET';
      default:
        return groupType.toUpperCase();
    }
  }
} 