// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'muscle_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MuscleGroupsResponse _$MuscleGroupsResponseFromJson(
        Map<String, dynamic> json) =>
    MuscleGroupsResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => MuscleGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$MuscleGroupsResponseToJson(
        MuscleGroupsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'message': instance.message,
    };
