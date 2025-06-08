// lib/features/workouts/bloc/workout_history_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';


import '../repository/workout_repository.dart';
import '../models/active_workout_models.dart';
import '../models/series_request_models.dart';
import '../../stats/models/user_stats_models.dart';

// ============================================================================
// WORKOUT HISTORY EVENTS
// ============================================================================

abstract class WorkoutHistoryEvent extends Equatable {
  const WorkoutHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Evento per caricare la cronologia degli allenamenti
class GetWorkoutHistory extends WorkoutHistoryEvent {
  final int userId;

  const GetWorkoutHistory({required this.userId});

  @override
  List<Object> get props => [userId];
}

/// Evento per caricare i dettagli delle serie di un allenamento specifico
class GetWorkoutSeriesDetail extends WorkoutHistoryEvent {
  final int allenamentoId;

  const GetWorkoutSeriesDetail({required this.allenamentoId});

  @override
  List<Object> get props => [allenamentoId];
}

/// Evento per eliminare una serie completata dalla cronologia
class DeleteCompletedSeries extends WorkoutHistoryEvent {
  final String seriesId;
  final int allenamentoId; // Per ricaricare i dati dopo la cancellazione

  const DeleteCompletedSeries({
    required this.seriesId,
    required this.allenamentoId,
  });

  @override
  List<Object> get props => [seriesId, allenamentoId];
}

/// Evento per aggiornare una serie completata
class UpdateCompletedSeries extends WorkoutHistoryEvent {
  final String seriesId;
  final double weight;
  final int reps;
  final int? recoveryTime;
  final String? notes;
  final int allenamentoId; // Per ricaricare i dati dopo l'aggiornamento

  const UpdateCompletedSeries({
    required this.seriesId,
    required this.weight,
    required this.reps,
    this.recoveryTime,
    this.notes,
    required this.allenamentoId,
  });

  @override
  List<Object?> get props => [seriesId, weight, reps, recoveryTime, notes, allenamentoId];
}

/// Evento per eliminare un intero allenamento dalla cronologia
class DeleteWorkoutFromHistory extends WorkoutHistoryEvent {
  final int workoutId;
  final int userId; // Per ricaricare la cronologia dopo la cancellazione

  const DeleteWorkoutFromHistory({
    required this.workoutId,
    required this.userId,
  });

  @override
  List<Object> get props => [workoutId, userId];
}

/// Evento per caricare le statistiche dell'utente
class GetUserStats extends WorkoutHistoryEvent {
  final int userId;

  const GetUserStats({required this.userId});

  @override
  List<Object> get props => [userId];
}

/// Evento per caricare statistiche per un periodo specifico
class GetPeriodStats extends WorkoutHistoryEvent {
  final String period; // "week", "month", "year"

  const GetPeriodStats({required this.period});

  @override
  List<Object> get props => [period];
}

/// Evento per resettare lo stato
class ResetWorkoutHistoryState extends WorkoutHistoryEvent {
  const ResetWorkoutHistoryState();
}

/// Evento per ricaricare i dati dopo un'operazione
class RefreshWorkoutHistory extends WorkoutHistoryEvent {
  final int userId;

  const RefreshWorkoutHistory({required this.userId});

  @override
  List<Object> get props => [userId];
}

// ============================================================================
// WORKOUT HISTORY STATES
// ============================================================================

abstract class WorkoutHistoryState extends Equatable {
  const WorkoutHistoryState();

  @override
  List<Object?> get props => [];
}

/// Stato iniziale
class WorkoutHistoryInitial extends WorkoutHistoryState {
  const WorkoutHistoryInitial();
}

/// Stato di caricamento
class WorkoutHistoryLoading extends WorkoutHistoryState {
  final String? message;

  const WorkoutHistoryLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Stato con cronologia caricata
class WorkoutHistoryLoaded extends WorkoutHistoryState {
  final List<WorkoutHistory> workoutHistory;
  final int userId;

  const WorkoutHistoryLoaded({
    required this.workoutHistory,
    required this.userId,
  });

  @override
  List<Object> get props => [workoutHistory, userId];
}

/// Stato con dettagli serie di un allenamento caricati
class WorkoutSeriesDetailLoaded extends WorkoutHistoryState {
  final List<CompletedSeriesData> seriesDetails;
  final int allenamentoId;

