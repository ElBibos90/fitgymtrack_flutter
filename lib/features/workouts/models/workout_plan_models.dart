// lib/features/workouts/models/workout_plan_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'workout_plan_models.g.dart';

// FUNZIONI HELPER ROBUSTE PER LA CONVERSIONE
/// Converte qualsiasi tipo a double in modo sicuro
double _parseWeightSafe(dynamic value) {
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

/// Converte qualsiasi tipo a int in modo sicuro
int _parseIntSafe(dynamic value) {
  if (value == null) return 0;

  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    try {
      return int.parse(value);
    } catch (e) {
      try {
        // Prova come double prima
        return double.parse(value).toInt();
      } catch (e2) {
        return 0;
      }
    }
  }

  return 0;
}

/// Converte il peso a stringa per l'invio al server
String _weightToJson(double value) {
  return value.toStringAsFixed(2);
}

/// Rappresenta una scheda di allenamento
@JsonSerializable()
class WorkoutPlan {
  final int id;
  final String nome;
  final String? descrizione;
  @JsonKey(name: 'data_creazione')
  final String? dataCreazione;
  final List<WorkoutExercise> esercizi;

  const WorkoutPlan({
    required this.id,
    required this.nome,
    this.descrizione,
    this.dataCreazione,
    this.esercizi = const [],
  });

  WorkoutPlan copyWith({
    int? id,
    String? nome,
    String? descrizione,
    String? dataCreazione,
    List<WorkoutExercise>? esercizi,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descrizione: descrizione ?? this.descrizione,
      dataCreazione: dataCreazione ?? this.dataCreazione,
      esercizi: esercizi ?? this.esercizi,
    );
  }

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => _$WorkoutPlanFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutPlanToJson(this);
}

/// Rappresenta un esercizio all'interno di una scheda
@JsonSerializable()
class WorkoutExercise {
  final int id;
  @JsonKey(name: 'scheda_esercizio_id')
  final int? schedaEsercizioId;
  final String nome;
  @JsonKey(name: 'gruppo_muscolare')
  final String? gruppoMuscolare;
  final String? attrezzatura;
  final String? descrizione;

  // 🔧 PARSING ROBUSTO per valori numerici
  @JsonKey(fromJson: _parseIntSafe)
  final int serie;

  @JsonKey(fromJson: _parseIntSafe)
  final int ripetizioni;

  @JsonKey(
    name: 'peso',
    fromJson: _parseWeightSafe,
    toJson: _weightToJson,
  )
  final double peso;

  @JsonKey(fromJson: _parseIntSafe)
  final int ordine;

  @JsonKey(name: 'tempo_recupero', fromJson: _parseIntSafe)
  final int tempoRecupero;

  final String? note;

  @JsonKey(name: 'set_type')
  final String setType;

  @JsonKey(name: 'linked_to_previous', fromJson: _parseIntSafe)
  final int linkedToPreviousInt;

  @JsonKey(name: 'is_isometric', fromJson: _parseIntSafe)
  final int isIsometricInt;

  const WorkoutExercise({
    required this.id,
    this.schedaEsercizioId,
    required this.nome,
    this.gruppoMuscolare,
    this.attrezzatura,
    this.descrizione,
    this.serie = 3,
    this.ripetizioni = 10,
    this.peso = 0.0,
    this.ordine = 0,
    this.tempoRecupero = 90,
    this.note,
    this.setType = 'normal',
    this.linkedToPreviousInt = 0,
    this.isIsometricInt = 0,
  });

  /// Proprietà calcolate per mantenere la compatibilità con il resto del codice
  bool get linkedToPrevious => linkedToPreviousInt > 0;
  bool get isIsometric => isIsometricInt > 0;

