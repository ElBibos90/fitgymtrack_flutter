import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/workout_design_system.dart';
import 'workout_history_collapsible.dart';

class VsUltimaIndicator extends StatelessWidget {
  final int serieNumber;
  final double currentPeso;
  final int currentRipetizioni;
  final CompletedSeries? lastWorkoutSeries;
  final bool showTrend;

  const VsUltimaIndicator({
    Key? key,
    required this.serieNumber,
    required this.currentPeso,
    required this.currentRipetizioni,
    this.lastWorkoutSeries,
    this.showTrend = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (lastWorkoutSeries == null) {
      return _buildNoDataIndicator();
    }

    final lastPeso = lastWorkoutSeries!.peso;
    final lastRipetizioni = lastWorkoutSeries!.ripetizioni;
    
    final pesoDiff = currentPeso - lastPeso;
    final ripetizioniDiff = currentRipetizioni - lastRipetizioni;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _getBackgroundColor(pesoDiff, ripetizioniDiff),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: _getBorderColor(pesoDiff, ripetizioniDiff),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Peso comparison
          _buildComparisonRow(
            'Peso',
            currentPeso,
            lastPeso,
            pesoDiff,
            'kg',
          ),
          
          SizedBox(height: 2.h),
          
          // Ripetizioni comparison
          _buildComparisonRow(
            'Reps',
            currentRipetizioni.toDouble(),
            lastRipetizioni.toDouble(),
            ripetizioniDiff.toDouble(),
            'reps',
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.neutral100,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: WorkoutDesignSystem.neutral300,
          width: 1,
        ),
      ),
      child: Text(
        'Prima volta',
        style: WorkoutDesignSystem.caption.copyWith(
          color: WorkoutDesignSystem.neutral600,
          fontSize: 10.sp,
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    double current,
    double last,
    double diff,
    String unit,
  ) {
    final isImprovement = diff > 0;
    final isSame = diff == 0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: WorkoutDesignSystem.caption.copyWith(
            color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.7),
            fontSize: 9.sp,
          ),
        ),
        SizedBox(width: 4.w),
        
        // Current value
        Text(
          '${current.toStringAsFixed(current % 1 == 0 ? 0 : 1)}$unit',
          style: WorkoutDesignSystem.captionBold.copyWith(
            color: WorkoutDesignSystem.onSurfaceColor,
            fontSize: 10.sp,
          ),
        ),
        
        SizedBox(width: 2.w),
        
        // Trend indicator
        if (showTrend && !isSame) ...[
          Icon(
            isImprovement ? Icons.trending_up : Icons.trending_down,
            size: 12.sp,
            color: isImprovement 
                ? WorkoutDesignSystem.success500 
                : WorkoutDesignSystem.warning500,
          ),
          SizedBox(width: 2.w),
        ],
        
        // Difference
        Text(
          _formatDifference(diff, unit),
          style: WorkoutDesignSystem.caption.copyWith(
            color: isImprovement 
                ? WorkoutDesignSystem.success600 
                : isSame 
                    ? WorkoutDesignSystem.neutral600 
                    : WorkoutDesignSystem.warning600,
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDifference(double diff, String unit) {
    if (diff == 0) return '=';
    
    final sign = diff > 0 ? '+' : '';
    final value = diff.abs();
    final formattedValue = value % 1 == 0 
        ? value.toInt().toString() 
        : value.toStringAsFixed(1);
    
    return '($sign$formattedValue$unit)';
  }

  Color _getBackgroundColor(double pesoDiff, double ripetizioniDiff) {
    // Se migliora peso E ripetizioni = verde
    if (pesoDiff > 0 && ripetizioniDiff > 0) {
      return WorkoutDesignSystem.success50;
    }
    // Se migliora peso O ripetizioni = giallo
    if (pesoDiff > 0 || ripetizioniDiff > 0) {
      return WorkoutDesignSystem.warning50;
    }
    // Se peggiora = rosso
    if (pesoDiff < 0 || ripetizioniDiff < 0) {
      return WorkoutDesignSystem.error50;
    }
    // Stesso = neutro
    return WorkoutDesignSystem.neutral50;
  }

  Color _getBorderColor(double pesoDiff, double ripetizioniDiff) {
    // Se migliora peso E ripetizioni = verde
    if (pesoDiff > 0 && ripetizioniDiff > 0) {
      return WorkoutDesignSystem.success200;
    }
    // Se migliora peso O ripetizioni = giallo
    if (pesoDiff > 0 || ripetizioniDiff > 0) {
      return WorkoutDesignSystem.warning200;
    }
    // Se peggiora = rosso
    if (pesoDiff < 0 || ripetizioniDiff < 0) {
      return WorkoutDesignSystem.error200;
    }
    // Stesso = neutro
    return WorkoutDesignSystem.neutral200;
  }
}

// Widget semplificato per mostrare solo il trend
class VsUltimaTrend extends StatelessWidget {
  final int serieNumber;
  final double currentPeso;
  final int currentRipetizioni;
  final CompletedSeries? lastWorkoutSeries;

  const VsUltimaTrend({
    Key? key,
    required this.serieNumber,
    required this.currentPeso,
    required this.currentRipetizioni,
    this.lastWorkoutSeries,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (lastWorkoutSeries == null) {
      return Text(
        '(prima volta)',
        style: WorkoutDesignSystem.caption.copyWith(
          color: WorkoutDesignSystem.neutral500,
          fontSize: 10.sp,
        ),
      );
    }

    final lastPeso = lastWorkoutSeries!.peso;
    final lastRipetizioni = lastWorkoutSeries!.ripetizioni;
    
    final pesoDiff = currentPeso - lastPeso;
    final ripetizioniDiff = currentRipetizioni - lastRipetizioni;

    // Determina il trend generale
    final isImprovement = pesoDiff > 0 && ripetizioniDiff > 0;
    final isPartialImprovement = pesoDiff > 0 || ripetizioniDiff > 0;
    final isDecline = pesoDiff < 0 || ripetizioniDiff < 0;
    final isSame = pesoDiff == 0 && ripetizioniDiff == 0;

    String trendText;
    Color trendColor;

    if (isImprovement) {
      trendText = 'vs ultima: ${lastPeso.toStringAsFixed(lastPeso % 1 == 0 ? 0 : 1)}kg x $lastRipetizioni ↑';
      trendColor = WorkoutDesignSystem.success600;
    } else if (isPartialImprovement) {
      trendText = 'vs ultima: ${lastPeso.toStringAsFixed(lastPeso % 1 == 0 ? 0 : 1)}kg x $lastRipetizioni ↗';
      trendColor = WorkoutDesignSystem.warning600;
    } else if (isDecline) {
      trendText = 'vs ultima: ${lastPeso.toStringAsFixed(lastPeso % 1 == 0 ? 0 : 1)}kg x $lastRipetizioni ↓';
      trendColor = WorkoutDesignSystem.error600;
    } else {
      trendText = 'vs ultima: ${lastPeso.toStringAsFixed(lastPeso % 1 == 0 ? 0 : 1)}kg x $lastRipetizioni =';
      trendColor = WorkoutDesignSystem.neutral600;
    }

    return Text(
      trendText,
      style: WorkoutDesignSystem.caption.copyWith(
        color: trendColor,
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
