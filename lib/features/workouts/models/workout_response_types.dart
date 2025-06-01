// lib/features/workouts/models/workout_response_types.dart
import 'package:json_annotation/json_annotation.dart';

part 'workout_response_types.g.dart';

/// Response per la creazione di una scheda di allenamento
@JsonSerializable()
class CreateWorkoutPlanResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'scheda_id')
  final int? schedaId;

  const CreateWorkoutPlanResponse({
    required this.success,
    required this.message,
    this.schedaId,
  });

  factory CreateWorkoutPlanResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateWorkoutPlanResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateWorkoutPlanResponseToJson(this);
}

/// Response per l'aggiornamento di una scheda di allenamento
@JsonSerializable()
class UpdateWorkoutPlanResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'scheda_id')
  final int? schedaId;

  const UpdateWorkoutPlanResponse({
    required this.success,
    required this.message,
    this.schedaId,
  });

  factory UpdateWorkoutPlanResponse.fromJson(Map<String, dynamic> json) =>
      _$UpdateWorkoutPlanResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateWorkoutPlanResponseToJson(this);
}

/// Response per l'eliminazione di una scheda di allenamento
@JsonSerializable()
class DeleteWorkoutPlanResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'scheda_id')
  final int? schedaId;

  const DeleteWorkoutPlanResponse({
    required this.success,
    required this.message,
    this.schedaId,
  });

  factory DeleteWorkoutPlanResponse.fromJson(Map<String, dynamic> json) =>
      _$DeleteWorkoutPlanResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteWorkoutPlanResponseToJson(this);
}