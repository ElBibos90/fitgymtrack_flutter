// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_stats_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserStats _$UserStatsFromJson(Map<String, dynamic> json) => UserStats(
      totalWorkouts: (json['total_workouts'] as num).toInt(),
      totalDurationMinutes: (json['total_duration_minutes'] as num).toInt(),
      totalSeries: (json['total_series'] as num).toInt(),
      currentStreak: (json['current_streak'] as num).toInt(),
      longestStreak: (json['longest_streak'] as num).toInt(),
      workoutsThisWeek: (json['workouts_this_week'] as num).toInt(),
      workoutsThisMonth: (json['workouts_this_month'] as num).toInt(),
      averageWorkoutDuration:
          (json['average_workout_duration'] as num).toDouble(),
      mostTrainedMuscleGroup: json['most_trained_muscle_group'] as String?,
      favoriteExercise: json['favorite_exercise'] as String?,
      totalWeightLiftedKg: (json['total_weight_lifted_kg'] as num).toDouble(),
      firstWorkoutDate: json['first_workout_date'] as String?,
      lastWorkoutDate: json['last_workout_date'] as String?,
      mostTrainedMuscle: json['most_trained_muscle'] == null
          ? null
          : MostTrainedMuscle.fromJson(
              json['most_trained_muscle'] as Map<String, dynamic>),
      muscleDistribution: (json['muscle_distribution'] as List<dynamic>?)
          ?.map((e) => MuscleDistribution.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserStatsToJson(UserStats instance) => <String, dynamic>{
      'total_workouts': instance.totalWorkouts,
      'total_duration_minutes': instance.totalDurationMinutes,
      'total_series': instance.totalSeries,
      'current_streak': instance.currentStreak,
      'longest_streak': instance.longestStreak,
      'workouts_this_week': instance.workoutsThisWeek,
      'workouts_this_month': instance.workoutsThisMonth,
      'average_workout_duration': instance.averageWorkoutDuration,
      'most_trained_muscle_group': instance.mostTrainedMuscleGroup,
      'favorite_exercise': instance.favoriteExercise,
      'total_weight_lifted_kg': instance.totalWeightLiftedKg,
      'first_workout_date': instance.firstWorkoutDate,
      'last_workout_date': instance.lastWorkoutDate,
      'most_trained_muscle': instance.mostTrainedMuscle,
      'muscle_distribution': instance.muscleDistribution,
    };

PeriodStats _$PeriodStatsFromJson(Map<String, dynamic> json) => PeriodStats(
      period: json['period'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      workoutCount: (json['workout_count'] as num).toInt(),
      totalDurationMinutes: (json['total_duration_minutes'] as num).toInt(),
      totalSeries: (json['total_series'] as num).toInt(),
      totalWeightKg: (json['total_weight_kg'] as num).toDouble(),
      averageDuration: (json['average_duration'] as num).toDouble(),
      mostActiveDay: json['most_active_day'] as String?,
      workoutFrequency: (json['workout_frequency'] as num).toDouble(),
      muscleDistributionPeriod:
          (json['muscle_distribution_period'] as List<dynamic>?)
              ?.map((e) =>
                  MuscleDistributionPeriod.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$PeriodStatsToJson(PeriodStats instance) =>
    <String, dynamic>{
      'period': instance.period,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'workout_count': instance.workoutCount,
      'total_duration_minutes': instance.totalDurationMinutes,
      'total_series': instance.totalSeries,
      'total_weight_kg': instance.totalWeightKg,
      'average_duration': instance.averageDuration,
      'most_active_day': instance.mostActiveDay,
      'workout_frequency': instance.workoutFrequency,
      'muscle_distribution_period': instance.muscleDistributionPeriod,
    };

WorkoutHistory _$WorkoutHistoryFromJson(Map<String, dynamic> json) =>
    WorkoutHistory(
      id: (json['id'] as num).toInt(),
      schedaId: (json['scheda_id'] as num).toInt(),
      schedaNome: json['scheda_nome'] as String,
      dataAllenamento: json['data_allenamento'] as String,
      durataMinuti: _parseIntSafe(json['durata_minuti']),
      serieCompletate: _parseIntSafe(json['serie_completate']),
      pesoTotaleKg: _parseDoubleSafe(json['peso_totale_kg']),
      note: json['note'] as String?,
      eserciziCompletati: _parseIntSafe(json['esercizi_completati']),
      eserciziTotali: _parseIntSafe(json['esercizi_totali']),
    );

Map<String, dynamic> _$WorkoutHistoryToJson(WorkoutHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scheda_id': instance.schedaId,
      'scheda_nome': instance.schedaNome,
      'data_allenamento': instance.dataAllenamento,
      'durata_minuti': instance.durataMinuti,
      'serie_completate': instance.serieCompletate,
      'peso_totale_kg': instance.pesoTotaleKg,
      'note': instance.note,
      'esercizi_completati': instance.eserciziCompletati,
      'esercizi_totali': instance.eserciziTotali,
    };

ExerciseProgress _$ExerciseProgressFromJson(Map<String, dynamic> json) =>
    ExerciseProgress(
      exerciseId: (json['exercise_id'] as num).toInt(),
      exerciseName: json['exercise_name'] as String,
      firstWorkoutDate: json['first_workout_date'] as String,
      lastWorkoutDate: json['last_workout_date'] as String,
      totalSessions: (json['total_sessions'] as num).toInt(),
      totalSeries: (json['total_series'] as num).toInt(),
      maxWeightKg: (json['max_weight_kg'] as num).toDouble(),
      maxReps: (json['max_reps'] as num).toInt(),
      averageWeightKg: (json['average_weight_kg'] as num).toDouble(),
      averageReps: (json['average_reps'] as num).toDouble(),
      totalVolumeKg: (json['total_volume_kg'] as num).toDouble(),
      improvementPercentage: (json['improvement_percentage'] as num).toDouble(),
    );

Map<String, dynamic> _$ExerciseProgressToJson(ExerciseProgress instance) =>
    <String, dynamic>{
      'exercise_id': instance.exerciseId,
      'exercise_name': instance.exerciseName,
      'first_workout_date': instance.firstWorkoutDate,
      'last_workout_date': instance.lastWorkoutDate,
      'total_sessions': instance.totalSessions,
      'total_series': instance.totalSeries,
      'max_weight_kg': instance.maxWeightKg,
      'max_reps': instance.maxReps,
      'average_weight_kg': instance.averageWeightKg,
      'average_reps': instance.averageReps,
      'total_volume_kg': instance.totalVolumeKg,
      'improvement_percentage': instance.improvementPercentage,
    };

ProgressDataPoint _$ProgressDataPointFromJson(Map<String, dynamic> json) =>
    ProgressDataPoint(
      date: json['date'] as String,
      weight: (json['weight'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      volume: (json['volume'] as num).toDouble(),
    );

Map<String, dynamic> _$ProgressDataPointToJson(ProgressDataPoint instance) =>
    <String, dynamic>{
      'date': instance.date,
      'weight': instance.weight,
      'reps': instance.reps,
      'volume': instance.volume,
    };

StatsResponse _$StatsResponseFromJson(Map<String, dynamic> json) =>
    StatsResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      stats: json['stats'] == null
          ? null
          : UserStats.fromJson(json['stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StatsResponseToJson(StatsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'stats': instance.stats,
    };

MostTrainedMuscle _$MostTrainedMuscleFromJson(Map<String, dynamic> json) =>
    MostTrainedMuscle(
      name: json['name'] as String,
      category: json['category'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$MostTrainedMuscleToJson(MostTrainedMuscle instance) =>
    <String, dynamic>{
      'name': instance.name,
      'category': instance.category,
      'count': instance.count,
    };

MuscleDistribution _$MuscleDistributionFromJson(Map<String, dynamic> json) =>
    MuscleDistribution(
      muscleName: json['muscle_name'] as String,
      muscleCategory: json['muscle_category'] as String,
      seriesCount: (json['series_count'] as num).toInt(),
      exercisesCount: (json['exercises_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MuscleDistributionToJson(MuscleDistribution instance) =>
    <String, dynamic>{
      'muscle_name': instance.muscleName,
      'muscle_category': instance.muscleCategory,
      'series_count': instance.seriesCount,
      'exercises_count': instance.exercisesCount,
    };

MuscleDistributionPeriod _$MuscleDistributionPeriodFromJson(
        Map<String, dynamic> json) =>
    MuscleDistributionPeriod(
      muscleName: json['muscle_name'] as String,
      muscleCategory: json['muscle_category'] as String,
      sessionsCount: (json['sessions_count'] as num).toInt(),
      seriesCount: (json['series_count'] as num).toInt(),
      totalVolume: (json['total_volume'] as num?)?.toDouble(),
      exercisesCount: (json['exercises_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MuscleDistributionPeriodToJson(
        MuscleDistributionPeriod instance) =>
    <String, dynamic>{
      'muscle_name': instance.muscleName,
      'muscle_category': instance.muscleCategory,
      'sessions_count': instance.sessionsCount,
      'series_count': instance.seriesCount,
      'total_volume': instance.totalVolume,
      'exercises_count': instance.exercisesCount,
    };
