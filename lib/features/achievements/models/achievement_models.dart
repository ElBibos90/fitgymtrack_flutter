// lib/features/achievements/models/achievement_models.dart

import 'package:flutter/material.dart';

/// Enum per i tipi di achievement
enum AchievementType {
  workoutCount('Allenamenti'),
  profileComplete('Profilo'),
  streak('Costanza'),
  experience('Esperienza'),
  weight('Carico'),
  time('Tempo');

  const AchievementType(this.displayName);
  final String displayName;
}

/// Model per un achievement
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final AchievementType type;
  final int targetValue;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int points;
  final String? iconEmoji;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.isUnlocked,
    this.unlockedAt,
    this.points = 10,
    this.iconEmoji,
  });

  /// Indica se l'achievement è completato
  bool get isCompleted => currentValue >= targetValue;

  /// Progresso in percentuale (0.0 - 1.0)
  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);

  /// Progresso in percentuale (0-100)
  int get progressPercentage => (progress * 100).round();

  /// Descrizione del progresso
  String get progressDescription => '$currentValue / $targetValue';

  /// Crea una copia con valori aggiornati
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    Color? color,
    AchievementType? type,
    int? targetValue,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? points,
    String? iconEmoji,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      points: points ?? this.points,
      iconEmoji: iconEmoji ?? this.iconEmoji,
    );
  }

  @override
  String toString() => 'Achievement(id: $id, title: $title, progress: $progressDescription)';
}

/// Categoria di achievement
class AchievementCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<Achievement> achievements;

  const AchievementCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.achievements,
  });

  /// Numero di achievement sbloccati
  int get unlockedCount => achievements.where((a) => a.isUnlocked).length;

  /// Numero totale di achievement
  int get totalCount => achievements.length;

  /// Progresso della categoria (0.0 - 1.0)
  double get progress => totalCount > 0 ? unlockedCount / totalCount : 0.0;

  /// Punti totali guadagnati
  int get totalPoints => achievements
      .where((a) => a.isUnlocked)
      .fold(0, (sum, a) => sum + a.points);
}

/// Statistiche generali achievement
class AchievementStats {
  final int totalAchievements;
  final int unlockedAchievements;
  final int totalPoints;
  final double completionPercentage;
  final Achievement? latestUnlocked;
  final List<AchievementCategory> categories;

  const AchievementStats({
    required this.totalAchievements,
    required this.unlockedAchievements,
    required this.totalPoints,
    required this.completionPercentage,
    this.latestUnlocked,
    required this.categories,
  });

  /// Livello dell'utente basato sui punti
  int get userLevel => (totalPoints / 100).floor() + 1;

  /// Punti necessari per il prossimo livello
  int get pointsToNextLevel => (userLevel * 100) - totalPoints;

  /// Progresso verso il prossimo livello (0.0 - 1.0)
  double get levelProgress {
    final currentLevelPoints = totalPoints % 100;
    return currentLevelPoints / 100.0;
  }
}