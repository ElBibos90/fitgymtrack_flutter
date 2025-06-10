// lib/core/utils/stripe_super_debug.dart
import 'package:dio/dio.dart';

import '../services/session_service.dart';
import '../config/environment.dart';
import '../config/stripe_config.dart';

/// Super Debug Utility per Stripe - VERSIONE INTELLIGENTE CON SMART TEST
class StripeSuperDebug {
  static final SessionService _sessionService = SessionService();

  /// Test super completo di tutto il sistema Stripe
  static Future<StripeSystemReport> runSuperDiagnostic({
    required Dio dio,
    bool verbose = true,
  }) async {
    if (verbose) {
      print('[CONSOLE] [stripe_super_debug]🚀 [SUPER DEBUG] Starting comprehensive Stripe diagnostic...');
    }

    final report = StripeSystemReport();

    // ============================================================================
    // FASE 1: CONFIGURAZIONE E SETUP
    // ============================================================================

    await _phase1ConfigurationCheck(report, verbose);

    // ============================================================================
    // FASE 2: CONNETTIVITÀ BASE
    // ============================================================================

    await _phase2ConnectivityCheck(dio, report, verbose);

    // ============================================================================
    // FASE 3: AUTENTICAZIONE
    // ============================================================================

    await _phase3AuthenticationCheck(report, verbose);

    // ============================================================================
    // FASE 4: STRIPE ENDPOINTS INTELLIGENTI
    // ============================================================================

    if (report.authenticationWorking) {
      await _phase4StripeEndpointsSmartCheck(dio, report, verbose);
    } else {
      if (verbose) {
        print('[CONSOLE] [stripe_super_debug]⚠️ [SUPER DEBUG] Skipping Stripe endpoints - authentication failed');
      }
    }

    // ============================================================================
    // FASE 5: ANALISI E RACCOMANDAZIONI
    // ============================================================================

    await _phase5AnalysisAndRecommendations(report, verbose);

    if (verbose) {
      print('[CONSOLE] [stripe_super_debug]✅ [SUPER DEBUG] Comprehensive diagnostic completed!');
      print('[CONSOLE] [stripe_super_debug]📊 [SUPER DEBUG] Overall Score: ${report.overallScore}/100');
    }

    return report;
  }

  /// FASE 1: Controllo configurazione
  static Future<void> _phase1ConfigurationCheck(StripeSystemReport report, bool verbose) async {
    if (verbose) {
      print('[CONSOLE] [stripe_super_debug]📋 [PHASE 1] Configuration check...');
    }

    // Stripe Configuration
    report.stripeKeySet = StripeConfig.publishableKey.isNotEmpty;
    report.stripeKeyValid = StripeConfig.isValidKey(StripeConfig.publishableKey);
    report.isTestMode = StripeConfig.isTestMode;
    report.isDemoMode = StripeConfig.isDemoMode;
    report.configurationScore = _calculateConfigScore();

    // Environment Configuration
    report.baseUrl = Environment.baseUrl;
    report.baseUrlValid = Environment.baseUrl.isNotEmpty && Environment.baseUrl.startsWith('https://');

    if (verbose) {
      print('[CONSOLE] [stripe_super_debug]📋 [PHASE 1] Stripe key valid: ${report.stripeKeyValid}');
      print('[CONSOLE] [stripe_super_debug]📋 [PHASE 1] Test mode: ${report.isTestMode}');
      print('[CONSOLE] [stripe_super_debug]📋 [PHASE 1] Demo mode: ${report.isDemoMode}');
      print('[CONSOLE] [stripe_super_debug]📋 [PHASE 1] Base URL valid: ${report.baseUrlValid}');
    }
  }

