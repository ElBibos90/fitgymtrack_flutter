// lib/features/payments/bloc/stripe_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;
import '../repository/stripe_repository.dart';
import '../services/stripe_service.dart';
import '../models/stripe_models.dart';
import '../../../core/utils/result.dart';

// ============================================================================
// EVENTS
// ============================================================================

abstract class StripeEvent extends Equatable {
  const StripeEvent();

  @override
  List<Object?> get props => [];
}

class InitializeStripeEvent extends StripeEvent {
  const InitializeStripeEvent();
}

class CreateSubscriptionPaymentEvent extends StripeEvent {
  final String priceId;
  final Map<String, dynamic>? metadata;

  const CreateSubscriptionPaymentEvent({
    required this.priceId,
    this.metadata,
  });

  @override
  List<Object?> get props => [priceId, metadata];
}

class CreateDonationPaymentEvent extends StripeEvent {
  final int amount; // in centesimi
  final Map<String, dynamic>? metadata;

  const CreateDonationPaymentEvent({
    required this.amount,
    this.metadata,
  });

  @override
  List<Object?> get props => [amount, metadata];
}

class ProcessPaymentEvent extends StripeEvent {
  final String clientSecret;
  final String paymentType; // 'subscription' o 'donation'

  const ProcessPaymentEvent({
    required this.clientSecret,
    required this.paymentType,
  });

  @override
  List<Object?> get props => [clientSecret, paymentType];
}

class ConfirmPaymentSuccessEvent extends StripeEvent {
  final String paymentIntentId;
  final String subscriptionType;

  const ConfirmPaymentSuccessEvent({
    required this.paymentIntentId,
    required this.subscriptionType,
  });

  @override
  List<Object?> get props => [paymentIntentId, subscriptionType];
}

class LoadCurrentSubscriptionEvent extends StripeEvent {
  const LoadCurrentSubscriptionEvent();
}

class CancelSubscriptionEvent extends StripeEvent {
  final String subscriptionId;
  final bool immediately;

  const CancelSubscriptionEvent({
    required this.subscriptionId,
    this.immediately = false,
  });

  @override
  List<Object?> get props => [subscriptionId, immediately];
}

class ReactivateSubscriptionEvent extends StripeEvent {
  final String subscriptionId;

  const ReactivateSubscriptionEvent({required this.subscriptionId});

  @override
  List<Object?> get props => [subscriptionId];
}

class LoadPaymentMethodsEvent extends StripeEvent {
  const LoadPaymentMethodsEvent();
}

class DeletePaymentMethodEvent extends StripeEvent {
  final String paymentMethodId;

  const DeletePaymentMethodEvent({required this.paymentMethodId});

  @override
  List<Object?> get props => [paymentMethodId];
}

class SyncSubscriptionStatusEvent extends StripeEvent {
  const SyncSubscriptionStatusEvent();
}

class ResetStripeStateEvent extends StripeEvent {
  const ResetStripeStateEvent();
}

// ============================================================================
// STATES
// ============================================================================

abstract class StripeState extends Equatable {
  const StripeState();

  @override
  List<Object?> get props => [];
}

class StripeInitial extends StripeState {
  const StripeInitial();
}

class StripeInitializing extends StripeState {
  const StripeInitializing();
}

class StripeReady extends StripeState {
  final StripeCustomer? customer;
  final StripeSubscription? subscription;
  final List<StripePaymentMethod> paymentMethods;

  const StripeReady({
    this.customer,
    this.subscription,
    this.paymentMethods = const [],
  });

  @override
  List<Object?> get props => [customer, subscription, paymentMethods];

  StripeReady copyWith({
    StripeCustomer? customer,
    StripeSubscription? subscription,
    List<StripePaymentMethod>? paymentMethods,
  }) {
    return StripeReady(
      customer: customer ?? this.customer,
      subscription: subscription ?? this.subscription,
      paymentMethods: paymentMethods ?? this.paymentMethods,
    );
  }
}

