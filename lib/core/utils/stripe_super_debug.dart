// lib/core/utils/stripe_super_debug.dart
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../services/session_service.dart';
import '../config/environment.dart';
import '../config/stripe_config.dart';

/// Super Debug Utility per Stripe - VERSIONE INTELLIGENTE E COMPLETA
class StripeSuperDebug {
  static final SessionService _sessionService = SessionService();

  /// Test super completo di tutto il sistema Stripe
  static Future<StripeSystemReport> runSuperDiagnostic({
    required Dio dio,
    bool verbose = true,
  }) async {
    if (verbose) {
      developer.log('🚀 [SUPER DEBUG] Starting comprehensive Stripe diagnostic...', name: 'StripeSuperDebug');
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
    // FASE 4: STRIPE ENDPOINTS
    // ============================================================================

    if (report.authenticationWorking) {
      await _phase4StripeEndpointsCheck(dio, report, verbose);
    } else {
      if (verbose) {
        developer.log('⚠️ [SUPER DEBUG] Skipping Stripe endpoints - authentication failed', name: 'StripeSuperDebug');
      }
    }

    // ============================================================================
    // FASE 5: ANALISI E RACCOMANDAZIONI
    // ============================================================================

    await _phase5AnalysisAndRecommendations(report, verbose);

    if (verbose) {
      developer.log('✅ [SUPER DEBUG] Comprehensive diagnostic completed!', name: 'StripeSuperDebug');
      developer.log('📊 [SUPER DEBUG] Overall Score: ${report.overallScore}/100', name: 'StripeSuperDebug');
    }

    return report;
  }

  /// FASE 1: Controllo configurazione
  static Future<void> _phase1ConfigurationCheck(StripeSystemReport report, bool verbose) async {
    if (verbose) {
      developer.log('📋 [PHASE 1] Configuration check...', name: 'StripeSuperDebug');
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
      developer.log('📋 [PHASE 1] Stripe key valid: ${report.stripeKeyValid}', name: 'StripeSuperDebug');
      developer.log('📋 [PHASE 1] Test mode: ${report.isTestMode}', name: 'StripeSuperDebug');
      developer.log('📋 [PHASE 1] Demo mode: ${report.isDemoMode}', name: 'StripeSuperDebug');
      developer.log('📋 [PHASE 1] Base URL valid: ${report.baseUrlValid}', name: 'StripeSuperDebug');
    }
  }

  /// FASE 2: Test connettività
  static Future<void> _phase2ConnectivityCheck(Dio dio, StripeSystemReport report, bool verbose) async {
    if (verbose) {
      developer.log('🌐 [PHASE 2] Connectivity check...', name: 'StripeSuperDebug');
    }

    try {
      // Test 1: Base API connectivity
      final response = await dio.get('/auth.php', queryParameters: {
        'action': 'verify_token',
      }).timeout(const Duration(seconds: 10));

      report.baseApiReachable = response.statusCode == 200;
      report.baseApiResponse = response.data.toString();

      if (verbose) {
        developer.log('✅ [PHASE 2] Base API reachable: ${report.baseApiReachable}', name: 'StripeSuperDebug');
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
        developer.log('🌐 [PHASE 2] Stripe directory accessible: ${report.stripeDirectoryAccessible}', name: 'StripeSuperDebug');
        developer.log('🌐 [PHASE 2] PHP files accessible: ${report.phpFilesAccessible}', name: 'StripeSuperDebug');
      }

    } catch (e) {
      report.baseApiReachable = false;
      report.connectivityError = e.toString();
      report.connectivityScore = 0;

      if (verbose) {
        developer.log('❌ [PHASE 2] Connectivity error: $e', name: 'StripeSuperDebug');
      }
    }
  }

  /// FASE 3: Test autenticazione
  static Future<void> _phase3AuthenticationCheck(StripeSystemReport report, bool verbose) async {
    if (verbose) {
      developer.log('🔐 [PHASE 3] Authentication check...', name: 'StripeSuperDebug');
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
        developer.log('🔐 [PHASE 3] User authenticated: ${report.userAuthenticated}', name: 'StripeSuperDebug');
        developer.log('🔐 [PHASE 3] Token available: ${report.tokenAvailable}', name: 'StripeSuperDebug');
        developer.log('🔐 [PHASE 3] User ID: ${report.userId}', name: 'StripeSuperDebug');
      }

    } catch (e) {
      report.authenticationWorking = false;
      report.authenticationError = e.toString();
      report.authenticationScore = 0;

      if (verbose) {
        developer.log('❌ [PHASE 3] Authentication error: $e', name: 'StripeSuperDebug');
      }
    }
  }

