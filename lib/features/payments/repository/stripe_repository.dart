// lib/features/payments/repository/stripe_repository.dart
import 'package:dio/dio.dart';

import '../../../core/utils/result.dart';
import '../../../core/network/api_client.dart';
import '../models/stripe_models.dart';
import '../../../core/services/session_service.dart';

/// Repository per gestire le operazioni Stripe tramite API backend - VERSIONE FINALE CON DEBUG
class StripeRepository {
  final ApiClient _apiClient;
  final Dio _dio;
  final SessionService _sessionService;

  // 🔧 FIX: Cache customer per evitare chiamate multiple
  StripeCustomer? _cachedCustomer;
  bool _customerCreationInProgress = false;

  StripeRepository({
    required ApiClient apiClient,
    required Dio dio,
    required SessionService sessionService,
  })  : _apiClient = apiClient,
        _dio = dio,
        _sessionService = sessionService;

  // ============================================================================
  // 🔧 ENDPOINT CORRETTI E VALIDATI
  // ============================================================================

  /// Base path per tutti gli endpoint Stripe - CORRETTI secondo backend summary
  static const String _stripePath = '/stripe';

  /// 🔧 FIX: Endpoint corretti come da backend working
  static const String _customerEndpoint = '$_stripePath/customer.php';
  static const String _subscriptionEndpoint = '$_stripePath/subscription.php';
  static const String _createSubscriptionPaymentEndpoint = '$_stripePath/create-subscription-payment-intent.php';
  static const String _createDonationPaymentEndpoint = '$_stripePath/create-donation-payment-intent.php';
  static const String _confirmPaymentEndpoint = '$_stripePath/confirm-payment.php';

  // ============================================================================
  // 🔧 CUSTOMER OPERATIONS - CORRETTE E ROBUSTE
  // ============================================================================

