// lib/features/workouts/bloc/active_workout_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;

import '../repository/workout_repository.dart';
import '../models/active_workout_models.dart';
import '../models/workout_plan_models.dart';

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
  }

  /// Handler per iniziare una sessione di allenamento
  Future<void> _onStartWorkoutSession(
      StartWorkoutSession event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    emit(const ActiveWorkoutLoading(message: 'Avvio allenamento...'));

    developer.log('🚀 Starting workout session - User: ${event.userId}, Scheda: ${event.schedaId}',
        name: 'ActiveWorkoutBloc');

    try {
      final result = await _workoutRepository.startWorkout(event.userId, event.schedaId);

      result.fold(
        onSuccess: (response) {
          developer.log('✅ Workout session started successfully: ${response.allenamentoId}',
              name: 'ActiveWorkoutBloc');
          final startTime = DateTime.now();

          emit(WorkoutSessionStarted(
            response: response,
            userId: event.userId,
            schedaId: event.schedaId,
            startTime: startTime,
          ));

          // Carica automaticamente gli esercizi della scheda
          developer.log('🔄 Loading exercises for scheda: ${event.schedaId}',
              name: 'ActiveWorkoutBloc');
          add(LoadWorkoutExercises(schedaId: event.schedaId));
        },
        onFailure: (exception, message) {
          developer.log('❌ Error starting workout session: $message',
              name: 'ActiveWorkoutBloc', error: exception);
          emit(ActiveWorkoutError(
            message: message ?? 'Errore nell\'avvio dell\'allenamento',
            exception: exception,
          ));
        },
      );
    } catch (e) {
      developer.log('💥 Exception in _onStartWorkoutSession: $e',
          name: 'ActiveWorkoutBloc', error: e);
      emit(ActiveWorkoutError(
        message: 'Errore critico nell\'avvio dell\'allenamento: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler per caricare gli esercizi della scheda
  Future<void> _onLoadWorkoutExercises(
      LoadWorkoutExercises event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    // Mantieni lo stato corrente se siamo già in workout attivo
    if (state is WorkoutSessionActive) {
      developer.log('⚠️ Exercises already loaded, skipping...', name: 'ActiveWorkoutBloc');
      return; // Gli esercizi sono già caricati
    }

    emit(const ActiveWorkoutLoading(message: 'Caricamento esercizi...'));

    developer.log('📋 Loading exercises for workout: ${event.schedaId}', name: 'ActiveWorkoutBloc');

    try {
      final result = await _workoutRepository.getWorkoutExercises(event.schedaId);

      result.fold(
        onSuccess: (exercises) {
          developer.log('✅ Successfully loaded ${exercises.length} exercises',
              name: 'ActiveWorkoutBloc');

          // Log dettagli esercizi per debug
          for (final exercise in exercises) {
            developer.log('  - Exercise: ${exercise.nome} (ID: ${exercise.id})',
                name: 'ActiveWorkoutBloc');
          }

          // Se abbiamo una sessione avviata, crea lo stato attivo completo
          if (state is WorkoutSessionStarted) {
            final startedState = state as WorkoutSessionStarted;

            final activeWorkout = ActiveWorkout(
              id: startedState.response.allenamentoId,
              schedaId: startedState.schedaId,
              dataAllenamento: startedState.startTime.toIso8601String(),
              userId: startedState.userId,
              esercizi: exercises,
            );

            developer.log('🎯 Creating WorkoutSessionActive state', name: 'ActiveWorkoutBloc');

            emit(WorkoutSessionActive(
              activeWorkout: activeWorkout,
              exercises: exercises,
              completedSeries: {},
              elapsedTime: Duration.zero,
              startTime: startedState.startTime,
            ));

            // Carica le serie completate se esistono
            developer.log('🔄 Loading completed series...', name: 'ActiveWorkoutBloc');
            add(LoadCompletedSeries(allenamentoId: startedState.response.allenamentoId));
          } else {
            developer.log('⚠️ State is not WorkoutSessionStarted: $state',
                name: 'ActiveWorkoutBloc');
            emit(ActiveWorkoutError(
              message: 'Stato inconsistente: sessione non avviata',
            ));
          }
        },
        onFailure: (exception, message) {
          developer.log('❌ Error loading exercises: $message',
              name: 'ActiveWorkoutBloc', error: exception);
          emit(ActiveWorkoutError(
            message: message ?? 'Errore nel caricamento degli esercizi',
            exception: exception,
          ));
        },
      );
    } catch (e) {
      developer.log('💥 Exception in _onLoadWorkoutExercises: $e',
          name: 'ActiveWorkoutBloc', error: e);
      emit(ActiveWorkoutError(
        message: 'Errore critico nel caricamento esercizi: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler per caricare le serie completate
  Future<void> _onLoadCompletedSeries(
      LoadCompletedSeries event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    developer.log('Loading completed series for workout: ${event.allenamentoId}',
        name: 'ActiveWorkoutBloc');

    final result = await _workoutRepository.getCompletedSeries(event.allenamentoId);

    result.fold(
      onSuccess: (completedSeriesList) {
        developer.log('Successfully loaded ${completedSeriesList.length} completed series',
            name: 'ActiveWorkoutBloc');

        // Organizza le serie per esercizio
        final Map<int, List<CompletedSeriesData>> seriesByExercise = {};
        for (final series in completedSeriesList) {
          final exerciseId = series.schedaEsercizioId;
          if (!seriesByExercise.containsKey(exerciseId)) {
            seriesByExercise[exerciseId] = [];
          }
          seriesByExercise[exerciseId]!.add(series);
        }

        // Aggiorna lo stato se siamo in workout attivo
        if (state is WorkoutSessionActive) {
          final activeState = state as WorkoutSessionActive;
          emit(activeState.copyWith(completedSeries: seriesByExercise));
        }
      },
      onFailure: (exception, message) {
        developer.log('Error loading completed series: $message',
            name: 'ActiveWorkoutBloc', error: exception);
        // Non emettiamo errore per questo, è normale che non ci siano serie all'inizio
      },
    );
  }

  /// Handler per salvare una serie completata
  Future<void> _onSaveCompletedSeries(
      SaveCompletedSeries event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    developer.log('Saving completed series for workout: ${event.allenamentoId}',
        name: 'ActiveWorkoutBloc');

    final result = await _workoutRepository.saveCompletedSeries(
      event.allenamentoId,
      event.serie,
      event.requestId,
    );

    result.fold(
      onSuccess: (response) {
        developer.log('Successfully saved completed series', name: 'ActiveWorkoutBloc');

        emit(SeriesSaved(
          response: response,
          message: response.message,
        ));

        // Ricarica le serie completate per aggiornare lo stato
        add(LoadCompletedSeries(allenamentoId: event.allenamentoId));
      },
      onFailure: (exception, message) {
        developer.log('Error saving completed series: $message',
            name: 'ActiveWorkoutBloc', error: exception);
        emit(ActiveWorkoutError(
          message: message ?? 'Errore nel salvataggio della serie',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per completare l'allenamento
  Future<void> _onCompleteWorkoutSession(
      CompleteWorkoutSession event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    emit(const ActiveWorkoutLoading(message: 'Completamento allenamento...'));

    developer.log('Completing workout session: ${event.allenamentoId}', name: 'ActiveWorkoutBloc');

    final result = await _workoutRepository.completeWorkout(
      event.allenamentoId,
      event.durataTotale,
      note: event.note,
    );

    result.fold(
      onSuccess: (response) {
        developer.log('Successfully completed workout session', name: 'ActiveWorkoutBloc');

        emit(WorkoutSessionCompleted(
          response: response,
          totalDuration: Duration(minutes: event.durataTotale),
          message: response.message,
        ));
      },
      onFailure: (exception, message) {
        developer.log('Error completing workout session: $message',
            name: 'ActiveWorkoutBloc', error: exception);
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

    developer.log('Cancelling workout session: ${event.allenamentoId}', name: 'ActiveWorkoutBloc');

    final result = await _workoutRepository.deleteWorkout(event.allenamentoId);

    result.fold(
      onSuccess: (success) {
        developer.log('Successfully cancelled workout session', name: 'ActiveWorkoutBloc');

        emit(const WorkoutSessionCancelled(
          message: 'Allenamento annullato con successo',
        ));
      },
      onFailure: (exception, message) {
        developer.log('Error cancelling workout session: $message',
            name: 'ActiveWorkoutBloc', error: exception);
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

  /// Handler per aggiungere serie locale
  Future<void> _onAddLocalSeries(
      AddLocalSeries event,
      Emitter<ActiveWorkoutState> emit,
      ) async {
    if (state is WorkoutSessionActive) {
      final activeState = state as WorkoutSessionActive;
      final updatedSeries = Map<int, List<CompletedSeriesData>>.from(activeState.completedSeries);

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
      }
      updatedSeries[event.exerciseId]!.add(completedSeries);

      emit(activeState.copyWith(completedSeries: updatedSeries));
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
    developer.log('Resetting active workout state', name: 'ActiveWorkoutBloc');
    emit(const ActiveWorkoutInitial());
  }

  // ============================================================================
  // PUBLIC METHODS (helper methods per semplificare l'uso)
  // ============================================================================

  /// Inizia una sessione di allenamento
  void startWorkout(int userId, int schedaId) {
    add(StartWorkoutSession(userId: userId, schedaId: schedaId));
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