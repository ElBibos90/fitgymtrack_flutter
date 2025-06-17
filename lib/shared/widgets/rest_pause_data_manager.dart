// 🚀 STEP 4: Sistema completo per gestione dati REST-PAUSE
// File: lib/shared/widgets/rest_pause_data_manager.dart

import 'package:flutter/material.dart';

/// Dati di una singola micro-serie completata
class MicroSeriesData {
  final int targetReps;
  final int actualReps;
  final DateTime timestamp;
  final String? note;

  const MicroSeriesData({
    required this.targetReps,
    required this.actualReps,
    required this.timestamp,
    this.note,
  });

  @override
  String toString() {
    return 'MicroSeries(target: $targetReps, actual: $actualReps)';
  }
}

/// Gestisce tutti i dati di una serie REST-PAUSE completa
class RestPauseExecutionData {
  final String exerciseName;
  final double weight;
  final int serieNumber;
  final String originalSequence; // "11+4+4"
  final int restSeconds;
  final List<int> targetSequence; // [11, 4, 4]
  final List<MicroSeriesData> completedMicroSeries; // Dati effettivi
  final DateTime startTime;
  DateTime? endTime;

  RestPauseExecutionData({
    required this.exerciseName,
    required this.weight,
    required this.serieNumber,
    required this.originalSequence,
    required this.restSeconds,
    required this.targetSequence,
    required this.startTime,
    this.completedMicroSeries = const [],
    this.endTime,
  });

  /// Aggiunge una micro-serie completata
  RestPauseExecutionData addMicroSeries({
    required int targetReps,
    required int actualReps,
    String? note,
  }) {
    final newMicroSeries = MicroSeriesData(
      targetReps: targetReps,
      actualReps: actualReps,
      timestamp: DateTime.now(),
      note: note,
    );

    return RestPauseExecutionData(
      exerciseName: exerciseName,
      weight: weight,
      serieNumber: serieNumber,
      originalSequence: originalSequence,
      restSeconds: restSeconds,
      targetSequence: targetSequence,
      startTime: startTime,
      completedMicroSeries: [...completedMicroSeries, newMicroSeries],
      endTime: endTime,
    );
  }

  /// Completa la serie REST-PAUSE
  RestPauseExecutionData complete() {
    return RestPauseExecutionData(
      exerciseName: exerciseName,
      weight: weight,
      serieNumber: serieNumber,
      originalSequence: originalSequence,
      restSeconds: restSeconds,
      targetSequence: targetSequence,
      startTime: startTime,
      completedMicroSeries: completedMicroSeries,
      endTime: DateTime.now(),
    );
  }

  // ====== GETTERS CALCOLATI ======

  /// Totale ripetizioni effettivamente completate
  int get totalActualReps => completedMicroSeries.fold(0, (sum, ms) => sum + ms.actualReps);

  /// Totale ripetizioni target
  int get totalTargetReps => targetSequence.fold(0, (sum, reps) => sum + reps);

  /// Sequenza effettiva completata come stringa
  String get actualSequence => completedMicroSeries.map((ms) => ms.actualReps.toString()).join('+');

  /// Durata totale della serie REST-PAUSE
  Duration? get totalDuration => endTime?.difference(startTime);

  /// Se la serie è completata
  bool get isCompleted => completedMicroSeries.length == targetSequence.length;

  /// Micro-serie corrente (0-based index)
  int get currentMicroSeriesIndex => completedMicroSeries.length;

  /// Se ci sono ancora micro-serie da completare
  bool get hasMoreMicroSeries => currentMicroSeriesIndex < targetSequence.length;

  /// Target reps per la prossima micro-serie
  int? get nextTargetReps => hasMoreMicroSeries ? targetSequence[currentMicroSeriesIndex] : null;

  /// Percentuale di completamento
  double get completionPercentage => targetSequence.isNotEmpty
      ? (currentMicroSeriesIndex / targetSequence.length)
      : 0.0;

  // ====== METODI DI UTILITÀ ======

