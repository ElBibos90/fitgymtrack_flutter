// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_workout_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActiveWorkout _$ActiveWorkoutFromJson(Map<String, dynamic> json) =>
    ActiveWorkout(
      id: (json['id'] as num).toInt(),
      schedaId: (json['scheda_id'] as num).toInt(),
      dataAllenamento: json['data_allenamento'] as String,
      durataTotale: (json['durata_totale'] as num?)?.toInt(),
      note: json['note'] as String?,
      userId: (json['user_id'] as num).toInt(),
      esercizi: (json['esercizi'] as List<dynamic>?)
              ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sessionId: json['session_id'] as String?,
    );

Map<String, dynamic> _$ActiveWorkoutToJson(ActiveWorkout instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scheda_id': instance.schedaId,
      'data_allenamento': instance.dataAllenamento,
      'durata_totale': instance.durataTotale,
      'note': instance.note,
      'user_id': instance.userId,
      'esercizi': instance.esercizi,
      'session_id': instance.sessionId,
    };

StartWorkoutRequest _$StartWorkoutRequestFromJson(Map<String, dynamic> json) =>
    StartWorkoutRequest(
      userId: (json['user_id'] as num).toInt(),
      schedaId: (json['scheda_id'] as num).toInt(),
      sessionId: json['session_id'] as String,
    );

Map<String, dynamic> _$StartWorkoutRequestToJson(
        StartWorkoutRequest instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'scheda_id': instance.schedaId,
      'session_id': instance.sessionId,
    };

StartWorkoutResponse _$StartWorkoutResponseFromJson(
        Map<String, dynamic> json) =>
    StartWorkoutResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      allenamentoId: (json['allenamento_id'] as num).toInt(),
      sessionId: json['session_id'] as String?,
    );

Map<String, dynamic> _$StartWorkoutResponseToJson(
        StartWorkoutResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'allenamento_id': instance.allenamentoId,
      'session_id': instance.sessionId,
    };

CompletedSeries _$CompletedSeriesFromJson(Map<String, dynamic> json) =>
    CompletedSeries(
      id: json['id'] as String,
      serieNumber: (json['serieNumber'] as num).toInt(),
      peso: (json['peso'] as num).toDouble(),
      ripetizioni: (json['ripetizioni'] as num).toInt(),
      tempoRecupero: (json['tempo_recupero'] as num).toInt(),
      timestamp: json['timestamp'] as String,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$CompletedSeriesToJson(CompletedSeries instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serieNumber': instance.serieNumber,
      'peso': instance.peso,
      'ripetizioni': instance.ripetizioni,
      'tempo_recupero': instance.tempoRecupero,
      'timestamp': instance.timestamp,
      'note': instance.note,
    };

SaveCompletedSeriesRequest _$SaveCompletedSeriesRequestFromJson(
        Map<String, dynamic> json) =>
    SaveCompletedSeriesRequest(
      allenamentoId: (json['allenamento_id'] as num).toInt(),
      serie: (json['serie'] as List<dynamic>)
          .map((e) => SeriesData.fromJson(e as Map<String, dynamic>))
          .toList(),
      requestId: json['request_id'] as String,
    );

Map<String, dynamic> _$SaveCompletedSeriesRequestToJson(
        SaveCompletedSeriesRequest instance) =>
    <String, dynamic>{
      'allenamento_id': instance.allenamentoId,
      'serie': instance.serie,
      'request_id': instance.requestId,
    };

SeriesData _$SeriesDataFromJson(Map<String, dynamic> json) => SeriesData(
      schedaEsercizioId: (json['scheda_esercizio_id'] as num).toInt(),
      peso: _parseWeight(json['peso']),
      ripetizioni: (json['ripetizioni'] as num).toInt(),
      completata: (json['completata'] as num?)?.toInt() ?? 1,
      tempoRecupero: (json['tempo_recupero'] as num?)?.toInt(),
      note: json['note'] as String?,
      serieNumber: (json['serie_number'] as num?)?.toInt(),
      serieId: json['serie_id'] as String?,
    );

Map<String, dynamic> _$SeriesDataToJson(SeriesData instance) =>
    <String, dynamic>{
      'scheda_esercizio_id': instance.schedaEsercizioId,
      'peso': _weightToJson(instance.peso),
      'ripetizioni': instance.ripetizioni,
      'completata': instance.completata,
      'tempo_recupero': instance.tempoRecupero,
      'note': instance.note,
      'serie_number': instance.serieNumber,
      'serie_id': instance.serieId,
    };

SaveCompletedSeriesResponse _$SaveCompletedSeriesResponseFromJson(
        Map<String, dynamic> json) =>
    SaveCompletedSeriesResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
    );

