import 'package:json_annotation/json_annotation.dart';
import '../../../core/config/app_config.dart';

part 'exercise.g.dart';

/// Modello per rappresentare un esercizio restituito dall'API esercizi.php
@JsonSerializable()
class Exercise {
  final int id;
  final String nome;
  final String descrizione;
  @JsonKey(name: 'immagine_url')
  final String immagineUrl;
  @JsonKey(name: 'immagine_nome')
  final String? immagineNome;
  @JsonKey(name: 'gruppo_muscolare')
  final String gruppoMuscolare;
  final String attrezzatura;
  @JsonKey(name: 'is_isometric')
  final int isIsometric;
  @JsonKey(name: 'equipment_type_id')
  final int? equipmentTypeId;
  final String? status;

  const Exercise({
    required this.id,
    required this.nome,
    required this.descrizione,
    required this.immagineUrl,
    this.immagineNome,
    required this.gruppoMuscolare,
    required this.attrezzatura,
    this.isIsometric = 0,
    this.equipmentTypeId,
    this.status,
  });

  /// Proprietà calcolata per facilitare l'uso
  bool get isIsometricBool => isIsometric > 0;

  /// URL completo per l'immagine GIF
  String? get imageUrl {
    if (immagineNome != null && immagineNome!.isNotEmpty) {
      // Rimuovi eventuali slash finali da baseUrl per evitare doppi slash
      String baseUrl = AppConfig.baseUrl;
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      return '$baseUrl/serve_image.php?filename=$immagineNome';
    }
    return immagineUrl.isNotEmpty ? immagineUrl : null;
  }

  factory Exercise.fromJson(Map<String, dynamic> json) => _$ExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseToJson(this);
}

/// Rappresenta un esercizio personalizzato creato dall'utente
@JsonSerializable()
class UserExercise {
  final int id;
  final String nome;
  @JsonKey(name: 'gruppo_muscolare')
  final String gruppoMuscolare;
  final String? descrizione;
  final String? attrezzatura;
  @JsonKey(name: 'is_isometric')
  final int isIsometricInt;
  @JsonKey(name: 'created_by_user_id')
  final int createdByUserId;
  final String status;
  @JsonKey(name: 'immagine_url')
  final String? immagineUrl;
  @JsonKey(name: 'immagine_nome')
  final String? immagineNome;

  const UserExercise({
    required this.id,
    required this.nome,
    required this.gruppoMuscolare,
    this.descrizione,
    this.attrezzatura,
    this.isIsometricInt = 0,
    required this.createdByUserId,
    this.status = 'pending_review',
    this.immagineUrl,
    this.immagineNome,
  });

  /// Proprietà calcolata per convertire Int a Boolean
  bool get isIsometric => isIsometricInt > 0;

  /// URL completo per l'immagine GIF
  String? get imageUrl {
    if (immagineNome != null && immagineNome!.isNotEmpty) {
      // Rimuovi eventuali slash finali da baseUrl per evitare doppi slash
      String baseUrl = AppConfig.baseUrl;
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      return '$baseUrl/serve_image.php?filename=$immagineNome';
    }
    return immagineUrl?.isNotEmpty == true ? immagineUrl : null;
  }

  factory UserExercise.fromJson(Map<String, dynamic> json) => _$UserExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$UserExerciseToJson(this);
}

/// Classe per la richiesta di creazione di un nuovo esercizio
@JsonSerializable()
class CreateUserExerciseRequest {
  final String nome;
  @JsonKey(name: 'gruppo_muscolare')
  final String gruppoMuscolare;
  final String? descrizione;
  final String? attrezzatura;
  @JsonKey(name: 'is_isometric')
  final bool isIsometric;
  @JsonKey(name: 'created_by_user_id')
  final int createdByUserId;
  final String status;

  const CreateUserExerciseRequest({
    required this.nome,
    required this.gruppoMuscolare,
    this.descrizione,
    this.attrezzatura,
    this.isIsometric = false,
    required this.createdByUserId,
    this.status = 'pending_review',
  });

  factory CreateUserExerciseRequest.fromJson(Map<String, dynamic> json) => _$CreateUserExerciseRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateUserExerciseRequestToJson(this);
}

/// Classe per la richiesta di aggiornamento di un esercizio esistente
@JsonSerializable()
class UpdateUserExerciseRequest {
  final int id;
  final String nome;
  @JsonKey(name: 'gruppo_muscolare')
  final String gruppoMuscolare;
  final String? descrizione;
  final String? attrezzatura;
  @JsonKey(name: 'is_isometric')
  final bool isIsometric;
  @JsonKey(name: 'user_id')
  final int userId;

  const UpdateUserExerciseRequest({
    required this.id,
    required this.nome,
    required this.gruppoMuscolare,
    this.descrizione,
    this.attrezzatura,
    this.isIsometric = false,
    required this.userId,
  });

  factory UpdateUserExerciseRequest.fromJson(Map<String, dynamic> json) => _$UpdateUserExerciseRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateUserExerciseRequestToJson(this);
}

/// Risposta generica per le operazioni sugli esercizi
@JsonSerializable()
class UserExerciseResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'exercise_id')
  final int? exerciseId;

  const UserExerciseResponse({
    required this.success,
    required this.message,
    this.exerciseId,
  });

  factory UserExerciseResponse.fromJson(Map<String, dynamic> json) => _$UserExerciseResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserExerciseResponseToJson(this);
}

/// Risposta per l'elenco degli esercizi
@JsonSerializable()
class UserExercisesResponse {
  final bool success;
  final List<UserExercise>? exercises;
  final String? message;

  const UserExercisesResponse({
    required this.success,
    this.exercises,
    this.message,
  });

  factory UserExercisesResponse.fromJson(Map<String, dynamic> json) => _$UserExercisesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserExercisesResponseToJson(this);
}

/// Richiesta per l'eliminazione di un esercizio
@JsonSerializable()
class DeleteUserExerciseRequest {
  @JsonKey(name: 'exercise_id')
  final int exerciseId;
  @JsonKey(name: 'user_id')
  final int userId;

  const DeleteUserExerciseRequest({
    required this.exerciseId,
    required this.userId,
  });

  factory DeleteUserExerciseRequest.fromJson(Map<String, dynamic> json) => _$DeleteUserExerciseRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DeleteUserExerciseRequestToJson(this);
}