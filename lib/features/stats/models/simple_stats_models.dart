// lib/features/stats/models/simple_stats_models.dart

/// 🎯 Fitness Score - Punteggio Fitness Completo
class FitnessScore {
  final double strength;      // 0-100 - Forza
  final double consistency;   // 0-100 - Costanza
  final double progression;   // 0-100 - Progressione
  final double balance;       // 0-100 - Equilibrio muscolare
  final double overall;       // 0-100 - Punteggio generale

  const FitnessScore({
    required this.strength,
    required this.consistency,
    required this.progression,
    required this.balance,
    required this.overall,
  });

  /// Ottiene il colore del punteggio
  String get scoreColor {
    if (overall >= 80) return 'excellent';
    if (overall >= 60) return 'good';
    if (overall >= 40) return 'average';
    return 'poor';
  }

  /// Ottiene la descrizione del punteggio
  String get scoreDescription {
    if (overall >= 80) return 'Eccellente';
    if (overall >= 60) return 'Buono';
    if (overall >= 40) return 'Nella media';
    return 'Da migliorare';
  }
}

/// 📊 KPI Card - Card per Metriche Principali
class KPICard {
  final String title;
  final String value;
  final String? subtitle;
  final String icon;
  final String color;
  final double? trend;        // Percentuale di trend
  final String? trendLabel;   // Etichetta del trend
  final bool isPositive;      // Se il trend è positivo

  const KPICard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
    this.trendLabel,
    this.isPositive = true,
  });
}

/// 🧠 Smart Insight - Insight Intelligente
class SmartInsight {
  final String id;
  final String title;
  final String description;
  final String type;          // 'achievement', 'recommendation', 'warning', 'tip'
  final String icon;
  final String color;
  final int priority;         // 1-5, 5 = più importante
  final DateTime createdAt;
  final bool isRead;

  const SmartInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.icon,
    required this.color,
    required this.priority,
    required this.createdAt,
    this.isRead = false,
  });
}

/// 🏆 Achievement - Achievement/Badge
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String color;
  final String category;      // 'strength', 'consistency', 'endurance', 'variety'
  final int points;           // Punti per l'achievement
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress;      // 0.0 - 1.0

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.points,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0.0,
  });
}

/// 📈 Muscle Group Analysis - Analisi Gruppo Muscolare
class MuscleGroupAnalysis {
  final String name;
  final String displayName;
  final int sessionsCount;
  final int totalSeries;
  final double totalVolume;
  final double averageIntensity;
  final double balanceScore;  // 0-100, quanto è bilanciato
  final List<String> topExercises;
  final String recommendation;

  const MuscleGroupAnalysis({
    required this.name,
    required this.displayName,
    required this.sessionsCount,
    required this.totalSeries,
    required this.totalVolume,
    required this.averageIntensity,
    required this.balanceScore,
    required this.topExercises,
    required this.recommendation,
  });
}

/// 📊 Exercise Progress - Progresso Esercizio
class ExerciseProgress {
  final String exerciseName;
  final String muscleGroup;
  final double currentMaxWeight;
  final double previousMaxWeight;
  final double improvementPercentage;
  final int totalSessions;
  final double averageVolume;
  final String trend;         // 'improving', 'stable', 'declining'
  final List<ProgressDataPoint> history;

  const ExerciseProgress({
    required this.exerciseName,
    required this.muscleGroup,
    required this.currentMaxWeight,
    required this.previousMaxWeight,
    required this.improvementPercentage,
    required this.totalSessions,
    required this.averageVolume,
    required this.trend,
    required this.history,
  });
}

/// 📅 Progress Data Point - Punto Dati Progresso
class ProgressDataPoint {
  final DateTime date;
  final double weight;
  final int reps;
  final double volume;
  final int sets;

  const ProgressDataPoint({
    required this.date,
    required this.weight,
    required this.reps,
    required this.volume,
    required this.sets,
  });
}

/// 🎯 Workout Pattern - Pattern di Allenamento
class WorkoutPattern {
  final String patternType;   // 'frequency', 'intensity', 'duration', 'volume'
  final String description;
  final String insight;
  final String recommendation;
  final double confidence;    // 0.0 - 1.0, quanto è affidabile il pattern

  const WorkoutPattern({
    required this.patternType,
    required this.description,
    required this.insight,
    required this.recommendation,
    required this.confidence,
  });
}

/// 📊 Weekly Summary - Riepilogo Settimanale
class WeeklySummary {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalWorkouts;
  final double totalDuration;
  final double totalVolume;
  final double averageIntensity;
  final List<String> topMuscleGroups;
  final List<String> topExercises;
  final double improvementPercentage;
  final String summary;

  const WeeklySummary({
    required this.weekStart,
    required this.weekEnd,
    required this.totalWorkouts,
    required this.totalDuration,
    required this.totalVolume,
    required this.averageIntensity,
    required this.topMuscleGroups,
    required this.topExercises,
    required this.improvementPercentage,
    required this.summary,
  });
}

/// 🎯 Goal - Obiettivo
class Goal {
  final String id;
  final String title;
  final String description;
  final String type;          // 'workout_frequency', 'weight_lifted', 'strength_gain', 'endurance'
  final double targetValue;
  final double currentValue;
  final DateTime targetDate;
  final DateTime createdAt;
  final bool isCompleted;
  final double progress;      // 0.0 - 1.0

  const Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.targetDate,
    required this.createdAt,
    this.isCompleted = false,
    this.progress = 0.0,
  });
}

/// 📊 Advanced User Stats - Statistiche Utente Avanzate
class AdvancedUserStats {
  final FitnessScore fitnessScore;
  final List<KPICard> kpiCards;
  final List<SmartInsight> insights;
  final List<Achievement> achievements;
  final List<MuscleGroupAnalysis> muscleGroups;
  final List<ExerciseProgress> exerciseProgress;
  final List<WorkoutPattern> patterns;
  final WeeklySummary? weeklySummary;
  final List<Goal> goals;
  final bool isPremium;

  const AdvancedUserStats({
    required this.fitnessScore,
    required this.kpiCards,
    required this.insights,
    required this.achievements,
    required this.muscleGroups,
    required this.exerciseProgress,
    required this.patterns,
    this.weeklySummary,
    required this.goals,
    required this.isPremium,
  });
}
