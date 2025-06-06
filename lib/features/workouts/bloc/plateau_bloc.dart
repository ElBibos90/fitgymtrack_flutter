// lib/features/workouts/bloc/plateau_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../models/plateau_models.dart';
import '../models/workout_plan_models.dart';
import '../models/active_workout_models.dart';
import '../services/plateau_detector.dart';
import '../repository/workout_repository.dart';

// 🛠️ Helper function for logging
void _plateauLog(String message, {String name = 'PlateauBloc'}) {
  if (kDebugMode) {
    debugPrint('[$name] $message');
  }
}

// ============================================================================
// PLATEAU EVENTS
// ============================================================================

abstract class PlateauEvent extends Equatable {
  const PlateauEvent();

  @override
  List<Object?> get props => [];
}

/// Analizza i plateau per un singolo esercizio
class AnalyzeExercisePlateau extends PlateauEvent {
  final int exerciseId;
  final String exerciseName;
  final double currentWeight;
  final int currentReps;

  const AnalyzeExercisePlateau({
    required this.exerciseId,
    required this.exerciseName,
    required this.currentWeight,
    required this.currentReps,
  });

  @override
  List<Object> get props => [exerciseId, exerciseName, currentWeight, currentReps];
}

/// Analizza i plateau per un gruppo di esercizi (superset/circuit)
class AnalyzeGroupPlateau extends PlateauEvent {
  final String groupName;
  final String groupType;
  final List<WorkoutExercise> exercises;
  final Map<int, double> currentWeights;
  final Map<int, int> currentReps;

  const AnalyzeGroupPlateau({
    required this.groupName,
    required this.groupType,
    required this.exercises,
    required this.currentWeights,
    required this.currentReps,
  });

  @override
  List<Object> get props => [groupName, groupType, exercises, currentWeights, currentReps];
}

/// Analizza tutti i plateau per l'allenamento corrente
class AnalyzeWorkoutPlateaus extends PlateauEvent {
  final List<WorkoutExercise> exercises;
  final Map<int, double> currentWeights;
  final Map<int, int> currentReps;
  final int userId;

  const AnalyzeWorkoutPlateaus({
    required this.exercises,
    required this.currentWeights,
    required this.currentReps,
    required this.userId,
  });

  @override
  List<Object> get props => [exercises, currentWeights, currentReps, userId];
}

/// Dismisses un plateau (lo nasconde)
class DismissPlateau extends PlateauEvent {
  final int exerciseId;

  const DismissPlateau({required this.exerciseId});

  @override
  List<Object> get props => [exerciseId];
}

/// Applica un suggerimento di progressione
class ApplyProgressionSuggestion extends PlateauEvent {
  final int exerciseId;
  final ProgressionSuggestion suggestion;

  const ApplyProgressionSuggestion({
    required this.exerciseId,
    required this.suggestion,
  });

  @override
  List<Object> get props => [exerciseId, suggestion];
}

/// Aggiorna la configurazione del rilevamento plateau
class UpdatePlateauConfig extends PlateauEvent {
  final PlateauDetectionConfig config;

  const UpdatePlateauConfig({required this.config});

  @override
  List<Object> get props => [config];
}

/// Reset dello stato plateau
class ResetPlateauState extends PlateauEvent {
  const ResetPlateauState();
}

// ============================================================================
// PLATEAU STATES
// ============================================================================

abstract class PlateauState extends Equatable {
  const PlateauState();

  @override
  List<Object?> get props => [];
}

/// Stato iniziale
class PlateauInitial extends PlateauState {
  const PlateauInitial();
}

/// Stato di caricamento
class PlateauAnalyzing extends PlateauState {
  final String? message;

  const PlateauAnalyzing({this.message});

  @override
  List<Object?> get props => [message];
}

