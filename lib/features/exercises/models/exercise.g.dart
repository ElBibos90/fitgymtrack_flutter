// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Exercise _$ExerciseFromJson(Map<String, dynamic> json) => Exercise(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      descrizione: json['descrizione'] as String,
      immagineUrl: json['immagine_url'] as String,
      immagineNome: json['immagine_nome'] as String?,
      gruppoMuscolare: json['gruppo_muscolare'] as String,
      attrezzatura: json['attrezzatura'] as String,
      isIsometric: (json['is_isometric'] as num?)?.toInt() ?? 0,
      equipmentTypeId: (json['equipment_type_id'] as num?)?.toInt(),
      status: json['status'] as String?,
      primaryMuscleId: (json['primary_muscle_id'] as num?)?.toInt(),
      primaryMuscle: json['primary_muscle'] == null
          ? null
          : MuscleGroup.fromJson(
              json['primary_muscle'] as Map<String, dynamic>),
      secondaryMuscles: (json['secondary_muscles'] as List<dynamic>?)
          ?.map((e) => SecondaryMuscle.fromJson(e as Map<String, dynamic>))
          .toList(),
      allMuscleNames: (json['all_muscle_names'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ExerciseToJson(Exercise instance) => <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'descrizione': instance.descrizione,
      'immagine_url': instance.immagineUrl,
      'immagine_nome': instance.immagineNome,
      'gruppo_muscolare': instance.gruppoMuscolare,
      'attrezzatura': instance.attrezzatura,
      'is_isometric': instance.isIsometric,
      'equipment_type_id': instance.equipmentTypeId,
      'status': instance.status,
      'primary_muscle_id': instance.primaryMuscleId,
      'primary_muscle': instance.primaryMuscle,
      'secondary_muscles': instance.secondaryMuscles,
      'all_muscle_names': instance.allMuscleNames,
    };

UserExercise _$UserExerciseFromJson(Map<String, dynamic> json) => UserExercise(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      gruppoMuscolare: json['gruppo_muscolare'] as String,
      descrizione: json['descrizione'] as String?,
      attrezzatura: json['attrezzatura'] as String?,
      isIsometricInt: (json['is_isometric'] as num?)?.toInt() ?? 0,
      createdByUserId: (json['created_by_user_id'] as num).toInt(),
      status: json['status'] as String? ?? 'pending_review',
      immagineUrl: json['immagine_url'] as String?,
      immagineNome: json['immagine_nome'] as String?,
      primaryMuscleId: (json['primary_muscle_id'] as num?)?.toInt(),
      primaryMuscle: json['primary_muscle'] == null
          ? null
          : MuscleGroup.fromJson(
              json['primary_muscle'] as Map<String, dynamic>),
      secondaryMuscles: (json['secondary_muscles'] as List<dynamic>?)
          ?.map((e) => SecondaryMuscle.fromJson(e as Map<String, dynamic>))
          .toList(),
      allMuscleNames: (json['all_muscle_names'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UserExerciseToJson(UserExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'gruppo_muscolare': instance.gruppoMuscolare,
      'descrizione': instance.descrizione,
      'attrezzatura': instance.attrezzatura,
      'is_isometric': instance.isIsometricInt,
      'created_by_user_id': instance.createdByUserId,
      'status': instance.status,
      'immagine_url': instance.immagineUrl,
      'immagine_nome': instance.immagineNome,
      'primary_muscle_id': instance.primaryMuscleId,
      'primary_muscle': instance.primaryMuscle,
      'secondary_muscles': instance.secondaryMuscles,
      'all_muscle_names': instance.allMuscleNames,
    };

CreateUserExerciseRequest _$CreateUserExerciseRequestFromJson(
        Map<String, dynamic> json) =>
    CreateUserExerciseRequest(
      nome: json['nome'] as String,
      gruppoMuscolare: json['gruppo_muscolare'] as String,
      descrizione: json['descrizione'] as String?,
      attrezzatura: json['attrezzatura'] as String?,
      isIsometric: json['is_isometric'] as bool? ?? false,
      createdByUserId: (json['created_by_user_id'] as num).toInt(),
      status: json['status'] as String? ?? 'pending_review',
      primaryMuscleId: (json['primary_muscle_id'] as num?)?.toInt(),
      secondaryMuscles: (json['secondary_muscles'] as List<dynamic>?)
          ?.map(
              (e) => SecondaryMuscleRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreateUserExerciseRequestToJson(
        CreateUserExerciseRequest instance) =>
    <String, dynamic>{
      'nome': instance.nome,
      'gruppo_muscolare': instance.gruppoMuscolare,
      'descrizione': instance.descrizione,
      'attrezzatura': instance.attrezzatura,
      'is_isometric': instance.isIsometric,
      'created_by_user_id': instance.createdByUserId,
      'status': instance.status,
      'primary_muscle_id': instance.primaryMuscleId,
      'secondary_muscles': instance.secondaryMuscles,
    };

UpdateUserExerciseRequest _$UpdateUserExerciseRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateUserExerciseRequest(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      gruppoMuscolare: json['gruppo_muscolare'] as String,
      descrizione: json['descrizione'] as String?,
      attrezzatura: json['attrezzatura'] as String?,
      isIsometric: json['is_isometric'] as bool? ?? false,
      userId: (json['user_id'] as num).toInt(),
      primaryMuscleId: (json['primary_muscle_id'] as num?)?.toInt(),
      secondaryMuscles: (json['secondary_muscles'] as List<dynamic>?)
          ?.map(
              (e) => SecondaryMuscleRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UpdateUserExerciseRequestToJson(
        UpdateUserExerciseRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'gruppo_muscolare': instance.gruppoMuscolare,
      'descrizione': instance.descrizione,
      'attrezzatura': instance.attrezzatura,
      'is_isometric': instance.isIsometric,
      'user_id': instance.userId,
      'primary_muscle_id': instance.primaryMuscleId,
      'secondary_muscles': instance.secondaryMuscles,
    };

UserExerciseResponse _$UserExerciseResponseFromJson(
        Map<String, dynamic> json) =>
    UserExerciseResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      exerciseId: (json['exercise_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserExerciseResponseToJson(
        UserExerciseResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'exercise_id': instance.exerciseId,
    };

UserExercisesResponse _$UserExercisesResponseFromJson(
        Map<String, dynamic> json) =>
    UserExercisesResponse(
      success: json['success'] as bool,
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((e) => UserExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$UserExercisesResponseToJson(
        UserExercisesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'exercises': instance.exercises,
      'message': instance.message,
    };

DeleteUserExerciseRequest _$DeleteUserExerciseRequestFromJson(
        Map<String, dynamic> json) =>
    DeleteUserExerciseRequest(
      exerciseId: (json['exercise_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
    );

Map<String, dynamic> _$DeleteUserExerciseRequestToJson(
        DeleteUserExerciseRequest instance) =>
    <String, dynamic>{
      'exercise_id': instance.exerciseId,
      'user_id': instance.userId,
    };
