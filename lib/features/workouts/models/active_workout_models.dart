// lib/features/workouts/models/active_workout_models.dart
// 🚀 FASE 5: VERSIONE COMPLETA CON SUPPORTO REST-PAUSE

import 'package:json_annotation/json_annotation.dart';

part 'active_workout_models.g.dart';

// ============================================================================
// PARSING HELPER FUNCTIONS
// ============================================================================

/// Helper per parsare in modo sicuro i pesi (stringa -> double)
double _parseWeight(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final cleaned = value.replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }
  return 0.0;
}

/// Helper per convertire peso in stringa JSON-safe
String _weightToJson(double? weight) => (weight ?? 0.0).toString();

/// Helper per parsare ID in modo sicuro (evita null e numeri)
String _parseIdSafe(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is int) return value.toString();
  if (value is double) return value.toInt().toString();
  return value.toString();
}

// ============================================================================
// ACTIVE WORKOUT MODELS
// ============================================================================

/// Rappresenta un allenamento attivo in corso
@JsonSerializable()
class ActiveWorkout {
  final int id;
  @JsonKey(name: 'scheda_id')
  final int schedaId;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'data_inizio')
  final String dataInizio;
  @JsonKey(name: 'durata_totale')
  final int? durataTotale;
  final String? note;
  final String stato;
  @JsonKey(name: 'session_id')
  final String? sessionId;

  const ActiveWorkout({
    required this.id,
    required this.schedaId,
    required this.userId,
    required this.dataInizio,
    this.durataTotale,
    this.note,
    required this.stato,
    this.sessionId,
  });

  factory ActiveWorkout.fromJson(Map<String, dynamic> json) => _$ActiveWorkoutFromJson(json);
  Map<String, dynamic> toJson() => _$ActiveWorkoutToJson(this);
}

/// Risposta per l'avvio di un nuovo allenamento
@JsonSerializable()
class StartWorkoutResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'allenamento_id')
  final int allenamentoId;
  @JsonKey(name: 'session_id')
  final String? sessionId;

  const StartWorkoutResponse({
    required this.success,
    required this.message,
    required this.allenamentoId,
    this.sessionId,
  });

  factory StartWorkoutResponse.fromJson(Map<String, dynamic> json) => _$StartWorkoutResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StartWorkoutResponseToJson(this);
}

/// Rappresenta una serie completata durante l'allenamento
@JsonSerializable()
class CompletedSeries {
  final String id;
  final int serieNumber;
  final double peso;
  final int ripetizioni;
  @JsonKey(name: 'tempo_recupero')
  final int tempoRecupero;
  final String timestamp;
  final String? note;

  const CompletedSeries({
    required this.id,
    required this.serieNumber,
    required this.peso,
    required this.ripetizioni,
    required this.tempoRecupero,
    required this.timestamp,
    this.note,
  });

  factory CompletedSeries.fromJson(Map<String, dynamic> json) => _$CompletedSeriesFromJson(json);
  Map<String, dynamic> toJson() => _$CompletedSeriesToJson(this);
}

/// Richiesta per salvare una serie completata
@JsonSerializable()
class SaveCompletedSeriesRequest {
  @JsonKey(name: 'allenamento_id')
  final int allenamentoId;
  final List<SeriesData> serie;
  @JsonKey(name: 'request_id')
  final String requestId;

  const SaveCompletedSeriesRequest({
    required this.allenamentoId,
    required this.serie,
    required this.requestId,
  });

  factory SaveCompletedSeriesRequest.fromJson(Map<String, dynamic> json) => _$SaveCompletedSeriesRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SaveCompletedSeriesRequestToJson(this);
}

/// Dati di una singola serie da salvare
/// 🚀 FASE 5: AGGIORNATO CON CAMPI REST-PAUSE
@JsonSerializable()
class SeriesData {
  @JsonKey(name: 'scheda_esercizio_id')
  final int schedaEsercizioId;

  @JsonKey(
    name: 'peso',
    fromJson: _parseWeight,
    toJson: _weightToJson,
  )
  final double peso;

  final int ripetizioni;
  final int completata;
  @JsonKey(name: 'tempo_recupero')
  final int? tempoRecupero;
  final String? note;
  @JsonKey(name: 'serie_number')
  final int? serieNumber;
  @JsonKey(name: 'serie_id')
  final String? serieId;

  // 🚀 FASE 5: NUOVI CAMPI REST-PAUSE
  @JsonKey(name: 'is_rest_pause')
  final int? isRestPause;
  @JsonKey(name: 'rest_pause_reps')
  final String? restPauseReps;
  @JsonKey(name: 'rest_pause_rest_seconds')
  final int? restPauseRestSeconds;

