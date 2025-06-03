// lib/features/stats/models/user_stats_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'user_stats_models.g.dart';

/// Statistiche generali dell'utente
@JsonSerializable()
class UserStats {
  @JsonKey(name: 'total_workouts')
  final int totalWorkouts;
  @JsonKey(name: 'total_duration_minutes')
  final int totalDurationMinutes;
  @JsonKey(name: 'total_series')
  final int totalSeries;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'longest_streak')
  final int longestStreak;
  @JsonKey(name: 'workouts_this_week')
  final int workoutsThisWeek;
  @JsonKey(name: 'workouts_this_month')
  final int workoutsThisMonth;
  @JsonKey(name: 'average_workout_duration')
  final double averageWorkoutDuration;
  @JsonKey(name: 'most_trained_muscle_group')
  final String? mostTrainedMuscleGroup;
  @JsonKey(name: 'favorite_exercise')
  final String? favoriteExercise;
  @JsonKey(name: 'total_weight_lifted_kg')
  final double totalWeightLiftedKg;
  @JsonKey(name: 'first_workout_date')
  final String? firstWorkoutDate;
  @JsonKey(name: 'last_workout_date')
  final String? lastWorkoutDate;

  const UserStats({
    required this.totalWorkouts,
    required this.totalDurationMinutes,
    required this.totalSeries,
    required this.currentStreak,
    required this.longestStreak,
    required this.workoutsThisWeek,
    required this.workoutsThisMonth,
    required this.averageWorkoutDuration,
    this.mostTrainedMuscleGroup,
    this.favoriteExercise,
    required this.totalWeightLiftedKg,
    this.firstWorkoutDate,
    this.lastWorkoutDate,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);

  Map<String, dynamic> toJson() => _$UserStatsToJson(this);

  /// Durata totale formattata in ore e minuti
  String get formattedTotalDuration {
    final hours = totalDurationMinutes ~/ 60;
    final minutes = totalDurationMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Durata media formattata
  String get formattedAverageDuration {
    final avgMinutes = averageWorkoutDuration.round();
    final hours = avgMinutes ~/ 60;
    final minutes = avgMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Peso totale formattato
  String get formattedTotalWeight {
    if (totalWeightLiftedKg >= 1000) {
      return '${(totalWeightLiftedKg / 1000).toStringAsFixed(1)}t';
    } else {
      return '${totalWeightLiftedKg.toStringAsFixed(0)}kg';
    }
  }
}

/// Statistiche per periodo specifico
@JsonSerializable()
class PeriodStats {
  final String period; // 'week', 'month', 'year'
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'end_date')
  final String endDate;
  @JsonKey(name: 'workout_count')
  final int workoutCount;
  @JsonKey(name: 'total_duration_minutes')
  final int totalDurationMinutes;
  @JsonKey(name: 'total_series')
  final int totalSeries;
  @JsonKey(name: 'total_weight_kg')
  final double totalWeightKg;
  @JsonKey(name: 'average_duration')
  final double averageDuration;
  @JsonKey(name: 'most_active_day')
  final String? mostActiveDay;
  @JsonKey(name: 'workout_frequency')
  final double workoutFrequency; // allenamenti per settimana

  const PeriodStats({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.workoutCount,
    required this.totalDurationMinutes,
    required this.totalSeries,
    required this.totalWeightKg,
    required this.averageDuration,
    this.mostActiveDay,
    required this.workoutFrequency,
  });

  factory PeriodStats.fromJson(Map<String, dynamic> json) =>
      _$PeriodStatsFromJson(json);

  Map<String, dynamic> toJson() => _$PeriodStatsToJson(this);
}

/// Cronologia allenamenti
@JsonSerializable()
class WorkoutHistory {
  final int id;
  @JsonKey(name: 'scheda_id')
  final int schedaId;
  @JsonKey(name: 'scheda_nome')
  final String schedaNome;
  @JsonKey(name: 'data_allenamento')
  final String dataAllenamento;
  @JsonKey(name: 'durata_minuti')
  final int durataMinuti;
  @JsonKey(name: 'serie_completate')
  final int serieCompletate;
  @JsonKey(name: 'peso_totale_kg')
  final double pesoTotaleKg;
  final String? note;
  @JsonKey(name: 'esercizi_completati')
  final int eserciziCompletati;
  @JsonKey(name: 'esercizi_totali')
  final int eserciziTotali;

  const WorkoutHistory({
    required this.id,
    required this.schedaId,
    required this.schedaNome,
    required this.dataAllenamento,
    required this.durataMinuti,
    required this.serieCompletate,
    required this.pesoTotaleKg,
    this.note,
    required this.eserciziCompletati,
    required this.eserciziTotali,
  });

  factory WorkoutHistory.fromJson(Map<String, dynamic> json) =>
      _$WorkoutHistoryFromJson(json);

  factory WorkoutHistory.fromMap(Map<String, dynamic> map) =>
      WorkoutHistory.fromJson(map);

  Map<String, dynamic> toJson() => _$WorkoutHistoryToJson(this);

  /// Percentuale di completamento
  double get completionPercentage {
    if (eserciziTotali == 0) return 0.0;
    return (eserciziCompletati / eserciziTotali) * 100;
  }

  /// Indica se l'allenamento è stato completato
  bool get isCompleted => eserciziCompletati == eserciziTotali;

  /// Durata formattata
  String get formattedDuration {
    final hours = durataMinuti ~/ 60;
    final minutes = durataMinuti % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Data formattata
  String get formattedDate {
    try {
      final date = DateTime.parse(dataAllenamento);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dataAllenamento;
    }
  }
}

/// Progresso su un esercizio specifico
@JsonSerializable()
class ExerciseProgress {
  @JsonKey(name: 'exercise_id')
  final int exerciseId;
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  @JsonKey(name: 'first_workout_date')
  final String firstWorkoutDate;
  @JsonKey(name: 'last_workout_date')
  final String lastWorkoutDate;
  @JsonKey(name: 'total_sessions')
  final int totalSessions;
  @JsonKey(name: 'total_series')
  final int totalSeries;
  @JsonKey(name: 'max_weight_kg')
  final double maxWeightKg;
  @JsonKey(name: 'max_reps')
  final int maxReps;
  @JsonKey(name: 'average_weight_kg')
  final double averageWeightKg;
  @JsonKey(name: 'average_reps')
  final double averageReps;
  @JsonKey(name: 'total_volume_kg')
  final double totalVolumeKg;
  @JsonKey(name: 'improvement_percentage')
  final double improvementPercentage;

  const ExerciseProgress({
    required this.exerciseId,
    required this.exerciseName,
    required this.firstWorkoutDate,
    required this.lastWorkoutDate,
    required this.totalSessions,
    required this.totalSeries,
    required this.maxWeightKg,
    required this.maxReps,
    required this.averageWeightKg,
    required this.averageReps,
    required this.totalVolumeKg,
    required this.improvementPercentage,
  });

  factory ExerciseProgress.fromJson(Map<String, dynamic> json) =>
      _$ExerciseProgressFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseProgressToJson(this);

  /// Indica se c'è stato miglioramento
  bool get hasImprovement => improvementPercentage > 0;

  /// Volume medio per sessione
  double get averageVolumePerSession {
    if (totalSessions == 0) return 0.0;
    return totalVolumeKg / totalSessions;
  }
}

/// Dati per grafico progresso
@JsonSerializable()
class ProgressDataPoint {
  final String date;
  final double weight;
  final int reps;
  final double volume; // peso * reps

  const ProgressDataPoint({
    required this.date,
    required this.weight,
    required this.reps,
    required this.volume,
  });

  factory ProgressDataPoint.fromJson(Map<String, dynamic> json) =>
      _$ProgressDataPointFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressDataPointToJson(this);
}

/// Risposta API per le statistiche
@JsonSerializable()
class StatsResponse {
  final bool success;
  final String message;
  final UserStats? stats;

  const StatsResponse({
    required this.success,
    required this.message,
    this.stats,
  });

  factory StatsResponse.fromJson(Map<String, dynamic> json) =>
      _$StatsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StatsResponseToJson(this);
}