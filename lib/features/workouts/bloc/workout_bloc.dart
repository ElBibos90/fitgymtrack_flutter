// lib/features/workouts/bloc/workout_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';


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

    ////print('[CONSOLE] [workout_bloc]Loading workout plans for user: ${event.userId}');

    final result = await _workoutRepository.getWorkoutPlans(event.userId);

    result.fold(
      onSuccess: (workoutPlans) {
        ////print('[CONSOLE] [workout_bloc]Successfully loaded ${workoutPlans.length} workout plans');
        emit(WorkoutPlansLoaded(
          workoutPlans: workoutPlans,
          userId: event.userId,
        ));
      },
      onFailure: (exception, message) {
        ////print('[CONSOLE] [workout_bloc]Error loading workout plans: $message');
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
    ////print('[CONSOLE] [workout_bloc]Auto-refreshing workout plans after ${event.operation}');

    // Ricarica silenziosamente le schede senza mostrare loading
    final result = await _workoutRepository.getWorkoutPlans(event.userId);

    result.fold(
      onSuccess: (workoutPlans) {
        ////print('[CONSOLE] [workout_bloc]Successfully auto-refreshed ${workoutPlans.length} workout plans');
        emit(WorkoutPlansLoaded(
          workoutPlans: workoutPlans,
          userId: event.userId,
        ));
      },
      onFailure: (exception, message) {
        ////print('[CONSOLE] [workout_bloc]Error auto-refreshing workout plans: $message');
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

    //print('[CONSOLE] [workout_bloc]Loading exercises for workout: ${event.schedaId}');

    final result = await _workoutRepository.getWorkoutExercises(event.schedaId);

    result.fold(
      onSuccess: (exercises) {
        //print('[CONSOLE] [workout_bloc]Successfully loaded ${exercises.length} exercises');
        emit(WorkoutExercisesLoaded(
          exercises: exercises,
          schedaId: event.schedaId,
        ));
      },
      onFailure: (exception, message) {
        //print('[CONSOLE] [workout_bloc]Error loading exercises: $message');
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

    try {
      final result = await _workoutRepository.getAvailableExercises(event.userId);

      result.fold(
        onSuccess: (exercises) {
          emit(AvailableExercisesLoaded(
            availableExercises: exercises,
            userId: event.userId,
          ));
        },
        onFailure: (exception, message) {
          emit(WorkoutError(
            message: message ?? 'Errore nel caricamento degli esercizi disponibili',
            exception: exception,
          ));
        },
      );
    } catch (e) {
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

    //print('[CONSOLE] [workout_bloc]Creating workout plan: ${event.request.nome}');

    final result = await _workoutRepository.createWorkoutPlan(event.request);

    result.fold(
      onSuccess: (response) {
        //print('[CONSOLE] [workout_bloc]Successfully created workout plan');
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
        //print('[CONSOLE] [workout_bloc]Error creating workout plan: $message');
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

    //print('[CONSOLE] [workout_bloc]Updating workout plan: ${event.request.schedaId}');

    final result = await _workoutRepository.updateWorkoutPlan(event.request);

    result.fold(
      onSuccess: (response) {
        //print('[CONSOLE] [workout_bloc]Successfully updated workout plan');
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
        //print('[CONSOLE] [workout_bloc]Error updating workout plan: $message');
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

    //print('[CONSOLE] [workout_bloc]Deleting workout plan: ${event.schedaId}');

    final result = await _workoutRepository.deleteWorkoutPlan(event.schedaId);

    result.fold(
      onSuccess: (response) {
        //print('[CONSOLE] [workout_bloc]Successfully deleted workout plan');
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
        //print('[CONSOLE] [workout_bloc]Error deleting workout plan: $message');
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

    //print('[CONSOLE] [workout_bloc]Loading workout plan with existing data: ${event.workoutPlan.nome}');

    try {
      final result = await _workoutRepository.getWorkoutExercises(event.schedaId);

      result.fold(
        onSuccess: (exercises) {
          //print('[CONSOLE] [workout_bloc]Successfully loaded workout plan with data: ${exercises.length} exercises');

          final workoutPlan = event.workoutPlan.copyWith(esercizi: exercises);

          emit(WorkoutPlanDetailsLoaded(
            workoutPlan: workoutPlan,
            exercises: exercises,
          ));
        },
        onFailure: (exception, message) {
          //print('[CONSOLE] [workout_bloc]Error loading workout plan with data: $message');
          emit(WorkoutError(
            message: message ?? 'Errore nel caricamento dei dettagli della scheda',
            exception: exception,
          ));
        },
      );
    } catch (e) {
      //print('[CONSOLE] [workout_bloc]Exception in _onLoadWorkoutPlanWithData: $e');
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

    //print('[CONSOLE] [workout_bloc]Loading workout plan details: ${event.schedaId}');

    try {
      // ✅ FIX: Prima assicuriamoci di avere le schede caricate
      WorkoutPlan? workoutPlan;

      // Controlla se abbiamo già i dati delle schede
      if (state is WorkoutPlansLoaded) {
        try {
          workoutPlan = (state as WorkoutPlansLoaded).workoutPlans.firstWhere(
                (plan) => plan.id == event.schedaId,
          );
          //print('[CONSOLE] [workout_bloc]✅ Found existing plan: ${workoutPlan.nome}');
        } catch (e) {
          //print('[CONSOLE] [workout_bloc]⚠️ Plan not found in current state');
          workoutPlan = null;
        }
      }

      // Se non abbiamo la scheda, dobbiamo caricarla prima
      if (workoutPlan == null && _lastUserId != null) {
        //print('[CONSOLE] [workout_bloc]🔄 Loading workout plans first to get real data...');

        // Carica le schede prima
        final plansResult = await _workoutRepository.getWorkoutPlans(_lastUserId!);

        plansResult.fold(
          onSuccess: (plans) {
            try {
              workoutPlan = plans.firstWhere((plan) => plan.id == event.schedaId);
              //print('[CONSOLE] [workout_bloc]✅ Found plan after loading: ${workoutPlan!.nome}');
            } catch (e) {
              //print('[CONSOLE] [workout_bloc]❌ Plan still not found after loading');
              workoutPlan = null;
            }
          },
          onFailure: (exception, message) {
            //print('[CONSOLE] [workout_bloc]❌ Failed to load plans: $message');
            workoutPlan = null;
          },
        );
      }

      // Ora carica gli esercizi
      final exercisesResult = await _workoutRepository.getWorkoutExercises(event.schedaId);

      exercisesResult.fold(
        onSuccess: (exercises) {
          //print('[CONSOLE] [workout_bloc]Successfully loaded workout plan details');

          // Se ancora non abbiamo la scheda, usa un fallback MA con avviso
          if (workoutPlan == null) {
            //print('[CONSOLE] [workout_bloc]⚠️ Using fallback workout plan data');
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
          //print('[CONSOLE] [workout_bloc]Error loading workout plan details: $message');
          emit(WorkoutError(
            message: message ?? 'Errore nel caricamento dei dettagli della scheda',
            exception: exception,
          ));
        },
      );
    } catch (e) {
      //print('[CONSOLE] [workout_bloc]Exception in _onGetWorkoutPlanDetails: $e');
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
    //print('[CONSOLE] [workout_bloc]Resetting workout state');
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