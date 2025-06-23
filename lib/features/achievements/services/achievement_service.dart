// lib/features/achievements/services/achievement_service.dart

import 'package:flutter/material.dart';
import '../models/achievement_models.dart';

/// Service per gestire gli achievement
class AchievementService {

  /// Genera gli achievement di base basati sui dati dell'utente
  static List<Achievement> getBasicAchievements({
    required int workoutCount,
    int profileCompleteness = 0,
    int currentStreak = 0,
    double maxWeight = 0,
    int totalMinutes = 0,
  }) {
    return [
      // ============================================================================
      // ACHIEVEMENT ALLENAMENTI
      // ============================================================================

      Achievement(
        id: 'first_workout',
        title: 'Primo Passo',
        description: 'Completa il tuo primo allenamento',
        icon: Icons.play_circle_fill,
        iconEmoji: '🎯',
        color: Colors.green,
        type: AchievementType.workoutCount,
        targetValue: 1,
        currentValue: workoutCount,
        isUnlocked: workoutCount >= 1,
        points: 10,
      ),

      Achievement(
        id: 'workout_5',
        title: 'In Movimento',
        description: 'Completa 5 allenamenti',
        icon: Icons.fitness_center,
        iconEmoji: '💪',
        color: Colors.blue,
        type: AchievementType.workoutCount,
        targetValue: 5,
        currentValue: workoutCount,
        isUnlocked: workoutCount >= 5,
        points: 25,
      ),

      Achievement(
        id: 'workout_10',
        title: 'Dedizione',
        description: 'Completa 10 allenamenti',
        icon: Icons.local_fire_department,
        iconEmoji: '🔥',
        color: Colors.orange,
        type: AchievementType.workoutCount,
        targetValue: 10,
        currentValue: workoutCount,
        isUnlocked: workoutCount >= 10,
        points: 50,
      ),

      Achievement(
        id: 'workout_25',
        title: 'Guerriero',
        description: 'Completa 25 allenamenti',
        icon: Icons.military_tech,
        iconEmoji: '🏆',
        color: Colors.purple,
        type: AchievementType.workoutCount,
        targetValue: 25,
        currentValue: workoutCount,
        isUnlocked: workoutCount >= 25,
        points: 100,
      ),

      Achievement(
        id: 'workout_50',
        title: 'Veterano',
        description: 'Completa 50 allenamenti',
        icon: Icons.emoji_events,
        iconEmoji: '👑',
        color: Colors.amber,
        type: AchievementType.workoutCount,
        targetValue: 50,
        currentValue: workoutCount,
        isUnlocked: workoutCount >= 50,
        points: 200,
      ),

      // ============================================================================
      // ACHIEVEMENT PROFILO
      // ============================================================================

      Achievement(
        id: 'profile_basic',
        title: 'Chi Sei?',
        description: 'Completa le informazioni di base del profilo',
        icon: Icons.person,
        iconEmoji: '👤',
        color: Colors.teal,
        type: AchievementType.profileComplete,
        targetValue: 50,
        currentValue: profileCompleteness,
        isUnlocked: profileCompleteness >= 50,
        points: 15,
      ),

      Achievement(
        id: 'profile_complete',
        title: 'Profilo Perfetto',
        description: 'Completa tutte le informazioni del profilo',
        icon: Icons.verified_user,
        iconEmoji: '✅',
        color: Colors.green.shade700,
        type: AchievementType.profileComplete,
        targetValue: 100,
        currentValue: profileCompleteness,
        isUnlocked: profileCompleteness >= 100,
        points: 30,
      ),

      // ============================================================================
      // ACHIEVEMENT COSTANZA
      // ============================================================================

      Achievement(
        id: 'streak_3',
        title: 'Buona Abitudine',
        description: 'Mantieni una streak di 3 giorni',
        icon: Icons.whatshot,
        iconEmoji: '🔥',
        color: Colors.red,
        type: AchievementType.streak,
        targetValue: 3,
        currentValue: currentStreak,
        isUnlocked: currentStreak >= 3,
        points: 20,
      ),

      Achievement(
        id: 'streak_7',
        title: 'Una Settimana di Fuoco',
        description: 'Mantieni una streak di 7 giorni',
        icon: Icons.local_fire_department,
        iconEmoji: '🔥',
        color: Colors.deepOrange,
        type: AchievementType.streak,
        targetValue: 7,
        currentValue: currentStreak,
        isUnlocked: currentStreak >= 7,
        points: 50,
      ),

      Achievement(
        id: 'streak_30',
        title: 'Mese Perfetto',
        description: 'Mantieni una streak di 30 giorni',
        icon: Icons.celebration,
        iconEmoji: '🎉',
        color: Colors.pink,
        type: AchievementType.streak,
        targetValue: 30,
        currentValue: currentStreak,
        isUnlocked: currentStreak >= 30,
        points: 150,
      ),

      // ============================================================================
      // ACHIEVEMENT PESO/FORZA
      // ============================================================================

      Achievement(
        id: 'weight_100',
        title: 'Centone',
        description: 'Solleva 100kg in un singolo esercizio',
        icon: Icons.fitness_center,
        iconEmoji: '💯',
        color: Colors.indigo,
        type: AchievementType.weight,
        targetValue: 100,
        currentValue: maxWeight.round(),
        isUnlocked: maxWeight >= 100,
        points: 75,
      ),

      Achievement(
        id: 'weight_150',
        title: 'Bestia',
        description: 'Solleva 150kg in un singolo esercizio',
        icon: Icons.psychology,
        iconEmoji: '🦍',
        color: Colors.brown,
        type: AchievementType.weight,
        targetValue: 150,
        currentValue: maxWeight.round(),
        isUnlocked: maxWeight >= 150,
        points: 150,
      ),

      // ============================================================================
      // ACHIEVEMENT TEMPO
      // ============================================================================

      Achievement(
        id: 'time_10h',
        title: 'Primo Impegno',
        description: 'Accumula 10 ore di allenamento totali',
        icon: Icons.schedule,
        iconEmoji: '⏰',
        color: Colors.cyan,
        type: AchievementType.time,
        targetValue: 600, // 10 ore in minuti
        currentValue: totalMinutes,
        isUnlocked: totalMinutes >= 600,
        points: 40,
      ),

      Achievement(
        id: 'time_50h',
        title: 'Esperto del Tempo',
        description: 'Accumula 50 ore di allenamento totali',
        icon: Icons.timer,
        iconEmoji: '⏱️',
        color: Colors.lightBlue,
        type: AchievementType.time,
        targetValue: 3000, // 50 ore in minuti
        currentValue: totalMinutes,
        isUnlocked: totalMinutes >= 3000,
        points: 125,
      ),
    ];
  }

