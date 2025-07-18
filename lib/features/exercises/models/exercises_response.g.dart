// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercises_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExerciseItem _$ExerciseItemFromJson(Map<String, dynamic> json) => ExerciseItem(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      gruppoMuscolare: json['gruppo_muscolare'] as String?,
      attrezzatura: json['attrezzatura'] as String?,
      descrizione: json['descrizione'] as String?,
      immagine: json['immagine'] as String?,
      immagineNome: json['immagine_nome'] as String?,
      isCustom: json['is_custom'] as bool? ?? false,
      createdBy: (json['created_by'] as num?)?.toInt(),
      dataCreazione: json['data_creazione'] as String?,
      isApproved: json['is_approved'] as bool? ?? true,
      categoria: json['categoria'] as String?,
      difficolta: json['difficolta'] as String?,
      istruzioni: json['istruzioni'] as String?,
      serieDefault: (json['serie_default'] as num?)?.toInt() ?? 3,
      ripetizioniDefault: (json['ripetizioni_default'] as num?)?.toInt() ?? 10,
      pesoDefault: (json['peso_default'] as num?)?.toDouble() ?? 0.0,
      isIsometric: json['is_isometric'] as bool? ?? false,
    );

Map<String, dynamic> _$ExerciseItemToJson(ExerciseItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'gruppo_muscolare': instance.gruppoMuscolare,
      'attrezzatura': instance.attrezzatura,
      'descrizione': instance.descrizione,
      'immagine': instance.immagine,
      'immagine_nome': instance.immagineNome,
      'is_custom': instance.isCustom,
      'created_by': instance.createdBy,
      'data_creazione': instance.dataCreazione,
      'is_approved': instance.isApproved,
      'categoria': instance.categoria,
      'difficolta': instance.difficolta,
      'istruzioni': instance.istruzioni,
      'serie_default': instance.serieDefault,
      'ripetizioni_default': instance.ripetizioniDefault,
      'peso_default': instance.pesoDefault,
      'is_isometric': instance.isIsometric,
    };

ExercisesResponse _$ExercisesResponseFromJson(Map<String, dynamic> json) =>
    ExercisesResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      esercizi: (json['esercizi'] as List<dynamic>)
          .map((e) => ExerciseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$ExercisesResponseToJson(ExercisesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'esercizi': instance.esercizi,
      'count': instance.count,
    };

ExerciseCategory _$ExerciseCategoryFromJson(Map<String, dynamic> json) =>
    ExerciseCategory(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      descrizione: json['descrizione'] as String?,
      icona: json['icona'] as String?,
      colore: json['colore'] as String?,
    );

Map<String, dynamic> _$ExerciseCategoryToJson(ExerciseCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'descrizione': instance.descrizione,
      'icona': instance.icona,
      'colore': instance.colore,
    };

MuscleGroup _$MuscleGroupFromJson(Map<String, dynamic> json) => MuscleGroup(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      descrizione: json['descrizione'] as String?,
      immagine: json['immagine'] as String?,
    );

Map<String, dynamic> _$MuscleGroupToJson(MuscleGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'descrizione': instance.descrizione,
      'immagine': instance.immagine,
    };

Equipment _$EquipmentFromJson(Map<String, dynamic> json) => Equipment(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      descrizione: json['descrizione'] as String?,
      immagine: json['immagine'] as String?,
      categoria: json['categoria'] as String?,
    );

Map<String, dynamic> _$EquipmentToJson(Equipment instance) => <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'descrizione': instance.descrizione,
      'immagine': instance.immagine,
      'categoria': instance.categoria,
    };

CreateCustomExerciseRequest _$CreateCustomExerciseRequestFromJson(
        Map<String, dynamic> json) =>
    CreateCustomExerciseRequest(
      userId: (json['user_id'] as num).toInt(),
      nome: json['nome'] as String,
      gruppoMuscolare: json['gruppo_muscolare'] as String?,
      attrezzatura: json['attrezzatura'] as String?,
      descrizione: json['descrizione'] as String?,
      istruzioni: json['istruzioni'] as String?,
      categoria: json['categoria'] as String?,
      difficolta: json['difficolta'] as String?,
    );

Map<String, dynamic> _$CreateCustomExerciseRequestToJson(
        CreateCustomExerciseRequest instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'nome': instance.nome,
      'gruppo_muscolare': instance.gruppoMuscolare,
      'attrezzatura': instance.attrezzatura,
      'descrizione': instance.descrizione,
      'istruzioni': instance.istruzioni,
      'categoria': instance.categoria,
      'difficolta': instance.difficolta,
    };

CustomExerciseResponse _$CustomExerciseResponseFromJson(
        Map<String, dynamic> json) =>
    CustomExerciseResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      exerciseId: (json['exercise_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CustomExerciseResponseToJson(
        CustomExerciseResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'exercise_id': instance.exerciseId,
    };

AvailableImagesResponse _$AvailableImagesResponseFromJson(
        Map<String, dynamic> json) =>
    AvailableImagesResponse(
      success: json['success'] as bool,
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$AvailableImagesResponseToJson(
        AvailableImagesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'images': instance.images,
      'count': instance.count,
    };
