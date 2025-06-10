// lib/features/workouts/bloc/plateau_bloc.dart - PERFORMANCE OPTIMIZED VERSION + FIX TRIGGER MULTIPLI
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../models/plateau_models.dart';
import '../models/workout_plan_models.dart';
import '../models/active_workout_models.dart';
import '../services/plateau_detector.dart';
import '../repository/workout_repository.dart';
import '../../../core/services/session_service.dart';
import '../../../core/di/dependency_injection.dart';

// 🛠️ Helper function for logging
void _plateauLog(String message, {String name = 'PlateauBloc'}) {
  if (kDebugMode) {
    print('[CONSOLE] [plateau_bloc][$name] $message');
  }
}

// ============================================================================
// PLATEAU EVENTS (unchanged)
// ============================================================================

abstract class PlateauEvent extends Equatable {
  const PlateauEvent();
  @override
  List<Object?> get props => [];
}

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

class DismissPlateau extends PlateauEvent {
  final int exerciseId;
  const DismissPlateau({required this.exerciseId});
  @override
  List<Object> get props => [exerciseId];
}

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

class UpdatePlateauConfig extends PlateauEvent {
  final PlateauDetectionConfig config;
  const UpdatePlateauConfig({required this.config});
  @override
  List<Object> get props => [config];
}

class ResetPlateauState extends PlateauEvent {
  const ResetPlateauState();
}

// ============================================================================
// PLATEAU STATES (unchanged)
// ============================================================================

abstract class PlateauState extends Equatable {
  const PlateauState();
  @override
  List<Object?> get props => [];
}

class PlateauInitial extends PlateauState {
  const PlateauInitial();
}

class PlateauAnalyzing extends PlateauState {
  final String? message;
  const PlateauAnalyzing({this.message});
  @override
  List<Object?> get props => [message];
}

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

  List<PlateauInfo> get activePlateaus => plateaus.where((p) => !p.isDismissed).toList();

  PlateauInfo? getPlateauForExercise(int exerciseId) {
    return plateaus.where((p) => p.exerciseId == exerciseId && !p.isDismissed).firstOrNull;
  }

  bool hasPlateauForExercise(int exerciseId) {
    return getPlateauForExercise(exerciseId) != null;
  }

  List<GroupPlateauAnalysis> get significantGroupPlateaus =>
      groupAnalyses.where((g) => g.hasSignificantPlateau).toList();

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
// 🚀 PLATEAU BLOC - PERFORMANCE OPTIMIZED VERSION + FIX TRIGGER MULTIPLI
// ============================================================================

class PlateauBloc extends Bloc<PlateauEvent, PlateauState> {
  final WorkoutRepository _workoutRepository;
  late PlateauDetector _plateauDetector;

  // 🚀 PERFORMANCE OPTIMIZATION: Cache ottimizzata
  final Map<int, List<CompletedSeriesData>> _historicDataCache = {};

  // Cache userId per evitare lookup multipli
  int? _cachedUserId;

  // 🚀 PERFORMANCE: Cache timestamp per evitare ricaricamenti inutili
  final Map<int, DateTime> _cacheTimestamps = {};

  // 🚀 PERFORMANCE: Flag per evitare caricamenti multipli simultanei
  bool _isLoadingHistoricData = false;

  // 🚀 PERFORMANCE: Lista esercizi correnti per caricamento mirato
  Set<int> _currentExerciseIds = {};

  // 🔧 FIX: TRACK ANALISI E DISMISS PER EVITARE TRIGGER MULTIPLI
  final Set<int> _analyzedExercises = {}; // Esercizi già analizzati
  final Set<int> _dismissedExercises = {}; // Esercizi con plateau dismissed dall'utente
  final Map<int, PlateauInfo> _detectedPlateaus = {}; // Cache plateau rilevati
  final Map<int, DateTime> _lastAnalysisTime = {}; // Timestamp ultima analisi per esercizio

  // 🔧 FIX: Intervallo minimo tra analisi (5 minuti)
  static const Duration _minAnalysisInterval = Duration(minutes: 5);

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

  /// Ottiene userId dalla sessione con cache
  Future<int?> _getUserId() async {
    if (_cachedUserId != null) {
      return _cachedUserId;
    }

    try {
      final sessionService = getIt<SessionService>();
      _cachedUserId = await sessionService.getCurrentUserId();
      _plateauLog('🔑 [SESSION] UserId cached: $_cachedUserId');
      return _cachedUserId;
    } catch (e) {
      _plateauLog('❌ [SESSION] Error getting userId: $e');
      return null;
    }
  }

