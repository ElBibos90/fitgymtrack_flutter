import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/workout_design_system.dart';
import 'vs_ultima_indicator.dart';
import 'workout_history_collapsible.dart';

class WeightRepsCardWithHistory extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final int serieNumber;
  final CompletedSeries? lastWorkoutSeries;
  final VoidCallback? onEdit;
  final bool isEditable;

  const WeightRepsCardWithHistory({
    Key? key,
    required this.label,
    required this.value,
    required this.unit,
    required this.serieNumber,
    this.lastWorkoutSeries,
    this.onEdit,
    this.isEditable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140.w,
      height: 78.h,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: WorkoutDesignSystem.borderColor,
          width: 1,
        ),
        boxShadow: [WorkoutDesignSystem.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con label e edit button
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: WorkoutDesignSystem.captionBold.copyWith(
                    color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.8),
                    fontSize: 11.sp,
                  ),
                ),
              ),
              if (isEditable && onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      color: WorkoutDesignSystem.primary50,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 12.sp,
                      color: WorkoutDesignSystem.primary600,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 4.h),
          
          // Valore principale
          Text(
            '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}$unit',
            style: WorkoutDesignSystem.heading2.copyWith(
              color: WorkoutDesignSystem.onSurfaceColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 2.h),
          
          // Indicatore "vs ultima"
          VsUltimaTrend(
            serieNumber: serieNumber,
            currentPeso: label.toLowerCase().contains('peso') ? value : 0,
            currentRipetizioni: label.toLowerCase().contains('ripetizioni') ? value.toInt() : 0,
            lastWorkoutSeries: lastWorkoutSeries,
          ),
        ],
      ),
    );
  }
}

// Widget per la card peso con storico
class WeightCardWithHistory extends StatelessWidget {
  final double peso;
  final int serieNumber;
  final CompletedSeries? lastWorkoutSeries;
  final VoidCallback? onEdit;
  final bool isEditable;

  const WeightCardWithHistory({
    Key? key,
    required this.peso,
    required this.serieNumber,
    this.lastWorkoutSeries,
    this.onEdit,
    this.isEditable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WeightRepsCardWithHistory(
      label: 'PESO',
      value: peso,
      unit: 'kg',
      serieNumber: serieNumber,
      lastWorkoutSeries: lastWorkoutSeries,
      onEdit: onEdit,
      isEditable: isEditable,
    );
  }
}

// Widget per la card ripetizioni con storico
class RepsCardWithHistory extends StatelessWidget {
  final int ripetizioni;
  final int serieNumber;
  final CompletedSeries? lastWorkoutSeries;
  final VoidCallback? onEdit;
  final bool isEditable;

  const RepsCardWithHistory({
    Key? key,
    required this.ripetizioni,
    required this.serieNumber,
    this.lastWorkoutSeries,
    this.onEdit,
    this.isEditable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WeightRepsCardWithHistory(
      label: 'RIPETIZIONI',
      value: ripetizioni.toDouble(),
      unit: 'reps',
      serieNumber: serieNumber,
      lastWorkoutSeries: lastWorkoutSeries,
      onEdit: onEdit,
      isEditable: isEditable,
    );
  }
}

// Widget combinato per peso e ripetizioni con storico
class WeightRepsCombinedWithHistory extends StatelessWidget {
  final double peso;
  final int ripetizioni;
  final int serieNumber;
  final CompletedSeries? lastWorkoutSeries;
  final VoidCallback? onPesoEdit;
  final VoidCallback? onRepsEdit;
  final bool isEditable;

  const WeightRepsCombinedWithHistory({
    Key? key,
    required this.peso,
    required this.ripetizioni,
    required this.serieNumber,
    this.lastWorkoutSeries,
    this.onPesoEdit,
    this.onRepsEdit,
    this.isEditable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Card Peso
        WeightCardWithHistory(
          peso: peso,
          serieNumber: serieNumber,
          lastWorkoutSeries: lastWorkoutSeries,
          onEdit: onPesoEdit,
          isEditable: isEditable,
        ),
        
        SizedBox(width: 8.w),
        
        // Card Ripetizioni
        RepsCardWithHistory(
          ripetizioni: ripetizioni,
          serieNumber: serieNumber,
          lastWorkoutSeries: lastWorkoutSeries,
          onEdit: onRepsEdit,
          isEditable: isEditable,
        ),
      ],
    );
  }
}