  const WorkoutSeriesDetailLoaded({
    required this.seriesDetails,
    required this.allenamentoId,
  });

  @override
  List<Object> get props => [seriesDetails, allenamentoId];
}

/// Stato con statistiche utente caricate
class UserStatsLoaded extends WorkoutHistoryState {
  final UserStats userStats;
  final int userId;

  const UserStatsLoaded({
    required this.userStats,
    required this.userId,
  });

  @override
  List<Object> get props => [userStats, userId];
}

/// Stato con statistiche periodo caricate
class PeriodStatsLoaded extends WorkoutHistoryState {
  final PeriodStats periodStats;
  final String period;

  const PeriodStatsLoaded({
    required this.periodStats,
    required this.period,
  });

  @override
  List<Object> get props => [periodStats, period];
}

/// Stato di successo per operazioni di modifica/cancellazione
class WorkoutHistoryOperationSuccess extends WorkoutHistoryState {
  final String message;
  final String operationType; // "delete_series", "update_series", "delete_workout"

  const WorkoutHistoryOperationSuccess({
    required this.message,
    required this.operationType,
  });

  @override
  List<Object> get props => [message, operationType];
}

/// Stato di errore
class WorkoutHistoryError extends WorkoutHistoryState {
  final String message;
  final Exception? exception;

  const WorkoutHistoryError({
    required this.message,
    this.exception,
  });

  @override
  List<Object?> get props => [message, exception];
}

// ============================================================================
// WORKOUT HISTORY BLOC
// ============================================================================

class WorkoutHistoryBloc extends Bloc<WorkoutHistoryEvent, WorkoutHistoryState> {
  final WorkoutRepository _workoutRepository;

  WorkoutHistoryBloc({required WorkoutRepository workoutRepository})
      : _workoutRepository = workoutRepository,
        super(const WorkoutHistoryInitial()) {

    // Registrazione event handlers
    on<GetWorkoutHistory>(_onGetWorkoutHistory);
    on<GetWorkoutSeriesDetail>(_onGetWorkoutSeriesDetail);
    on<DeleteCompletedSeries>(_onDeleteCompletedSeries);
    on<UpdateCompletedSeries>(_onUpdateCompletedSeries);
    on<DeleteWorkoutFromHistory>(_onDeleteWorkoutFromHistory);
    on<GetUserStats>(_onGetUserStats);
    on<GetPeriodStats>(_onGetPeriodStats);
    on<ResetWorkoutHistoryState>(_onResetWorkoutHistoryState);
    on<RefreshWorkoutHistory>(_onRefreshWorkoutHistory);
  }