  /// Organizza gli achievement per categorie
  static List<AchievementCategory> organizeByCategories(List<Achievement> achievements) {
    final Map<AchievementType, List<Achievement>> grouped = {};

    for (final achievement in achievements) {
      grouped.putIfAbsent(achievement.type, () => []).add(achievement);
    }

    return grouped.entries.map((entry) {
      return AchievementCategory(
        id: entry.key.name,
        name: entry.key.displayName,
        description: _getCategoryDescription(entry.key),
        icon: _getCategoryIcon(entry.key),
        color: _getCategoryColor(entry.key),
        achievements: entry.value..sort((a, b) => a.targetValue.compareTo(b.targetValue)),
      );
    }).toList();
  }

  /// Calcola le statistiche generali
  static AchievementStats calculateStats(List<Achievement> achievements) {
    final unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();
    final totalPoints = unlockedAchievements.fold(0, (sum, a) => sum + a.points);
    final completionPercentage = achievements.isNotEmpty
        ? (unlockedAchievements.length / achievements.length) * 100
        : 0.0;

    // Trova l'achievement sbloccato più recente
    Achievement? latestUnlocked;
    if (unlockedAchievements.isNotEmpty) {
      latestUnlocked = unlockedAchievements
          .where((a) => a.unlockedAt != null)
          .fold<Achievement?>(null, (latest, current) {
        if (latest == null) return current;
        if (current.unlockedAt!.isAfter(latest.unlockedAt!)) return current;
        return latest;
      });
    }

    return AchievementStats(
      totalAchievements: achievements.length,
      unlockedAchievements: unlockedAchievements.length,
      totalPoints: totalPoints,
      completionPercentage: completionPercentage,
      latestUnlocked: latestUnlocked,
      categories: organizeByCategories(achievements),
    );
  }