  /// FASE 4: Test endpoint Stripe
  static Future<void> _phase4StripeEndpointsCheck(Dio dio, StripeSystemReport report, bool verbose) async {
    if (verbose) {
      developer.log('🎯 [PHASE 4] Stripe endpoints check...', name: 'StripeSuperDebug');
    }

    final endpoints = [
      StripeEndpointTest(
        name: 'customer',
        endpoint: '/stripe/customer.php',
        method: 'POST',
        data: {
          'user_id': report.userId ?? 999999,
          'email': report.userEmail ?? 'test@example.com',
          'name': 'Debug Test User',
        },
      ),
      StripeEndpointTest(
        name: 'subscription',
        endpoint: '/stripe/subscription.php',
        method: 'GET',
        queryParams: {
          'user_id': (report.userId ?? 999999).toString(),
        },
      ),
      StripeEndpointTest(
        name: 'subscription_payment',
        endpoint: '/stripe/create-subscription-payment-intent.php',
        method: 'POST',
        data: {
          'user_id': report.userId ?? 999999,
          'price_id': StripeConfig.subscriptionPlans['premium_monthly']?.stripePriceId ?? 'price_test_123',
          'metadata': {'test': true},
        },
      ),
      StripeEndpointTest(
        name: 'donation_payment',
        endpoint: '/stripe/create-donation-payment-intent.php',
        method: 'POST',
        data: {
          'user_id': report.userId ?? 999999,
          'amount': 500,
          'currency': 'eur',
          'metadata': {'test': true},
        },
      ),
      StripeEndpointTest(
        name: 'confirm_payment',
        endpoint: '/stripe/confirm-payment.php',
        method: 'POST',
        data: {
          'payment_intent_id': 'pi_test_1234567890',
          'subscription_type': 'premium',
        },
      ),
    ];

    int successfulEndpoints = 0;

    for (final endpointTest in endpoints) {
      final result = await _testSingleEndpoint(dio, endpointTest, verbose);
      report.endpointResults[endpointTest.name] = result;

      if (result.isWorking) {
        successfulEndpoints++;
      }

      if (verbose) {
        final status = result.isWorking ? '✅' : result.isReachable ? '⚠️' : '❌';
        developer.log(
            '$status [PHASE 4] ${endpointTest.name}: ${result.statusMessage}',
            name: 'StripeSuperDebug'
        );
      }
    }

    report.stripeEndpointsScore = (successfulEndpoints / endpoints.length * 100).round();

    if (verbose) {
      developer.log('🎯 [PHASE 4] Successful endpoints: $successfulEndpoints/${endpoints.length}', name: 'StripeSuperDebug');
    }
  }

  /// Test di un singolo endpoint
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
            result.errorReason = 'HTTP 405 - ${endpointTest.method} not supported';
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

    return result;
  }

  /// FASE 5: Analisi e raccomandazioni
  static Future<void> _phase5AnalysisAndRecommendations(StripeSystemReport report, bool verbose) async {
    if (verbose) {
      developer.log('🔍 [PHASE 5] Analysis and recommendations...', name: 'StripeSuperDebug');
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
      developer.log('🔍 [PHASE 5] System status: ${report.systemStatus}', name: 'StripeSuperDebug');
      developer.log('🔍 [PHASE 5] Recommendations: ${report.recommendations.length}', name: 'StripeSuperDebug');
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
    print('');
    print('🚀 STRIPE SUPER DIAGNOSTIC REPORT');
    print('================================================');
    print('📊 Overall Score: ${report.overallScore}/100');
    print('🏥 System Status: ${report.systemStatus}');
    print('');

    // Configurazione
    print('📋 CONFIGURATION (Score: ${report.configurationScore}/100)');
    print('   Stripe key set: ${report.stripeKeySet}');
    print('   Stripe key valid: ${report.stripeKeyValid}');
    print('   Test mode: ${report.isTestMode}');
    print('   Demo mode: ${report.isDemoMode}');
    print('   Base URL valid: ${report.baseUrlValid}');
    print('');

    // Connettività
    print('🌐 CONNECTIVITY (Score: ${report.connectivityScore}/100)');
    print('   Base API reachable: ${report.baseApiReachable}');
    print('   Stripe directory accessible: ${report.stripeDirectoryAccessible}');
    print('   PHP Files:');
    report.phpFilesAccessible.forEach((file, accessible) {
      print('     $file: ${accessible ? "✅" : "❌"}');
    });
    print('');

    // Autenticazione
    print('🔐 AUTHENTICATION (Score: ${report.authenticationScore}/100)');
    print('   User authenticated: ${report.userAuthenticated}');
    print('   Token available: ${report.tokenAvailable}');
    print('   User ID: ${report.userId}');
    print('   Token preview: ${report.tokenPreview}');
    print('');

    // Endpoints
    print('🎯 STRIPE ENDPOINTS (Score: ${report.stripeEndpointsScore}/100)');
    report.endpointResults.forEach((name, result) {
      final status = result.isWorking ? "✅" : result.isReachable ? "⚠️" : "❌";
      print('   $status $name: ${result.statusMessage}');
      if (!result.isWorking && result.errorReason != null) {
        print('     Error: ${result.errorReason}');
      }
    });
    print('');

    // Raccomandazioni
    if (report.recommendations.isNotEmpty) {
      print('💡 RECOMMENDATIONS:');
      for (final rec in report.recommendations) {
        print('   $rec');
      }
      print('');
    }

    // Fix rapidi
    if (report.quickFixes.isNotEmpty) {
      print('🔧 QUICK FIXES:');
      for (final fix in report.quickFixes) {
        print('   • $fix');
      }
      print('');
    }

    print('================================================');
    print('');
  }

  /// Test rapido per problemi comuni
  static Future<StripeQuickTestResults> runQuickTest(Dio dio) async {
    developer.log('⚡ [QUICK TEST] Running quick Stripe test...', name: 'StripeSuperDebug');

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

    developer.log('⚡ [QUICK TEST] Score: ${results.score}/100', name: 'StripeSuperDebug');
    developer.log('⚡ [QUICK TEST] Overall success: ${results.overallSuccess}', name: 'StripeSuperDebug');

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