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
    );

Map<String, dynamic> _$UpdateWorkoutPlanResponseToJson(
        UpdateWorkoutPlanResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'scheda_id': instance.schedaId,
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
