// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series_request_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteSeriesRequest _$DeleteSeriesRequestFromJson(Map<String, dynamic> json) =>
    DeleteSeriesRequest(
      serieId: json['serie_id'] as String,
    );

Map<String, dynamic> _$DeleteSeriesRequestToJson(
        DeleteSeriesRequest instance) =>
    <String, dynamic>{
      'serie_id': instance.serieId,
    };

UpdateSeriesRequest _$UpdateSeriesRequestFromJson(Map<String, dynamic> json) =>
    UpdateSeriesRequest(
      serieId: json['serie_id'] as String,
      peso: (json['peso'] as num).toDouble(),
      ripetizioni: (json['ripetizioni'] as num).toInt(),
      tempoRecupero: (json['tempo_recupero'] as num?)?.toInt(),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$UpdateSeriesRequestToJson(
        UpdateSeriesRequest instance) =>
    <String, dynamic>{
      'serie_id': instance.serieId,
      'peso': instance.peso,
      'ripetizioni': instance.ripetizioni,
      'tempo_recupero': instance.tempoRecupero,
      'note': instance.note,
    };

SeriesOperationResponse _$SeriesOperationResponseFromJson(
        Map<String, dynamic> json) =>
    SeriesOperationResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
    );

Map<String, dynamic> _$SeriesOperationResponseToJson(
        SeriesOperationResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
    };
