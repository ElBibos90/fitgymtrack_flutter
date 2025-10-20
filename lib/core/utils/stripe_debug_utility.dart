// lib/core/utils/stripe_debug_utility.dart
import 'package:dio/dio.dart';
import '../services/session_service.dart';

/// Utility per debugging problemi Stripe - FIXED per 405 errors
class StripeDebugUtility {
  static final SessionService _sessionService = SessionService();

  /// Test completo di tutti gli endpoint Stripe con metodi HTTP corretti
  static Future<StripeDebugReport> runFullDiagnostic({
    required Dio dio,
  }) async {
    //print('[CONSOLE] [stripe_debug_utility]🔍 [STRIPE DEBUG] Starting full diagnostic...');

    final report = StripeDebugReport();

    // ============================================================================
    // 1. TEST CONFIGURAZIONE BASE
    // ============================================================================

    report.baseUrl = dio.options.baseUrl;
    report.headers = Map<String, dynamic>.from(dio.options.headers);

    // ============================================================================
    // 2. TEST AUTENTICAZIONE
    // ============================================================================

    try {
      final user = await _sessionService.getUserData();
      final token = await _sessionService.getAuthToken();

      report.userAuthenticated = user != null;
      report.tokenAvailable = token != null && token.isNotEmpty;
      report.userId = user?.id;
      report.userEmail = user?.email;

      if (token != null) {
        report.tokenPreview = '${token.substring(0, 20)}...';
      }

      //print('[CONSOLE] [stripe_debug_utility]🔍 [AUTH] User authenticated: ${report.userAuthenticated}');
      //print('[CONSOLE] [stripe_debug_utility]🔍 [AUTH] Token available: ${report.tokenAvailable}');

    } catch (e) {
      report.authError = e.toString();
      //print('[CONSOLE] [stripe_debug_utility]❌ [AUTH] Authentication check failed: $e');
    }

    // ============================================================================
    // 3. TEST CONNETTIVITÀ BASE
    // ============================================================================

    try {
      //print('[CONSOLE] [stripe_debug_utility]🔍 [CONNECTIVITY] Testing base API connectivity...');

      final response = await dio.get('/auth.php', queryParameters: {
        'action': 'verify_token',
      });

      report.baseApiWorking = response.statusCode == 200;
      report.baseApiResponse = response.data.toString();

      //print('[CONSOLE] [stripe_debug_utility]✅ [CONNECTIVITY] Base API working: ${report.baseApiWorking}');

    } catch (e) {
      report.baseApiWorking = false;
      report.baseApiError = e.toString();
      //print('[CONSOLE] [stripe_debug_utility]❌ [CONNECTIVITY] Base API test failed: $e');
    }

    // ============================================================================
    // 4. TEST ENDPOINT STRIPE CON METODI HTTP CORRETTI
    // ============================================================================

    // 🔧 FIX: Endpoint con metodi HTTP corretti
    final stripeEndpoints = [
      EndpointConfig('/stripe/customer.php', 'POST', {
        'user_id': report.userId ?? 1,
        'email': 'test@test.com',
        'name': 'Test User',
      }),
      EndpointConfig('/stripe/subscription.php', 'GET', null, queryParams: {
        'user_id': report.userId ?? 1,
      }),
      EndpointConfig('/stripe/create-subscription-payment-intent.php', 'POST', {
        'user_id': report.userId ?? 1,
        'price_id': 'price_1RXVOfHHtQGHyul9qMGFmpmO',
        'metadata': {},
      }),
      EndpointConfig('/stripe/create-donation-payment-intent.php', 'POST', {
        'user_id': report.userId ?? 1,
        'amount': 500,
        'currency': 'eur',
        'metadata': {},
      }),
      EndpointConfig('/stripe/confirm-payment.php', 'POST', {
        'payment_intent_id': 'pi_test_123',
        'subscription_type': 'premium',
      }),
    ];

    for (final endpointConfig in stripeEndpoints) {
      final result = await _testSingleEndpointWithMethod(dio, endpointConfig);
      report.endpointTests[endpointConfig.path] = result;
    }

    // ============================================================================
    // 5. TEST STRUTTURA SERVER
    // ============================================================================

    await _testServerStructure(dio, report);

    // ============================================================================
    // 6. RISULTATO FINALE
    // ============================================================================

    report.overallHealth = _calculateOverallHealth(report);

    //print('[CONSOLE] [stripe_debug_utility]🔍 [STRIPE DEBUG] Diagnostic completed. Overall health: ${report.overallHealth}');

    return report;
  }

