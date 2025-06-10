// lib/features/workouts/models/exercise_group_models.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'workout_plan_models.dart';
import 'active_workout_models.dart';

// 🛠️ Helper function for logging
void _log(String message, {String name = 'ExerciseGroupModels'}) {
  // if (kDebugMode) {
  //   print('[CONSOLE] [exercise_group_models][$name] $message');
  // }
}

/// Rappresenta un gruppo di esercizi collegati
class ExerciseGroup extends Equatable {
  final String type;                    // "normal", "superset", "circuit"
  final List<WorkoutExercise> exercises;
  final int groupIndex;                 // Indice del gruppo nella lista
  final String groupId;                 // ID univoco del gruppo
  final int currentExerciseIndex;       // 🚀 NUOVO: Indice esercizio corrente nel gruppo

  const ExerciseGroup({
    required this.type,
    required this.exercises,
    required this.groupIndex,
    required this.groupId,
    this.currentExerciseIndex = 0,      // 🚀 NUOVO: Default primo esercizio
  });

  @override
  List<Object> get props => [type, exercises, groupIndex, groupId, currentExerciseIndex];

  /// 🚀 NUOVO: Ottieni l'esercizio corrente nel gruppo
  WorkoutExercise get currentExercise {
    if (exercises.isEmpty) throw StateError('No exercises in group');
    if (currentExerciseIndex >= exercises.length) return exercises.first;
    return exercises[currentExerciseIndex];
  }

  /// 🚀 NUOVO: Verifica se l'esercizio corrente è isometrico
  bool get isCurrentExerciseIsometric => currentExercise.isIsometric;

  /// 🚀 NUOVO: Ottieni i secondi per il timer isometrico dell'esercizio corrente
  int get currentExerciseIsometricSeconds =>
      isCurrentExerciseIsometric ? currentExercise.ripetizioni : 0;

  /// Numero totale di serie per il gruppo
  int get totalSeries {
    if (exercises.isEmpty) return 0;

    // Per superset/circuit, il numero di serie è lo stesso per tutti gli esercizi
    // Prendiamo il massimo per sicurezza
    return exercises.map((e) => e.serie).reduce((a, b) => a > b ? a : b);
  }

  /// Calcola le serie completate per il gruppo
  int getCompletedSeries(Map<int, List<CompletedSeriesData>> completedSeries) {
    if (exercises.isEmpty) return 0;

    int minCompletedSeries = 999;

    for (final exercise in exercises) {
      final exerciseSeries = completedSeries[exercise.id] ?? [];
      final completedCount = exerciseSeries.length;

      if (completedCount < minCompletedSeries) {
        minCompletedSeries = completedCount;
      }
    }

    return minCompletedSeries == 999 ? 0 : minCompletedSeries;
  }

  /// Verifica se il gruppo è completato
  bool isCompleted(Map<int, List<CompletedSeriesData>> completedSeries) {
    final completed = getCompletedSeries(completedSeries);
    return completed >= totalSeries;
  }

  /// Ottieni il numero della prossima serie da completare
  int getNextSeriesNumber(Map<int, List<CompletedSeriesData>> completedSeries) {
    return getCompletedSeries(completedSeries) + 1;
  }

  /// 🚀 NUOVO: Calcola le serie completate per l'esercizio corrente
  int getCurrentExerciseCompletedSeries(Map<int, List<CompletedSeriesData>> completedSeries) {
    final exerciseSeries = completedSeries[currentExercise.id] ?? [];
    return exerciseSeries.length;
  }

  /// 🚀 NUOVO: Verifica se l'esercizio corrente ha completato tutte le sue serie
  bool isCurrentExerciseCompleted(Map<int, List<CompletedSeriesData>> completedSeries) {
    final completed = getCurrentExerciseCompletedSeries(completedSeries);
    return completed >= currentExercise.serie;
  }

  /// 🚀 NUOVO: Ottieni il numero della prossima serie per l'esercizio corrente
  int getCurrentExerciseNextSeriesNumber(Map<int, List<CompletedSeriesData>> completedSeries) {
    return getCurrentExerciseCompletedSeries(completedSeries) + 1;
  }

  /// 🚀 NUOVO: Calcola la serie CORRENTE del superset/circuit (non dell'esercizio singolo)
  int getCurrentGroupSeriesNumber(Map<int, List<CompletedSeriesData>> completedSeries) {
    if (isSingleExercise) {
      return getCurrentExerciseNextSeriesNumber(completedSeries);
    }

    // Per gruppi: calcola quante "rotazioni complete" sono state fatte
    // Una rotazione completa = tutti gli esercizi del gruppo hanno fatto una serie
    final completedGroupSeries = getCompletedSeries(completedSeries);

    // Se stiamo nel mezzo di una rotazione (alcuni esercizi hanno fatto una serie in più)
    // consideriamo che stiamo nella serie successiva
    final currentExerciseCompletedSeries = getCurrentExerciseCompletedSeries(completedSeries);

    // Il numero di serie del gruppo è basato su quante serie complete ha fatto il gruppo
    return completedGroupSeries + 1;
  }

