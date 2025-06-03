// lib/features/workouts/bloc/workout_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;

import '../repository/workout_repository.dart';
import '../models/workout_plan_models.dart';
import '../models/workout_response_types.dart';
import '../../exercises/models/exercises_response.dart';

// ============================================================================
// WORKOUT EVENTS (aggiunta di nuovi eventi)
// ============================================================================

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

// Eventi esistenti...
class GetWorkoutPlans extends WorkoutEvent {
  final int userId;

  const GetWorkoutPlans({required this.userId});

  @override
  List<Object> get props => [userId];
}

class GetWorkoutExercises extends WorkoutEvent {
  final int schedaId;

  const GetWorkoutExercises({required this.schedaId});

  @override
  List<Object> get props => [schedaId];
}

class GetAvailableExercises extends WorkoutEvent {
  final int userId;

  const GetAvailableExercises({required this.userId});

  @override
  List<Object> get props => [userId];
}

class CreateWorkoutPlan extends WorkoutEvent {
  final CreateWorkoutPlanRequest request;

  const CreateWorkoutPlan({required this.request});

  @override
  List<Object> get props => [request];
}

class UpdateWorkoutPlan extends WorkoutEvent {
  final UpdateWorkoutPlanRequest request;

  const UpdateWorkoutPlan({required this.request});

  @override
  List<Object> get props => [request];
}

class DeleteWorkoutPlan extends WorkoutEvent {
  final int schedaId;

  const DeleteWorkoutPlan({required this.schedaId});

  @override
  List<Object> get props => [schedaId];
}

class ResetWorkoutState extends WorkoutEvent {
  const ResetWorkoutState();
}

class GetWorkoutPlanDetails extends WorkoutEvent {
  final int schedaId;

  const GetWorkoutPlanDetails({required this.schedaId});

  @override
  List<Object> get props => [schedaId];
}

class LoadWorkoutPlanWithData extends WorkoutEvent {
  final WorkoutPlan workoutPlan;
  final int schedaId;

  const LoadWorkoutPlanWithData({
    required this.workoutPlan,
    required this.schedaId,
  });

  @override
  List<Object> get props => [workoutPlan, schedaId];
}

// ✅ NUOVO EVENTO per refresh automatico
class RefreshWorkoutPlansAfterOperation extends WorkoutEvent {
  final int userId;
  final String operation; // "create", "update", "delete"

  const RefreshWorkoutPlansAfterOperation({
    required this.userId,
    required this.operation,
  });

  @override
  List<Object> get props => [userId, operation];
}

// ============================================================================
// WORKOUT STATES (mantenute le esistenti)
// ============================================================================

abstract class WorkoutState extends Equatable {
  const WorkoutState();

  @override
  List<Object?> get props => [];
}

class WorkoutInitial extends WorkoutState {
  const WorkoutInitial();
}

class WorkoutLoading extends WorkoutState {
  const WorkoutLoading();
}

class WorkoutLoadingWithMessage extends WorkoutState {
  final String message;

  const WorkoutLoadingWithMessage({required this.message});