  /// Metodo di copia sicuro con conversioni Boolean -> Int
  WorkoutExercise safeCopy({
    int? id,
    int? schedaEsercizioId,
    String? nome,
    String? gruppoMuscolare,
    String? attrezzatura,
    String? descrizione,
    int? serie,
    int? ripetizioni,
    double? peso,
    int? ordine,
    int? tempoRecupero,
    String? note,
    String? setType,
    bool? linkedToPrevious,
    bool? isIsometric,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      schedaEsercizioId: schedaEsercizioId ?? this.schedaEsercizioId,
      nome: nome ?? this.nome,
      gruppoMuscolare: gruppoMuscolare ?? this.gruppoMuscolare,
      attrezzatura: attrezzatura ?? this.attrezzatura,
      descrizione: descrizione ?? this.descrizione,
      serie: serie ?? this.serie,
      ripetizioni: ripetizioni ?? this.ripetizioni,
      peso: peso ?? this.peso,
      ordine: ordine ?? this.ordine,
      tempoRecupero: tempoRecupero ?? this.tempoRecupero,
      note: note ?? this.note,
      setType: (setType ?? this.setType).isEmpty ? 'normal' : (setType ?? this.setType),
      linkedToPreviousInt: linkedToPrevious != null ? (linkedToPrevious ? 1 : 0) : this.linkedToPreviousInt,
      isIsometricInt: isIsometric != null ? (isIsometric ? 1 : 0) : this.isIsometricInt,
    );
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    try {
      return _$WorkoutExerciseFromJson(json);
    } catch (e) {
      // 🔧 DEBUG: Log dell'errore di parsing
      print('❌ ERROR parsing WorkoutExercise: $e');
      print('❌ JSON data: $json');

      // Fallback con parsing manuale sicuro
      return WorkoutExercise(
        id: _parseIntSafe(json['id']),
        schedaEsercizioId: _parseIntSafe(json['scheda_esercizio_id']),
        nome: json['nome']?.toString() ?? 'Esercizio sconosciuto',
        gruppoMuscolare: json['gruppo_muscolare']?.toString(),
        attrezzatura: json['attrezzatura']?.toString(),
        descrizione: json['descrizione']?.toString(),
        serie: _parseIntSafe(json['serie']),
        ripetizioni: _parseIntSafe(json['ripetizioni']),
        peso: _parseWeightSafe(json['peso']),
        ordine: _parseIntSafe(json['ordine']),
        tempoRecupero: _parseIntSafe(json['tempo_recupero']),
        note: json['note']?.toString(),
        setType: json['set_type']?.toString() ?? 'normal',
        linkedToPreviousInt: _parseIntSafe(json['linked_to_previous']),
        isIsometricInt: _parseIntSafe(json['is_isometric']),
      );
    }
  }

  Map<String, dynamic> toJson() => _$WorkoutExerciseToJson(this);
}

/// Factory function per creare un WorkoutExercise con parametri booleani
WorkoutExercise createWorkoutExercise({
  required int id,
  int? schedaEsercizioId,
  required String nome,
  String? gruppoMuscolare,
  String? attrezzatura,
  String? descrizione,
  int serie = 3,
  int ripetizioni = 10,
  double peso = 0.0,
  int ordine = 0,
  int tempoRecupero = 90,
  String? note,
  String setType = 'normal',
  bool linkedToPrevious = false,
  bool isIsometric = false,
}) {
  return WorkoutExercise(
    id: id,
    schedaEsercizioId: schedaEsercizioId,
    nome: nome,
    gruppoMuscolare: gruppoMuscolare,
    attrezzatura: attrezzatura,
    descrizione: descrizione,
    serie: serie,
    ripetizioni: ripetizioni,
    peso: peso,
    ordine: ordine,
    tempoRecupero: tempoRecupero,
    note: note,
    setType: setType.isEmpty ? 'normal' : setType,
    linkedToPreviousInt: linkedToPrevious ? 1 : 0,
    isIsometricInt: isIsometric ? 1 : 0,
  );
}

/// Richiesta per creare una nuova scheda
@JsonSerializable()
class CreateWorkoutPlanRequest {
  @JsonKey(name: 'user_id')
  final int userId;
  final String nome;
  final String? descrizione;
  final List<WorkoutExerciseRequest> esercizi;

  const CreateWorkoutPlanRequest({
    required this.userId,
    required this.nome,
    this.descrizione,
    required this.esercizi,
  });

