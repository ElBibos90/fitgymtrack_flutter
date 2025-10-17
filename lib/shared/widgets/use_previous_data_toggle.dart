import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/workout_design_system.dart';

/// 🔄 Use Previous Data Toggle
/// Toggle switch per abilitare/disabilitare l'uso dei dati precedenti
class UsePreviousDataToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isEnabled;
  final String? tooltip;

  const UsePreviousDataToggle({
    Key? key,
    required this.value,
    required this.onChanged,
    this.isEnabled = true,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: value 
            ? WorkoutDesignSystem.primary50 
            : WorkoutDesignSystem.neutral50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: value 
              ? WorkoutDesignSystem.primary200 
              : WorkoutDesignSystem.neutral200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icona
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: value 
                  ? WorkoutDesignSystem.primary500 
                  : WorkoutDesignSystem.neutral400,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.history,
              color: Colors.white,
              size: 16.sp,
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Testo e descrizione
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usa dati precedenti',
                  style: WorkoutDesignSystem.captionBold.copyWith(
                    color: WorkoutDesignSystem.onSurfaceColor,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value 
                      ? 'Carica automaticamente peso e ripetizioni dell\'ultimo allenamento'
                      : 'Inserisci manualmente peso e ripetizioni',
                  style: WorkoutDesignSystem.caption.copyWith(
                    color: WorkoutDesignSystem.onSurfaceColor.withOpacity(0.7),
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Toggle switch
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: isEnabled ? onChanged : null,
              activeColor: WorkoutDesignSystem.primary500,
              activeTrackColor: WorkoutDesignSystem.primary200,
              inactiveThumbColor: WorkoutDesignSystem.neutral300,
              inactiveTrackColor: WorkoutDesignSystem.neutral200,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎯 Previous Data Status Badge
/// Badge per mostrare lo stato dei dati precedenti
class PreviousDataStatusBadge extends StatelessWidget {
  final bool isUsingPreviousData;
  final bool hasPreviousData;
  final String? previousDataInfo;

  const PreviousDataStatusBadge({
    Key? key,
    required this.isUsingPreviousData,
    required this.hasPreviousData,
    this.previousDataInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isUsingPreviousData || !hasPreviousData) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.success50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: WorkoutDesignSystem.success200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 12.sp,
            color: WorkoutDesignSystem.success600,
          ),
          SizedBox(width: 4.w),
          Text(
            previousDataInfo ?? 'Dati precedenti caricati',
            style: WorkoutDesignSystem.caption.copyWith(
              color: WorkoutDesignSystem.success700,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 📊 Previous Data Info Card
/// Card per mostrare informazioni sui dati precedenti
class PreviousDataInfoCard extends StatelessWidget {
  final Map<int, CompletedSeries> lastWorkoutSeries;
  final int currentSeries;
  final VoidCallback? onViewHistory;

  const PreviousDataInfoCard({
    Key? key,
    required this.lastWorkoutSeries,
    required this.currentSeries,
    this.onViewHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentSeriesData = lastWorkoutSeries[currentSeries];
    
    if (currentSeriesData == null) {
      return _buildNoDataCard();
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.primary50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: WorkoutDesignSystem.primary200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16.sp,
                color: WorkoutDesignSystem.primary600,
              ),
              SizedBox(width: 8.w),
              Text(
                'Dati Serie $currentSeries',
                style: WorkoutDesignSystem.captionBold.copyWith(
                  color: WorkoutDesignSystem.primary700,
                ),
              ),
              Spacer(),
              if (onViewHistory != null)
                GestureDetector(
                  onTap: onViewHistory,
                  child: Text(
                    'Vedi storico',
                    style: WorkoutDesignSystem.caption.copyWith(
                      color: WorkoutDesignSystem.primary600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 8.h),
          
          Row(
            children: [
              // Peso
              Expanded(
                child: _buildDataItem(
                  'Peso',
                  '${currentSeriesData.formattedPeso}kg',
                  Icons.fitness_center,
                ),
              ),
              
              SizedBox(width: 12.w),
              
              // Ripetizioni
              Expanded(
                child: _buildDataItem(
                  'Reps',
                  currentSeriesData.formattedRipetizioni,
                  Icons.repeat,
                ),
              ),
              
              SizedBox(width: 12.w),
              
              // Data
              Expanded(
                child: _buildDataItem(
                  'Data',
                  currentSeriesData.formattedDate,
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.neutral50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: WorkoutDesignSystem.neutral200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16.sp,
            color: WorkoutDesignSystem.neutral500,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Nessun dato precedente per la serie $currentSeries',
              style: WorkoutDesignSystem.caption.copyWith(
                color: WorkoutDesignSystem.neutral600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 14.sp,
          color: WorkoutDesignSystem.primary600,
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: WorkoutDesignSystem.caption.copyWith(
            color: WorkoutDesignSystem.primary600,
            fontSize: 9.sp,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: WorkoutDesignSystem.captionBold.copyWith(
            color: WorkoutDesignSystem.primary700,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }
}