  /// Simula il calcolo della completezza del profilo
  static int calculateProfileCompleteness({
    bool hasHeight = false,
    bool hasWeight = false,
    bool hasAge = false,
    bool hasGender = false,
    bool hasExperienceLevel = false,
    bool hasFitnessGoals = false,
    bool hasPreferences = false,
  }) {
    int completeness = 0;

    if (hasHeight) completeness += 15;
    if (hasWeight) completeness += 15;
    if (hasAge) completeness += 10;
    if (hasGender) completeness += 10;
    if (hasExperienceLevel) completeness += 20;
    if (hasFitnessGoals) completeness += 15;
    if (hasPreferences) completeness += 15;

    return completeness.clamp(0, 100);
  }

  /// Filtra achievement per tipo
  static List<Achievement> filterByType(List<Achievement> achievements, AchievementType type) {
    return achievements.where((a) => a.type == type).toList();
  }

  /// Trova achievement prossimi al completamento
  static List<Achievement> getAlmostCompleted(List<Achievement> achievements, {double threshold = 0.8}) {
    return achievements
        .where((a) => !a.isUnlocked && a.progress >= threshold)
        .toList();
  }

  /// Cerca achievement per query
  static List<Achievement> searchAchievements(List<Achievement> achievements, String query) {
    final lowerQuery = query.toLowerCase();
    return achievements.where((a) {
      return a.title.toLowerCase().contains(lowerQuery) ||
          a.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // ============================================================================
  // HELPERS PRIVATI
  // ============================================================================

  static String _getCategoryDescription(AchievementType type) {
    switch (type) {
      case AchievementType.workoutCount:
        return 'Achievement basati sul numero di allenamenti completati';
      case AchievementType.profileComplete:
        return 'Achievement per completare il profilo utente';
      case AchievementType.streak:
        return 'Achievement per la costanza negli allenamenti';
      case AchievementType.experience:
        return 'Achievement basati sull\'esperienza accumulata';
      case AchievementType.weight:
        return 'Achievement basati sui carichi utilizzati';
      case AchievementType.time:
        return 'Achievement basati sul tempo totale di allenamento';
    }
  }

  static IconData _getCategoryIcon(AchievementType type) {
    switch (type) {
      case AchievementType.workoutCount:
        return Icons.fitness_center;
      case AchievementType.profileComplete:
        return Icons.person;
      case AchievementType.streak:
        return Icons.local_fire_department;
      case AchievementType.experience:
        return Icons.star;
      case AchievementType.weight:
        return Icons.fitness_center;
      case AchievementType.time:
        return Icons.schedule;
    }
  }

  static Color _getCategoryColor(AchievementType type) {
    switch (type) {
      case AchievementType.workoutCount:
        return Colors.blue;
      case AchievementType.profileComplete:
        return Colors.teal;
      case AchievementType.streak:
        return Colors.red;
      case AchievementType.experience:
        return Colors.purple;
      case AchievementType.weight:
        return Colors.indigo;
      case AchievementType.time:
        return Colors.cyan;
    }
  }
}