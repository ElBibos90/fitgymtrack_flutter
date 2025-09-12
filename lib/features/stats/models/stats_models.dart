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
  final double value; // Per i grafici

  ProgressTrend({
    required this.date,
    required this.workouts,
    required this.durationMinutes,
    required this.weightKg,
    required this.value,
  });

  factory ProgressTrend.fromJson(Map<String, dynamic> json) {
    return ProgressTrend(
      date: json['workout_date'] ?? json['date'] ?? '',
      workouts: _parseToInt(json['workout_count']),
      durationMinutes: _parseToInt(json['total_duration']),
      weightKg: _parseToDouble(json['total_volume']),
      value: _parseToDouble(json['value']) ?? _parseToDouble(json['total_volume']) ?? 0.0,
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
      totalVolumeKg: _parseToDouble(json['total_volume']),
      totalSeries: _parseToInt(json['series_count']),
      averageWeightKg: _parseToDouble(json['avg_weight']),
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
        thisWeekWorkouts: _parseToInt(weekData['workout_count']),
        lastWeekWorkouts: 0, // Non disponibile in questo formato
        thisWeekDuration: _parseToInt(weekData['total_duration']),
        lastWeekDuration: 0, // Non disponibile in questo formato
        improvementPercentage: 0.0, // Non disponibile in questo formato
      );
    }

    // Fallback per formato oggetto
    if (json is Map<String, dynamic>) {
      return WeeklyComparison(
        thisWeekWorkouts: _parseToInt(json['this_week_workouts']),
        lastWeekWorkouts: _parseToInt(json['last_week_workouts']),
        thisWeekDuration: _parseToInt(json['this_week_duration']),
        lastWeekDuration: _parseToInt(json['last_week_duration']),
        improvementPercentage: _parseToDouble(json['improvement_percentage']),
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
  final String period;
  final String startDate;
  final String endDate;
  final int workoutCount;
  final int totalDurationMinutes;
  final int totalSeries;
  final double totalWeightKg;
  final double averageDuration;
  final double? averageDurationMinutes;
  final String? mostActiveDay;

  // ✅ AGGIUNTE: Proprietà premium richieste dal widget
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
    this.averageDurationMinutes,
    this.mostActiveDay,
    this.weeklyDistribution,
    this.muscleGroupsInPeriod,
    this.timelineProgression,
    this.topExercisesInPeriod,
    this.comparisonWithPrevious,
  });

  // ✅ AGGIUNTA: Proprietà richiesta dal widget
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
        return period;
    }
  }

  factory PeriodStats.fromJson(Map<String, dynamic> json) {
    return PeriodStats(
      period: json['period'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      workoutCount: _parseToInt(json['workout_count']),
      totalDurationMinutes: _parseToInt(json['total_duration_minutes']),
      totalSeries: _parseToInt(json['total_series']),
      totalWeightKg: _parseToDouble(json['total_weight_kg']),
      averageDuration: _parseToDouble(json['average_duration']),
      averageDurationMinutes: _parseToDouble(json['average_duration_minutes']),
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

// ✅ AGGIUNTE: Classi premium richieste dal widget
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
      dayNumber: _parseToInt(json['day_number']),
      workoutCount: _parseToInt(json['workout_count']),
      totalDuration: _parseToInt(json['total_duration']),
      avgDuration: _parseToDouble(json['avg_duration']),
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
      sessionsCount: _parseToInt(json['sessions_count']),
      seriesCount: _parseToInt(json['series_count']),
      totalVolume: _parseToDouble(json['total_volume']),
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
      dailyWorkouts: _parseToInt(json['daily_workouts']),
      dailyDuration: _parseToInt(json['daily_duration']),
      dailySeries: _parseToInt(json['daily_series']),
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
      seriesPerformed: _parseToInt(json['series_performed']),
      totalVolume: _parseToDouble(json['total_volume']),
      avgWeight: _parseToDouble(json['avg_weight']),
      maxWeight: _parseToDouble(json['max_weight']),
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
// 🛠️ HELPER FUNCTIONS
// ============================================================================

int _parseToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _parseToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}