/// Stato con plateau rilevati
class PlateauDetected extends PlateauState {
  final List<PlateauInfo> plateaus;
  final List<GroupPlateauAnalysis> groupAnalyses;
  final PlateauStatistics statistics;
  final PlateauDetectionConfig config;
  final DateTime analyzedAt;

  const PlateauDetected({
    required this.plateaus,
    required this.groupAnalyses,
    required this.statistics,
    required this.config,
    required this.analyzedAt,
  });

  /// Ottiene i plateau attivi (non dismissati)
  List<PlateauInfo> get activePlateaus => plateaus.where((p) => !p.isDismissed).toList();

  /// Ottiene i plateau per un esercizio specifico
  PlateauInfo? getPlateauForExercise(int exerciseId) {
    return plateaus.where((p) => p.exerciseId == exerciseId && !p.isDismissed).firstOrNull;
  }

  /// Verifica se un esercizio ha plateau
  bool hasPlateauForExercise(int exerciseId) {
    return getPlateauForExercise(exerciseId) != null;
  }

  /// Ottiene i gruppi con plateau significativi
  List<GroupPlateauAnalysis> get significantGroupPlateaus =>
      groupAnalyses.where((g) => g.hasSignificantPlateau).toList();

  /// Copia lo stato con modifiche
  PlateauDetected copyWith({
    List<PlateauInfo>? plateaus,
    List<GroupPlateauAnalysis>? groupAnalyses,
    PlateauStatistics? statistics,
    PlateauDetectionConfig? config,
    DateTime? analyzedAt,
  }) {
    return PlateauDetected(
      plateaus: plateaus ?? this.plateaus,
      groupAnalyses: groupAnalyses ?? this.groupAnalyses,
      statistics: statistics ?? this.statistics,
      config: config ?? this.config,
      analyzedAt: analyzedAt ?? this.analyzedAt,
    );
  }

  @override
  List<Object> get props => [plateaus, groupAnalyses, statistics, config, analyzedAt];
}

/// Stato di errore
class PlateauError extends PlateauState {
  final String message;
  final Exception? exception;

  const PlateauError({
    required this.message,
    this.exception,
  });

  @override
  List<Object?> get props => [message, exception];
}

// ============================================================================
// PLATEAU BLOC
// ============================================================================

class PlateauBloc extends Bloc<PlateauEvent, PlateauState> {
  final WorkoutRepository _workoutRepository;
  late PlateauDetector _plateauDetector;

  // Cache per i dati storici
  final Map<int, List<CompletedSeriesData>> _historicDataCache = {};

  PlateauBloc({required WorkoutRepository workoutRepository})
      : _workoutRepository = workoutRepository,
        super(const PlateauInitial()) {

    _plateauLog('🏗️ [INIT] PlateauBloc constructor called');

    // Inizializza detector con configurazione di default
    _plateauDetector = PlateauDetector(config: createDefaultPlateauConfig());

    // Registrazione event handlers
    on<AnalyzeExercisePlateau>(_onAnalyzeExercisePlateau);
    on<AnalyzeGroupPlateau>(_onAnalyzeGroupPlateau);
    on<AnalyzeWorkoutPlateaus>(_onAnalyzeWorkoutPlateaus);
    on<DismissPlateau>(_onDismissPlateau);
    on<ApplyProgressionSuggestion>(_onApplyProgressionSuggestion);
    on<UpdatePlateauConfig>(_onUpdatePlateauConfig);
    on<ResetPlateauState>(_onResetPlateauState);

    _plateauLog('✅ [INIT] PlateauBloc event handlers registered');
  }

