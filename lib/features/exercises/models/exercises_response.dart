// lib/features/exercises/models/exercises_response.dart
import 'package:json_annotation/json_annotation.dart';

part 'exercises_response.g.dart';

// 🔧 FUNZIONI HELPER ROBUSTE
int _parseIntSafe(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    try {
      return int.parse(value);
    } catch (e) {
      try {
        return double.parse(value).toInt();
      } catch (e2) {
        return 0;
      }
    }
  }
  return 0;
}

double _parseDoubleSafe(dynamic value) {
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

bool _parseBoolSafe(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value > 0;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  return false;
}

/// Risposta per la lista degli esercizi disponibili
@JsonSerializable()
class ExercisesResponse {
  final bool success;
  final List<ExerciseItem> esercizi;
  final String? message;

  const ExercisesResponse({
    required this.success,
    required this.esercizi,
    this.message,
  });

  factory ExercisesResponse.fromJson(Map<String, dynamic> json) =>
      _$ExercisesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExercisesResponseToJson(this);
}

/// Elemento di esercizio nella lista degli esercizi disponibili
@JsonSerializable()
class ExerciseItem {
  @JsonKey(fromJson: _parseIntSafe)
  final int id;

  final String nome;
  final String? descrizione;

  @JsonKey(name: 'gruppo_muscolare')
  final String? gruppoMuscolare;

  final String? attrezzatura;

  @JsonKey(name: 'immagine_url')
  final String? immagineUrl;

  @JsonKey(name: 'is_isometric', fromJson: _parseBoolSafe)
  final bool isIsometric;

  @JsonKey(name: 'serie_default', fromJson: _parseIntSafe)
  final int? serieDefault;

  @JsonKey(name: 'ripetizioni_default', fromJson: _parseIntSafe)
  final int? ripetizioniDefault;

  @JsonKey(name: 'peso_default', fromJson: _parseDoubleSafe)
  final double? pesoDefault;

  const ExerciseItem({
    required this.id,
    required this.nome,
    this.descrizione,
    this.gruppoMuscolare,
    this.attrezzatura,
    this.immagineUrl,
    this.isIsometric = false,
    this.serieDefault,
    this.ripetizioniDefault,
    this.pesoDefault,
  });

  factory ExerciseItem.fromJson(Map<String, dynamic> json) {
    try {
      return _$ExerciseItemFromJson(json);
    } catch (e) {
      // 🔧 DEBUG: Log dell'errore di parsing
      print('❌ ERROR parsing ExerciseItem: $e');
      print('❌ JSON data: $json');

      // Fallback con parsing manuale sicuro
      return ExerciseItem(
        id: _parseIntSafe(json['id']),
        nome: json['nome']?.toString() ?? 'Esercizio sconosciuto',
        descrizione: json['descrizione']?.toString(),
        gruppoMuscolare: json['gruppo_muscolare']?.toString(),
        attrezzatura: json['attrezzatura']?.toString(),
        immagineUrl: json['immagine_url']?.toString(),
        isIsometric: _parseBoolSafe(json['is_isometric']),
        serieDefault: _parseIntSafe(json['serie_default']),
        ripetizioniDefault: _parseIntSafe(json['ripetizioni_default']),
        pesoDefault: _parseDoubleSafe(json['peso_default']),
      );
    }
  }

  Map<String, dynamic> toJson() => _$ExerciseItemToJson(this);
}