class StripePaymentLoading extends StripeState {
  final String paymentType;
  final String? message;

  const StripePaymentLoading({
    required this.paymentType,
    this.message,
  });

  @override
  List<Object?> get props => [paymentType, message];
}

class StripePaymentReady extends StripeState {
  final StripePaymentIntentResponse paymentIntent;
  final String paymentType;

  const StripePaymentReady({
    required this.paymentIntent,
    required this.paymentType,
  });

  @override
  List<Object?> get props => [paymentIntent, paymentType];
}

class StripePaymentSuccess extends StripeState {
  final String paymentIntentId;
  final String paymentType;
  final String message;

  const StripePaymentSuccess({
    required this.paymentIntentId,
    required this.paymentType,
    required this.message,
  });

  @override
  List<Object?> get props => [paymentIntentId, paymentType, message];
}

class StripeSubscriptionUpdated extends StripeState {
  final StripeSubscription subscription;
  final String message;

  const StripeSubscriptionUpdated({
    required this.subscription,
    required this.message,
  });

  @override
  List<Object?> get props => [subscription, message];
}

class StripePaymentMethodsLoaded extends StripeState {
  final List<StripePaymentMethod> paymentMethods;

  const StripePaymentMethodsLoaded({required this.paymentMethods});

  @override
  List<Object?> get props => [paymentMethods];
}

class StripeErrorState extends StripeState {
  final String message;
  final String? errorCode;
  final StripeErrorModel? stripeError;

  const StripeErrorState({
    required this.message,
    this.errorCode,
    this.stripeError,
  });

  @override
  List<Object?> get props => [message, errorCode, stripeError];
}

class StripeOperationSuccess extends StripeState {
  final String message;
  final String operation;

  const StripeOperationSuccess({
    required this.message,
    required this.operation,
  });

  @override
  List<Object?> get props => [message, operation];
}

// ============================================================================
// BLOC
// ============================================================================

class StripeBloc extends Bloc<StripeEvent, StripeState> {
  final StripeRepository _repository;
  StripeCustomer? _currentCustomer;
  StripeSubscription? _currentSubscription;
  List<StripePaymentMethod> _paymentMethods = [];

  StripeBloc({required StripeRepository repository})
      : _repository = repository,
        super(const StripeInitial()) {
    on<InitializeStripeEvent>(_onInitializeStripe);
    on<CreateSubscriptionPaymentEvent>(_onCreateSubscriptionPayment);
    on<CreateDonationPaymentEvent>(_onCreateDonationPayment);
    on<ProcessPaymentEvent>(_onProcessPayment);
    on<ConfirmPaymentSuccessEvent>(_onConfirmPaymentSuccess);
    on<LoadCurrentSubscriptionEvent>(_onLoadCurrentSubscription);
    on<CancelSubscriptionEvent>(_onCancelSubscription);
    on<ReactivateSubscriptionEvent>(_onReactivateSubscription);
    on<LoadPaymentMethodsEvent>(_onLoadPaymentMethods);
    on<DeletePaymentMethodEvent>(_onDeletePaymentMethod);
    on<SyncSubscriptionStatusEvent>(_onSyncSubscriptionStatus);
    on<ResetStripeStateEvent>(_onResetStripeState);
  }

