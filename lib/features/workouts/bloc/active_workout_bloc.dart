// lib/features/workouts/bloc/active_workout_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../repository/workout_repository.dart';
import '../services/workout_offline_service.dart';
import '../models/active_workout_models.dart';
import '../models/workout_plan_models.dart';
import '../models/workout_history_models.dart' as workout_models;
import '../../stats/models/user_stats_models.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/di/dependency_injection.dart';
import '../../auth/bloc/auth_bloc.dart';

// 🛠️ Helper function for logging
void _log(String message, {String name = 'ActiveWorkoutBloc'}) {
  if (kDebugMode) {
    //print('[CONSOLE] [active_workout_bloc][$name] $message');
  }
}

// ============================================================================
// ACTIVE WORKOUT EVENTS (invariati)
// ============================================================================

abstract class ActiveWorkoutEvent extends Equatable {
  const ActiveWorkoutEvent();

  @override
  List<Object?> get props => [];
}

/// Evento per iniziare un nuovo allenamento
class StartWorkoutSession extends ActiveWorkoutEvent {
  final int userId;
  final int schedaId;

  const StartWorkoutSession({
    required this.userId,
    required this.schedaId,
  });

  @override
  List<Object> get props => [userId, schedaId];
}

/// Evento per caricare gli esercizi della scheda corrente
class LoadWorkoutExercises extends ActiveWorkoutEvent {
  final int schedaId;

  const LoadWorkoutExercises({required this.schedaId});

  @override
  List<Object> get props => [schedaId];
}

/// 🆕 NUOVO: Evento per caricare lo storico degli allenamenti precedenti
class LoadWorkoutHistory extends ActiveWorkoutEvent {
  final int userId;
  final int schedaId;

  const LoadWorkoutHistory({
    required this.userId,
    required this.schedaId,
  });

  @override
  List<Object> get props => [userId, schedaId];
}

/// Evento per caricare le serie completate di un allenamento
class LoadCompletedSeries extends ActiveWorkoutEvent {
  final int allenamentoId;

  const LoadCompletedSeries({required this.allenamentoId});

  @override
  List<Object> get props => [allenamentoId];
}

/// Evento per salvare una serie completata
class SaveCompletedSeries extends ActiveWorkoutEvent {
  final int allenamentoId;
  final List<SeriesData> serie;
  final String requestId;

  const SaveCompletedSeries({
    required this.allenamentoId,
    required this.serie,
    required this.requestId,
  });

  @override
  List<Object> get props => [allenamentoId, serie, requestId];
}

/// Evento per completare l'allenamento
class CompleteWorkoutSession extends ActiveWorkoutEvent {
  final int allenamentoId;
  final int durataTotale;
  final String? note;

  const CompleteWorkoutSession({
    required this.allenamentoId,
    required this.durataTotale,
    this.note,
  });

  @override
  List<Object?> get props => [allenamentoId, durataTotale, note];
}

/// Evento per annullare/eliminare un allenamento
class CancelWorkoutSession extends ActiveWorkoutEvent {
  final int allenamentoId;

  const CancelWorkoutSession({required this.allenamentoId});

  @override
  List<Object> get props => [allenamentoId];
}

/// Evento per resettare lo stato
class ResetActiveWorkoutState extends ActiveWorkoutEvent {
  const ResetActiveWorkoutState();
}

/// Evento per aggiornare il timer dell'allenamento
class UpdateWorkoutTimer extends ActiveWorkoutEvent {
  final Duration duration;

  const UpdateWorkoutTimer({required this.duration});

  @override
  List<Object> get props => [duration];
}

/// Evento per aggiungere una serie locale (prima del salvataggio)
class AddLocalSeries extends ActiveWorkoutEvent {
  final int exerciseId;
  final SeriesData seriesData;

  const AddLocalSeries({
    required this.exerciseId,
    required this.seriesData,
  });

  @override
  List<Object> get props => [exerciseId, seriesData];
}

/// Evento per rimuovere una serie locale
class RemoveLocalSeries extends ActiveWorkoutEvent {
  final int exerciseId;
  final String seriesId;

  const RemoveLocalSeries({
    required this.exerciseId,
    required this.seriesId,
  });

  @override
  List<Object> get props => [exerciseId, seriesId];
}

/// 🆕 NUOVO: Evento per aggiornare i valori di un esercizio (peso/ripetizioni)
class UpdateExerciseValues extends ActiveWorkoutEvent {
  final int exerciseId;
  final double weight;
  final int reps;

  const UpdateExerciseValues({
    required this.exerciseId,
    required this.weight,
    required this.reps,
  });

  @override
  List<Object> get props => [exerciseId, weight, reps];
}

/// 🚀 NUOVO: Evento per sincronizzare dati offline
class SyncOfflineData extends ActiveWorkoutEvent {
  const SyncOfflineData();

  @override
  List<Object> get props => [];
}

/// 🚀 NUOVO: Evento per ripristinare allenamento offline
class RestoreOfflineWorkout extends ActiveWorkoutEvent {
  const RestoreOfflineWorkout();

  @override
  List<Object> get props => [];
}

/// 🚀 NUOVO: Evento per salvare stato offline
class SaveOfflineState extends ActiveWorkoutEvent {
  const SaveOfflineState();

  @override
  List<Object> get props => [];
}

/// 🌐 NUOVO: Evento per controllare allenamenti in sospeso
class CheckPendingWorkout extends ActiveWorkoutEvent {
  final int userId;
  const CheckPendingWorkout(this.userId);

  @override
  List<Object> get props => [userId];
}

/// 🌐 NUOVO: Evento per ripristinare un allenamento in sospeso dal database
class RestorePendingWorkout extends ActiveWorkoutEvent {
  final Map<String, dynamic> pendingWorkout;
  
  const RestorePendingWorkout(this.pendingWorkout);
  
  @override
  List<Object> get props => [pendingWorkout];
}

// ============================================================================
// ACTIVE WORKOUT STATES (invariati)
// ============================================================================

abstract class ActiveWorkoutState extends Equatable {
  const ActiveWorkoutState();

  @override
  List<Object?> get props => [];
}

/// Stato iniziale - nessun allenamento attivo
class ActiveWorkoutInitial extends ActiveWorkoutState {
  const ActiveWorkoutInitial();
}

/// Stato di caricamento
class ActiveWorkoutLoading extends ActiveWorkoutState {
  final String? message;

  const ActiveWorkoutLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Stato di allenamento iniziato con successo
class WorkoutSessionStarted extends ActiveWorkoutState {
  final StartWorkoutResponse response;
  final int userId;
  final int schedaId;
  final DateTime startTime;

  const WorkoutSessionStarted({
    required this.response,
    required this.userId,
    required this.schedaId,
    required this.startTime,
  });

  @override
  List<Object> get props => [response, userId, schedaId, startTime];
}

/// Stato con allenamento attivo e dati completi
class WorkoutSessionActive extends ActiveWorkoutState {
  final ActiveWorkout activeWorkout;
  final List<WorkoutExercise> exercises;
  final Map<int, List<CompletedSeriesData>> completedSeries;
  final Duration elapsedTime;
  final DateTime startTime;
  final Map<int, ExerciseValues> exerciseValues; // 🆕 NUOVO: Valori esercizi

  const WorkoutSessionActive({
    required this.activeWorkout,
    required this.exercises,
    required this.completedSeries,
    required this.elapsedTime,
    required this.startTime,
    this.exerciseValues = const {}, // 🆕 NUOVO
  });

  @override
  List<Object> get props => [
    activeWorkout,
    exercises,
    completedSeries,
    elapsedTime,
    startTime,
    exerciseValues, // 🆕 NUOVO
  ];

  /// Copia lo stato aggiornando solo alcuni campi
  WorkoutSessionActive copyWith({
    ActiveWorkout? activeWorkout,
    List<WorkoutExercise>? exercises,
    Map<int, List<CompletedSeriesData>>? completedSeries,
    Duration? elapsedTime,
    DateTime? startTime,
    Map<int, ExerciseValues>? exerciseValues, // 🆕 NUOVO
  }) {
    return WorkoutSessionActive(
      activeWorkout: activeWorkout ?? this.activeWorkout,
      exercises: exercises ?? this.exercises,
      completedSeries: completedSeries ?? this.completedSeries,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      startTime: startTime ?? this.startTime,
      exerciseValues: exerciseValues ?? this.exerciseValues, // 🆕 NUOVO
    );
  }
}

/// 🚀 NUOVO: Stato temporaneo per salvare serie senza loading
class SeriesSaving extends ActiveWorkoutState {
  final String message;

  const SeriesSaving({required this.message});

  @override
  List<Object> get props => [message];
}

/// Stato con serie salvata con successo
class SeriesSaved extends ActiveWorkoutState {
  final SaveCompletedSeriesResponse response;
  final String message;

  const SeriesSaved({
    required this.response,
    required this.message,
  });