  /// 🚀 PERFORMANCE OPTIMIZED: Controlla se i dati sono freschi
  bool _isCacheFresh(int exerciseId) {
    final cacheTime = _cacheTimestamps[exerciseId];
    if (cacheTime == null) return false;

    // Cache valida per 5 minuti
    final cacheAge = DateTime.now().difference(cacheTime);
    return cacheAge.inMinutes < 5;
  }

  /// 🔧 FIX: Controlla se l'esercizio può essere analizzato
  bool _canAnalyzeExercise(int exerciseId) {
    // 1. Se è dismissed dall'utente, NON analizzare
    if (_dismissedExercises.contains(exerciseId)) {
      _plateauLog('🔧 [TRIGGER FIX] Exercise $exerciseId - SKIPPING: dismissed by user');
      return false;
    }

    // 2. Se già analizzato recentemente, NON rianalizzare
    final lastAnalysis = _lastAnalysisTime[exerciseId];
    if (lastAnalysis != null) {
      final timeSinceLastAnalysis = DateTime.now().difference(lastAnalysis);
      if (timeSinceLastAnalysis < _minAnalysisInterval) {
        _plateauLog('🔧 [TRIGGER FIX] Exercise $exerciseId - SKIPPING: analyzed ${timeSinceLastAnalysis.inMinutes}min ago (min: ${_minAnalysisInterval.inMinutes}min)');
        return false;
      }
    }

    // 3. Se plateau già rilevato e non dismissed, NON rianalizzare
    if (_detectedPlateaus.containsKey(exerciseId)) {
      final plateau = _detectedPlateaus[exerciseId]!;
      if (!plateau.isDismissed) {
        _plateauLog('🔧 [TRIGGER FIX] Exercise $exerciseId - SKIPPING: plateau already detected and not dismissed');
        return false;
      }
    }

    _plateauLog('🔧 [TRIGGER FIX] Exercise $exerciseId - CAN ANALYZE: passed all checks');
    return true;
  }

  /// 🔧 FIX: Registra analisi eseguita
  void _markExerciseAnalyzed(int exerciseId) {
    _analyzedExercises.add(exerciseId);
    _lastAnalysisTime[exerciseId] = DateTime.now();
    _plateauLog('🔧 [TRIGGER FIX] Exercise $exerciseId - marked as analyzed');
  }

  /// 🔧 FIX: Registra plateau dismissed
  void _markExerciseDismissed(int exerciseId) {
    _dismissedExercises.add(exerciseId);
    _detectedPlateaus.remove(exerciseId);
    _plateauLog('🔧 [TRIGGER FIX] Exercise $exerciseId - marked as dismissed');
  }

