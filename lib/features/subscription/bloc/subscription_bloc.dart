// lib/features/subscription/bloc/subscription_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../repository/subscription_repository.dart';
import '../models/subscription_models.dart';
import '../../../core/utils/result.dart';

// ============================================================================
// EVENTS
// ============================================================================

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubscriptionEvent extends SubscriptionEvent {
  final bool checkExpired;

  const LoadSubscriptionEvent({this.checkExpired = true});

  @override
  List<Object?> get props => [checkExpired];
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
  const LoadAvailablePlansEvent();
}

class DismissExpiredNotificationEvent extends SubscriptionEvent {
  const DismissExpiredNotificationEvent();
}

class DismissLimitNotificationEvent extends SubscriptionEvent {
  const DismissLimitNotificationEvent();
}

// ============================================================================
// STATES
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
  const SubscriptionLoading();
}

class SubscriptionLoaded extends SubscriptionState {
  final Subscription subscription;
  final List<SubscriptionPlan> availablePlans;
  final ResourceLimits? workoutLimits;
  final ResourceLimits? exerciseLimits;
  final bool showExpiredNotification;
  final bool showLimitNotification;
  final int? expiredCount;

  const SubscriptionLoaded({
    required this.subscription,
    this.availablePlans = const [],
    this.workoutLimits,
    this.exerciseLimits,
    this.showExpiredNotification = false,
    this.showLimitNotification = false,
    this.expiredCount,
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
  ];

  SubscriptionLoaded copyWith({
    Subscription? subscription,
    List<SubscriptionPlan>? availablePlans,
    ResourceLimits? workoutLimits,
    ResourceLimits? exerciseLimits,
    bool? showExpiredNotification,
    bool? showLimitNotification,
    int? expiredCount,
  }) {
    return SubscriptionLoaded(
      subscription: subscription ?? this.subscription,
      availablePlans: availablePlans ?? this.availablePlans,
      workoutLimits: workoutLimits ?? this.workoutLimits,
      exerciseLimits: exerciseLimits ?? this.exerciseLimits,
      showExpiredNotification: showExpiredNotification ?? this.showExpiredNotification,
      showLimitNotification: showLimitNotification ?? this.showLimitNotification,
      expiredCount: expiredCount ?? this.expiredCount,
    );
  }
}

class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError(this.message);

