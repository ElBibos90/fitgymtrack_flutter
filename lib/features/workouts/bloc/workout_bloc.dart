// lib/features/workouts/bloc/workout_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;

import '../repository/workout_repository.dart';
import '../models/workout_plan_models.dart';
import '../models/workout_response_types.dart';
import '../../exercises/models/exercises_response.dart';

// ============================================================================
// WORKOUT EVENTS
// ============================================================================

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

/// Evento per caricare tutte le schede dell'utente
class GetWorkoutPlans extends WorkoutEvent {
  final int userId;

  const GetWorkoutPlans({required this.userId});

  @override
  List<Object> get props => [userId];
}

/// Evento per caricare gli esercizi di una scheda specifica
class GetWorkoutExercises extends WorkoutEvent {
  final int schedaId;

  const GetWorkoutExercises({required this.schedaId});

  @override
  List<Object> get props => [schedaId];
}

/// Evento per caricare gli esercizi disponibili per creare/modificare schede
class GetAvailableExercises extends WorkoutEvent {
  final int userId;

  const GetAvailableExercises({required this.userId});

  @override
  List<Object> get props => [userId];
}

/// Evento per creare una nuova scheda
class CreateWorkoutPlan extends WorkoutEvent {
  final CreateWorkoutPlanRequest request;

  const CreateWorkoutPlan({required this.request});

  @override
  List<Object> get props => [request];
}

/// Evento per aggiornare una scheda esistente
class UpdateWorkoutPlan extends WorkoutEvent {
  final UpdateWorkoutPlanRequest request;

  const UpdateWorkoutPlan({required this.request});

  @override
  List<Object> get props => [request];
}

/// Evento per eliminare una scheda
class DeleteWorkoutPlan extends WorkoutEvent {
  final int schedaId;

  const DeleteWorkoutPlan({required this.schedaId});

  @override
  List<Object> get props => [schedaId];
}

/// Evento per resettare lo stato
class ResetWorkoutState extends WorkoutEvent {
  const ResetWorkoutState();
}

/// Evento per caricare i dettagli di una scheda specifica (esercizi inclusi)
class GetWorkoutPlanDetails extends WorkoutEvent {
  final int schedaId;

  const GetWorkoutPlanDetails({required this.schedaId});

  @override
  List<Object> get props => [schedaId];
}

// ============================================================================
// WORKOUT STATES
// ============================================================================

abstract class WorkoutState extends Equatable {
  const WorkoutState();

  @override
  List<Object?> get props => [];
}

/// Stato iniziale
class WorkoutInitial extends WorkoutState {
  const WorkoutInitial();
}

/// Stato di caricamento
class WorkoutLoading extends WorkoutState {
  const WorkoutLoading();
}

/// Stato di caricamento con messaggio personalizzato
class WorkoutLoadingWithMessage extends WorkoutState {
  final String message;

  const WorkoutLoadingWithMessage({required this.message});

  @override
  List<Object> get props => [message];
}

/// Stato di successo con lista schede caricate
class WorkoutPlansLoaded extends WorkoutState {
  final List<WorkoutPlan> workoutPlans;
  final int userId;

  const WorkoutPlansLoaded({
    required this.workoutPlans,
    required this.userId,
  });

  @override
  List<Object> get props => [workoutPlans, userId];
}

/// Stato di successo con esercizi di una scheda caricati
class WorkoutExercisesLoaded extends WorkoutState {
  final List<WorkoutExercise> exercises;
  final int schedaId;

  const WorkoutExercisesLoaded({
    required this.exercises,
    required this.schedaId,
  });

  @override
  List<Object> get props => [exercises, schedaId];
}

/// Stato di successo con esercizi disponibili caricati
class AvailableExercisesLoaded extends WorkoutState {
  final List<ExerciseItem> availableExercises;
  final int userId;

  const AvailableExercisesLoaded({
    required this.availableExercises,
    required this.userId,
  });

  @override
  List<Object> get props => [availableExercises, userId];
}

/// Stato di successo dopo creazione scheda
class WorkoutPlanCreated extends WorkoutState {
  final CreateWorkoutPlanResponse response;
  final String message;

  const WorkoutPlanCreated({
    required this.response,
    required this.message,
  });

  @override
  List<Object> get props => [response, message];
}

/// Stato di successo dopo aggiornamento scheda
class WorkoutPlanUpdated extends WorkoutState {
  final UpdateWorkoutPlanResponse response;
  final String message;

  const WorkoutPlanUpdated({
    required this.response,
    required this.message,
  });

  @override
  List<Object> get props => [response, message];
}

/// Stato di successo dopo eliminazione scheda
class WorkoutPlanDeleted extends WorkoutState {
  final DeleteWorkoutPlanResponse response;
  final String message;

  const WorkoutPlanDeleted({
    required this.response,
    required this.message,
  });

  @override
  List<Object> get props => [response, message];
}

/// Stato di successo con dettagli completi di una scheda
class WorkoutPlanDetailsLoaded extends WorkoutState {
  final WorkoutPlan workoutPlan;
  final List<WorkoutExercise> exercises;