  /// 🔧 FIX: Handler per analizzare un singolo esercizio CON CONTROLLI ANTI-SPAM
  Future<void> _onAnalyzeExercisePlateau(
      AnalyzeExercisePlateau event,
      Emitter<PlateauState> emit,
      ) async {
    _plateauLog('🔍 [EVENT] AnalyzeExercisePlateau - Exercise: ${event.exerciseId} (${event.exerciseName})');

    // 🔧 FIX: Controllo se può essere analizzato (anti-spam)
    if (!_canAnalyzeExercise(event.exerciseId)) {
      _plateauLog('🔧 [TRIGGER FIX] Skipping analysis for exercise ${event.exerciseId} - already processed');
      return;
    }

    emit(const PlateauAnalyzing(message: 'Analizzando plateau esercizio...'));

    try {
      // 🚀 PERFORMANCE: Controlla cache fresca
      if (_historicDataCache.containsKey(event.exerciseId) && _isCacheFresh(event.exerciseId)) {
        final exerciseData = _historicDataCache[event.exerciseId]!;
        _plateauLog('⚡ [CACHE HIT] Using fresh cache for exercise ${event.exerciseId}: ${exerciseData.length} series');
      } else {
        _plateauLog('🔄 [CACHE MISS] Loading targeted data for exercise ${event.exerciseId}');

        // Ottieni userId dalla sessione
        final userId = await _getUserId();

        if (userId != null) {
          // 🚀 PERFORMANCE: Caricamento MIRATO per singolo esercizio
          await _loadTargetedHistoricData(userId, [event.exerciseId]);
        } else {
          _plateauLog('❌ [ERROR] Cannot get userId for historic data loading');
          emit(const PlateauError(message: 'Impossibile ottenere ID utente per analisi plateau'));
          return;
        }
      }

      // Verifica che i dati siano disponibili
      final exerciseData = _historicDataCache[event.exerciseId] ?? [];
      _plateauLog('🎯 [ANALYSIS] Starting plateau detection with ${exerciseData.length} historic series');

      // 🔧 FIX: Marca come analizzato PRIMA della detection
      _markExerciseAnalyzed(event.exerciseId);

      final plateau = await _plateauDetector.detectPlateau(
        exerciseId: event.exerciseId,
        exerciseName: event.exerciseName,
        currentWeight: event.currentWeight,
        currentReps: event.currentReps,
        historicData: _historicDataCache,
      );

      if (plateau != null) {
        _plateauLog('🚨 [RESULT] Plateau rilevato per ${event.exerciseName}!');
        _plateauLog('🚨 [PLATEAU DETAILS] Type: ${plateau.plateauType}, Sessions: ${plateau.sessionsInPlateau}');

        // 🔧 FIX: Salva plateau rilevato in cache
        _detectedPlateaus[event.exerciseId] = plateau;

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

  /// 🚀 PERFORMANCE OPTIMIZED: Caricamento dati storici MIRATO
  Future<void> _loadTargetedHistoricData(int userId, List<int> exerciseIds) async {
    // Evita caricamenti multipli simultanei
    if (_isLoadingHistoricData) {
      _plateauLog('⏳ [LOADING] Historic data loading already in progress, waiting...');

      // Aspetta che il caricamento corrente finisca
      while (_isLoadingHistoricData) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      _plateauLog('✅ [LOADING] Historic data loading completed by another call');
      return;
    }

    _isLoadingHistoricData = true;

    try {
      _plateauLog('🚀 [LOADING TARGETED] Loading targeted historic data for user $userId');
      _plateauLog('🚀 [LOADING TARGETED] Target exercises: $exerciseIds');

      // 🚀 PERFORMANCE: Carica solo ultimi 3 allenamenti (non 10!)
      final workoutHistoryResult = await _workoutRepository.getWorkoutHistory(userId);

      await workoutHistoryResult.fold(
        onSuccess: (workouts) async {
          _plateauLog('📚 [LOADED TARGETED] ${workouts.length} total workouts found');

          // 🚀 PERFORMANCE: Prendi solo ultimi 3 allenamenti invece di 10
          final recentWorkouts = workouts.take(3).toList();
          _plateauLog('🚀 [OPTIMIZATION] Using only last ${recentWorkouts.length} workouts for analysis');

          // Lista delle operazioni async da completare
          final List<Future<void>> loadingOperations = [];

          // Per ogni allenamento recente, carica le serie dettagliate
          for (final workout in recentWorkouts) {
            final future = _loadWorkoutSeriesTargeted(workout.id, exerciseIds);
            loadingOperations.add(future);
          }

          // Aspetta che TUTTE le operazioni completino
          _plateauLog('⏳ [LOADING TARGETED] Waiting for ${loadingOperations.length} loading operations to complete...');
          await Future.wait(loadingOperations);
          _plateauLog('✅ [LOADING TARGETED] All loading operations completed');

          // 🚀 PERFORMANCE: Aggiorna timestamp cache
          for (final exerciseId in exerciseIds) {
            _cacheTimestamps[exerciseId] = DateTime.now();
          }

          // Log risultati finali
          _plateauLog('📚 [FINAL TARGETED] Total exercises in cache: ${_historicDataCache.length}');
          for (final exerciseId in exerciseIds) {
            final series = _historicDataCache[exerciseId] ?? [];
            _plateauLog('📚 [CACHED TARGETED] Exercise $exerciseId: ${series.length} historic series');
          }

        },
        onFailure: (exception, message) async {
          _plateauLog('❌ [ERROR TARGETED] Failed to load workout history: $message');
        },
      );

    } catch (e) {
      _plateauLog('💥 [ERROR TARGETED] Exception loading historic data: $e');
    } finally {
      _isLoadingHistoricData = false;
      _plateauLog('🏁 [LOADING TARGETED] Historic data loading completed');
    }
  }

  /// 🚀 PERFORMANCE OPTIMIZED: Carica le serie per un singolo allenamento, filtrando per esercizi target
  Future<void> _loadWorkoutSeriesTargeted(int workoutId, List<int> targetExerciseIds) async {
    try {
      _plateauLog('📊 [SERIES TARGETED] Loading series for workout $workoutId (target exercises: $targetExerciseIds)');
      final seriesResult = await _workoutRepository.getWorkoutSeriesDetail(workoutId);

      seriesResult.fold(
        onSuccess: (series) {
          _plateauLog('📊 [SERIES TARGETED] Workout $workoutId: ${series.length} total series found');

          int addedSeries = 0;
          // 🚀 PERFORMANCE: Filtra solo serie degli esercizi target
          for (final seriesData in series) {
            final exerciseId = seriesData.schedaEsercizioId;

            // 🚀 PERFORMANCE: Considera solo esercizi target
            if (targetExerciseIds.contains(exerciseId)) {
              _historicDataCache.putIfAbsent(exerciseId, () => []);
              _historicDataCache[exerciseId]!.add(seriesData);
              addedSeries++;

              // Log solo per esercizi target
              _plateauLog('📊 [EX${exerciseId} TARGETED] Added series: ${seriesData.peso}kg x ${seriesData.ripetizioni} (${seriesData.timestamp})');
            }
          }

          _plateauLog('📊 [SERIES TARGETED] Workout $workoutId: $addedSeries relevant series added to cache');
        },
        onFailure: (exception, message) {
          _plateauLog('⚠️ [WARNING TARGETED] Error loading series for workout $workoutId: $message');
        },
      );
    } catch (e) {
      _plateauLog('💥 [ERROR TARGETED] Exception loading workout $workoutId: $e');
    }
  }

  /// 🚀 PERFORMANCE OPTIMIZED: Handler per analizzare workout plateaus CON FIX
  Future<void> _onAnalyzeWorkoutPlateaus(
      AnalyzeWorkoutPlateaus event,
      Emitter<PlateauState> emit,
      ) async {
    _plateauLog('🔍 [EVENT] AnalyzeWorkoutPlateaus - ${event.exercises.length} exercises');

    emit(const PlateauAnalyzing(message: 'Analizzando plateau allenamento...'));

    try {
      // 🚀 PERFORMANCE: Estrai IDs degli esercizi per caricamento mirato
      final exerciseIds = event.exercises
          .map((e) => e.schedaEsercizioId ?? e.id)
          .toList();

      _currentExerciseIds = exerciseIds.toSet();

      _plateauLog('🚀 [WORKOUT ANALYSIS] Target exercises: $exerciseIds');

      // 🔧 FIX: Filtra solo esercizi che possono essere analizzati
      final exercisesToAnalyze = exerciseIds.where(_canAnalyzeExercise).toList();
      _plateauLog('🔧 [TRIGGER FIX] Analyzing only ${exercisesToAnalyze.length}/${exerciseIds.length} exercises (others skipped)');

      if (exercisesToAnalyze.isEmpty) {
        _plateauLog('🔧 [TRIGGER FIX] No exercises to analyze - all were skipped');
        return;
      }

      // 🚀 PERFORMANCE: Caricamento mirato solo per esercizi da analizzare
      await _loadTargetedHistoricData(event.userId, exercisesToAnalyze);

      final List<PlateauInfo> allPlateaus = [];
      final List<GroupPlateauAnalysis> groupAnalyses = [];

      // Raggruppa esercizi per tipo (normale, superset, circuit)
      final exerciseGroups = _groupExercisesByType(event.exercises);

      for (final group in exerciseGroups) {
        // 🔧 FIX: Filtra esercizi del gruppo che possono essere analizzati
        final analyzableExercises = group['exercises'].where((ex) {
          final exId = ex.schedaEsercizioId ?? ex.id;
          return _canAnalyzeExercise(exId);
        }).toList();

        if (analyzableExercises.isNotEmpty) {
          // 🔧 FIX: Marca esercizi come analizzati
          for (final ex in analyzableExercises) {
            final exId = ex.schedaEsercizioId ?? ex.id;
            _markExerciseAnalyzed(exId);
          }

          final groupAnalysis = await _plateauDetector.detectGroupPlateau(
            groupName: group['name'],
            groupType: group['type'],
            exercises: analyzableExercises,
            currentWeights: event.currentWeights,
            currentReps: event.currentReps,
            historicData: _historicDataCache,
          );

          groupAnalyses.add(groupAnalysis);
          allPlateaus.addAll(groupAnalysis.plateauList);

          // 🔧 FIX: Salva plateau rilevati in cache
          for (final plateau in groupAnalysis.plateauList) {
            _detectedPlateaus[plateau.exerciseId] = plateau;
          }

          _plateauLog('📊 [GROUP] ${group['name']}: ${groupAnalysis.exercisesInPlateau}/${groupAnalysis.totalExercises} plateau');
        } else {
          _plateauLog('🔧 [TRIGGER FIX] Group ${group['name']}: no exercises to analyze');
        }
      }

      final statistics = _plateauDetector.calculateStatistics(allPlateaus);

      _plateauLog('🎯 [RESULT] Totale plateau rilevati: ${allPlateaus.length}');

      if (allPlateaus.isNotEmpty) {
        emit(PlateauDetected(
          plateaus: allPlateaus,
          groupAnalyses: groupAnalyses,
          statistics: statistics,
          config: _plateauDetector.config,
          analyzedAt: DateTime.now(),
        ));
      } else {
        _plateauLog('✅ [RESULT] Nessun plateau rilevato in questo workout');
      }

    } catch (e) {
      _plateauLog('💥 [ERROR] Error analyzing workout plateaus: $e');
      emit(PlateauError(
        message: 'Errore nell\'analisi plateau allenamento: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  // ============================================================================
  // OTHER HANDLERS (updated with dismiss fix)
  // ============================================================================

  Future<void> _onAnalyzeGroupPlateau(AnalyzeGroupPlateau event, Emitter<PlateauState> emit) async {
    _plateauLog('🔍 [EVENT] AnalyzeGroupPlateau - Group: ${event.groupName} (${event.groupType})');
    emit(const PlateauAnalyzing(message: 'Analizzando plateau gruppo...'));

    try {
      // 🚀 PERFORMANCE: Caricamento mirato per gruppo
      final exerciseIds = event.exercises
          .map((e) => e.schedaEsercizioId ?? e.id)
          .toList();

      // 🔧 FIX: Filtra solo esercizi che possono essere analizzati
      final exercisesToAnalyze = exerciseIds.where(_canAnalyzeExercise).toList();

      if (exercisesToAnalyze.isEmpty) {
        _plateauLog('🔧 [TRIGGER FIX] No exercises to analyze in group - all were skipped');
        return;
      }

      final userId = await _getUserId();
      if (userId != null) {
        await _loadTargetedHistoricData(userId, exercisesToAnalyze);
      }

      // 🔧 FIX: Marca esercizi come analizzati
      for (final exId in exercisesToAnalyze) {
        _markExerciseAnalyzed(exId);
      }

      final groupAnalysis = await _plateauDetector.detectGroupPlateau(
        groupName: event.groupName,
        groupType: event.groupType,
        exercises: event.exercises.where((ex) {
          final exId = ex.schedaEsercizioId ?? ex.id;
          return exercisesToAnalyze.contains(exId);
        }).toList(),
        currentWeights: event.currentWeights,
        currentReps: event.currentReps,
        historicData: _historicDataCache,
      );

      _plateauLog('📊 [RESULT] Gruppo ${event.groupName}: ${groupAnalysis.exercisesInPlateau}/${groupAnalysis.totalExercises} esercizi in plateau');

      // 🔧 FIX: Salva plateau rilevati in cache
      for (final plateau in groupAnalysis.plateauList) {
        _detectedPlateaus[plateau.exerciseId] = plateau;
      }

      // Aggiorna lo stato
      if (state is PlateauDetected) {
        final currentState = state as PlateauDetected;
        final updatedPlateaus = [...currentState.plateaus];
        for (final plateau in groupAnalysis.plateauList) {
          updatedPlateaus.removeWhere((p) => p.exerciseId == plateau.exerciseId);
          updatedPlateaus.add(plateau);
        }

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

  /// 🔧 FIX: DismissPlateau with tracking
  Future<void> _onDismissPlateau(DismissPlateau event, Emitter<PlateauState> emit) async {
    _plateauLog('❌ [EVENT] DismissPlateau - Exercise: ${event.exerciseId}');

    // 🔧 FIX: Marca come dismissed per evitare future analisi
    _markExerciseDismissed(event.exerciseId);

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

      _plateauLog('✅ [DISMISS] Exercise ${event.exerciseId} dismissed and won\'t be reanalyzed');
    }
  }

  Future<void> _onApplyProgressionSuggestion(ApplyProgressionSuggestion event, Emitter<PlateauState> emit) async {
    // 🔧 FIX: Quando applichi una suggestion, marca anche come dismissed
    _markExerciseDismissed(event.exerciseId);
    add(DismissPlateau(exerciseId: event.exerciseId));
  }

  Future<void> _onUpdatePlateauConfig(UpdatePlateauConfig event, Emitter<PlateauState> emit) async {
    _plateauDetector = PlateauDetector(config: event.config);
    if (state is PlateauDetected) {
      final currentState = state as PlateauDetected;
      emit(currentState.copyWith(config: event.config, analyzedAt: DateTime.now()));
    }
  }

  /// 🔧 FIX: Reset with complete cleanup
  Future<void> _onResetPlateauState(ResetPlateauState event, Emitter<PlateauState> emit) async {
    // 🔧 FIX: Pulisci tutti i tracker
    _analyzedExercises.clear();
    _dismissedExercises.clear();
    _detectedPlateaus.clear();
    _lastAnalysisTime.clear();

    _historicDataCache.clear();
    _cacheTimestamps.clear();
    _currentExerciseIds.clear();
    _cachedUserId = null;
    _isLoadingHistoricData = false;

    _plateauLog('🔧 [RESET] All plateau tracking data cleared');
    emit(const PlateauInitial());
  }

  // ============================================================================
  // HELPER METHODS (unchanged)
  // ============================================================================

  List<Map<String, dynamic>> _groupExercisesByType(List<WorkoutExercise> exercises) {
    final List<Map<String, dynamic>> groups = [];
    List<WorkoutExercise> currentGroup = [];
    String currentGroupType = 'normal';

    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];

      if (exercise.linkedToPreviousInt == 0) {
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
        currentGroup.add(exercise);
      }
    }

    if (currentGroup.isNotEmpty) {
      groups.add({
        'name': _generateGroupName(currentGroup, currentGroupType),
        'type': currentGroupType,
        'exercises': currentGroup,
      });
    }

    return groups;
  }

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
  // PUBLIC METHODS (updated with checks)
  // ============================================================================

  void analyzeExercisePlateau(int exerciseId, String exerciseName, double weight, int reps) {
    // 🔧 FIX: Solo se può essere analizzato
    if (_canAnalyzeExercise(exerciseId)) {
      add(AnalyzeExercisePlateau(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        currentWeight: weight,
        currentReps: reps,
      ));
    } else {
      _plateauLog('🔧 [PUBLIC] Skipped analysis for exercise $exerciseId - blocked by checks');
    }
  }

  void analyzeGroupPlateau(String groupName, String groupType, List<WorkoutExercise> exercises, Map<int, double> weights, Map<int, int> reps) {
    add(AnalyzeGroupPlateau(
      groupName: groupName,
      groupType: groupType,
      exercises: exercises,
      currentWeights: weights,
      currentReps: reps,
    ));
  }

  void analyzeWorkoutPlateaus(List<WorkoutExercise> exercises, Map<int, double> weights, Map<int, int> reps, int userId) {
    add(AnalyzeWorkoutPlateaus(
      exercises: exercises,
      currentWeights: weights,
      currentReps: reps,
      userId: userId,
    ));
  }

  void dismissPlateau(int exerciseId) {
    add(DismissPlateau(exerciseId: exerciseId));
  }

  void applyProgressionSuggestion(int exerciseId, ProgressionSuggestion suggestion) {
    add(ApplyProgressionSuggestion(exerciseId: exerciseId, suggestion: suggestion));
  }

  void updateConfig(PlateauDetectionConfig config) {
    add(UpdatePlateauConfig(config: config));
  }

  void resetState() {
    add(const ResetPlateauState());
  }

  // 🔧 FIX: Metodi per check manuali
  bool isExerciseDismissed(int exerciseId) => _dismissedExercises.contains(exerciseId);
  bool isExerciseAnalyzed(int exerciseId) => _analyzedExercises.contains(exerciseId);
  PlateauInfo? getCachedPlateau(int exerciseId) => _detectedPlateaus[exerciseId];

  // 🔧 DEBUG: Metodi per ispezionare stato interno
  Set<int> get debugDismissedExercises => Set.from(_dismissedExercises);
  Set<int> get debugAnalyzedExercises => Set.from(_analyzedExercises);
  Map<int, DateTime> get debugLastAnalysisTime => Map.from(_lastAnalysisTime);
}