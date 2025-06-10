// lib/features/payments/bloc/stripe_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../repository/stripe_repository.dart';
import '../services/stripe_service.dart';
import '../models/stripe_models.dart';
import '../../../core/utils/result.dart';

// ============================================================================
// EVENTS (unchanged)
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
  final bool afterPayment; // 🚀 NUOVO: Indica se è dopo un pagamento

  const LoadCurrentSubscriptionEvent({this.afterPayment = false});

  @override
  List<Object?> get props => [afterPayment];
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
// STATES (unchanged)
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
// BLOC - VERSIONE FINALE CON SMART POST-PAYMENT HANDLING
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
    print('[CONSOLE]🔧 [STRIPE BLOC] Initializing Stripe...');
    emit(const StripeInitializing());

    try {
      // Inizializza Stripe SDK
      final initResult = await StripeService.initialize();

      if (initResult.isFailure) {
        emit(StripeErrorState(message: initResult.message ?? 'Errore inizializzazione Stripe'));
        return;
      }

      // Ottieni o crea customer con retry per evitare duplicati
      final customerResult = await _getOrCreateCustomerWithRetry();

      if (customerResult.isSuccess) {
        _currentCustomer = customerResult.data!;
        print('[CONSOLE]✅ [STRIPE BLOC] Customer loaded: ${_currentCustomer!.id}');
      }

      // Carica subscription corrente
      final subscriptionResult = await _repository.getCurrentSubscription();

      if (subscriptionResult.isSuccess) {
        _currentSubscription = subscriptionResult.data;
        if (_currentSubscription != null) {
          print('[CONSOLE]✅ [STRIPE BLOC] Subscription loaded: ${_currentSubscription!.id}');
        }
      }

      emit(StripeReady(
        customer: _currentCustomer,
        subscription: _currentSubscription,
        paymentMethods: _paymentMethods,
      ));

      print('[CONSOLE]✅ [STRIPE BLOC] Stripe initialized successfully');

    } catch (e) {
      print('[CONSOLE]❌ [STRIPE BLOC] Initialization error: $e');
      emit(StripeErrorState(message: 'Errore inizializzazione: $e'));
    }
  }

  /// Ottieni customer con retry per evitare duplicati
  Future<Result<StripeCustomer>> _getOrCreateCustomerWithRetry() async {
    print('[CONSOLE]🔧 [STRIPE BLOC] Getting customer with retry protection...');

    // Primo tentativo
    final firstResult = await _repository.getOrCreateCustomer();
    if (firstResult.isSuccess) {
      return firstResult;
    }

    // Attendi e riprova una volta in caso di race condition
    await Future.delayed(const Duration(milliseconds: 500));
    print('[CONSOLE]🔧 [STRIPE BLOC] Retrying customer creation...');

    final retryResult = await _repository.getOrCreateCustomer();
    return retryResult;
  }

  /// Crea Payment Intent per subscription (unchanged)
  Future<void> _onCreateSubscriptionPayment(
      CreateSubscriptionPaymentEvent event,
      Emitter<StripeState> emit,
      ) async {
    print('[CONSOLE]🔧 [STRIPE BLOC] Creating subscription payment...');
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
          print('[CONSOLE]✅ [STRIPE BLOC] Subscription payment intent created');
          emit(StripePaymentReady(
            paymentIntent: paymentIntent,
            paymentType: 'subscription',
          ));
        },
        onFailure: (exception, message) {
          print('[CONSOLE]❌ [STRIPE BLOC] Payment intent creation failed: $message');
          emit(StripeErrorState(message: message ?? 'Errore creazione pagamento'));
        },
      );

    } catch (e) {
      print('[CONSOLE]❌ [STRIPE BLOC] Payment creation error: $e');
      emit(StripeErrorState(message: 'Errore imprevisto: $e'));
    }
  }

  /// Crea Payment Intent per donazione (unchanged)
  Future<void> _onCreateDonationPayment(
      CreateDonationPaymentEvent event,
      Emitter<StripeState> emit,
      ) async {
    print('[CONSOLE]🔧 [STRIPE BLOC] Creating donation payment...');
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
          print('[CONSOLE]✅ [STRIPE BLOC] Donation payment intent created');
          emit(StripePaymentReady(
            paymentIntent: paymentIntent,
            paymentType: 'donation',
          ));
        },
        onFailure: (exception, message) {
          print('[CONSOLE]❌ [STRIPE BLOC] Donation payment creation failed: $message');
          emit(StripeErrorState(message: message ?? 'Errore creazione donazione'));
        },
      );

    } catch (e) {
      print('[CONSOLE]❌ [STRIPE BLOC] Donation creation error: $e');
      emit(StripeErrorState(message: 'Errore imprevisto: $e'));
    }
  }

  /// 🔧 FIX FINALE: Processa il pagamento tramite Payment Sheet con gestione CORRETTA del successo
  /// 🔧 FIX FINALE: Processa il pagamento tramite Payment Sheet con gestione CORRETTA del successo
  Future<void> _onProcessPayment(
      ProcessPaymentEvent event,
      Emitter<StripeState> emit,
      ) async {
    print('[CONSOLE]🔧 [STRIPE BLOC] Processing payment...');
    emit(StripePaymentLoading(
      paymentType: event.paymentType,
      message: 'Elaborazione pagamento...',
    ));

    try {
      final result = await StripeService.presentPaymentSheet(
        clientSecret: event.clientSecret,
        customerId: _currentCustomer?.id,
      );

      // 🔧 FIX CRITICO: Analizza correttamente il Result
      print('[CONSOLE]🔧 [STRIPE BLOC] Payment Sheet result: ${result.runtimeType}');
      print('[CONSOLE]🔧 [STRIPE BLOC] Result isSuccess: ${result.isSuccess}');
      print('[CONSOLE]🔧 [STRIPE BLOC] Result isFailure: ${result.isFailure}');

      if (result.isSuccess) {
        // ✅ SUCCESSO: Result è success significa che Payment Sheet è completato con successo
        final paymentOption = result.data;

        print('[CONSOLE]✅ [STRIPE BLOC] Payment Sheet completed successfully!');
        print('[CONSOLE]🔧 [STRIPE BLOC] Payment option data: $paymentOption');

        final paymentIntentId = _extractPaymentIntentId(event.clientSecret);

        print('[CONSOLE]✅ [STRIPE BLOC] Payment successful - extracted PI ID: $paymentIntentId');

        // 🚀 CRITICAL FIX: Chiama backend per confermare e sincronizzare DB
        print('[CONSOLE]🚀 [STRIPE BLOC] Calling backend to confirm payment and sync database...');

        try {
          final confirmResult = await _repository.confirmPaymentSuccess(
            paymentIntentId: paymentIntentId,
            subscriptionType: event.paymentType,
          );

          if (confirmResult.isSuccess) {
            print('[CONSOLE]✅ [STRIPE BLOC] Backend confirmation successful - database updated!');

            // Emetti successo solo DOPO conferma backend
            emit(StripePaymentSuccess(
              paymentIntentId: paymentIntentId,
              paymentType: event.paymentType,
              message: event.paymentType == 'subscription'
                  ? 'Abbonamento attivato con successo!'
                  : 'Grazie per la tua donazione!',
            ));

            // 🚀 Refresh intelligente dei dati dopo conferma backend
            if (event.paymentType == 'subscription') {
              print('[CONSOLE]🚀 [STRIPE BLOC] Payment confirmed - loading subscription with post-payment retry');
              add(const LoadCurrentSubscriptionEvent(afterPayment: true));
            }

            _refreshCustomerData();

          } else {
            print('[CONSOLE]❌ [STRIPE BLOC] Backend confirmation failed: ${confirmResult.message}');

            // Payment Sheet è riuscito ma backend ha fallito - mostra warning
            emit(StripePaymentSuccess(
              paymentIntentId: paymentIntentId,
              paymentType: event.paymentType,
              message: 'Pagamento completato. Sincronizzazione in corso...',
            ));

            // Prova comunque a ricaricare
            if (event.paymentType == 'subscription') {
              add(const LoadCurrentSubscriptionEvent(afterPayment: true));
            }
          }

        } catch (confirmError) {
          print('[CONSOLE]❌ [STRIPE BLOC] Backend confirmation error: $confirmError');

          // Payment Sheet è riuscito ma backend non risponde - mostra warning
          emit(StripePaymentSuccess(
            paymentIntentId: paymentIntentId,
            paymentType: event.paymentType,
            message: 'Pagamento completato. Verifica in corso...',
          ));

          // Prova comunque a ricaricare dopo un delay
          Future.delayed(const Duration(seconds: 3), () {
            if (!isClosed) {
              if (event.paymentType == 'subscription') {
                add(const LoadCurrentSubscriptionEvent(afterPayment: true));
              }
            }
          });
        }

      } else {
        // ❌ ERRORE: Result è failure significa che c'è stato un vero errore
        final errorMessage = result.message ?? 'Pagamento fallito';

        print('[CONSOLE]❌ [STRIPE BLOC] Payment Sheet failed with error: $errorMessage');

        // Gestione errori specifici
        if (errorMessage.toLowerCase().contains('cancel') ||
            errorMessage.toLowerCase().contains('user_cancel')) {
          emit(const StripeErrorState(message: 'Pagamento annullato dall\'utente'));
        } else {
          emit(StripeErrorState(message: errorMessage));
        }
      }

    } catch (e) {
      print('[CONSOLE]❌ [STRIPE BLOC] Payment processing exception: $e');
      emit(StripeErrorState(message: 'Errore elaborazione pagamento: $e'));
    }
  }

  /// Aggiorna i dati del customer dopo il pagamento
  Future<void> _refreshCustomerData() async {
    try {
      print('[CONSOLE]🔧 [STRIPE BLOC] Refreshing customer data after payment...');

      final customerResult = await _repository.getOrCreateCustomer();
      if (customerResult.isSuccess) {
        _currentCustomer = customerResult.data!;
        print('[CONSOLE]✅ [STRIPE BLOC] Customer data refreshed');
      }
    } catch (e) {
      print('[CONSOLE]⚠️ [STRIPE BLOC] Could not refresh customer data: $e');
    }
  }

  /// Conferma il successo del pagamento (unchanged)
  Future<void> _onConfirmPaymentSuccess(
      ConfirmPaymentSuccessEvent event,
      Emitter<StripeState> emit,
      ) async {
    print('[CONSOLE]🔧 [STRIPE BLOC] Confirming payment success...');

    try {
      final result = await _repository.confirmPaymentSuccess(
        paymentIntentId: event.paymentIntentId,
        subscriptionType: event.subscriptionType,
      );

      result.fold(
        onSuccess: (success) {
          print('[CONSOLE]✅ [STRIPE BLOC] Payment confirmed successfully');

          // Ricarica la subscription se è un pagamento di abbonamento
          if (event.subscriptionType == 'subscription') {
            add(const LoadCurrentSubscriptionEvent(afterPayment: true));
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
          print('[CONSOLE]❌ [STRIPE BLOC] Payment confirmation failed: $message');
          emit(StripeErrorState(message: message ?? 'Errore conferma pagamento'));
        },
      );

    } catch (e) {
      print('[CONSOLE]❌ [STRIPE BLOC] Payment confirmation error: $e');
      emit(StripeErrorState(message: 'Errore conferma pagamento: $e'));
    }
  }

  /// 🚀 NUOVA: Carica la subscription corrente con gestione post-pagamento intelligente
  Future<void> _onLoadCurrentSubscription(
      LoadCurrentSubscriptionEvent event,
      Emitter<StripeState> emit,
      ) async {
    print('[CONSOLE]🔧 [STRIPE BLOC] Loading current subscription (afterPayment: ${event.afterPayment})...');

    try {
      Result<StripeSubscription?> result;

      if (event.afterPayment) {
        // 🚀 USA IL NUOVO METODO con retry automatico per post-pagamento
        print('[CONSOLE]🚀 [STRIPE BLOC] Using post-payment retry logic...');
        result = await _repository.getCurrentSubscriptionAfterPayment();
      } else {
        // Usa il metodo normale
        result = await _repository.getCurrentSubscription();
      }

      result.fold(
        onSuccess: (subscription) {
          _currentSubscription = subscription;

          if (subscription != null) {
            print('[CONSOLE]✅ [STRIPE BLOC] Subscription loaded: ${subscription.id} (${subscription.status})');
          } else {
            print('[CONSOLE]✅ [STRIPE BLOC] No subscription found');
          }

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
          print('[CONSOLE]❌ [STRIPE BLOC] Subscription loading failed: $message');

          // 🔧 FIX: Se è dopo un pagamento e fallisce, NON emettere errore che confonde l'utente
          // Il pagamento è comunque riuscito, semplicemente la subscription non è ancora visibile
          if (event.afterPayment) {
            print('[CONSOLE]⚠️ [STRIPE BLOC] Post-payment subscription loading failed - this is OK, subscription may take time to appear');

            // Emetti uno stato di successo comunque, senza subscription
            if (state is StripeReady) {
              emit((state as StripeReady).copyWith(subscription: null));
            } else {
              emit(StripeReady(
                customer: _currentCustomer,
                subscription: null,
                paymentMethods: _paymentMethods,
              ));
            }

            // 🚀 OPZIONALE: Programma un retry futuro
            _scheduleDelayedSubscriptionRetry();

          } else {
            // Solo per caricamenti normali (non post-pagamento) mostra errore
            emit(StripeErrorState(message: message ?? 'Errore caricamento subscription'));
          }
        },
      );

    } catch (e) {
      print('[CONSOLE]❌ [STRIPE BLOC] Subscription loading error: $e');

      // 🔧 FIX: Stessa logica per le eccezioni
      if (event.afterPayment) {
        print('[CONSOLE]⚠️ [STRIPE BLOC] Post-payment subscription loading exception - this is OK');

        if (state is StripeReady) {
          emit((state as StripeReady).copyWith(subscription: null));
        } else {
          emit(StripeReady(
            customer: _currentCustomer,
            subscription: null,
            paymentMethods: _paymentMethods,
          ));
        }

        _scheduleDelayedSubscriptionRetry();

      } else {
        emit(StripeErrorState(message: 'Errore imprevisto: $e'));
      }
    }
  }

  /// 🚀 NUOVA: Programma un retry ritardato per caricare la subscription
  void _scheduleDelayedSubscriptionRetry() {
    print('[CONSOLE]🚀 [STRIPE BLOC] Scheduling delayed subscription retry in 10 seconds...');

    Future.delayed(const Duration(seconds: 10), () {
      if (!isClosed) {
        print('[CONSOLE]🚀 [STRIPE BLOC] Executing delayed subscription retry...');
        add(const LoadCurrentSubscriptionEvent(afterPayment: false));
      }
    });
  }

  /// Cancella subscription (unchanged)
  Future<void> _onCancelSubscription(
      CancelSubscriptionEvent event,
      Emitter<StripeState> emit,
      ) async {
    print('[CONSOLE]🔧 [STRIPE BLOC] Canceling subscription...');

    try {
      final result = await _repository.cancelSubscription(
        subscriptionId: event.subscriptionId,
        immediately: event.immediately,
      );

      result.fold(
        onSuccess: (success) {
          print('[CONSOLE]✅ [STRIPE BLOC] Subscription canceled');

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
          print('[CONSOLE]❌ [STRIPE BLOC] Subscription cancellation failed: $message');
          emit(StripeErrorState(message: message ?? 'Errore cancellazione subscription'));
        },
      );

    } catch (e) {
      print('[CONSOLE]❌ [STRIPE BLOC] Subscription cancellation error: $e');
      emit(StripeErrorState(message: 'Errore cancellazione subscription: $e'));
    }
  }

  /// Riattiva subscription (unchanged)
  Future<void> _onReactivateSubscription(
      ReactivateSubscriptionEvent event,
      Emitter<StripeState> emit,
      ) async {
    print('[CONSOLE]🔧 [STRIPE BLOC] Reactivating subscription...');

    try {
      final result = await _repository.reactivateSubscription(
        subscriptionId: event.subscriptionId,
      );

      result.fold(
        onSuccess: (subscription) {
          _currentSubscription = subscription;
          print('[CONSOLE]✅ [STRIPE BLOC] Subscription reactivated');

          emit(StripeSubscriptionUpdated(
            subscription: subscription,
            message: 'Abbonamento riattivato con successo!',
          ));
        },
        onFailure: (exception, message) {
          print('[CONSOLE]❌ [STRIPE BLOC] Subscription reactivation failed: $message');
          emit(StripeErrorState(message: message ?? 'Errore riattivazione subscription'));
        },
      );

    } catch (e) {
      print('[CONSOLE]❌ [STRIPE BLOC] Subscription reactivation error: $e');
      emit(StripeErrorState(message: 'Errore riattivazione subscription: $e'));
    }
  }

  /// Carica metodi di pagamento (unchanged)
  Future<void> _onLoadPaymentMethods(
      LoadPaymentMethodsEvent event,
      Emitter<StripeState> emit,
      ) async {
    print('[CONSOLE]🔧 [STRIPE BLOC] Loading payment methods...');

    try {
      final result = await _repository.getPaymentMethods();

      result.fold(
        onSuccess: (paymentMethods) {
          _paymentMethods = paymentMethods;
          print('[CONSOLE]✅ [STRIPE BLOC] Payment methods loaded');

          emit(StripePaymentMethodsLoaded(paymentMethods: paymentMethods));
        },
        onFailure: (exception, message) {
          print('[CONSOLE]❌ [STRIPE BLOC] Payment methods loading failed: $message');
          emit(StripeErrorState(message: message ?? 'Errore caricamento metodi di pagamento'));
        },
      );

    } catch (e) {
      print('[CONSOLE]❌ [STRIPE BLOC] Payment methods loading error: $e');
      emit(StripeErrorState(message: 'Errore caricamento metodi di pagamento: $e'));
    }
  }

  /// Elimina metodo di pagamento (unchanged)
  Future<void> _onDeletePaymentMethod(
      DeletePaymentMethodEvent event,
      Emitter<StripeState> emit,
      ) async {
    print('[CONSOLE]🔧 [STRIPE BLOC] Deleting payment method...');

    try {
      final result = await _repository.deletePaymentMethod(
        paymentMethodId: event.paymentMethodId,
      );

      result.fold(
        onSuccess: (success) {
          print('[CONSOLE]✅ [STRIPE BLOC] Payment method deleted');

          // Ricarica metodi di pagamento
          add(const LoadPaymentMethodsEvent());

          emit(const StripeOperationSuccess(
            message: 'Metodo di pagamento eliminato',
            operation: 'delete_payment_method',
          ));
        },
        onFailure: (exception, message) {
          print('[CONSOLE]❌ [STRIPE BLOC] Payment method deletion failed: $message');
          emit(StripeErrorState(message: message ?? 'Errore eliminazione metodo di pagamento'));
        },
      );

    } catch (e) {
      print('[CONSOLE]❌ [STRIPE BLOC] Payment method deletion error: $e');
      emit(StripeErrorState(message: 'Errore eliminazione metodo di pagamento: $e'));
    }
  }

  /// Sincronizza status subscription (unchanged)
  Future<void> _onSyncSubscriptionStatus(
      SyncSubscriptionStatusEvent event,
      Emitter<StripeState> emit,
      ) async {
    print('[CONSOLE]🔧 [STRIPE BLOC] Syncing subscription status...');

    try {
      final result = await _repository.syncSubscriptionStatus();

      result.fold(
        onSuccess: (success) {
          print('[CONSOLE]✅ [STRIPE BLOC] Subscription status synced');

          // Ricarica la subscription
          add(const LoadCurrentSubscriptionEvent());

          emit(const StripeOperationSuccess(
            message: 'Stato abbonamento sincronizzato',
            operation: 'sync_subscription',
          ));
        },
        onFailure: (exception, message) {
          print('[CONSOLE]❌ [STRIPE BLOC] Subscription sync failed: $message');
          emit(StripeErrorState(message: message ?? 'Errore sincronizzazione'));
        },
      );

    } catch (e) {
      print('[CONSOLE]❌ [STRIPE BLOC] Subscription sync error: $e');
      emit(StripeErrorState(message: 'Errore sincronizzazione: $e'));
    }
  }

  /// Reset stato (unchanged)
  void _onResetStripeState(
      ResetStripeStateEvent event,
      Emitter<StripeState> emit,
      ) {
    print('[CONSOLE]🔧 [STRIPE BLOC] Resetting state...');

    _currentCustomer = null;
    _currentSubscription = null;
    _paymentMethods = [];

    emit(const StripeInitial());
  }

  /// Helper per estrarre Payment Intent ID dal client secret (unchanged)
  String _extractPaymentIntentId(String clientSecret) {
    return clientSecret.split('_secret_')[0];
  }

  /// Getter per i dati correnti (unchanged)
  StripeCustomer? get currentCustomer => _currentCustomer;
  StripeSubscription? get currentSubscription => _currentSubscription;
  List<StripePaymentMethod> get paymentMethods => _paymentMethods;

  /// Verifica se l'utente ha una subscription attiva (unchanged)
  bool get hasActiveSubscription =>
      _currentSubscription?.isActive ?? false;

  /// Verifica se la subscription sta per scadere (unchanged)
  bool get isSubscriptionExpiring =>
      _currentSubscription?.isExpiring ?? false;
}