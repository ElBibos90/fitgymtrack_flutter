// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_response_types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateWorkoutPlanResponse _$CreateWorkoutPlanResponseFromJson(
        Map<String, dynamic> json) =>
    CreateWorkoutPlanResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      schedaId: (json['scheda_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CreateWorkoutPlanResponseToJson(
        CreateWorkoutPlanResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'scheda_id': instance.schedaId,
    };

UpdateWorkoutPlanResponse _$UpdateWorkoutPlanResponseFromJson(
        Map<String, dynamic> json) =>
    UpdateWorkoutPlanResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      schedaId: (json['scheda_id'] as num?)?.toInt(),
      updatedExercises: (json['updated_exercises'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UpdateWorkoutPlanResponseToJson(
        UpdateWorkoutPlanResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'scheda_id': instance.schedaId,
      'updated_exercises': instance.updatedExercises,
    };

DeleteWorkoutPlanResponse _$DeleteWorkoutPlanResponseFromJson(
        Map<String, dynamic> json) =>
    DeleteWorkoutPlanResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      schedaId: (json['scheda_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DeleteWorkoutPlanResponseToJson(
        DeleteWorkoutPlanResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'scheda_id': instance.schedaId,
    };

GenericWorkoutResponse _$GenericWorkoutResponseFromJson(
        Map<String, dynamic> json) =>
    GenericWorkoutResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$GenericWorkoutResponseToJson(
        GenericWorkoutResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

AvailableExercisesResponse _$AvailableExercisesResponseFromJson(
        Map<String, dynamic> json) =>
    AvailableExercisesResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      esercizi: (json['esercizi'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$AvailableExercisesResponseToJson(
        AvailableExercisesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'esercizi': instance.esercizi,
      'count': instance.count,
    };

WorkoutDetailsResponse _$WorkoutDetailsResponseFromJson(
        Map<String, dynamic> json) =>
    WorkoutDetailsResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      scheda: json['scheda'] as Map<String, dynamic>?,
      esercizi: (json['esercizi'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$WorkoutDetailsResponseToJson(
        WorkoutDetailsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'scheda': instance.scheda,
      'esercizi': instance.esercizi,
    };

StartActiveWorkoutResponse _$StartActiveWorkoutResponseFromJson(
        Map<String, dynamic> json) =>
    StartActiveWorkoutResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      allenamentoId: (json['allenamento_id'] as num).toInt(),
      sessionId: json['session_id'] as String?,
      dataInizio: json['data_inizio'] as String?,
    );

Map<String, dynamic> _$StartActiveWorkoutResponseToJson(
        StartActiveWorkoutResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'allenamento_id': instance.allenamentoId,
      'session_id': instance.sessionId,
      'data_inizio': instance.dataInizio,
    };

CompleteActiveWorkoutResponse _$CompleteActiveWorkoutResponseFromJson(
        Map<String, dynamic> json) =>
    CompleteActiveWorkoutResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      allenamentoId: (json['allenamento_id'] as num).toInt(),
      durataTotale: (json['durata_totale'] as num).toInt(),
      serieCompletate: (json['serie_completate'] as num?)?.toInt(),
      dataCompletamento: json['data_completamento'] as String?,
    );

Map<String, dynamic> _$CompleteActiveWorkoutResponseToJson(
        CompleteActiveWorkoutResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'allenamento_id': instance.allenamentoId,
      'durata_totale': instance.durataTotale,
      'serie_completate': instance.serieCompletate,
      'data_completamento': instance.dataCompletamento,
    };

SaveSeriesResponse _$SaveSeriesResponseFromJson(Map<String, dynamic> json) =>
    SaveSeriesResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      serieSalvate: (json['serie_salvate'] as num?)?.toInt(),
      requestId: json['request_id'] as String?,
    );

Map<String, dynamic> _$SaveSeriesResponseToJson(SaveSeriesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'serie_salvate': instance.serieSalvate,
      'request_id': instance.requestId,
    };

LoadSeriesResponse _$LoadSeriesResponseFromJson(Map<String, dynamic> json) =>
    LoadSeriesResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      serie: (json['serie'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      count: (json['count'] as num).toInt(),
      allenamentoId: (json['allenamento_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LoadSeriesResponseToJson(LoadSeriesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'serie': instance.serie,
      'count': instance.count,
      'allenamento_id': instance.allenamentoId,
    };
