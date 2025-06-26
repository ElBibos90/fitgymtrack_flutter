// lib/features/stats/bloc/stats_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../repository/stats_repository.dart';
import '../models/stats_models.dart';

// ============================================================================
// 📊 STATS EVENTS
// ============================================================================

abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object?> get props => [];
}

class LoadInitialStats extends StatsEvent {
  final StatsPeriod initialPeriod;

  const LoadInitialStats({this.initialPeriod = StatsPeriod.week});

  @override
  List<Object?> get props => [initialPeriod];
}

class LoadUserStats extends StatsEvent {}

class ChangePeriod extends StatsEvent {
  final StatsPeriod period;

  const ChangePeriod(this.period);

  @override
  List<Object?> get props => [period];
}

class RefreshStats extends StatsEvent {}

class RefreshPeriodStats extends StatsEvent {}

// ============================================================================
// 📊 STATS STATES
// ============================================================================

abstract class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class StatsPeriodLoading extends StatsState {
  final UserStatsResponse userStats;
  final StatsPeriod currentPeriod;
  final bool isPremium;

  const StatsPeriodLoading({
    required this.userStats,
    required this.currentPeriod,
    required this.isPremium,
  });

  @override
  List<Object?> get props => [userStats, currentPeriod, isPremium];
}

class StatsLoaded extends StatsState {
  final UserStatsResponse userStats;
  final PeriodStatsResponse periodStats;
  final StatsPeriod currentPeriod;
  final bool isPremium;

  const StatsLoaded({
    required this.userStats,
    required this.periodStats,
    required this.currentPeriod,
    required this.isPremium,
  });

  @override
  List<Object?> get props => [userStats, periodStats, currentPeriod, isPremium];

