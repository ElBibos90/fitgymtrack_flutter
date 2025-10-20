// lib/shared/widgets/superset_overview_card.dart
// 🔗 SUPERSET OVERVIEW CARD - Mostra tutti gli esercizi linkati
// MASSIMA PRIORITÀ VISIBILITÀ!

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/workout_design_system.dart';
import '../../features/workouts/models/workout_plan_models.dart';

/// Card overview che mostra TUTTI gli esercizi di un superset/circuit
/// Visibilità massima per utente
class SupersetOverviewCard extends StatelessWidget {
  final List<WorkoutExercise> exercises;
  final int currentExerciseIndex;
  final Map<int, int> completedSeriesCounts; // exerciseId -> count
  final String groupType; // 'superset', 'circuit'
  final int currentSeriesNumber;

  const SupersetOverviewCard({
    super.key,
    required this.exercises,
    required this.currentExerciseIndex,
    required this.completedSeriesCounts,
    required this.groupType,
    required this.currentSeriesNumber,
  });

  @override
  Widget build(BuildContext context) {
    final color = WorkoutDesignSystem.getBadgeColor(groupType);
    final backgroundColor = _getBackgroundColor();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: WorkoutDesignSystem.mobileHorizontalPadding.w,
      ),
      padding: EdgeInsets.all(WorkoutDesignSystem.spacingM.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: WorkoutDesignSystem.borderRadiusM,
        border: Border.all(
          color: color,
          width: 2,
        ),
        boxShadow: WorkoutDesignSystem.shadowLevel2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con badge e info serie
          Row(
            children: [
              Icon(
                WorkoutDesignSystem.getExerciseTypeIcon(groupType),
                color: color,
                size: 20.sp,
              ),
              SizedBox(width: WorkoutDesignSystem.spacingXS.w),
              Text(
                _getHeaderText(),
                style: TextStyle(
                  fontSize: WorkoutDesignSystem.fontSizeH3.sp,
                  fontWeight: WorkoutDesignSystem.fontWeightBold,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                'Serie $currentSeriesNumber/${exercises.first.serie}',
                style: TextStyle(
                  fontSize: WorkoutDesignSystem.fontSizeCaption.sp,
                  fontWeight: WorkoutDesignSystem.fontWeightMedium,
                  color: WorkoutDesignSystem.gray700,
                ),
              ),
            ],
          ),

          SizedBox(height: WorkoutDesignSystem.spacingS.h),

          // Divider
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color,
                  color.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),

          SizedBox(height: WorkoutDesignSystem.spacingS.h),

          // Lista esercizi
          ...exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            return _buildExerciseRow(
              exercise: exercise,
              index: index,
              isCurrent: index == currentExerciseIndex,
              color: color,
            );
          }).toList(),

          SizedBox(height: WorkoutDesignSystem.spacingS.h),

          // 🎯 FASE 5: Info recupero rimossa per risparmiare spazio - comportamento gestito automaticamente
          // // Info importante: NO recupero
          // if (currentExerciseIndex < exercises.length - 1) ...[
          //   Container(
          //     padding: EdgeInsets.symmetric(
          //       horizontal: WorkoutDesignSystem.spacingXS.w,
          //       vertical: WorkoutDesignSystem.spacingXXS.h,
          //     ),
          //     decoration: BoxDecoration(
          //       color: WorkoutDesignSystem.accent100,
          //       borderRadius: WorkoutDesignSystem.borderRadiusS,
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Icon(
          //           Icons.warning_rounded,
          //           color: WorkoutDesignSystem.accent600,
          //           size: 16.sp,
          //         ),
          //         SizedBox(width: WorkoutDesignSystem.spacingXXS.w),
          //         Text(
          //           'NO recupero tra esercizi linkati',
          //           style: TextStyle(
          //             fontSize: WorkoutDesignSystem.fontSizeSmall.sp,
          //             fontWeight: WorkoutDesignSystem.fontWeightMedium,
          //             color: WorkoutDesignSystem.accent700,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ] else ...[
          //   // Ultimo esercizio: SÌ recupero
          //   Container(
          //     padding: EdgeInsets.symmetric(
          //       horizontal: WorkoutDesignSystem.spacingXS.w,
          //       vertical: WorkoutDesignSystem.spacingXXS.h,
          //     ),
          //     decoration: BoxDecoration(
          //       color: WorkoutDesignSystem.success100,
          //       borderRadius: WorkoutDesignSystem.borderRadiusS,
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Icon(
          //           Icons.check_circle_rounded,
          //           color: WorkoutDesignSystem.success600,
          //           size: 16.sp,
          //         ),
          //         SizedBox(width: WorkoutDesignSystem.spacingXXS.w),
          //         Text(
          //           'Recupero dopo questo esercizio',
          //           style: TextStyle(
          //             fontSize: WorkoutDesignSystem.fontSizeSmall.sp,
          //             fontWeight: WorkoutDesignSystem.fontWeightMedium,
          //             color: WorkoutDesignSystem.success700,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ],

          // Progress bar
          SizedBox(height: WorkoutDesignSystem.spacingS.h),
          _buildProgressBar(color),
        ],
      ),
    );
  }

  Widget _buildExerciseRow({
    required WorkoutExercise exercise,
    required int index,
    required bool isCurrent,
    required Color color,
  }) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
    final completedCount = completedSeriesCounts[exerciseId] ?? 0;
    final isCompleted = completedCount >= exercise.serie;

    return Container(
      margin: EdgeInsets.only(bottom: WorkoutDesignSystem.spacingXS.h),
      padding: EdgeInsets.symmetric(
        horizontal: WorkoutDesignSystem.spacingXS.w,
        vertical: WorkoutDesignSystem.spacingXXS.h,
      ),
      decoration: BoxDecoration(
        color: isCurrent ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: WorkoutDesignSystem.borderRadiusS,
        border: isCurrent
            ? Border.all(color: color, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Numero esercizio
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: isCurrent ? color : WorkoutDesignSystem.gray200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: WorkoutDesignSystem.fontSizeBody.sp,
                  fontWeight: WorkoutDesignSystem.fontWeightBold,
                  color: isCurrent ? Colors.white : WorkoutDesignSystem.gray700,
                ),
              ),
            ),
          ),

          SizedBox(width: WorkoutDesignSystem.spacingXS.w),

          // Nome esercizio
          Expanded(
            child: Text(
              exercise.nome,
              style: TextStyle(
                fontSize: WorkoutDesignSystem.fontSizeBody.sp,
                fontWeight: isCurrent
                    ? WorkoutDesignSystem.fontWeightSemiBold
                    : WorkoutDesignSystem.fontWeightRegular,
                color: isCurrent
                    ? color
                    : WorkoutDesignSystem.gray900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          SizedBox(width: WorkoutDesignSystem.spacingXS.w),

          // Progress dots per serie
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(exercise.serie, (serieIndex) {
              final isSerieCompleted = serieIndex < completedCount;
              return Container(
                width: 8.w,
                height: 8.w,
                margin: EdgeInsets.only(left: 2.w),
                decoration: BoxDecoration(
                  color: isSerieCompleted ? color : WorkoutDesignSystem.gray200,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),

          // Status icon
          SizedBox(width: WorkoutDesignSystem.spacingXS.w),
          if (isCurrent)
            Icon(
              Icons.arrow_forward_rounded,
              color: color,
              size: 18.sp,
            )
          else if (isCompleted)
            Icon(
              Icons.check_circle,
              color: WorkoutDesignSystem.success600,
              size: 18.sp,
            )
          else
            Icon(
              Icons.circle_outlined,
              color: WorkoutDesignSystem.gray400,
              size: 18.sp,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(Color color) {
    final totalExercises = exercises.length;
    final currentProgress = (currentExerciseIndex + 1) / totalExercises;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progresso: ${currentExerciseIndex + 1}/$totalExercises (${(currentProgress * 100).toInt()}%)',
          style: TextStyle(
            fontSize: WorkoutDesignSystem.fontSizeSmall.sp,
            fontWeight: WorkoutDesignSystem.fontWeightMedium,
            color: WorkoutDesignSystem.gray700,
          ),
        ),
        SizedBox(height: WorkoutDesignSystem.spacingXXS.h),
        ClipRRect(
          borderRadius: WorkoutDesignSystem.borderRadiusFull,
          child: LinearProgressIndicator(
            value: currentProgress,
            backgroundColor: WorkoutDesignSystem.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6.h,
          ),
        ),
      ],
    );
  }

  Color _getBackgroundColor() {
    switch (groupType.toLowerCase()) {
      case 'superset':
        return WorkoutDesignSystem.supersetPurple50;
      case 'circuit':
        return WorkoutDesignSystem.circuitOrange50;
      default:
        return WorkoutDesignSystem.primary50;
    }
  }

  String _getHeaderText() {
    switch (groupType.toLowerCase()) {
      case 'superset':
        return exercises.length == 2
            ? 'SUPERSET (2 esercizi)'
            : 'SUPERSET (${exercises.length} esercizi)';
      case 'circuit':
        return 'CIRCUIT (${exercises.length} esercizi)';
      default:
        return 'GRUPPO (${exercises.length} esercizi)';
    }
  }
}