  /// FASE 2: Test connettività
  static Future<void> _phase2ConnectivityCheck(Dio dio, StripeSystemReport report, bool verbose) async {
    if (verbose) {
      print('[CONSOLE] [stripe_super_debug]🌐 [PHASE 2] Connectivity check...');
    }

    try {
      // Test 1: Base API connectivity con GET
      final response = await dio.get('/auth.php', queryParameters: {
        'action': 'verify_token',
      }).timeout(const Duration(seconds: 10));

      report.baseApiReachable = response.statusCode == 200;
      report.baseApiResponse = response.data.toString();

      if (verbose) {
        print('[CONSOLE] [stripe_super_debug]✅ [PHASE 2] Base API reachable: ${report.baseApiReachable}');
      }

      // Test 2: Stripe directory
      try {
        final stripeResponse = await dio.get('/stripe/').timeout(const Duration(seconds: 5));
        report.stripeDirectoryAccessible = stripeResponse.statusCode != 404;
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 403) {
          report.stripeDirectoryAccessible = true; // 403 = exists but forbidden
        } else {
          report.stripeDirectoryAccessible = false;
        }
      }

      // Test 3: Individual PHP files
      final phpFiles = [
        'customer.php',
        'subscription.php',
        'create-subscription-payment-intent.php',
        'create-donation-payment-intent.php',
        'confirm-payment.php',
      ];

      for (final file in phpFiles) {
        try {
          final fileResponse = await dio.head('/stripe/$file').timeout(const Duration(seconds: 3));
          report.phpFilesAccessible[file] = fileResponse.statusCode != 404;
        } catch (e) {
          if (e is DioException) {
            // 405 = method not allowed ma file esiste
            // 403 = forbidden ma file esiste
            // 500 = server error ma file esiste
            report.phpFilesAccessible[file] = e.response?.statusCode != 404;
          } else {
            report.phpFilesAccessible[file] = false;
          }
        }
      }

      report.connectivityScore = _calculateConnectivityScore(report);

      if (verbose) {
        print('[CONSOLE] [stripe_super_debug]🌐 [PHASE 2] Stripe directory accessible: ${report.stripeDirectoryAccessible}');
        print('[CONSOLE] [stripe_super_debug]🌐 [PHASE 2] PHP files accessible: ${report.phpFilesAccessible}');
      }

    } catch (e) {
      report.baseApiReachable = false;
      report.connectivityError = e.toString();
      report.connectivityScore = 0;

      if (verbose) {
        print('[CONSOLE] [stripe_super_debug]❌ [PHASE 2] Connectivity error: $e');
      }
    }
  }

  /// FASE 3: Test autenticazione
  static Future<void> _phase3AuthenticationCheck(StripeSystemReport report, bool verbose) async {
    if (verbose) {
      print('[CONSOLE] [stripe_super_debug]🔐 [PHASE 3] Authentication check...');
    }

    try {
      final user = await _sessionService.getUserData();
      final token = await _sessionService.getAuthToken();

      report.userAuthenticated = user != null;
      report.tokenAvailable = token != null && token.isNotEmpty;
      report.userId = user?.id;
      report.userEmail = user?.email;

      if (token != null && token.length > 20) {
        report.tokenPreview = '${token.substring(0, 20)}...';
      }

      report.authenticationWorking = report.userAuthenticated && report.tokenAvailable;
      report.authenticationScore = report.authenticationWorking ? 100 : 0;

      if (verbose) {
        print('[CONSOLE] [stripe_super_debug]🔐 [PHASE 3] User authenticated: ${report.userAuthenticated}');
        print('[CONSOLE] [stripe_super_debug]🔐 [PHASE 3] Token available: ${report.tokenAvailable}');
        print('[CONSOLE] [stripe_super_debug]🔐 [PHASE 3] User ID: ${report.userId}');
      }

    } catch (e) {
      report.authenticationWorking = false;
      report.authenticationError = e.toString();
      report.authenticationScore = 0;

      if (verbose) {
        print('[CONSOLE] [stripe_super_debug]❌ [PHASE 3] Authentication error: $e');
      }
    }
  }

  /// FASE 4: Test endpoint Stripe INTELLIGENTI
  static Future<void> _phase4StripeEndpointsSmartCheck(Dio dio, StripeSystemReport report, bool verbose) async {
    if (verbose) {
      print('[CONSOLE] [stripe_super_debug]🎯 [PHASE 4] Smart Stripe endpoints check...');
    }

    // Store per Payment Intent ID creato per test successivi
    String? createdPaymentIntentId;
    int successfulEndpoints = 0;

    // ============================================================================
    // TEST 1: CUSTOMER
    // ============================================================================
    final customerResult = await _testSingleEndpoint(dio, StripeEndpointTest(
      name: 'customer',
      endpoint: '/stripe/customer.php',
      method: 'POST',
      data: {
        'user_id': report.userId ?? 999999,
        'email': report.userEmail ?? 'test@example.com',
        'name': 'Debug Test User',
      },
    ), verbose);

    report.endpointResults['customer'] = customerResult;
    if (customerResult.isWorking) successfulEndpoints++;

    // ============================================================================
    // TEST 2: SUBSCRIPTION
    // ============================================================================
    final subscriptionResult = await _testSingleEndpoint(dio, StripeEndpointTest(
      name: 'subscription',
      endpoint: '/stripe/subscription.php',
      method: 'GET',
      queryParams: {
        'user_id': (report.userId ?? 999999).toString(),
      },
    ), verbose);

    report.endpointResults['subscription'] = subscriptionResult;
    if (subscriptionResult.isWorking) successfulEndpoints++;

    // ============================================================================
    // TEST 3: SUBSCRIPTION PAYMENT
    // ============================================================================
    final subscriptionPaymentResult = await _testSingleEndpoint(dio, StripeEndpointTest(
      name: 'subscription_payment',
      endpoint: '/stripe/create-subscription-payment-intent.php',
      method: 'POST',
      data: {
        'user_id': report.userId ?? 999999,
        'price_id': StripeConfig.subscriptionPlans['premium_monthly']?.stripePriceId ?? 'price_test_123',
        'metadata': {'debug_test': true},
      },
    ), verbose);

    report.endpointResults['subscription_payment'] = subscriptionPaymentResult;
    if (subscriptionPaymentResult.isWorking) successfulEndpoints++;

    // ============================================================================
    // TEST 4: DONATION PAYMENT (e salva Payment Intent ID)
    // ============================================================================
    final donationPaymentResult = await _testDonationPaymentAndExtractId(dio, report, verbose);
    report.endpointResults['donation_payment'] = donationPaymentResult.result;
    if (donationPaymentResult.result.isWorking) {
      successfulEndpoints++;
      createdPaymentIntentId = donationPaymentResult.paymentIntentId;
    }

    // ============================================================================
    // TEST 5: CONFIRM PAYMENT (usa Payment Intent ID reale se disponibile)
    // ============================================================================
    final confirmPaymentResult = await _testConfirmPaymentIntelligent(dio, createdPaymentIntentId, verbose);
    report.endpointResults['confirm_payment'] = confirmPaymentResult;
    if (confirmPaymentResult.isWorking) successfulEndpoints++;

    report.stripeEndpointsScore = (successfulEndpoints / 5 * 100).round();

    if (verbose) {
      print('[CONSOLE] [stripe_super_debug]🎯 [PHASE 4] Successful endpoints: $successfulEndpoints/5');
    }
  }

  /// Test intelligente del donation payment che estrae il Payment Intent ID
  static Future<DonationTestResult> _testDonationPaymentAndExtractId(
      Dio dio,
      StripeSystemReport report,
      bool verbose
      ) async {
    final result = StripeEndpointResult(name: 'donation_payment');
    String? paymentIntentId;

    try {
      final response = await dio.post(
        '/stripe/create-donation-payment-intent.php',
        data: {
          'user_id': report.userId ?? 999999,
          'amount': 500,
          'currency': 'eur',
          'metadata': {'debug_test': true},
        },
      ).timeout(const Duration(seconds: 10));

      result.isReachable = true;
      result.statusCode = response.statusCode ?? 0;

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          result.isWorking = true;
          result.statusMessage = 'Working correctly';

          // Estrai Payment Intent ID per test successivi
          final paymentIntentData = responseData['data']?['payment_intent'];
          if (paymentIntentData is Map<String, dynamic>) {
            paymentIntentId = paymentIntentData['payment_intent_id'] as String?;

            if (verbose && paymentIntentId != null) {
              print('[CONSOLE] [stripe_super_debug]🎯 [SMART TEST] Extracted Payment Intent ID: ${paymentIntentId!.substring(0, 20)}...');
            }
          }
        } else {
          result.isWorking = false;
          result.statusMessage = 'API error: ${responseData['message'] ?? 'unknown'}';
        }
      } else {
        result.isWorking = false;
        result.statusMessage = 'Invalid response format';
      }

    } catch (e) {
      _handleEndpointError(result, e);
    }

    return DonationTestResult(result: result, paymentIntentId: paymentIntentId);
  }

  /// Test intelligente del confirm payment
  static Future<StripeEndpointResult> _testConfirmPaymentIntelligent(
      Dio dio,
      String? realPaymentIntentId,
      bool verbose
      ) async {
    final result = StripeEndpointResult(name: 'confirm_payment');

    if (realPaymentIntentId == null) {
      // Nessun Payment Intent ID reale disponibile - testa solo connettività
      if (verbose) {
        print('[CONSOLE] [stripe_super_debug]🎯 [SMART TEST] No real Payment Intent ID - testing connectivity only');
      }

      try {
        final response = await dio.post(
          '/stripe/confirm-payment.php',
          data: {
            'payment_intent_id': 'pi_test_connectivity_check',
            'subscription_type': 'donation',
          },
        ).timeout(const Duration(seconds: 10));

        result.isReachable = true;
        result.statusCode = response.statusCode ?? 0;

        // Per il test di connettività, anche un errore "Payment Intent non trovato" è OK
        if (response.statusCode == 200) {
          if (response.data is Map<String, dynamic>) {
            final responseData = response.data as Map<String, dynamic>;
            if (responseData['message']?.toString().contains('Payment Intent non trovato') == true) {
              result.isWorking = true; // Endpoint funziona ma non trova ID (normale)
              result.statusMessage = 'Working (connectivity verified)';
            } else {
              result.isWorking = responseData['success'] == true;
              result.statusMessage = responseData['success'] == true
                  ? 'Working correctly'
                  : 'API error: ${responseData['message'] ?? 'unknown'}';
            }
          }
        } else {
          result.isWorking = false;
          result.statusMessage = 'HTTP error ${response.statusCode}';
        }

      } catch (e) {
        _handleEndpointError(result, e);
      }
    } else {
      // Test con Payment Intent ID reale
      if (verbose) {
        print('[CONSOLE] [stripe_super_debug]🎯 [SMART TEST] Testing with real Payment Intent ID: ${realPaymentIntentId.substring(0, 20)}...');
      }

      try {
        final response = await dio.post(
          '/stripe/confirm-payment.php',
          data: {
            'payment_intent_id': realPaymentIntentId,
            'subscription_type': 'donation',
          },
        ).timeout(const Duration(seconds: 10));

        result.isReachable = true;
        result.statusCode = response.statusCode ?? 0;

        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;

          // Con Payment Intent reale, potrebbe fallire per altri motivi (es. non succeeded)
          // ma l'importante è che l'endpoint sia raggiungibile e funzionale
          if (responseData['message']?.toString().contains('non completato') == true ||
              responseData['message']?.toString().contains('requires_payment_method') == true) {
            result.isWorking = true; // Endpoint funziona, Payment Intent solo non è completed
            result.statusMessage = 'Working (payment not completed yet)';
          } else {
            result.isWorking = responseData['success'] == true;
            result.statusMessage = responseData['success'] == true
                ? 'Working correctly'
                : 'API error: ${responseData['message'] ?? 'unknown'}';
          }
        } else {
          result.isWorking = false;
          result.statusMessage = 'Invalid response format';
        }

      } catch (e) {
        _handleEndpointError(result, e);
      }
    }

    return result;
  }

  /// Gestisce errori comuni degli endpoint
  static void _handleEndpointError(StripeEndpointResult result, dynamic e) {
    if (e is DioException) {
      result.statusCode = e.response?.statusCode ?? 0;
      result.responsePreview = e.response?.data?.toString() ?? 'No response data';

      switch (e.response?.statusCode) {
        case 404:
          result.isReachable = false;
          result.statusMessage = 'Endpoint not found';
          result.errorReason = 'HTTP 404 - File does not exist';
          break;
        case 405:
          result.isReachable = true;
          result.isWorking = false;
          result.statusMessage = 'Method not allowed';
          result.errorReason = 'HTTP 405 - Method not supported';
          break;
        case 500:
          result.isReachable = true;
          result.isWorking = false;
          result.statusMessage = 'Server error';
          result.errorReason = 'HTTP 500 - PHP or server error';
          break;
        default:
          result.isReachable = true;
          result.isWorking = false;
          result.statusMessage = 'HTTP error ${e.response?.statusCode}';
          result.errorReason = e.message ?? 'Unknown HTTP error';
      }
    } else {
      result.isReachable = false;
      result.statusMessage = 'Network error';
      result.errorReason = e.toString();
    }
  }

  /// Test di un singolo endpoint (versione generica)
  static Future<StripeEndpointResult> _testSingleEndpoint(
      Dio dio,
      StripeEndpointTest endpointTest,
      bool verbose
      ) async {
    final result = StripeEndpointResult(name: endpointTest.name);

    try {
      Response response;

      // Esegui richiesta
      switch (endpointTest.method.toLowerCase()) {
        case 'get':
          response = await dio.get(
            endpointTest.endpoint,
            queryParameters: endpointTest.queryParams,
          ).timeout(const Duration(seconds: 10));
          break;
        case 'post':
          response = await dio.post(
            endpointTest.endpoint,
            data: endpointTest.data,
            queryParameters: endpointTest.queryParams,
          ).timeout(const Duration(seconds: 10));
          break;
        default:
          throw Exception('Unsupported method: ${endpointTest.method}');
      }

      result.isReachable = true;
      result.statusCode = response.statusCode ?? 0;
      result.responsePreview = response.data.toString().length > 100
          ? '${response.data.toString().substring(0, 100)}...'
          : response.data.toString();

      // Analisi intelligente della risposta
      if (response.statusCode == 200) {
        final responseData = response.data;

        // Controlla se è HTML (errore)
        if (responseData.toString().contains('<!DOCTYPE') ||
            responseData.toString().contains('<html>')) {
          result.isWorking = false;
          result.errorReason = 'Server returned HTML error page';
          result.statusMessage = 'Reachable but returns HTML error';
        }
        // Controlla JSON con success field
        else if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('success')) {
            result.isWorking = responseData['success'] == true;
            result.statusMessage = result.isWorking
                ? 'Working correctly'
                : 'API error: ${responseData['message'] ?? 'unknown'}';
            if (!result.isWorking) {
              result.errorReason = responseData['message']?.toString() ?? 'API returned success: false';
            }
          } else {
            // JSON valido ma senza campo success
            result.isWorking = true;
            result.statusMessage = 'Working (non-standard response)';
          }
        }
        // Altri formati
        else {
          result.isWorking = true;
          result.statusMessage = 'Working (non-JSON response)';
        }
      } else {
        result.isWorking = false;
        result.errorReason = 'HTTP ${response.statusCode}';
        result.statusMessage = 'HTTP error ${response.statusCode}';
      }

    } catch (e) {
      _handleEndpointError(result, e);
    }

    return result;
  }

  /// FASE 5: Analisi e raccomandazioni
  static Future<void> _phase5AnalysisAndRecommendations(StripeSystemReport report, bool verbose) async {
    if (verbose) {
      print('[CONSOLE] [stripe_super_debug]🔍 [PHASE 5] Analysis and recommendations...');
    }

    // Calcola score generale
    report.overallScore = _calculateOverallScore(report);

    // Determina stato del sistema
    if (report.overallScore >= 90) {
      report.systemStatus = 'EXCELLENT';
    } else if (report.overallScore >= 75) {
      report.systemStatus = 'GOOD';
    } else if (report.overallScore >= 50) {
      report.systemStatus = 'NEEDS_ATTENTION';
    } else if (report.overallScore >= 25) {
      report.systemStatus = 'POOR';
    } else {
      report.systemStatus = 'CRITICAL';
    }

    // Genera raccomandazioni
    report.recommendations = _generateRecommendations(report);
    report.quickFixes = _generateQuickFixes(report);

    if (verbose) {
      print('[CONSOLE] [stripe_super_debug]🔍 [PHASE 5] System status: ${report.systemStatus}');
      print('[CONSOLE] [stripe_super_debug]🔍 [PHASE 5] Recommendations: ${report.recommendations.length}');
    }
  }

  /// Calcola score configurazione
  static int _calculateConfigScore() {
    int score = 0;

    if (StripeConfig.publishableKey.isNotEmpty) score += 20;
    if (StripeConfig.isValidKey(StripeConfig.publishableKey)) score += 30;
    if (!StripeConfig.isDemoMode) score += 25;
    if (StripeConfig.subscriptionPlans.isNotEmpty) score += 15;
    if (Environment.baseUrl.startsWith('https://')) score += 10;

    return score;
  }

  /// Calcola score connettività
  static int _calculateConnectivityScore(StripeSystemReport report) {
    int score = 0;

    if (report.baseApiReachable) score += 40;
    if (report.stripeDirectoryAccessible) score += 30;

    final accessibleFiles = report.phpFilesAccessible.values.where((accessible) => accessible).length;
    final totalFiles = report.phpFilesAccessible.length;
    if (totalFiles > 0) {
      score += (accessibleFiles / totalFiles * 30).round();
    }

    return score;
  }

  /// Calcola score generale
  static int _calculateOverallScore(StripeSystemReport report) {
    final scores = [
      report.configurationScore,
      report.connectivityScore,
      report.authenticationScore,
      report.stripeEndpointsScore,
    ];

    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  /// Genera raccomandazioni
  static List<String> _generateRecommendations(StripeSystemReport report) {
    final recommendations = <String>[];

    // Configurazione
    if (!report.stripeKeyValid) {
      recommendations.add('🔑 CRITICAL: Configure valid Stripe publishable key in stripe_config.dart');
    }
    if (report.isDemoMode) {
      recommendations.add('⚠️ WARNING: Replace demo Stripe keys with real test keys');
    }
    if (!report.baseUrlValid) {
      recommendations.add('🌐 CRITICAL: Set valid HTTPS base URL in environment.dart');
    }

    // Connettività
    if (!report.baseApiReachable) {
      recommendations.add('🔌 CRITICAL: API server is not reachable - check server status');
    }
    if (!report.stripeDirectoryAccessible) {
      recommendations.add('📁 CRITICAL: /stripe/ directory not accessible - upload Stripe PHP files');
    }

    // Files
    final missingFiles = report.phpFilesAccessible.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key);
    if (missingFiles.isNotEmpty) {
      recommendations.add('📄 CRITICAL: Missing PHP files: ${missingFiles.join(', ')}');
    }

    // Autenticazione
    if (!report.authenticationWorking) {
      recommendations.add('🔐 HIGH: Authentication not working - login again');
    }

    // Endpoints
    final brokenEndpoints = report.endpointResults.entries
        .where((entry) => !entry.value.isWorking)
        .map((entry) => entry.key);
    if (brokenEndpoints.isNotEmpty) {
      recommendations.add('🎯 HIGH: Fix broken endpoints: ${brokenEndpoints.join(', ')}');
    }

    return recommendations;
  }

  /// Genera fix rapidi
  static List<String> _generateQuickFixes(StripeSystemReport report) {
    final fixes = <String>[];

    if (report.isDemoMode) {
      fixes.add('Replace StripeConfig.publishableKey with real test key');
    }

    if (!report.authenticationWorking) {
      fixes.add('Logout and login again to refresh token');
    }

    if (!report.stripeDirectoryAccessible) {
      fixes.add('Upload all PHP files to /api/stripe/ directory');
      fixes.add('Check .htaccess configuration in stripe directory');
    }

    final methodErrors = report.endpointResults.values
        .where((result) => result.errorReason?.contains('405') == true);
    if (methodErrors.isNotEmpty) {
      fixes.add('Check HTTP method compatibility in PHP endpoints');
    }

    final serverErrors = report.endpointResults.values
        .where((result) => result.errorReason?.contains('500') == true);
    if (serverErrors.isNotEmpty) {
      fixes.add('Check PHP error logs on server');
      fixes.add('Verify Stripe SDK installation on backend');
    }

    return fixes;
  }

  /// Stampa report completo
  static void printFullReport(StripeSystemReport report) {
    print('[CONSOLE] [stripe_super_debug]');
    print('[CONSOLE] [stripe_super_debug]🚀 STRIPE SUPER DIAGNOSTIC REPORT');
    print('[CONSOLE] [stripe_super_debug]================================================');
    print('[CONSOLE] [stripe_super_debug]📊 Overall Score: ${report.overallScore}/100');
    print('[CONSOLE] [stripe_super_debug]🏥 System Status: ${report.systemStatus}');
    print('[CONSOLE] [stripe_super_debug]');

    // Configurazione
    print('[CONSOLE] [stripe_super_debug]📋 CONFIGURATION (Score: ${report.configurationScore}/100)');
    print('[CONSOLE] [stripe_super_debug]   Stripe key set: ${report.stripeKeySet}');
    print('[CONSOLE] [stripe_super_debug]   Stripe key valid: ${report.stripeKeyValid}');
    print('[CONSOLE] [stripe_super_debug]   Test mode: ${report.isTestMode}');
    print('[CONSOLE] [stripe_super_debug]   Demo mode: ${report.isDemoMode}');
    print('[CONSOLE] [stripe_super_debug]   Base URL valid: ${report.baseUrlValid}');
    print('[CONSOLE] [stripe_super_debug]');

    // Connettività
    print('[CONSOLE] [stripe_super_debug]🌐 CONNECTIVITY (Score: ${report.connectivityScore}/100)');
    print('[CONSOLE] [stripe_super_debug]   Base API reachable: ${report.baseApiReachable}');
    print('[CONSOLE] [stripe_super_debug]   Stripe directory accessible: ${report.stripeDirectoryAccessible}');
    print('[CONSOLE] [stripe_super_debug]   PHP Files:');
    report.phpFilesAccessible.forEach((file, accessible) {
      print('[CONSOLE] [stripe_super_debug]     $file: ${accessible ? "✅" : "❌"}');
    });
    print('[CONSOLE] [stripe_super_debug]');

    // Autenticazione
    print('[CONSOLE] [stripe_super_debug]🔐 AUTHENTICATION (Score: ${report.authenticationScore}/100)');
    print('[CONSOLE] [stripe_super_debug]   User authenticated: ${report.userAuthenticated}');
    print('[CONSOLE] [stripe_super_debug]   Token available: ${report.tokenAvailable}');
    print('[CONSOLE] [stripe_super_debug]   User ID: ${report.userId}');
    print('[CONSOLE] [stripe_super_debug]   Token preview: ${report.tokenPreview}');
    print('[CONSOLE] [stripe_super_debug]');

    // Endpoints
    print('[CONSOLE] [stripe_super_debug]🎯 STRIPE ENDPOINTS (Score: ${report.stripeEndpointsScore}/100)');
    report.endpointResults.forEach((name, result) {
      final status = result.isWorking ? "✅" : result.isReachable ? "⚠️" : "❌";
      print('[CONSOLE] [stripe_super_debug]   $status $name: ${result.statusMessage}');
      if (!result.isWorking && result.errorReason != null) {
        print('[CONSOLE] [stripe_super_debug]     Error: ${result.errorReason}');
      }
    });
    print('[CONSOLE] [stripe_super_debug]');

    // Raccomandazioni
    if (report.recommendations.isNotEmpty) {
      print('[CONSOLE] [stripe_super_debug]💡 RECOMMENDATIONS:');
      for (final rec in report.recommendations) {
        print('[CONSOLE] [stripe_super_debug]   $rec');
      }
      print('[CONSOLE] [stripe_super_debug]');
    }

    // Fix rapidi
    if (report.quickFixes.isNotEmpty) {
      print('[CONSOLE] [stripe_super_debug]🔧 QUICK FIXES:');
      for (final fix in report.quickFixes) {
        print('[CONSOLE] [stripe_super_debug]   • $fix');
      }
      print('[CONSOLE] [stripe_super_debug]');
    }

    print('[CONSOLE] [stripe_super_debug]================================================');
    print('[CONSOLE] [stripe_super_debug]');
  }

  /// Test rapido per problemi comuni
  static Future<StripeQuickTestResults> runQuickTest(Dio dio) async {
    print('[CONSOLE] [stripe_super_debug]⚡ [QUICK TEST] Running quick Stripe test...');

    final results = StripeQuickTestResults();

    // Test 1: Configurazione
    results.configValid = StripeConfig.isValidKey(StripeConfig.publishableKey) && !StripeConfig.isDemoMode;

    // Test 2: Connettività base
    try {
      final response = await dio.get('/auth.php', queryParameters: {'action': 'verify_token'}).timeout(const Duration(seconds: 5));
      results.apiReachable = response.statusCode == 200;
    } catch (e) {
      results.apiReachable = false;
    }

    // Test 3: Autenticazione
    try {
      final user = await _sessionService.getUserData();
      final token = await _sessionService.getAuthToken();
      results.authWorking = user != null && token != null && token.isNotEmpty;
    } catch (e) {
      results.authWorking = false;
    }

    // Test 4: Endpoint customer (più importante)
    try {
      final response = await dio.post('/stripe/customer.php', data: {
        'user_id': 999999,
        'email': 'test@test.com',
        'name': 'Test User',
      }).timeout(const Duration(seconds: 10));

      results.stripeWorking = response.statusCode == 200 &&
          !response.data.toString().contains('<!DOCTYPE');
    } catch (e) {
      results.stripeWorking = false;
      results.stripeError = e.toString();
    }

    // Calcola risultato generale
    final passedTests = [
      results.configValid,
      results.apiReachable,
      results.authWorking,
      results.stripeWorking,
    ].where((test) => test).length;

    results.overallSuccess = passedTests >= 3; // 3 su 4 test devono passare
    results.score = (passedTests / 4 * 100).round();

    print('[CONSOLE] [stripe_super_debug]⚡ [QUICK TEST] Score: ${results.score}/100');
    print('[CONSOLE] [stripe_super_debug]⚡ [QUICK TEST] Overall success: ${results.overallSuccess}');

    return results;
  }
}