  /// Inizializza Stripe
  Future<void> _onInitializeStripe(
      InitializeStripeEvent event,
      Emitter<StripeState> emit,
      ) async {
    developer.log('🔧 [STRIPE BLOC] Initializing Stripe...', name: 'StripeBloc');
    emit(const StripeInitializing());

    try {
      // Inizializza Stripe SDK
      final initResult = await StripeService.initialize();

      if (initResult.isFailure) {
        emit(StripeErrorState(message: initResult.message ?? 'Errore inizializzazione Stripe'));
        return;
      }

      // Ottieni o crea customer
      final customerResult = await _repository.getOrCreateCustomer();

      if (customerResult.isSuccess) {
        _currentCustomer = customerResult.data!;
        developer.log('✅ [STRIPE BLOC] Customer loaded: ${_currentCustomer!.id}', name: 'StripeBloc');
      }

      // Carica subscription corrente
      final subscriptionResult = await _repository.getCurrentSubscription();

      if (subscriptionResult.isSuccess) {
        _currentSubscription = subscriptionResult.data;
        if (_currentSubscription != null) {
          developer.log('✅ [STRIPE BLOC] Subscription loaded: ${_currentSubscription!.id}', name: 'StripeBloc');
        }
      }

      emit(StripeReady(
        customer: _currentCustomer,
        subscription: _currentSubscription,
        paymentMethods: _paymentMethods,
      ));

      developer.log('✅ [STRIPE BLOC] Stripe initialized successfully', name: 'StripeBloc');

    } catch (e) {
      developer.log('❌ [STRIPE BLOC] Initialization error: $e', name: 'StripeBloc');
      emit(StripeErrorState(message: 'Errore inizializzazione: $e'));
    }
  }

  /// Crea Payment Intent per subscription
  Future<void> _onCreateSubscriptionPayment(
      CreateSubscriptionPaymentEvent event,
      Emitter<StripeState> emit,
      ) async {
    developer.log('🔧 [STRIPE BLOC] Creating subscription payment...', name: 'StripeBloc');
    emit(const StripePaymentLoading(
      paymentType: 'subscription',
      message: 'Preparazione pagamento...',
    ));

    try {
      final result = await _repository.createSubscriptionPaymentIntent(
        priceId: event.priceId,
        metadata: event.metadata,
      );

      result.fold(
        onSuccess: (paymentIntent) {
          developer.log('✅ [STRIPE BLOC] Subscription payment intent created', name: 'StripeBloc');
          emit(StripePaymentReady(
            paymentIntent: paymentIntent,
            paymentType: 'subscription',
          ));
        },
        onFailure: (exception, message) {
          developer.log('❌ [STRIPE BLOC] Payment intent creation failed: $message', name: 'StripeBloc');
          emit(StripeErrorState(message: message ?? 'Errore creazione pagamento'));
        },
      );

    } catch (e) {
      developer.log('❌ [STRIPE BLOC] Payment creation error: $e', name: 'StripeBloc');
      emit(StripeErrorState(message: 'Errore imprevisto: $e'));
    }
  }

  /// Crea Payment Intent per donazione
  Future<void> _onCreateDonationPayment(
      CreateDonationPaymentEvent event,
      Emitter<StripeState> emit,
      ) async {
    developer.log('🔧 [STRIPE BLOC] Creating donation payment...', name: 'StripeBloc');
    emit(const StripePaymentLoading(
      paymentType: 'donation',
      message: 'Preparazione donazione...',
    ));

    try {
      final result = await _repository.createDonationPaymentIntent(
        amount: event.amount,
        metadata: event.metadata,
      );

      result.fold(
        onSuccess: (paymentIntent) {
          developer.log('✅ [STRIPE BLOC] Donation payment intent created', name: 'StripeBloc');
          emit(StripePaymentReady(
            paymentIntent: paymentIntent,
            paymentType: 'donation',
          ));
        },
        onFailure: (exception, message) {
          developer.log('❌ [STRIPE BLOC] Donation payment creation failed: $message', name: 'StripeBloc');
          emit(StripeErrorState(message: message ?? 'Errore creazione donazione'));
        },
      );

    } catch (e) {
      developer.log('❌ [STRIPE BLOC] Donation creation error: $e', name: 'StripeBloc');
      emit(StripeErrorState(message: 'Errore imprevisto: $e'));
    }
  }