  @override
  List<Object> get props => [response, message];
}

/// Stato con allenamento completato
class WorkoutSessionCompleted extends ActiveWorkoutState {
  final CompleteWorkoutResponse response;
  final Duration totalDuration;
  final String message;

  const WorkoutSessionCompleted({
    required this.response,
    required this.totalDuration,
    required this.message,
  });

  @override
  List<Object> get props => [response, totalDuration, message];
}

/// 🌐 NUOVO: Stato per completamento offline
class WorkoutSessionCompletedOffline extends ActiveWorkoutState {
  final int allenamentoId;
  final Duration totalDuration;
  final String message;

  const WorkoutSessionCompletedOffline({
    required this.allenamentoId,
    required this.totalDuration,
    required this.message,
  });

  @override
  List<Object> get props => [allenamentoId, totalDuration, message];
}

/// Stato con allenamento annullato
class WorkoutSessionCancelled extends ActiveWorkoutState {
  final String message;

  const WorkoutSessionCancelled({required this.message});

  @override
  List<Object> get props => [message];
}

/// Stato di errore
class ActiveWorkoutError extends ActiveWorkoutState {
  final String message;
  final Exception? exception;

  const ActiveWorkoutError({
    required this.message,
    this.exception,
  });

  @override
  List<Object?> get props => [message, exception];
}

/// 🚀 NUOVO: Stato per sincronizzazione offline
class OfflineSyncInProgress extends ActiveWorkoutState {
  final String message;
  final int pendingCount;

  const OfflineSyncInProgress({
    required this.message,
    required this.pendingCount,
  });

  @override
  List<Object> get props => [message, pendingCount];
}

/// 🚀 NUOVO: Stato per ripristino offline
class OfflineRestoreInProgress extends ActiveWorkoutState {
  final String message;

  const OfflineRestoreInProgress({required this.message});

  @override
  List<Object> get props => [message];
}

/// 🌐 NUOVO: Stato per allenamento in sospeso trovato
class PendingWorkoutFound extends ActiveWorkoutState {
  final Map<String, dynamic> pendingWorkout;
  final String message;

  const PendingWorkoutFound({
    required this.pendingWorkout,
    required this.message,
  });

  @override
  List<Object> get props => [pendingWorkout, message];
}

// ============================================================================
// 🆕 NUOVO: DATA CLASSES PER GESTIRE VALORI ESERCIZI E STORICO
// ============================================================================

/// Rappresenta i valori correnti di un esercizio (peso e ripetizioni)
class ExerciseValues extends Equatable {
  final double weight;
  final int reps;
  final bool isFromHistory; // 🆕 Indica se i valori vengono dallo storico

  const ExerciseValues({
    required this.weight,
    required this.reps,
    this.isFromHistory = false,
  });

  @override
  List<Object> get props => [weight, reps, isFromHistory];

  ExerciseValues copyWith({
    double? weight,
    int? reps,
    bool? isFromHistory,
  }) {
    return ExerciseValues(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isFromHistory: isFromHistory ?? this.isFromHistory,
    );
  }
}

/// 🔧 FIX: Rappresenta i dati storici di un esercizio organizzati per serie
class HistoricExerciseData extends Equatable {
  final int exerciseId;
  final Map<int, CompletedSeriesData> seriesByNumber; // Serie organizzate per numero (1, 2, 3, ecc.)
  final String lastWorkoutDate;

  const HistoricExerciseData({
    required this.exerciseId,
    required this.seriesByNumber,
    required this.lastWorkoutDate,
  });

  /// Ottiene la serie per numero specifico
  CompletedSeriesData? getSeriesByNumber(int serieNumber) {
    return seriesByNumber[serieNumber];
  }

  /// Ottiene tutte le serie ordinate per numero
  List<CompletedSeriesData> get allSeries {
    final sortedKeys = seriesByNumber.keys.toList()..sort();
    return sortedKeys.map((key) => seriesByNumber[key]!).toList();
  }

  /// Ottiene il numero massimo di serie
  int get maxSeriesNumber {
    return seriesByNumber.keys.isNotEmpty ? seriesByNumber.keys.reduce((a, b) => a > b ? a : b) : 0;
  }

  @override
  List<Object> get props => [exerciseId, seriesByNumber, lastWorkoutDate];
}

// ============================================================================
// 🔧 PERFORMANCE FIX: CACHE PER VALORI SERIE-SPECIFICI
// ============================================================================

/// Cache key per valori serie-specifici
class _SeriesValuesKey {
  final int exerciseId;
  final int seriesNumber;

  const _SeriesValuesKey(this.exerciseId, this.seriesNumber);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is _SeriesValuesKey &&
              runtimeType == other.runtimeType &&
              exerciseId == other.exerciseId &&
              seriesNumber == other.seriesNumber;

  @override
  int get hashCode => exerciseId.hashCode ^ seriesNumber.hashCode;

  @override
  String toString() => '_SeriesValuesKey($exerciseId, $seriesNumber)';
}

// ============================================================================
// ACTIVE WORKOUT BLOC
// ============================================================================

class ActiveWorkoutBloc extends Bloc<ActiveWorkoutEvent, ActiveWorkoutState> {
  final WorkoutRepository _workoutRepository;
  final WorkoutOfflineService _offlineService;

  // 🔧 FIX: Memorizza i dati storici degli esercizi organizzati meglio
  final Map<int, HistoricExerciseData> _historicWorkoutData = {};

  // 🔧 PERFORMANCE FIX: Cache per valori serie-specifici
  final Map<_SeriesValuesKey, ExerciseValues> _seriesValuesCache = {};

  // 🔧 PERFORMANCE FIX: Set per log debugging (evita spam)
  final Set<int> _loggedExercises = {};

  // 🆕 FIX: Memorizza l'ID dell'allenamento corrente per escluderlo dalla ricerca storica
  int? _currentWorkoutId;

  // 🚀 NUOVO: Flag per tracciare se siamo in modalità offline
  bool _isOfflineMode = false;

  ActiveWorkoutBloc({
    required WorkoutRepository workoutRepository,
    required WorkoutOfflineService offlineService,
  }) : _workoutRepository = workoutRepository,
       _offlineService = offlineService,
       super(const ActiveWorkoutInitial()) {

    _log('🏗️ [INIT] ActiveWorkoutBloc constructor called');

    // Registrazione event handlers
    on<StartWorkoutSession>(_onStartWorkoutSession);
    on<LoadWorkoutExercises>(_onLoadWorkoutExercises);
    on<LoadWorkoutHistory>(_onLoadWorkoutHistory); // 🆕 NUOVO
    on<LoadCompletedSeries>(_onLoadCompletedSeries);
    on<SaveCompletedSeries>(_onSaveCompletedSeries);
    on<CompleteWorkoutSession>(_onCompleteWorkoutSession);
    on<CancelWorkoutSession>(_onCancelWorkoutSession);
    on<ResetActiveWorkoutState>(_onResetActiveWorkoutState);
    on<UpdateWorkoutTimer>(_onUpdateWorkoutTimer);
    on<AddLocalSeries>(_onAddLocalSeries);
    on<RemoveLocalSeries>(_onRemoveLocalSeries);
    on<UpdateExerciseValues>(_onUpdateExerciseValues); // 🆕 NUOVO
    on<SyncOfflineData>(_onSyncOfflineData); // 🚀 NUOVO
    on<RestoreOfflineWorkout>(_onRestoreOfflineWorkout); // 🚀 NUOVO
    on<SaveOfflineState>(_onSaveOfflineState); // 🚀 NUOVO
    on<CheckPendingWorkout>(_onCheckPendingWorkout); // 🌐 NUOVO
    on<RestorePendingWorkout>(_onRestorePendingWorkout); // 🌐 NUOVO

    _log('✅ [INIT] ActiveWorkoutBloc event handlers registered');
  }