  /// Handler per analizzare un singolo esercizio
  Future<void> _onAnalyzeExercisePlateau(
      AnalyzeExercisePlateau event,
      Emitter<PlateauState> emit,
      ) async {
    _plateauLog('🔍 [EVENT] AnalyzeExercisePlateau - Exercise: ${event.exerciseId} (${event.exerciseName})');

    emit(const PlateauAnalyzing(message: 'Analizzando plateau esercizio...'));

    try {
      // Carica dati storici se non in cache
      if (!_historicDataCache.containsKey(event.exerciseId)) {
        await _loadHistoricDataForExercise(event.exerciseId);
      }

      final plateau = await _plateauDetector.detectPlateau(
        exerciseId: event.exerciseId,
        exerciseName: event.exerciseName,
        currentWeight: event.currentWeight,
        currentReps: event.currentReps,
        historicData: _historicDataCache,
      );

      if (plateau != null) {
        _plateauLog('🚨 [RESULT] Plateau rilevato per ${event.exerciseName}');

        // Aggiorna lo stato con il nuovo plateau
        if (state is PlateauDetected) {
          final currentState = state as PlateauDetected;
          final updatedPlateaus = [...currentState.plateaus];

          // Rimuovi eventuale plateau precedente per questo esercizio
          updatedPlateaus.removeWhere((p) => p.exerciseId == event.exerciseId);
          // Aggiungi nuovo plateau
          updatedPlateaus.add(plateau);

          final updatedStatistics = _plateauDetector.calculateStatistics(updatedPlateaus);

          emit(currentState.copyWith(
            plateaus: updatedPlateaus,
            statistics: updatedStatistics,
            analyzedAt: DateTime.now(),
          ));
        } else {
          // Primo plateau rilevato
          emit(PlateauDetected(
            plateaus: [plateau],
            groupAnalyses: [],
            statistics: _plateauDetector.calculateStatistics([plateau]),
            config: _plateauDetector.config,
            analyzedAt: DateTime.now(),
          ));
        }
      } else {
        _plateauLog('✅ [RESULT] Nessun plateau rilevato per ${event.exerciseName}');

        // Se era in stato PlateauDetected, rimuovi plateau per questo esercizio
        if (state is PlateauDetected) {
          final currentState = state as PlateauDetected;
          final updatedPlateaus = currentState.plateaus
              .where((p) => p.exerciseId != event.exerciseId)
              .toList();

          if (updatedPlateaus.isEmpty) {
            emit(const PlateauInitial());
          } else {
            final updatedStatistics = _plateauDetector.calculateStatistics(updatedPlateaus);
            emit(currentState.copyWith(
              plateaus: updatedPlateaus,
              statistics: updatedStatistics,
              analyzedAt: DateTime.now(),
            ));
          }
        }
      }

    } catch (e) {
      _plateauLog('💥 [ERROR] Error analyzing exercise plateau: $e');
      emit(PlateauError(
        message: 'Errore nell\'analisi plateau: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler per analizzare un gruppo di esercizi
  Future<void> _onAnalyzeGroupPlateau(
      AnalyzeGroupPlateau event,
      Emitter<PlateauState> emit,
      ) async {
    _plateauLog('🔍 [EVENT] AnalyzeGroupPlateau - Group: ${event.groupName} (${event.groupType})');

    emit(const PlateauAnalyzing(message: 'Analizzando plateau gruppo...'));

    try {
      // Carica dati storici per tutti gli esercizi del gruppo
      for (final exercise in event.exercises) {
        final exerciseId = exercise.schedaEsercizioId ?? exercise.id;
        if (!_historicDataCache.containsKey(exerciseId)) {
          await _loadHistoricDataForExercise(exerciseId);
        }
      }

      final groupAnalysis = await _plateauDetector.detectGroupPlateau(
        groupName: event.groupName,
        groupType: event.groupType,
        exercises: event.exercises,
        currentWeights: event.currentWeights,
        currentReps: event.currentReps,
        historicData: _historicDataCache,
      );

      _plateauLog('📊 [RESULT] Gruppo ${event.groupName}: ${groupAnalysis.exercisesInPlateau}/${groupAnalysis.totalExercises} esercizi in plateau');

      // Aggiorna lo stato
      if (state is PlateauDetected) {
        final currentState = state as PlateauDetected;

        // Aggiorna plateaus individuali
        final updatedPlateaus = [...currentState.plateaus];
        for (final plateau in groupAnalysis.plateauList) {
          updatedPlateaus.removeWhere((p) => p.exerciseId == plateau.exerciseId);
          updatedPlateaus.add(plateau);
        }

        // Aggiorna analisi gruppi
        final updatedGroupAnalyses = [...currentState.groupAnalyses];
        updatedGroupAnalyses.removeWhere((g) => g.groupName == event.groupName);
        updatedGroupAnalyses.add(groupAnalysis);

        final updatedStatistics = _plateauDetector.calculateStatistics(updatedPlateaus);

        emit(currentState.copyWith(
          plateaus: updatedPlateaus,
          groupAnalyses: updatedGroupAnalyses,
          statistics: updatedStatistics,
          analyzedAt: DateTime.now(),
        ));
      } else {
        // Primo gruppo analizzato
        emit(PlateauDetected(
          plateaus: groupAnalysis.plateauList,
          groupAnalyses: [groupAnalysis],
          statistics: _plateauDetector.calculateStatistics(groupAnalysis.plateauList),
          config: _plateauDetector.config,
          analyzedAt: DateTime.now(),
        ));
      }

    } catch (e) {
      _plateauLog('💥 [ERROR] Error analyzing group plateau: $e');
      emit(PlateauError(
        message: 'Errore nell\'analisi plateau gruppo: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler per analizzare tutti i plateau dell'allenamento
  Future<void> _onAnalyzeWorkoutPlateaus(
      AnalyzeWorkoutPlateaus event,
      Emitter<PlateauState> emit,
      ) async {
    _plateauLog('🔍 [EVENT] AnalyzeWorkoutPlateaus - ${event.exercises.length} exercises');

    emit(const PlateauAnalyzing(message: 'Analizzando plateau allenamento...'));

    try {
      // Carica dati storici completi
      await _loadCompleteHistoricData(event.userId);

      final List<PlateauInfo> allPlateaus = [];
      final List<GroupPlateauAnalysis> groupAnalyses = [];

      // Raggruppa esercizi per tipo (normale, superset, circuit)
      final exerciseGroups = _groupExercisesByType(event.exercises);

      for (final group in exerciseGroups) {
        final groupAnalysis = await _plateauDetector.detectGroupPlateau(
          groupName: group['name'],
          groupType: group['type'],
          exercises: group['exercises'],
          currentWeights: event.currentWeights,
          currentReps: event.currentReps,
          historicData: _historicDataCache,
        );

        groupAnalyses.add(groupAnalysis);
        allPlateaus.addAll(groupAnalysis.plateauList);

        _plateauLog('📊 [GROUP] ${group['name']}: ${groupAnalysis.exercisesInPlateau}/${groupAnalysis.totalExercises} plateau');
      }

      final statistics = _plateauDetector.calculateStatistics(allPlateaus);

      _plateauLog('🎯 [RESULT] Totale plateau rilevati: ${allPlateaus.length}');

      emit(PlateauDetected(
        plateaus: allPlateaus,
        groupAnalyses: groupAnalyses,
        statistics: statistics,
        config: _plateauDetector.config,
        analyzedAt: DateTime.now(),
      ));

    } catch (e) {
      _plateauLog('💥 [ERROR] Error analyzing workout plateaus: $e');
      emit(PlateauError(
        message: 'Errore nell\'analisi plateau allenamento: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler per dismissare un plateau
  Future<void> _onDismissPlateau(
      DismissPlateau event,
      Emitter<PlateauState> emit,
      ) async {
    _plateauLog('❌ [EVENT] DismissPlateau - Exercise: ${event.exerciseId}');

    if (state is PlateauDetected) {
      final currentState = state as PlateauDetected;

      final updatedPlateaus = currentState.plateaus.map((plateau) {
        if (plateau.exerciseId == event.exerciseId) {
          return plateau.copyWith(isDismissed: true);
        }
        return plateau;
      }).toList();

      emit(currentState.copyWith(
        plateaus: updatedPlateaus,
        analyzedAt: DateTime.now(),
      ));

      _plateauLog('✅ [RESULT] Plateau dismissed for exercise ${event.exerciseId}');
    }
  }

  /// Handler per applicare un suggerimento
  Future<void> _onApplyProgressionSuggestion(
      ApplyProgressionSuggestion event,
      Emitter<PlateauState> emit,
      ) async {
    _plateauLog('💡 [EVENT] ApplyProgressionSuggestion - Exercise: ${event.exerciseId}');
    _plateauLog('💡 [SUGGESTION] ${event.suggestion.description}');

    // Nota: L'applicazione effettiva del suggerimento dovrebbe essere gestita
    // dal BLoC dell'allenamento attivo. Qui possiamo solo dismissare il plateau
    // una volta applicato il suggerimento.

    add(DismissPlateau(exerciseId: event.exerciseId));
  }

  /// Handler per aggiornare la configurazione
  Future<void> _onUpdatePlateauConfig(
      UpdatePlateauConfig event,
      Emitter<PlateauState> emit,
      ) async {
    _plateauLog('⚙️ [EVENT] UpdatePlateauConfig');

    _plateauDetector = PlateauDetector(config: event.config);

    if (state is PlateauDetected) {
      final currentState = state as PlateauDetected;
      emit(currentState.copyWith(
        config: event.config,
        analyzedAt: DateTime.now(),
      ));
    }

    _plateauLog('✅ [RESULT] Plateau config updated');
  }

  /// Handler per reset dello stato
  Future<void> _onResetPlateauState(
      ResetPlateauState event,
      Emitter<PlateauState> emit,
      ) async {
    _plateauLog('🔄 [EVENT] ResetPlateauState');

    _historicDataCache.clear();
    emit(const PlateauInitial());

    _plateauLog('✅ [RESULT] Plateau state reset');
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Carica dati storici per un singolo esercizio
  Future<void> _loadHistoricDataForExercise(int exerciseId) async {
    // Qui dovresti implementare la logica per caricare i dati storici
    // dell'esercizio dal repository. Per ora usiamo cache vuota.
    _historicDataCache[exerciseId] = [];
    _plateauLog('📚 [CACHE] Historic data cached for exercise $exerciseId (empty for now)');
  }

  /// Carica dati storici completi per l'utente
  Future<void> _loadCompleteHistoricData(int userId) async {
    try {
      _plateauLog('📚 [LOADING] Loading complete historic data for user $userId');

      // Carica cronologia allenamenti
      final workoutHistoryResult = await _workoutRepository.getWorkoutHistory(userId);

      workoutHistoryResult.fold(
        onSuccess: (workouts) async {
          _plateauLog('📚 [LOADED] ${workouts.length} workouts found');

          // Per ogni allenamento, carica le serie dettagliate
          for (final workout in workouts.take(10)) { // Limita agli ultimi 10 per performance
            try {
              final seriesResult = await _workoutRepository.getWorkoutSeriesDetail(workout.id);

              seriesResult.fold(
                onSuccess: (series) {
                  // Raggruppa le serie per esercizio
                  for (final seriesData in series) {
                    final exerciseId = seriesData.schedaEsercizioId;
                    _historicDataCache.putIfAbsent(exerciseId, () => []);
                    _historicDataCache[exerciseId]!.add(seriesData);
                  }
                },
                onFailure: (exception, message) {
                  _plateauLog('⚠️ [WARNING] Error loading series for workout ${workout.id}: $message');
                },
              );
            } catch (e) {
              _plateauLog('💥 [ERROR] Exception loading workout ${workout.id}: $e');
            }
          }

          // Log risultati
          _historicDataCache.forEach((exerciseId, series) {
            _plateauLog('📚 [CACHED] Exercise $exerciseId: ${series.length} historic series');
          });

        },
        onFailure: (exception, message) {
          _plateauLog('❌ [ERROR] Failed to load workout history: $message');
        },
      );

    } catch (e) {
      _plateauLog('💥 [ERROR] Exception loading historic data: $e');
    }
  }

  /// Raggruppa esercizi per tipo
  List<Map<String, dynamic>> _groupExercisesByType(List<WorkoutExercise> exercises) {
    final List<Map<String, dynamic>> groups = [];
    List<WorkoutExercise> currentGroup = [];
    String currentGroupType = 'normal';

    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];

      // Nuovo gruppo se linked_to_previous = 0 (non collegato al precedente)
      if (exercise.linkedToPreviousInt == 0) {
        // Salva il gruppo precedente se non vuoto
        if (currentGroup.isNotEmpty) {
          groups.add({
            'name': _generateGroupName(currentGroup, currentGroupType),
            'type': currentGroupType,
            'exercises': List<WorkoutExercise>.from(currentGroup),
          });
          currentGroup.clear();
        }
        currentGroup.add(exercise);
        currentGroupType = exercise.setType;
      } else {
        // Esercizio collegato al precedente
        currentGroup.add(exercise);
      }
    }

    // Aggiungi l'ultimo gruppo
    if (currentGroup.isNotEmpty) {
      groups.add({
        'name': _generateGroupName(currentGroup, currentGroupType),
        'type': currentGroupType,
        'exercises': currentGroup,
      });
    }

    return groups;
  }

  /// Genera nome per un gruppo di esercizi
  String _generateGroupName(List<WorkoutExercise> exercises, String groupType) {
    if (exercises.length == 1) {
      return exercises.first.nome;
    }

    switch (groupType) {
      case 'superset':
        return 'Superset: ${exercises.map((e) => e.nome).join(' + ')}';
      case 'circuit':
        return 'Circuit: ${exercises.length} esercizi';
      default:
        return 'Gruppo: ${exercises.length} esercizi';
    }
  }

  // ============================================================================
  // PUBLIC METHODS
  // ============================================================================

  /// Analizza plateau per un singolo esercizio
  void analyzeExercisePlateau(int exerciseId, String exerciseName, double weight, int reps) {
    add(AnalyzeExercisePlateau(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      currentWeight: weight,
      currentReps: reps,
    ));
  }

  /// Analizza plateau per un gruppo
  void analyzeGroupPlateau(
      String groupName,
      String groupType,
      List<WorkoutExercise> exercises,
      Map<int, double> weights,
      Map<int, int> reps,
      ) {
    add(AnalyzeGroupPlateau(
      groupName: groupName,
      groupType: groupType,
      exercises: exercises,
      currentWeights: weights,
      currentReps: reps,
    ));
  }

  /// Analizza plateau per tutto l'allenamento
  void analyzeWorkoutPlateaus(
      List<WorkoutExercise> exercises,
      Map<int, double> weights,
      Map<int, int> reps,
      int userId,
      ) {
    add(AnalyzeWorkoutPlateaus(
      exercises: exercises,
      currentWeights: weights,
      currentReps: reps,
      userId: userId,
    ));
  }

  /// Dismisses un plateau
  void dismissPlateau(int exerciseId) {
    add(DismissPlateau(exerciseId: exerciseId));
  }

  /// Applica un suggerimento
  void applyProgressionSuggestion(int exerciseId, ProgressionSuggestion suggestion) {
    add(ApplyProgressionSuggestion(
      exerciseId: exerciseId,
      suggestion: suggestion,
    ));
  }

  /// Aggiorna configurazione
  void updateConfig(PlateauDetectionConfig config) {
    add(UpdatePlateauConfig(config: config));
  }

  /// Reset dello stato
  void resetState() {
    add(const ResetPlateauState());
  }
}