// lib/features/payments/models/stripe_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'stripe_models.g.dart';

// ============================================================================
// PAYMENT INTENT MODELS
// ============================================================================

/// Risposta per la creazione di un Payment Intent
@JsonSerializable()
class StripePaymentIntentResponse {
  @JsonKey(name: 'client_secret')
  final String clientSecret;
  @JsonKey(name: 'payment_intent_id')
  final String paymentIntentId;
  final String status;
  final int amount;
  final String currency;
  @JsonKey(name: 'customer_id')
  final String? customerId;

  const StripePaymentIntentResponse({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.status,
    required this.amount,
    required this.currency,
    this.customerId,
  });

  factory StripePaymentIntentResponse.fromJson(Map<String, dynamic> json) =>
      _$StripePaymentIntentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StripePaymentIntentResponseToJson(this);
}

/// Richiesta per creare un Payment Intent
@JsonSerializable()
class StripePaymentIntentRequest {
  final int amount; // in centesimi
  final String currency;
  @JsonKey(name: 'customer_id')
  final String? customerId;
  @JsonKey(name: 'payment_method_types')
  final List<String> paymentMethodTypes;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'automatic_payment_methods')
  final bool? automaticPaymentMethods;

  const StripePaymentIntentRequest({
    required this.amount,
    required this.currency,
    this.customerId,
    this.paymentMethodTypes = const ['card'],
    this.metadata,
    this.automaticPaymentMethods,
  });

  factory StripePaymentIntentRequest.fromJson(Map<String, dynamic> json) =>
      _$StripePaymentIntentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StripePaymentIntentRequestToJson(this);
}

// ============================================================================
// SUBSCRIPTION MODELS
// ============================================================================

/// Abbonamento Stripe
@JsonSerializable()
class StripeSubscription {
  final String id;
  @JsonKey(name: 'customer_id')
  final String customerId;
  final String status; // active, past_due, canceled, etc.
  @JsonKey(name: 'current_period_start')
  final int currentPeriodStart; // timestamp
  @JsonKey(name: 'current_period_end')
  final int currentPeriodEnd; // timestamp
  @JsonKey(name: 'cancel_at_period_end')
  final bool cancelAtPeriodEnd;
  final List<StripeSubscriptionItem> items;
  @JsonKey(name: 'latest_invoice')
  final String? latestInvoice;
  final Map<String, dynamic>? metadata;

  const StripeSubscription({
    required this.id,
    required this.customerId,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    required this.items,
    this.latestInvoice,
    this.metadata,
  });

  factory StripeSubscription.fromJson(Map<String, dynamic> json) =>
      _$StripeSubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$StripeSubscriptionToJson(this);

  /// Data di inizio periodo corrente
  DateTime get currentPeriodStartDate =>
      DateTime.fromMillisecondsSinceEpoch(currentPeriodStart * 1000);

  /// Data di fine periodo corrente
  DateTime get currentPeriodEndDate =>
      DateTime.fromMillisecondsSinceEpoch(currentPeriodEnd * 1000);

  /// Indica se l'abbonamento è attivo
  bool get isActive => status == 'active';

  /// Indica se l'abbonamento è in scadenza
  bool get isExpiring {
    final now = DateTime.now();
    final endDate = currentPeriodEndDate;
    final daysUntilEnd = endDate.difference(now).inDays;
    return daysUntilEnd <= 7 && daysUntilEnd > 0;
  }

  /// Giorni rimanenti
  int get daysRemaining {
    final now = DateTime.now();
    final endDate = currentPeriodEndDate;
    return endDate.difference(now).inDays;
  }
}

/// Item di una subscription Stripe
@JsonSerializable()
class StripeSubscriptionItem {
  final String id;
  final StripePrice price;
  final int quantity;

  const StripeSubscriptionItem({
    required this.id,
    required this.price,
    required this.quantity,
  });

  factory StripeSubscriptionItem.fromJson(Map<String, dynamic> json) =>
      _$StripeSubscriptionItemFromJson(json);

  Map<String, dynamic> toJson() => _$StripeSubscriptionItemToJson(this);
}

