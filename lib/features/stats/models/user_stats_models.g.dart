// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_stats_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutHistory _$WorkoutHistoryFromJson(Map<String, dynamic> json) =>
    WorkoutHistory(
      id: (json['id'] as num).toInt(),
      schedaId: (json['scheda_id'] as num).toInt(),
      dataAllenamento: json['data_allenamento'] as String,
      durataTotale: (json['durata_totale'] as num?)?.toInt(),
      note: json['note'] as String?,
      userId: (json['user_id'] as num).toInt(),
      schedaNome: json['scheda_nome'] as String?,
    );

Map<String, dynamic> _$WorkoutHistoryToJson(WorkoutHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scheda_id': instance.schedaId,
      'data_allenamento': instance.dataAllenamento,
      'durata_totale': instance.durataTotale,
      'note': instance.note,
      'user_id': instance.userId,
      'scheda_nome': instance.schedaNome,
    };

UserStats _$UserStatsFromJson(Map<String, dynamic> json) => UserStats(
      totalWorkouts: (json['total_workouts'] as num?)?.toInt() ?? 0,
      totalHours: (json['total_hours'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      weeklyAverage: (json['weekly_average'] as num?)?.toDouble() ?? 0.0,
      monthlyAverage: (json['monthly_average'] as num?)?.toDouble() ?? 0.0,
      favoriteExercise: json['favorite_exercise'] as String?,
      totalExercisesPerformed:
          (json['total_exercises_performed'] as num?)?.toInt() ?? 0,
      totalSetsCompleted: (json['total_sets_completed'] as num?)?.toInt() ?? 0,
      totalRepsCompleted: (json['total_reps_completed'] as num?)?.toInt() ?? 0,
      weightProgress: (json['weight_progress'] as num?)?.toDouble(),
      heaviestLift: json['heaviest_lift'] == null
          ? null
          : WeightRecord.fromJson(
              json['heaviest_lift'] as Map<String, dynamic>),
      averageWorkoutDuration:
          (json['average_workout_duration'] as num?)?.toInt() ?? 0,
      bestWorkoutTime: json['best_workout_time'] as String?,
      mostActiveDay: json['most_active_day'] as String?,
      goalsAchieved: (json['goals_achieved'] as num?)?.toInt() ?? 0,
      personalRecords: (json['personal_records'] as List<dynamic>?)
              ?.map((e) => PersonalRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recentWorkouts: (json['recent_workouts'] as num?)?.toInt() ?? 0,
      recentImprovements: (json['recent_improvements'] as num?)?.toInt() ?? 0,
      firstWorkoutDate: json['first_workout_date'] as String?,
      lastWorkoutDate: json['last_workout_date'] as String?,
      consistencyScore: (json['consistency_score'] as num?)?.toDouble() ?? 0.0,
      workoutFrequency: json['workout_frequency'] == null
          ? null
          : WorkoutFrequency.fromJson(
              json['workout_frequency'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserStatsToJson(UserStats instance) => <String, dynamic>{
      'total_workouts': instance.totalWorkouts,
      'total_hours': instance.totalHours,
      'current_streak': instance.currentStreak,
      'longest_streak': instance.longestStreak,
      'weekly_average': instance.weeklyAverage,
      'monthly_average': instance.monthlyAverage,
      'favorite_exercise': instance.favoriteExercise,
      'total_exercises_performed': instance.totalExercisesPerformed,
      'total_sets_completed': instance.totalSetsCompleted,
      'total_reps_completed': instance.totalRepsCompleted,
      'weight_progress': instance.weightProgress,
      'heaviest_lift': instance.heaviestLift,
      'average_workout_duration': instance.averageWorkoutDuration,
      'best_workout_time': instance.bestWorkoutTime,
      'most_active_day': instance.mostActiveDay,
      'goals_achieved': instance.goalsAchieved,
      'personal_records': instance.personalRecords,
      'recent_workouts': instance.recentWorkouts,
      'recent_improvements': instance.recentImprovements,
      'first_workout_date': instance.firstWorkoutDate,
      'last_workout_date': instance.lastWorkoutDate,
      'consistency_score': instance.consistencyScore,
      'workout_frequency': instance.workoutFrequency,
    };

WeightRecord _$WeightRecordFromJson(Map<String, dynamic> json) => WeightRecord(
      exerciseName: json['exercise_name'] as String,
      weight: (json['weight'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      date: json['date'] as String,
    );

Map<String, dynamic> _$WeightRecordToJson(WeightRecord instance) =>
    <String, dynamic>{
      'exercise_name': instance.exerciseName,
      'weight': instance.weight,
      'reps': instance.reps,
      'date': instance.date,
    };

PersonalRecord _$PersonalRecordFromJson(Map<String, dynamic> json) =>
    PersonalRecord(
      exerciseName: json['exercise_name'] as String,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      dateAchieved: json['date_achieved'] as String,
      previousRecord: (json['previous_record'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PersonalRecordToJson(PersonalRecord instance) =>
    <String, dynamic>{
      'exercise_name': instance.exerciseName,
      'type': instance.type,
      'value': instance.value,
      'date_achieved': instance.dateAchieved,
      'previous_record': instance.previousRecord,
    };

WorkoutFrequency _$WorkoutFrequencyFromJson(Map<String, dynamic> json) =>
    WorkoutFrequency(
      weeklyDays: (json['weekly_days'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      monthlyWeeks: (json['monthly_weeks'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      hourlyDistribution:
          (json['hourly_distribution'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toInt()),
              ) ??
              const {},
    );

Map<String, dynamic> _$WorkoutFrequencyToJson(WorkoutFrequency instance) =>
    <String, dynamic>{
      'weekly_days': instance.weeklyDays,
      'monthly_weeks': instance.monthlyWeeks,
      'hourly_distribution': instance.hourlyDistribution,
    };

UserStatsResponse _$UserStatsResponseFromJson(Map<String, dynamic> json) =>
    UserStatsResponse(
      success: json['success'] as bool,
      stats: json['stats'] == null
          ? null
          : UserStats.fromJson(json['stats'] as Map<String, dynamic>),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$UserStatsResponseToJson(UserStatsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'stats': instance.stats,
      'message': instance.message,
    };

PeriodStats _$PeriodStatsFromJson(Map<String, dynamic> json) => PeriodStats(
      periodType: json['period_type'] as String,
      periodLabel: json['period_label'] as String,
      workoutsCount: (json['workouts_count'] as num).toInt(),
      totalDuration: (json['total_duration'] as num).toInt(),
      averageDuration: (json['average_duration'] as num).toInt(),
      mostTrainedMuscleGroup: json['most_trained_muscle_group'] as String?,
      improvementPercentage:
          (json['improvement_percentage'] as num?)?.toDouble(),
      newRecords: (json['new_records'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PeriodStatsToJson(PeriodStats instance) =>
    <String, dynamic>{
      'period_type': instance.periodType,
      'period_label': instance.periodLabel,
      'workouts_count': instance.workoutsCount,
      'total_duration': instance.totalDuration,
      'average_duration': instance.averageDuration,
      'most_trained_muscle_group': instance.mostTrainedMuscleGroup,
      'improvement_percentage': instance.improvementPercentage,
      'new_records': instance.newRecords,
    };

StatsComparison _$StatsComparisonFromJson(Map<String, dynamic> json) =>
    StatsComparison(
      currentPeriod:
          PeriodStats.fromJson(json['current_period'] as Map<String, dynamic>),
      previousPeriod:
          PeriodStats.fromJson(json['previous_period'] as Map<String, dynamic>),
      improvementPercentage: (json['improvement_percentage'] as num).toDouble(),
      trend: json['trend'] as String,
    );

Map<String, dynamic> _$StatsComparisonToJson(StatsComparison instance) =>
    <String, dynamic>{
      'current_period': instance.currentPeriod,
      'previous_period': instance.previousPeriod,
      'improvement_percentage': instance.improvementPercentage,
      'trend': instance.trend,
    };

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String,
      isUnlocked: json['is_unlocked'] as bool,
      unlockDate: json['unlock_date'] as String?,
      progressCurrent: (json['progress_current'] as num?)?.toInt() ?? 0,
      progressTarget: (json['progress_target'] as num?)?.toInt() ?? 100,
    );

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon_name': instance.iconName,
      'is_unlocked': instance.isUnlocked,
      'unlock_date': instance.unlockDate,
      'progress_current': instance.progressCurrent,
      'progress_target': instance.progressTarget,
    };

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      height: (json['height'] as num?)?.toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
      age: (json['age'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      experienceLevel: json['experienceLevel'] as String?,
      fitnessGoals: json['fitnessGoals'] as String?,
      injuries: json['injuries'] as String?,
      preferences: json['preferences'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'height': instance.height,
      'weight': instance.weight,
      'age': instance.age,
      'gender': instance.gender,
      'experienceLevel': instance.experienceLevel,
      'fitnessGoals': instance.fitnessGoals,
      'injuries': instance.injuries,
      'preferences': instance.preferences,
      'notes': instance.notes,
    };

UserSubscriptionInfo _$UserSubscriptionInfoFromJson(
        Map<String, dynamic> json) =>
    UserSubscriptionInfo(
      planId: (json['planId'] as num).toInt(),
      planName: json['planName'] as String,
      isActive: json['isActive'] as bool,
      expiryDate: json['expiryDate'] as String?,
    );

Map<String, dynamic> _$UserSubscriptionInfoToJson(
        UserSubscriptionInfo instance) =>
    <String, dynamic>{
      'planId': instance.planId,
      'planName': instance.planName,
      'isActive': instance.isActive,
      'expiryDate': instance.expiryDate,
    };