  @override
  List<Object> get props => [message];
}

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
// WORKOUT BLOC (con fix del refresh automatico)
// ============================================================================

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutRepository _workoutRepository;

  // ✅ Aggiungiamo il tracking dell'ultimo userId per il refresh automatico
  int? _lastUserId;

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
    on<LoadWorkoutPlanWithData>(_onLoadWorkoutPlanWithData);
    on<RefreshWorkoutPlansAfterOperation>(_onRefreshWorkoutPlansAfterOperation);
  }

  /// Handler per caricamento schede allenamento
  Future<void> _onGetWorkoutPlans(
      GetWorkoutPlans event,
      Emitter<WorkoutState> emit,
      ) async {
    emit(const WorkoutLoading());

    // ✅ Salva l'ultimo userId per refresh automatici
    _lastUserId = event.userId;

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

  /// ✅ Handler per refresh automatico dopo operazioni
  Future<void> _onRefreshWorkoutPlansAfterOperation(
      RefreshWorkoutPlansAfterOperation event,
      Emitter<WorkoutState> emit,
      ) async {
    developer.log('Auto-refreshing workout plans after ${event.operation}', name: 'WorkoutBloc');

    // Ricarica silenziosamente le schede senza mostrare loading
    final result = await _workoutRepository.getWorkoutPlans(event.userId);

    result.fold(
      onSuccess: (workoutPlans) {
        developer.log('Successfully auto-refreshed ${workoutPlans.length} workout plans', name: 'WorkoutBloc');
        emit(WorkoutPlansLoaded(
          workoutPlans: workoutPlans,
          userId: event.userId,
        ));
      },
      onFailure: (exception, message) {
        developer.log('Error auto-refreshing workout plans: $message', name: 'WorkoutBloc', error: exception);
        // Non emettiamo errore per refresh automatico, manteniamo lo stato precedente
      },
    );
  }

  // Altri handler rimangono invariati...
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

  Future<void> _onGetAvailableExercises(
      GetAvailableExercises event,
      Emitter<WorkoutState> emit,
      ) async {
    emit(const WorkoutLoadingWithMessage(message: 'Caricamento esercizi disponibili...'));

    developer.log('Loading available exercises for user: ${event.userId}', name: 'WorkoutBloc');

    try {
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
    } catch (e) {
      developer.log('Exception in _onGetAvailableExercises: $e', name: 'WorkoutBloc', error: e);
      emit(WorkoutError(
        message: 'Errore nell\'elaborazione degli esercizi disponibili: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// ✅ Handler per creazione scheda con refresh automatico
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

        // ✅ Refresh automatico delle schede dopo creazione
        if (_lastUserId != null) {
          add(RefreshWorkoutPlansAfterOperation(
            userId: _lastUserId!,
            operation: 'create',
          ));
        }
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

  /// ✅ Handler per aggiornamento scheda con refresh automatico
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

        // ✅ Refresh automatico delle schede dopo aggiornamento
        if (_lastUserId != null) {
          add(RefreshWorkoutPlansAfterOperation(
            userId: _lastUserId!,
            operation: 'update',
          ));
        }
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

  /// ✅ Handler per eliminazione scheda con refresh automatico
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

        // ✅ Refresh automatico delle schede dopo eliminazione
        if (_lastUserId != null) {
          add(RefreshWorkoutPlansAfterOperation(
            userId: _lastUserId!,
            operation: 'delete',
          ));
        }
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

  // Altri handler rimangono invariati...
  Future<void> _onLoadWorkoutPlanWithData(
      LoadWorkoutPlanWithData event,
      Emitter<WorkoutState> emit,
      ) async {
    emit(const WorkoutLoadingWithMessage(message: 'Caricamento dettagli scheda...'));

    developer.log('Loading workout plan with existing data: ${event.workoutPlan.nome}', name: 'WorkoutBloc');

    try {
      final result = await _workoutRepository.getWorkoutExercises(event.schedaId);

      result.fold(
        onSuccess: (exercises) {
          developer.log('Successfully loaded workout plan with data: ${exercises.length} exercises', name: 'WorkoutBloc');

          final workoutPlan = event.workoutPlan.copyWith(esercizi: exercises);

          emit(WorkoutPlanDetailsLoaded(
            workoutPlan: workoutPlan,
            exercises: exercises,
          ));
        },
        onFailure: (exception, message) {
          developer.log('Error loading workout plan with data: $message', name: 'WorkoutBloc', error: exception);
          emit(WorkoutError(
            message: message ?? 'Errore nel caricamento dei dettagli della scheda',
            exception: exception,
          ));
        },
      );
    } catch (e) {
      developer.log('Exception in _onLoadWorkoutPlanWithData: $e', name: 'WorkoutBloc', error: e);
      emit(WorkoutError(
        message: 'Errore nell\'elaborazione dei dettagli della scheda: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  Future<void> _onGetWorkoutPlanDetails(
      GetWorkoutPlanDetails event,
      Emitter<WorkoutState> emit,
      ) async {
    emit(const WorkoutLoadingWithMessage(message: 'Caricamento dettagli scheda...'));

    developer.log('Loading workout plan details: ${event.schedaId}', name: 'WorkoutBloc');

    try {
      // ✅ FIX: Prima assicuriamoci di avere le schede caricate
      WorkoutPlan? workoutPlan;

      // Controlla se abbiamo già i dati delle schede
      if (state is WorkoutPlansLoaded) {
        try {
          workoutPlan = (state as WorkoutPlansLoaded).workoutPlans.firstWhere(
                (plan) => plan.id == event.schedaId,
          );
          developer.log('✅ Found existing plan: ${workoutPlan.nome}', name: 'WorkoutBloc');
        } catch (e) {
          developer.log('⚠️ Plan not found in current state', name: 'WorkoutBloc');
          workoutPlan = null;
        }
      }

      // Se non abbiamo la scheda, dobbiamo caricarla prima
      if (workoutPlan == null && _lastUserId != null) {
        developer.log('🔄 Loading workout plans first to get real data...', name: 'WorkoutBloc');

        // Carica le schede prima
        final plansResult = await _workoutRepository.getWorkoutPlans(_lastUserId!);

        plansResult.fold(
          onSuccess: (plans) {
            try {
              workoutPlan = plans.firstWhere((plan) => plan.id == event.schedaId);
              developer.log('✅ Found plan after loading: ${workoutPlan!.nome}', name: 'WorkoutBloc');
            } catch (e) {
              developer.log('❌ Plan still not found after loading', name: 'WorkoutBloc');
              workoutPlan = null;
            }
          },
          onFailure: (exception, message) {
            developer.log('❌ Failed to load plans: $message', name: 'WorkoutBloc');
            workoutPlan = null;
          },
        );
      }

      // Ora carica gli esercizi
      final exercisesResult = await _workoutRepository.getWorkoutExercises(event.schedaId);

      exercisesResult.fold(
        onSuccess: (exercises) {
          developer.log('Successfully loaded workout plan details', name: 'WorkoutBloc');

          // Se ancora non abbiamo la scheda, usa un fallback MA con avviso
          if (workoutPlan == null) {
            developer.log('⚠️ Using fallback workout plan data', name: 'WorkoutBloc');
            workoutPlan = WorkoutPlan(
              id: event.schedaId,
              nome: 'Scheda Sconosciuta #${event.schedaId}',
              descrizione: 'Dati della scheda non disponibili',
              dataCreazione: null,
              esercizi: exercises,
            );
          } else {
            // Usa i dati reali
            workoutPlan = workoutPlan!.copyWith(esercizi: exercises);
          }

          emit(WorkoutPlanDetailsLoaded(
            workoutPlan: workoutPlan!,
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
    } catch (e) {
      developer.log('Exception in _onGetWorkoutPlanDetails: $e', name: 'WorkoutBloc', error: e);
      emit(WorkoutError(
        message: 'Errore nell\'elaborazione dei dettagli della scheda',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  Future<void> _onResetWorkoutState(
      ResetWorkoutState event,
      Emitter<WorkoutState> emit,
      ) async {
    developer.log('Resetting workout state', name: 'WorkoutBloc');
    _lastUserId = null; // ✅ Reset anche il tracking userId
    emit(const WorkoutInitial());
  }

  // ============================================================================
  // PUBLIC METHODS (aggiornati)
  // ============================================================================

  void loadWorkoutPlans(int userId) {
    add(GetWorkoutPlans(userId: userId));
  }

  void loadWorkoutExercises(int schedaId) {
    add(GetWorkoutExercises(schedaId: schedaId));
  }

  void loadAvailableExercises(int userId) {
    add(GetAvailableExercises(userId: userId));
  }

  void createWorkout(CreateWorkoutPlanRequest request) {
    // ✅ Salva l'userId per il refresh automatico
    _lastUserId = request.userId;
    add(CreateWorkoutPlan(request: request));
  }

  void updateWorkout(UpdateWorkoutPlanRequest request) {
    // ✅ Salva l'userId per il refresh automatico
    _lastUserId = request.userId;
    add(UpdateWorkoutPlan(request: request));
  }

  void deleteWorkout(int schedaId) {
    add(DeleteWorkoutPlan(schedaId: schedaId));
  }

  void loadWorkoutPlanDetails(int schedaId) {
    add(GetWorkoutPlanDetails(schedaId: schedaId));
  }

  void loadWorkoutPlanWithData(WorkoutPlan workoutPlan) {
    add(LoadWorkoutPlanWithData(workoutPlan: workoutPlan, schedaId: workoutPlan.id));
  }

  void resetState() {
    add(const ResetWorkoutState());
  }

  // ✅ Nuovo metodo pubblico per refresh manuale
  void refreshWorkoutPlans(int userId) {
    add(RefreshWorkoutPlansAfterOperation(userId: userId, operation: 'manual'));
  }
}