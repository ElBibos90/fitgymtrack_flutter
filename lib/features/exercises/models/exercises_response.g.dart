// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercises_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExercisesResponse _$ExercisesResponseFromJson(Map<String, dynamic> json) =>
    ExercisesResponse(
      success: json['success'] as bool,
      esercizi: (json['esercizi'] as List<dynamic>)
          .map((e) => ExerciseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$ExercisesResponseToJson(ExercisesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'esercizi': instance.esercizi,
      'message': instance.message,
    };

ExerciseItem _$ExerciseItemFromJson(Map<String, dynamic> json) => ExerciseItem(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      descrizione: json['descrizione'] as String?,
      gruppoMuscolare: json['gruppo_muscolare'] as String?,
      attrezzatura: json['attrezzatura'] as String?,
      immagineUrl: json['immagine_url'] as String?,
      isIsometric: json['is_isometric'] as bool? ?? false,
      serieDefault: (json['serie_default'] as num?)?.toInt(),
      ripetizioniDefault: (json['ripetizioni_default'] as num?)?.toInt(),
      pesoDefault: (json['peso_default'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ExerciseItemToJson(ExerciseItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'descrizione': instance.descrizione,
      'gruppo_muscolare': instance.gruppoMuscolare,
      'attrezzatura': instance.attrezzatura,
      'immagine_url': instance.immagineUrl,
      'is_isometric': instance.isIsometric,
      'serie_default': instance.serieDefault,
      'ripetizioni_default': instance.ripetizioniDefault,
      'peso_default': instance.pesoDefault,
    };