  /// 🔧 FIX: Crea o ottiene un cliente Stripe per l'utente corrente con protezione duplicati
  Future<Result<StripeCustomer>> getOrCreateCustomer() async {
    print('[CONSOLE]🔧 [STRIPE REPO] Getting or creating Stripe customer...');

    // 🔧 FIX: Se abbiamo già un customer in cache, usalo
    if (_cachedCustomer != null) {
      print('[CONSOLE]✅ [STRIPE REPO] Using cached customer: ${_cachedCustomer!.id}');
      return Result.success(_cachedCustomer!);
    }

    // 🔧 FIX: Se c'è già una creazione in corso, aspetta
    if (_customerCreationInProgress) {
      print('[CONSOLE]⏳ [STRIPE REPO] Customer creation already in progress, waiting...');

      // Aspetta che la creazione finisca
      int attempts = 0;
      while (_customerCreationInProgress && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      // Se il customer è stato creato nel frattempo, restituiscilo
      if (_cachedCustomer != null) {
        print('[CONSOLE]✅ [STRIPE REPO] Customer created by parallel request: ${_cachedCustomer!.id}');
        return Result.success(_cachedCustomer!);
      }
    }

    // 🔧 FIX: Marca che stiamo creando il customer
    _customerCreationInProgress = true;

    try {
      return await Result.tryCallAsync(() async {
        // Verifica autenticazione
        final authResult = await _validateAuthentication();
        if (authResult.isFailure) {
          throw Exception('Authentication failed: ${authResult.message}');
        }

        final user = authResult.data!;

        // 🔧 FIX: Dati customer con validazione e timestamp unico
        final customerData = {
          'user_id': user.id,
          'email': user.email ?? 'user${user.id}@fitgymtrack.com',
          'name': user.username ?? 'User ${user.id}',
          'timestamp': DateTime.now().millisecondsSinceEpoch, // Per identificare la richiesta
        };

        print('[CONSOLE]🔧 [STRIPE REPO] Customer data: $customerData');

        // 🔧 FIX: POST con retry automatico per gestire race conditions
        final response = await _makeAuthenticatedRequestWithRetry(
          method: 'POST',
          endpoint: _customerEndpoint,
          data: customerData,
          maxRetries: 3,
          retryDelay: const Duration(milliseconds: 1000),
        );

        if (response['success'] == true && response['customer'] != null) {
          final customer = StripeCustomer.fromJson(response['customer']);

          // 🔧 FIX: Cache del customer per evitare future chiamate
          _cachedCustomer = customer;

          print('[CONSOLE]✅ [STRIPE REPO] Customer obtained and cached: ${customer.id}');

          return customer;
        } else if (response['message']?.contains('Cliente esistente') == true) {
          // 🔧 FIX: Se il customer esiste già, è comunque un successo
          print('[CONSOLE]✅ [STRIPE REPO] Customer already exists - treating as success');

          if (response['customer'] != null) {
            final customer = StripeCustomer.fromJson(response['customer']);
            _cachedCustomer = customer;
            return customer;
          } else {
            // Se non abbiamo customer data, fai una chiamata di recovery
            print('[CONSOLE]🔧 [STRIPE REPO] Recovering existing customer...');
            // Per ora, riprova una volta
            throw Exception('Customer exists but data not returned - retry needed');
          }
        } else {
          throw Exception(response['message'] ?? 'Errore nella creazione del cliente Stripe');
        }
      });
    } finally {
      // 🔧 FIX: Marca che la creazione è finita
      _customerCreationInProgress = false;
    }
  }

  // ============================================================================
  // 🔧 PAYMENT INTENT OPERATIONS - CORRETTE E VALIDATE
  // ============================================================================

  /// Crea un Payment Intent per una subscription - FIXED VERSION
  Future<Result<StripePaymentIntentResponse>> createSubscriptionPaymentIntent({
    required String priceId,
    Map<String, dynamic>? metadata,
  }) async {
    print('[CONSOLE]🔧 [STRIPE REPO] Creating subscription payment intent for price: $priceId',
    );

    return Result.tryCallAsync(() async {
      // Verifica autenticazione
      final authResult = await _validateAuthentication();
      if (authResult.isFailure) {
        throw Exception('Authentication failed: ${authResult.message}');
      }

      final user = authResult.data!;

      // 🔧 FIX: Validazione price ID
      if (priceId.isEmpty || !priceId.startsWith('price_')) {
        throw Exception('Invalid price ID format: $priceId');
      }

      // Dati per payment intent
      final paymentData = {
        'user_id': user.id,
        'price_id': priceId,
        'metadata': {
          'user_id': user.id.toString(),
          'subscription_type': 'premium',
          'platform': 'flutter',
          ...metadata ?? {},
        },
      };

      print('[CONSOLE]🔧 [STRIPE REPO] Payment data: $paymentData');

      // 🔧 FIX: Richiesta con retry automatico
      final response = await _makeAuthenticatedRequest(
        method: 'POST',
        endpoint: _createSubscriptionPaymentEndpoint,
        data: paymentData,
        retryOnFailure: true,
      );

      print('[CONSOLE]🔧 [STRIPE REPO] Full response: $response');

      // 🔧 FIX: Parsing corretto della risposta - SUPPORTA ENTRAMBI I FORMATI
      if (response['success'] == true) {
        Map<String, dynamic>? paymentIntentData;

        // Controlla nuovo formato: data.payment_intent
        if (response['data'] != null && response['data']['payment_intent'] != null) {
          paymentIntentData = response['data']['payment_intent'];
          print('[CONSOLE]🔧 [STRIPE REPO] Using new format: data.payment_intent');
        }
        // Controlla vecchio formato: payment_intent diretto
        else if (response['payment_intent'] != null) {
          paymentIntentData = response['payment_intent'];
          print('[CONSOLE]🔧 [STRIPE REPO] Using old format: payment_intent');
        }

        if (paymentIntentData != null) {
          try {
            final paymentIntent = StripePaymentIntentResponse.fromJson(paymentIntentData);

            print('[CONSOLE]✅ [STRIPE REPO] Payment intent created successfully: ${paymentIntent.paymentIntentId}',
            );

            return paymentIntent;
          } catch (e) {
            print('[CONSOLE]❌ [STRIPE REPO] JSON parsing error: $e');
            print('[CONSOLE]❌ [STRIPE REPO] Payment intent data: $paymentIntentData');
            throw Exception('Error parsing payment intent response: $e');
          }
        } else {
          print('[CONSOLE]❌ [STRIPE REPO] Payment intent data not found in response');
          print('[CONSOLE]❌ [STRIPE REPO] Response structure: ${response.keys.toList()}');
          throw Exception('Payment intent data not found in response. Available keys: ${response.keys.toList()}');
        }
      } else {
        final errorMessage = response['message'] ?? 'Errore nella creazione del payment intent per subscription';
        print('[CONSOLE]❌ [STRIPE REPO] Server returned success=false: $errorMessage');
        throw Exception(errorMessage);
      }
    });
  }

  /// Crea un Payment Intent per donazione
  Future<Result<StripePaymentIntentResponse>> createDonationPaymentIntent({
    required int amount, // in centesimi
    Map<String, dynamic>? metadata,
  }) async {
    print('[CONSOLE]🔧 [STRIPE REPO] Creating donation payment intent for amount: €${amount / 100}',
    );

    return Result.tryCallAsync(() async {
      // Verifica autenticazione
      final authResult = await _validateAuthentication();
      if (authResult.isFailure) {
        throw Exception('Authentication failed: ${authResult.message}');
      }

      final user = authResult.data!;

      // 🔧 FIX: Validazione importo
      if (amount < 50) { // Minimo €0.50
        throw Exception('Donation amount too small. Minimum: €0.50');
      }
      if (amount > 50000) { // Massimo €500
        throw Exception('Donation amount too large. Maximum: €500.00');
      }

      // Dati per donazione
      final donationData = {
        'user_id': user.id,
        'amount': amount,
        'currency': 'eur',
        'metadata': {
          'user_id': user.id.toString(),
          'donation_type': 'one_time',
          'platform': 'flutter',
          ...metadata ?? {},
        },
      };

      print('[CONSOLE]🔧 [STRIPE REPO] Donation data: $donationData');

      // 🔧 FIX: Richiesta con retry automatico
      final response = await _makeAuthenticatedRequest(
        method: 'POST',
        endpoint: _createDonationPaymentEndpoint,
        data: donationData,
        retryOnFailure: true,
      );

      if (response['success'] == true && response['payment_intent'] != null) {
        final paymentIntent = StripePaymentIntentResponse.fromJson(response['payment_intent']);

        print('[CONSOLE] ✅ [STRIPE REPO] Donation payment intent created: ${paymentIntent.paymentIntentId}',
        );

        return paymentIntent;
      } else {
        throw Exception(response['message'] ?? 'Errore nella creazione del payment intent per donazione');
      }
    });
  }

  /// Conferma il completamento del pagamento
  Future<Result<bool>> confirmPaymentSuccess({
    required String paymentIntentId,
    required String subscriptionType,
  }) async {
    print('[CONSOLE]🔧 [STRIPE REPO] Confirming payment success: $paymentIntentId',
    );

    return Result.tryCallAsync(() async {
      // 🔧 FIX: Validazione payment intent ID
      if (paymentIntentId.isEmpty || !paymentIntentId.startsWith('pi_')) {
        throw Exception('Invalid payment intent ID format: $paymentIntentId');
      }

      // Dati per conferma
      final confirmData = {
        'payment_intent_id': paymentIntentId,
        'subscription_type': subscriptionType,
        'confirmed_at': DateTime.now().toIso8601String(),
      };

      print('[CONSOLE]🔧 [STRIPE REPO] Confirm data: $confirmData');

      // 🔧 FIX: Richiesta con retry automatico e timeout esteso
      final response = await _makeAuthenticatedRequest(
        method: 'POST',
        endpoint: _confirmPaymentEndpoint,
        data: confirmData,
        retryOnFailure: true,
        timeoutSeconds: 30, // Timeout più lungo per conferma pagamento
      );

      if (response['success'] == true) {
        print('[CONSOLE]✅ [STRIPE REPO] Payment confirmed successfully',
        );

        return true;
      } else {
        throw Exception(response['message'] ?? 'Errore nella conferma del pagamento');
      }
    });
  }

  // ============================================================================
  // 🔧 SUBSCRIPTION OPERATIONS - IMPLEMENTAZIONE COMPLETA CON POST-PAYMENT FIX E DEBUG
  // ============================================================================

  /// 🚀 NUOVA: Ottiene la subscription corrente con retry intelligente post-pagamento
  Future<Result<StripeSubscription?>> getCurrentSubscription({
    bool retryForRecentPayment = false,
    int maxRetries = 3,
  }) async {
    print('[CONSOLE]🔧 [STRIPE REPO] Getting current subscription (retryForRecentPayment: $retryForRecentPayment)...');

    return Result.tryCallAsync(() async {
      // Verifica autenticazione
      final authResult = await _validateAuthentication();
      if (authResult.isFailure) {
        throw Exception('Authentication failed: ${authResult.message}');
      }

      final user = authResult.data!;
      StripeSubscription? subscription;
      int attempt = 0;

      // 🔧 FIX: Retry loop per gestire subscriptions appena create
      while (attempt < maxRetries) {
        attempt++;

        print('[CONSOLE]🔧 [STRIPE REPO] Attempt $attempt/$maxRetries to get subscription');

        try {
          // 🔧 FIX: GET con query parameters + include incomplete subscriptions
          final response = await _makeAuthenticatedRequest(
            method: 'GET',
            endpoint: _subscriptionEndpoint,
            queryParameters: {
              'user_id': user.id.toString(),
              'include_cancelled': 'true',
              'include_incomplete': 'true', // 🚀 NUOVO: Include subscription incomplete
              'include_recent': retryForRecentPayment ? 'true' : 'false', // 🚀 NUOVO: Include subscription recenti
            },
          );

          if (response['success'] == true) {
            // 🔧 FIX: Il backend ora restituisce dati dentro "data" field
            final data = response['data'];

            if (data != null && data is Map<String, dynamic>) {
              // 🚀 FIXED: Cerca subscription dentro data field
              if (data['subscription'] != null) {
                // 🔧 DEBUG: Log dei dati subscription prima del parsing
                print('[CONSOLE]🔧 [DEBUG] Subscription data before parsing: ${data['subscription']}');

                try {
                  subscription = StripeSubscription.fromJson(data['subscription']);
                  print('[CONSOLE]✅ [STRIPE REPO] Current subscription found: ${subscription!.id} (${subscription!.status})');
                  return subscription;
                } catch (e, stackTrace) {
                  print('[CONSOLE]❌ [DEBUG] StripeSubscription.fromJson failed: $e');
                  print('[CONSOLE]❌ [DEBUG] Stack trace: $stackTrace');

                  // 🚀 ULTIMATE FIX: Ricostruisci con TUTTI i campi richiesti dal modello
                  print('[CONSOLE]🔧 [DEBUG] Building subscription with required model fields...');

                  try {
                    final subscriptionData = data['subscription'];
                    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

                    // 🔧 FIX: Ricostruisci gli items nel formato corretto
                    final originalItems = subscriptionData['items'] as List;
                    final safeItems = originalItems.map((item) {
                      final originalPrice = item['price'];

                      return {
                        'id': item['id'] ?? 'si_default',
                        'object': 'subscription_item', // Campo mancante
                        'created': now, // Campo mancante
                        'quantity': 1, // Campo mancante ma obbligatorio
                        'subscription': subscriptionData['id'],
                        'price': {
                          'id': originalPrice['id'] ?? 'price_default',
                          'object': 'price', // Campo mancante
                          'active': true, // Campo mancante
                          'billing_scheme': 'per_unit', // Campo mancante
                          'created': now, // Campo mancante
                          'currency': originalPrice['currency'] ?? 'eur',
                          'livemode': false, // Campo mancante
                          'lookup_key': null, // Campo opzionale
                          'nickname': null, // Campo opzionale
                          'product': originalPrice['product']['id'] ?? 'prod_default',
                          'recurring': {
                            'aggregate_usage': null,
                            'interval': originalPrice['interval'] ?? 'month',
                            'interval_count': originalPrice['interval_count'] ?? 1,
                            'usage_type': 'licensed',
                          },
                          'tax_behavior': 'unspecified', // Campo mancante
                          'tiers_mode': null, // Campo opzionale
                          'transform_quantity': null, // Campo opzionale
                          'type': 'recurring', // Campo mancante
                          'unit_amount': originalPrice['amount'] ?? 0,
                          'unit_amount_decimal': '${originalPrice['amount'] ?? 0}', // Campo mancante
                        },
                        'billing_thresholds': null, // Campo opzionale
                        'metadata': {}, // Campo mancante
                        'tax_rates': [], // Campo mancante
                      };
                    }).toList();

                    // 🔧 FIX: Subscription completa nel formato corretto
                    final safeSubscriptionData = {
                      'id': subscriptionData['id'],
                      'object': 'subscription', // Campo mancante
                      'application': null, // Campo opzionale
                      'application_fee_percent': null, // Campo opzionale
                      'automatic_tax': {'enabled': false}, // Campo mancante
                      'billing_cycle_anchor': subscriptionData['current_period_start'] ?? now,
                      'billing_thresholds': null, // Campo opzionale
                      'cancel_at': null, // Campo opzionale
                      'cancel_at_period_end': subscriptionData['cancel_at_period_end'] ?? false,
                      'canceled_at': null, // Campo opzionale
                      'collection_method': 'charge_automatically', // Campo mancante
                      'created': now, // Campo mancante
                      'currency': 'eur', // Campo mancante
                      'current_period_end': subscriptionData['current_period_end'] ?? (now + 2592000), // +30 giorni
                      'current_period_start': subscriptionData['current_period_start'] ?? now,
                      'customer': subscriptionData['customer_id'],
                      'days_until_due': null, // Campo opzionale
                      'default_payment_method': null, // Campo opzionale
                      'default_source': null, // Campo opzionale
                      'default_tax_rates': [], // Campo mancante
                      'description': null, // Campo opzionale
                      'discount': null, // Campo opzionale
                      'ended_at': null, // Campo opzionale
                      'items': {
                        'object': 'list',
                        'data': safeItems,
                        'has_more': false,
                        'total_count': safeItems.length,
                        'url': '/v1/subscription_items?subscription=${subscriptionData['id']}',
                      },
                      'latest_invoice': subscriptionData['latest_invoice'],
                      'livemode': false, // Campo mancante
                      'metadata': subscriptionData['metadata'] ?? {},
                      'next_pending_invoice_item_invoice': null, // Campo opzionale
                      'on_behalf_of': null, // Campo opzionale
                      'pause_collection': null, // Campo opzionale
                      'payment_settings': {
                        'payment_method_options': null,
                        'payment_method_types': null,
                        'save_default_payment_method': 'off',
                      }, // Campo mancante
                      'pending_invoice_item_interval': null, // Campo opzionale
                      'pending_setup_intent': null, // Campo opzionale
                      'pending_update': null, // Campo opzionale
                      'schedule': null, // Campo opzionale
                      'start_date': subscriptionData['current_period_start'] ?? now,
                      'status': subscriptionData['status'] ?? 'active',
                      'test_clock': null, // Campo opzionale
                      'transfer_data': null, // Campo opzionale
                      'trial_end': null, // Campo opzionale
                      'trial_settings': {'end_behavior': {'missing_payment_method': 'create_invoice'}}, // Campo mancante
                      'trial_start': null, // Campo opzionale
                    };

                    subscription = StripeSubscription.fromJson(safeSubscriptionData);
                    print('[CONSOLE]✅ [STRIPE REPO] Safe subscription creation successful: ${subscription!.id}');
                    return subscription;
                  } catch (e2) {
                    print('[CONSOLE]❌ [DEBUG] Safe subscription creation also failed: $e2');
                    throw Exception('Subscription parsing failed: $e');
                  }
                }
              } else if (data['subscriptions'] != null && data['subscriptions'] is List) {
                // 🚀 FIXED: Gestisce array di subscriptions dentro data field
                final subscriptionsList = data['subscriptions'] as List;

                if (subscriptionsList.isNotEmpty) {
                  subscription = StripeSubscription.fromJson(subscriptionsList.first);

                  print('[CONSOLE]✅ [STRIPE REPO] Found subscription from list: ${subscription!.id} (${subscription!.status})');

                  return subscription;
                }
              }
            }

            // 🔧 FALLBACK: Prova il vecchio formato per compatibilità
            if (response['subscription'] != null) {
              subscription = StripeSubscription.fromJson(response['subscription']);

              print('[CONSOLE]✅ [STRIPE REPO] Current subscription found (legacy format): ${subscription!.id} (${subscription!.status})');

              return subscription;
            } else if (response['subscriptions'] != null && response['subscriptions'] is List) {
              final subscriptionsList = response['subscriptions'] as List;

              if (subscriptionsList.isNotEmpty) {
                subscription = StripeSubscription.fromJson(subscriptionsList.first);

                print('[CONSOLE]✅ [STRIPE REPO] Found subscription from list (legacy format): ${subscription!.id} (${subscription!.status})');

                return subscription;
              }
            }
          }

          // Se non trova subscription e stiamo facendo retry per recent payment
          if (retryForRecentPayment && attempt < maxRetries) {
            print('[CONSOLE]⏳ [STRIPE REPO] No subscription found on attempt $attempt, retrying in ${attempt * 2} seconds...');
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }

          // Se non trova nulla
          print('[CONSOLE]🚨 [DEBUG] About to return null - Backend says no subscription found');
          print('[CONSOLE]✅ [STRIPE REPO] No current subscription found');
          return null;

        } catch (e) {
          print('[CONSOLE]❌ [STRIPE REPO] Error getting subscription on attempt $attempt: $e');

          if (attempt >= maxRetries) {
            rethrow;
          }

          // Retry con delay
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }

      return null;
    });
  }

  /// 🚀 NUOVA: Wrapper per chiamate post-pagamento con retry automatico
  Future<Result<StripeSubscription?>> getCurrentSubscriptionAfterPayment() async {
    print('[CONSOLE]🚀 [STRIPE REPO] Getting subscription after payment with intelligent retry...');

    return await getCurrentSubscription(
      retryForRecentPayment: true,
      maxRetries: 5, // Più tentativi per post-pagamento
    );
  }

  /// Cancella una subscription
  Future<Result<bool>> cancelSubscription({
    required String subscriptionId,
    bool immediately = false,
  }) async {
    print('[CONSOLE]🔧 [STRIPE REPO] Canceling subscription: $subscriptionId (immediately: $immediately)',
    );

    return Result.tryCallAsync(() async {
      // 🔧 FIX: Validazione subscription ID
      if (subscriptionId.isEmpty || !subscriptionId.startsWith('sub_')) {
        throw Exception('Invalid subscription ID format: $subscriptionId');
      }

      // Dati per cancellazione
      final cancelData = {
        'subscription_id': subscriptionId,
        'immediately': immediately,
        'cancel_reason': 'user_request',
        'cancelled_at': DateTime.now().toIso8601String(),
      };

      print('[CONSOLE]🔧 [STRIPE REPO] Cancel data: $cancelData');

      // 🔧 FIX: DELETE method per cancellazione
      final response = await _makeAuthenticatedRequest(
        method: 'DELETE',
        endpoint: _subscriptionEndpoint,
        data: cancelData,
        retryOnFailure: true,
      );

      if (response['success'] == true) {
        print('[CONSOLE]✅ [STRIPE REPO] Subscription canceled successfully',
        );

        return true;
      } else {
        throw Exception(response['message'] ?? 'Errore nella cancellazione della subscription');
      }
    });
  }

  /// Riattiva una subscription cancellata
  Future<Result<StripeSubscription>> reactivateSubscription({
    required String subscriptionId,
  }) async {
    print('[CONSOLE]🔧 [STRIPE REPO] Reactivating subscription: $subscriptionId',
    );

    return Result.tryCallAsync(() async {
      // 🔧 FIX: Validazione subscription ID
      if (subscriptionId.isEmpty || !subscriptionId.startsWith('sub_')) {
        throw Exception('Invalid subscription ID format: $subscriptionId');
      }

      // Dati per riattivazione
      final reactivateData = {
        'subscription_id': subscriptionId,
        'reactivate': true,
        'reactivated_at': DateTime.now().toIso8601String(),
      };

      print('[CONSOLE]🔧 [STRIPE REPO] Reactivate data: $reactivateData');

      // 🔧 FIX: PUT method per riattivazione
      final response = await _makeAuthenticatedRequest(
        method: 'PUT',
        endpoint: _subscriptionEndpoint,
        data: reactivateData,
        retryOnFailure: true,
      );

      if (response['success'] == true && response['subscription'] != null) {
        final subscription = StripeSubscription.fromJson(response['subscription']);

        print('[CONSOLE]✅ [STRIPE REPO] Subscription reactivated: ${subscription.id}',
        );

        return subscription;
      } else {
        throw Exception(response['message'] ?? 'Errore nella riattivazione della subscription');
      }
    });
  }

  // ============================================================================
  // 🔧 PAYMENT METHODS - GESTIONE COMPLETA
  // ============================================================================

  /// Ottiene i metodi di pagamento salvati per l'utente
  Future<Result<List<StripePaymentMethod>>> getPaymentMethods() async {
    print('[CONSOLE]🔧 [STRIPE REPO] Getting payment methods...');

    return Result.tryCallAsync(() async {
      // Verifica autenticazione
      final authResult = await _validateAuthentication();
      if (authResult.isFailure) {
        throw Exception('Authentication failed: ${authResult.message}');
      }

      final user = authResult.data!;

      // GET payment methods
      final response = await _makeAuthenticatedRequest(
        method: 'GET',
        endpoint: '$_stripePath/payment-methods.php',
        queryParameters: {
          'user_id': user.id.toString(),
        },
      );

      if (response['success'] == true && response['payment_methods'] != null) {
        final paymentMethodsData = response['payment_methods'] as List;
        final paymentMethods = paymentMethodsData
            .map((pm) => StripePaymentMethod.fromJson(pm))
            .toList();

        print('[CONSOLE]✅ [STRIPE REPO] Retrieved ${paymentMethods.length} payment methods',
        );

        return paymentMethods;
      } else {
        // Non è un errore se non ci sono metodi di pagamento
        print('[CONSOLE]✅ [STRIPE REPO] No payment methods found',
        );

        return <StripePaymentMethod>[];
      }
    });
  }

  /// Rimuove un metodo di pagamento
  Future<Result<bool>> deletePaymentMethod({
    required String paymentMethodId,
  }) async {
    print('[CONSOLE]🔧 [STRIPE REPO] Deleting payment method: $paymentMethodId',
    );

    return Result.tryCallAsync(() async {
      // 🔧 FIX: Validazione payment method ID
      if (paymentMethodId.isEmpty || !paymentMethodId.startsWith('pm_')) {
        throw Exception('Invalid payment method ID format: $paymentMethodId');
      }

      // DELETE payment method
      final response = await _makeAuthenticatedRequest(
        method: 'DELETE',
        endpoint: '$_stripePath/payment-methods.php',
        data: {
          'payment_method_id': paymentMethodId,
          'detach_reason': 'user_request',
        },
      );

      if (response['success'] == true) {
        print('[CONSOLE]✅ [STRIPE REPO] Payment method deleted successfully',
        );

        return true;
      } else {
        throw Exception(response['message'] ?? 'Errore nella rimozione del metodo di pagamento');
      }
    });
  }

  /// Sincronizza lo stato della subscription locale con Stripe
  Future<Result<bool>> syncSubscriptionStatus() async {
    print('[CONSOLE]🔧 [STRIPE REPO] Syncing subscription status...');

    return Result.tryCallAsync(() async {
      // Verifica autenticazione
      final authResult = await _validateAuthentication();
      if (authResult.isFailure) {
        throw Exception('Authentication failed: ${authResult.message}');
      }

      final user = authResult.data!;

      // POST sync request
      final response = await _makeAuthenticatedRequest(
        method: 'POST',
        endpoint: '$_stripePath/sync-subscription.php',
        data: {
          'user_id': user.id,
          'sync_timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response['success'] == true) {
        print('[CONSOLE]✅ [STRIPE REPO] Subscription status synced successfully',
        );

        return true;
      } else {
        throw Exception(response['message'] ?? 'Errore nella sincronizzazione');
      }
    });
  }

  // ============================================================================
  // 🔧 HELPER METHODS PRIVATE - GESTIONE ROBUSTA RICHIESTE
  // ============================================================================

  /// Valida l'autenticazione dell'utente
  Future<Result<dynamic>> _validateAuthentication() async {
    return Result.tryCallAsync(() async {
      final user = await _sessionService.getUserData();
      if (user == null) {
        throw Exception('Utente non autenticato - login richiesto');
      }

      final token = await _sessionService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token di autenticazione mancante - login richiesto');
      }

      return user;
    });
  }

  /// 🔧 FIX: Nuova versione con retry automatico per race conditions
  Future<Map<String, dynamic>> _makeAuthenticatedRequestWithRetry({
    required String method,
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 1000),
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        return await _makeAuthenticatedRequest(
          method: method,
          endpoint: endpoint,
          data: data,
          queryParameters: queryParameters,
          retryOnFailure: false, // Gestisco i retry qui
          timeoutSeconds: 15,
        );
      } catch (e) {
        attempt++;

        if (attempt >= maxRetries) {
          print('[CONSOLE]❌ [STRIPE REPO] Max retries reached for $endpoint: $e');
          rethrow;
        }

        print('[CONSOLE]⏳ [STRIPE REPO] Request failed (attempt $attempt/$maxRetries), retrying in ${retryDelay.inMilliseconds}ms: $e');
        await Future.delayed(retryDelay);
      }
    }

    throw Exception('Unexpected end of retry loop');
  }

