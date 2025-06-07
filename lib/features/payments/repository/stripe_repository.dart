// lib/features/payments/repository/stripe_repository.dart
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../../../core/utils/result.dart';
import '../../../core/network/api_client.dart';
import '../models/stripe_models.dart';
import '../../../core/services/session_service.dart';

/// Repository per gestire le operazioni Stripe tramite API backend
class StripeRepository {
  final ApiClient _apiClient;
  final Dio _dio;
  final SessionService _sessionService;

  StripeRepository({
    required ApiClient apiClient,
    required Dio dio,
    required SessionService sessionService,
  })  : _apiClient = apiClient,
        _dio = dio,
        _sessionService = sessionService;

  // ============================================================================
  // CUSTOMER OPERATIONS
  // ============================================================================

  /// Crea o ottiene un cliente Stripe per l'utente corrente
  Future<Result<StripeCustomer>> getOrCreateCustomer() async {
    developer.log('🔧 [STRIPE REPO] Getting or creating Stripe customer...', name: 'StripeRepository');

    return Result.tryCallAsync(() async {
      final user = await _sessionService.getUserData();
      if (user == null) {
        throw Exception('Utente non autenticato');
      }

      final response = await _dio.post('/stripe/customer', data: {
        'user_id': user.id,
        'email': user.email,
        'name': user.username,
      });

      final data = response.data;
      if (data['success'] == true && data['customer'] != null) {
        final customer = StripeCustomer.fromJson(data['customer']);

        developer.log(
          '✅ [STRIPE REPO] Customer obtained: ${customer.id}',
          name: 'StripeRepository',
        );

        return customer;
      } else {
        throw Exception(data['message'] ?? 'Errore nella creazione del cliente');
      }
    });
  }

  // ============================================================================
  // PAYMENT INTENT OPERATIONS
  // ============================================================================

  /// Crea un Payment Intent per una subscription
  Future<Result<StripePaymentIntentResponse>> createSubscriptionPaymentIntent({
    required String priceId,
    Map<String, dynamic>? metadata,
  }) async {
    developer.log(
      '🔧 [STRIPE REPO] Creating subscription payment intent for price: $priceId',
      name: 'StripeRepository',
    );

    return Result.tryCallAsync(() async {
      final user = await _sessionService.getUserData();
      if (user == null) {
        throw Exception('Utente non autenticato');
      }

      final response = await _dio.post('/stripe/create-subscription-payment-intent', data: {
        'user_id': user.id,
        'price_id': priceId,
        'metadata': metadata ?? {},
      });

      final data = response.data;
      if (data['success'] == true && data['payment_intent'] != null) {
        final paymentIntent = StripePaymentIntentResponse.fromJson(data['payment_intent']);

        developer.log(
          '✅ [STRIPE REPO] Payment intent created: ${paymentIntent.paymentIntentId}',
          name: 'StripeRepository',
        );

        return paymentIntent;
      } else {
        throw Exception(data['message'] ?? 'Errore nella creazione del payment intent');
      }
    });
  }

  /// Crea un Payment Intent per donazione
  Future<Result<StripePaymentIntentResponse>> createDonationPaymentIntent({
    required int amount, // in centesimi
    Map<String, dynamic>? metadata,
  }) async {
    developer.log(
      '🔧 [STRIPE REPO] Creating donation payment intent for amount: €${amount / 100}',
      name: 'StripeRepository',
    );

    return Result.tryCallAsync(() async {
      final user = await _sessionService.getUserData();
      if (user == null) {
        throw Exception('Utente non autenticato');
      }

      final response = await _dio.post('/stripe/create-donation-payment-intent', data: {
        'user_id': user.id,
        'amount': amount,
        'currency': 'eur',
        'metadata': metadata ?? {},
      });

      final data = response.data;
      if (data['success'] == true && data['payment_intent'] != null) {
        final paymentIntent = StripePaymentIntentResponse.fromJson(data['payment_intent']);

        developer.log(
          '✅ [STRIPE REPO] Donation payment intent created: ${paymentIntent.paymentIntentId}',
          name: 'StripeRepository',
        );

        return paymentIntent;
      } else {
        throw Exception(data['message'] ?? 'Errore nella creazione del payment intent per donazione');
      }
    });
  }

  /// Conferma il completamento del pagamento
  Future<Result<bool>> confirmPaymentSuccess({
    required String paymentIntentId,
    required String subscriptionType, // 'premium' o 'donation'
  }) async {
    developer.log(
      '🔧 [STRIPE REPO] Confirming payment success: $paymentIntentId',
      name: 'StripeRepository',
    );

    return Result.tryCallAsync(() async {
      final response = await _dio.post('/stripe/confirm-payment', data: {
        'payment_intent_id': paymentIntentId,
        'subscription_type': subscriptionType,
      });

      final data = response.data;
      if (data['success'] == true) {
        developer.log(
          '✅ [STRIPE REPO] Payment confirmed successfully',
          name: 'StripeRepository',
        );

        return true;
      } else {
        throw Exception(data['message'] ?? 'Errore nella conferma del pagamento');
      }
    });
  }