/// Prezzo Stripe
@JsonSerializable()
class StripePrice {
  final String id;
  final int amount; // in centesimi
  final String currency;
  final String interval; // month, year
  @JsonKey(name: 'interval_count')
  final int intervalCount;
  final StripeProduct product;

  const StripePrice({
    required this.id,
    required this.amount,
    required this.currency,
    required this.interval,
    required this.intervalCount,
    required this.product,
  });

  factory StripePrice.fromJson(Map<String, dynamic> json) =>
      _$StripePriceFromJson(json);

  Map<String, dynamic> toJson() => _$StripePriceToJson(this);

  /// Prezzo formattato
  String get formattedAmount {
    final euros = amount / 100.0;
    return '€${euros.toStringAsFixed(2)}';
  }
}

/// Prodotto Stripe
@JsonSerializable()
class StripeProduct {
  final String id;
  final String name;
  final String? description;
  final Map<String, dynamic>? metadata;

  const StripeProduct({
    required this.id,
    required this.name,
    this.description,
    this.metadata,
  });

  factory StripeProduct.fromJson(Map<String, dynamic> json) =>
      _$StripeProductFromJson(json);

  Map<String, dynamic> toJson() => _$StripeProductToJson(this);
}

// ============================================================================
// CUSTOMER MODELS
// ============================================================================

/// Cliente Stripe
@JsonSerializable()
class StripeCustomer {
  final String id;
  final String? email;
  final String? name;
  final String? phone;
  final Map<String, dynamic>? metadata;

  const StripeCustomer({
    required this.id,
    this.email,
    this.name,
    this.phone,
    this.metadata,
  });

  factory StripeCustomer.fromJson(Map<String, dynamic> json) =>
      _$StripeCustomerFromJson(json);

  Map<String, dynamic> toJson() => _$StripeCustomerToJson(this);
}

/// Richiesta per creare un cliente Stripe
@JsonSerializable()
class StripeCustomerRequest {
  final String? email;
  final String? name;
  final String? phone;
  final Map<String, dynamic>? metadata;

  const StripeCustomerRequest({
    this.email,
    this.name,
    this.phone,
    this.metadata,
  });

  factory StripeCustomerRequest.fromJson(Map<String, dynamic> json) =>
      _$StripeCustomerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StripeCustomerRequestToJson(this);
}

// ============================================================================
// SUBSCRIPTION REQUEST MODELS
// ============================================================================

/// Richiesta per creare una subscription
@JsonSerializable()
class StripeSubscriptionRequest {
  @JsonKey(name: 'customer_id')
  final String customerId;
  @JsonKey(name: 'price_id')
  final String priceId;
  @JsonKey(name: 'payment_behavior')
  final String? paymentBehavior;
  @JsonKey(name: 'expand')
  final List<String>? expand;
  final Map<String, dynamic>? metadata;

  const StripeSubscriptionRequest({
    required this.customerId,
    required this.priceId,
    this.paymentBehavior = 'default_incomplete',
    this.expand,
    this.metadata,
  });

  factory StripeSubscriptionRequest.fromJson(Map<String, dynamic> json) =>
      _$StripeSubscriptionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StripeSubscriptionRequestToJson(this);
}

// ============================================================================
// WEBHOOK MODELS
// ============================================================================

/// Evento webhook da Stripe
@JsonSerializable()
class StripeWebhookEvent {
  final String id;
  final String type;
  @JsonKey(name: 'api_version')
  final String? apiVersion;
  final Map<String, dynamic> data;
  final bool livemode;
  @JsonKey(name: 'pending_webhooks')
  final int pendingWebhooks;
  final StripeWebhookRequest? request;

  const StripeWebhookEvent({
    required this.id,
    required this.type,
    this.apiVersion,
    required this.data,
    required this.livemode,
    required this.pendingWebhooks,
    this.request,
  });

  factory StripeWebhookEvent.fromJson(Map<String, dynamic> json) =>
      _$StripeWebhookEventFromJson(json);

  Map<String, dynamic> toJson() => _$StripeWebhookEventToJson(this);
}

