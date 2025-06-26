// lib/features/stats/models/stats_models.dart

enum StatsPeriod {
  week,
  month,
  year,
  lastWeek,
  lastMonth,
  lastYear;

  String get apiValue {
    switch (this) {
      case StatsPeriod.week:
        return 'week';
      case StatsPeriod.month:
        return 'month';
      case StatsPeriod.year:
        return 'year';
      case StatsPeriod.lastWeek:
        return 'last_week';
      case StatsPeriod.lastMonth:
        return 'last_month';
      case StatsPeriod.lastYear:
        return 'last_year';
    }
  }

  String get displayName {
    switch (this) {
      case StatsPeriod.week:
        return 'Questa settimana';
      case StatsPeriod.month:
        return 'Questo mese';
      case StatsPeriod.year:
        return 'Quest\'anno';
      case StatsPeriod.lastWeek:
        return 'Settimana scorsa';
      case StatsPeriod.lastMonth:
        return 'Mese scorso';
      case StatsPeriod.lastYear:
        return 'Anno scorso';
    }
  }
}

// ============================================================================
// 📊 USER STATS MODELS
// ============================================================================

class UserStatsResponse {
  final bool success;
  final UserStats userStats;
  final bool isPremium;
  final String message;

  UserStatsResponse({
    required this.success,
    required this.userStats,
    required this.isPremium,
    required this.message,
  });

