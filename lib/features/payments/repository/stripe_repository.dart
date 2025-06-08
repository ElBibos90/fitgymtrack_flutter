// lib/features/payments/repository/stripe_repository.dart
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../../../core/utils/result.dart';
import '../../../core/network/api_client.dart';
import '../models/stripe_models.dart';
import '../../../core/services/session_service.dart';

/// Repository per gestire le operazioni Stripe tramite API backend - VERSIONE CORRETTA E ROBUSTA
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
  // 🔧 CUSTOMER OPERATIONS - CORRETTE
  // ============================================================================

  /// Crea o ottiene un cliente Stripe per l'utente corrente
  Future<Result<StripeCustomer>> getOrCreateCustomer() async {
    developer.log('🔧 [STRIPE REPO] Getting or creating Stripe customer...', name: 'StripeRepository');

    return Result.tryCallAsync(() async {
      // Verifica autenticazione
      final authResult = await _validateAuthentication();
      if (authResult.isFailure) {
        throw Exception('Authentication failed: ${authResult.message}');
      }

      final user = authResult.data!;

      // 🔧 FIX: Dati customer con validazione
      final customerData = {
        'user_id': user.id,
        'email': user.email ?? 'user${user.id}@fitgymtrack.com',
        'name': user.username ?? 'User ${user.id}',
      };

      developer.log('🔧 [STRIPE REPO] Customer data: $customerData', name: 'StripeRepository');

      // 🔧 FIX: POST corretto con gestione errori
      final response = await _makeAuthenticatedRequest(
        method: 'POST',
        endpoint: _customerEndpoint,
        data: customerData,
      );

      if (response['success'] == true && response['customer'] != null) {
        final customer = StripeCustomer.fromJson(response['customer']);

        developer.log(
          '✅ [STRIPE REPO] Customer obtained: ${customer.id}',
          name: 'StripeRepository',
        );

        return customer;
      } else {
        throw Exception(response['message'] ?? 'Errore nella creazione del cliente Stripe');
      }
    });
  }

  // ============================================================================
  // 🔧 PAYMENT INTENT OPERATIONS - CORRETTE E VALIDATE
  // ============================================================================

  /// Crea un Payment Intent per una subscription
  /// Crea un Payment Intent per una subscription - FIXED VERSION
  Future<Result<StripePaymentIntentResponse>> createSubscriptionPaymentIntent({
    required String priceId,
    Map<String, dynamic>? metadata,
  }) async {
    developer.log(
      '🔧 [STRIPE REPO] Creating subscription payment intent for price: $priceId',
      name: 'StripeRepository',
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

      developer.log('🔧 [STRIPE REPO] Payment data: $paymentData', name: 'StripeRepository');

      // 🔧 FIX: Richiesta con retry automatico
      final response = await _makeAuthenticatedRequest(
        method: 'POST',
        endpoint: _createSubscriptionPaymentEndpoint,
        data: paymentData,
        retryOnFailure: true,
      );

      developer.log('🔧 [STRIPE REPO] Full response: $response', name: 'StripeRepository');

      // 🔧 FIX: Parsing corretto della risposta - SUPPORTA ENTRAMBI I FORMATI
      if (response['success'] == true) {
        Map<String, dynamic>? paymentIntentData;

        // Controlla nuovo formato: data.payment_intent
        if (response['data'] != null && response['data']['payment_intent'] != null) {
          paymentIntentData = response['data']['payment_intent'];
          developer.log('🔧 [STRIPE REPO] Using new format: data.payment_intent', name: 'StripeRepository');
        }
        // Controlla vecchio formato: payment_intent diretto
        else if (response['payment_intent'] != null) {
          paymentIntentData = response['payment_intent'];
          developer.log('🔧 [STRIPE REPO] Using old format: payment_intent', name: 'StripeRepository');
        }

        if (paymentIntentData != null) {
          try {
            final paymentIntent = StripePaymentIntentResponse.fromJson(paymentIntentData);

            developer.log(
              '✅ [STRIPE REPO] Payment intent created successfully: ${paymentIntent.paymentIntentId}',
              name: 'StripeRepository',
            );

            return paymentIntent;
          } catch (e) {
            developer.log('❌ [STRIPE REPO] JSON parsing error: $e', name: 'StripeRepository');
            developer.log('❌ [STRIPE REPO] Payment intent data: $paymentIntentData', name: 'StripeRepository');
            throw Exception('Error parsing payment intent response: $e');
          }
        } else {
          developer.log('❌ [STRIPE REPO] Payment intent data not found in response', name: 'StripeRepository');
          developer.log('❌ [STRIPE REPO] Response structure: ${response.keys.toList()}', name: 'StripeRepository');
          throw Exception('Payment intent data not found in response. Available keys: ${response.keys.toList()}');
        }
      } else {
        final errorMessage = response['message'] ?? 'Errore nella creazione del payment intent per subscription';
        developer.log('❌ [STRIPE REPO] Server returned success=false: $errorMessage', name: 'StripeRepository');
        throw Exception(errorMessage);
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

      developer.log('🔧 [STRIPE REPO] Donation data: $donationData', name: 'StripeRepository');

      // 🔧 FIX: Richiesta con retry automatico
      final response = await _makeAuthenticatedRequest(
        method: 'POST',
        endpoint: _createDonationPaymentEndpoint,
        data: donationData,
        retryOnFailure: true,
      );

      if (response['success'] == true && response['payment_intent'] != null) {
        final paymentIntent = StripePaymentIntentResponse.fromJson(response['payment_intent']);

        developer.log(
          '✅ [STRIPE REPO] Donation payment intent created: ${paymentIntent.paymentIntentId}',
          name: 'StripeRepository',
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
    developer.log(
      '🔧 [STRIPE REPO] Confirming payment success: $paymentIntentId',
      name: 'StripeRepository',
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

      developer.log('🔧 [STRIPE REPO] Confirm data: $confirmData', name: 'StripeRepository');

      // 🔧 FIX: Richiesta con retry automatico e timeout esteso
      final response = await _makeAuthenticatedRequest(
        method: 'POST',
        endpoint: _confirmPaymentEndpoint,
        data: confirmData,
        retryOnFailure: true,
        timeoutSeconds: 30, // Timeout più lungo per conferma pagamento
      );

      if (response['success'] == true) {
        developer.log(
          '✅ [STRIPE REPO] Payment confirmed successfully',
          name: 'StripeRepository',
        );

        return true;
      } else {
        throw Exception(response['message'] ?? 'Errore nella conferma del pagamento');
      }
    });
  }

  // ============================================================================
  // 🔧 SUBSCRIPTION OPERATIONS - IMPLEMENTAZIONE COMPLETA
  // ============================================================================

  /// Ottiene la subscription corrente dell'utente
  Future<Result<StripeSubscription?>> getCurrentSubscription() async {
    developer.log('🔧 [STRIPE REPO] Getting current subscription...', name: 'StripeRepository');

    return Result.tryCallAsync(() async {
      // Verifica autenticazione
      final authResult = await _validateAuthentication();
      if (authResult.isFailure) {
        throw Exception('Authentication failed: ${authResult.message}');
      }

      final user = authResult.data!;

      // 🔧 FIX: GET con query parameters
      final response = await _makeAuthenticatedRequest(
        method: 'GET',
        endpoint: _subscriptionEndpoint,
        queryParameters: {
          'user_id': user.id.toString(),
          'include_cancelled': 'true', // Include anche quelle cancellate
        },
      );

      if (response['success'] == true) {
        if (response['subscription'] != null) {
          final subscription = StripeSubscription.fromJson(response['subscription']);

          developer.log(
            '✅ [STRIPE REPO] Current subscription found: ${subscription.id} (${subscription.status})',
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
        throw Exception(response['message'] ?? 'Errore nel recupero della subscription');
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

      developer.log('🔧 [STRIPE REPO] Cancel data: $cancelData', name: 'StripeRepository');

      // 🔧 FIX: DELETE method per cancellazione
      final response = await _makeAuthenticatedRequest(
        method: 'DELETE',
        endpoint: _subscriptionEndpoint,
        data: cancelData,
        retryOnFailure: true,
      );

      if (response['success'] == true) {
        developer.log(
          '✅ [STRIPE REPO] Subscription canceled successfully',
          name: 'StripeRepository',
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
    developer.log(
      '🔧 [STRIPE REPO] Reactivating subscription: $subscriptionId',
      name: 'StripeRepository',
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

      developer.log('🔧 [STRIPE REPO] Reactivate data: $reactivateData', name: 'StripeRepository');

      // 🔧 FIX: PUT method per riattivazione
      final response = await _makeAuthenticatedRequest(
        method: 'PUT',
        endpoint: _subscriptionEndpoint,
        data: reactivateData,
        retryOnFailure: true,
      );

      if (response['success'] == true && response['subscription'] != null) {
        final subscription = StripeSubscription.fromJson(response['subscription']);

        developer.log(
          '✅ [STRIPE REPO] Subscription reactivated: ${subscription.id}',
          name: 'StripeRepository',
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
    developer.log('🔧 [STRIPE REPO] Getting payment methods...', name: 'StripeRepository');

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

        developer.log(
          '✅ [STRIPE REPO] Retrieved ${paymentMethods.length} payment methods',
          name: 'StripeRepository',
        );

        return paymentMethods;
      } else {
        // Non è un errore se non ci sono metodi di pagamento
        developer.log(
          '✅ [STRIPE REPO] No payment methods found',
          name: 'StripeRepository',
        );

        return <StripePaymentMethod>[];
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
        developer.log(
          '✅ [STRIPE REPO] Payment method deleted successfully',
          name: 'StripeRepository',
        );

        return true;
      } else {
        throw Exception(response['message'] ?? 'Errore nella rimozione del metodo di pagamento');
      }
    });
  }

  /// Sincronizza lo stato della subscription locale con Stripe
  Future<Result<bool>> syncSubscriptionStatus() async {
    developer.log('🔧 [STRIPE REPO] Syncing subscription status...', name: 'StripeRepository');

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
        developer.log(
          '✅ [STRIPE REPO] Subscription status synced successfully',
          name: 'StripeRepository',
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

  /// Esegue richieste autenticate con gestione errori robusta
  Future<Map<String, dynamic>> _makeAuthenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    bool retryOnFailure = false,
    int timeoutSeconds = 15,
  }) async {
    developer.log('🔧 [REQUEST] $method $endpoint', name: 'StripeRepository');

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

        developer.log('✅ [REQUEST] $method $endpoint - Success', name: 'StripeRepository');
        return responseData;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }

    } on DioException catch (e) {
      developer.log('❌ [REQUEST] $method $endpoint - DioException: ${e.message}', name: 'StripeRepository');

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
        developer.log('🔄 [REQUEST] Retrying $method $endpoint...', name: 'StripeRepository');
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
      developer.log('❌ [REQUEST] $method $endpoint - Exception: $e', name: 'StripeRepository');
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
    developer.log('🔧 [STRIPE REPO] Testing backend connection...', name: 'StripeRepository');

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

        developer.log(
          isSuccess
              ? '✅ [STRIPE REPO] Backend connection successful'
              : '⚠️ [STRIPE REPO] Backend responded but format unexpected',
          name: 'StripeRepository',
        );

        return isSuccess;
      } catch (e) {
        developer.log('❌ [STRIPE REPO] Backend connection failed: $e', name: 'StripeRepository');
        return false;
      }
    });
  }

  /// Informazioni di debug per troubleshooting
  Map<String, dynamic> getDebugInfo() {
    return {
      'base_url': _dio.options.baseUrl,
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
    print('');
    print('🔍 STRIPE REPOSITORY DEBUG INFO');
    print('================================');
    print('Base URL: ${info['base_url']}');
    print('');
    print('Endpoints:');
    (info['endpoints'] as Map).forEach((key, value) {
      print('  $key: $value');
    });
    print('');
    print('Full URLs:');
    (info['full_urls'] as Map).forEach((key, value) {
      print('  $key: $value');
    });
    print('');
    print('Headers: ${info['headers']}');
    print('Timeouts: ${info['timeout']}');
    print('================================');
    print('');
  }

  /// Test rapido di tutti gli endpoint principali
  Future<Map<String, bool>> quickEndpointTest() async {
    developer.log('🧪 [STRIPE REPO] Running quick endpoint test...', name: 'StripeRepository');

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

    developer.log('🧪 [STRIPE REPO] Quick test results: $results', name: 'StripeRepository');
    return results;
  }
}