  /// Processa il pagamento tramite Payment Sheet
  Future<void> _onProcessPayment(
      ProcessPaymentEvent event,
      Emitter<StripeState> emit,
      ) async {
    developer.log('🔧 [STRIPE BLOC] Processing payment...', name: 'StripeBloc');
    emit(StripePaymentLoading(
      paymentType: event.paymentType,
      message: 'Elaborazione pagamento...',
    ));

    try {
      final result = await StripeService.presentPaymentSheet(
        clientSecret: event.clientSecret,
        customerId: _currentCustomer?.id,
      );

      result.fold(
        onSuccess: (paymentOption) {
          developer.log('✅ [STRIPE BLOC] Payment Sheet completed successfully', name: 'StripeBloc');

          // 🔧 FIX: Extract payment intent ID correctly
          final paymentIntentId = _extractPaymentIntentId(event.clientSecret);

          // 🔧 FIX: Emit success immediately without backend confirmation for now
          emit(StripePaymentSuccess(
            paymentIntentId: paymentIntentId,
            paymentType: event.paymentType,
            message: event.paymentType == 'subscription'
                ? 'Abbonamento attivato con successo!'
                : 'Grazie per la tua donazione!',
          ));

          // 🔧 Reload subscription after success
          add(const LoadCurrentSubscriptionEvent());
        },
        onFailure: (exception, message) {
          developer.log('❌ [STRIPE BLOC] Payment Sheet failed: $message', name: 'StripeBloc');
          emit(StripeErrorState(message: message ?? 'Pagamento fallito'));
        },
      );

    } catch (e) {
      developer.log('❌ [STRIPE BLOC] Payment processing error: $e', name: 'StripeBloc');
      emit(StripeErrorState(message: 'Errore elaborazione pagamento: $e'));
    }
  }

  /// Conferma il successo del pagamento
  Future<void> _onConfirmPaymentSuccess(
      ConfirmPaymentSuccessEvent event,
      Emitter<StripeState> emit,
      ) async {
    developer.log('🔧 [STRIPE BLOC] Confirming payment success...', name: 'StripeBloc');

    try {
      final result = await _repository.confirmPaymentSuccess(
        paymentIntentId: event.paymentIntentId,
        subscriptionType: event.subscriptionType,
      );

      result.fold(
        onSuccess: (success) {
          developer.log('✅ [STRIPE BLOC] Payment confirmed successfully', name: 'StripeBloc');

          // Ricarica la subscription se è un pagamento di abbonamento
          if (event.subscriptionType == 'subscription') {
            add(const LoadCurrentSubscriptionEvent());
          }

          emit(StripePaymentSuccess(
            paymentIntentId: event.paymentIntentId,
            paymentType: event.subscriptionType,
            message: event.subscriptionType == 'subscription'
                ? 'Abbonamento attivato con successo!'
                : 'Grazie per la tua donazione!',
          ));
        },
        onFailure: (exception, message) {
          developer.log('❌ [STRIPE BLOC] Payment confirmation failed: $message', name: 'StripeBloc');
          emit(StripeErrorState(message: message ?? 'Errore conferma pagamento'));
        },
      );

    } catch (e) {
      developer.log('❌ [STRIPE BLOC] Payment confirmation error: $e', name: 'StripeBloc');
      emit(StripeErrorState(message: 'Errore conferma pagamento: $e'));
    }
  }

  /// Carica la subscription corrente
  Future<void> _onLoadCurrentSubscription(
      LoadCurrentSubscriptionEvent event,
      Emitter<StripeState> emit,
      ) async {
    developer.log('🔧 [STRIPE BLOC] Loading current subscription...', name: 'StripeBloc');

    try {
      final result = await _repository.getCurrentSubscription();

      result.fold(
        onSuccess: (subscription) {
          _currentSubscription = subscription;
          developer.log('✅ [STRIPE BLOC] Subscription loaded', name: 'StripeBloc');

          if (state is StripeReady) {
            emit((state as StripeReady).copyWith(subscription: subscription));
          } else {
            emit(StripeReady(
              customer: _currentCustomer,
              subscription: subscription,
              paymentMethods: _paymentMethods,
            ));
          }
        },
        onFailure: (exception, message) {
          developer.log('❌ [STRIPE BLOC] Subscription loading failed: $message', name: 'StripeBloc');
          emit(StripeErrorState(message: message ?? 'Errore caricamento subscription'));
        },
      );

    } catch (e) {
      developer.log('❌ [STRIPE BLOC] Subscription loading error: $e', name: 'StripeBloc');
      emit(StripeErrorState(message: 'Errore caricamento subscription: $e'));
    }
  }

