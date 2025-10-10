// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secondary_muscle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecondaryMuscleRequest _$SecondaryMuscleRequestFromJson(
        Map<String, dynamic> json) =>
    SecondaryMuscleRequest(
      muscleId: (json['muscle_id'] as num).toInt(),
      activationLevel: json['activation_level'] as String,
    );

Map<String, dynamic> _$SecondaryMuscleRequestToJson(
        SecondaryMuscleRequest instance) =>
    <String, dynamic>{
      'muscle_id': instance.muscleId,
      'activation_level': instance.activationLevel,
    };