Map<String, dynamic> _$SaveCompletedSeriesResponseToJson(
        SaveCompletedSeriesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
    };

GetCompletedSeriesResponse _$GetCompletedSeriesResponseFromJson(
        Map<String, dynamic> json) =>
    GetCompletedSeriesResponse(
      success: json['success'] as bool,
      serie: (json['serie'] as List<dynamic>)
          .map((e) => CompletedSeriesData.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$GetCompletedSeriesResponseToJson(
        GetCompletedSeriesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'serie': instance.serie,
      'count': instance.count,
    };

CompletedSeriesData _$CompletedSeriesDataFromJson(Map<String, dynamic> json) =>
    CompletedSeriesData(
      id: _parseIdSafe(json['id']),
      schedaEsercizioId: (json['scheda_esercizio_id'] as num).toInt(),
      peso: _parseWeight(json['peso']),
      ripetizioni: (json['ripetizioni'] as num).toInt(),
      completata: (json['completata'] as num).toInt(),
      tempoRecupero: (json['tempo_recupero'] as num?)?.toInt(),
      timestamp: json['timestamp'] as String,
      note: json['note'] as String?,
      serieNumber: (json['serie_number'] as num?)?.toInt(),
      esercizioId: (json['esercizio_id'] as num?)?.toInt(),
      esercizioNome: json['esercizio_nome'] as String?,
      realSerieNumber: (json['real_serie_number'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CompletedSeriesDataToJson(
        CompletedSeriesData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scheda_esercizio_id': instance.schedaEsercizioId,
      'peso': _weightToJson(instance.peso),
      'ripetizioni': instance.ripetizioni,
      'completata': instance.completata,
      'tempo_recupero': instance.tempoRecupero,
      'timestamp': instance.timestamp,
      'note': instance.note,
      'serie_number': instance.serieNumber,
      'esercizio_id': instance.esercizioId,
      'esercizio_nome': instance.esercizioNome,
      'real_serie_number': instance.realSerieNumber,
    };

CompleteWorkoutRequest _$CompleteWorkoutRequestFromJson(
        Map<String, dynamic> json) =>
    CompleteWorkoutRequest(
      allenamentoId: (json['allenamento_id'] as num).toInt(),
      durataTotale: (json['durata_totale'] as num).toInt(),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$CompleteWorkoutRequestToJson(
        CompleteWorkoutRequest instance) =>
    <String, dynamic>{
      'allenamento_id': instance.allenamentoId,
      'durata_totale': instance.durataTotale,
      'note': instance.note,
    };

CompleteWorkoutResponse _$CompleteWorkoutResponseFromJson(
        Map<String, dynamic> json) =>
    CompleteWorkoutResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      allenamentoId: (json['allenamento_id'] as num).toInt(),
      durataTotale: (json['durata_totale'] as num).toInt(),
    );

Map<String, dynamic> _$CompleteWorkoutResponseToJson(
        CompleteWorkoutResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'allenamento_id': instance.allenamentoId,
      'durata_totale': instance.durataTotale,
    };

DeleteWorkoutRequest _$DeleteWorkoutRequestFromJson(
        Map<String, dynamic> json) =>
    DeleteWorkoutRequest(
      allenamentoId: (json['allenamento_id'] as num).toInt(),
    );

Map<String, dynamic> _$DeleteWorkoutRequestToJson(
        DeleteWorkoutRequest instance) =>
    <String, dynamic>{
      'allenamento_id': instance.allenamentoId,
    };
