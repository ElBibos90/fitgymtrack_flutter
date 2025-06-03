// lib/features/workouts/models/workout_response_types.dart
import 'package:json_annotation/json_annotation.dart';

part 'workout_response_types.g.dart';

/// Risposta per la creazione di una scheda allenamento
@JsonSerializable()
class CreateWorkoutPlanResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'scheda_id')
  final int? schedaId;

  const CreateWorkoutPlanResponse({
    required this.success,
    required this.message,
    this.schedaId,
  });

  factory CreateWorkoutPlanResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateWorkoutPlanResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateWorkoutPlanResponseToJson(this);
}

/// Risposta per l'aggiornamento di una scheda allenamento
@JsonSerializable()
class UpdateWorkoutPlanResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'scheda_id')
  final int? schedaId;
  @JsonKey(name: 'updated_exercises')
  final int? updatedExercises;

  const UpdateWorkoutPlanResponse({
    required this.success,
    required this.message,
    this.schedaId,
    this.updatedExercises,
  });

  factory UpdateWorkoutPlanResponse.fromJson(Map<String, dynamic> json) =>
      _$UpdateWorkoutPlanResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateWorkoutPlanResponseToJson(this);
}

/// Risposta per l'eliminazione di una scheda allenamento
@JsonSerializable()
class DeleteWorkoutPlanResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'scheda_id')
  final int? schedaId;

  const DeleteWorkoutPlanResponse({
    required this.success,
    required this.message,
    this.schedaId,
  });

  factory DeleteWorkoutPlanResponse.fromJson(Map<String, dynamic> json) =>
      _$DeleteWorkoutPlanResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteWorkoutPlanResponseToJson(this);
}

/// Risposta generica per operazioni di successo/errore
@JsonSerializable()
class GenericWorkoutResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const GenericWorkoutResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory GenericWorkoutResponse.fromJson(Map<String, dynamic> json) =>
      _$GenericWorkoutResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GenericWorkoutResponseToJson(this);
}

/// Risposta per la lista degli esercizi disponibili
@JsonSerializable()
class AvailableExercisesResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'esercizi')
  final List<Map<String, dynamic>> esercizi;
  final int count;

  const AvailableExercisesResponse({
    required this.success,
    required this.message,
    required this.esercizi,
    required this.count,
  });

  factory AvailableExercisesResponse.fromJson(Map<String, dynamic> json) =>
      _$AvailableExercisesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AvailableExercisesResponseToJson(this);
}

/// Risposta per il caricamento dei dettagli di una scheda
@JsonSerializable()
class WorkoutDetailsResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? scheda;
  @JsonKey(name: 'esercizi')
  final List<Map<String, dynamic>>? esercizi;

  const WorkoutDetailsResponse({
    required this.success,
    required this.message,
    this.scheda,
    this.esercizi,
  });

  factory WorkoutDetailsResponse.fromJson(Map<String, dynamic> json) =>
      _$WorkoutDetailsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutDetailsResponseToJson(this);
}

/// Risposta per l'avvio di un allenamento
@JsonSerializable()
class StartActiveWorkoutResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'allenamento_id')
  final int allenamentoId;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  @JsonKey(name: 'data_inizio')
  final String? dataInizio;

  const StartActiveWorkoutResponse({
    required this.success,
    required this.message,
    required this.allenamentoId,
    this.sessionId,
    this.dataInizio,
  });

  factory StartActiveWorkoutResponse.fromJson(Map<String, dynamic> json) =>
      _$StartActiveWorkoutResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StartActiveWorkoutResponseToJson(this);
}

/// Risposta per il completamento di un allenamento
@JsonSerializable()
class CompleteActiveWorkoutResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'allenamento_id')
  final int allenamentoId;
  @JsonKey(name: 'durata_totale')
  final int durataTotale;
  @JsonKey(name: 'serie_completate')
  final int? serieCompletate;
  @JsonKey(name: 'data_completamento')
  final String? dataCompletamento;

  const CompleteActiveWorkoutResponse({
    required this.success,
    required this.message,
    required this.allenamentoId,
    required this.durataTotale,
    this.serieCompletate,
    this.dataCompletamento,
  });

  factory CompleteActiveWorkoutResponse.fromJson(Map<String, dynamic> json) =>
      _$CompleteActiveWorkoutResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CompleteActiveWorkoutResponseToJson(this);
}

/// Risposta per il salvataggio di serie completate
@JsonSerializable()
class SaveSeriesResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'serie_salvate')
  final int? serieSalvate;
  @JsonKey(name: 'request_id')
  final String? requestId;

  const SaveSeriesResponse({
    required this.success,
    required this.message,
    this.serieSalvate,
    this.requestId,
  });

  factory SaveSeriesResponse.fromJson(Map<String, dynamic> json) =>
      _$SaveSeriesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SaveSeriesResponseToJson(this);
}

/// Risposta per il caricamento di serie completate
@JsonSerializable()
class LoadSeriesResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'serie')
  final List<Map<String, dynamic>> serie;
  final int count;
  @JsonKey(name: 'allenamento_id')
  final int? allenamentoId;

  const LoadSeriesResponse({
    required this.success,
    required this.message,
    required this.serie,
    required this.count,
    this.allenamentoId,
  });

  factory LoadSeriesResponse.fromJson(Map<String, dynamic> json) =>
      _$LoadSeriesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoadSeriesResponseToJson(this);
}

/// Errore personalizzato per operazioni workout
class WorkoutException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const WorkoutException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'WorkoutException($statusCode): $message';
    }
    return 'WorkoutException: $message';
  }
}

/// Factory per creare errori comuni
class WorkoutErrors {
  static WorkoutException networkError() => const WorkoutException(
    message: 'Errore di connessione. Verifica la tua connessione internet.',
    statusCode: 0,
  );

  static WorkoutException serverError([String? customMessage]) => WorkoutException(
    message: customMessage ?? 'Errore del server. Riprova più tardi.',
    statusCode: 500,
  );

  static WorkoutException unauthorized() => const WorkoutException(
    message: 'Sessione scaduta. Effettua nuovamente il login.',
    statusCode: 401,
  );

  static WorkoutException notFound([String? resource]) => WorkoutException(
    message: resource != null
        ? '$resource non trovata.'
        : 'Risorsa non trovata.',
    statusCode: 404,
  );

  static WorkoutException validationError(String details) => WorkoutException(
    message: 'Dati non validi: $details',
    statusCode: 400,
  );

  static WorkoutException timeout() => const WorkoutException(
    message: 'Timeout di connessione. Riprova più tardi.',
    statusCode: 408,
  );

  static WorkoutException generic([String? message]) => WorkoutException(
    message: message ?? 'Si è verificato un errore sconosciuto.',
  );
}