  /// Test di un singolo endpoint con metodo HTTP corretto
  static Future<EndpointTestResult> _testSingleEndpointWithMethod(
      Dio dio,
      EndpointConfig config,
      ) async {
    //print('[CONSOLE] [stripe_debug_utility]🔍 [ENDPOINT] Testing: ${config.method} ${config.path}');

    final result = EndpointTestResult(endpoint: config.path);

    try {
      Response response;

      // 🔧 FIX: Usa il metodo HTTP corretto
      switch (config.method.toLowerCase()) {
        case 'get':
          response = await dio.get(
            config.path,
            queryParameters: config.queryParams,
          ).timeout(const Duration(seconds: 10));
          break;
        case 'post':
          response = await dio.post(
            config.path,
            data: config.data,
            queryParameters: config.queryParams,
          ).timeout(const Duration(seconds: 10));
          break;
        case 'put':
          response = await dio.put(
            config.path,
            data: config.data,
            queryParameters: config.queryParams,
          ).timeout(const Duration(seconds: 10));
          break;
        case 'delete':
          response = await dio.delete(
            config.path,
            data: config.data,
            queryParameters: config.queryParams,
          ).timeout(const Duration(seconds: 10));
          break;
        default:
          throw Exception('Unsupported HTTP method: ${config.method}');
      }

      result.statusCode = response.statusCode ?? 0;
      result.isReachable = true;
      result.httpMethod = config.method;
      result.responsePreview = response.data.toString().length > 200
          ? '${response.data.toString().substring(0, 200)}...'
          : response.data.toString();

      // 🔧 FIX: Analisi più accurata della risposta
      if (response.data.toString().contains('<!DOCTYPE HTML')) {
        result.responseType = 'HTML';
        result.isWorking = false;
        result.error = 'Endpoint returns HTML (likely error page)';
      } else if (response.data is Map) {
        result.responseType = 'JSON';
        final data = response.data as Map;

        if (data.containsKey('success')) {
          result.isWorking = data['success'] == true;
          if (!result.isWorking) {
            result.error = data['message'] ?? 'API returned success: false';
          }
        } else {
          // Alcuni endpoint potrebbero non avere il campo 'success'
          result.isWorking = response.statusCode == 200;
          if (!result.isWorking) {
            result.error = 'No success field in response';
          }
        }
      } else if (response.statusCode == 200) {
        result.responseType = 'OTHER';
        result.isWorking = true;
      } else {
        result.responseType = 'UNKNOWN';
        result.isWorking = false;
        result.error = 'Unexpected response format';
      }

      /*print(
          result.isWorking
              ? '✅ [ENDPOINT] ${config.method} ${config.path} working'
              : '⚠️ [ENDPOINT] ${config.method} ${config.path} reachable but not working: ${result.error}'
      );*/

    } catch (e) {
      result.isReachable = false;
      result.isWorking = false;
      result.error = e.toString();
      result.httpMethod = config.method;

      if (e is DioException) {
        result.statusCode = e.response?.statusCode ?? 0;
        result.responsePreview = e.response?.data?.toString() ?? 'No response data';

        // 🔧 FIX: Gestione specifica errore 405
        if (e.response?.statusCode == 405) {
          result.error = 'Method ${config.method} not allowed. Check if endpoint accepts this HTTP method.';
          result.isReachable = true; // 405 significa che l'endpoint esiste
        }
      }

      //print('[CONSOLE] [stripe_debug_utility]❌ [ENDPOINT] ${config.method} ${config.path} failed: $e');
    }

    return result;
  }

  /// Test struttura del server
  static Future<void> _testServerStructure(Dio dio, StripeDebugReport report) async {
    //print('[CONSOLE] [stripe_debug_utility]🔍 [SERVER] Testing server structure...');

    // Test se la directory /stripe/ esiste
    try {
      final response = await dio.get('/stripe/');
      report.stripeDirectoryExists = response.statusCode != 404;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        report.stripeDirectoryExists = true; // 403 = esiste ma non accessibile
      } else {
        report.stripeDirectoryExists = false;
      }
    }

    // Test se i file .php esistono direttamente
    final phpFiles = [
      'customer.php',
      'subscription.php',
      'create-subscription-payment-intent.php',
      'create-donation-payment-intent.php',
      'confirm-payment.php',
    ];

