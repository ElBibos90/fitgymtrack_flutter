// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_history_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutHistory _$WorkoutHistoryFromJson(Map<String, dynamic> json) =>
    WorkoutHistory(
      id: (json['id'] as num).toInt(),
      schedaId: (json['scheda_id'] as num).toInt(),
      schedaNome: json['scheda_nome'] as String,
      dataAllenamento: json['data_allenamento'] as String,
      durataMinuti: (json['durata_minuti'] as num).toInt(),
      serieCompletate: (json['serie_completate'] as num).toInt(),
      pesoTotaleKg: (json['peso_totale_kg'] as num).toDouble(),
      note: json['note'] as String?,
      eserciziCompletati: (json['esercizi_completati'] as num).toInt(),
      eserciziTotali: (json['esercizi_totali'] as num).toInt(),
    );

Map<String, dynamic> _$WorkoutHistoryToJson(WorkoutHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scheda_id': instance.schedaId,
      'scheda_nome': instance.schedaNome,
      'data_allenamento': instance.dataAllenamento,
      'durata_minuti': instance.durataMinuti,
      'serie_completate': instance.serieCompletate,
      'peso_totale_kg': instance.pesoTotaleKg,
      'note': instance.note,
      'esercizi_completati': instance.eserciziCompletati,
      'esercizi_totali': instance.eserciziTotali,
    };

WorkoutHistoryResponse _$WorkoutHistoryResponseFromJson(
        Map<String, dynamic> json) =>
    WorkoutHistoryResponse(
      success: json['success'] as bool,
      allenamenti: (json['allenamenti'] as List<dynamic>)
          .map((e) => WorkoutHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$WorkoutHistoryResponseToJson(
        WorkoutHistoryResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'allenamenti': instance.allenamenti,
      'count': instance.count,
    };
