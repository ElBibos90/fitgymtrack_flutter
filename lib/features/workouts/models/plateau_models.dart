// lib/features/workouts/models/plateau_models.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'plateau_models.g.dart';

/// 🎯 STEP 6: Modelli per il sistema di rilevamento plateau
/// Traduzioni Dart dei modelli Kotlin esistenti

/// Informazioni su un plateau rilevato
@JsonSerializable()
class PlateauInfo extends Equatable {
  final int exerciseId;
  final String exerciseName;
  final PlateauType plateauType;
  final int sessionsInPlateau;
  final double currentWeight;
  final int currentReps;
  final List<ProgressionSuggestion> suggestions;
  final DateTime detectedAt;
  final bool isDismissed;

  const PlateauInfo({
    required this.exerciseId,
    required this.exerciseName,
    required this.plateauType,
    required this.sessionsInPlateau,
    required this.currentWeight,
    required this.currentReps,
    required this.suggestions,
    required this.detectedAt,
    this.isDismissed = false,
  });

  /// Crea una copia con modifiche
  PlateauInfo copyWith({
    int? exerciseId,
    String? exerciseName,
    PlateauType? plateauType,
    int? sessionsInPlateau,
    double? currentWeight,
    int? currentReps,
    List<ProgressionSuggestion>? suggestions,
    DateTime? detectedAt,
    bool? isDismissed,
  }) {
    return PlateauInfo(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      plateauType: plateauType ?? this.plateauType,
      sessionsInPlateau: sessionsInPlateau ?? this.sessionsInPlateau,
      currentWeight: currentWeight ?? this.currentWeight,
      currentReps: currentReps ?? this.currentReps,
      suggestions: suggestions ?? this.suggestions,
      detectedAt: detectedAt ?? this.detectedAt,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  /// Ottiene il suggerimento con maggiore confidenza
  ProgressionSuggestion? get bestSuggestion {
    if (suggestions.isEmpty) return null;
    return suggestions.reduce((a, b) => a.confidence > b.confidence ? a : b);
  }

  /// Ottiene il colore associato al tipo di plateau
  String get colorHex {
    switch (plateauType) {
      case PlateauType.lightWeight:
        return '#FF9800'; // Arancione
      case PlateauType.heavyWeight:
        return '#F44336'; // Rosso
      case PlateauType.lowReps:
        return '#2196F3'; // Blu
      case PlateauType.highReps:
        return '#9C27B0'; // Viola
      case PlateauType.moderate:
        return '#FF5722'; // Deep Orange
    }
  }

  /// Ottiene la descrizione del tipo di plateau
  String get typeDescription {
    switch (plateauType) {
      case PlateauType.lightWeight:
        return 'Peso Leggero';
      case PlateauType.heavyWeight:
        return 'Peso Pesante';
      case PlateauType.lowReps:
        return 'Poche Ripetizioni';
      case PlateauType.highReps:
        return 'Molte Ripetizioni';
      case PlateauType.moderate:
        return 'Valori Moderati';
    }
  }

  @override
  List<Object?> get props => [
    exerciseId,
    exerciseName,
    plateauType,
    sessionsInPlateau,
    currentWeight,
    currentReps,
    suggestions,
    detectedAt,
    isDismissed,
  ];

  factory PlateauInfo.fromJson(Map<String, dynamic> json) => _$PlateauInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PlateauInfoToJson(this);
}

/// Tipi di plateau
@JsonEnum()
enum PlateauType {
  @JsonValue('light_weight')
  lightWeight,
  @JsonValue('heavy_weight')
  heavyWeight,
  @JsonValue('low_reps')
  lowReps,
  @JsonValue('high_reps')
  highReps,
  @JsonValue('moderate')
  moderate,
}

/// Suggerimento per la progressione
@JsonSerializable()
class ProgressionSuggestion extends Equatable {
  final SuggestionType type;
  final String description;
  final double newWeight;
  final int newReps;
  final double confidence; // 0.0 - 1.0

  const ProgressionSuggestion({
    required this.type,
    required this.description,
    required this.newWeight,
    required this.newReps,
    required this.confidence,
  });

  /// Ottiene l'icona associata al tipo di suggerimento
  String get iconName {
    switch (type) {
      case SuggestionType.increaseWeight:
        return 'arrow_upward';
      case SuggestionType.increaseReps:
        return 'add';
      case SuggestionType.advancedTechnique:
        return 'psychology';
      case SuggestionType.reduceRest:
        return 'timer';
      case SuggestionType.changeTempo:
        return 'speed';
    }
  }

  /// Ottiene il colore della confidenza
  String get confidenceColorHex {
    if (confidence >= 0.8) return '#4CAF50'; // Verde
    if (confidence >= 0.6) return '#FF9800'; // Arancione
    return '#F44336'; // Rosso
  }

  /// Ottiene il testo della confidenza
  String get confidenceText {
    return '${(confidence * 100).toInt()}%';
  }

  /// Ottiene la descrizione della confidenza
  String get confidenceDescription {
    if (confidence >= 0.8) return 'Alta Confidenza';
    if (confidence >= 0.6) return 'Media Confidenza';
    return 'Bassa Confidenza';
  }

  @override
  List<Object?> get props => [type, description, newWeight, newReps, confidence];

  factory ProgressionSuggestion.fromJson(Map<String, dynamic> json) => _$ProgressionSuggestionFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressionSuggestionToJson(this);
}

/// Tipi di suggerimenti
@JsonEnum()
enum SuggestionType {
  @JsonValue('increase_weight')
  increaseWeight,
  @JsonValue('increase_reps')
  increaseReps,
  @JsonValue('advanced_technique')
  advancedTechnique,
  @JsonValue('reduce_rest')
  reduceRest,
  @JsonValue('change_tempo')
  changeTempo,
}

/// Configurazione per il rilevamento plateau
@JsonSerializable()
class PlateauDetectionConfig extends Equatable {
  final int minSessionsForPlateau;
  final double weightTolerance;
  final int repsTolerance;
  final bool enableSimulatedPlateau; // Per testing
  final bool autoDetectionEnabled;

  const PlateauDetectionConfig({
    this.minSessionsForPlateau = 3,
    this.weightTolerance = 1.0,
    this.repsTolerance = 1,
    this.enableSimulatedPlateau = false,
    this.autoDetectionEnabled = true,
  });

  PlateauDetectionConfig copyWith({
    int? minSessionsForPlateau,
    double? weightTolerance,
    int? repsTolerance,
    bool? enableSimulatedPlateau,
    bool? autoDetectionEnabled,
  }) {
    return PlateauDetectionConfig(
      minSessionsForPlateau: minSessionsForPlateau ?? this.minSessionsForPlateau,
      weightTolerance: weightTolerance ?? this.weightTolerance,
      repsTolerance: repsTolerance ?? this.repsTolerance,
      enableSimulatedPlateau: enableSimulatedPlateau ?? this.enableSimulatedPlateau,
      autoDetectionEnabled: autoDetectionEnabled ?? this.autoDetectionEnabled,
    );
  }

  @override
  List<Object?> get props => [
    minSessionsForPlateau,
    weightTolerance,
    repsTolerance,
    enableSimulatedPlateau,
    autoDetectionEnabled,
  ];

  factory PlateauDetectionConfig.fromJson(Map<String, dynamic> json) => _$PlateauDetectionConfigFromJson(json);
  Map<String, dynamic> toJson() => _$PlateauDetectionConfigToJson(this);
}

/// Risultato dell'analisi plateau per un gruppo di esercizi
@JsonSerializable()
class GroupPlateauAnalysis extends Equatable {
  final String groupName;
  final String groupType; // 'normal', 'superset', 'circuit'
  final List<PlateauInfo> plateauList;
  final int totalExercises;
  final DateTime analyzedAt;

  const GroupPlateauAnalysis({
    required this.groupName,
    required this.groupType,
    required this.plateauList,
    required this.totalExercises,
    required this.analyzedAt,
  });

  /// Ottiene il numero di esercizi in plateau
  int get exercisesInPlateau => plateauList.length;

  /// Ottiene la percentuale di plateau nel gruppo
  double get plateauPercentage {
    if (totalExercises == 0) return 0.0;
    return (exercisesInPlateau / totalExercises) * 100;
  }

  /// Verifica se il gruppo ha plateau significativi
  bool get hasSignificantPlateau => plateauPercentage >= 50.0;

  /// Ottiene la priorità del gruppo (basata sulla percentuale di plateau)
  PlateauPriority get priority {
    if (plateauPercentage >= 75.0) return PlateauPriority.high;
    if (plateauPercentage >= 50.0) return PlateauPriority.medium;
    if (plateauPercentage > 0.0) return PlateauPriority.low;
    return PlateauPriority.none;
  }

  @override
  List<Object?> get props => [groupName, groupType, plateauList, totalExercises, analyzedAt];

  factory GroupPlateauAnalysis.fromJson(Map<String, dynamic> json) => _$GroupPlateauAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$GroupPlateauAnalysisToJson(this);
}

/// Priorità del plateau
enum PlateauPriority {
  none,
  low,
  medium,
  high,
}

/// Statistiche globali sui plateau
@JsonSerializable()
class PlateauStatistics extends Equatable {
  final int totalExercisesAnalyzed;
  final int totalPlateauDetected;
  final Map<PlateauType, int> plateauByType;
  final Map<SuggestionType, int> suggestionsByType;
  final DateTime lastAnalysisAt;
  final double averageSessionsInPlateau;

  const PlateauStatistics({
    required this.totalExercisesAnalyzed,
    required this.totalPlateauDetected,
    required this.plateauByType,
    required this.suggestionsByType,
    required this.lastAnalysisAt,
    required this.averageSessionsInPlateau,
  });

  /// Ottiene la percentuale globale di plateau
  double get globalPlateauPercentage {
    if (totalExercisesAnalyzed == 0) return 0.0;
    return (totalPlateauDetected / totalExercisesAnalyzed) * 100;
  }

  /// Ottiene il tipo di plateau più comune
  PlateauType? get mostCommonPlateauType {
    if (plateauByType.isEmpty) return null;

    var maxType = plateauByType.entries.first;
    for (final entry in plateauByType.entries) {
      if (entry.value > maxType.value) {
        maxType = entry;
      }
    }
    return maxType.key;
  }

  /// Ottiene il tipo di suggerimento più comune
  SuggestionType? get mostCommonSuggestionType {
    if (suggestionsByType.isEmpty) return null;

    var maxType = suggestionsByType.entries.first;
    for (final entry in suggestionsByType.entries) {
      if (entry.value > maxType.value) {
        maxType = entry;
      }
    }
    return maxType.key;
  }

  @override
  List<Object?> get props => [
    totalExercisesAnalyzed,
    totalPlateauDetected,
    plateauByType,
    suggestionsByType,
    lastAnalysisAt,
    averageSessionsInPlateau,
  ];

  factory PlateauStatistics.fromJson(Map<String, dynamic> json) => _$PlateauStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$PlateauStatisticsToJson(this);
}

/// Factory functions per creare istanze comuni

/// Crea un plateau simulato per testing
PlateauInfo createSimulatedPlateau({
  required int exerciseId,
  required String exerciseName,
  double weight = 20.0,
  int reps = 10,
  int sessions = 3,
}) {
  return PlateauInfo(
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    plateauType: PlateauType.moderate,
    sessionsInPlateau: sessions,
    currentWeight: weight,
    currentReps: reps,
    detectedAt: DateTime.now(),
    suggestions: [
      ProgressionSuggestion(
        type: SuggestionType.increaseWeight,
        description: 'Prova ad aumentare il peso a ${(weight + 2.5).toStringAsFixed(1)} kg',
        newWeight: weight + 2.5,
        newReps: reps,
        confidence: 0.8,
      ),
      ProgressionSuggestion(
        type: SuggestionType.increaseReps,
        description: 'Prova ad aumentare le ripetizioni a ${reps + 2}',
        newWeight: weight,
        newReps: reps + 2,
        confidence: 0.7,
      ),
    ],
  );
}

/// Crea una configurazione di default per il rilevamento
PlateauDetectionConfig createDefaultPlateauConfig({bool enableTesting = false}) {
  return PlateauDetectionConfig(
    minSessionsForPlateau: enableTesting ? 2 : 3,
    weightTolerance: 1.0,
    repsTolerance: 1,
    enableSimulatedPlateau: enableTesting,
    autoDetectionEnabled: true,
  );
}

/// Crea statistiche vuote
PlateauStatistics createEmptyStatistics() {
  return PlateauStatistics(
    totalExercisesAnalyzed: 0,
    totalPlateauDetected: 0,
    plateauByType: {},
    suggestionsByType: {},
    lastAnalysisAt: DateTime.now(),
    averageSessionsInPlateau: 0.0,
  );
}