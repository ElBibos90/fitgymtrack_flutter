// lib/features/workouts/models/series_request_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'series_request_models.g.dart';

/// Converte il peso dal JSON (può essere stringa o numero) a double
double _parseWeight(dynamic value) {
  if (value == null) return 0.0;

  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return 0.0;
    }
  }

  return 0.0;
}

/// Converte il peso a stringa per l'invio al server
String _weightToJson(double value) {
  return value.toStringAsFixed(2);
}

/// Richiesta per eliminare una serie completata
@JsonSerializable()
class DeleteSeriesRequest {
  @JsonKey(name: 'serie_id')
  final String serieId;

  const DeleteSeriesRequest({
    required this.serieId,
  });

  factory DeleteSeriesRequest.fromJson(Map<String, dynamic> json) =>
      _$DeleteSeriesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteSeriesRequestToJson(this);
}

/// Richiesta per aggiornare una serie completata
@JsonSerializable()
class UpdateSeriesRequest {
  @JsonKey(name: 'serie_id')
  final String serieId;

  // ✅ FIX: Gestisce peso come stringa dal server
  @JsonKey(
    name: 'peso',
    fromJson: _parseWeight,
    toJson: _weightToJson,
  )
  final double peso;

  final int ripetizioni;
  @JsonKey(name: 'tempo_recupero')
  final int? tempoRecupero;
  final String? note;

  const UpdateSeriesRequest({
    required this.serieId,
    required this.peso,
    required this.ripetizioni,
    this.tempoRecupero,
    this.note,
  });

  factory UpdateSeriesRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateSeriesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateSeriesRequestToJson(this);
}

/// Risposta generica per le operazioni sulle serie
@JsonSerializable()
class SeriesOperationResponse {
  final bool success;
  final String message;

  const SeriesOperationResponse({
    required this.success,
    required this.message,
  });

  factory SeriesOperationResponse.fromJson(Map<String, dynamic> json) =>
      _$SeriesOperationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SeriesOperationResponseToJson(this);
}