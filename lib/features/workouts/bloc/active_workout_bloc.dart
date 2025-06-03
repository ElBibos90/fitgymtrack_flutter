// lib/features/workouts/bloc/active_workout_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../repository/workout_repository.dart';
import '../models/active_workout_models.dart';
import '../models/workout_plan_models.dart';

// 🛠️ Helper function for logging
void _log(String message, {String name = 'ActiveWorkoutBloc'}) {
  if (kDebugMode) {
    debugPrint('[$name] $message');
  }
}

// ============================================================================
// ACTIVE WORKOUT EVENTS
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

// ============================================================================
// ACTIVE WORKOUT STATES
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

  const WorkoutSessionActive({
    required this.activeWorkout,
    required this.exercises,
    required this.completedSeries,
    required this.elapsedTime,
    required this.startTime,
  });

  @override
  List<Object> get props => [
    activeWorkout,
    exercises,
    completedSeries,
    elapsedTime,
    startTime,
  ];

  /// Copia lo stato aggiornando solo alcuni campi
  WorkoutSessionActive copyWith({
    ActiveWorkout? activeWorkout,
    List<WorkoutExercise>? exercises,
    Map<int, List<CompletedSeriesData>>? completedSeries,
    Duration? elapsedTime,
    DateTime? startTime,
  }) {
    return WorkoutSessionActive(
      activeWorkout: activeWorkout ?? this.activeWorkout,
      exercises: exercises ?? this.exercises,
      completedSeries: completedSeries ?? this.completedSeries,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      startTime: startTime ?? this.startTime,
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

// ============================================================================
// ACTIVE WORKOUT BLOC
// ============================================================================

class ActiveWorkoutBloc extends Bloc<ActiveWorkoutEvent, ActiveWorkoutState> {
  final WorkoutRepository _workoutRepository;

  ActiveWorkoutBloc({required WorkoutRepository workoutRepository})
      : _workoutRepository = workoutRepository,
        super(const ActiveWorkoutInitial()) {

    //_log('🏗️ [INIT] ActiveWorkoutBloc constructor called');

    // Registrazione event handlers
    on<StartWorkoutSession>(_onStartWorkoutSession);
    on<LoadWorkoutExercises>(_onLoadWorkoutExercises);
    on<LoadCompletedSeries>(_onLoadCompletedSeries);
    on<SaveCompletedSeries>(_onSaveCompletedSeries);
    on<CompleteWorkoutSession>(_onCompleteWorkoutSession);
    on<CancelWorkoutSession>(_onCancelWorkoutSession);
    on<ResetActiveWorkoutState>(_onResetActiveWorkoutState);
    on<UpdateWorkoutTimer>(_onUpdateWorkoutTimer);
    on<AddLocalSeries>(_onAddLocalSeries);
    on<RemoveLocalSeries>(_onRemoveLocalSeries);

    //_log('✅ [INIT] ActiveWorkoutBloc event handlers registered');
  }

  /// 🚀 HANDLER SEMPLIFICATO: Gestisce tutto con try/catch invece di Result pattern
  Future<void> _onStartWorkoutSession(
      StartWorkoutSession event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    //_log('🚀 [EVENT] StartWorkoutSession received - User: ${event.userId}, Scheda: ${event.schedaId}');

    emit(const ActiveWorkoutLoading(message: 'Avvio allenamento...'));
    //_log('🔄 [STATE] Emitted ActiveWorkoutLoading');

    try {
      // STEP 1: Avvia allenamento
      //_log('📡 [API] Calling startWorkout repository method...');
      final workoutResult = await _workoutRepository.startWorkout(event.userId, event.schedaId);

      // Controlla se l'emitter è ancora valido
      if (emit.isDone) {
        //_log('⚠️ [WARNING] Emitter is done, stopping execution');
        return;
      }

      // Gestisce il risultato usando fold() ma senza callback async
      StartWorkoutResponse? workoutResponse;
      String? errorMessage;
      Exception? errorException;

      workoutResult.fold(
        onSuccess: (response) {
          workoutResponse = response;
        },
        onFailure: (exception, message) {
          errorException = exception;
          errorMessage = message;
        },
      );

      if (workoutResponse == null) {
        //_log('❌ [ERROR] Error starting workout session: $errorMessage');
        emit(ActiveWorkoutError(
          message: errorMessage ?? 'Errore nell\'avvio dell\'allenamento',
          exception: errorException,
        ));
        return;
      }

      //_log('✅ [API] Workout session started successfully: ${workoutResponse!.allenamentoId}');

      // STEP 2: Carica esercizi
      //_log('📡 [API] Loading exercises for scheda: ${event.schedaId}');
      final exercisesResult = await _workoutRepository.getWorkoutExercises(event.schedaId);

      // Controlla di nuovo se l'emitter è ancora valido
      if (emit.isDone) {
        //_log('⚠️ [WARNING] Emitter is done, stopping execution');
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
        //_log('❌ [ERROR] Error loading exercises: $errorMessage');
        emit(ActiveWorkoutError(
          message: errorMessage ?? 'Errore nel caricamento degli esercizi',
          exception: errorException,
        ));
        return;
      }

      //_log('✅ [API] Successfully loaded ${exercises!.length} exercises');

      // Log dettagli esercizi per debug
      for (final exercise in exercises!) {
        //_log('  📝 Exercise: ${exercise.nome} (ID: ${exercise.id})');
      }

      // STEP 3: Crea stato attivo finale
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
      );

      // Controllo finale prima di emettere
      if (!emit.isDone) {
        emit(activeState);
        //_log('🔄 [STATE] Emitted WorkoutSessionActive directly');
      } else {
        //_log('⚠️ [WARNING] Cannot emit - emitter is done');
      }

    } catch (e) {
      //_log('💥 [EXCEPTION] Exception in _onStartWorkoutSession: $e');

      if (!emit.isDone) {
        emit(ActiveWorkoutError(
          message: 'Errore critico nell\'avvio dell\'allenamento: $e',
          exception: e is Exception ? e : Exception(e.toString()),
        ));
        //_log('🔄 [STATE] Emitted ActiveWorkoutError (exception)');
      }
    }
  }

  /// Handler per caricare gli esercizi della scheda (SEMPLIFICATO - DEPRECATED)
  Future<void> _onLoadWorkoutExercises(
      LoadWorkoutExercises event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    //_log('📋 [EVENT] LoadWorkoutExercises received - Scheda: ${event.schedaId}');
    //_log('⚠️ [INFO] This method is now deprecated - exercises are loaded directly in StartWorkoutSession');

    // Non fare nulla - gli esercizi vengono caricati direttamente in StartWorkoutSession
    // Questo previene lo stato inconsistente
  }

  /// 🚀 FIX: Handler per caricare le serie completate - NON SOVRASCRIVE LO STATO LOCALE
  Future<void> _onLoadCompletedSeries(
      LoadCompletedSeries event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    //_log('📊 [EVENT] LoadCompletedSeries received - Workout: ${event.allenamentoId}');

    // ✅ NON emettere loading se siamo già in WorkoutSessionActive
    if (state is! WorkoutSessionActive) {
      //_log('⚠️ [WARNING] LoadCompletedSeries called but not in active session');
      return;
    }

    final activeState = state as WorkoutSessionActive;

    try {
      final result = await _workoutRepository.getCompletedSeries(event.allenamentoId);

      result.fold(
        onSuccess: (completedSeriesList) {
          //_log('✅ [API] Successfully loaded ${completedSeriesList.length} completed series from server');

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
              //_log('🔄 [MERGE] Updated exercise $exerciseId: ${serverSeries.length} series from server');
            } else {
              //_log('✅ [MERGE] Keeping local state for exercise $exerciseId: ${localSeries.length} local vs ${serverSeries.length} server');
            }
          }

          // Emetti solo se ci sono cambiamenti
          if (mergedSeries.toString() != activeState.completedSeries.toString()) {
            emit(activeState.copyWith(completedSeries: mergedSeries));
            //_log('🔄 [STATE] Updated completed series state');
          } else {
            //_log('✅ [STATE] No changes needed, keeping current state');
          }
        },
        onFailure: (exception, message) {
          //_log('⚠️ [WARNING] Error loading completed series: $message (This is normal for new workouts)');
          // Non emettiamo errore per questo, è normale che non ci siano serie all'inizio
        },
      );
    } catch (e) {
      //_log('💥 [EXCEPTION] Exception in LoadCompletedSeries: $e');
      // Non emettere errore, mantieni lo stato corrente
    }
  }

  /// 🚀 FIX: Handler per salvare una serie completata - NON CAMBIARE STATO
  Future<void> _onSaveCompletedSeries(
      SaveCompletedSeries event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    //_log('💾 [BLOC] SaveCompletedSeries received - Workout: ${event.allenamentoId}, Series: ${event.serie.length}');

    try {
      final result = await _workoutRepository.saveCompletedSeries(
        event.allenamentoId,
        event.serie,
        event.requestId,
      );

      result.fold(
        onSuccess: (response) {
          //_log('✅ [BLOC] Successfully saved completed series');

          // 🚀 FIX: NON emettere SeriesSaved - rimani in WorkoutSessionActive!
          // Il salvataggio è avvenuto con successo, ma non cambiamo stato
          //_log('✅ [BLOC] Series saved but keeping current state');

          // Non emettere nulla - rimaniamo nello stato corrente
        },
        onFailure: (exception, message) {
          //_log('❌ [BLOC] Error saving completed series: $message');
          emit(ActiveWorkoutError(
            message: message ?? 'Errore nel salvataggio della serie',
            exception: exception,
          ));
        },
      );
    } catch (e) {
      //_log('💥 [BLOC] Exception in SaveCompletedSeries: $e');
      emit(ActiveWorkoutError(
        message: 'Errore critico nel salvataggio: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler per completare l'allenamento
  Future<void> _onCompleteWorkoutSession(
      CompleteWorkoutSession event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    emit(const ActiveWorkoutLoading(message: 'Completamento allenamento...'));

    //_log('🏁 [EVENT] Completing workout session: ${event.allenamentoId}');

    final result = await _workoutRepository.completeWorkout(
      event.allenamentoId,
      event.durataTotale,
      note: event.note,
    );

    result.fold(
      onSuccess: (response) {
        //_log('✅ [API] Successfully completed workout session');

        emit(WorkoutSessionCompleted(
          response: response,
          totalDuration: Duration(minutes: event.durataTotale),
          message: response.message,
        ));
      },
      onFailure: (exception, message) {
        //_log('❌ [ERROR] Error completing workout session: $message');
        emit(ActiveWorkoutError(
          message: message ?? 'Errore nel completamento dell\'allenamento',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per annullare l'allenamento
  Future<void> _onCancelWorkoutSession(
      CancelWorkoutSession event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    emit(const ActiveWorkoutLoading(message: 'Annullamento allenamento...'));

    //_log('🚪 [EVENT] Cancelling workout session: ${event.allenamentoId}');

    final result = await _workoutRepository.deleteWorkout(event.allenamentoId);

    result.fold(
      onSuccess: (success) {
        //_log('✅ [API] Successfully cancelled workout session');

        emit(const WorkoutSessionCancelled(
          message: 'Allenamento annullato con successo',
        ));
      },
      onFailure: (exception, message) {
        //_log('❌ [ERROR] Error cancelling workout session: $message');
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
    //_log('📋 [BLOC] AddLocalSeries - Exercise: ${event.exerciseId}');

    if (state is WorkoutSessionActive) {
      final activeState = state as WorkoutSessionActive;
      //_log('✅ [BLOC] Currently in active state with ${activeState.exercises.length} exercises');

      final updatedSeries = Map<int, List<CompletedSeriesData>>.from(activeState.completedSeries);
      //_log('📊 [BLOC] Current series map has ${updatedSeries.keys.length} exercises');

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
        //_log('🆕 [BLOC] Created new series list for exercise ${event.exerciseId}');
      }

      final previousCount = updatedSeries[event.exerciseId]!.length;
      updatedSeries[event.exerciseId]!.add(completedSeries);
      final newCount = updatedSeries[event.exerciseId]!.length;

      //_log('✅ [BLOC] Added local series for exercise ${event.exerciseId}: ${previousCount} -> ${newCount}');
      //_log('📊 [BLOC] Total series map now has ${updatedSeries.keys.length} exercises');

      // Emit new state
      final newState = activeState.copyWith(completedSeries: updatedSeries);
      emit(newState);
      //_log('🔄 [BLOC] Emitted new WorkoutSessionActive state');
    } else {
      //_log('⚠️ [BLOC] AddLocalSeries called but not in active session: ${state.runtimeType}');
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
    //_log('🔄 [EVENT] Resetting active workout state');
    emit(const ActiveWorkoutInitial());
  }

  // ============================================================================
  // PUBLIC METHODS (helper methods per semplificare l'uso)
  // ============================================================================

  /// Inizia una sessione di allenamento
  void startWorkout(int userId, int schedaId) {
    //_log('🎯 [PUBLIC] startWorkout called - User: $userId, Scheda: $schedaId');
    add(StartWorkoutSession(userId: userId, schedaId: schedaId));
    //_log('📧 [EVENT] StartWorkoutSession event added to queue');
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
}