/// Richiesta webhook
@JsonSerializable()
class StripeWebhookRequest {
  final String? id;
  @JsonKey(name: 'idempotency_key')
  final String? idempotencyKey;

  const StripeWebhookRequest({
    this.id,
    this.idempotencyKey,
  });

  factory StripeWebhookRequest.fromJson(Map<String, dynamic> json) =>
      _$StripeWebhookRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StripeWebhookRequestToJson(this);
}

// ============================================================================
// RESPONSE WRAPPERS
// ============================================================================

/// Risposta generica dall'API Stripe
@JsonSerializable(genericArgumentFactories: true)
class StripeApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? error;
  @JsonKey(name: 'error_code')
  final String? errorCode;

  const StripeApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
    this.errorCode,
  });

  factory StripeApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Object? json) fromJsonT,
      ) => _$StripeApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$StripeApiResponseToJson(this, toJsonT);

  /// Crea una risposta di successo
  factory StripeApiResponse.success(T data, {String? message}) {
    return StripeApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  /// Crea una risposta di errore
  factory StripeApiResponse.error(String error, {String? errorCode}) {
    return StripeApiResponse(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }
}

// ============================================================================
// PAYMENT METHOD MODELS
// ============================================================================

/// Metodo di pagamento Stripe
@JsonSerializable()
class StripePaymentMethod {
  final String id;
  final String type; // card, google_pay, apple_pay
  final StripeCard? card;
  @JsonKey(name: 'customer_id')
  final String? customerId;

  const StripePaymentMethod({
    required this.id,
    required this.type,
    this.card,
    this.customerId,
  });

  factory StripePaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$StripePaymentMethodFromJson(json);

  Map<String, dynamic> toJson() => _$StripePaymentMethodToJson(this);
}

/// Dettagli carta di credito
@JsonSerializable()
class StripeCard {
  final String brand; // visa, mastercard, etc.
  @JsonKey(name: 'exp_month')
  final int expMonth;
  @JsonKey(name: 'exp_year')
  final int expYear;
  @JsonKey(name: 'last4')
  final String last4;
  final String? country;

  const StripeCard({
    required this.brand,
    required this.expMonth,
    required this.expYear,
    required this.last4,
    this.country,
  });

  factory StripeCard.fromJson(Map<String, dynamic> json) =>
      _$StripeCardFromJson(json);

  Map<String, dynamic> toJson() => _$StripeCardToJson(this);

  /// Formato data di scadenza
  String get formattedExpiry => '${expMonth.toString().padLeft(2, '0')}/$expYear';

  /// Numero carta mascherato
  String get maskedNumber => '**** **** **** $last4';
}

// ============================================================================
// ERROR MODELS
// ============================================================================

/// Errore Stripe completo
@JsonSerializable()
class StripeErrorModel {
  final String code;
  final String message;
  final String? type;
  @JsonKey(name: 'decline_code')
  final String? declineCode;
  @JsonKey(name: 'payment_intent')
  final String? paymentIntent;

  const StripeErrorModel({
    required this.code,
    required this.message,
    this.type,
    this.declineCode,
    this.paymentIntent,
  });

  factory StripeErrorModel.fromJson(Map<String, dynamic> json) =>
      _$StripeErrorModelFromJson(json);

  Map<String, dynamic> toJson() => _$StripeErrorModelToJson(this);

  /// Messaggio utente-friendly
  String get userFriendlyMessage {
    switch (code) {
      case 'card_declined':
        return 'Carta rifiutata. Controlla i dati o usa un altro metodo di pagamento.';
      case 'insufficient_funds':
        return 'Fondi insufficienti sulla carta.';
      case 'expired_card':
        return 'Carta scaduta.';
      case 'incorrect_cvc':
        return 'Codice di sicurezza non valido.';
      case 'processing_error':
        return 'Errore durante l\'elaborazione. Riprova.';
      case 'authentication_required':
        return 'Autenticazione richiesta. Completa la verifica 3D Secure.';
      default:
        return message;
    }
  }
}

// Nota: StripeError come State è definito nel BLoC
// Questa classe è StripeErrorModel per evitare conflitti