  const WorkoutPlanDetailsLoaded({
    required this.workoutPlan,
    required this.exercises,
  });

  @override
  List<Object> get props => [workoutPlan, exercises];
}

/// Stato di errore
class WorkoutError extends WorkoutState {
  final String message;
  final Exception? exception;

  const WorkoutError({
    required this.message,
    this.exception,
  });

  @override
  List<Object?> get props => [message, exception];
}

// ============================================================================
// WORKOUT BLOC
// ============================================================================

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutRepository _workoutRepository;

  WorkoutBloc({required WorkoutRepository workoutRepository})
      : _workoutRepository = workoutRepository,
        super(const WorkoutInitial()) {

    // Registrazione event handlers
    on<GetWorkoutPlans>(_onGetWorkoutPlans);
    on<GetWorkoutExercises>(_onGetWorkoutExercises);
    on<GetAvailableExercises>(_onGetAvailableExercises);
    on<CreateWorkoutPlan>(_onCreateWorkoutPlan);
    on<UpdateWorkoutPlan>(_onUpdateWorkoutPlan);
    on<DeleteWorkoutPlan>(_onDeleteWorkoutPlan);
    on<ResetWorkoutState>(_onResetWorkoutState);
    on<GetWorkoutPlanDetails>(_onGetWorkoutPlanDetails);
  }

  /// Handler per caricamento schede allenamento
  Future<void> _onGetWorkoutPlans(
      GetWorkoutPlans event,
      Emitter<WorkoutState> emit,
      ) async {
    emit(const WorkoutLoading());

    developer.log('Loading workout plans for user: ${event.userId}', name: 'WorkoutBloc');

    final result = await _workoutRepository.getWorkoutPlans(event.userId);

    result.fold(
      onSuccess: (workoutPlans) {
        developer.log('Successfully loaded ${workoutPlans.length} workout plans', name: 'WorkoutBloc');
        emit(WorkoutPlansLoaded(
          workoutPlans: workoutPlans,
          userId: event.userId,
        ));
      },
      onFailure: (exception, message) {
        developer.log('Error loading workout plans: $message', name: 'WorkoutBloc', error: exception);
        emit(WorkoutError(
          message: message ?? 'Errore nel caricamento delle schede di allenamento',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per caricamento esercizi di una scheda
  Future<void> _onGetWorkoutExercises(
      GetWorkoutExercises event,
      Emitter<WorkoutState> emit,
      ) async {
    emit(const WorkoutLoadingWithMessage(message: 'Caricamento esercizi...'));

    developer.log('Loading exercises for workout: ${event.schedaId}', name: 'WorkoutBloc');

    final result = await _workoutRepository.getWorkoutExercises(event.schedaId);

    result.fold(
      onSuccess: (exercises) {
        developer.log('Successfully loaded ${exercises.length} exercises', name: 'WorkoutBloc');
        emit(WorkoutExercisesLoaded(
          exercises: exercises,
          schedaId: event.schedaId,
        ));
      },
      onFailure: (exception, message) {
        developer.log('Error loading exercises: $message', name: 'WorkoutBloc', error: exception);
        emit(WorkoutError(
          message: message ?? 'Errore nel caricamento degli esercizi',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per caricamento esercizi disponibili
  Future<void> _onGetAvailableExercises(
      GetAvailableExercises event,
      Emitter<WorkoutState> emit,
      ) async {
    emit(const WorkoutLoadingWithMessage(message: 'Caricamento esercizi disponibili...'));

    developer.log('Loading available exercises for user: ${event.userId}', name: 'WorkoutBloc');

    final result = await _workoutRepository.getAvailableExercises(event.userId);

    result.fold(
      onSuccess: (exercises) {
        developer.log('Successfully loaded ${exercises.length} available exercises', name: 'WorkoutBloc');
        emit(AvailableExercisesLoaded(
          availableExercises: exercises,
          userId: event.userId,
        ));
      },
      onFailure: (exception, message) {
        developer.log('Error loading available exercises: $message', name: 'WorkoutBloc', error: exception);
        emit(WorkoutError(
          message: message ?? 'Errore nel caricamento degli esercizi disponibili',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per creazione scheda
  Future<void> _onCreateWorkoutPlan(
      CreateWorkoutPlan event,
      Emitter<WorkoutState> emit,
      ) async {
    emit(const WorkoutLoadingWithMessage(message: 'Creazione scheda in corso...'));

    developer.log('Creating workout plan: ${event.request.nome}', name: 'WorkoutBloc');

    final result = await _workoutRepository.createWorkoutPlan(event.request);

    result.fold(
      onSuccess: (response) {
        developer.log('Successfully created workout plan', name: 'WorkoutBloc');
        emit(WorkoutPlanCreated(
          response: response,
          message: response.message,
        ));
      },
      onFailure: (exception, message) {
        developer.log('Error creating workout plan: $message', name: 'WorkoutBloc', error: exception);
        emit(WorkoutError(
          message: message ?? 'Errore nella creazione della scheda',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per aggiornamento scheda
  Future<void> _onUpdateWorkoutPlan(
      UpdateWorkoutPlan event,
      Emitter<WorkoutState> emit,
      ) async {
    emit(const WorkoutLoadingWithMessage(message: 'Aggiornamento scheda in corso...'));

    developer.log('Updating workout plan: ${event.request.schedaId}', name: 'WorkoutBloc');

    final result = await _workoutRepository.updateWorkoutPlan(event.request);

    result.fold(
      onSuccess: (response) {
        developer.log('Successfully updated workout plan', name: 'WorkoutBloc');
        emit(WorkoutPlanUpdated(
          response: response,
          message: response.message,
        ));
      },
      onFailure: (exception, message) {
        developer.log('Error updating workout plan: $message', name: 'WorkoutBloc', error: exception);
        emit(WorkoutError(
          message: message ?? 'Errore nell\'aggiornamento della scheda',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per eliminazione scheda
  Future<void> _onDeleteWorkoutPlan(
      DeleteWorkoutPlan event,
      Emitter<WorkoutState> emit,
      ) async {
    emit(const WorkoutLoadingWithMessage(message: 'Eliminazione scheda in corso...'));

    developer.log('Deleting workout plan: ${event.schedaId}', name: 'WorkoutBloc');

    final result = await _workoutRepository.deleteWorkoutPlan(event.schedaId);

    result.fold(
      onSuccess: (response) {
        developer.log('Successfully deleted workout plan', name: 'WorkoutBloc');
        emit(WorkoutPlanDeleted(
          response: response,
          message: response.message,
        ));
      },
      onFailure: (exception, message) {
        developer.log('Error deleting workout plan: $message', name: 'WorkoutBloc', error: exception);
        emit(WorkoutError(
          message: message ?? 'Errore nell\'eliminazione della scheda',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per caricamento dettagli completi di una scheda
  Future<void> _onGetWorkoutPlanDetails(
      GetWorkoutPlanDetails event,
      Emitter<WorkoutState> emit,
      ) async {
    emit(const WorkoutLoadingWithMessage(message: 'Caricamento dettagli scheda...'));

    developer.log('Loading workout plan details: ${event.schedaId}', name: 'WorkoutBloc');

    // Per ora implementazione semplificata - carica solo esercizi
    // In futuro potremmo avere un endpoint specifico per i dettagli completi
    final result = await _workoutRepository.getWorkoutExercises(event.schedaId);

    result.fold(
      onSuccess: (exercises) {
        developer.log('Successfully loaded workout plan details', name: 'WorkoutBloc');

        // Crea un WorkoutPlan placeholder per ora
        // In una implementazione reale, dovremmo avere i dati della scheda
        final workoutPlan = WorkoutPlan(
          id: event.schedaId,
          nome: 'Dettagli Scheda',
          descrizione: null,
          dataCreazione: null,
          esercizi: exercises,
        );

        emit(WorkoutPlanDetailsLoaded(
          workoutPlan: workoutPlan,
          exercises: exercises,
        ));
      },
      onFailure: (exception, message) {
        developer.log('Error loading workout plan details: $message', name: 'WorkoutBloc', error: exception);
        emit(WorkoutError(
          message: message ?? 'Errore nel caricamento dei dettagli della scheda',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per reset dello stato
  Future<void> _onResetWorkoutState(
      ResetWorkoutState event,
      Emitter<WorkoutState> emit,
      ) async {
    developer.log('Resetting workout state', name: 'WorkoutBloc');
    emit(const WorkoutInitial());
  }

  // ============================================================================
  // PUBLIC METHODS (helper methods per semplificare l'uso)
  // ============================================================================

  /// Carica le schede di allenamento per un utente
  void loadWorkoutPlans(int userId) {
    add(GetWorkoutPlans(userId: userId));
  }

  /// Carica gli esercizi di una scheda
  void loadWorkoutExercises(int schedaId) {
    add(GetWorkoutExercises(schedaId: schedaId));
  }

  /// Carica gli esercizi disponibili
  void loadAvailableExercises(int userId) {
    add(GetAvailableExercises(userId: userId));
  }

  /// Crea una nuova scheda
  void createWorkout(CreateWorkoutPlanRequest request) {
    add(CreateWorkoutPlan(request: request));
  }

  /// Aggiorna una scheda esistente
  void updateWorkout(UpdateWorkoutPlanRequest request) {
    add(UpdateWorkoutPlan(request: request));
  }

  /// Elimina una scheda
  void deleteWorkout(int schedaId) {
    add(DeleteWorkoutPlan(schedaId: schedaId));
  }

  /// Carica i dettagli completi di una scheda
  void loadWorkoutPlanDetails(int schedaId) {
    add(GetWorkoutPlanDetails(schedaId: schedaId));
  }

  /// Resetta lo stato del BLoC
  void resetState() {
    add(const ResetWorkoutState());
  }
}