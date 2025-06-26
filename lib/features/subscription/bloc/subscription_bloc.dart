// lib/features/subscription/bloc/subscription_bloc.dart - VERSIONE OTTIMIZZATA
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../repository/subscription_repository.dart';
import '../models/subscription_models.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/api_request_debouncer.dart';

// ============================================================================
// EVENTS (mantenuti da codice esistente + aggiunti refresh event)
// ============================================================================

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubscriptionEvent extends SubscriptionEvent {
  final bool checkExpired;
  final bool forceRefresh; // 🚀 NUOVO: Per forzare refresh cache

  const LoadSubscriptionEvent({
    this.checkExpired = true,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [checkExpired, forceRefresh];
}

class CheckExpiredSubscriptionsEvent extends SubscriptionEvent {
  const CheckExpiredSubscriptionsEvent();
}

class CheckResourceLimitsEvent extends SubscriptionEvent {
  final String resourceType;

  const CheckResourceLimitsEvent(this.resourceType);

  @override
  List<Object?> get props => [resourceType];
}

class UpdatePlanEvent extends SubscriptionEvent {
  final int planId;

  const UpdatePlanEvent(this.planId);

  @override
  List<Object?> get props => [planId];
}

class LoadAvailablePlansEvent extends SubscriptionEvent {
  final bool forceRefresh; // 🚀 NUOVO: Per forzare refresh cache

  const LoadAvailablePlansEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class DismissExpiredNotificationEvent extends SubscriptionEvent {
  const DismissExpiredNotificationEvent();
}

class DismissLimitNotificationEvent extends SubscriptionEvent {
  const DismissLimitNotificationEvent();
}

class RefreshSubscriptionEvent extends SubscriptionEvent {
  const RefreshSubscriptionEvent();
}

class CancelSubscriptionEvent extends SubscriptionEvent {
  const CancelSubscriptionEvent();
}

// ============================================================================
// STATES (mantenuti da codice esistente + aggiunti nuovi)
// ============================================================================

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

class SubscriptionLoading extends SubscriptionState {
  final String? loadingMessage; // 🚀 NUOVO: Messaggio specifico

  const SubscriptionLoading({this.loadingMessage});

  @override
  List<Object?> get props => [loadingMessage];
}

class SubscriptionLoaded extends SubscriptionState {
  final Subscription subscription;
  final List<SubscriptionPlan> availablePlans;
  final ResourceLimits? workoutLimits;
  final ResourceLimits? exerciseLimits;
  final bool showExpiredNotification;
  final bool showLimitNotification;
  final int? expiredCount;
  final DateTime loadedAt; // 🚀 NUOVO: Timestamp per cache

  const SubscriptionLoaded({
    required this.subscription,
    this.availablePlans = const [],
    this.workoutLimits,
    this.exerciseLimits,
    this.showExpiredNotification = false,
    this.showLimitNotification = false,
    this.expiredCount,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [
    subscription,
    availablePlans,
    workoutLimits,
    exerciseLimits,
    showExpiredNotification,
    showLimitNotification,
    expiredCount,
    loadedAt,
  ];

  SubscriptionLoaded copyWith({
    Subscription? subscription,
    List<SubscriptionPlan>? availablePlans,
    ResourceLimits? workoutLimits,
    ResourceLimits? exerciseLimits,
    bool? showExpiredNotification,
    bool? showLimitNotification,
    int? expiredCount,
    DateTime? loadedAt,
  }) {
    return SubscriptionLoaded(
      subscription: subscription ?? this.subscription,
      availablePlans: availablePlans ?? this.availablePlans,
      workoutLimits: workoutLimits ?? this.workoutLimits,
      exerciseLimits: exerciseLimits ?? this.exerciseLimits,
      showExpiredNotification: showExpiredNotification ?? this.showExpiredNotification,
      showLimitNotification: showLimitNotification ?? this.showLimitNotification,
      expiredCount: expiredCount ?? this.expiredCount,
      loadedAt: loadedAt ?? this.loadedAt,
    );
  }
}

class SubscriptionError extends SubscriptionState {
  final String message;
  final Exception? exception; // 🚀 NUOVO: Per debugging

  const SubscriptionError({
    required this.message,
    this.exception,
  });

  @override
  List<Object?> get props => [message, exception];
}

class SubscriptionUpdating extends SubscriptionState {
  final Subscription currentSubscription;

  const SubscriptionUpdating(this.currentSubscription);

  @override
  List<Object?> get props => [currentSubscription];
}

class SubscriptionUpdateSuccess extends SubscriptionState {
  final Subscription subscription;
  final String message;

  const SubscriptionUpdateSuccess({
    required this.subscription,
    required this.message,
  });

  @override
  List<Object?> get props => [subscription, message];
}

// ============================================================================
// 🚀 PERFORMANCE OPTIMIZED SUBSCRIPTION BLOC
// ============================================================================

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository _repository;

  // 🚀 PERFORMANCE: Cache interno per evitare richieste duplicate
  Subscription? _cachedSubscription;
  List<SubscriptionPlan>? _cachedPlans;
  DateTime? _lastSubscriptionUpdate;
  DateTime? _lastPlansUpdate;

  // 🚀 PERFORMANCE: Durata cache
  static const Duration _subscriptionCacheDuration = Duration(minutes: 3);
  static const Duration _plansCacheDuration = Duration(minutes: 10);

  // 🚀 PERFORMANCE: Flag per evitare operazioni multiple simultanee
  bool _isLoadingSubscription = false;
  bool _isLoadingPlans = false;

  SubscriptionBloc({required SubscriptionRepository repository})
      : _repository = repository,
        super(const SubscriptionInitial()) {

    on<LoadSubscriptionEvent>(_onLoadSubscription);
    on<CheckExpiredSubscriptionsEvent>(_onCheckExpiredSubscriptions);
    on<CheckResourceLimitsEvent>(_onCheckResourceLimits);
    on<UpdatePlanEvent>(_onUpdatePlan);
    on<LoadAvailablePlansEvent>(_onLoadAvailablePlans);
    on<DismissExpiredNotificationEvent>(_onDismissExpiredNotification);
    on<DismissLimitNotificationEvent>(_onDismissLimitNotification);
    on<RefreshSubscriptionEvent>(_onRefreshSubscription);
    on<CancelSubscriptionEvent>(_onCancelSubscription);
  }

  // ============================================================================
  // 🚀 PERFORMANCE: Event Handlers Ottimizzati
  // ============================================================================

  /// 🚀 PERFORMANCE: Carica subscription con cache intelligente
  Future<void> _onLoadSubscription(
      LoadSubscriptionEvent event,
      Emitter<SubscriptionState> emit,
      ) async {
    try {
      print('[CONSOLE] [subscription_bloc]💳 Loading subscription...');

      // 🚀 PERFORMANCE: Controlla cache se non è force refresh
      if (!event.forceRefresh && _isSubscriptionCacheValid()) {
        print('[CONSOLE] [subscription_bloc]⚡ Using cached subscription data');
        emit(SubscriptionLoaded(
          subscription: _cachedSubscription!,
          availablePlans: _cachedPlans ?? [],
          loadedAt: _lastSubscriptionUpdate!,
        ));
        return;
      }

      // 🚀 PERFORMANCE: Evita carichi multipli simultanei
      if (_isLoadingSubscription) {
        print('[CONSOLE] [subscription_bloc]⏳ Subscription loading already in progress');
        return;
      }

      _isLoadingSubscription = true;
      emit(const SubscriptionLoading(loadingMessage: 'Caricamento abbonamento...'));

      // 🚀 PERFORMANCE: Usa debouncer per evitare duplicate API calls
      await ApiRequestDebouncer.debounceRequest<void>(
        key: 'subscription_current_subscription',
        request: () async {
          // Check expired solo se richiesto
          if (event.checkExpired) {
            await _checkExpiredSubscriptions();
          }
        },
      );

      final subscriptionResult = await _repository.getCurrentSubscription();
      subscriptionResult.fold(
        onSuccess: (subscription) {
          _cachedSubscription = subscription;
          _lastSubscriptionUpdate = DateTime.now();

          // Carica anche i piani se non li abbiamo
          if (_cachedPlans == null || !_isPlansCacheValid()) {
            _loadPlansInBackground();
          }

          emit(SubscriptionLoaded(
            subscription: subscription,
            availablePlans: _cachedPlans ?? [],
            loadedAt: _lastSubscriptionUpdate!,
          ));

          print('[CONSOLE] [subscription_bloc]✅ Subscription loaded successfully');
        },
        onFailure: (exception, message) {
          print('[CONSOLE] [subscription_bloc]❌ Error loading subscription: $message');
          emit(SubscriptionError(
            message: message ?? 'Errore nel caricamento dell\'abbonamento',
            exception: exception,
          ));
        },
      );

    } catch (e) {
      print('[CONSOLE] [subscription_bloc]❌ Error loading subscription: $e');
      emit(SubscriptionError(
        message: 'Errore nel caricamento dell\'abbonamento',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    } finally {
      _isLoadingSubscription = false;
    }
  }

  /// 🚀 PERFORMANCE: Carica piani con cache intelligente
  Future<void> _onLoadAvailablePlans(
      LoadAvailablePlansEvent event,
      Emitter<SubscriptionState> emit,
      ) async {
    try {
      print('[CONSOLE] [subscription_bloc]📋 Loading plans...');

      // 🚀 PERFORMANCE: Controlla cache
      if (!event.forceRefresh && _isPlansCacheValid()) {
        print('[CONSOLE] [subscription_bloc]⚡ Using cached plans data');
        return;
      }

      // 🚀 PERFORMANCE: Evita carichi multipli
      if (_isLoadingPlans) {
        print('[CONSOLE] [subscription_bloc]⏳ Plans loading already in progress');
        return;
      }

      _isLoadingPlans = true;

      // 🚀 PERFORMANCE: Usa debouncer
      final result = await ApiRequestDebouncer.debounceRequest<List<SubscriptionPlan>>(
        key: 'subscription_plans',
        request: () async {
          final plansResult = await _repository.getAvailablePlans();
          return plansResult.fold(
            onSuccess: (plans) => plans,
            onFailure: (exception, message) => throw Exception(message ?? 'Errore caricamento piani'),
          );
        },
        cacheDuration: _plansCacheDuration,
      );

      if (result != null) {
        _cachedPlans = result;
        _lastPlansUpdate = DateTime.now();

        // Aggiorna stato se abbiamo anche subscription
        if (state is SubscriptionLoaded) {
          final currentState = state as SubscriptionLoaded;
          emit(currentState.copyWith(
            availablePlans: result,
            loadedAt: DateTime.now(),
          ));
        }

        print('[CONSOLE] [subscription_bloc]✅ Plans loaded successfully: ${result.length} plans');
      }

    } catch (e) {
      print('[CONSOLE] [subscription_bloc]❌ Error loading plans: $e');
      emit(SubscriptionError(
        message: 'Errore nel caricamento dei piani',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    } finally {
      _isLoadingPlans = false;
    }
  }

  /// 🚀 PERFORMANCE: Carica piani in background senza bloccare UI
  Future<void> _loadPlansInBackground() async {
    Future.microtask(() async {
      try {
        if (_isLoadingPlans) return;

        _isLoadingPlans = true;
        print('[CONSOLE] [subscription_bloc]🔄 Loading plans in background...');

        final plansResult = await _repository.getAvailablePlans();
        plansResult.fold(
          onSuccess: (plans) {
            _cachedPlans = plans;
            _lastPlansUpdate = DateTime.now();
            print('[CONSOLE] [subscription_bloc]✅ Background plans load completed');
          },
          onFailure: (exception, message) {
            print('[CONSOLE] [subscription_bloc]❌ Background plans load error: $message');
          },
        );

      } catch (e) {
        print('[CONSOLE] [subscription_bloc]❌ Background plans load error: $e');
      } finally {
        _isLoadingPlans = false;
      }
    });
  }

  /// 🚀 PERFORMANCE: Check expired con debouncing
  Future<void> _checkExpiredSubscriptions() async {
    try {
      await ApiRequestDebouncer.debounceRequest<void>(
        key: 'check_expired_subscriptions',
        request: () async {
          final result = await _repository.checkExpiredSubscriptions();
          result.fold(
            onSuccess: (expiredCount) {
              print('[CONSOLE] [subscription_bloc]✅ Check expired completed: $expiredCount expired');
            },
            onFailure: (exception, message) {
              print('[CONSOLE] [subscription_bloc]⚠️ Check expired error: $message');
            },
          );
        },
        delay: const Duration(milliseconds: 1000), // Delay più lungo per check expired
      );
    } catch (e) {
      print('[CONSOLE] [subscription_bloc]⚠️ Check expired error: $e');
      // Non bloccare il flow principale per errori di check expired
    }
  }

  // ============================================================================
  // Handlers dal codice esistente (mantenuti invariati)
  // ============================================================================

  Future<void> _onCheckExpiredSubscriptions(
      CheckExpiredSubscriptionsEvent event,
      Emitter<SubscriptionState> emit,
      ) async {
    await _checkExpiredSubscriptions();
  }

  Future<void> _onCheckResourceLimits(
      CheckResourceLimitsEvent event,
      Emitter<SubscriptionState> emit,
      ) async {
    try {
      final result = await _repository.checkResourceLimits(event.resourceType);

      result.fold(
        onSuccess: (limits) {
          if (state is SubscriptionLoaded) {
            final currentState = state as SubscriptionLoaded;

            if (event.resourceType == 'workout') {
              emit(currentState.copyWith(workoutLimits: limits));
            } else if (event.resourceType == 'exercise') {
              emit(currentState.copyWith(exerciseLimits: limits));
            }
          }
        },
        onFailure: (exception, message) {
          emit(SubscriptionError(message: message ?? 'Errore controllo limiti'));
        },
      );
    } catch (e) {
      emit(SubscriptionError(message: 'Errore controllo limiti: $e'));
    }
  }

  /// Update plan
  Future<void> _onUpdatePlan(
      UpdatePlanEvent event,
      Emitter<SubscriptionState> emit,
      ) async {
    try {
      if (state is SubscriptionLoaded) {
        final currentState = state as SubscriptionLoaded;
        emit(SubscriptionUpdating(currentState.subscription));
      }

      final result = await _repository.updatePlan(event.planId);

      result.fold(
        onSuccess: (updateResponse) {
          // Invalida cache
          _invalidateCache();

          emit(SubscriptionUpdateSuccess(
            subscription: _cachedSubscription!, // Usa la subscription cached esistente
            message: updateResponse.message,
          ));

          // Ricarica dati per ottenere la subscription aggiornata
          add(const LoadSubscriptionEvent(forceRefresh: true));
        },
        onFailure: (exception, message) {
          emit(SubscriptionError(
            message: message ?? 'Errore nell\'attivazione dell\'abbonamento',
            exception: exception,
          ));
        },
      );
    } catch (e) {
      emit(SubscriptionError(
        message: 'Errore nell\'attivazione dell\'abbonamento',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Cancel subscription
  Future<void> _onCancelSubscription(
      CancelSubscriptionEvent event,
      Emitter<SubscriptionState> emit,
      ) async {
    try {
      emit(const SubscriptionLoading(loadingMessage: 'Cancellazione abbonamento...'));

      // Per ora simuliamo la cancellazione
      await Future.delayed(const Duration(seconds: 1));

      // Invalida cache
      _invalidateCache();

      emit(SubscriptionUpdateSuccess(
        subscription: Subscription(
          id: 0,
          userId: 0,
          planId: 1,
          planName: 'Free',
          status: 'cancelled',
          price: 0.0,
          maxWorkouts: 3,
          maxCustomExercises: 5,
          currentCount: 0,
          currentCustomExercises: 0,
          advancedStats: false,
          cloudBackup: false,
          noAds: false,
          startDate: '',
          endDate: null,
          daysRemaining: null,
          computedStatus: 'cancelled',
        ),
        message: 'Abbonamento cancellato con successo',
      ));

      // Ricarica dati
      add(const LoadSubscriptionEvent(forceRefresh: true));

    } catch (e) {
      emit(SubscriptionError(
        message: 'Errore nella cancellazione dell\'abbonamento',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Refresh subscription
  Future<void> _onRefreshSubscription(
      RefreshSubscriptionEvent event,
      Emitter<SubscriptionState> emit,
      ) async {
    _invalidateCache();
    add(const LoadSubscriptionEvent(forceRefresh: true));
    add(const LoadAvailablePlansEvent(forceRefresh: true));
  }

  void _onDismissExpiredNotification(
      DismissExpiredNotificationEvent event,
      Emitter<SubscriptionState> emit,
      ) {
    if (state is SubscriptionLoaded) {
      final currentState = state as SubscriptionLoaded;
      emit(currentState.copyWith(showExpiredNotification: false));
    }
  }

  void _onDismissLimitNotification(
      DismissLimitNotificationEvent event,
      Emitter<SubscriptionState> emit,
      ) {
    if (state is SubscriptionLoaded) {
      final currentState = state as SubscriptionLoaded;
      emit(currentState.copyWith(showLimitNotification: false));
    }
  }

  // ============================================================================
  // 🚀 PERFORMANCE: Cache Management
  // ============================================================================

  bool _isSubscriptionCacheValid() {
    return _cachedSubscription != null &&
        _lastSubscriptionUpdate != null &&
        DateTime.now().difference(_lastSubscriptionUpdate!) < _subscriptionCacheDuration;
  }

  bool _isPlansCacheValid() {
    return _cachedPlans != null &&
        _lastPlansUpdate != null &&
        DateTime.now().difference(_lastPlansUpdate!) < _plansCacheDuration;
  }

  void _invalidateCache() {
    _cachedSubscription = null;
    _cachedPlans = null;
    _lastSubscriptionUpdate = null;
    _lastPlansUpdate = null;
    ApiRequestDebouncer.clearCache('subscription');
    print('[CONSOLE] [subscription_bloc]🗑️ Cache invalidated');
  }

  @override
  Future<void> close() {
    // Cleanup debouncer per subscription
    ApiRequestDebouncer.clearCache('subscription');
    return super.close();
  }
}