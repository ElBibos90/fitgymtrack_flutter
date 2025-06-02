// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_plan_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutPlan _$WorkoutPlanFromJson(Map<String, dynamic> json) => WorkoutPlan(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      descrizione: json['descrizione'] as String?,
      dataCreazione: json['data_creazione'] as String?,
      esercizi: (json['esercizi'] as List<dynamic>?)
              ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WorkoutPlanToJson(WorkoutPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'descrizione': instance.descrizione,
      'data_creazione': instance.dataCreazione,
      'esercizi': instance.esercizi,
    };

WorkoutExercise _$WorkoutExerciseFromJson(Map<String, dynamic> json) =>
    WorkoutExercise(
      id: (json['id'] as num).toInt(),
      schedaEsercizioId: (json['scheda_esercizio_id'] as num?)?.toInt(),
      nome: json['nome'] as String,
      gruppoMuscolare: json['gruppo_muscolare'] as String?,
      attrezzatura: json['attrezzatura'] as String?,
      descrizione: json['descrizione'] as String?,
      serie: json['serie'] == null ? 3 : _parseIntSafe(json['serie']),
      ripetizioni:
          json['ripetizioni'] == null ? 10 : _parseIntSafe(json['ripetizioni']),
      peso: json['peso'] == null ? 0.0 : _parseWeightSafe(json['peso']),
      ordine: json['ordine'] == null ? 0 : _parseIntSafe(json['ordine']),
      tempoRecupero: json['tempo_recupero'] == null
          ? 90
          : _parseIntSafe(json['tempo_recupero']),
      note: json['note'] as String?,
      setType: json['set_type'] as String? ?? 'normal',
      linkedToPreviousInt: json['linked_to_previous'] == null
          ? 0
          : _parseIntSafe(json['linked_to_previous']),
      isIsometricInt: json['is_isometric'] == null
          ? 0
          : _parseIntSafe(json['is_isometric']),
    );

Map<String, dynamic> _$WorkoutExerciseToJson(WorkoutExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scheda_esercizio_id': instance.schedaEsercizioId,
      'nome': instance.nome,
      'gruppo_muscolare': instance.gruppoMuscolare,
      'attrezzatura': instance.attrezzatura,
      'descrizione': instance.descrizione,
      'serie': instance.serie,
      'ripetizioni': instance.ripetizioni,
      'peso': _weightToJson(instance.peso),
      'ordine': instance.ordine,
      'tempo_recupero': instance.tempoRecupero,
      'note': instance.note,
      'set_type': instance.setType,
      'linked_to_previous': instance.linkedToPreviousInt,
      'is_isometric': instance.isIsometricInt,
    };

CreateWorkoutPlanRequest _$CreateWorkoutPlanRequestFromJson(
        Map<String, dynamic> json) =>
    CreateWorkoutPlanRequest(
      userId: (json['user_id'] as num).toInt(),
      nome: json['nome'] as String,
      descrizione: json['descrizione'] as String?,
      esercizi: (json['esercizi'] as List<dynamic>)
          .map(
              (e) => WorkoutExerciseRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreateWorkoutPlanRequestToJson(
        CreateWorkoutPlanRequest instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'nome': instance.nome,
      'descrizione': instance.descrizione,
      'esercizi': instance.esercizi,
    };

WorkoutExerciseRequest _$WorkoutExerciseRequestFromJson(
        Map<String, dynamic> json) =>
    WorkoutExerciseRequest(
      id: (json['id'] as num).toInt(),
      schedaEsercizioId: (json['scheda_esercizio_id'] as num?)?.toInt(),
      serie: (json['serie'] as num).toInt(),
      ripetizioni: (json['ripetizioni'] as num).toInt(),
      peso: (json['peso'] as num).toDouble(),
      ordine: (json['ordine'] as num).toInt(),
      tempoRecupero: (json['tempo_recupero'] as num?)?.toInt() ?? 90,
      note: json['note'] as String?,
      setType: json['set_type'] as String? ?? 'normal',
      linkedToPrevious: (json['linked_to_previous'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$WorkoutExerciseRequestToJson(
        WorkoutExerciseRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scheda_esercizio_id': instance.schedaEsercizioId,
      'serie': instance.serie,
      'ripetizioni': instance.ripetizioni,
      'peso': instance.peso,
      'ordine': instance.ordine,
      'tempo_recupero': instance.tempoRecupero,
      'note': instance.note,
      'set_type': instance.setType,
      'linked_to_previous': instance.linkedToPrevious,
    };

UpdateWorkoutPlanRequest _$UpdateWorkoutPlanRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateWorkoutPlanRequest(
      schedaId: (json['scheda_id'] as num).toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      nome: json['nome'] as String,
      descrizione: json['descrizione'] as String?,
      esercizi: (json['esercizi'] as List<dynamic>)
          .map(
              (e) => WorkoutExerciseRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      rimuovi: (json['rimuovi'] as List<dynamic>?)
          ?.map((e) =>
              WorkoutExerciseToRemove.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UpdateWorkoutPlanRequestToJson(
        UpdateWorkoutPlanRequest instance) =>
    <String, dynamic>{
      'scheda_id': instance.schedaId,
      'user_id': instance.userId,
      'nome': instance.nome,
      'descrizione': instance.descrizione,
      'esercizi': instance.esercizi,
      'rimuovi': instance.rimuovi,
    };

WorkoutExerciseToRemove _$WorkoutExerciseToRemoveFromJson(
        Map<String, dynamic> json) =>
    WorkoutExerciseToRemove(
      id: (json['id'] as num).toInt(),
    );

Map<String, dynamic> _$WorkoutExerciseToRemoveToJson(
        WorkoutExerciseToRemove instance) =>
    <String, dynamic>{
      'id': instance.id,
    };

WorkoutPlanResponse _$WorkoutPlanResponseFromJson(Map<String, dynamic> json) =>
    WorkoutPlanResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
    );

Map<String, dynamic> _$WorkoutPlanResponseToJson(
        WorkoutPlanResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
    };

WorkoutPlansResponse _$WorkoutPlansResponseFromJson(
        Map<String, dynamic> json) =>
    WorkoutPlansResponse(
      success: json['success'] as bool,
      schede: (json['schede'] as List<dynamic>)
          .map((e) => WorkoutPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WorkoutPlansResponseToJson(
        WorkoutPlansResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'schede': instance.schede,
    };

WorkoutExercisesResponse _$WorkoutExercisesResponseFromJson(
        Map<String, dynamic> json) =>
    WorkoutExercisesResponse(
      success: json['success'] as bool,
      esercizi: (json['esercizi'] as List<dynamic>)
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WorkoutExercisesResponseToJson(
        WorkoutExercisesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'esercizi': instance.esercizi,
    };