  /// Cancella subscription
  Future<void> _onCancelSubscription(
      CancelSubscriptionEvent event,
      Emitter<StripeState> emit,
      ) async {
    developer.log('🔧 [STRIPE BLOC] Canceling subscription...', name: 'StripeBloc');

    try {
      final result = await _repository.cancelSubscription(
        subscriptionId: event.subscriptionId,
        immediately: event.immediately,
      );

      result.fold(
        onSuccess: (success) {
          developer.log('✅ [STRIPE BLOC] Subscription canceled', name: 'StripeBloc');

          // Ricarica la subscription
          add(const LoadCurrentSubscriptionEvent());

          emit(StripeOperationSuccess(
            message: event.immediately
                ? 'Abbonamento cancellato immediatamente'
                : 'Abbonamento verrà cancellato a fine periodo',
            operation: 'cancel_subscription',
          ));
        },
        onFailure: (exception, message) {
          developer.log('❌ [STRIPE BLOC] Subscription cancellation failed: $message', name: 'StripeBloc');
          emit(StripeErrorState(message: message ?? 'Errore cancellazione subscription'));
        },
      );

    } catch (e) {
      developer.log('❌ [STRIPE BLOC] Subscription cancellation error: $e', name: 'StripeBloc');
      emit(StripeErrorState(message: 'Errore cancellazione subscription: $e'));
    }
  }

  /// Riattiva subscription
  Future<void> _onReactivateSubscription(
      ReactivateSubscriptionEvent event,
      Emitter<StripeState> emit,
      ) async {
    developer.log('🔧 [STRIPE BLOC] Reactivating subscription...', name: 'StripeBloc');

    try {
      final result = await _repository.reactivateSubscription(
        subscriptionId: event.subscriptionId,
      );

      result.fold(
        onSuccess: (subscription) {
          _currentSubscription = subscription;
          developer.log('✅ [STRIPE BLOC] Subscription reactivated', name: 'StripeBloc');

          emit(StripeSubscriptionUpdated(
            subscription: subscription,
            message: 'Abbonamento riattivato con successo!',
          ));
        },
        onFailure: (exception, message) {
          developer.log('❌ [STRIPE BLOC] Subscription reactivation failed: $message', name: 'StripeBloc');
          emit(StripeErrorState(message: message ?? 'Errore riattivazione subscription'));
        },
      );

    } catch (e) {
      developer.log('❌ [STRIPE BLOC] Subscription reactivation error: $e', name: 'StripeBloc');
      emit(StripeErrorState(message: 'Errore riattivazione subscription: $e'));
    }
  }

  /// Carica metodi di pagamento
  Future<void> _onLoadPaymentMethods(
      LoadPaymentMethodsEvent event,
      Emitter<StripeState> emit,
      ) async {
    developer.log('🔧 [STRIPE BLOC] Loading payment methods...', name: 'StripeBloc');

    try {
      final result = await _repository.getPaymentMethods();

      result.fold(
        onSuccess: (paymentMethods) {
          _paymentMethods = paymentMethods;
          developer.log('✅ [STRIPE BLOC] Payment methods loaded', name: 'StripeBloc');

          emit(StripePaymentMethodsLoaded(paymentMethods: paymentMethods));
        },
        onFailure: (exception, message) {
          developer.log('❌ [STRIPE BLOC] Payment methods loading failed: $message', name: 'StripeBloc');
          emit(StripeErrorState(message: message ?? 'Errore caricamento metodi di pagamento'));
        },
      );

    } catch (e) {
      developer.log('❌ [STRIPE BLOC] Payment methods loading error: $e', name: 'StripeBloc');
      emit(StripeErrorState(message: 'Errore caricamento metodi di pagamento: $e'));
    }
  }