  const SeriesData({
    required this.schedaEsercizioId,
    required this.peso,
    required this.ripetizioni,
    this.completata = 1,
    this.tempoRecupero,
    this.note,
    this.serieNumber,
    this.serieId,
    // 🚀 FASE 5: Parametri REST-PAUSE opzionali (backward compatible)
    this.isRestPause,
    this.restPauseReps,
    this.restPauseRestSeconds,
  });

  // 🚀 FASE 5: Factory method per creare SeriesData REST-PAUSE
  factory SeriesData.restPause({
    required int schedaEsercizioId,
    required double peso,
    required int ripetizioni,
    required String restPauseReps,
    required int restPauseRestSeconds,
    int completata = 1,
    int? tempoRecupero,
    String? note,
    int? serieNumber,
    String? serieId,
  }) {
    return SeriesData(
      schedaEsercizioId: schedaEsercizioId,
      peso: peso,
      ripetizioni: ripetizioni,
      completata: completata,
      tempoRecupero: tempoRecupero,
      note: note,
      serieNumber: serieNumber,
      serieId: serieId,
      // Campi REST-PAUSE
      isRestPause: 1,
      restPauseReps: restPauseReps,
      restPauseRestSeconds: restPauseRestSeconds,
    );
  }

  factory SeriesData.fromJson(Map<String, dynamic> json) => _$SeriesDataFromJson(json);
  Map<String, dynamic> toJson() => _$SeriesDataToJson(this);
}

/// Risposta generica per le operazioni sulle serie
@JsonSerializable()
class SaveCompletedSeriesResponse {
  final bool success;
  final String message;

  const SaveCompletedSeriesResponse({
    required this.success,
    required this.message,
  });

  factory SaveCompletedSeriesResponse.fromJson(Map<String, dynamic> json) => _$SaveCompletedSeriesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SaveCompletedSeriesResponseToJson(this);
}

/// Risposta per ottenere le serie completate
@JsonSerializable()
class GetCompletedSeriesResponse {
  final bool success;
  final List<CompletedSeriesData> serie;
  final int count;

  const GetCompletedSeriesResponse({
    required this.success,
    required this.serie,
    required this.count,
  });

  factory GetCompletedSeriesResponse.fromJson(Map<String, dynamic> json) => _$GetCompletedSeriesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GetCompletedSeriesResponseToJson(this);
}

/// Dati di una serie completata ricevuta dal server
/// 🚀 FASE 5: AGGIORNATO CON CAMPI REST-PAUSE
@JsonSerializable()
class CompletedSeriesData {
  @JsonKey(fromJson: _parseIdSafe)
  final String id;
  @JsonKey(name: 'scheda_esercizio_id')
  final int schedaEsercizioId;

  @JsonKey(
    name: 'peso',
    fromJson: _parseWeight,
    toJson: _weightToJson,
  )
  final double peso;

  final int ripetizioni;
  final int completata;
  @JsonKey(name: 'tempo_recupero')
  final int? tempoRecupero;
  final String timestamp;
  final String? note;
  @JsonKey(name: 'serie_number')
  final int? serieNumber;
  @JsonKey(name: 'esercizio_id')
  final int? esercizioId;
  @JsonKey(name: 'esercizio_nome')
  final String? esercizioNome;
  @JsonKey(name: 'real_serie_number')
  final int? realSerieNumber;

  // 🚀 FASE 5: NUOVI CAMPI REST-PAUSE per CompletedSeriesData
  @JsonKey(name: 'is_rest_pause')
  final int? isRestPause;
  @JsonKey(name: 'rest_pause_reps')
  final String? restPauseReps;
  @JsonKey(name: 'rest_pause_rest_seconds')
  final int? restPauseRestSeconds;

  const CompletedSeriesData({
    required this.id,
    required this.schedaEsercizioId,
    required this.peso,
    required this.ripetizioni,
    required this.completata,
    this.tempoRecupero,
    required this.timestamp,
    this.note,
    this.serieNumber,
    this.esercizioId,
    this.esercizioNome,
    this.realSerieNumber,
    // 🚀 FASE 5: Parametri REST-PAUSE
    this.isRestPause,
    this.restPauseReps,
    this.restPauseRestSeconds,
  });

  // 🚀 FASE 5: Proprietà calcolata per identificare serie REST-PAUSE
  bool get isRestPauseSeries => (isRestPause ?? 0) > 0;

  factory CompletedSeriesData.fromJson(Map<String, dynamic> json) => _$CompletedSeriesDataFromJson(json);
  Map<String, dynamic> toJson() => _$CompletedSeriesDataToJson(this);
}