  factory UserStatsResponse.fromJson(Map<String, dynamic> json) {
    return UserStatsResponse(
      success: json['success'] ?? false,
      userStats: UserStats.fromJson(json['user_stats'] ?? {}),
      isPremium: json['is_premium'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class UserStats {
  // BASE STATS (FREE)
  final int totalWorkouts;
  final int totalDurationMinutes;
  final int totalSeries;
  final int currentStreak;
  final int longestStreak;
  final int workoutsThisWeek;
  final int workoutsThisMonth;
  final double averageWorkoutDuration;
  final double totalWeightLiftedKg;
  final String? firstWorkoutDate;
  final String? lastWorkoutDate;

  // PREMIUM STATS
  final String? mostTrainedMuscleGroup;
  final ExercisePreference? favoriteExercise;
  final List<ProgressTrend>? progressTrends;
  final List<TopExercise>? topExercisesByVolume;
  final WeeklyComparison? weeklyComparison;

  UserStats({
    required this.totalWorkouts,
    required this.totalDurationMinutes,
    required this.totalSeries,
    required this.currentStreak,
    required this.longestStreak,
    required this.workoutsThisWeek,
    required this.workoutsThisMonth,
    required this.averageWorkoutDuration,
    required this.totalWeightLiftedKg,
    this.firstWorkoutDate,
    this.lastWorkoutDate,
    this.mostTrainedMuscleGroup,
    this.favoriteExercise,
    this.progressTrends,
    this.topExercisesByVolume,
    this.weeklyComparison,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalWorkouts: _parseToInt(json['total_workouts']),
      totalDurationMinutes: _parseToInt(json['total_duration_minutes']),
      totalSeries: _parseToInt(json['total_series']),
      currentStreak: _parseToInt(json['current_streak']),
      longestStreak: _parseToInt(json['longest_streak']),
      workoutsThisWeek: _parseToInt(json['workouts_this_week']),
      workoutsThisMonth: _parseToInt(json['workouts_this_month']),
      averageWorkoutDuration: _parseToDouble(json['average_workout_duration']),
      totalWeightLiftedKg: _parseToDouble(json['total_weight_lifted_kg']),
      firstWorkoutDate: json['first_workout_date'],
      lastWorkoutDate: json['last_workout_date'],
      mostTrainedMuscleGroup: json['most_trained_muscle_group'],
      favoriteExercise: json['favorite_exercise'] != null
          ? ExercisePreference.fromJson(json['favorite_exercise'])
          : null,
      progressTrends: json['progress_trends'] != null
          ? (json['progress_trends'] as List)
          .map((e) => ProgressTrend.fromJson(e))
          .toList()
          : null,
      topExercisesByVolume: json['top_exercises_by_volume'] != null
          ? (json['top_exercises_by_volume'] as List)
          .map((e) => TopExercise.fromJson(e))
          .toList()
          : null,
      weeklyComparison: json['weekly_comparison'] != null
          ? WeeklyComparison.fromJson(json['weekly_comparison'])
          : null,
    );
  }
}

class ExercisePreference {
  final String exerciseName;
  final int timesPerformed;
  final double totalVolumeKg;

  ExercisePreference({
    required this.exerciseName,
    required this.timesPerformed,
    required this.totalVolumeKg,
  });

  factory ExercisePreference.fromJson(Map<String, dynamic> json) {
    return ExercisePreference(
      exerciseName: json['exercise_name'] ?? '',
      timesPerformed: _parseToInt(json['times_performed']),
      totalVolumeKg: _parseToDouble(json['total_volume_kg']),
    );
  }
}

class ProgressTrend {
  final String date;
  final int workouts;
  final int durationMinutes;
  final double weightKg;

  ProgressTrend({
    required this.date,
    required this.workouts,
    required this.durationMinutes,
    required this.weightKg,
  });

  factory ProgressTrend.fromJson(Map<String, dynamic> json) {
    return ProgressTrend(
      date: json['date'] ?? '',
      workouts: _parseToInt(json['workouts']),
      durationMinutes: _parseToInt(json['duration_minutes']),
      weightKg: _parseToDouble(json['weight_kg']),
    );
  }
}

class TopExercise {
  final String exerciseName;
  final double totalVolumeKg;
  final int totalSeries;
  final double averageWeightKg;

  TopExercise({
    required this.exerciseName,
    required this.totalVolumeKg,
    required this.totalSeries,
    required this.averageWeightKg,
  });

  factory TopExercise.fromJson(Map<String, dynamic> json) {
    return TopExercise(
      exerciseName: json['exercise_name'] ?? '',
      totalVolumeKg: _parseToDouble(json['total_volume_kg']),
      totalSeries: _parseToInt(json['total_series']),
      averageWeightKg: _parseToDouble(json['average_weight_kg']),
    );
  }
}

class WeeklyComparison {
  final int thisWeekWorkouts;
  final int lastWeekWorkouts;
  final int thisWeekDuration;
  final int lastWeekDuration;
  final double improvementPercentage;

  WeeklyComparison({
    required this.thisWeekWorkouts,
    required this.lastWeekWorkouts,
    required this.thisWeekDuration,
    required this.lastWeekDuration,
    required this.improvementPercentage,
  });

  factory WeeklyComparison.fromJson(Map<String, dynamic> json) {
    return WeeklyComparison(
      thisWeekWorkouts: _parseToInt(json['this_week_workouts']),
      lastWeekWorkouts: _parseToInt(json['last_week_workouts']),
      thisWeekDuration: _parseToInt(json['this_week_duration']),
      lastWeekDuration: _parseToInt(json['last_week_duration']),
      improvementPercentage: _parseToDouble(json['improvement_percentage']),
    );
  }
}

// ============================================================================
// 📅 PERIOD STATS MODELS
// ============================================================================

class PeriodStatsResponse {
  final bool success;
  final PeriodStats periodStats;
  final bool isPremium;
  final String message;

  PeriodStatsResponse({
    required this.success,
    required this.periodStats,
    required this.isPremium,
    required this.message,
  });

  factory PeriodStatsResponse.fromJson(Map<String, dynamic> json) {
    return PeriodStatsResponse(
      success: json['success'] ?? false,
      periodStats: PeriodStats.fromJson(json['period_stats'] ?? {}),
      isPremium: json['is_premium'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class PeriodStats {
  // BASE INFO
  final String period;
  final String startDate;
  final String endDate;

  // BASE STATS (FREE)
  final int workoutCount;
  final int totalDurationMinutes;
  final int totalSeries;
  final double totalWeightKg;
  final double averageDuration;
  final String? mostActiveDay;

  // PREMIUM STATS
  final List<DayDistribution>? weeklyDistribution;
  final List<MuscleGroupPeriod>? muscleGroupsInPeriod;
  final List<TimelineProgress>? timelineProgression;
  final List<TopExercisePeriod>? topExercisesInPeriod;
  final PeriodComparison? comparisonWithPrevious;

  PeriodStats({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.workoutCount,
    required this.totalDurationMinutes,
    required this.totalSeries,
    required this.totalWeightKg,
    required this.averageDuration,
    this.mostActiveDay,
    this.weeklyDistribution,
    this.muscleGroupsInPeriod,
    this.timelineProgression,
    this.topExercisesInPeriod,
    this.comparisonWithPrevious,
  });

  factory PeriodStats.fromJson(Map<String, dynamic> json) {
    return PeriodStats(
      period: json['period'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      workoutCount: json['workout_count'] ?? 0,
      totalDurationMinutes: json['total_duration_minutes'] ?? 0,
      totalSeries: json['total_series'] ?? 0,
      totalWeightKg: _parseToDouble(json['total_weight_kg']),
      averageDuration: _parseToDouble(json['average_duration']),
      mostActiveDay: json['most_active_day'],
      weeklyDistribution: json['weekly_distribution'] != null
          ? (json['weekly_distribution'] as List)
          .map((e) => DayDistribution.fromJson(e))
          .toList()
          : null,
      muscleGroupsInPeriod: json['muscle_groups_in_period'] != null
          ? (json['muscle_groups_in_period'] as List)
          .map((e) => MuscleGroupPeriod.fromJson(e))
          .toList()
          : json['muscle_group_distribution'] != null
          ? (json['muscle_group_distribution'] as List)
          .map((e) => MuscleGroupPeriod.fromJson(e))
          .toList()
          : null,
      timelineProgression: json['timeline_progression'] != null
          ? (json['timeline_progression'] as List)
          .map((e) => TimelineProgress.fromJson(e))
          .toList()
          : json['progression_data'] != null
          ? (json['progression_data'] as List)
          .map((e) => TimelineProgress.fromJson(e))
          .toList()
          : null,
      topExercisesInPeriod: json['top_exercises_in_period'] != null
          ? (json['top_exercises_in_period'] as List)
          .map((e) => TopExercisePeriod.fromJson(e))
          .toList()
          : null,
      comparisonWithPrevious: json['comparison_with_previous'] != null
          ? PeriodComparison.fromJson(json['comparison_with_previous'])
          : null,
    );
  }

  String get periodDisplayName {
    switch (period) {
      case 'week':
        return 'Questa settimana';
      case 'month':
        return 'Questo mese';
      case 'year':
        return 'Quest\'anno';
      case 'last_week':
        return 'Settimana scorsa';
      case 'last_month':
        return 'Mese scorso';
      case 'last_year':
        return 'Anno scorso';
      default:
        return period.toUpperCase();
    }
  }
}

class DayDistribution {
  final String dayName;
  final int dayNumber;
  final int workoutCount;
  final int totalDuration;
  final double avgDuration;

  DayDistribution({
    required this.dayName,
    required this.dayNumber,
    required this.workoutCount,
    required this.totalDuration,
    required this.avgDuration,
  });

  factory DayDistribution.fromJson(Map<String, dynamic> json) {
    return DayDistribution(
      dayName: json['day_name'] ?? '',
      dayNumber: json['day_number'] ?? 0,
      workoutCount: json['workout_count'] ?? 0,
      totalDuration: _parseToInt(json['total_duration']),
      avgDuration: _parseToDouble(json['avg_duration']),
    );
  }
}

class MuscleGroupPeriod {
  final String muscleGroup;
  final int workoutCount;
  final int totalSeries;
  final double totalVolumeKg;

  MuscleGroupPeriod({
    required this.muscleGroup,
    required this.workoutCount,
    required this.totalSeries,
    required this.totalVolumeKg,
  });

  factory MuscleGroupPeriod.fromJson(Map<String, dynamic> json) {
    return MuscleGroupPeriod(
      muscleGroup: json['muscle_group'] ?? json['gruppo_muscolare'] ?? '',
      workoutCount: _parseToInt(json['workout_count'] ?? json['sessions_count']),
      totalSeries: _parseToInt(json['total_series'] ?? json['series_count']),
      totalVolumeKg: _parseToDouble(json['total_volume_kg'] ?? json['total_volume']),
    );
  }
}

class TimelineProgress {
  final String date;
  final int dailyWorkouts;
  final int dailyDuration;
  final double dailyWeight;

  TimelineProgress({
    required this.date,
    required this.dailyWorkouts,
    required this.dailyDuration,
    required this.dailyWeight,
  });

  factory TimelineProgress.fromJson(Map<String, dynamic> json) {
    return TimelineProgress(
      date: json['date'] ?? json['workout_date'] ?? '',
      dailyWorkouts: _parseToInt(json['daily_workouts']),
      dailyDuration: _parseToInt(json['daily_duration']),
      dailyWeight: _parseToDouble(json['daily_weight']),
    );
  }
}

class TopExercisePeriod {
  final String exerciseName;
  final double totalVolumeKg;
  final int totalSeries;
  final int workoutCount;

  TopExercisePeriod({
    required this.exerciseName,
    required this.totalVolumeKg,
    required this.totalSeries,
    required this.workoutCount,
  });

  factory TopExercisePeriod.fromJson(Map<String, dynamic> json) {
    return TopExercisePeriod(
      exerciseName: json['exercise_name'] ?? '',
      totalVolumeKg: _parseToDouble(json['total_volume_kg']),
      totalSeries: _parseToInt(json['total_series']),
      workoutCount: _parseToInt(json['workout_count']),
    );
  }
}

class PeriodComparison {
  final String previousPeriod;
  final String previousStartDate;
  final String previousEndDate;
  final int workoutCountDiff;
  final int durationDiffMinutes;
  final double improvementPercentage;

  PeriodComparison({
    required this.previousPeriod,
    required this.previousStartDate,
    required this.previousEndDate,
    required this.workoutCountDiff,
    required this.durationDiffMinutes,
    required this.improvementPercentage,
  });

  factory PeriodComparison.fromJson(Map<String, dynamic> json) {
    return PeriodComparison(
      previousPeriod: json['previous_period'] ?? '',
      previousStartDate: json['previous_start_date'] ?? '',
      previousEndDate: json['previous_end_date'] ?? '',
      workoutCountDiff: _parseToInt(json['workout_count_diff']),
      durationDiffMinutes: _parseToInt(json['duration_diff_minutes']),
      improvementPercentage: _parseToDouble(json['improvement_percentage']),
    );
  }
}

// ============================================================================
// 🔧 HELPER FUNCTIONS FOR SAFE PARSING
// ============================================================================

/// Parse value to int, handling both int and String inputs
int _parseToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

/// Parse value to double, handling both double and String inputs
double _parseToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}