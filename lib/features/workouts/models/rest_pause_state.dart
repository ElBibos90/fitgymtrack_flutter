// lib/features/workouts/models/rest_pause_state.dart
// 🚀 FASE 5: Modello RestPauseState separato

/// Stato REST-PAUSE per tracciare l'esecuzione delle micro-serie
class RestPauseState {
  final List<int> sequence;          // [8, 4, 2] - sequenza ripetizioni
  final int currentMicroSeries;      // 0, 1, 2 - indice micro-serie corrente
  final int restSeconds;             // 15 - secondi di recupero tra micro-serie
  final bool isInRestPause;          // true durante mini-recupero
  final List<int> completedReps;     // [8, 4] - ripetizioni completate finora
  final int totalRepsCompleted;      // 12 - totale ripetizioni completate

  const RestPauseState({
    required this.sequence,
    this.currentMicroSeries = 0,
    required this.restSeconds,
    this.isInRestPause = false,
    this.completedReps = const [],
    this.totalRepsCompleted = 0,
  });

  /// Crea una nuova istanza con valori aggiornati
  RestPauseState copyWith({
    List<int>? sequence,
    int? currentMicroSeries,
    int? restSeconds,
    bool? isInRestPause,
    List<int>? completedReps,
    int? totalRepsCompleted,
  }) {
    return RestPauseState(
      sequence: sequence ?? this.sequence,
      currentMicroSeries: currentMicroSeries ?? this.currentMicroSeries,
      restSeconds: restSeconds ?? this.restSeconds,
      isInRestPause: isInRestPause ?? this.isInRestPause,
      completedReps: completedReps ?? this.completedReps,
      totalRepsCompleted: totalRepsCompleted ?? this.totalRepsCompleted,
    );
  }

  /// Verifica se ci sono ancora micro-serie da completare
  bool get hasMoreMicroSeries => currentMicroSeries < sequence.length;

  /// Ottiene le ripetizioni target per la micro-serie corrente
  int get currentTargetReps => hasMoreMicroSeries ? sequence[currentMicroSeries] : 0;

  /// Verifica se questa è l'ultima micro-serie
  bool get isLastMicroSeries => currentMicroSeries == sequence.length - 1;

  /// Ottiene le ripetizioni per la prossima micro-serie (se esiste)
  int? get nextTargetReps {
    final nextIndex = currentMicroSeries + 1;
    return nextIndex < sequence.length ? sequence[nextIndex] : null;
  }

  /// Genera la stringa sequenza completata (es. "8+4+2")
  String get completedSequenceString {
    if (completedReps.isEmpty) return '';
    return completedReps.join('+');
  }

  /// Genera la stringa sequenza completa per il salvataggio
  String get fullSequenceString => sequence.join('+');
}