  /// 🚀 HANDLER AGGIORNATO: Gestisce tutto con caricamento storico incluso
  Future<void> _onStartWorkoutSession(
      StartWorkoutSession event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    _log('🚀 [EVENT] StartWorkoutSession received - User: ${event.userId}, Scheda: ${event.schedaId}');

    emit(const ActiveWorkoutLoading(message: 'Avvio allenamento...'));
    _log('🔄 [STATE] Emitted ActiveWorkoutLoading');

    try {
      // 🔧 PERFORMANCE FIX: Reset cache e log su nuovo allenamento
      _clearCacheAndLogs();

      // STEP 1: Avvia allenamento
      _log('📡 [API] Calling startWorkout repository method...');
      final workoutResult = await _workoutRepository.startWorkout(event.userId, event.schedaId);

      // Controlla se l'emitter è ancora valido
      if (emit.isDone) {
        _log('⚠️ [WARNING] Emitter is done, stopping execution');
        return;
      }

      // Gestisce il risultato usando fold() ma senza callback async
      StartWorkoutResponse? workoutResponse;
      String? errorMessage;
      Exception? errorException;

      workoutResult.fold(
        onSuccess: (response) {
          workoutResponse = response;
          // 🆕 FIX: Memorizza l'ID dell'allenamento corrente
          _currentWorkoutId = response.allenamentoId;
        },
        onFailure: (exception, message) {
          errorException = exception;
          errorMessage = message;
        },
      );

      if (workoutResponse == null) {
        _log('❌ [ERROR] Error starting workout session: $errorMessage');
        emit(ActiveWorkoutError(
          message: errorMessage ?? 'Errore nell\'avvio dell\'allenamento',
          exception: errorException,
        ));
        return;
      }

      _log('✅ [API] Workout session started successfully: ${workoutResponse!.allenamentoId}');

      // STEP 2: Carica esercizi
      _log('📡 [API] Loading exercises for scheda: ${event.schedaId}');
      final exercisesResult = await _workoutRepository.getWorkoutExercises(event.schedaId);

      // Controlla di nuovo se l'emitter è ancora valido
      if (emit.isDone) {
        _log('⚠️ [WARNING] Emitter is done, stopping execution');
        return;
      }

      // Gestisce il risultato degli esercizi
      List<WorkoutExercise>? exercises;
      errorMessage = null;
      errorException = null;

      exercisesResult.fold(
        onSuccess: (exercisesList) {
          exercises = exercisesList;
        },
        onFailure: (exception, message) {
          errorException = exception;
          errorMessage = message;
        },
      );

      if (exercises == null) {
        _log('❌ [ERROR] Error loading exercises: $errorMessage');
        emit(ActiveWorkoutError(
          message: errorMessage ?? 'Errore nel caricamento degli esercizi',
          exception: errorException,
        ));
        return;
      }

      _log('✅ [API] Successfully loaded ${exercises!.length} exercises');

      // Log dettagli esercizi per debug
      for (final exercise in exercises!) {
        _log('  📝 Exercise: ${exercise.nome} (ID: ${exercise.id}, SchemaExerciseID: ${exercise.schedaEsercizioId})');
      }

      // 🔧 FIX: STEP 3: Carica storico allenamenti per preloadare valori PERFEZIONATO
      _log('📚 [HISTORY] Loading workout history for value preloading...');
      await _loadWorkoutHistoryFixed(event.userId, event.schedaId, exercises!);

      // 🔧 FIX: STEP 4: Crea valori iniziali per ogni esercizio con logica CORRETTA
      final Map<int, ExerciseValues> initialExerciseValues = {};
      for (final exercise in exercises!) {
        final exerciseId = exercise.schedaEsercizioId ?? exercise.id;

        // 🔧 FIX: Preleva valori per serie 1 (per default UI)
        final initialValues = _getInitialValuesForExercisePerfected(exercise, 1);
        initialExerciseValues[exerciseId] = initialValues;

        _log('💡 [VALUES] Exercise ${exercise.nome} (${exerciseId}): '
            'peso=${initialValues.weight}kg, reps=${initialValues.reps} '
            '${initialValues.isFromHistory ? "(FROM HISTORY)" : "(DEFAULT)"}');
      }

      // STEP 5: Crea stato attivo finale
      final startTime = DateTime.now();
      final activeWorkout = ActiveWorkout(
        id: workoutResponse!.allenamentoId,
        schedaId: event.schedaId,
        dataAllenamento: startTime.toIso8601String(),
        userId: event.userId,
        esercizi: exercises!,
      );

      final activeState = WorkoutSessionActive(
        activeWorkout: activeWorkout,
        exercises: exercises!,
        completedSeries: {},
        elapsedTime: Duration.zero,
        startTime: startTime,
        exerciseValues: initialExerciseValues, // 🔧 FIX: Valori preloadati correttamente
      );

      // Controllo finale prima di emettere
      if (!emit.isDone) {
        emit(activeState);
        _log('🔄 [STATE] Emitted WorkoutSessionActive with preloaded values');
      } else {
        _log('⚠️ [WARNING] Cannot emit - emitter is done');
      }

    } catch (e) {
      _log('💥 [EXCEPTION] Exception in _onStartWorkoutSession: $e');

      if (!emit.isDone) {
        emit(ActiveWorkoutError(
          message: 'Errore critico nell\'avvio dell\'allenamento: $e',
          exception: e is Exception ? e : Exception(e.toString()),
        ));
        _log('🔄 [STATE] Emitted ActiveWorkoutError (exception)');
      }
    }
  }

  /// 🆕 NUOVO: Handler per caricare lo storico degli allenamenti
  Future<void> _onLoadWorkoutHistory(
      LoadWorkoutHistory event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    _log('📚 [EVENT] LoadWorkoutHistory received - User: ${event.userId}, Scheda: ${event.schedaId}');

    try {
      await _loadWorkoutHistoryFixed(event.userId, event.schedaId, []);
      _log('✅ [HISTORY] Workout history loaded successfully');
    } catch (e) {
      _log('❌ [HISTORY] Error loading workout history: $e');
      // Non emettiamo errore per lo storico, è opzionale
    }
  }

  /// 🔧 FIX PRINCIPALE: Metodo PERFEZIONATO per caricare lo storico escludendo l'allenamento corrente
  Future<void> _loadWorkoutHistoryFixed(int userId, int schedaId, List<WorkoutExercise> exercises) async {
    try {
      _log('📚 [HISTORY] === CARICAMENTO STORICO FIXATO ===');
      _log('📚 [HISTORY] Loading workout history for userId=$userId, schedaId=$schedaId');
      _log('📚 [HISTORY] Current workout ID to exclude: $_currentWorkoutId');

      // STEP 1: Carica tutti gli allenamenti dell'utente
      final workoutHistoryResult = await _workoutRepository.getWorkoutHistory(userId);

      List<workout_models.WorkoutHistory>? allWorkouts;
      workoutHistoryResult.fold(
        onSuccess: (workouts) {
          allWorkouts = workouts.cast<workout_models.WorkoutHistory>();
        },
        onFailure: (exception, message) {
          _log('⚠️ [HISTORY] Error loading workout history: $message');
          return; // Exit early se non riusciamo a caricare
        },
      );

      if (allWorkouts == null || allWorkouts!.isEmpty) {
        _log('📚 [HISTORY] No previous workouts found');
        return;
      }

      _log('📚 [HISTORY] Found ${allWorkouts!.length} total workouts for user');

      // STEP 2: Filtra per stessa scheda e ordina per data (più recente primo)
      var sameSchemaWorkouts = allWorkouts!
          .where((workout) => workout.schedaId == schedaId)
          .toList()
        ..sort((a, b) => b.dataAllenamento.compareTo(a.dataAllenamento));

      if (sameSchemaWorkouts.isEmpty) {
        _log('📚 [HISTORY] No previous workouts found for schema $schedaId');
        return;
      }

      _log('📚 [HISTORY] Found ${sameSchemaWorkouts.length} workouts with same schema');

      // 🔧 FIX PRINCIPALE: ESCLUDI l'allenamento corrente se presente
      if (_currentWorkoutId != null) {
        final originalCount = sameSchemaWorkouts.length;
        sameSchemaWorkouts = sameSchemaWorkouts
            .where((workout) => workout.id != _currentWorkoutId)
            .toList();

        final excludedCount = originalCount - sameSchemaWorkouts.length;
        if (excludedCount > 0) {
          _log('🚫 [HISTORY] Excluded current workout $_currentWorkoutId from history search');
        }
      }

      if (sameSchemaWorkouts.isEmpty) {
        _log('📚 [HISTORY] No previous completed workouts found after excluding current');
        return;
      }

      _log('📚 [HISTORY] Processing ${sameSchemaWorkouts.length} candidate workouts for history data');

      // 🔧 FIX: STEP 3: Prova con gli allenamenti in ordine finché non trova uno con serie
      workout_models.WorkoutHistory? workoutWithSeries;
      List<CompletedSeriesData>? series;

      for (int i = 0; i < sameSchemaWorkouts.length && i < 3; i++) { // Prova max 3 allenamenti
        final candidate = sameSchemaWorkouts[i];
        _log('📚 [HISTORY] Trying workout ${candidate.id} (${candidate.dataAllenamento}) - attempt ${i + 1}');

        try {
          // Carica le serie del candidato
          final seriesResult = await _workoutRepository.getWorkoutSeriesDetail(candidate.id);

          List<CompletedSeriesData>? candidateSeries;
          seriesResult.fold(
            onSuccess: (seriesList) {
              candidateSeries = seriesList;
            },
            onFailure: (exception, message) {
              _log('⚠️ [HISTORY] Error loading series for workout ${candidate.id}: $message');
              return; // Skip questo allenamento
            },
          );

          if (candidateSeries != null && candidateSeries!.isNotEmpty) {
            workoutWithSeries = candidate;
            series = candidateSeries;
            _log('✅ [HISTORY] Found workout with ${series!.length} series: ${candidate.id}');
            break; // Trovato un allenamento con serie, fermiamoci qui
          } else {
            _log('📚 [HISTORY] Workout ${candidate.id} has no series, trying next...');
          }

        } catch (e) {
          _log('💥 [HISTORY] Exception loading workout ${candidate.id}: $e');
          continue; // Prova il prossimo
        }
      }

      if (workoutWithSeries == null || series == null || series!.isEmpty) {
        _log('📚 [HISTORY] No workout with completed series found in recent history');
        return;
      }

      _log('🎉 [HISTORY] Successfully found workout ${workoutWithSeries.id} with ${series!.length} series');

      // 🔧 FIX: STEP 4: Raggruppa le serie per exerciseId E per numero di serie
      final Map<int, Map<int, CompletedSeriesData>> historicData = {};

      for (final seriesData in series!) {
        final exerciseId = seriesData.schedaEsercizioId;
        final serieNumber = seriesData.serieNumber ?? 1;

        // 🔧 VERIFICA: Log per debugging del campo scheda_esercizio_id
        _log('🔍 [VERIFY] Serie: id=${seriesData.id}, '
            'schedaEsercizioId=${seriesData.schedaEsercizioId}, '
            'serieNumber=${seriesData.serieNumber}, '
            'peso=${seriesData.peso}, reps=${seriesData.ripetizioni}');

        // Organizza: exerciseId -> serieNumber -> SeriesData
        historicData.putIfAbsent(exerciseId, () => {});
        historicData[exerciseId]![serieNumber] = seriesData;
      }

      // 🔧 FIX: STEP 5: Converte e memorizza nei dati storici
      _historicWorkoutData.clear();

      for (final entry in historicData.entries) {
        final exerciseId = entry.key;
        final seriesByNumber = entry.value;

        _historicWorkoutData[exerciseId] = HistoricExerciseData(
          exerciseId: exerciseId,
          seriesByNumber: seriesByNumber,
          lastWorkoutDate: workoutWithSeries.dataAllenamento,
        );

        _log('✅ [HISTORY] Historic data saved for exercise $exerciseId: '
            '${seriesByNumber.length} series from ${workoutWithSeries.dataAllenamento}');

        // Log dettagliato delle serie per debug
        seriesByNumber.forEach((serieNumber, seriesData) {
          _log('    📊 Serie $serieNumber: ${seriesData.peso}kg x ${seriesData.ripetizioni} reps');
        });
      }

      _log('🏁 [HISTORY] Historic data loading completed. Found data for ${historicData.length} exercises');

      // 🔧 PERFORMANCE FIX: Pre-popola la cache con i dati storici
      _prePopulateCache();

    } catch (e) {
      _log('💥 [HISTORY] Exception in _loadWorkoutHistoryFixed: $e');
      // Non propaghiamo l'errore, lo storico è opzionale
    }
  }