  @override
  List<Object?> get props => [message];
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
// BLOC
// ============================================================================

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository _repository;

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
  }

  /// 🔧 FIX: Carica l'abbonamento corrente con gestione async corretta
  Future<void> _onLoadSubscription(
      LoadSubscriptionEvent event,
      Emitter<SubscriptionState> emit,
      ) async {
    print('[CONSOLE]Caricamento abbonamento');
    emit(const SubscriptionLoading());

    try {
      // Controlla le scadenze se richiesto
      int? expiredCount;
      if (event.checkExpired) {
        final expiredResult = await _repository.checkExpiredSubscriptions();
        expiredResult.fold(
          onSuccess: (response) => expiredCount = response.updatedCount,
          onFailure: (exception, message) {
            print('[CONSOLE]Errore controllo scadenze: $message');
          },
        );
      }

      // 🔧 FIX: Carica l'abbonamento SENZA usare async dentro fold()
      final result = await _repository.getCurrentSubscription();

      // 🔧 FIX: Gestisci il risultato FUORI dal fold per evitare async issues
      if (result.isSuccess) {
        final subscription = result.data!;

        print('[CONSOLE]Abbonamento caricato: ${subscription.planName} - €${subscription.price}');

        // 🔧 FIX: Carica i piani disponibili SEPARATAMENTE
        final plansResult = await _repository.getAvailablePlans();
        final plans = plansResult.fold(
          onSuccess: (plans) => plans,
          onFailure: (exception, message) {
            print('[CONSOLE]Errore caricamento piani: $message');
            return <SubscriptionPlan>[];
          },
        );

        // Determina se mostrare notifica di scadenza
        final showExpiredNotification = subscription.isExpired ||
            (expiredCount != null && expiredCount! > 0);

        // 🔧 FIX: Controlla se l'emitter è ancora valido prima di emettere
        if (!emit.isDone) {
          emit(SubscriptionLoaded(
            subscription: subscription,
            availablePlans: plans,
            showExpiredNotification: showExpiredNotification,
            expiredCount: expiredCount,
          ));
        }
      } else {
        // Gestione errore
        final errorMessage = result.message ?? 'Errore nel caricamento dell\'abbonamento';
        print('[CONSOLE]Errore caricamento abbonamento: $errorMessage');

        if (!emit.isDone) {
          emit(SubscriptionError(errorMessage));
        }
      }
    } catch (e, stackTrace) {
      print('[CONSOLE]Eccezione caricamento abbonamento: $e');

      if (!emit.isDone) {
        emit(SubscriptionError('Errore imprevisto: $e'));
      }
    }
  }

  /// Controlla le subscription scadute manualmente
  Future<void> _onCheckExpiredSubscriptions(
      CheckExpiredSubscriptionsEvent event,
      Emitter<SubscriptionState> emit,
      ) async {
    if (state is! SubscriptionLoaded) return;

    final currentState = state as SubscriptionLoaded;

    try {
      final result = await _repository.checkExpiredSubscriptions();

      result.fold(
        onSuccess: (response) {
          if (response.updatedCount > 0 && !emit.isDone) {
            emit(currentState.copyWith(
              showExpiredNotification: true,
              expiredCount: response.updatedCount,
            ));

            // Ricarica l'abbonamento per aggiornare i dati
            add(const LoadSubscriptionEvent(checkExpired: false));
          }
        },
        onFailure: (exception, message) {
          print('[CONSOLE]Errore controllo scadenze: $message');
        },
      );
    } catch (e) {
      print('[CONSOLE]Eccezione controllo scadenze: $e');
    }
  }

  /// Verifica i limiti per un tipo di risorsa
  Future<void> _onCheckResourceLimits(
      CheckResourceLimitsEvent event,
      Emitter<SubscriptionState> emit,
      ) async {
    if (state is! SubscriptionLoaded) return;

    final currentState = state as SubscriptionLoaded;

    try {
      final result = await _repository.checkResourceLimits(event.resourceType);

      result.fold(
        onSuccess: (limits) {
          if (!emit.isDone) {
            ResourceLimits? workoutLimits = currentState.workoutLimits;
            ResourceLimits? exerciseLimits = currentState.exerciseLimits;

            if (event.resourceType == 'max_workouts') {
              workoutLimits = limits;
            } else if (event.resourceType == 'max_custom_exercises') {
              exerciseLimits = limits;
            }

            emit(currentState.copyWith(
              workoutLimits: workoutLimits,
              exerciseLimits: exerciseLimits,
              showLimitNotification: limits.limitReached,
            ));
          }
        },
        onFailure: (exception, message) {
          print('[CONSOLE]Errore verifica limiti: $message');
        },
      );
    } catch (e) {
      print('[CONSOLE]Eccezione verifica limiti: $e');
    }
  }

  /// 🔧 FIX: Aggiorna il piano di abbonamento con gestione async corretta
  Future<void> _onUpdatePlan(
      UpdatePlanEvent event,
      Emitter<SubscriptionState> emit,
      ) async {
    if (state is! SubscriptionLoaded) return;

    final currentState = state as SubscriptionLoaded;

    if (!emit.isDone) {
      emit(SubscriptionUpdating(currentState.subscription));
    }

    try {
      final result = await _repository.updatePlan(event.planId);

      if (result.isSuccess) {
        final response = result.data!;
        print('[CONSOLE]Piano aggiornato: ${response.planName}');

        // Ricarica l'abbonamento per ottenere i nuovi dati
        final subscriptionResult = await _repository.getCurrentSubscription();

        if (subscriptionResult.isSuccess && !emit.isDone) {
          final subscription = subscriptionResult.data!;

          emit(SubscriptionUpdateSuccess(
            subscription: subscription,
            message: response.message,
          ));

          // Torna allo stato caricato con i nuovi dati
          emit(currentState.copyWith(subscription: subscription));
        } else if (!emit.isDone) {
          emit(SubscriptionError(
              subscriptionResult.message ?? 'Errore dopo aggiornamento piano'
          ));
        }
      } else {
        final errorMessage = result.message ?? 'Errore nell\'aggiornamento del piano';
        print('[CONSOLE]Errore aggiornamento piano: $errorMessage');

        if (!emit.isDone) {
          emit(SubscriptionError(errorMessage));
          // Torna allo stato precedente
          emit(currentState);
        }
      }
    } catch (e) {
      print('[CONSOLE]Eccezione aggiornamento piano: $e');
      if (!emit.isDone) {
        emit(SubscriptionError('Errore imprevisto: $e'));
        emit(currentState);
      }
    }
  }

  /// Carica i piani disponibili
  Future<void> _onLoadAvailablePlans(
      LoadAvailablePlansEvent event,
      Emitter<SubscriptionState> emit,
      ) async {
    if (state is! SubscriptionLoaded) return;

    final currentState = state as SubscriptionLoaded;

    try {
      final result = await _repository.getAvailablePlans();

      result.fold(
        onSuccess: (plans) {
          if (!emit.isDone) {
            emit(currentState.copyWith(availablePlans: plans));
          }
        },
        onFailure: (exception, message) {
          print('[CONSOLE]Errore caricamento piani: $message');
        },
      );
    } catch (e) {
      print('[CONSOLE]Eccezione caricamento piani: $e');
    }
  }

  /// Dismisses la notifica di scadenza
  void _onDismissExpiredNotification(
      DismissExpiredNotificationEvent event,
      Emitter<SubscriptionState> emit,
      ) {
    if (state is SubscriptionLoaded && !emit.isDone) {
      final currentState = state as SubscriptionLoaded;
      emit(currentState.copyWith(showExpiredNotification: false));
    }
  }

  /// Dismisses la notifica di limite
  void _onDismissLimitNotification(
      DismissLimitNotificationEvent event,
      Emitter<SubscriptionState> emit,
      ) {
    if (state is SubscriptionLoaded && !emit.isDone) {
      final currentState = state as SubscriptionLoaded;
      emit(currentState.copyWith(showLimitNotification: false));
    }
  }

  /// Helper per verificare se l'utente può creare una scheda
  Future<bool> canCreateWorkout() async {
    try {
      final result = await _repository.canCreateWorkout();
      return result.fold(
        onSuccess: (canCreate) => canCreate,
        onFailure: (exception, message) {
          print('[CONSOLE]Errore verifica creazione scheda: $message');
          return true; // Default permissivo in caso di errore
        },
      );
    } catch (e) {
      print('[CONSOLE]Eccezione verifica creazione scheda: $e');
      return true;
    }
  }

  /// Helper per verificare se l'utente può creare un esercizio personalizzato
  Future<bool> canCreateCustomExercise() async {
    try {
      final result = await _repository.canCreateCustomExercise();
      return result.fold(
        onSuccess: (canCreate) => canCreate,
        onFailure: (exception, message) {
          print('[CONSOLE]Errore verifica creazione esercizio: $message');
          return true; // Default permissivo in caso di errore
        },
      );
    } catch (e) {
      print('[CONSOLE]Eccezione verifica creazione esercizio: $e');
      return true;
    }
  }
}