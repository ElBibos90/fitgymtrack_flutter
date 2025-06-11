// lib/features/workouts/models/plateau_models.dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plateau_models.g.dart';

// ============================================================================
// 🎯 CORE PLATEAU MODELS - STEP 6
// ============================================================================

/// 🔧 PRIORITÀ PLATEAU - Ordine di importanza
enum PlateauPriority {
  none,
  low,
  medium,
  high,
  critical,
}

/// Informazioni plateau per un singolo esercizio
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

  /// 🔧 FIX: Descrizione dettagliata del plateau
  String get detailedDescription {
    return 'Plateau di tipo ${typeDescription.toLowerCase()} rilevato per ${exerciseName}. '
        'Stessi valori (${currentWeight.toStringAsFixed(1)}kg x $currentReps reps) '
        'per $sessionsInPlateau allenamenti consecutivi.';
  }

  /// 🔧 FIX: Indicatore di severità del plateau
  PlateauSeverity get severity {
    if (sessionsInPlateau >= 5) return PlateauSeverity.severe;
    if (sessionsInPlateau >= 3) return PlateauSeverity.moderate;
    return PlateauSeverity.mild;
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

/// 🔧 FIX: Severità del plateau
enum PlateauSeverity {
  mild,     // 2-3 sessioni
  moderate, // 3-4 sessioni
  severe,   // 5+ sessioni
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

  /// 🔧 FIX: Differenza rispetto ai valori attuali
  String getWeightDifference(double currentWeight) {
    final diff = newWeight - currentWeight;
    if (diff > 0) {
      return '+${diff.toStringAsFixed(1)}kg';
    } else if (diff < 0) {
      return '${diff.toStringAsFixed(1)}kg';
    } else {
      return 'Stesso peso';
    }
  }

  /// 🔧 FIX: Differenza ripetizioni
  String getRepsDifference(int currentReps) {
    final diff = newReps - currentReps;
    if (diff > 0) {
      return '+$diff reps';
    } else if (diff < 0) {
      return '$diff reps';
    } else {
      return 'Stesse reps';
    }
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

/// 🔧 FIX CRITICO: Configurazione per il rilevamento plateau - TOLLERANZE ESATTE
@JsonSerializable()
class PlateauDetectionConfig extends Equatable {
  final int minSessionsForPlateau;
  final double weightTolerance;
  final int repsTolerance;
  final bool enableSimulatedPlateau; // Per testing
  final bool autoDetectionEnabled;

  const PlateauDetectionConfig({
    this.minSessionsForPlateau = 3,
    this.weightTolerance = 0.0, // 🔧 FIX: Tolleranza ZERO per confronto ESATTO
    this.repsTolerance = 0,      // 🔧 FIX: Tolleranza ZERO per confronto ESATTO
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

  /// 🔧 FIX: Valida la configurazione
  bool get isValid {
    return minSessionsForPlateau >= 2 &&
        minSessionsForPlateau <= 10 &&
        weightTolerance >= 0.0 &&
        weightTolerance <= 5.0 &&
        repsTolerance >= 0 &&
        repsTolerance <= 5;
  }

  /// 🔧 FIX: Descrizione configurazione
  String get description {
    return 'Plateau dopo $minSessionsForPlateau sessioni (±${weightTolerance.toStringAsFixed(1)}kg, ±$repsTolerance reps)';
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

  /// 🔧 FIX: Descrizione dettagliata del gruppo
  String get detailedDescription {
    final typeText = groupType == 'superset' ? 'Superset' :
    groupType == 'circuit' ? 'Circuito' : 'Gruppo';
    return '$typeText "$groupName": $exercisesInPlateau/$totalExercises esercizi in plateau (${plateauPercentage.toStringAsFixed(1)}%)';
  }

  @override
  List<Object?> get props => [groupName, groupType, plateauList, totalExercises, analyzedAt];

  factory GroupPlateauAnalysis.fromJson(Map<String, dynamic> json) => _$GroupPlateauAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$GroupPlateauAnalysisToJson(this);
}

/// Statistiche globali sui plateau rilevati
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

  /// Ottiene la percentuale di plateau
  double get plateauPercentage {
    if (totalExercisesAnalyzed == 0) return 0.0;
    return (totalPlateauDetected / totalExercisesAnalyzed) * 100;
  }

  /// Ottiene il tipo di plateau più comune
  PlateauType? get mostCommonType {
    if (plateauByType.isEmpty) return null;
    return plateauByType.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Ottiene il suggerimento più comune
  SuggestionType? get mostCommonSuggestion {
    if (suggestionsByType.isEmpty) return null;
    return suggestionsByType.entries.reduce((a, b) => a.value > b.value ? a : b).key;
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

// ============================================================================
// 🔧 HELPER FUNCTIONS
// ============================================================================

/// 🔧 FIX: Genera suggerimenti smart per un plateau specifico
List<ProgressionSuggestion> generateSmartSuggestions(PlateauInfo plateau) {
  final suggestions = <ProgressionSuggestion>[];
  final weight = plateau.currentWeight;
  final reps = plateau.currentReps;
  final type = plateau.plateauType;

  // Suggerimento aumento peso (prioritario per plateau di peso leggero)
  final weightIncrement = weight < 10 ? 0.5 : (weight < 50 ? 1.25 : 2.5);
  suggestions.add(
    ProgressionSuggestion(
      type: SuggestionType.increaseWeight,
      description: 'Aumenta il peso a ${(weight + weightIncrement).toStringAsFixed(1)} kg',
      newWeight: weight + weightIncrement,
      newReps: reps,
      confidence: type == PlateauType.lightWeight ? 0.9 : 0.7,
    ),
  );

  // Suggerimento aumento ripetizioni
  final repsIncrement = reps < 8 ? 1 : 2;
  suggestions.add(
    ProgressionSuggestion(
      type: SuggestionType.increaseReps,
      description: 'Aumenta le ripetizioni a ${reps + repsIncrement}',
      newWeight: weight,
      newReps: reps + repsIncrement,
      confidence: type == PlateauType.lowReps ? 0.8 : 0.6,
    ),
  );

  // Suggerimento tecniche avanzate
  if (weight > 20 && reps > 8) {
    suggestions.add(
      ProgressionSuggestion(
        type: SuggestionType.advancedTechnique,
        description: 'Prova tecniche avanzate come drop set o rest-pause',
        newWeight: weight,
        newReps: reps,
        confidence: 0.6,
      ),
    );
  }

  return suggestions..sort((a, b) => b.confidence.compareTo(a.confidence));
}

/// 🔧 FIX: Determina il tipo di plateau basato sui valori
PlateauType _determinePlateauTypeForValues(double weight, int reps) {
  if (weight < 10) return PlateauType.lightWeight;
  if (weight > 100) return PlateauType.heavyWeight;
  if (reps < 5) return PlateauType.lowReps;
  if (reps > 15) return PlateauType.highReps;
  return PlateauType.moderate;
}

/// Crea una configurazione di default per il rilevamento ESATTO
PlateauDetectionConfig createDefaultPlateauConfig({bool enableTesting = false}) {
  return enableTesting
      ? const PlateauDetectionConfig(
    minSessionsForPlateau: 2,
    weightTolerance: 0.0,     // 🔧 FIX: ESATTO per testing
    repsTolerance: 0,         // 🔧 FIX: ESATTO per testing
    enableSimulatedPlateau: true,
    autoDetectionEnabled: true,
  )
      : const PlateauDetectionConfig(
    minSessionsForPlateau: 3,
    weightTolerance: 0.0,     // 🔧 FIX: ESATTO per produzione
    repsTolerance: 0,         // 🔧 FIX: ESATTO per produzione
    enableSimulatedPlateau: false,
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

// ============================================================================
// 🔧 FIX: CORE PLATEAU MODELS ONLY
// ============================================================================
// Nota: Helper functions e DI sono in dependency_injection_plateau.dart