  // ============================================================================
  // SUBSCRIPTION OPERATIONS
  // ============================================================================

  /// Crea una subscription Stripe
  Future<Result<StripeSubscription>> createSubscription({
    required String customerId,
    required String priceId,
    Map<String, dynamic>? metadata,
  }) async {
    developer.log(
      '🔧 [STRIPE REPO] Creating subscription for customer: $customerId',
      name: 'StripeRepository',
    );

    return Result.tryCallAsync(() async {
      final response = await _dio.post('/stripe/create-subscription', data: {
        'customer_id': customerId,
        'price_id': priceId,
        'metadata': metadata ?? {},
      });

      final data = response.data;
      if (data['success'] == true && data['subscription'] != null) {
        final subscription = StripeSubscription.fromJson(data['subscription']);

        developer.log(
          '✅ [STRIPE REPO] Subscription created: ${subscription.id}',
          name: 'StripeRepository',
        );

        return subscription;
      } else {
        throw Exception(data['message'] ?? 'Errore nella creazione della subscription');
      }
    });
  }

  /// Ottiene la subscription corrente dell'utente
  Future<Result<StripeSubscription?>> getCurrentSubscription() async {
    developer.log('🔧 [STRIPE REPO] Getting current subscription...', name: 'StripeRepository');

    return Result.tryCallAsync(() async {
      final user = await _sessionService.getUserData();
      if (user == null) {
        throw Exception('Utente non autenticato');
      }

      final response = await _dio.get('/stripe/subscription', queryParameters: {
        'user_id': user.id,
      });

      final data = response.data;
      if (data['success'] == true) {
        if (data['subscription'] != null) {
          final subscription = StripeSubscription.fromJson(data['subscription']);

          developer.log(
            '✅ [STRIPE REPO] Current subscription found: ${subscription.id}',
            name: 'StripeRepository',
          );

          return subscription;
        } else {
          developer.log(
            '✅ [STRIPE REPO] No current subscription found',
            name: 'StripeRepository',
          );

          return null;
        }
      } else {
        throw Exception(data['message'] ?? 'Errore nel recupero della subscription');
      }
    });
  }

  /// Cancella una subscription
  Future<Result<bool>> cancelSubscription({
    required String subscriptionId,
    bool immediately = false,
  }) async {
    developer.log(
      '🔧 [STRIPE REPO] Canceling subscription: $subscriptionId (immediately: $immediately)',
      name: 'StripeRepository',
    );

    return Result.tryCallAsync(() async {
      final response = await _dio.post('/stripe/cancel-subscription', data: {
        'subscription_id': subscriptionId,
        'immediately': immediately,
      });

      final data = response.data;
      if (data['success'] == true) {
        developer.log(
          '✅ [STRIPE REPO] Subscription canceled successfully',
          name: 'StripeRepository',
        );

        return true;
      } else {
        throw Exception(data['message'] ?? 'Errore nella cancellazione della subscription');
      }
    });
  }

  /// Riattiva una subscription cancellata
  Future<Result<StripeSubscription>> reactivateSubscription({
    required String subscriptionId,
  }) async {
    developer.log(
      '🔧 [STRIPE REPO] Reactivating subscription: $subscriptionId',
      name: 'StripeRepository',
    );

    return Result.tryCallAsync(() async {
      final response = await _dio.post('/stripe/reactivate-subscription', data: {
        'subscription_id': subscriptionId,
      });

      final data = response.data;
      if (data['success'] == true && data['subscription'] != null) {
        final subscription = StripeSubscription.fromJson(data['subscription']);

        developer.log(
          '✅ [STRIPE REPO] Subscription reactivated: ${subscription.id}',
          name: 'StripeRepository',
        );

        return subscription;
      } else {
        throw Exception(data['message'] ?? 'Errore nella riattivazione della subscription');
      }
    });
  }

  // ============================================================================
  // PAYMENT METHODS
  // ============================================================================