  /// Elimina metodo di pagamento
  Future<void> _onDeletePaymentMethod(
      DeletePaymentMethodEvent event,
      Emitter<StripeState> emit,
      ) async {
    developer.log('🔧 [STRIPE BLOC] Deleting payment method...', name: 'StripeBloc');

    try {
      final result = await _repository.deletePaymentMethod(
        paymentMethodId: event.paymentMethodId,
      );

      result.fold(
        onSuccess: (success) {
          developer.log('✅ [STRIPE BLOC] Payment method deleted', name: 'StripeBloc');

          // Ricarica metodi di pagamento
          add(const LoadPaymentMethodsEvent());

          emit(const StripeOperationSuccess(
            message: 'Metodo di pagamento eliminato',
            operation: 'delete_payment_method',
          ));
        },
        onFailure: (exception, message) {
          developer.log('❌ [STRIPE BLOC] Payment method deletion failed: $message', name: 'StripeBloc');
          emit(StripeErrorState(message: message ?? 'Errore eliminazione metodo di pagamento'));
        },
      );

    } catch (e) {
      developer.log('❌ [STRIPE BLOC] Payment method deletion error: $e', name: 'StripeBloc');
      emit(StripeErrorState(message: 'Errore eliminazione metodo di pagamento: $e'));
    }
  }

  /// Sincronizza status subscription
  Future<void> _onSyncSubscriptionStatus(
      SyncSubscriptionStatusEvent event,
      Emitter<StripeState> emit,
      ) async {
    developer.log('🔧 [STRIPE BLOC] Syncing subscription status...', name: 'StripeBloc');

    try {
      final result = await _repository.syncSubscriptionStatus();

      result.fold(
        onSuccess: (success) {
          developer.log('✅ [STRIPE BLOC] Subscription status synced', name: 'StripeBloc');

          // Ricarica la subscription
          add(const LoadCurrentSubscriptionEvent());

          emit(const StripeOperationSuccess(
            message: 'Stato abbonamento sincronizzato',
            operation: 'sync_subscription',
          ));
        },
        onFailure: (exception, message) {
          developer.log('❌ [STRIPE BLOC] Subscription sync failed: $message', name: 'StripeBloc');
          emit(StripeErrorState(message: message ?? 'Errore sincronizzazione'));
        },
      );

    } catch (e) {
      developer.log('❌ [STRIPE BLOC] Subscription sync error: $e', name: 'StripeBloc');
      emit(StripeErrorState(message: 'Errore sincronizzazione: $e'));
    }
  }

  /// Reset stato
  void _onResetStripeState(
      ResetStripeStateEvent event,
      Emitter<StripeState> emit,
      ) {
    developer.log('🔧 [STRIPE BLOC] Resetting state...', name: 'StripeBloc');

    _currentCustomer = null;
    _currentSubscription = null;
    _paymentMethods = [];

    emit(const StripeInitial());
  }

  /// Helper per estrarre Payment Intent ID dal client secret
  String _extractPaymentIntentId(String clientSecret) {
    return clientSecret.split('_secret_')[0];
  }

  /// Getter per i dati correnti
  StripeCustomer? get currentCustomer => _currentCustomer;
  StripeSubscription? get currentSubscription => _currentSubscription;
  List<StripePaymentMethod> get paymentMethods => _paymentMethods;

  /// Verifica se l'utente ha una subscription attiva
  bool get hasActiveSubscription =>
      _currentSubscription?.isActive ?? false;

  /// Verifica se la subscription sta per scadere
  bool get isSubscriptionExpiring =>
      _currentSubscription?.isExpiring ?? false;
}