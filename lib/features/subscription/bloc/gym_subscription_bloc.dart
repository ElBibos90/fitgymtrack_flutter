// lib/features/subscription/bloc/gym_subscription_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repository/gym_subscription_repository.dart';
import '../models/gym_subscription.dart';

// ============================================================================
// EVENTS
// ============================================================================

abstract class GymSubscriptionEvent extends Equatable {
  const GymSubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadGymSubscriptionEvent extends GymSubscriptionEvent {
  final int userId;
  final bool forceRefresh;

  const LoadGymSubscriptionEvent({
    required this.userId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [userId, forceRefresh];
}

class RefreshGymSubscriptionEvent extends GymSubscriptionEvent {
  final int userId;

  const RefreshGymSubscriptionEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// ============================================================================
// STATES
// ============================================================================

abstract class GymSubscriptionState extends Equatable {
  const GymSubscriptionState();

  @override
  List<Object?> get props => [];
}

class GymSubscriptionInitial extends GymSubscriptionState {}

class GymSubscriptionLoading extends GymSubscriptionState {
  final String loadingMessage;

  const GymSubscriptionLoading({this.loadingMessage = 'Caricamento abbonamento palestra...'});

  @override
  List<Object?> get props => [loadingMessage];
}

class GymSubscriptionLoaded extends GymSubscriptionState {
  final GymSubscription subscription;
  final DateTime loadedAt;

  const GymSubscriptionLoaded({
    required this.subscription,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [subscription, loadedAt];
}

class GymSubscriptionError extends GymSubscriptionState {
  final String message;
  final String? details;

  const GymSubscriptionError({
    required this.message,
    this.details,
  });

  @override
  List<Object?> get props => [message, details];
}

class GymSubscriptionNotFound extends GymSubscriptionState {
  final String message;

  const GymSubscriptionNotFound({this.message = 'Nessun abbonamento trovato'});

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// BLOC
// ============================================================================

class GymSubscriptionBloc extends Bloc<GymSubscriptionEvent, GymSubscriptionState> {
  final GymSubscriptionRepository _repository;

  // Cache per evitare chiamate multiple
  GymSubscription? _cachedSubscription;
  DateTime? _lastUpdate;
  bool _isLoading = false;

  GymSubscriptionBloc({
    required GymSubscriptionRepository repository,
  })  : _repository = repository,
        super(GymSubscriptionInitial()) {
    
    on<LoadGymSubscriptionEvent>(_onLoadGymSubscription);
    on<RefreshGymSubscriptionEvent>(_onRefreshGymSubscription);
  }

  /// Carica l'abbonamento palestra
  Future<void> _onLoadGymSubscription(
    LoadGymSubscriptionEvent event,
    Emitter<GymSubscriptionState> emit,
  ) async {
    try {
      //debugPrint('[CONSOLE] [gym_subscription_bloc] 🏋️ Loading gym subscription for user: ${event.userId}');

      // Controlla cache se non è force refresh
      if (!event.forceRefresh && _isCacheValid()) {
        //debugPrint('[CONSOLE] [gym_subscription_bloc] ⚡ Using cached gym subscription data');
        emit(GymSubscriptionLoaded(
          subscription: _cachedSubscription!,
          loadedAt: _lastUpdate!,
        ));
        return;
      }

      // Evita carichi multipli simultanei
      if (_isLoading) {
        //debugPrint('[CONSOLE] [gym_subscription_bloc] ⏳ Gym subscription loading already in progress');
        return;
      }

      _isLoading = true;
      emit(const GymSubscriptionLoading());

      final result = await _repository.getGymSubscription(event.userId);

      if (result.isSuccess) {
        _cachedSubscription = result.data;
        _lastUpdate = DateTime.now();
        
        //debugPrint('[CONSOLE] [gym_subscription_bloc] ✅ Gym subscription loaded: ${result.data!.gymName}');
        emit(GymSubscriptionLoaded(
          subscription: result.data!,
          loadedAt: _lastUpdate!,
        ));
      } else {
        final error = result.message ?? 'Errore sconosciuto';
        //debugPrint('[CONSOLE] [gym_subscription_bloc] ❌ Error loading gym subscription: $error');
        
        if (error.contains('Nessun abbonamento attivo')) {
          emit(const GymSubscriptionNotFound());
        } else {
          emit(GymSubscriptionError(message: error));
        }
      }
    } catch (e) {
      //debugPrint('[CONSOLE] [gym_subscription_bloc] ❌ Exception loading gym subscription: $e');
      emit(GymSubscriptionError(
        message: 'Errore nel caricamento abbonamento palestra',
        details: e.toString(),
      ));
    } finally {
      _isLoading = false;
    }
  }

  /// Aggiorna l'abbonamento palestra
  Future<void> _onRefreshGymSubscription(
    RefreshGymSubscriptionEvent event,
    Emitter<GymSubscriptionState> emit,
  ) async {
    add(LoadGymSubscriptionEvent(
      userId: event.userId,
      forceRefresh: true,
    ));
  }

  /// Verifica se la cache è valida (5 minuti)
  bool _isCacheValid() {
    if (_cachedSubscription == null || _lastUpdate == null) {
      return false;
    }
    
    final now = DateTime.now();
    final cacheAge = now.difference(_lastUpdate!);
    return cacheAge.inMinutes < 5;
  }

  /// Invalida la cache
  void invalidateCache() {
    _cachedSubscription = null;
    _lastUpdate = null;
    //debugPrint('[CONSOLE] [gym_subscription_bloc] 🧹 Cache invalidated');
  }
}
