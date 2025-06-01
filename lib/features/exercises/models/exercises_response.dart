// lib/features/exercises/models/exercises_response.dart
import 'package:json_annotation/json_annotation.dart';

part 'exercises_response.g.dart';

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
  final int id;
  final String nome;
  final String? descrizione;
  @JsonKey(name: 'gruppo_muscolare')
  final String? gruppoMuscolare;
  final String? attrezzatura;
  @JsonKey(name: 'immagine_url')
  final String? immagineUrl;
  @JsonKey(name: 'is_isometric')
  final bool isIsometric;
  @JsonKey(name: 'serie_default')
  final int? serieDefault;
  @JsonKey(name: 'ripetizioni_default')
  final int? ripetizioniDefault;
  @JsonKey(name: 'peso_default')
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

  factory ExerciseItem.fromJson(Map<String, dynamic> json) =>
      _$ExerciseItemFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseItemToJson(this);

/// Converte ExerciseItem in WorkoutExercise per l'uso nelle schede
/// Utile quando si aggiunge un esercizio a una scheda
///
/// NOTA: Qui usiamo createWorkoutExercise invece del constructor
/// per evitare conflitti con i parametri Boolean vs Int
// WorkoutExercise toWorkoutExercise({
//   int serie = 3,
//   int ripetizioni = 10,
//   double peso = 0.0,
//   int ordine = 0,
//   int tempoRecupero = 90,
//   String? note,
//   String setType = "normal",
// }) {
//   return createWorkoutExercise(
//     id: id,
//     nome: nome,
//     gruppoMuscolare: gruppoMuscolare,
//     attrezzatura: attrezzatura,
//     descrizione: descrizione,
//     serie: serieDefault ?? serie,
//     ripetizioni: ripetizioniDefault ?? ripetizioni,
//     peso: pesoDefault ?? peso,
//     ordine: ordine,
//     tempoRecupero: tempoRecupero,
//     note: note,
//     setType: setType,
//     isIsometric: isIsometric,
//   );
// }
}