// lib/features/workouts/models/active_workout_models.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'workout_plan_models.dart';

part 'active_workout_models.g.dart';

/// Converte il peso dal JSON (può essere stringa o numero) a double
double _parseWeight(dynamic value) {
  if (value == null) return 0.0;

  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return 0.0; // Fallback se la stringa non è parsabile
    }
  }

  return 0.0; // Fallback per tipi non supportati
}

/// Converte il peso a stringa per l'invio al server
String _weightToJson(double value) {
  return value.toStringAsFixed(2);
}

/// 🔧 FIX: Converte l'ID dal JSON (può essere int o string) a string
String _parseIdSafe(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is int) return value.toString();
  if (value is double) return value.toInt().toString();
  return value.toString();
}

/// Rappresenta una sessione di allenamento attiva
@JsonSerializable()
class ActiveWorkout {
  final int id;
  @JsonKey(name: 'scheda_id')
  final int schedaId;
  @JsonKey(name: 'data_allenamento')
  final String dataAllenamento;
  @JsonKey(name: 'durata_totale')
  final int? durataTotale;
  final String? note;
  @JsonKey(name: 'user_id')
  final int userId;
  final List<WorkoutExercise> esercizi;
  @JsonKey(name: 'session_id')
  final String? sessionId;

  const ActiveWorkout({
    required this.id,
    required this.schedaId,
    required this.dataAllenamento,
    this.durataTotale,
    this.note,
    required this.userId,
    this.esercizi = const [],
    this.sessionId,
  });

  factory ActiveWorkout.fromJson(Map<String, dynamic> json) => _$ActiveWorkoutFromJson(json);
  Map<String, dynamic> toJson() => _$ActiveWorkoutToJson(this);
}

/// Rappresenta una richiesta per iniziare un nuovo allenamento
@JsonSerializable()
class StartWorkoutRequest {
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'scheda_id')
  final int schedaId;
  @JsonKey(name: 'session_id')
  final String sessionId;

  const StartWorkoutRequest({
    required this.userId,
    required this.schedaId,
    required this.sessionId,
  });

  factory StartWorkoutRequest.fromJson(Map<String, dynamic> json) => _$StartWorkoutRequestFromJson(json);
  Map<String, dynamic> toJson() => _$StartWorkoutRequestToJson(this);
}

/// Rappresenta la risposta quando si inizia un nuovo allenamento
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
@JsonSerializable()
class SeriesData {
  @JsonKey(name: 'scheda_esercizio_id')
  final int schedaEsercizioId;

  // ✅ FIX: Gestisce peso come stringa dal server
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

  const SeriesData({
    required this.schedaEsercizioId,
    required this.peso,
    required this.ripetizioni,
    this.completata = 1,
    this.tempoRecupero,
    this.note,
    this.serieNumber,
    this.serieId,
  });

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

/// 🔧 FIX: Dati di una serie completata ricevuta dal server - ID SICURO
@JsonSerializable()
class CompletedSeriesData {
  @JsonKey(fromJson: _parseIdSafe)
  final String id;
  @JsonKey(name: 'scheda_esercizio_id')
  final int schedaEsercizioId;

  // ✅ FIX: Gestisce peso come stringa dal server
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
  });

  factory CompletedSeriesData.fromJson(Map<String, dynamic> json) => _$CompletedSeriesDataFromJson(json);
  Map<String, dynamic> toJson() => _$CompletedSeriesDataToJson(this);
}

/// Richiesta per completare un allenamento
@JsonSerializable()
class CompleteWorkoutRequest {
  @JsonKey(name: 'allenamento_id')
  final int allenamentoId;
  @JsonKey(name: 'durata_totale')
  final int durataTotale;
  final String? note;

  const CompleteWorkoutRequest({
    required this.allenamentoId,
    required this.durataTotale,
    this.note,
  });

  factory CompleteWorkoutRequest.fromJson(Map<String, dynamic> json) => _$CompleteWorkoutRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CompleteWorkoutRequestToJson(this);
}

/// Risposta per il completamento di un allenamento
@JsonSerializable()
class CompleteWorkoutResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'allenamento_id')
  final int allenamentoId;
  @JsonKey(name: 'durata_totale')
  final int durataTotale;

  const CompleteWorkoutResponse({
    required this.success,
    required this.message,
    required this.allenamentoId,
    required this.durataTotale,
  });

  factory CompleteWorkoutResponse.fromJson(Map<String, dynamic> json) => _$CompleteWorkoutResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CompleteWorkoutResponseToJson(this);
}

/// Richiesta per eliminare un allenamento
@JsonSerializable()
class DeleteWorkoutRequest {
  @JsonKey(name: 'allenamento_id')
  final int allenamentoId;

  const DeleteWorkoutRequest({
    required this.allenamentoId,
  });

  factory DeleteWorkoutRequest.fromJson(Map<String, dynamic> json) => _$DeleteWorkoutRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DeleteWorkoutRequestToJson(this);
}