  factory CreateWorkoutPlanRequest.fromJson(Map<String, dynamic> json) => _$CreateWorkoutPlanRequestFromJson(json);

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'nome': nome,
      if (descrizione != null) 'descrizione': descrizione,
      'esercizi': esercizi.map((e) => e.toJson()).toList(),
    };
  }
}

/// Rappresenta un esercizio nella richiesta di creazione/modifica scheda
@JsonSerializable()
class WorkoutExerciseRequest {
  final int id;
  @JsonKey(name: 'scheda_esercizio_id')
  final int? schedaEsercizioId;
  final int serie;
  final int ripetizioni;
  final double peso;
  final int ordine;
  @JsonKey(name: 'tempo_recupero')
  final int tempoRecupero;
  final String? note;
  @JsonKey(name: 'set_type')
  final String setType;
  @JsonKey(name: 'linked_to_previous')
  final int linkedToPrevious;
  @JsonKey(name: 'is_isometric')
  final int isIsometricInt;

  const WorkoutExerciseRequest({
    required this.id,
    this.schedaEsercizioId,
    required this.serie,
    required this.ripetizioni,
    required this.peso,
    required this.ordine,
    this.tempoRecupero = 90,
    this.note,
    this.setType = 'normal',
    this.linkedToPrevious = 0,
    this.isIsometricInt = 0
  });

  factory WorkoutExerciseRequest.fromJson(Map<String, dynamic> json) => _$WorkoutExerciseRequestFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutExerciseRequestToJson(this);
}

/// Richiesta per modificare una scheda esistente
@JsonSerializable()
class UpdateWorkoutPlanRequest {
  @JsonKey(name: 'scheda_id')
  final int schedaId;
  @JsonKey(name: 'user_id')
  final int? userId;
  final String nome;
  final String? descrizione;
  final List<WorkoutExerciseRequest> esercizi;
  final List<WorkoutExerciseToRemove>? rimuovi;

  const UpdateWorkoutPlanRequest({
    required this.schedaId,
    this.userId,
    required this.nome,
    this.descrizione,
    required this.esercizi,
    this.rimuovi,
  });

  factory UpdateWorkoutPlanRequest.fromJson(Map<String, dynamic> json) => _$UpdateWorkoutPlanRequestFromJson(json);

  Map<String, dynamic> toJson() {
    return {
      'action': 'update',
      'scheda_id': schedaId,
      if (userId != null) 'user_id': userId,
      'nome': nome,
      'descrizione': descrizione ?? '',
      'esercizi': esercizi.map((e) => e.toJson()).toList(),
      if (rimuovi != null) 'rimuovi': rimuovi!.map((e) => e.toJson()).toList(),
    };
  }
}

/// Esercizio da rimuovere nella richiesta di modifica
@JsonSerializable()
class WorkoutExerciseToRemove {
  final int id;

  const WorkoutExerciseToRemove({
    required this.id,
  });

  factory WorkoutExerciseToRemove.fromJson(Map<String, dynamic> json) => _$WorkoutExerciseToRemoveFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutExerciseToRemoveToJson(this);
}

/// Risposta generica per le operazioni sulle schede
@JsonSerializable()
class WorkoutPlanResponse {
  final bool success;
  final String message;

  const WorkoutPlanResponse({
    required this.success,
    required this.message,
  });

  factory WorkoutPlanResponse.fromJson(Map<String, dynamic> json) => _$WorkoutPlanResponseFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutPlanResponseToJson(this);
}

/// Risposta per la lista schede
@JsonSerializable()
class WorkoutPlansResponse {
  final bool success;
  final List<WorkoutPlan> schede;

  const WorkoutPlansResponse({
    required this.success,
    required this.schede,
  });

  factory WorkoutPlansResponse.fromJson(Map<String, dynamic> json) => _$WorkoutPlansResponseFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutPlansResponseToJson(this);
}

/// Risposta per gli esercizi di una scheda
@JsonSerializable()
class WorkoutExercisesResponse {
  final bool success;
  final List<WorkoutExercise> esercizi;

  const WorkoutExercisesResponse({
    required this.success,
    required this.esercizi,
  });

  factory WorkoutExercisesResponse.fromJson(Map<String, dynamic> json) => _$WorkoutExercisesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutExercisesResponseToJson(this);
}