  StatsLoaded copyWith({
    UserStatsResponse? userStats,
    PeriodStatsResponse? periodStats,
    StatsPeriod? currentPeriod,
    bool? isPremium,
  }) {
    return StatsLoaded(
      userStats: userStats ?? this.userStats,
      periodStats: periodStats ?? this.periodStats,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}

class StatsError extends StatsState {
  final String message;
  final bool canRetry;

  const StatsError({
    required this.message,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, canRetry];
}

// ============================================================================
// 📊 STATS BLOC
// ============================================================================

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final StatsRepository _repository;

  StatsBloc(this._repository) : super(StatsInitial()) {
    on<LoadInitialStats>(_onLoadInitialStats);
    on<LoadUserStats>(_onLoadUserStats);
    on<ChangePeriod>(_onChangePeriod);
    on<RefreshStats>(_onRefreshStats);
    on<RefreshPeriodStats>(_onRefreshPeriodStats);
  }

  Future<void> _onLoadInitialStats(
      LoadInitialStats event,
      Emitter<StatsState> emit,
      ) async {
    try {
      print('🔄 Caricamento statistiche iniziali...');
      emit(StatsLoading());

      final bundle = await _repository.getStatsBundle(event.initialPeriod);

      print('✅ Statistiche iniziali caricate con successo');
      emit(StatsLoaded(
        userStats: bundle.userStats,
        periodStats: bundle.periodStats,
        currentPeriod: event.initialPeriod,
        isPremium: bundle.isPremium,
      ));

    } on StatsException catch (e) {
      print('❌ Errore StatsException nel caricamento iniziale: ${e.message}');
      emit(StatsError(message: e.message));
    } catch (e) {
      print('❌ Errore generico nel caricamento iniziale: $e');
      emit(const StatsError(
        message: 'Errore imprevisto nel caricamento delle statistiche. Riprova.',
      ));
    }
  }

  Future<void> _onLoadUserStats(
      LoadUserStats event,
      Emitter<StatsState> emit,
      ) async {
    try {
      print('🔄 Caricamento statistiche utente...');
      emit(StatsLoading());

      final userStats = await _repository.getUserStats();

      print('✅ Statistiche utente caricate con successo');

      if (state is StatsLoaded) {
        final currentState = state as StatsLoaded;
        emit(currentState.copyWith(userStats: userStats));
      } else {
        add(const LoadInitialStats(initialPeriod: StatsPeriod.week));
      }

    } on StatsException catch (e) {
      print('❌ Errore nel caricamento statistiche utente: ${e.message}');
      emit(StatsError(message: e.message));
    } catch (e) {
      print('❌ Errore generico nel caricamento statistiche utente: $e');
      emit(const StatsError(
        message: 'Errore nel caricamento delle statistiche utente.',
      ));
    }
  }

  Future<void> _onChangePeriod(
      ChangePeriod event,
      Emitter<StatsState> emit,
      ) async {
    try {
      print('🔄 Cambio periodo a: ${event.period.displayName}');

      if (state is StatsLoaded) {
        final currentState = state as StatsLoaded;
        emit(StatsPeriodLoading(
          userStats: currentState.userStats,
          currentPeriod: event.period,
          isPremium: currentState.isPremium,
        ));
      } else {
        emit(StatsLoading());
      }

      final periodStats = await _repository.getPeriodStats(event.period);

      print('✅ Statistiche periodo ${event.period.displayName} caricate');

      if (state is StatsPeriodLoading) {
        final loadingState = state as StatsPeriodLoading;
        emit(StatsLoaded(
          userStats: loadingState.userStats,
          periodStats: periodStats,
          currentPeriod: event.period,
          isPremium: loadingState.isPremium,
        ));
      } else {
        add(LoadInitialStats(initialPeriod: event.period));
      }

    } on StatsException catch (e) {
      print('❌ Errore nel cambio periodo: ${e.message}');
      emit(StatsError(message: e.message));
    } catch (e) {
      print('❌ Errore generico nel cambio periodo: $e');
      emit(StatsError(
        message: 'Errore nel cambio del periodo. Riprova.',
      ));
    }
  }

  Future<void> _onRefreshStats(
      RefreshStats event,
      Emitter<StatsState> emit,
      ) async {
    try {
      print('🔄 Refresh completo statistiche...');

      StatsPeriod currentPeriod = StatsPeriod.week;
      if (state is StatsLoaded) {
        currentPeriod = (state as StatsLoaded).currentPeriod;
      }

      final bundle = await _repository.getStatsBundle(currentPeriod);

      print('✅ Refresh statistiche completato');
      emit(StatsLoaded(
        userStats: bundle.userStats,
        periodStats: bundle.periodStats,
        currentPeriod: currentPeriod,
        isPremium: bundle.isPremium,
      ));

    } on StatsException catch (e) {
      print('❌ Errore nel refresh: ${e.message}');
      if (state is! StatsLoaded) {
        emit(StatsError(message: e.message));
      }
    } catch (e) {
      print('❌ Errore generico nel refresh: $e');
      if (state is! StatsLoaded) {
        emit(const StatsError(
          message: 'Errore nel refresh delle statistiche.',
        ));
      }
    }
  }

  Future<void> _onRefreshPeriodStats(
      RefreshPeriodStats event,
      Emitter<StatsState> emit,
      ) async {
    try {
      if (state is! StatsLoaded) {
        print('⚠️ Tentativo di refresh periodo senza stato caricato');
        return;
      }

      final currentState = state as StatsLoaded;
      print('🔄 Refresh statistiche periodo: ${currentState.currentPeriod.displayName}');

      final periodStats = await _repository.refreshPeriodStats(currentState.currentPeriod);

      print('✅ Refresh periodo completato');
      emit(currentState.copyWith(periodStats: periodStats));

    } on StatsException catch (e) {
      print('❌ Errore nel refresh periodo: ${e.message}');
    } catch (e) {
      print('❌ Errore generico nel refresh periodo: $e');
    }
  }

  // ============================================================================
  // 📊 UTILITY METHODS
  // ============================================================================

  StatsPeriod get currentPeriod {
    if (state is StatsLoaded) {
      return (state as StatsLoaded).currentPeriod;
    }
    return StatsPeriod.week;
  }

  bool get isPremium {
    if (state is StatsLoaded) {
      return (state as StatsLoaded).isPremium;
    }
    if (state is StatsPeriodLoading) {
      return (state as StatsPeriodLoading).isPremium;
    }
    return false;
  }

  bool get hasData {
    return state is StatsLoaded;
  }

  UserStatsResponse? get userStats {
    if (state is StatsLoaded) {
      return (state as StatsLoaded).userStats;
    }
    if (state is StatsPeriodLoading) {
      return (state as StatsPeriodLoading).userStats;
    }
    return null;
  }

  PeriodStatsResponse? get periodStats {
    if (state is StatsLoaded) {
      return (state as StatsLoaded).periodStats;
    }
    return null;
  }
}