  /// Converte in note leggibili per il database
  String toNote() {
    final duration = totalDuration;
    final durationText = duration != null
        ? ' (${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')})'
        : '';

    return 'REST-PAUSE: $actualSequence / $originalSequence$durationText';
  }

  /// Debug info completa
  @override
  String toString() {
    return '''RestPauseExecutionData(
  exercise: $exerciseName,
  weight: ${weight}kg,
  series: $serieNumber,
  original: $originalSequence,
  actual: $actualSequence,
  total reps: $totalActualReps/$totalTargetReps,
  completed: ${completedMicroSeries.length}/${targetSequence.length},
  duration: ${totalDuration?.inSeconds ?? 0}s
)''';
  }

  // ====== VALIDAZIONE ======

  /// Valida se i dati sono consistenti
  bool isValid() {
    if (targetSequence.isEmpty) return false;
    if (weight <= 0) return false;
    if (originalSequence.isEmpty) return false;
    if (exerciseName.isEmpty) return false;
    if (serieNumber < 1) return false;
    if (restSeconds < 5 || restSeconds > 300) return false;

    // Verifica che le micro-serie completate non superino quelle target
    if (completedMicroSeries.length > targetSequence.length) return false;

    // Verifica che ogni micro-serie abbia reps positive
    for (final ms in completedMicroSeries) {
      if (ms.actualReps < 0 || ms.targetReps < 0) return false;
    }

    return true;
  }
}

/// Helper per parsing e creazione dati REST-PAUSE
class RestPauseDataHelper {
  /// Parsa sequenza REST-PAUSE sicura
  static List<int> parseSequence(String? sequence) {
    if (sequence == null || sequence.isEmpty) return [];

    try {
      return sequence
          .split('+')
          .map((s) => int.tryParse(s.trim()) ?? 0)
          .where((reps) => reps > 0)
          .toList();
    } catch (e) {
      print('⚠️ [REST-PAUSE DATA] Error parsing sequence "$sequence": $e');
      return [];
    }
  }

  /// Crea RestPauseExecutionData iniziale
  static RestPauseExecutionData createInitial({
    required String exerciseName,
    required double weight,
    required int serieNumber,
    required String restPauseSequence,
    required int restSeconds,
  }) {
    final targetSequence = parseSequence(restPauseSequence);

    return RestPauseExecutionData(
      exerciseName: exerciseName,
      weight: weight,
      serieNumber: serieNumber,
      originalSequence: restPauseSequence,
      restSeconds: restSeconds,
      targetSequence: targetSequence,
      startTime: DateTime.now(),
    );
  }

  /// Valida sequenza REST-PAUSE
  static bool isValidSequence(String? sequence) {
    if (sequence == null || sequence.isEmpty) return false;

    final parsed = parseSequence(sequence);
    if (parsed.isEmpty) return false;
    if (parsed.length > 10) return false; // Max 10 micro-serie
    if (parsed.any((reps) => reps > 100)) return false; // Max 100 reps per micro-serie

    return true;
  }

  /// Stima durata totale REST-PAUSE
  static Duration estimateDuration({
    required List<int> sequence,
    required int restSeconds,
    double avgSecondsPerRep = 3.0,
  }) {
    // Tempo esecuzione = reps totali * secondi per rep
    final totalReps = sequence.fold(0, (sum, reps) => sum + reps);
    final executionSeconds = (totalReps * avgSecondsPerRep).round();

    // Tempo recupero = (micro-serie - 1) * restSeconds
    final restTime = (sequence.length - 1) * restSeconds;

    return Duration(seconds: executionSeconds + restTime);
  }

  /// Converte RestPauseExecutionData in SeriesData per il database
  static Map<String, dynamic> toSeriesDataMap(RestPauseExecutionData data) {
    if (!data.isValid() || !data.isCompleted) {
      throw ArgumentError('RestPauseExecutionData deve essere valido e completato');
    }

    return {
      'peso': data.weight,
      'ripetizioni': data.totalActualReps,
      'note': data.toNote(),
      'is_rest_pause': 1,
      'rest_pause_reps': data.actualSequence,
      'rest_pause_rest_seconds': data.restSeconds,
    };
  }
}