  /// 🚀 NUOVO: Verifica se il gruppo ha completato l'attuale "giro" di serie
  bool hasCompletedCurrentGroupRound(Map<int, List<CompletedSeriesData>> completedSeries) {
    if (isSingleExercise) return false;

    // Verifica se tutti gli esercizi del gruppo hanno completato la serie corrente
    final currentGroupSeries = getCurrentGroupSeriesNumber(completedSeries);

    return exercises.every((exercise) {
      final exerciseSeries = completedSeries[exercise.id] ?? [];
      return exerciseSeries.length >= currentGroupSeries;
    });
  }

  /// 🚀 NUOVO: Determina l'indice del prossimo esercizio nel gruppo
  int getNextExerciseIndex(Map<int, List<CompletedSeriesData>> completedSeries) {
    if (isSingleExercise) return currentExerciseIndex;

    // Per gruppi (superset/circuit), dopo aver completato una serie,
    // passa al prossimo esercizio del gruppo
    final nextIndex = (currentExerciseIndex + 1) % exercises.length;
    return nextIndex;
  }

  /// 🚀 NUOVO: Verifica se dovremmo passare al prossimo esercizio
  bool shouldMoveToNextExercise(Map<int, List<CompletedSeriesData>> completedSeries) {
    if (isSingleExercise) return false;

    // Per gruppi, dopo ogni serie completata, passa al prossimo esercizio
    // a meno che non sia l'ultimo esercizio e tutte le serie sono completate
    return !isCurrentExerciseCompleted(completedSeries);
  }

  /// 🚀 NUOVO: Crea una copia del gruppo con un nuovo esercizio corrente
  ExerciseGroup moveToNextExercise(Map<int, List<CompletedSeriesData>> completedSeries) {
    final nextIndex = getNextExerciseIndex(completedSeries);
    return copyWith(currentExerciseIndex: nextIndex);
  }

  /// Verifica se il gruppo è un gruppo singolo (normal)
  bool get isSingleExercise => type == 'normal' && exercises.length == 1;

  /// Verifica se il gruppo è un superset
  bool get isSuperset => type == 'superset' && exercises.length >= 2;

  /// Verifica se il gruppo è un circuit
  bool get isCircuit => type == 'circuit' && exercises.length >= 2;

  /// Nome descrittivo del gruppo
  String get displayName {
    switch (type) {
      case 'superset':
        return 'Superset ${String.fromCharCode(65 + groupIndex)}'; // A, B, C...
      case 'circuit':
        return 'Circuit ${String.fromCharCode(65 + groupIndex)}';  // A, B, C...
      case 'normal':
        return exercises.first.nome;
      default:
        return 'Gruppo ${groupIndex + 1}';
    }
  }

