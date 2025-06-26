// lib/features/stats/models/stats_response_models.dart

// ============================================================================
// 📊 SIMPLE STATS MODELS - NO BUILD RUNNER REQUIRED
// ============================================================================

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
      userStats: UserStats.fromJson(json['stats'] ?? {}),  // ✅ CORREZIONE: 'stats' non 'user_stats'
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
      totalWorkouts: json['total_workouts'] ?? 0,
      totalDurationMinutes: json['total_duration_minutes'] ?? 0,
      totalSeries: json['total_series'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      workoutsThisWeek: json['workouts_this_week'] ?? 0,
      workoutsThisMonth: json['workouts_this_month'] ?? 0,
      averageWorkoutDuration: (json['average_workout_duration'] ?? 0.0).toDouble(),
      totalWeightLiftedKg: (json['total_weight_lifted_kg'] ?? 0.0).toDouble(),
      firstWorkoutDate: json['first_workout_date'],
      lastWorkoutDate: json['last_workout_date'],
      mostTrainedMuscleGroup: json['most_trained_muscle_group'],
      favoriteExercise: UserStats._parseFavoriteExercise(json['favorite_exercise']), // ✅ CORREZIONE
      progressTrends: json['progress_trend_30_days'] != null
          ? (json['progress_trend_30_days'] as List)
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

  // ✅ CORREZIONE: Helper per gestire favorite_exercise che può essere String o Object
  static ExercisePreference? _parseFavoriteExercise(dynamic favoriteExerciseData) {
    if (favoriteExerciseData == null) return null;

    // Se è una stringa (come arriva dall'API), crea un ExercisePreference base
    if (favoriteExerciseData is String) {
      return ExercisePreference(
        exerciseName: favoriteExerciseData,
        timesPerformed: 0,
        totalVolumeKg: 0.0,
      );
    }

    // Se è un oggetto (formato completo), usa il parsing normale
    if (favoriteExerciseData is Map<String, dynamic>) {
      return ExercisePreference.fromJson(favoriteExerciseData);
    }

    return null;
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
      timesPerformed: json['times_performed'] ?? 0,
      totalVolumeKg: (json['total_volume_kg'] ?? 0.0).toDouble(),
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
      date: json['workout_date'] ?? json['date'] ?? '',
      workouts: json['workout_count'] ?? 0,
      durationMinutes: json['total_duration'] ?? 0,
      weightKg: (json['total_volume'] ?? 0.0).toDouble(),
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
      totalVolumeKg: (json['total_volume'] ?? 0.0).toDouble(),
      totalSeries: json['series_count'] ?? 0,
      averageWeightKg: (json['avg_weight'] ?? 0.0).toDouble(),
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

  factory WeeklyComparison.fromJson(dynamic json) {
    // L'API restituisce un array, prendiamo il primo elemento
    if (json is List && json.isNotEmpty) {
      final weekData = json[0] as Map<String, dynamic>;
      return WeeklyComparison(
        thisWeekWorkouts: weekData['workout_count'] ?? 0,
        lastWeekWorkouts: 0, // Non disponibile in questo formato
        thisWeekDuration: weekData['total_duration'] ?? 0,
        lastWeekDuration: 0, // Non disponibile in questo formato
        improvementPercentage: 0.0, // Non disponibile in questo formato
      );
    }

    // Fallback per formato oggetto
    if (json is Map<String, dynamic>) {
      return WeeklyComparison(
        thisWeekWorkouts: json['this_week_workouts'] ?? 0,
        lastWeekWorkouts: json['last_week_workouts'] ?? 0,
        thisWeekDuration: json['this_week_duration'] ?? 0,
        lastWeekDuration: json['last_week_duration'] ?? 0,
        improvementPercentage: (json['improvement_percentage'] ?? 0.0).toDouble(),
      );
    }

    // Default
    return WeeklyComparison(
      thisWeekWorkouts: 0,
      lastWeekWorkouts: 0,
      thisWeekDuration: 0,
      lastWeekDuration: 0,
      improvementPercentage: 0.0,
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
      totalWeightKg: (json['total_weight_kg'] ?? 0.0).toDouble(),
      averageDuration: (json['average_duration'] ?? 0.0).toDouble(),
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
          : json['top_exercises_period'] != null
          ? (json['top_exercises_period'] as List)
          .map((e) => TopExercisePeriod.fromJson(e))
          .toList()
          : null,
      comparisonWithPrevious: json['comparison_with_previous'] != null
          ? PeriodComparison.fromJson(json['comparison_with_previous'])
          : null,
    );
  }
}

// Premium stats helper classes
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
      totalDuration: json['total_duration'] ?? 0,
      avgDuration: (json['avg_duration'] ?? 0.0).toDouble(),
    );
  }
}

class MuscleGroupPeriod {
  final String muscleGroup;
  final int sessionsCount;
  final int seriesCount;
  final double totalVolume;

  MuscleGroupPeriod({
    required this.muscleGroup,
    required this.sessionsCount,
    required this.seriesCount,
    required this.totalVolume,
  });

  factory MuscleGroupPeriod.fromJson(Map<String, dynamic> json) {
    return MuscleGroupPeriod(
      muscleGroup: json['gruppo_muscolare'] ?? json['muscle_group'] ?? '',
      sessionsCount: json['sessions_count'] ?? 0,
      seriesCount: json['series_count'] ?? 0,
      totalVolume: (json['total_volume'] ?? 0.0).toDouble(),
    );
  }
}

class TimelineProgress {
  final String date;
  final int dailyWorkouts;
  final int dailyDuration;
  final int dailySeries;

  TimelineProgress({
    required this.date,
    required this.dailyWorkouts,
    required this.dailyDuration,
    required this.dailySeries,
  });

  factory TimelineProgress.fromJson(Map<String, dynamic> json) {
    return TimelineProgress(
      date: json['workout_date'] ?? json['date'] ?? '',
      dailyWorkouts: json['daily_workouts'] ?? 0,
      dailyDuration: json['daily_duration'] ?? 0,
      dailySeries: json['daily_series'] ?? 0,
    );
  }
}

class TopExercisePeriod {
  final String exerciseName;
  final int seriesPerformed;
  final double totalVolume;
  final double avgWeight;
  final double maxWeight;

  TopExercisePeriod({
    required this.exerciseName,
    required this.seriesPerformed,
    required this.totalVolume,
    required this.avgWeight,
    required this.maxWeight,
  });

  factory TopExercisePeriod.fromJson(Map<String, dynamic> json) {
    return TopExercisePeriod(
      exerciseName: json['exercise_name'] ?? '',
      seriesPerformed: json['series_performed'] ?? 0,
      totalVolume: (json['total_volume'] ?? 0.0).toDouble(),
      avgWeight: (json['avg_weight'] ?? 0.0).toDouble(),
      maxWeight: (json['max_weight'] ?? 0.0).toDouble(),
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
      workoutCountDiff: json['workout_count_diff'] ?? 0,
      durationDiffMinutes: json['duration_diff_minutes'] ?? 0,
      improvementPercentage: (json['improvement_percentage'] ?? 0.0).toDouble(),
    );
  }
}