  /// 🔧 PERFORMANCE FIX: Pre-popola la cache con i dati storici
  void _prePopulateCache() {
    _log('⚡ [CACHE] Pre-populating series values cache...');
    int cacheEntries = 0;

    for (final historicData in _historicWorkoutData.values) {
      for (final entry in historicData.seriesByNumber.entries) {
        final serieNumber = entry.key;
        final seriesData = entry.value;

        final cacheKey = _SeriesValuesKey(historicData.exerciseId, serieNumber);
        final cacheValue = ExerciseValues(
          weight: seriesData.peso,
          reps: seriesData.ripetizioni,
          isFromHistory: true,
        );

        _seriesValuesCache[cacheKey] = cacheValue;
        cacheEntries++;
      }
    }

    _log('⚡ [CACHE] Pre-populated $cacheEntries cache entries');
  }

  /// 🔧 PERFORMANCE FIX: Pulisce cache e log
  void _clearCacheAndLogs() {
    _seriesValuesCache.clear();
    _loggedExercises.clear();
    _currentWorkoutId = null; // 🆕 Reset current workout ID
    _log('🧹 [CACHE] Cache cleared and reset');
  }

  /// 🔧 FIX: Ottiene i valori iniziali per un esercizio basandosi sullo storico PERFEZIONATO
  ExerciseValues _getInitialValuesForExercisePerfected(WorkoutExercise exercise, int seriesIndex) {
    final exerciseId = exercise.schedaEsercizioId ?? exercise.id;

    // 🔧 PERFORMANCE FIX: Usa la cache se disponibile
    final cacheKey = _SeriesValuesKey(exerciseId, seriesIndex);
    if (_seriesValuesCache.containsKey(cacheKey)) {
      final cachedValue = _seriesValuesCache[cacheKey]!;
      // Log solo una volta per exercise per evitare spam
      if (!_loggedExercises.contains(exerciseId)) {
        _loggedExercises.add(exerciseId);
        _log('⚡ [CACHE HIT] Exercise ${exercise.nome} (${exerciseId}): '
            '${cachedValue.weight}kg x ${cachedValue.reps} reps (FROM CACHE)');
      }
      return cachedValue;
    }

    _log('💡 [VALUES] === CALCOLO VALORI INIZIALI PERFEZIONATO ===');
    _log('💡 [VALUES] Getting initial values for exercise ${exercise.nome} (${exerciseId}), series ${seriesIndex}');

    // STEP 1: Verifica se abbiamo dati storici per questo esercizio
    if (_historicWorkoutData.containsKey(exerciseId)) {
      final historicData = _historicWorkoutData[exerciseId]!;

      _log('📚 [VALUES] Found historic data: ${historicData.seriesByNumber.length} series from ${historicData.lastWorkoutDate}');

      // 🔧 FIX: LOGICA CORRETTA - Serie N attuale prende valori da Serie N storica
      final targetSeriesData = historicData.getSeriesByNumber(seriesIndex);

      if (targetSeriesData != null) {
        final result = ExerciseValues(
          weight: targetSeriesData.peso,
          reps: targetSeriesData.ripetizioni,
          isFromHistory: true,
        );

        // 🔧 PERFORMANCE FIX: Salva in cache per future chiamate
        _seriesValuesCache[cacheKey] = result;

        _log('✅ [VALUES] Found EXACT historic series $seriesIndex: ${targetSeriesData.peso}kg x ${targetSeriesData.ripetizioni} reps');
        return result;
      }

      // 🔧 FIX: Se non troviamo la serie specifica, usa la serie 1 come fallback
      final fallbackSeriesData = historicData.getSeriesByNumber(1);
      if (fallbackSeriesData != null) {
        final result = ExerciseValues(
          weight: fallbackSeriesData.peso,
          reps: fallbackSeriesData.ripetizioni,
          isFromHistory: true,
        );

        // 🔧 PERFORMANCE FIX: Salva in cache per future chiamate
        _seriesValuesCache[cacheKey] = result;

        _log('✅ [VALUES] Using fallback to series 1: ${fallbackSeriesData.peso}kg x ${fallbackSeriesData.ripetizioni} reps');
        return result;
      }

      // 🔧 FIX: Se non abbiamo nemmeno la serie 1, usa l'ultima serie disponibile
      final allSeries = historicData.allSeries;
      if (allSeries.isNotEmpty) {
        final lastSeries = allSeries.last;
        final result = ExerciseValues(
          weight: lastSeries.peso,
          reps: lastSeries.ripetizioni,
          isFromHistory: true,
        );

        // 🔧 PERFORMANCE FIX: Salva in cache per future chiamate
        _seriesValuesCache[cacheKey] = result;

        _log('✅ [VALUES] Using last available historic series: ${lastSeries.peso}kg x ${lastSeries.ripetizioni} reps');
        return result;
      }
    }

    // STEP 2: Se non abbiamo dati storici, usa i valori di default dell'esercizio
    final result = ExerciseValues(
      weight: exercise.peso,
      reps: exercise.ripetizioni,
      isFromHistory: false,
    );

    // 🔧 PERFORMANCE FIX: Salva in cache per future chiamate
    _seriesValuesCache[cacheKey] = result;

    _log('📝 [VALUES] Using default values: ${exercise.peso}kg x ${exercise.ripetizioni} reps');
    return result;
  }

  /// 🔧 FIX: Metodo pubblico per ottenere valori per una serie specifica CON CACHE
  ExerciseValues getValuesForSeriesNumber(int exerciseId, int seriesNumber) {
    // 🔧 PERFORMANCE FIX: Controlla la cache prima di qualsiasi calcolo
    final cacheKey = _SeriesValuesKey(exerciseId, seriesNumber);
    if (_seriesValuesCache.containsKey(cacheKey)) {
      // 🔧 PERFORMANCE FIX: Log MOLTO ridotto per evitare spam
      // Solo log ogni 10 chiamate per la stessa chiave
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now % 10000 < 1000) {  // Log solo ogni ~10 secondi
        _log('⚡ [CACHE HIT] Exercise $exerciseId, series $seriesNumber (cached)');
      }
      return _seriesValuesCache[cacheKey]!;
    }