  /// Handler per caricare la cronologia degli allenamenti
  Future<void> _onGetWorkoutHistory(
      GetWorkoutHistory event,
      Emitter<WorkoutHistoryState> emit,
      ) async {
    emit(const WorkoutHistoryLoading(message: 'Caricamento cronologia...'));

    print('Loading workout history for user: ${event.userId}');

    final result = await _workoutRepository.getWorkoutHistory(event.userId);

    result.fold(
      onSuccess: (workoutHistory) {
        print('Successfully loaded ${workoutHistory.length} workout history entries',
            name: 'WorkoutHistoryBloc');
        emit(WorkoutHistoryLoaded(
          workoutHistory: workoutHistory,
          userId: event.userId,
        ));
      },
      onFailure: (exception, message) {
        print('Error loading workout history: $message',
            name: 'WorkoutHistoryBloc');
        emit(WorkoutHistoryError(
          message: message ?? 'Errore nel caricamento della cronologia allenamenti',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per caricare i dettagli delle serie di un allenamento
  Future<void> _onGetWorkoutSeriesDetail(
      GetWorkoutSeriesDetail event,
      Emitter<WorkoutHistoryState> emit,
      ) async {
    emit(const WorkoutHistoryLoading(message: 'Caricamento dettagli serie...'));

    print('Loading series details for workout: ${event.allenamentoId}',
        name: 'WorkoutHistoryBloc');

    final result = await _workoutRepository.getWorkoutSeriesDetail(event.allenamentoId);

    result.fold(
      onSuccess: (seriesDetails) {
        print('Successfully loaded ${seriesDetails.length} series details',
            name: 'WorkoutHistoryBloc');
        emit(WorkoutSeriesDetailLoaded(
          seriesDetails: seriesDetails,
          allenamentoId: event.allenamentoId,
        ));
      },
      onFailure: (exception, message) {
        print('Error loading series details: $message',
            name: 'WorkoutHistoryBloc');
        emit(WorkoutHistoryError(
          message: message ?? 'Errore nel caricamento dei dettagli delle serie',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per eliminare una serie completata
  Future<void> _onDeleteCompletedSeries(
      DeleteCompletedSeries event,
      Emitter<WorkoutHistoryState> emit,
      ) async {
    emit(const WorkoutHistoryLoading(message: 'Eliminazione serie...'));

    print('Deleting completed series: ${event.seriesId}');

    final result = await _workoutRepository.deleteCompletedSeries(event.seriesId);

    result.fold(
      onSuccess: (success) {
        if (success) {
          print('Successfully deleted completed series');

          emit(const WorkoutHistoryOperationSuccess(
            message: 'Serie eliminata con successo',
            operationType: 'delete_series',
          ));

          // Ricarica i dettagli delle serie per aggiornare la lista
          add(GetWorkoutSeriesDetail(allenamentoId: event.allenamentoId));
        } else {
          emit(const WorkoutHistoryError(
            message: 'Impossibile eliminare la serie',
          ));
        }
      },
      onFailure: (exception, message) {
        print('Error deleting completed series: $message',
            name: 'WorkoutHistoryBloc');
        emit(WorkoutHistoryError(
          message: message ?? 'Errore nell\'eliminazione della serie',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per aggiornare una serie completata
  Future<void> _onUpdateCompletedSeries(
      UpdateCompletedSeries event,
      Emitter<WorkoutHistoryState> emit,
      ) async {
    emit(const WorkoutHistoryLoading(message: 'Aggiornamento serie...'));

    print('Updating completed series: ${event.seriesId}');

    final result = await _workoutRepository.updateCompletedSeries(
      event.seriesId,
      event.weight,
      event.reps,
      recoveryTime: event.recoveryTime,
      notes: event.notes,
    );

    result.fold(
      onSuccess: (success) {
        if (success) {
          print('Successfully updated completed series');

          emit(const WorkoutHistoryOperationSuccess(
            message: 'Serie aggiornata con successo',
            operationType: 'update_series',
          ));

          // Ricarica i dettagli delle serie per aggiornare la lista
          add(GetWorkoutSeriesDetail(allenamentoId: event.allenamentoId));
        } else {
          emit(const WorkoutHistoryError(
            message: 'Impossibile aggiornare la serie',
          ));
        }
      },
      onFailure: (exception, message) {
        print('Error updating completed series: $message',
            name: 'WorkoutHistoryBloc');
        emit(WorkoutHistoryError(
          message: message ?? 'Errore nell\'aggiornamento della serie',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per eliminare un allenamento dalla cronologia
  Future<void> _onDeleteWorkoutFromHistory(
      DeleteWorkoutFromHistory event,
      Emitter<WorkoutHistoryState> emit,
      ) async {
    emit(const WorkoutHistoryLoading(message: 'Eliminazione allenamento...'));

    print('Deleting workout from history: ${event.workoutId}');

    final result = await _workoutRepository.deleteWorkout(event.workoutId);

    result.fold(
      onSuccess: (success) {
        if (success) {
          print('Successfully deleted workout from history');

          emit(const WorkoutHistoryOperationSuccess(
            message: 'Allenamento eliminato con successo',
            operationType: 'delete_workout',
          ));

          // Ricarica la cronologia per aggiornare la lista
          add(GetWorkoutHistory(userId: event.userId));
        } else {
          emit(const WorkoutHistoryError(
            message: 'Impossibile eliminare l\'allenamento',
          ));
        }
      },
      onFailure: (exception, message) {
        print('Error deleting workout from history: $message',
            name: 'WorkoutHistoryBloc');
        emit(WorkoutHistoryError(
          message: message ?? 'Errore nell\'eliminazione dell\'allenamento',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per caricare le statistiche dell'utente
  Future<void> _onGetUserStats(
      GetUserStats event,
      Emitter<WorkoutHistoryState> emit,
      ) async {
    emit(const WorkoutHistoryLoading(message: 'Caricamento statistiche...'));

    print('Loading user stats for user: ${event.userId}');

    final result = await _workoutRepository.getUserStats(event.userId);

    result.fold(
      onSuccess: (userStats) {
        print('Successfully loaded user stats');
        emit(UserStatsLoaded(
          userStats: userStats,
          userId: event.userId,
        ));
      },
      onFailure: (exception, message) {
        print('Error loading user stats: $message',
            name: 'WorkoutHistoryBloc');
        emit(WorkoutHistoryError(
          message: message ?? 'Errore nel caricamento delle statistiche',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per caricare le statistiche per periodo
  Future<void> _onGetPeriodStats(
      GetPeriodStats event,
      Emitter<WorkoutHistoryState> emit,
      ) async {
    emit(const WorkoutHistoryLoading(message: 'Caricamento statistiche periodo...'));

    print('Loading period stats for period: ${event.period}');

    final result = await _workoutRepository.getPeriodStats(event.period);

    result.fold(
      onSuccess: (periodStats) {
        print('Successfully loaded period stats');
        emit(PeriodStatsLoaded(
          periodStats: periodStats,
          period: event.period,
        ));
      },
      onFailure: (exception, message) {
        print('Error loading period stats: $message',
            name: 'WorkoutHistoryBloc');
        emit(WorkoutHistoryError(
          message: message ?? 'Errore nel caricamento delle statistiche del periodo',
          exception: exception,
        ));
      },
    );
  }

  /// Handler per refresh della cronologia
  Future<void> _onRefreshWorkoutHistory(
      RefreshWorkoutHistory event,
      Emitter<WorkoutHistoryState> emit,
      ) async {
    // Ricarica la cronologia senza mostrare loading se già abbiamo dati
    if (state is! WorkoutHistoryLoaded) {
      emit(const WorkoutHistoryLoading(message: 'Aggiornamento...'));
    }

    add(GetWorkoutHistory(userId: event.userId));
  }

  /// Handler per reset dello stato
  Future<void> _onResetWorkoutHistoryState(
      ResetWorkoutHistoryState event,
      Emitter<WorkoutHistoryState> emit,
      ) async {
    print('Resetting workout history state');
    emit(const WorkoutHistoryInitial());
  }

  // ============================================================================
  // PUBLIC METHODS (helper methods per semplificare l'uso)
  // ============================================================================

  /// Carica la cronologia degli allenamenti
  void loadWorkoutHistory(int userId) {
    add(GetWorkoutHistory(userId: userId));
  }

  /// Carica i dettagli delle serie di un allenamento
  void loadWorkoutSeriesDetail(int allenamentoId) {
    add(GetWorkoutSeriesDetail(allenamentoId: allenamentoId));
  }

  /// Elimina una serie completata
  void deleteCompletedSeries(String seriesId, int allenamentoId) {
    add(DeleteCompletedSeries(seriesId: seriesId, allenamentoId: allenamentoId));
  }

  /// Aggiorna una serie completata
  void updateCompletedSeries(
      String seriesId,
      double weight,
      int reps,
      int allenamentoId, {
        int? recoveryTime,
        String? notes,
      }) {
    add(UpdateCompletedSeries(
      seriesId: seriesId,
      weight: weight,
      reps: reps,
      allenamentoId: allenamentoId,
      recoveryTime: recoveryTime,
      notes: notes,
    ));
  }

  /// Elimina un allenamento dalla cronologia
  void deleteWorkoutFromHistory(int workoutId, int userId) {
    add(DeleteWorkoutFromHistory(workoutId: workoutId, userId: userId));
  }

  /// Carica le statistiche dell'utente
  void loadUserStats(int userId) {
    add(GetUserStats(userId: userId));
  }

  /// Carica le statistiche per un periodo
  void loadPeriodStats(String period) {
    add(GetPeriodStats(period: period));
  }

  /// Aggiorna la cronologia
  void refreshWorkoutHistory(int userId) {
    add(RefreshWorkoutHistory(userId: userId));
  }

  /// Resetta lo stato del BLoC
  void resetState() {
    add(const ResetWorkoutHistoryState());
  }
}