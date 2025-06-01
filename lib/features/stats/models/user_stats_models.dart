import 'package:json_annotation/json_annotation.dart';

part 'user_stats_models.g.dart';

/// Rappresenta un elemento nella cronologia degli allenamenti
@JsonSerializable()
class WorkoutHistory {
  final int id;
  @JsonKey(name: 'scheda_id')
  final int schedaId;
  @JsonKey(name: 'data_allenamento')
  final String dataAllenamento;
  @JsonKey(name: 'durata_totale')
  final int? durataTotale;
  final String? note;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'scheda_nome')
  final String? schedaNome;

  const WorkoutHistory({
    required this.id,
    required this.schedaId,
    required this.dataAllenamento,
    this.durataTotale,
    this.note,
    required this.userId,
    this.schedaNome,
  });

  /// Proprietà calcolata per verificare se l'allenamento è completato
  bool get isCompleted => durataTotale != null && durataTotale! > 0;

  /// Proprietà calcolata per la data formattata
  String get formattedDate {
    try {
      final date = DateTime.parse(dataAllenamento);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dataAllenamento;
    }
  }

  /// Proprietà calcolata per la durata formattata
  String get formattedDuration {
    if (durataTotale != null && durataTotale! > 0) {
      final hours = durataTotale! ~/ 60;
      final minutes = durataTotale! % 60;

      if (hours > 0) {
        return '$hours h ${minutes.toString().padLeft(2, '0')} min';
      } else {
        return '$minutes min';
      }
    } else {
      return 'N/D';
    }
  }

  factory WorkoutHistory.fromJson(Map<String, dynamic> json) => _$WorkoutHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutHistoryToJson(this);

  /// Factory method per creare da una mappa con conversioni sicure
  factory WorkoutHistory.fromMap(Map<String, dynamic> map) {
    return WorkoutHistory(
      id: _parseIntSafely(map['id']),
      schedaId: _parseIntSafely(map['scheda_id']),
      dataAllenamento: map['data_allenamento']?.toString() ?? '',
      durataTotale: _parseIntSafelyNullable(map['durata_totale']),
      note: map['note']?.toString(),
      userId: _parseIntSafely(map['user_id']),
      schedaNome: map['scheda_nome']?.toString(),
    );
  }

  static int _parseIntSafely(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _parseIntSafelyNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// Modello per le statistiche dell'utente
@JsonSerializable()
class UserStats {
  // Statistiche di base
  @JsonKey(name: 'total_workouts')
  final int totalWorkouts;
  @JsonKey(name: 'total_hours')
  final int totalHours;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'longest_streak')
  final int longestStreak;
  @JsonKey(name: 'weekly_average')
  final double weeklyAverage;
  @JsonKey(name: 'monthly_average')
  final double monthlyAverage;

  // Esercizi
  @JsonKey(name: 'favorite_exercise')
  final String? favoriteExercise;
  @JsonKey(name: 'total_exercises_performed')
  final int totalExercisesPerformed;
  @JsonKey(name: 'total_sets_completed')
  final int totalSetsCompleted;
  @JsonKey(name: 'total_reps_completed')
  final int totalRepsCompleted;

  // Progressi peso
  @JsonKey(name: 'weight_progress')
  final double? weightProgress;
  @JsonKey(name: 'heaviest_lift')
  final WeightRecord? heaviestLift;

  // Statistiche temporali
  @JsonKey(name: 'average_workout_duration')
  final int averageWorkoutDuration;
  @JsonKey(name: 'best_workout_time')
  final String? bestWorkoutTime;
  @JsonKey(name: 'most_active_day')
  final String? mostActiveDay;

  // Obiettivi e achievement
  @JsonKey(name: 'goals_achieved')
  final int goalsAchieved;
  @JsonKey(name: 'personal_records')
  final List<PersonalRecord> personalRecords;

  // Statistiche recenti (ultimi 30 giorni)
  @JsonKey(name: 'recent_workouts')
  final int recentWorkouts;
  @JsonKey(name: 'recent_improvements')
  final int recentImprovements;

  // Date importanti
  @JsonKey(name: 'first_workout_date')
  final String? firstWorkoutDate;
  @JsonKey(name: 'last_workout_date')
  final String? lastWorkoutDate;

  // Consistenza
  @JsonKey(name: 'consistency_score')
  final double consistencyScore;
  @JsonKey(name: 'workout_frequency')
  final WorkoutFrequency? workoutFrequency;

  const UserStats({
    this.totalWorkouts = 0,
    this.totalHours = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.weeklyAverage = 0.0,
    this.monthlyAverage = 0.0,
    this.favoriteExercise,
    this.totalExercisesPerformed = 0,
    this.totalSetsCompleted = 0,
    this.totalRepsCompleted = 0,
    this.weightProgress,
    this.heaviestLift,
    this.averageWorkoutDuration = 0,
    this.bestWorkoutTime,
    this.mostActiveDay,
    this.goalsAchieved = 0,
    this.personalRecords = const [],
    this.recentWorkouts = 0,
    this.recentImprovements = 0,
    this.firstWorkoutDate,
    this.lastWorkoutDate,
    this.consistencyScore = 0.0,
    this.workoutFrequency,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => _$UserStatsFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatsToJson(this);
}

/// Record di peso per un esercizio specifico
@JsonSerializable()
class WeightRecord {
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  final double weight;
  final int reps;
  final String date;

  const WeightRecord({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.date,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) => _$WeightRecordFromJson(json);
  Map<String, dynamic> toJson() => _$WeightRecordToJson(this);
}

/// Record personale
@JsonSerializable()
class PersonalRecord {
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  final String type; // "max_weight", "max_reps", "max_volume"
  final double value;
  @JsonKey(name: 'date_achieved')
  final String dateAchieved;
  @JsonKey(name: 'previous_record')
  final double? previousRecord;

  const PersonalRecord({
    required this.exerciseName,
    required this.type,
    required this.value,
    required this.dateAchieved,
    this.previousRecord,
  });

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => _$PersonalRecordFromJson(json);
  Map<String, dynamic> toJson() => _$PersonalRecordToJson(this);
}

/// Frequenza degli allenamenti
@JsonSerializable()
class WorkoutFrequency {
  @JsonKey(name: 'weekly_days')
  final Map<String, int> weeklyDays;
  @JsonKey(name: 'monthly_weeks')
  final Map<String, int> monthlyWeeks;
  @JsonKey(name: 'hourly_distribution')
  final Map<String, int> hourlyDistribution; // Cambiato da Map<int, int> per JSON safety

  const WorkoutFrequency({
    this.weeklyDays = const {},
    this.monthlyWeeks = const {},
    this.hourlyDistribution = const {},
  });

  factory WorkoutFrequency.fromJson(Map<String, dynamic> json) => _$WorkoutFrequencyFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutFrequencyToJson(this);
}

/// Risposta API per le statistiche
@JsonSerializable()
class UserStatsResponse {
  final bool success;
  final UserStats? stats;
  final String? message;

  const UserStatsResponse({
    required this.success,
    this.stats,
    this.message,
  });

  factory UserStatsResponse.fromJson(Map<String, dynamic> json) => _$UserStatsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatsResponseToJson(this);
}

/// Statistiche aggregate per periodi specifici
@JsonSerializable()
class PeriodStats {
  @JsonKey(name: 'period_type')
  final String periodType; // "week", "month", "year"
  @JsonKey(name: 'period_label')
  final String periodLabel; // "Questa settimana", "Questo mese", etc.
  @JsonKey(name: 'workouts_count')
  final int workoutsCount;
  @JsonKey(name: 'total_duration')
  final int totalDuration; // in minuti
  @JsonKey(name: 'average_duration')
  final int averageDuration; // in minuti
  @JsonKey(name: 'most_trained_muscle_group')
  final String? mostTrainedMuscleGroup;
  @JsonKey(name: 'improvement_percentage')
  final double? improvementPercentage;
  @JsonKey(name: 'new_records')
  final int newRecords;

  const PeriodStats({
    required this.periodType,
    required this.periodLabel,
    required this.workoutsCount,
    required this.totalDuration,
    required this.averageDuration,
    this.mostTrainedMuscleGroup,
    this.improvementPercentage,
    this.newRecords = 0,
  });

  factory PeriodStats.fromJson(Map<String, dynamic> json) => _$PeriodStatsFromJson(json);
  Map<String, dynamic> toJson() => _$PeriodStatsToJson(this);
}

/// Confronto tra periodi
@JsonSerializable()
class StatsComparison {
  @JsonKey(name: 'current_period')
  final PeriodStats currentPeriod;
  @JsonKey(name: 'previous_period')
  final PeriodStats previousPeriod;
  @JsonKey(name: 'improvement_percentage')
  final double improvementPercentage;
  final String trend; // "improving", "declining", "stable"

  const StatsComparison({
    required this.currentPeriod,
    required this.previousPeriod,
    required this.improvementPercentage,
    required this.trend,
  });

  factory StatsComparison.fromJson(Map<String, dynamic> json) => _$StatsComparisonFromJson(json);
  Map<String, dynamic> toJson() => _$StatsComparisonToJson(this);
}

/// Achievement/Obiettivo
@JsonSerializable()
class Achievement {
  final int id;
  final String name;
  final String description;
  @JsonKey(name: 'icon_name')
  final String iconName;
  @JsonKey(name: 'is_unlocked')
  final bool isUnlocked;
  @JsonKey(name: 'unlock_date')
  final String? unlockDate;
  @JsonKey(name: 'progress_current')
  final int progressCurrent;
  @JsonKey(name: 'progress_target')
  final int progressTarget;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.isUnlocked,
    this.unlockDate,
    this.progressCurrent = 0,
    this.progressTarget = 100,
  });

  /// Calcola la percentuale di progresso
  double get progressPercentage {
    if (progressTarget <= 0) return 0.0;
    return (progressCurrent / progressTarget * 100).clamp(0.0, 100.0);
  }

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementToJson(this);
}

/// Profilo utente
@JsonSerializable()
class UserProfile {
  final int? height;
  final double? weight;
  final int? age;
  final String? gender;
  final String? experienceLevel;
  final String? fitnessGoals;
  final String? injuries;
  final String? preferences;
  final String? notes;

  const UserProfile({
    this.height,
    this.weight,
    this.age,
    this.gender,
    this.experienceLevel,
    this.fitnessGoals,
    this.injuries,
    this.preferences,
    this.notes,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}

/// Informazioni sulla sottoscrizione utente
@JsonSerializable()
class UserSubscriptionInfo {
  final int planId;
  final String planName;
  final bool isActive;
  final String? expiryDate;

  const UserSubscriptionInfo({
    required this.planId,
    required this.planName,
    required this.isActive,
    this.expiryDate,
  });

  factory UserSubscriptionInfo.fromJson(Map<String, dynamic> json) => _$UserSubscriptionInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserSubscriptionInfoToJson(this);
}