    for (final file in phpFiles) {
      try {
        final response = await dio.head('/stripe/$file');
        report.phpFilesExist[file] = response.statusCode != 404;
      } catch (e) {
        if (e is DioException) {
          // 🔧 FIX: 405 significa che il file esiste ma non accetta HEAD
          report.phpFilesExist[file] = e.response?.statusCode != 404;
        } else {
          report.phpFilesExist[file] = false;
        }
      }
    }

    //print('[CONSOLE] [stripe_debug_utility]🔍 [SERVER] Stripe directory exists: ${report.stripeDirectoryExists}');
    //print('[CONSOLE] [stripe_debug_utility]🔍 [SERVER] PHP files: ${report.phpFilesExist}');
  }

  /// Calcola la salute generale del sistema
  static String _calculateOverallHealth(StripeDebugReport report) {
    final issues = <String>[];

    if (!report.userAuthenticated) issues.add('User not authenticated');
    if (!report.tokenAvailable) issues.add('No auth token');
    if (!report.stripeDirectoryExists) issues.add('Stripe directory missing');

    final workingEndpoints = report.endpointTests.values.where((test) => test.isWorking).length;
    final reachableEndpoints = report.endpointTests.values.where((test) => test.isReachable).length;
    final totalEndpoints = report.endpointTests.length;

    // 🔧 FIX: Calcolo più accurato della salute
    if (workingEndpoints == totalEndpoints) {
      return 'HEALTHY';
    } else if (reachableEndpoints == totalEndpoints && workingEndpoints >= totalEndpoints / 2) {
      return 'MOSTLY_HEALTHY';
    } else if (reachableEndpoints >= totalEndpoints / 2) {
      return 'DEGRADED';
    } else {
      return 'CRITICAL';
    }
  }

  /// Test rapido per controllare se il problema è risolto
  static Future<bool> quickHealthCheck(Dio dio) async {
    try {
      // Test endpoint customer con POST (corretto)
      final response = await dio.post('/stripe/customer.php', data: {
        'user_id': 1,
        'email': 'test@test.com',
        'name': 'Test User',
      }).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 &&
          response.data is Map &&
          !response.data.toString().contains('<!DOCTYPE HTML');

    } catch (e) {
      return false;
    }
  }

  /// Stampa un report dettagliato
  static void printDetailedReport(StripeDebugReport report) {
    //print('[CONSOLE] [stripe_debug_utility]');
    //print('[CONSOLE] [stripe_debug_utility]🔍 STRIPE DIAGNOSTIC REPORT');
    //print('[CONSOLE] [stripe_debug_utility]============================');
    //print('[CONSOLE] [stripe_debug_utility]Overall Health: ${report.overallHealth}');
    //print('[CONSOLE] [stripe_debug_utility]');
    //print('[CONSOLE] [stripe_debug_utility]🔗 CONNECTIVITY:');
    //print('[CONSOLE] [stripe_debug_utility]  Base URL: ${report.baseUrl}');
    //print('[CONSOLE] [stripe_debug_utility]  Base API Working: ${report.baseApiWorking}');
    //print('[CONSOLE] [stripe_debug_utility]  Stripe Directory Exists: ${report.stripeDirectoryExists}');
    //print('[CONSOLE] [stripe_debug_utility]');
    //print('[CONSOLE] [stripe_debug_utility]🔐 AUTHENTICATION:');
    //print('[CONSOLE] [stripe_debug_utility]  User Authenticated: ${report.userAuthenticated}');
    //print('[CONSOLE] [stripe_debug_utility]  Token Available: ${report.tokenAvailable}');
    //print('[CONSOLE] [stripe_debug_utility]  User ID: ${report.userId}');
    //print('[CONSOLE] [stripe_debug_utility]  Token Preview: ${report.tokenPreview}');
    //print('[CONSOLE] [stripe_debug_utility]');
    //print('[CONSOLE] [stripe_debug_utility]📁 SERVER STRUCTURE:');
    //print('[CONSOLE] [stripe_debug_utility]  PHP Files:');
    report.phpFilesExist.forEach((file, exists) {
      //print('[CONSOLE] [stripe_debug_utility]    $file: $exists');
    });
    //print('[CONSOLE] [stripe_debug_utility]');
    //print('[CONSOLE] [stripe_debug_utility]🎯 ENDPOINT TESTS:');
    // report.endpointTests.forEach((endpoint, result) {
    //   final status = result.isWorking ? '✅' : result.isReachable ? '⚠️' : '❌';
    //   //print('[CONSOLE] [stripe_debug_utility]  $status ${result.httpMethod} $endpoint');
    //   //print('[CONSOLE] [stripe_debug_utility]    Status: ${result.statusCode}');
    //   //print('[CONSOLE] [stripe_debug_utility]    Working: ${result.isWorking}');
    //   //print('[CONSOLE] [stripe_debug_utility]    Reachable: ${result.isReachable}');
    //   //print('[CONSOLE] [stripe_debug_utility]    Error: ${result.error ?? 'None'}');
    //   //print('[CONSOLE] [stripe_debug_utility]');
    // });

    if (report.overallHealth != 'HEALTHY' && report.overallHealth != 'MOSTLY_HEALTHY') {
      //print('[CONSOLE] [stripe_debug_utility]🔧 SUGGESTED FIXES:');
      _printSuggestedFixes(report);
    } else {
      //print('[CONSOLE] [stripe_debug_utility]🎉 SYSTEM STATUS: All major components are working!');
      if (report.overallHealth == 'MOSTLY_HEALTHY') {
        //print('[CONSOLE] [stripe_debug_utility]   Minor issues detected but system is functional.');
      }
    }

    //print('[CONSOLE] [stripe_debug_utility]============================');
    //print('[CONSOLE] [stripe_debug_utility]');
  }

  static void _printSuggestedFixes(StripeDebugReport report) {
    if (!report.baseApiWorking) {
      //print('[CONSOLE] [stripe_debug_utility]  - Check base API configuration and server status');
    }
    if (!report.userAuthenticated || !report.tokenAvailable) {
      //print('[CONSOLE] [stripe_debug_utility]  - Login again to refresh authentication token');
    }
    if (!report.stripeDirectoryExists) {
      //print('[CONSOLE] [stripe_debug_utility]  - Verify /stripe/ directory exists on server');
      //print('[CONSOLE] [stripe_debug_utility]  - Check file upload to https://fitgymtrack.com/api/stripe/');
    }

    final notWorkingEndpoints = report.endpointTests.values.where((test) => !test.isWorking);
    if (notWorkingEndpoints.isNotEmpty) {
      //print('[CONSOLE] [stripe_debug_utility]  - Some endpoints not responding correctly:');
      for (final endpoint in notWorkingEndpoints) {
        if (endpoint.statusCode == 405) {
          //print('[CONSOLE] [stripe_debug_utility]    ${endpoint.endpoint}: Check HTTP method compatibility');
        } else if (endpoint.statusCode == 500) {
          //print('[CONSOLE] [stripe_debug_utility]    ${endpoint.endpoint}: Check PHP error logs');
        } else {
          //print('[CONSOLE] [stripe_debug_utility]    ${endpoint.endpoint}: ${endpoint.error}');
        }
      }
      //print('[CONSOLE] [stripe_debug_utility]  - Verify backend Stripe configuration and keys');
      //print('[CONSOLE] [stripe_debug_utility]  - Check PHP error logs on server');
    }
  }
}

/// Configurazione per test endpoint
class EndpointConfig {
  final String path;
  final String method;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? queryParams;

  EndpointConfig(this.path, this.method, this.data, {this.queryParams});
}

/// Report completo del diagnostic
class StripeDebugReport {
  // Connectivity
  String baseUrl = '';
  bool baseApiWorking = false;
  String? baseApiError;
  String? baseApiResponse;
  Map<String, dynamic> headers = {};

  // Authentication
  bool userAuthenticated = false;
  bool tokenAvailable = false;
  int? userId;
  String? userEmail;
  String? tokenPreview;
  String? authError;

  // Server Structure
  bool stripeDirectoryExists = false;
  Map<String, bool> phpFilesExist = {};

  // Endpoint Tests
  Map<String, EndpointTestResult> endpointTests = {};

  // Overall
  String overallHealth = 'UNKNOWN';
}

/// Risultato del test di un singolo endpoint con HTTP method
class EndpointTestResult {
  final String endpoint;
  bool isReachable = false;
  bool isWorking = false;
  int statusCode = 0;
  String? error;
  String? responsePreview;
  String responseType = 'UNKNOWN';
  String httpMethod = 'GET';

  EndpointTestResult({required this.endpoint});
}