    // 🔧 RIDOTTO LOG: Solo se non è in cache (dovrebbe essere raro)
    _log('💡 [VALUES] Getting values for exercise $exerciseId, series $seriesNumber (CACHE MISS)');

    // Cerca prima nei dati storici
    if (_historicWorkoutData.containsKey(exerciseId)) {
      final historicData = _historicWorkoutData[exerciseId]!;
      final seriesData = historicData.getSeriesByNumber(seriesNumber);

      if (seriesData != null) {
        final result = ExerciseValues(
          weight: seriesData.peso,
          reps: seriesData.ripetizioni,
          isFromHistory: true,
        );

        // 🔧 PERFORMANCE FIX: Salva in cache
        _seriesValuesCache[cacheKey] = result;

        _log('✅ [VALUES] Found historic series $seriesNumber: ${seriesData.peso}kg x ${seriesData.ripetizioni} reps');
        return result;
      }

      // Fallback alla serie 1
      final fallbackSeries = historicData.getSeriesByNumber(1);
      if (fallbackSeries != null) {
        final result = ExerciseValues(
          weight: fallbackSeries.peso,
          reps: fallbackSeries.ripetizioni,
          isFromHistory: true,
        );

        // 🔧 PERFORMANCE FIX: Salva in cache
        _seriesValuesCache[cacheKey] = result;

        _log('✅ [VALUES] Fallback to series 1: ${fallbackSeries.peso}kg x ${fallbackSeries.ripetizioni} reps');
        return result;
      }
    }

    // Se lo stato è attivo, cerca nei valori correnti
    if (state is WorkoutSessionActive) {
      final activeState = state as WorkoutSessionActive;
      final currentValues = activeState.exerciseValues[exerciseId];

      if (currentValues != null) {
        // 🔧 PERFORMANCE FIX: Salva in cache
        _seriesValuesCache[cacheKey] = currentValues;

        _log('✅ [VALUES] Using current values: ${currentValues.weight}kg x ${currentValues.reps} reps');
        return currentValues;
      }

      // Cerca l'esercizio nei dati per ottenere i valori di default
      try {
        final exercise = activeState.exercises.firstWhere(
              (ex) => (ex.schedaEsercizioId ?? ex.id) == exerciseId,
        );

        final result = ExerciseValues(
          weight: exercise.peso,
          reps: exercise.ripetizioni,
          isFromHistory: false,
        );

        // 🔧 PERFORMANCE FIX: Salva in cache
        _seriesValuesCache[cacheKey] = result;

        _log('📝 [VALUES] Using exercise default values: ${exercise.peso}kg x ${exercise.ripetizioni} reps');
        return result;
      } catch (e) {
        // Exercise non trovato
      }
    }

    // Fallback finale
    final fallbackResult = const ExerciseValues(weight: 0.0, reps: 0, isFromHistory: false);
    _seriesValuesCache[cacheKey] = fallbackResult;

    _log('⚠️ [VALUES] No values found, using fallback');
    return fallbackResult;
  }

  /// 🆕 NUOVO: Handler per aggiornare i valori di un esercizio
  Future<void> _onUpdateExerciseValues(
      UpdateExerciseValues event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    _log('✏️ [VALUES] Updating exercise values - Exercise: ${event.exerciseId}, Weight: ${event.weight}, Reps: ${event.reps}');

    if (state is WorkoutSessionActive) {
      final activeState = state as WorkoutSessionActive;

      final updatedValues = Map<int, ExerciseValues>.from(activeState.exerciseValues);
      final newValues = ExerciseValues(
        weight: event.weight,
        reps: event.reps,
        isFromHistory: false, // Modificato dall'utente
      );

      updatedValues[event.exerciseId] = newValues;

      // 🔧 PERFORMANCE FIX: Aggiorna anche la cache per tutte le serie
      for (int i = 1; i <= 10; i++) {  // Assume max 10 serie
        final cacheKey = _SeriesValuesKey(event.exerciseId, i);
        _seriesValuesCache[cacheKey] = newValues;
      }

      emit(activeState.copyWith(exerciseValues: updatedValues));
      _log('✅ [VALUES] Exercise values updated successfully');
    }
  }

  /// Handler per caricare gli esercizi della scheda (SEMPLIFICATO - DEPRECATED)
  Future<void> _onLoadWorkoutExercises(
      LoadWorkoutExercises event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    _log('📋 [EVENT] LoadWorkoutExercises received - Scheda: ${event.schedaId}');
    _log('⚠️ [INFO] This method is now deprecated - exercises are loaded directly in StartWorkoutSession');

    // Non fare nulla - gli esercizi vengono caricati direttamente in StartWorkoutSession
    // Questo previene lo stato inconsistente
  }

  /// 🚀 FIX: Handler per caricare le serie completate - NON SOVRASCRIVE LO STATO LOCALE
  Future<void> _onLoadCompletedSeries(
      LoadCompletedSeries event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    _log('📊 [EVENT] LoadCompletedSeries received - Workout: ${event.allenamentoId}');

    // ✅ NON emettere loading se siamo già in WorkoutSessionActive
    if (state is! WorkoutSessionActive) {
      _log('⚠️ [WARNING] LoadCompletedSeries called but not in active session');
      return;
    }

    final activeState = state as WorkoutSessionActive;

    try {
      final result = await _workoutRepository.getCompletedSeries(event.allenamentoId);

      result.fold(
        onSuccess: (completedSeriesList) {
          _log('✅ [API] Successfully loaded ${completedSeriesList.length} completed series from server');

          // Organizza le serie per esercizio
          final Map<int, List<CompletedSeriesData>> seriesByExercise = {};
          for (final series in completedSeriesList) {
            final exerciseId = series.schedaEsercizioId;
            if (!seriesByExercise.containsKey(exerciseId)) {
              seriesByExercise[exerciseId] = [];
            }
            seriesByExercise[exerciseId]!.add(series);
          }

          // 🚀 FIX: MERGE con stato locale invece di sovrascrivere
          final Map<int, List<CompletedSeriesData>> mergedSeries = Map<int, List<CompletedSeriesData>>.from(activeState.completedSeries);

          // Aggiorna solo se ci sono più serie dal server
          for (final entry in seriesByExercise.entries) {
            final exerciseId = entry.key;
            final serverSeries = entry.value;
            final localSeries = mergedSeries[exerciseId] ?? [];

            // Se il server ha più serie di quelle locali, usa quelle del server
            if (serverSeries.length > localSeries.length) {
              mergedSeries[exerciseId] = serverSeries;
              _log('🔄 [MERGE] Updated exercise $exerciseId: ${serverSeries.length} series from server');
            } else {
              _log('✅ [MERGE] Keeping local state for exercise $exerciseId: ${localSeries.length} local vs ${serverSeries.length} server');
            }
          }

          // Emetti solo se ci sono cambiamenti
          if (mergedSeries.toString() != activeState.completedSeries.toString()) {
            emit(activeState.copyWith(completedSeries: mergedSeries));
            _log('🔄 [STATE] Updated completed series state');
          } else {
            _log('✅ [STATE] No changes needed, keeping current state');
          }
        },
        onFailure: (exception, message) {
          _log('⚠️ [WARNING] Error loading completed series: $message (This is normal for new workouts)');
          // Non emettiamo errore per questo, è normale che non ci siano serie all'inizio
        },
      );
    } catch (e) {
      _log('💥 [EXCEPTION] Exception in LoadCompletedSeries: $e');
      // Non emettere errore, mantieni lo stato corrente
    }
  }

