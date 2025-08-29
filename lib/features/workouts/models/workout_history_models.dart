// lib/features/workouts/models/workout_history_models.dart

import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'workout_history_models.g.dart';

/// Modello per rappresentare un allenamento nella cronologia
@JsonSerializable()
class WorkoutHistory extends Equatable {
  final int id;
  @JsonKey(name: 'scheda_id')
  final int schedaId;
  @JsonKey(name: 'scheda_nome')
  final String schedaNome;
  @JsonKey(name: 'data_allenamento')
  final String dataAllenamento;
  @JsonKey(name: 'durata_minuti')
  final int durataMinuti;
  @JsonKey(name: 'serie_completate')
  final int serieCompletate;
  @JsonKey(name: 'peso_totale_kg')
  final double pesoTotaleKg;
  final String? note;
  @JsonKey(name: 'esercizi_completati')
  final int eserciziCompletati;
  @JsonKey(name: 'esercizi_totali')
  final int eserciziTotali;

  const WorkoutHistory({
    required this.id,
    required this.schedaId,
    required this.schedaNome,
    required this.dataAllenamento,
    required this.durataMinuti,
    required this.serieCompletate,
    required this.pesoTotaleKg,
    this.note,
    required this.eserciziCompletati,
    required this.eserciziTotali,
  });

  factory WorkoutHistory.fromJson(Map<String, dynamic> json) => _$WorkoutHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutHistoryToJson(this);

  @override
  List<Object?> get props => [
    id,
    schedaId,
    schedaNome,
    dataAllenamento,
    durataMinuti,
    serieCompletate,
    pesoTotaleKg,
    note,
    eserciziCompletati,
    eserciziTotali,
  ];

  /// Percentuale di completamento
  double get completionPercentage {
    if (eserciziTotali == 0) return 0.0;
    return (eserciziCompletati / eserciziTotali) * 100;
  }

  /// Indica se l'allenamento è stato completato
  bool get isCompleted => eserciziCompletati == eserciziTotali && eserciziTotali > 0;

  /// Durata formattata
  String get formattedDuration {
    final hours = durataMinuti ~/ 60;
    final minutes = durataMinuti % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Data formattata
  String get formattedDate {
    try {
      final date = DateTime.parse(dataAllenamento);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dataAllenamento;
    }
  }
}

/// Risposta per la cronologia degli allenamenti
@JsonSerializable()
class WorkoutHistoryResponse {
  final bool success;
  final List<WorkoutHistory> allenamenti;
  final int count;

  const WorkoutHistoryResponse({
    required this.success,
    required this.allenamenti,
    required this.count,
  });

  factory WorkoutHistoryResponse.fromJson(Map<String, dynamic> json) => _$WorkoutHistoryResponseFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutHistoryResponseToJson(this);
}