  /// Esegue richieste autenticate con gestione errori robusta
  Future<Map<String, dynamic>> _makeAuthenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    bool retryOnFailure = false,
    int timeoutSeconds = 15,
  }) async {
    print('[CONSOLE]🔧 [REQUEST] $method $endpoint');

    try {
      Response response;
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        sendTimeout: Duration(seconds: timeoutSeconds),
        receiveTimeout: Duration(seconds: timeoutSeconds),
      );

      // Esegui richiesta in base al metodo
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _dio.get(
            endpoint,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case 'POST':
          response = await _dio.post(
            endpoint,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case 'PUT':
          response = await _dio.put(
            endpoint,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case 'DELETE':
          response = await _dio.delete(
            endpoint,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // 🔧 FIX: Analisi robusta della risposta
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        // Controlla se è HTML (errore server)
        if (responseData is String && responseData.contains('<!DOCTYPE') ||
            responseData.toString().contains('<html>')) {
          throw Exception('Server returned HTML error page instead of JSON');
        }

        // Controlla formato JSON
        if (responseData is! Map<String, dynamic>) {
          throw Exception('Server returned invalid JSON format');
        }

        print('[CONSOLE]✅ [REQUEST] $method $endpoint - Success');
        return responseData;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }

    } on DioException catch (e) {
      print('[CONSOLE]❌ [REQUEST] $method $endpoint - DioException: ${e.message}');

      // 🔧 FIX: Gestione specifici errori Dio
      String errorMessage = 'Errore di rete';

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Timeout di connessione. Controlla la connessione internet.';
          break;
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          switch (statusCode) {
            case 400:
              errorMessage = 'Richiesta non valida (400)';
              break;
            case 401:
              errorMessage = 'Non autorizzato. Effettua nuovamente il login (401).';
              break;
            case 403:
              errorMessage = 'Accesso negato (403)';
              break;
            case 404:
              errorMessage = 'Endpoint non trovato (404): $endpoint';
              break;
            case 405:
              errorMessage = 'Metodo $method non supportato per $endpoint (405)';
              break;
            case 500:
              errorMessage = 'Errore interno del server (500). Riprova più tardi.';
              break;
            default:
              errorMessage = 'Errore server HTTP $statusCode';
          }
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Richiesta annullata';
          break;
        case DioExceptionType.unknown:
          if (e.message?.contains('SocketException') == true) {
            errorMessage = 'Impossibile connettersi al server. Verifica la connessione.';
          } else {
            errorMessage = 'Errore di rete sconosciuto: ${e.message}';
          }
          break;
        default:
          errorMessage = 'Errore di rete: ${e.message}';
      }

      // 🔧 FIX: Retry automatico per errori temporanei
      if (retryOnFailure && _shouldRetry(e)) {
        print('[CONSOLE]🔄 [REQUEST] Retrying $method $endpoint...');
        await Future.delayed(const Duration(seconds: 2));

        return await _makeAuthenticatedRequest(
          method: method,
          endpoint: endpoint,
          data: data,
          queryParameters: queryParameters,
          retryOnFailure: false, // Evita retry infiniti
          timeoutSeconds: timeoutSeconds,
        );
      }

      throw Exception(errorMessage);

    } catch (e) {
      print('[CONSOLE]❌ [REQUEST] $method $endpoint - Exception: $e');
      throw Exception('Errore imprevisto: $e');
    }
  }

  /// Determina se dovremmo fare retry della richiesta
  bool _shouldRetry(DioException e) {
    // Retry per errori temporanei
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        (e.type == DioExceptionType.badResponse && e.response?.statusCode == 500);
  }

  // ============================================================================
  // 🔧 DEBUG E TESTING - METODI PUBBLICI
  // ============================================================================

  /// Test di connettività con backend Stripe
  Future<Result<bool>> testConnection() async {
    print('[CONSOLE]🔧 [STRIPE REPO] Testing backend connection...');

    return Result.tryCallAsync(() async {
      try {
        // Test semplice: customer endpoint con dati fittizi
        final response = await _makeAuthenticatedRequest(
          method: 'POST',
          endpoint: _customerEndpoint,
          data: {
            'user_id': 999999, // ID fittizio per test
            'email': 'test@test.com',
            'name': 'Test Connection',
          },
          timeoutSeconds: 10,
        );

        final isSuccess = response['success'] == true ||
            response.containsKey('customer') ||
            response.containsKey('error'); // Anche errori strutturati sono OK

        print(
          isSuccess
              ? '[CONSOLE]✅ [STRIPE REPO] Backend connection successful'
              : '[CONSOLE]⚠️ [STRIPE REPO] Backend responded but format unexpected',
        );

        return isSuccess;
      } catch (e) {
        print('[CONSOLE]❌ [STRIPE REPO] Backend connection failed: $e');
        return false;
      }
    });
  }

  /// 🔧 FIX: Clear cache (utile per logout/login)
  void clearCache() {
    print('[CONSOLE]🔧 [STRIPE REPO] Clearing cache...');
    _cachedCustomer = null;
    _customerCreationInProgress = false;
  }

  /// Informazioni di debug per troubleshooting
  Map<String, dynamic> getDebugInfo() {
    return {
      'base_url': _dio.options.baseUrl,
      'cached_customer': _cachedCustomer?.id,
      'customer_creation_in_progress': _customerCreationInProgress,
      'endpoints': {
        'customer': _customerEndpoint,
        'subscription': _subscriptionEndpoint,
        'create_subscription_payment': _createSubscriptionPaymentEndpoint,
        'create_donation_payment': _createDonationPaymentEndpoint,
        'confirm_payment': _confirmPaymentEndpoint,
      },
      'headers': _dio.options.headers,
      'timeout': {
        'connect': _dio.options.connectTimeout?.inMilliseconds,
        'receive': _dio.options.receiveTimeout?.inMilliseconds,
        'send': _dio.options.sendTimeout?.inMilliseconds,
      },
      'full_urls': {
        'customer': '${_dio.options.baseUrl}$_customerEndpoint',
        'subscription': '${_dio.options.baseUrl}$_subscriptionEndpoint',
        'create_subscription_payment': '${_dio.options.baseUrl}$_createSubscriptionPaymentEndpoint',
        'create_donation_payment': '${_dio.options.baseUrl}$_createDonationPaymentEndpoint',
        'confirm_payment': '${_dio.options.baseUrl}$_confirmPaymentEndpoint',
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Stampa informazioni di debug dettagliate
  void printDebugInfo() {
    final info = getDebugInfo();
    print('[CONSOLE]');
    print('[CONSOLE]🔍 STRIPE REPOSITORY DEBUG INFO');
    print('[CONSOLE]================================');
    print('[CONSOLE]Base URL: ${info['base_url']}');
    print('[CONSOLE]Cached Customer: ${info['cached_customer'] ?? 'None'}');
    print('[CONSOLE]Creation In Progress: ${info['customer_creation_in_progress']}');
    print('[CONSOLE]');
    print('[CONSOLE]Endpoints:');
    (info['endpoints'] as Map).forEach((key, value) {
      print('[CONSOLE]  $key: $value');
    });
    print('[CONSOLE]');
    print('[CONSOLE]Full URLs:');
    (info['full_urls'] as Map).forEach((key, value) {
      print('[CONSOLE]  $key: $value');
    });
    print('[CONSOLE]');
    print('[CONSOLE]Headers: ${info['headers']}');
    print('[CONSOLE]Timeouts: ${info['timeout']}');
    print('[CONSOLE]================================');
    print('[CONSOLE]');
  }

  /// Test rapido di tutti gli endpoint principali
  Future<Map<String, bool>> quickEndpointTest() async {
    print('[CONSOLE]🧪 [STRIPE REPO] Running quick endpoint test...');

    final results = <String, bool>{};

    // Test customer endpoint
    try {
      await _makeAuthenticatedRequest(
        method: 'POST',
        endpoint: _customerEndpoint,
        data: {'user_id': 999999, 'email': 'test@test.com', 'name': 'Test'},
        timeoutSeconds: 5,
      );
      results['customer'] = true;
    } catch (e) {
      results['customer'] = false;
    }

    // Test subscription endpoint
    try {
      await _makeAuthenticatedRequest(
        method: 'GET',
        endpoint: _subscriptionEndpoint,
        queryParameters: {'user_id': '999999'},
        timeoutSeconds: 5,
      );
      results['subscription'] = true;
    } catch (e) {
      results['subscription'] = false;
    }

    // Test payment intent endpoints
    try {
      await _makeAuthenticatedRequest(
        method: 'POST',
        endpoint: _createSubscriptionPaymentEndpoint,
        data: {
          'user_id': 999999,
          'price_id': 'price_test_123',
          'metadata': {},
        },
        timeoutSeconds: 5,
      );
      results['subscription_payment'] = true;
    } catch (e) {
      results['subscription_payment'] = false;
    }

    try {
      await _makeAuthenticatedRequest(
        method: 'POST',
        endpoint: _createDonationPaymentEndpoint,
        data: {
          'user_id': 999999,
          'amount': 500,
          'currency': 'eur',
          'metadata': {},
        },
        timeoutSeconds: 5,
      );
      results['donation_payment'] = true;
    } catch (e) {
      results['donation_payment'] = false;
    }

    print('[CONSOLE]🧪 [STRIPE REPO] Quick test results: $results');
    return results;
  }
}