  /// 🚀 FIX: Handler per salvare una serie completata - CON GESTIONE OFFLINE
  Future<void> _onSaveCompletedSeries(
      SaveCompletedSeries event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    _log('💾 [BLOC] SaveCompletedSeries received - Workout: ${event.allenamentoId}, Series: ${event.serie.length}');

    try {
      // 🚀 NUOVO: Verifica connessione prima del salvataggio
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      if (!isOnline) {
        _log('📡 [OFFLINE] No internet connection, saving series offline');
        _isOfflineMode = true;
        
        // Salva le serie offline
        for (final series in event.serie) {
          await _offlineService.queueSeriesForSync(series, event.allenamentoId);
        }
        
        // Salva anche lo stato corrente offline
        if (state is WorkoutSessionActive) {
          await _offlineService.saveOfflineWorkout(state as WorkoutSessionActive);
        }
        
        _log('✅ [OFFLINE] Series saved offline successfully');
        return; // Non emettere errori, l'utente può continuare
      }

      // 🚀 NUOVO: Tenta sincronizzazione offline prima del salvataggio
      if (_isOfflineMode) {
        _log('🔄 [OFFLINE] Syncing offline data before new save');
        await _offlineService.syncPendingData();
        _isOfflineMode = false;
      }

      // Salvataggio online normale
      final result = await _workoutRepository.saveCompletedSeries(
        event.allenamentoId,
        event.serie,
        event.requestId,
      );

      result.fold(
        onSuccess: (response) {
          _log('✅ [BLOC] Successfully saved completed series');

          // 🚀 FIX: NON emettere SeriesSaved - rimani in WorkoutSessionActive!
          // Il salvataggio è avvenuto con successo, ma non cambiamo stato
          _log('✅ [BLOC] Series saved but keeping current state');

          // Non emettere nulla - rimaniamo nello stato corrente
        },
        onFailure: (exception, message) {
          _log('❌ [BLOC] Error saving completed series: $message');
          
          // 🚀 NUOVO: Se il salvataggio online fallisce, salva offline
          _log('📡 [OFFLINE] Online save failed, saving offline');
          _isOfflineMode = true;
          
          for (final series in event.serie) {
            _offlineService.queueSeriesForSync(series, event.allenamentoId);
          }
          
          // Non emettere errore, l'utente può continuare
          _log('✅ [OFFLINE] Series queued for offline sync');
        },
      );
    } catch (e) {
      _log('💥 [BLOC] Exception in SaveCompletedSeries: $e');
      
      // 🚀 NUOVO: In caso di eccezione, salva offline
      _log('📡 [OFFLINE] Exception occurred, saving offline');
      _isOfflineMode = true;
      
      for (final series in event.serie) {
        _offlineService.queueSeriesForSync(series, event.allenamentoId);
      }
      
      // Non emettere errore critico, l'utente può continuare
      _log('✅ [OFFLINE] Series queued for offline sync after exception');
    }
  }

  /// Handler per completare l'allenamento - CON GESTIONE OFFLINE
  Future<void> _onCompleteWorkoutSession(
      CompleteWorkoutSession event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    emit(const ActiveWorkoutLoading(message: 'Completamento allenamento...'));

    _log('🏁 [EVENT] Completing workout session: ${event.allenamentoId}');

    try {
      // 🌐 NUOVO: Verifica connessione prima del completamento
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity.isNotEmpty && connectivity.first != ConnectivityResult.none;

      if (!isOnline) {
        _log('📡 [OFFLINE] No internet connection, completing workout offline');
        
        // Salva l'allenamento offline per completamento futuro
        await _offlineService.saveOfflineWorkoutForCompletion(
          event.allenamentoId,
          event.durataTotale,
          event.note,
        );
        
        // Emetti stato di completamento offline
        emit(WorkoutSessionCompletedOffline(
          allenamentoId: event.allenamentoId,
          totalDuration: Duration(minutes: event.durataTotale),
          message: 'Allenamento completato offline. Verrà sincronizzato quando tornerai online.',
        ));
        
        _log('✅ [OFFLINE] Workout marked for offline completion');
        return;
      }

      // Prova completamento online
      final result = await _workoutRepository.completeWorkout(
        event.allenamentoId,
        event.durataTotale,
        note: event.note,
      );

      result.fold(
        onSuccess: (response) {
          _log('✅ [API] Successfully completed workout session');

          emit(WorkoutSessionCompleted(
            response: response,
            totalDuration: Duration(minutes: event.durataTotale),
            message: response.message,
          ));
          
          // 🔧 FIX: Notifica all'AuthBloc che l'allenamento è stato completato
          // Questo rimuove lo stato PendingWorkoutPrompt e evita che il dialogo riappara
          try {
            final authBloc = getIt<AuthBloc>();
            authBloc.add(const WorkoutCompleted());
            _log('✅ [AUTH] Notified AuthBloc that workout is completed');
          } catch (e) {
            _log('❌ [AUTH] Error notifying AuthBloc: $e');
          }
        },
        onFailure: (exception, message) {
          _log('❌ [ERROR] Error completing workout session: $message');
          
          // 🌐 NUOVO: Se fallisce online, salva offline
          if (message?.contains('Connessione internet non disponibile') == true) {
            _log('📡 [OFFLINE] API failed, saving workout for offline completion');
            
            _offlineService.saveOfflineWorkoutForCompletion(
              event.allenamentoId,
              event.durataTotale,
              event.note,
            );
            
            emit(WorkoutSessionCompletedOffline(
              allenamentoId: event.allenamentoId,
              totalDuration: Duration(minutes: event.durataTotale),
              message: 'Allenamento completato offline. Verrà sincronizzato quando tornerai online.',
            ));
            
            // 🔧 FIX: Notifica all'AuthBloc che l'allenamento è stato completato offline
            try {
              final authBloc = getIt<AuthBloc>();
              authBloc.add(const WorkoutCompleted());
              _log('✅ [AUTH] Notified AuthBloc that offline workout is completed');
            } catch (e) {
              _log('❌ [AUTH] Error notifying AuthBloc: $e');
            }
          } else {
            emit(ActiveWorkoutError(
              message: message ?? 'Errore nel completamento dell\'allenamento',
              exception: exception,
            ));
          }
        },
      );
    } catch (e) {
      _log('💥 [EXCEPTION] Exception in CompleteWorkoutSession: $e');
      
      // In caso di eccezione, salva offline
      await _offlineService.saveOfflineWorkoutForCompletion(
        event.allenamentoId,
        event.durataTotale,
        event.note,
      );
      
      emit(WorkoutSessionCompletedOffline(
        allenamentoId: event.allenamentoId,
        totalDuration: Duration(minutes: event.durataTotale),
        message: 'Allenamento completato offline. Verrà sincronizzato quando tornerai online.',
      ));
      
      // 🔧 FIX: Notifica all'AuthBloc che l'allenamento è stato completato offline (exception case)
      try {
        final authBloc = getIt<AuthBloc>();
        authBloc.add(const WorkoutCompleted());
        _log('✅ [AUTH] Notified AuthBloc that offline workout is completed (exception case)');
      } catch (e) {
        _log('❌ [AUTH] Error notifying AuthBloc: $e');
      }
    }
  }

