// lib/features/workouts/models/workout_plan_models.dart
// 🚀 FASE 3: Aggiornamento request classes per comunicazione REST-PAUSE con backend
import 'package:json_annotation/json_annotation.dart';
import '../../../core/config/app_config.dart';
import '../../exercises/models/muscle_group.dart';
import '../../exercises/models/secondary_muscle.dart';

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
  @JsonKey(name: 'immagine_nome')
  final String? immagineNome;

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

  // 🔥 FASE 6: Note Duali - Campo notes parsato dal JSON
  @JsonKey(name: 'notes')
  final Map<String, String?>? notes;

  @JsonKey(name: 'set_type')
  final String setType;

  @JsonKey(name: 'linked_to_previous', fromJson: _parseIntSafe)
  final int linkedToPreviousInt;

  @JsonKey(name: 'is_isometric', fromJson: _parseIntSafe)
  final int isIsometricInt;

  // 🚀 FASE 1: NUOVI CAMPI REST-PAUSE con default sicuri
  @JsonKey(name: 'is_rest_pause', fromJson: _parseIntSafe)
  final int isRestPauseInt;

  @JsonKey(name: 'rest_pause_reps')
  final String? restPauseReps;

  @JsonKey(name: 'rest_pause_rest_seconds', fromJson: _parseIntSafe)
  final int restPauseRestSeconds;

  // ========== NUOVI CAMPI SISTEMA MUSCOLI ==========
  @JsonKey(name: 'primary_muscle_id')
  final int? primaryMuscleId;
  @JsonKey(name: 'primary_muscle')
  final MuscleGroup? primaryMuscle;
  @JsonKey(name: 'secondary_muscles')
  final List<SecondaryMuscle>? secondaryMuscles;
  @JsonKey(name: 'all_muscle_names')
  final List<String>? allMuscleNames;
  // ==================================================

  const WorkoutExercise({
    required this.id,
    this.schedaEsercizioId,
    required this.nome,
    this.gruppoMuscolare,
    this.attrezzatura,
    this.descrizione,
    this.immagineNome,
    this.serie = 3,
    this.ripetizioni = 10,
    this.peso = 0.0,
    this.ordine = 0,
    this.tempoRecupero = 90,
    this.note,
    this.notes, // 🔥 FASE 6: Note Duali
    this.setType = 'normal',
    this.linkedToPreviousInt = 0,
    this.isIsometricInt = 0,
    // 🚀 FASE 1: Default sicuri per REST-PAUSE
    this.isRestPauseInt = 0,           // ✅ 0 = disabilitato (sicuro)
    this.restPauseReps,                // ✅ null = nessuna sequenza (sicuro)
    this.restPauseRestSeconds = 15,    // ✅ 15s default sensato
    // ========== NUOVI CAMPI SISTEMA MUSCOLI ==========
    this.primaryMuscleId,
    this.primaryMuscle,
    this.secondaryMuscles,
    this.allMuscleNames,
    // ==================================================
  });

  /// Proprietà calcolate per mantenere la compatibilità con il resto del codice
  bool get linkedToPrevious => linkedToPreviousInt > 0;
  bool get isIsometric => isIsometricInt > 0;

  // 🚀 FASE 1: Nuova proprietà calcolata per REST-PAUSE (backward compatible)
  bool get isRestPause => isRestPauseInt > 0;

  // ========== GETTER SISTEMA MUSCOLI ==========
  bool get hasMuscleInfo => primaryMuscle != null || (allMuscleNames != null && allMuscleNames!.isNotEmpty);
  String get primaryMuscleName => primaryMuscle?.name ?? gruppoMuscolare ?? '';
  List<String> get allMuscles {
    if (allMuscleNames != null && allMuscleNames!.isNotEmpty) {
      return allMuscleNames!;
    }
    final muscles = <String>[];
    if (primaryMuscle != null) {
      muscles.add(primaryMuscle!.name);
    }
    if (secondaryMuscles != null) {
      muscles.addAll(secondaryMuscles!.map((m) => m.name));
    }
    return muscles.isNotEmpty ? muscles : [gruppoMuscolare ?? ''];
  }
  // ===========================================

  /// URL completo per l'immagine GIF
  String? get imageUrl {
    if (immagineNome != null && immagineNome!.isNotEmpty) {
      // Rimuovi eventuali slash finali da baseUrl per evitare doppi slash
      String baseUrl = AppConfig.baseUrl;
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      
      // 🔧 FIX: Estrai la parte root del baseUrl (rimuovi /api)
      // Da http://192.168.1.113/api a http://192.168.1.113
      String webRootUrl = baseUrl.replaceFirst('/api', '');
      if (webRootUrl.endsWith('/')) {
        webRootUrl = webRootUrl.substring(0, webRootUrl.length - 1);
      }
      
      // 🔧 FIX: Path diretto alle immagini in /uploads/images/
      final fullUrl = '$webRootUrl/uploads/images/$immagineNome';
      return fullUrl;
    }
    
    return null;
  }

  /// Metodo di copia sicuro con conversioni Boolean -> Int
  /// 🚀 FASE 2: Aggiunto supporto REST-PAUSE con parametri opzionali
  WorkoutExercise safeCopy({
    int? id,
    int? schedaEsercizioId,
    String? nome,
    String? gruppoMuscolare,
    String? attrezzatura,
    String? descrizione,
    String? immagineNome,
    int? serie,
    int? ripetizioni,
    double? peso,
    int? ordine,
    int? tempoRecupero,
    String? note,
    Map<String, String?>? notes, // 🔥 FASE 6: Note Duali
    String? setType,
    bool? linkedToPrevious,
    bool? isIsometric,
    // 🚀 FASE 2: NUOVI PARAMETRI REST-PAUSE (tutti opzionali per backward compatibility)
    bool? isRestPause,
    String? restPauseReps,
    int? restPauseRestSeconds,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      schedaEsercizioId: schedaEsercizioId ?? this.schedaEsercizioId,
      nome: nome ?? this.nome,
      gruppoMuscolare: gruppoMuscolare ?? this.gruppoMuscolare,
      attrezzatura: attrezzatura ?? this.attrezzatura,
      descrizione: descrizione ?? this.descrizione,
      immagineNome: immagineNome ?? this.immagineNome,
      serie: serie ?? this.serie,
      ripetizioni: ripetizioni ?? this.ripetizioni,
      peso: peso ?? this.peso,
      ordine: ordine ?? this.ordine,
      tempoRecupero: tempoRecupero ?? this.tempoRecupero,
      note: note ?? this.note,
      notes: notes ?? this.notes, // 🔥 FASE 6: Note Duali
      setType: (setType ?? this.setType).isEmpty ? 'normal' : (setType ?? this.setType),
      linkedToPreviousInt: linkedToPrevious != null ? (linkedToPrevious ? 1 : 0) : this.linkedToPreviousInt,
      isIsometricInt: isIsometric != null ? (isIsometric ? 1 : 0) : this.isIsometricInt,
      // 🚀 FASE 2: Gestione intelligente dei parametri REST-PAUSE
      isRestPauseInt: isRestPause != null ? (isRestPause ? 1 : 0) : this.isRestPauseInt,
      restPauseReps: restPauseReps ?? this.restPauseReps,
      restPauseRestSeconds: restPauseRestSeconds ?? this.restPauseRestSeconds,
    );
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    try {
      return _$WorkoutExerciseFromJson(json);
    } catch (e) {
      // 🔧 DEBUG: Log dell'errore di parsing
      //print('[CONSOLE] [workout_plan_models]❌ ERROR parsing WorkoutExercise: $e');
      //print('[CONSOLE] [workout_plan_models]❌ JSON data: $json');

      // Fallback con parsing manuale sicuro - 🚀 FASE 1: Aggiunti campi REST-PAUSE
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
        // 🚀 FASE 1: Parsing sicuro dei nuovi campi REST-PAUSE
        isRestPauseInt: _parseIntSafe(json['is_rest_pause']),
        restPauseReps: json['rest_pause_reps']?.toString(),
        restPauseRestSeconds: _parseIntSafe(json['rest_pause_rest_seconds']) != 0
            ? _parseIntSafe(json['rest_pause_rest_seconds'])
            : 15, // Default se zero o null
      );
    }
  }

  Map<String, dynamic> toJson() => _$WorkoutExerciseToJson(this);
}

