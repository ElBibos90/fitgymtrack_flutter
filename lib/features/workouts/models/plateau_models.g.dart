// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plateau_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlateauInfo _$PlateauInfoFromJson(Map<String, dynamic> json) => PlateauInfo(
      exerciseId: (json['exerciseId'] as num).toInt(),
      exerciseName: json['exerciseName'] as String,
      plateauType: $enumDecode(_$PlateauTypeEnumMap, json['plateauType']),
      sessionsInPlateau: (json['sessionsInPlateau'] as num).toInt(),
      currentWeight: (json['currentWeight'] as num).toDouble(),
      currentReps: (json['currentReps'] as num).toInt(),
      suggestions: (json['suggestions'] as List<dynamic>)
          .map((e) => ProgressionSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      isDismissed: json['isDismissed'] as bool? ?? false,
    );

Map<String, dynamic> _$PlateauInfoToJson(PlateauInfo instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'exerciseName': instance.exerciseName,
      'plateauType': _$PlateauTypeEnumMap[instance.plateauType]!,
      'sessionsInPlateau': instance.sessionsInPlateau,
      'currentWeight': instance.currentWeight,
      'currentReps': instance.currentReps,
      'suggestions': instance.suggestions,
      'detectedAt': instance.detectedAt.toIso8601String(),
      'isDismissed': instance.isDismissed,
    };

const _$PlateauTypeEnumMap = {
  PlateauType.lightWeight: 'light_weight',
  PlateauType.heavyWeight: 'heavy_weight',
  PlateauType.lowReps: 'low_reps',
  PlateauType.highReps: 'high_reps',
  PlateauType.moderate: 'moderate',
};

ProgressionSuggestion _$ProgressionSuggestionFromJson(
        Map<String, dynamic> json) =>
    ProgressionSuggestion(
      type: $enumDecode(_$SuggestionTypeEnumMap, json['type']),
      description: json['description'] as String,
      newWeight: (json['newWeight'] as num).toDouble(),
      newReps: (json['newReps'] as num).toInt(),
      confidence: (json['confidence'] as num).toDouble(),
    );

Map<String, dynamic> _$ProgressionSuggestionToJson(
        ProgressionSuggestion instance) =>
    <String, dynamic>{
      'type': _$SuggestionTypeEnumMap[instance.type]!,
      'description': instance.description,
      'newWeight': instance.newWeight,
      'newReps': instance.newReps,
      'confidence': instance.confidence,
    };

const _$SuggestionTypeEnumMap = {
  SuggestionType.increaseWeight: 'increase_weight',
  SuggestionType.increaseReps: 'increase_reps',
  SuggestionType.advancedTechnique: 'advanced_technique',
  SuggestionType.reduceRest: 'reduce_rest',
  SuggestionType.changeTempo: 'change_tempo',
};

PlateauDetectionConfig _$PlateauDetectionConfigFromJson(
        Map<String, dynamic> json) =>
    PlateauDetectionConfig(
      minSessionsForPlateau:
          (json['minSessionsForPlateau'] as num?)?.toInt() ?? 3,
      weightTolerance: (json['weightTolerance'] as num?)?.toDouble() ?? 0.0,
      repsTolerance: (json['repsTolerance'] as num?)?.toInt() ?? 0,
      enableSimulatedPlateau: json['enableSimulatedPlateau'] as bool? ?? false,
      autoDetectionEnabled: json['autoDetectionEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$PlateauDetectionConfigToJson(
        PlateauDetectionConfig instance) =>
    <String, dynamic>{
      'minSessionsForPlateau': instance.minSessionsForPlateau,
      'weightTolerance': instance.weightTolerance,
      'repsTolerance': instance.repsTolerance,
      'enableSimulatedPlateau': instance.enableSimulatedPlateau,
      'autoDetectionEnabled': instance.autoDetectionEnabled,
    };

GroupPlateauAnalysis _$GroupPlateauAnalysisFromJson(
        Map<String, dynamic> json) =>
    GroupPlateauAnalysis(
      groupName: json['groupName'] as String,
      groupType: json['groupType'] as String,
      plateauList: (json['plateauList'] as List<dynamic>)
          .map((e) => PlateauInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalExercises: (json['totalExercises'] as num).toInt(),
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
    );

Map<String, dynamic> _$GroupPlateauAnalysisToJson(
        GroupPlateauAnalysis instance) =>
    <String, dynamic>{
      'groupName': instance.groupName,
      'groupType': instance.groupType,
      'plateauList': instance.plateauList,
      'totalExercises': instance.totalExercises,
      'analyzedAt': instance.analyzedAt.toIso8601String(),
    };

PlateauStatistics _$PlateauStatisticsFromJson(Map<String, dynamic> json) =>
    PlateauStatistics(
      totalExercisesAnalyzed: (json['totalExercisesAnalyzed'] as num).toInt(),
      totalPlateauDetected: (json['totalPlateauDetected'] as num).toInt(),
      plateauByType: (json['plateauByType'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry($enumDecode(_$PlateauTypeEnumMap, k), (e as num).toInt()),
      ),
      suggestionsByType:
          (json['suggestionsByType'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            $enumDecode(_$SuggestionTypeEnumMap, k), (e as num).toInt()),
      ),
      lastAnalysisAt: DateTime.parse(json['lastAnalysisAt'] as String),
      averageSessionsInPlateau:
          (json['averageSessionsInPlateau'] as num).toDouble(),
    );

Map<String, dynamic> _$PlateauStatisticsToJson(PlateauStatistics instance) =>
    <String, dynamic>{
      'totalExercisesAnalyzed': instance.totalExercisesAnalyzed,
      'totalPlateauDetected': instance.totalPlateauDetected,
      'plateauByType': instance.plateauByType
          .map((k, e) => MapEntry(_$PlateauTypeEnumMap[k]!, e)),
      'suggestionsByType': instance.suggestionsByType
          .map((k, e) => MapEntry(_$SuggestionTypeEnumMap[k]!, e)),
      'lastAnalysisAt': instance.lastAnalysisAt.toIso8601String(),
      'averageSessionsInPlateau': instance.averageSessionsInPlateau,
    };