// ============================================================================
// MODELLI DATI
// ============================================================================

class StripeSystemReport {
  // Configuration
  bool stripeKeySet = false;
  bool stripeKeyValid = false;
  bool isTestMode = false;
  bool isDemoMode = false;
  String baseUrl = '';
  bool baseUrlValid = false;
  int configurationScore = 0;

  // Connectivity
  bool baseApiReachable = false;
  String? baseApiResponse;
  String? connectivityError;
  bool stripeDirectoryAccessible = false;
  Map<String, bool> phpFilesAccessible = {};
  int connectivityScore = 0;

  // Authentication
  bool userAuthenticated = false;
  bool tokenAvailable = false;
  int? userId;
  String? userEmail;
  String? tokenPreview;
  bool authenticationWorking = false;
  String? authenticationError;
  int authenticationScore = 0;

  // Stripe Endpoints
  Map<String, StripeEndpointResult> endpointResults = {};
  int stripeEndpointsScore = 0;

  // Overall
  int overallScore = 0;
  String systemStatus = 'UNKNOWN';
  List<String> recommendations = [];
  List<String> quickFixes = [];
}

class StripeEndpointTest {
  final String name;
  final String endpoint;
  final String method;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? queryParams;

  StripeEndpointTest({
    required this.name,
    required this.endpoint,
    required this.method,
    this.data,
    this.queryParams,
  });
}

class StripeEndpointResult {
  final String name;
  bool isReachable = false;
  bool isWorking = false;
  int statusCode = 0;
  String statusMessage = '';
  String? errorReason;
  String? responsePreview;

  StripeEndpointResult({required this.name});
}

class DonationTestResult {
  final StripeEndpointResult result;
  final String? paymentIntentId;

  DonationTestResult({required this.result, this.paymentIntentId});
}

class StripeQuickTestResults {
  bool configValid = false;
  bool apiReachable = false;
  bool authWorking = false;
  bool stripeWorking = false;
  String? stripeError;
  bool overallSuccess = false;
  int score = 0;

  String get statusText {
    if (score >= 90) return 'EXCELLENT';
    if (score >= 75) return 'GOOD';
    if (score >= 50) return 'FAIR';
    if (score >= 25) return 'POOR';
    return 'CRITICAL';
  }
}