  /// Handler per annullare l'allenamento
  Future<void> _onCancelWorkoutSession(
      CancelWorkoutSession event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    emit(const ActiveWorkoutLoading(message: 'Annullamento allenamento...'));

    _log('🚪 [EVENT] Cancelling workout session: ${event.allenamentoId}');

    final result = await _workoutRepository.deleteWorkout(event.allenamentoId);

    result.fold(
      onSuccess: (success) {
        _log('✅ [API] Successfully cancelled workout session');

        emit(const WorkoutSessionCancelled(
          message: 'Allenamento annullato con successo',
        ));
      },
      onFailure: (exception, message) {
        _log('❌ [ERROR] Error cancelling workout session: $message');
        emit(ActiveWorkoutError(
          message: message ?? 'Errore nell\'annullamento dell\'allenamento',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per aggiornare il timer
  Future<void> _onUpdateWorkoutTimer(
      UpdateWorkoutTimer event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    if (state is WorkoutSessionActive) {
      final activeState = state as WorkoutSessionActive;
      emit(activeState.copyWith(elapsedTime: event.duration));
    }
  }

  /// 🚀 FIX: Handler per aggiungere serie locale - CON LOGGING INTENSIVO
  Future<void> _onAddLocalSeries(
      AddLocalSeries event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    _log('📋 [BLOC] AddLocalSeries - Exercise: ${event.exerciseId}');

    if (state is WorkoutSessionActive) {
      final activeState = state as WorkoutSessionActive;
      _log('✅ [BLOC] Currently in active state with ${activeState.exercises.length} exercises');

      final updatedSeries = Map<int, List<CompletedSeriesData>>.from(activeState.completedSeries);
      _log('📊 [BLOC] Current series map has ${updatedSeries.keys.length} exercises');

      // Converti SeriesData in CompletedSeriesData per l'UI
      final completedSeries = CompletedSeriesData(
        id: event.seriesData.serieId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        schedaEsercizioId: event.seriesData.schedaEsercizioId,
        peso: event.seriesData.peso,
        ripetizioni: event.seriesData.ripetizioni,
        completata: event.seriesData.completata,
        tempoRecupero: event.seriesData.tempoRecupero,
        timestamp: DateTime.now().toIso8601String(),
        note: event.seriesData.note,
        serieNumber: event.seriesData.serieNumber,
      );

      if (!updatedSeries.containsKey(event.exerciseId)) {
        updatedSeries[event.exerciseId] = [];
        _log('🆕 [BLOC] Created new series list for exercise ${event.exerciseId}');
      }

      final previousCount = updatedSeries[event.exerciseId]!.length;
      updatedSeries[event.exerciseId]!.add(completedSeries);
      final newCount = updatedSeries[event.exerciseId]!.length;

      _log('✅ [BLOC] Added local series for exercise ${event.exerciseId}: ${previousCount} -> ${newCount}');
      _log('📊 [BLOC] Total series map now has ${updatedSeries.keys.length} exercises');

      // Emit new state
      final newState = activeState.copyWith(completedSeries: updatedSeries);
      emit(newState);
      _log('🔄 [BLOC] Emitted new WorkoutSessionActive state');
    } else {
      _log('⚠️ [BLOC] AddLocalSeries called but not in active session: ${state.runtimeType}');
    }
  }

  /// Handler per rimuovere serie locale
  Future<void> _onRemoveLocalSeries(
      RemoveLocalSeries event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    if (state is WorkoutSessionActive) {
      final activeState = state as WorkoutSessionActive;
      final updatedSeries = Map<int, List<CompletedSeriesData>>.from(activeState.completedSeries);

      if (updatedSeries.containsKey(event.exerciseId)) {
        updatedSeries[event.exerciseId]!.removeWhere((series) => series.id == event.seriesId);
        if (updatedSeries[event.exerciseId]!.isEmpty) {
          updatedSeries.remove(event.exerciseId);
        }
      }

      emit(activeState.copyWith(completedSeries: updatedSeries));
    }
  }

  /// Handler per reset dello stato
  Future<void> _onResetActiveWorkoutState(
      ResetActiveWorkoutState event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    _log('🔄 [EVENT] Resetting active workout state');

    // Reset dei dati storici e cache
    _historicWorkoutData.clear();
    _clearCacheAndLogs();

    emit(const ActiveWorkoutInitial());
  }

  // ============================================================================
  // 🆕 NUOVO: PUBLIC METHODS PER GESTIRE VALORI ESERCIZI
  // ============================================================================

  /// Ottiene i valori correnti di un esercizio
  ExerciseValues? getExerciseValues(int exerciseId) {
    if (state is WorkoutSessionActive) {
      final activeState = state as WorkoutSessionActive;
      return activeState.exerciseValues[exerciseId];
    }
    return null;
  }

  /// Aggiorna i valori di un esercizio
  void updateExerciseValues(int exerciseId, double weight, int reps) {
    add(UpdateExerciseValues(
      exerciseId: exerciseId,
      weight: weight,
      reps: reps,
    ));
  }

  /// Controlla se un esercizio ha valori dallo storico
  bool hasHistoricValues(int exerciseId) {
    final values = getExerciseValues(exerciseId);
    return values?.isFromHistory ?? false;
  }

  /// Ottiene i dati storici di un esercizio
  HistoricExerciseData? getHistoricData(int exerciseId) {
    return _historicWorkoutData[exerciseId];
  }

  /// 🔧 FIX: Ottiene valori per una serie specifica (pubblico)
  ExerciseValues getValuesForSeries(int exerciseId, int seriesNumber) {
    return getValuesForSeriesNumber(exerciseId, seriesNumber);
  }

  /// 🔧 PERFORMANCE FIX: Ottiene informazioni sulla cache
  Map<String, dynamic> getCacheInfo() {
    return {
      'cache_size': _seriesValuesCache.length,
      'historic_exercises': _historicWorkoutData.length,
      'logged_exercises': _loggedExercises.length,
      'current_workout_id': _currentWorkoutId,
    };
  }

  // ============================================================================
  // PUBLIC METHODS (helper methods per semplificare l'uso)
  // ============================================================================

  /// Inizia una sessione di allenamento
  void startWorkout(int userId, int schedaId) {
    _log('🎯 [PUBLIC] startWorkout called - User: $userId, Scheda: $schedaId');
    add(StartWorkoutSession(userId: userId, schedaId: schedaId));
    _log('📧 [EVENT] StartWorkoutSession event added to queue');
  }

  /// Carica lo storico degli allenamenti
  void loadWorkoutHistory(int userId, int schedaId) {
    add(LoadWorkoutHistory(userId: userId, schedaId: schedaId));
  }

  /// Salva una serie completata
  void saveSeries(int allenamentoId, List<SeriesData> serie, String requestId) {
    add(SaveCompletedSeries(
      allenamentoId: allenamentoId,
      serie: serie,
      requestId: requestId,
    ));
  }

  /// Completa l'allenamento
  void completeWorkout(int allenamentoId, int durataTotale, {String? note}) {
    add(CompleteWorkoutSession(
      allenamentoId: allenamentoId,
      durataTotale: durataTotale,
      note: note,
    ));
  }

  /// Annulla l'allenamento
  void cancelWorkout(int allenamentoId) {
    add(CancelWorkoutSession(allenamentoId: allenamentoId));
  }

  /// Aggiorna il timer dell'allenamento
  void updateTimer(Duration duration) {
    add(UpdateWorkoutTimer(duration: duration));
  }

  /// Aggiunge una serie locale (per feedback immediato UI)
  void addLocalSeries(int exerciseId, SeriesData seriesData) {
    add(AddLocalSeries(exerciseId: exerciseId, seriesData: seriesData));
  }

  /// Rimuove una serie locale
  void removeLocalSeries(int exerciseId, String seriesId) {
    add(RemoveLocalSeries(exerciseId: exerciseId, seriesId: seriesId));
  }

  /// Resetta lo stato del BLoC
  void resetState() {
    add(const ResetActiveWorkoutState());
  }

  // ============================================================================
  // 🚀 NUOVO: OFFLINE METHODS
  // ============================================================================

  /// Ottiene statistiche sui dati offline
  Future<Map<String, dynamic>> getOfflineStats() async {
    try {
      return await _offlineService.getOfflineStats();
    } catch (e) {
      _log('❌ [OFFLINE] Error getting offline stats: $e');
      return {
        'pending_series_count': 0,
        'has_offline_workout': false,
        'last_sync': null,
      };
    }
  }

  /// Ripristina l'allenamento offline se disponibile
  void restoreOfflineWorkout() {
    add(const RestoreOfflineWorkout());
  }

  /// Salva lo stato corrente offline
  void saveOfflineState() {
    add(const SaveOfflineState());
  }

  /// Sincronizza i dati offline
  void syncOfflineData() {
    add(const SyncOfflineData());
  }

  // ============================================================================
  // 🚀 NUOVO: OFFLINE HANDLERS
  // ============================================================================

  /// Handler per sincronizzare dati offline
  Future<void> _onSyncOfflineData(
    SyncOfflineData event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    _log('🔄 [EVENT] SyncOfflineData received');

    try {
      // Verifica se ci sono dati pendenti
      final hasPending = await _offlineService.hasPendingData();
      if (!hasPending) {
        _log('✅ [OFFLINE] No pending data to sync');
        // 🔧 FIX: Non emettere ActiveWorkoutInitial se siamo già in un allenamento attivo
        if (state is! WorkoutSessionActive) {
          emit(const ActiveWorkoutInitial());
        }
        return;
      }

      // Ottieni statistiche per il messaggio
      final stats = await _offlineService.getOfflineStats();
      final pendingCount = stats['pending_series_count'] as int;

      emit(OfflineSyncInProgress(
        message: 'Sincronizzazione in corso...',
        pendingCount: pendingCount,
      ));

      // 🔧 FIX: Aggiungi timeout per evitare blocchi infiniti
      final success = await _offlineService.syncPendingData().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log('⏰ [OFFLINE] Sync timeout after 30 seconds');
          return false;
        },
      );

      if (success) {
        _log('✅ [OFFLINE] Sync completed successfully');
        // 🔧 FIX CRITICO: Dopo la sincronizzazione, NON ripristinare automaticamente l'allenamento offline
        // Questo evita conflitti con la logica degli allenamenti in sospeso
        // L'allenamento offline rimane disponibile per il ripristino manuale o automatico
        _log('✅ [OFFLINE] Sync completed - offline workout remains available for restore');
        
        // 🔧 FIX: Emetti ActiveWorkoutInitial solo se non siamo già in un allenamento attivo
        if (state is! WorkoutSessionActive) {
          emit(const ActiveWorkoutInitial());
        } else {
          _log('✅ [OFFLINE] Keeping current workout session active after sync');
        }
      } else {
        _log('❌ [OFFLINE] Sync failed');
        emit(const ActiveWorkoutError(
          message: 'Sincronizzazione fallita. Riprova più tardi.',
        ));
      }
    } catch (e) {
      _log('💥 [OFFLINE] Exception in sync: $e');
      emit(ActiveWorkoutError(
        message: 'Errore durante la sincronizzazione: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler per ripristinare allenamento offline
  Future<void> _onRestoreOfflineWorkout(
    RestoreOfflineWorkout event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    _log('📱 [EVENT] RestoreOfflineWorkout received');

    try {
      // 🔧 FIX: Verifica se siamo già in un allenamento attivo
      if (state is WorkoutSessionActive) {
        _log('⚠️ [OFFLINE] Already in active workout session, skipping restore');
        return;
      }

      emit(const OfflineRestoreInProgress(message: 'Ripristino allenamento...'));

      final offlineData = await _offlineService.loadOfflineWorkout();
      if (offlineData == null) {
        _log('⚠️ [OFFLINE] No offline workout to restore');
        emit(const ActiveWorkoutInitial());
        return;
      }

      _log('📱 [OFFLINE] Found offline workout: ${offlineData['allenamento_id']}');

                   // Ricostruisci lo stato dell'allenamento
      final allenamentoId = offlineData['allenamento_id'] as int;
      final schedaId = offlineData['scheda_id'] as int;
      final startTime = DateTime.parse(offlineData['start_time']);
      final elapsedTimeMinutes = offlineData['elapsed_time'] as int;

      // Carica esercizi dalla scheda
      final exercisesResult = await _workoutRepository.getWorkoutExercises(schedaId);
      List<WorkoutExercise> exercises = [];
      
      exercisesResult.fold(
        onSuccess: (exercisesList) => exercises = exercisesList,
        onFailure: (exception, message) {
          _log('❌ [OFFLINE] Error loading exercises: $message');
          emit(ActiveWorkoutError(
            message: 'Errore nel caricamento degli esercizi: $message',
            exception: exception,
          ));
          return;
        },
      );

      // Ricostruisci le serie completate
      final completedSeriesData = offlineData['completed_series'] as Map<String, dynamic>;
      final Map<int, List<CompletedSeriesData>> completedSeries = {};
      
      for (final entry in completedSeriesData.entries) {
        final exerciseId = int.parse(entry.key);
        final seriesList = (entry.value as List<dynamic>)
            .map((s) => CompletedSeriesData.fromJson(s as Map<String, dynamic>))
            .toList();
        completedSeries[exerciseId] = seriesList;
      }

      // Crea l'allenamento attivo
      final activeWorkout = ActiveWorkout(
        id: allenamentoId,
        schedaId: schedaId,
        dataAllenamento: startTime.toIso8601String(),
        durataTotale: null,
        userId: 1, // TODO: Get actual userId from session or offline data
      );

                   // Emetti lo stato ripristinato
      emit(WorkoutSessionActive(
        activeWorkout: activeWorkout,
        exercises: exercises,
        completedSeries: completedSeries,
        elapsedTime: Duration(minutes: elapsedTimeMinutes),
        startTime: startTime,
      ));

      _log('✅ [OFFLINE] Workout restored successfully');
    } catch (e) {
      _log('💥 [OFFLINE] Exception in restore: $e');
      emit(ActiveWorkoutError(
        message: 'Errore nel ripristino dell\'allenamento: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// 🌐 NUOVO: Handler per ripristinare un allenamento in sospeso dal database
  Future<void> _onRestorePendingWorkout(
    RestorePendingWorkout event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    //print('[CONSOLE] [active_workout_bloc] 🌐 [EVENT] RestorePendingWorkout received for workout: ${event.pendingWorkout['allenamento_id']}');
    _log('🌐 [EVENT] RestorePendingWorkout received for workout: ${event.pendingWorkout['allenamento_id']}');

    try {
      //print('[CONSOLE] [active_workout_bloc] 🔄 Emitting OfflineRestoreInProgress...');
      emit(const OfflineRestoreInProgress(message: 'Ripristino allenamento in sospeso dal database...'));

      final pendingWorkout = event.pendingWorkout;
      final allenamentoId = pendingWorkout['allenamento_id'] as int;
      final schedaId = pendingWorkout['scheda_id'] as int;
      final dataAllenamento = DateTime.parse(pendingWorkout['data_allenamento']);

      //print('[CONSOLE] [active_workout_bloc] 🌐 [PENDING] Restoring workout: $allenamentoId, scheda: $schedaId');
      _log('🌐 [PENDING] Restoring workout: $allenamentoId, scheda: $schedaId');

      // Carica esercizi dalla scheda
      //print('[CONSOLE] [active_workout_bloc] 📡 Loading exercises for scheda: $schedaId');
      final exercisesResult = await _workoutRepository.getWorkoutExercises(schedaId);
      List<WorkoutExercise> exercises = [];
      
      exercisesResult.fold(
        onSuccess: (exercisesList) {
          exercises = exercisesList;
          //print('[CONSOLE] [active_workout_bloc] ✅ Loaded ${exercises.length} exercises');
        },
        onFailure: (exception, message) {
          print('[CONSOLE] [active_workout_bloc] ❌ Error loading exercises: $message');
          _log('❌ [PENDING] Error loading exercises: $message');
          emit(ActiveWorkoutError(
            message: 'Errore nel caricamento degli esercizi: $message',
            exception: exception,
          ));
          return;
        },
      );

      // Carica le serie completate dal database
      //print('[CONSOLE] [active_workout_bloc] 📡 Loading completed series for workout: $allenamentoId');
      final completedSeriesResult = await _workoutRepository.getCompletedSeries(allenamentoId);
      Map<int, List<CompletedSeriesData>> completedSeries = {};
      
      completedSeriesResult.fold(
        onSuccess: (seriesList) {
          // Converti la lista in una mappa raggruppata per scheda_esercizio_id
          for (final series in seriesList) {
            if (!completedSeries.containsKey(series.schedaEsercizioId)) {
              completedSeries[series.schedaEsercizioId] = [];
            }
            completedSeries[series.schedaEsercizioId]!.add(series);
          }
          //print('[CONSOLE] [active_workout_bloc] ✅ Loaded ${seriesList.length} completed series');
        },
        onFailure: (exception, message) {
          print('[CONSOLE] [active_workout_bloc] ⚠️ Error loading completed series: $message');
          _log('⚠️ [PENDING] Error loading completed series: $message');
          // Non bloccare il ripristino se non riesce a caricare le serie
          completedSeries = {};
        },
      );

      // Crea l'allenamento attivo
      final activeWorkout = ActiveWorkout(
        id: allenamentoId,
        schedaId: schedaId,
        dataAllenamento: dataAllenamento.toIso8601String(),
        durataTotale: null,
        userId: pendingWorkout['user_id'] as int,
      );

      // Calcola il tempo trascorso
      final elapsedTime = DateTime.now().difference(dataAllenamento);

      //print('[CONSOLE] [active_workout_bloc] 🎯 Emitting WorkoutSessionActive...');
      // Emetti lo stato ripristinato
      emit(WorkoutSessionActive(
        activeWorkout: activeWorkout,
        exercises: exercises,
        completedSeries: completedSeries,
        elapsedTime: elapsedTime,
        startTime: dataAllenamento,
      ));

      //print('[CONSOLE] [active_workout_bloc] ✅ [PENDING] Workout restored successfully from database');
      _log('✅ [PENDING] Workout restored successfully from database');
    } catch (e) {
      //print('[CONSOLE] [active_workout_bloc] 💥 Exception in restore: $e');
      _log('💥 [PENDING] Exception in restore: $e');
      emit(ActiveWorkoutError(
        message: 'Errore nel ripristino dell\'allenamento: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler per salvare stato offline
  Future<void> _onSaveOfflineState(
    SaveOfflineState event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    _log('💾 [EVENT] SaveOfflineState received');

    try {
      if (state is WorkoutSessionActive) {
        final activeState = state as WorkoutSessionActive;
        await _offlineService.saveOfflineWorkout(activeState);
        _log('✅ [OFFLINE] State saved offline');
      } else {
        _log('⚠️ [OFFLINE] No active workout to save');
      }
    } catch (e) {
      _log('❌ [OFFLINE] Error saving offline state: $e');
    }
  }

  /// 🌐 NUOVO: Handler per controllare allenamenti in sospeso
  Future<void> _onCheckPendingWorkout(
    CheckPendingWorkout event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    _log('🔍 [EVENT] CheckPendingWorkout received for user: ${event.userId}');

    try {
      final result = await _workoutRepository.checkPendingWorkout(event.userId);

      result.fold(
        onSuccess: (pendingWorkout) {
          if (pendingWorkout != null) {
            _log('✅ [PENDING] Found pending workout: ${pendingWorkout['allenamento_id']}');
            emit(PendingWorkoutFound(
              pendingWorkout: pendingWorkout,
              message: 'Hai un allenamento in sospeso. Vuoi riprenderlo?',
            ));
          } else {
            _log('ℹ️ [PENDING] No pending workouts found');
            emit(const ActiveWorkoutInitial());
          }
        },
        onFailure: (exception, message) {
          _log('❌ [PENDING] Error checking pending workouts: $message');
          emit(ActiveWorkoutError(
            message: 'Errore nel controllo degli allenamenti in sospeso: $message',
            exception: exception,
          ));
        },
      );
    } catch (e) {
      _log('💥 [PENDING] Exception in check pending workout: $e');
      emit(ActiveWorkoutError(
        message: 'Errore nel controllo degli allenamenti in sospeso: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Verifica se siamo in modalità offline
  bool get isOfflineMode => _isOfflineMode;
}