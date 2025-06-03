// lib/features/exercises/models/exercises_response.dart
import 'package:json_annotation/json_annotation.dart';

part 'exercises_response.g.dart';

/// Rappresenta un esercizio disponibile nel database
@JsonSerializable()
class ExerciseItem {
  final int id;
  final String nome;
  @JsonKey(name: 'gruppo_muscolare')
  final String? gruppoMuscolare;
  final String? attrezzatura;
  final String? descrizione;
  final String? immagine;
  @JsonKey(name: 'is_custom')
  final bool isCustom;
  @JsonKey(name: 'created_by')
  final int? createdBy;
  @JsonKey(name: 'data_creazione')
  final String? dataCreazione;
  @JsonKey(name: 'is_approved')
  final bool isApproved;
  final String? categoria;
  final String? difficolta;
  final String? istruzioni;

  // 🏋️ Valori default per gli allenamenti
  @JsonKey(name: 'serie_default')
  final int serieDefault;
  @JsonKey(name: 'ripetizioni_default')
  final int ripetizioniDefault;
  @JsonKey(name: 'peso_default')
  final double pesoDefault;
  @JsonKey(name: 'is_isometric')
  final bool isIsometric;

  const ExerciseItem({
    required this.id,
    required this.nome,
    this.gruppoMuscolare,
    this.attrezzatura,
    this.descrizione,
    this.immagine,
    this.isCustom = false,
    this.createdBy,
    this.dataCreazione,
    this.isApproved = true,
    this.categoria,
    this.difficolta,
    this.istruzioni,
    this.serieDefault = 3,
    this.ripetizioniDefault = 10,
    this.pesoDefault = 0.0,
    this.isIsometric = false,
  });

  factory ExerciseItem.fromJson(Map<String, dynamic> json) =>
      _$ExerciseItemFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseItemToJson(this);

  /// Copia con modifiche
  ExerciseItem copyWith({
    int? id,
    String? nome,
    String? gruppoMuscolare,
    String? attrezzatura,
    String? descrizione,
    String? immagine,
    bool? isCustom,
    int? createdBy,
    String? dataCreazione,
    bool? isApproved,
    String? categoria,
    String? difficolta,
    String? istruzioni,
    int? serieDefault,
    int? ripetizioniDefault,
    double? pesoDefault,
    bool? isIsometric,
  }) {
    return ExerciseItem(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      gruppoMuscolare: gruppoMuscolare ?? this.gruppoMuscolare,
      attrezzatura: attrezzatura ?? this.attrezzatura,
      descrizione: descrizione ?? this.descrizione,
      immagine: immagine ?? this.immagine,
      isCustom: isCustom ?? this.isCustom,
      createdBy: createdBy ?? this.createdBy,
      dataCreazione: dataCreazione ?? this.dataCreazione,
      isApproved: isApproved ?? this.isApproved,
      categoria: categoria ?? this.categoria,
      difficolta: difficolta ?? this.difficolta,
      istruzioni: istruzioni ?? this.istruzioni,
      serieDefault: serieDefault ?? this.serieDefault,
      ripetizioniDefault: ripetizioniDefault ?? this.ripetizioniDefault,
      pesoDefault: pesoDefault ?? this.pesoDefault,
      isIsometric: isIsometric ?? this.isIsometric,
    );
  }
}

/// Risposta API per gli esercizi disponibili
@JsonSerializable()
class ExercisesResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'esercizi')
  final List<ExerciseItem> esercizi;
  final int count;

  const ExercisesResponse({
    required this.success,
    required this.message,
    required this.esercizi,
    required this.count,
  });

  factory ExercisesResponse.fromJson(Map<String, dynamic> json) =>
      _$ExercisesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExercisesResponseToJson(this);
}

/// Categoria di esercizio
@JsonSerializable()
class ExerciseCategory {
  final int id;
  final String nome;
  final String? descrizione;
  final String? icona;
  final String? colore;

  const ExerciseCategory({
    required this.id,
    required this.nome,
    this.descrizione,
    this.icona,
    this.colore,
  });

  factory ExerciseCategory.fromJson(Map<String, dynamic> json) =>
      _$ExerciseCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseCategoryToJson(this);
}

/// Gruppo muscolare
@JsonSerializable()
class MuscleGroup {
  final int id;
  final String nome;
  final String? descrizione;
  final String? immagine;

  const MuscleGroup({
    required this.id,
    required this.nome,
    this.descrizione,
    this.immagine,
  });

  factory MuscleGroup.fromJson(Map<String, dynamic> json) =>
      _$MuscleGroupFromJson(json);

  Map<String, dynamic> toJson() => _$MuscleGroupToJson(this);
}

/// Attrezzatura per esercizi
@JsonSerializable()
class Equipment {
  final int id;
  final String nome;
  final String? descrizione;
  final String? immagine;
  final String? categoria;

  const Equipment({
    required this.id,
    required this.nome,
    this.descrizione,
    this.immagine,
    this.categoria,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) =>
      _$EquipmentFromJson(json);

  Map<String, dynamic> toJson() => _$EquipmentToJson(this);
}

/// Richiesta per creare un esercizio personalizzato
@JsonSerializable()
class CreateCustomExerciseRequest {
  @JsonKey(name: 'user_id')
  final int userId;
  final String nome;
  @JsonKey(name: 'gruppo_muscolare')
  final String? gruppoMuscolare;
  final String? attrezzatura;
  final String? descrizione;
  final String? istruzioni;
  final String? categoria;
  final String? difficolta;

  const CreateCustomExerciseRequest({
    required this.userId,
    required this.nome,
    this.gruppoMuscolare,
    this.attrezzatura,
    this.descrizione,
    this.istruzioni,
    this.categoria,
    this.difficolta,
  });

  factory CreateCustomExerciseRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCustomExerciseRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCustomExerciseRequestToJson(this);
}

/// Risposta per operazioni su esercizi personalizzati
@JsonSerializable()
class CustomExerciseResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'exercise_id')
  final int? exerciseId;

  const CustomExerciseResponse({
    required this.success,
    required this.message,
    this.exerciseId,
  });

  factory CustomExerciseResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomExerciseResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CustomExerciseResponseToJson(this);
}