/// Factory function per creare un WorkoutExercise con parametri booleani
/// 🚀 FASE 2: Aggiunto supporto REST-PAUSE con parametri opzionali
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
  // 🚀 FASE 2: NUOVI PARAMETRI REST-PAUSE (con default sicuri)
  bool isRestPause = false,
  String? restPauseReps,
  int restPauseRestSeconds = 15,
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
    // 🚀 FASE 2: Conversione parametri REST-PAUSE
    isRestPauseInt: isRestPause ? 1 : 0,
    restPauseReps: restPauseReps,
    restPauseRestSeconds: restPauseRestSeconds,
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
/// 🚀 FASE 3: Aggiunto supporto REST-PAUSE per comunicazione backend
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

  // 🚀 FASE 3: NUOVI CAMPI REST-PAUSE per backend
  @JsonKey(name: 'is_rest_pause')
  final int isRestPauseInt;
  @JsonKey(name: 'rest_pause_reps')
  final String? restPauseReps;
  @JsonKey(name: 'rest_pause_rest_seconds')
  final int restPauseRestSeconds;

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
    this.isIsometricInt = 0,
    // 🚀 FASE 3: Default sicuri per campi REST-PAUSE
    this.isRestPauseInt = 0,
    this.restPauseReps,
    this.restPauseRestSeconds = 15,
  });

  factory WorkoutExerciseRequest.fromJson(Map<String, dynamic> json) => _$WorkoutExerciseRequestFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutExerciseRequestToJson(this);

  // 🚀 FASE 3: Helper method per convertire da WorkoutExercise a WorkoutExerciseRequest
  factory WorkoutExerciseRequest.fromWorkoutExercise(WorkoutExercise exercise) {
    return WorkoutExerciseRequest(
      id: exercise.id,
      schedaEsercizioId: exercise.schedaEsercizioId,
      serie: exercise.serie,
      ripetizioni: exercise.ripetizioni,
      peso: exercise.peso,
      ordine: exercise.ordine,
      tempoRecupero: exercise.tempoRecupero,
      note: exercise.note,
      setType: exercise.setType,
      linkedToPrevious: exercise.linkedToPreviousInt,
      isIsometricInt: exercise.isIsometricInt,
      // 🚀 FASE 3: Trasferimento campi REST-PAUSE
      isRestPauseInt: exercise.isRestPauseInt,
      restPauseReps: exercise.restPauseReps,
      restPauseRestSeconds: exercise.restPauseRestSeconds,
    );
  }
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