  /// Ottiene i metodi di pagamento salvati per l'utente
  Future<Result<List<StripePaymentMethod>>> getPaymentMethods() async {
    developer.log('🔧 [STRIPE REPO] Getting payment methods...', name: 'StripeRepository');

    return Result.tryCallAsync(() async {
      final user = await _sessionService.getUserData();
      if (user == null) {
        throw Exception('Utente non autenticato');
      }

      final response = await _dio.get('/stripe/payment-methods', queryParameters: {
        'user_id': user.id,
      });

      final data = response.data;
      if (data['success'] == true && data['payment_methods'] != null) {
        final paymentMethodsData = data['payment_methods'] as List;
        final paymentMethods = paymentMethodsData
            .map((pm) => StripePaymentMethod.fromJson(pm))
            .toList();

        developer.log(
          '✅ [STRIPE REPO] Retrieved ${paymentMethods.length} payment methods',
          name: 'StripeRepository',
        );

        return paymentMethods;
      } else {
        throw Exception(data['message'] ?? 'Errore nel recupero dei metodi di pagamento');
      }
    });
  }

  /// Rimuove un metodo di pagamento
  Future<Result<bool>> deletePaymentMethod({
    required String paymentMethodId,
  }) async {
    developer.log(
      '🔧 [STRIPE REPO] Deleting payment method: $paymentMethodId',
      name: 'StripeRepository',
    );

    return Result.tryCallAsync(() async {
      final response = await _dio.delete('/stripe/payment-method', data: {
        'payment_method_id': paymentMethodId,
      });

      final data = response.data;
      if (data['success'] == true) {
        developer.log(
          '✅ [STRIPE REPO] Payment method deleted successfully',
          name: 'StripeRepository',
        );

        return true;
      } else {
        throw Exception(data['message'] ?? 'Errore nella rimozione del metodo di pagamento');
      }
    });
  }

  // ============================================================================
  // WEBHOOK VALIDATION
  // ============================================================================

  /// Valida un webhook Stripe (per test)
  Future<Result<bool>> validateWebhook({
    required String payload,
    required String signature,
  }) async {
    developer.log('🔧 [STRIPE REPO] Validating webhook...', name: 'StripeRepository');

    return Result.tryCallAsync(() async {
      final response = await _dio.post('/stripe/validate-webhook', data: {
        'payload': payload,
        'signature': signature,
      });

      final data = response.data;
      if (data['success'] == true) {
        developer.log(
          '✅ [STRIPE REPO] Webhook validated successfully',
          name: 'StripeRepository',
        );

        return true;
      } else {
        throw Exception(data['message'] ?? 'Webhook non valido');
      }
    });
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Ottiene informazioni sui piani disponibili da Stripe
  Future<Result<List<StripePrice>>> getAvailablePrices() async {
    developer.log('🔧 [STRIPE REPO] Getting available prices...', name: 'StripeRepository');

    return Result.tryCallAsync(() async {
      final response = await _dio.get('/stripe/prices');

      final data = response.data;
      if (data['success'] == true && data['prices'] != null) {
        final pricesData = data['prices'] as List;
        final prices = pricesData
            .map((price) => StripePrice.fromJson(price))
            .toList();

        developer.log(
          '✅ [STRIPE REPO] Retrieved ${prices.length} available prices',
          name: 'StripeRepository',
        );

        return prices;
      } else {
        throw Exception(data['message'] ?? 'Errore nel recupero dei prezzi');
      }
    });
  }

  /// Ottiene lo stato del pagamento
  Future<Result<Map<String, dynamic>>> getPaymentStatus({
    required String paymentIntentId,
  }) async {
    developer.log(
      '🔧 [STRIPE REPO] Getting payment status: $paymentIntentId',
      name: 'StripeRepository',
    );

    return Result.tryCallAsync(() async {
      final response = await _dio.get('/stripe/payment-status', queryParameters: {
        'payment_intent_id': paymentIntentId,
      });

      final data = response.data;
      if (data['success'] == true && data['payment_status'] != null) {
        final paymentStatus = data['payment_status'] as Map<String, dynamic>;

        developer.log(
          '✅ [STRIPE REPO] Payment status retrieved: ${paymentStatus['status']}',
          name: 'StripeRepository',
        );

        return paymentStatus;
      } else {
        throw Exception(data['message'] ?? 'Errore nel recupero dello stato del pagamento');
      }
    });
  }

  /// Sincronizza lo stato della subscription locale con Stripe
  Future<Result<bool>> syncSubscriptionStatus() async {
    developer.log('🔧 [STRIPE REPO] Syncing subscription status...', name: 'StripeRepository');

    return Result.tryCallAsync(() async {
      final user = await _sessionService.getUserData();
      if (user == null) {
        throw Exception('Utente non autenticato');
      }

      final response = await _dio.post('/stripe/sync-subscription', data: {
        'user_id': user.id,
      });

      final data = response.data;
      if (data['success'] == true) {
        developer.log(
          '✅ [STRIPE REPO] Subscription status synced successfully',
          name: 'StripeRepository',
        );

        return true;
      } else {
        throw Exception(data['message'] ?? 'Errore nella sincronizzazione');
      }
    });
  }
}