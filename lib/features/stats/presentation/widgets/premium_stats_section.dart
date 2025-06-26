// lib/features/stats/presentation/widgets/premium_stats_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../stats/models/stats_models.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../stats/presentation/widgets/stats_card.dart';

class PremiumStatsSection extends StatelessWidget {
  final UserStatsResponse userStats;
  final PeriodStatsResponse? periodStats;

  const PremiumStatsSection({
    super.key,
    required this.userStats,
    this.periodStats,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Premium
        Row(
          children: [
            Icon(
              Icons.diamond,
              color: AppColors.warning,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Statistiche Premium',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // User Premium Stats
        if (userStats.userStats.mostTrainedMuscleGroup != null) ...[
          _buildAdvancedUserStats(context),
          SizedBox(height: 20.h),
        ],

        // Period Premium Stats
        if (periodStats?.periodStats.weeklyDistribution != null) ...[
          _buildAdvancedPeriodStats(context),
          SizedBox(height: 20.h),
        ],

        // Simple charts section placeholder
        _buildChartsSection(context),
      ],
    );
  }

  Widget _buildAdvancedUserStats(BuildContext context) {
    final stats = userStats.userStats;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analisi Avanzate',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),

        // Gruppo muscolare più allenato
        if (stats.mostTrainedMuscleGroup != null)
          StatsCard(
            title: 'Gruppo muscolare più allenato',
            value: stats.mostTrainedMuscleGroup!,
            icon: Icons.fitness_center,
            color: AppColors.indigo600,
            isWide: true,
          ),

        SizedBox(height: 12.h),

        // Esercizio preferito
        if (stats.favoriteExercise != null) ...[
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Esercizio preferito',
                  value: stats.favoriteExercise!.exerciseName,
                  icon: Icons.star,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: StatsCard(
                  title: 'Volume totale',
                  value: '${stats.favoriteExercise!.totalVolumeKg.toStringAsFixed(1)}kg',
                  icon: Icons.scale,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],

        // Weekly Comparison
        if (stats.weeklyComparison != null) ...[
          SizedBox(height: 12.h),
          _buildWeeklyComparison(context, stats.weeklyComparison!),
        ],
      ],
    );
  }

  Widget _buildWeeklyComparison(BuildContext context, WeeklyComparison comparison) {
    final isImprovement = comparison.improvementPercentage >= 0;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDarkMode ? AppColors.border.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isImprovement ? Icons.trending_up : Icons.trending_down,
                color: isImprovement ? AppColors.success : AppColors.error,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Confronto Settimanale',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Questa settimana',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${comparison.thisWeekWorkouts} allenamenti',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDarkMode ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settimana scorsa',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${comparison.lastWeekWorkouts} allenamenti',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDarkMode ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isImprovement
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${isImprovement ? '+' : ''}${comparison.improvementPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isImprovement ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedPeriodStats(BuildContext context) {
    final stats = periodStats!.periodStats;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribuzione ${stats.periodDisplayName}',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),

        // Semplice lista invece di grafico complesso
        if (stats.weeklyDistribution != null)
          _buildSimpleWeeklyList(context, stats.weeklyDistribution!),
      ],
    );
  }

  Widget _buildSimpleWeeklyList(BuildContext context, List<DayDistribution> distribution) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDarkMode ? AppColors.border.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Column(
        children: distribution.map((day) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    day.dayName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${day.workoutCount}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.indigo600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 8.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      color: AppColors.border,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: day.workoutCount / 7.0, // Normalizza su 7 giorni max
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.r),
                          color: AppColors.indigo600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grafici e Tendenze',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),

        // Placeholder per futuri grafici
        Container(
          height: 100.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isDarkMode ? AppColors.border.withOpacity(0.3) : AppColors.border,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppColors.indigo600,
                  size: 32.sp,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Grafici avanzati in arrivo',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}