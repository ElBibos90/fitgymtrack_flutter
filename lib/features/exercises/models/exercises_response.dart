// lib/features/exercises/models/exercises_response.dart
import 'package:json_annotation/json_annotation.dart';
import '../../../core/config/app_config.dart';
import 'muscle_group.dart';
import 'secondary_muscle.dart';

part 'exercises_response.g.dart';

class ExerciseItem {
  final int id;
  final String nome;
  @JsonKey(name: 'gruppo_muscolare')
  final String? gruppoMuscolare;
  final String? attrezzatura;
  final String? descrizione;
  final String? immagine;
  @JsonKey(name: 'immagine_nome')
  final String? immagineNome;
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
  @JsonKey(name: 'serie_default')
  final int serieDefault;
  @JsonKey(name: 'ripetizioni_default')
  final int ripetizioniDefault;
  @JsonKey(name: 'peso_default')
  final double pesoDefault;
  @JsonKey(name: 'is_isometric')
  final bool isIsometric;

  // ========== NUOVI CAMPI SISTEMA MUSCOLI ==========
  @JsonKey(name: 'primary_muscle_id')
  final int? primaryMuscleId;
  @JsonKey(name: 'primary_muscle')
  final MuscleGroup? primaryMuscle;
  @JsonKey(name: 'secondary_muscles')
  final List<SecondaryMuscle>? secondaryMuscles;
  @JsonKey(name: 'all_muscle_names')
  final List<String>? allMuscleNames;
  // ==================================================

  const ExerciseItem({
    required this.id,
    required this.nome,
    this.gruppoMuscolare,
    this.attrezzatura,
    this.descrizione,
    this.immagine,
    this.immagineNome,
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
    // ========== NUOVI CAMPI SISTEMA MUSCOLI ==========
    this.primaryMuscleId,
    this.primaryMuscle,
    this.secondaryMuscles,
    this.allMuscleNames,
    // ==================================================
  });

  // ========== GETTER SISTEMA MUSCOLI ==========
  bool get hasMuscleInfo => primaryMuscle != null || (allMuscleNames != null && allMuscleNames!.isNotEmpty);
  String get primaryMuscleName => primaryMuscle?.name ?? gruppoMuscolare ?? '';
  List<String> get allMuscles {
    if (allMuscleNames != null && allMuscleNames!.isNotEmpty) {
      return allMuscleNames!;
    }
    final muscles = <String>[];
    if (primaryMuscle != null) {
      muscles.add(primaryMuscle!.name);
    }
    if (secondaryMuscles != null) {
      muscles.addAll(secondaryMuscles!.map((m) => m.name));
    }
    return muscles.isNotEmpty ? muscles : [gruppoMuscolare ?? ''];
  }
  // ===========================================

  // ✅ Parsing manuale SICURO
  factory ExerciseItem.fromJson(Map<String, dynamic> json) {
    return ExerciseItem(
      id: _parseInt(json['id']) ?? 0,
      nome: json['nome'] as String? ?? '',
      gruppoMuscolare: json['gruppo_muscolare'] as String?,
      attrezzatura: json['attrezzatura'] as String?,
      descrizione: json['descrizione'] as String?,
      immagine: json['immagine'] as String?,
      immagineNome: json['immagine_nome'] as String?,
      isCustom: _parseBool(json['is_custom']) ?? false,
      createdBy: _parseInt(json['created_by']),
      dataCreazione: json['data_creazione'] as String?,
      isApproved: _parseBool(json['is_approved']) ?? true,
      categoria: json['categoria'] as String?,
      difficolta: json['difficolta'] as String?,
      istruzioni: json['istruzioni'] as String?,
      serieDefault: _parseInt(json['serie_default']) ?? 3,
      ripetizioniDefault: _parseInt(json['ripetizioni_default']) ?? 10,
      pesoDefault: _parseDouble(json['peso_default']) ?? 0.0,
      isIsometric: _parseBool(json['is_isometric']) ?? false,
      primaryMuscleId: _parseInt(json['primary_muscle_id']),
      primaryMuscle: json['primary_muscle'] != null ? MuscleGroup.fromJson(json['primary_muscle']) : null,
      secondaryMuscles: json['secondary_muscles'] != null 
          ? (json['secondary_muscles'] as List).map((m) => SecondaryMuscle.fromJson(m)).toList()
          : null,
      allMuscleNames: json['all_muscle_names'] != null 
          ? (json['all_muscle_names'] as List).cast<String>()
          : null,
    );
  }

  // ✅ Helper functions per parsing sicuro
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    if (value is int) return value != 0;
    return null;
  }

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
    return immagine?.isNotEmpty == true ? immagine : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'gruppo_muscolare': gruppoMuscolare,
      'attrezzatura': attrezzatura,
      'descrizione': descrizione,
      'immagine': immagine,
      'immagine_nome': immagineNome,
      'is_custom': isCustom,
      'created_by': createdBy,
      'data_creazione': dataCreazione,
      'is_approved': isApproved,
      'categoria': categoria,
      'difficolta': difficolta,
      'istruzioni': istruzioni,
      'serie_default': serieDefault,
      'ripetizioni_default': ripetizioniDefault,
      'peso_default': pesoDefault,
      'is_isometric': isIsometric,
      'primary_muscle_id': primaryMuscleId,
      'primary_muscle': primaryMuscle?.toJson(),
      'secondary_muscles': secondaryMuscles?.map((m) => m.toJson()).toList(),
      'all_muscle_names': allMuscleNames,
    };
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

/// Risposta per le immagini disponibili
@JsonSerializable()
class AvailableImagesResponse {
  final bool success;
  final List<String> images;
  final int count;

  const AvailableImagesResponse({
    required this.success,
    required this.images,
    required this.count,
  });

  factory AvailableImagesResponse.fromJson(Map<String, dynamic> json) =>
      _$AvailableImagesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AvailableImagesResponseToJson(this);
}