  /// Tempo di recupero del gruppo (prende il massimo tra gli esercizi)
  int get recoveryTime {
    if (exercises.isEmpty) return 90;

    return exercises
        .map((e) => e.tempoRecupero)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Nomi degli esercizi nel gruppo
  List<String> get exerciseNames => exercises.map((e) => e.nome).toList();

  /// Copia il gruppo con modifiche
  ExerciseGroup copyWith({
    String? type,
    List<WorkoutExercise>? exercises,
    int? groupIndex,
    String? groupId,
    int? currentExerciseIndex,              // 🚀 NUOVO
  }) {
    return ExerciseGroup(
      type: type ?? this.type,
      exercises: exercises ?? this.exercises,
      groupIndex: groupIndex ?? this.groupIndex,
      groupId: groupId ?? this.groupId,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,  // 🚀 NUOVO
    );
  }

  @override
  String toString() {
    return 'ExerciseGroup(type: $type, exercises: ${exercises.length}, groupIndex: $groupIndex, currentExercise: $currentExerciseIndex)';
  }
}

/// Utility class per il raggruppamento degli esercizi
class ExerciseGroupingUtils {
  /// Raggruppa gli esercizi in base a setType e linkedToPrevious
  static List<ExerciseGroup> groupExercises(List<WorkoutExercise> exercises) {
    _log('🧮 [GROUPING] Starting grouping with ${exercises.length} exercises');

    if (exercises.isEmpty) {
      _log('⚠️ [GROUPING] No exercises to group');
      return [];
    }

    // Ordina gli esercizi per ordine
    final sortedExercises = List<WorkoutExercise>.from(exercises)
      ..sort((a, b) => a.ordine.compareTo(b.ordine));

    _log('📋 [GROUPING] Sorted exercises:');
    for (final exercise in sortedExercises) {
      _log('  - ${exercise.nome}: setType="${exercise.setType}", linkedInt=${exercise.linkedToPreviousInt}, ordine=${exercise.ordine}');
    }

    final List<ExerciseGroup> groups = [];
    int groupIndex = 0;

    for (int i = 0; i < sortedExercises.length; i++) {
      final exercise = sortedExercises[i];

      // 🔧 FIX: Usa linkedToPreviousInt invece di linkedToPrevious
      // Se linkedToPreviousInt = 0, inizia un nuovo gruppo
      if (exercise.linkedToPreviousInt == 0) {
        final List<WorkoutExercise> groupExercises = [exercise];

        // Aggiungi tutti gli esercizi successivi collegati a questo
        for (int j = i + 1; j < sortedExercises.length; j++) {
          final nextExercise = sortedExercises[j];

          // 🔧 FIX: Usa linkedToPreviousInt invece di linkedToPrevious
          // Se il prossimo esercizio è collegato e dello stesso tipo, aggiungilo al gruppo
          if (nextExercise.linkedToPreviousInt == 1 &&
              nextExercise.setType == exercise.setType) {
            groupExercises.add(nextExercise);
          } else {
            // Esercizio non collegato, ferma la ricerca per questo gruppo
            break;
          }
        }

        // Crea il gruppo
        final group = ExerciseGroup(
          type: exercise.setType.isEmpty ? 'normal' : exercise.setType,
          exercises: groupExercises,
          groupIndex: groupIndex,
          groupId: 'group_${groupIndex}_${DateTime.now().millisecondsSinceEpoch}',
        );

        groups.add(group);
        groupIndex++;

        _log('✅ [GROUPING] Created group ${groupIndex - 1}: ${group.type} with ${group.exercises.length} exercises');
        for (final ex in group.exercises) {
          _log('    └─ ${ex.nome}');
        }

        // Salta gli esercizi già processati
        i += groupExercises.length - 1;
      }
      // 🔧 FIX: Usa linkedToPreviousInt invece di linkedToPrevious
      // Se linkedToPreviousInt = 1 ma non è stato processato, crea un gruppo singolo
      else if (exercise.linkedToPreviousInt == 1) {
        _log('⚠️ [GROUPING] Found orphaned linked exercise: ${exercise.nome} - creating single group');

        final group = ExerciseGroup(
          type: 'normal', // Tratta come normale se è orfano
          exercises: [exercise],
          groupIndex: groupIndex,
          groupId: 'group_${groupIndex}_${DateTime.now().millisecondsSinceEpoch}',
        );

        groups.add(group);
        groupIndex++;
      }
    }

    _log('🎯 [GROUPING] Final result: ${groups.length} groups created');
    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      _log('  Group $i: ${group.type} (${group.exercises.length} exercises) - ${group.displayName}');
    }

    return groups;
  }

  /// Trova il gruppo che contiene un determinato esercizio
  static ExerciseGroup? findGroupContainingExercise(
      List<ExerciseGroup> groups,
      int exerciseId
      ) {
    for (final group in groups) {
      if (group.exercises.any((exercise) => exercise.id == exerciseId)) {
        return group;
      }
    }
    return null;
  }

  /// Calcola il progresso totale dell'allenamento basato sui gruppi
  static double calculateOverallProgress(
      List<ExerciseGroup> groups,
      Map<int, List<CompletedSeriesData>> completedSeries,
      ) {
    if (groups.isEmpty) return 0.0;

    int totalCompletedGroups = 0;

    for (final group in groups) {
      if (group.isCompleted(completedSeries)) {
        totalCompletedGroups++;
      }
    }

    return totalCompletedGroups / groups.length;
  }

  /// Verifica se tutti i gruppi sono completati
  static bool areAllGroupsCompleted(
      List<ExerciseGroup> groups,
      Map<int, List<CompletedSeriesData>> completedSeries,
      ) {
    if (groups.isEmpty) return false;

    return groups.every((group) => group.isCompleted(completedSeries));
  }

  /// Ottieni statistiche di riepilogo dei gruppi
  static Map<String, dynamic> getGroupingStats(List<ExerciseGroup> groups) {
    final stats = <String, int>{
      'total_groups': groups.length,
      'normal_groups': 0,
      'superset_groups': 0,
      'circuit_groups': 0,
      'total_exercises': 0,
    };

    for (final group in groups) {
      stats['total_exercises'] = stats['total_exercises']! + group.exercises.length;

      switch (group.type) {
        case 'normal':
          stats['normal_groups'] = stats['normal_groups']! + 1;
          break;
        case 'superset':
          stats['superset_groups'] = stats['superset_groups']! + 1;
          break;
        case 'circuit':
          stats['circuit_groups'] = stats['circuit_groups']! + 1;
          break;
      }
    }

    return stats;
  }
}