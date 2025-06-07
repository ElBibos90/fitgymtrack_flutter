// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stripe_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StripePaymentIntentResponse _$StripePaymentIntentResponseFromJson(
        Map<String, dynamic> json) =>
    StripePaymentIntentResponse(
      clientSecret: json['client_secret'] as String,
      paymentIntentId: json['payment_intent_id'] as String,
      status: json['status'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String,
      customerId: json['customer_id'] as String?,
    );

Map<String, dynamic> _$StripePaymentIntentResponseToJson(
        StripePaymentIntentResponse instance) =>
    <String, dynamic>{
      'client_secret': instance.clientSecret,
      'payment_intent_id': instance.paymentIntentId,
      'status': instance.status,
      'amount': instance.amount,
      'currency': instance.currency,
      'customer_id': instance.customerId,
    };

StripePaymentIntentRequest _$StripePaymentIntentRequestFromJson(
        Map<String, dynamic> json) =>
    StripePaymentIntentRequest(
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String,
      customerId: json['customer_id'] as String?,
      paymentMethodTypes: (json['payment_method_types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['card'],
      metadata: json['metadata'] as Map<String, dynamic>?,
      automaticPaymentMethods: json['automatic_payment_methods'] as bool?,
    );

Map<String, dynamic> _$StripePaymentIntentRequestToJson(
        StripePaymentIntentRequest instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'currency': instance.currency,
      'customer_id': instance.customerId,
      'payment_method_types': instance.paymentMethodTypes,
      'metadata': instance.metadata,
      'automatic_payment_methods': instance.automaticPaymentMethods,
    };

StripeSubscription _$StripeSubscriptionFromJson(Map<String, dynamic> json) =>
    StripeSubscription(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      status: json['status'] as String,
      currentPeriodStart: (json['current_period_start'] as num).toInt(),
      currentPeriodEnd: (json['current_period_end'] as num).toInt(),
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool,
      items: (json['items'] as List<dynamic>)
          .map(
              (e) => StripeSubscriptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      latestInvoice: json['latest_invoice'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$StripeSubscriptionToJson(StripeSubscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customer_id': instance.customerId,
      'status': instance.status,
      'current_period_start': instance.currentPeriodStart,
      'current_period_end': instance.currentPeriodEnd,
      'cancel_at_period_end': instance.cancelAtPeriodEnd,
      'items': instance.items,
      'latest_invoice': instance.latestInvoice,
      'metadata': instance.metadata,
    };

StripeSubscriptionItem _$StripeSubscriptionItemFromJson(
        Map<String, dynamic> json) =>
    StripeSubscriptionItem(
      id: json['id'] as String,
      price: StripePrice.fromJson(json['price'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$StripeSubscriptionItemToJson(
        StripeSubscriptionItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'price': instance.price,
      'quantity': instance.quantity,
    };

StripePrice _$StripePriceFromJson(Map<String, dynamic> json) => StripePrice(
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String,
      interval: json['interval'] as String,
      intervalCount: (json['interval_count'] as num).toInt(),
      product: StripeProduct.fromJson(json['product'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StripePriceToJson(StripePrice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'currency': instance.currency,
      'interval': instance.interval,
      'interval_count': instance.intervalCount,
      'product': instance.product,
    };

StripeProduct _$StripeProductFromJson(Map<String, dynamic> json) =>
    StripeProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$StripeProductToJson(StripeProduct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'metadata': instance.metadata,
    };

StripeCustomer _$StripeCustomerFromJson(Map<String, dynamic> json) =>
    StripeCustomer(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$StripeCustomerToJson(StripeCustomer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'phone': instance.phone,
      'metadata': instance.metadata,
    };

StripeCustomerRequest _$StripeCustomerRequestFromJson(
        Map<String, dynamic> json) =>
    StripeCustomerRequest(
      email: json['email'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$StripeCustomerRequestToJson(
        StripeCustomerRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'name': instance.name,
      'phone': instance.phone,
      'metadata': instance.metadata,
    };

StripeSubscriptionRequest _$StripeSubscriptionRequestFromJson(
        Map<String, dynamic> json) =>
    StripeSubscriptionRequest(
      customerId: json['customer_id'] as String,
      priceId: json['price_id'] as String,
      paymentBehavior:
          json['payment_behavior'] as String? ?? 'default_incomplete',
      expand:
          (json['expand'] as List<dynamic>?)?.map((e) => e as String).toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$StripeSubscriptionRequestToJson(
        StripeSubscriptionRequest instance) =>
    <String, dynamic>{
      'customer_id': instance.customerId,
      'price_id': instance.priceId,
      'payment_behavior': instance.paymentBehavior,
      'expand': instance.expand,
      'metadata': instance.metadata,
    };

StripeWebhookEvent _$StripeWebhookEventFromJson(Map<String, dynamic> json) =>
    StripeWebhookEvent(
      id: json['id'] as String,
      type: json['type'] as String,
      apiVersion: json['api_version'] as String?,
      data: json['data'] as Map<String, dynamic>,
      livemode: json['livemode'] as bool,
      pendingWebhooks: (json['pending_webhooks'] as num).toInt(),
      request: json['request'] == null
          ? null
          : StripeWebhookRequest.fromJson(
              json['request'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StripeWebhookEventToJson(StripeWebhookEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'api_version': instance.apiVersion,
      'data': instance.data,
      'livemode': instance.livemode,
      'pending_webhooks': instance.pendingWebhooks,
      'request': instance.request,
    };

StripeWebhookRequest _$StripeWebhookRequestFromJson(
        Map<String, dynamic> json) =>
    StripeWebhookRequest(
      id: json['id'] as String?,
      idempotencyKey: json['idempotency_key'] as String?,
    );

Map<String, dynamic> _$StripeWebhookRequestToJson(
        StripeWebhookRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'idempotency_key': instance.idempotencyKey,
    };

StripeApiResponse<T> _$StripeApiResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    StripeApiResponse<T>(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: _$nullableGenericFromJson(json['data'], fromJsonT),
      error: json['error'] as String?,
      errorCode: json['error_code'] as String?,
    );

Map<String, dynamic> _$StripeApiResponseToJson<T>(
  StripeApiResponse<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': _$nullableGenericToJson(instance.data, toJsonT),
      'error': instance.error,
      'error_code': instance.errorCode,
    };

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) =>
    input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) =>
    input == null ? null : toJson(input);

StripePaymentMethod _$StripePaymentMethodFromJson(Map<String, dynamic> json) =>
    StripePaymentMethod(
      id: json['id'] as String,
      type: json['type'] as String,
      card: json['card'] == null
          ? null
          : StripeCard.fromJson(json['card'] as Map<String, dynamic>),
      customerId: json['customer_id'] as String?,
    );

Map<String, dynamic> _$StripePaymentMethodToJson(
        StripePaymentMethod instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'card': instance.card,
      'customer_id': instance.customerId,
    };

StripeCard _$StripeCardFromJson(Map<String, dynamic> json) => StripeCard(
      brand: json['brand'] as String,
      expMonth: (json['exp_month'] as num).toInt(),
      expYear: (json['exp_year'] as num).toInt(),
      last4: json['last4'] as String,
      country: json['country'] as String?,
    );

Map<String, dynamic> _$StripeCardToJson(StripeCard instance) =>
    <String, dynamic>{
      'brand': instance.brand,
      'exp_month': instance.expMonth,
      'exp_year': instance.expYear,
      'last4': instance.last4,
      'country': instance.country,
    };

StripeError _$StripeErrorFromJson(Map<String, dynamic> json) => StripeError(
      code: json['code'] as String,
      message: json['message'] as String,
      type: json['type'] as String?,
      declineCode: json['decline_code'] as String?,
      paymentIntent: json['payment_intent'] as String?,
    );

Map<String, dynamic> _$StripeErrorToJson(StripeError instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'type': instance.type,
      'decline_code': instance.declineCode,
      'payment_intent': instance.paymentIntent,
    };
