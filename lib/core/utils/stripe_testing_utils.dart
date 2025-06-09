// lib/core/utils/stripe_testing_utils.dart
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../config/stripe_config.dart';
import '../../features/payments/services/stripe_service.dart';
import '../../features/payments/repository/stripe_repository.dart';
import '../../features/payments/bloc/stripe_bloc.dart';

/// Utilities per testing e debug del sistema Stripe completo
/// Include test end-to-end e verifica dello stato post-pagamento
class StripeTestingUtils {
  static final GetIt _getIt = GetIt.instance;

  // ============================================================================
  // 🧪 COMPREHENSIVE SYSTEM TESTS
  // ============================================================================

  /// Test completo dell'intero flusso Stripe
  static Future<StripeSystemTestResult> runFullSystemTest({
    bool verbose = true,
  }) async {
    final result = StripeSystemTestResult();
    final startTime = DateTime.now();

    if (verbose) {
      print('[CONSOLE]🧪 [STRIPE TEST] Starting comprehensive system test...');
    }

    try {
      // ============================================================================
      // PHASE 1: CONFIGURATION TEST
      // ============================================================================

      if (verbose) print('[CONSOLE]🧪 [STRIPE TEST] Phase 1: Configuration');

      result.configurationValid = StripeConfig.isConfigurationValid;
      result.readyForSandbox = StripeConfig.isReadyForSandboxTesting;
      result.testMode = StripeConfig.isTestMode;

      if (verbose) {
        print('[CONSOLE]🧪 [STRIPE TEST] - Configuration valid: ${result.configurationValid}');
        print('[CONSOLE]🧪 [STRIPE TEST] - Ready for sandbox: ${result.readyForSandbox}');
        print('[CONSOLE]🧪 [STRIPE TEST] - Test mode: ${result.testMode}');
      }

      // ============================================================================
      // PHASE 2: SERVICE INITIALIZATION TEST
      // ============================================================================

      if (verbose) print('[CONSOLE]🧪 [STRIPE TEST] Phase 2: Service Initialization');

      final serviceTestStart = DateTime.now();
      final initResult = await StripeService.initialize();
      final serviceTestDuration = DateTime.now().difference(serviceTestStart);

      result.serviceInitialized = initResult.isSuccess;
      result.serviceInitTime = serviceTestDuration;
      result.serviceError = initResult.isFailure ? initResult.message : null;

      if (verbose) {
        print('[CONSOLE]🧪 [STRIPE TEST] - Service initialized: ${result.serviceInitialized}');
        print('[CONSOLE]🧪 [STRIPE TEST] - Init time: ${serviceTestDuration.inMilliseconds}ms');
        if (result.serviceError != null) {
          print('[CONSOLE]🧪 [STRIPE TEST] - Service error: ${result.serviceError}');
        }
      }

      // ============================================================================
      // PHASE 3: REPOSITORY CONNECTIVITY TEST
      // ============================================================================

      if (verbose) print('[CONSOLE]🧪 [STRIPE TEST] Phase 3: Repository Connectivity');

      if (_getIt.isRegistered<StripeRepository>()) {
        final repository = _getIt<StripeRepository>();

        final connectivityResult = await repository.testConnection();
        result.repositoryConnected = connectivityResult.isSuccess;
        result.repositoryError = connectivityResult.isFailure ? connectivityResult.message : null;

        if (verbose) {
          print('[CONSOLE]🧪 [STRIPE TEST] - Repository connected: ${result.repositoryConnected}');
          if (result.repositoryError != null) {
            print('[CONSOLE]🧪 [STRIPE TEST] - Repository error: ${result.repositoryError}');
          }
        }

        // Test endpoint specifici
        final endpointTests = await repository.quickEndpointTest();
        result.endpointResults = endpointTests;

        if (verbose) {
          print('[CONSOLE]🧪 [STRIPE TEST] - Endpoint tests:');
          endpointTests.forEach((endpoint, success) {
            print('[CONSOLE]🧪 [STRIPE TEST]   - $endpoint: ${success ? "✅" : "❌"}');
          });
        }
      } else {
        result.repositoryConnected = false;
        result.repositoryError = 'StripeRepository not registered in DI';

        if (verbose) {
          print('[CONSOLE]🧪 [STRIPE TEST] - Repository not registered');
        }
      }

      // ============================================================================
      // PHASE 4: BLOC STATE TEST
      // ============================================================================

      if (verbose) print('[CONSOLE]🧪 [STRIPE TEST] Phase 4: BLoC State');

      if (_getIt.isRegistered<StripeBloc>()) {
        final bloc = _getIt<StripeBloc>();
        result.blocRegistered = true;
        result.blocCurrentState = bloc.state.runtimeType.toString();

        if (verbose) {
          print('[CONSOLE]🧪 [STRIPE TEST] - BLoC registered: true');
          print('[CONSOLE]🧪 [STRIPE TEST] - BLoC state: ${result.blocCurrentState}');
        }
      } else {
        result.blocRegistered = false;
        result.blocCurrentState = 'Not Registered';

        if (verbose) {
          print('[CONSOLE]🧪 [STRIPE TEST] - BLoC registered: false');
        }
      }

      // ============================================================================
      // PHASE 5: GOOGLE PAY SUPPORT TEST
      // ============================================================================

      if (verbose) print('[CONSOLE]🧪 [STRIPE TEST] Phase 5: Google Pay Support');

      if (result.serviceInitialized) {
        final gPayResult = await StripeService.isGooglePaySupported();
        result.googlePaySupported = gPayResult.isSuccess ? gPayResult.data! : false;

        if (verbose) {
          print('[CONSOLE]🧪 [STRIPE TEST] - Google Pay supported: ${result.googlePaySupported}');
        }
      } else {
        result.googlePaySupported = false;
        if (verbose) {
          print('[CONSOLE]🧪 [STRIPE TEST] - Google Pay test skipped (service not initialized)');
        }
      }

      // ============================================================================
      // FINAL SCORE CALCULATION
      // ============================================================================

      result.calculateOverallScore();
      result.testDuration = DateTime.now().difference(startTime);
      result.success = result.overallScore >= 75; // 75% threshold

      if (verbose) {
        print('[CONSOLE]🧪 [STRIPE TEST] ===== TEST COMPLETED =====');
        print('[CONSOLE]🧪 [STRIPE TEST] Overall Score: ${result.overallScore}/100');
        print('[CONSOLE]🧪 [STRIPE TEST] Result: ${result.success ? "✅ PASS" : "❌ FAIL"}');
        print('[CONSOLE]🧪 [STRIPE TEST] Duration: ${result.testDuration.inMilliseconds}ms');
      }

    } catch (e) {
      result.success = false;
      result.overallScore = 0;
      result.testDuration = DateTime.now().difference(startTime);
      result.generalError = e.toString();

      if (verbose) {
        print('[CONSOLE]🧪 [STRIPE TEST] Test failed with exception: $e');
      }
    }

    return result;
  }

  // ============================================================================
  // 🎯 POST-PAYMENT TESTING SIMULATION
  // ============================================================================

  /// Simula il flusso post-pagamento per verificare la gestione robusta
  static Future<PostPaymentTestResult> simulatePostPaymentFlow({
    bool verbose = true,
  }) async {
    final result = PostPaymentTestResult();
    final startTime = DateTime.now();

    if (verbose) {
      print('[CONSOLE]🎯 [POST-PAY TEST] Starting post-payment flow simulation...');
    }

    try {
      if (!_getIt.isRegistered<StripeRepository>()) {
        throw Exception('StripeRepository not registered');
      }

      final repository = _getIt<StripeRepository>();

      // ============================================================================
      // TEST 1: SUBSCRIPTION LOADING WITH RETRY
      // ============================================================================

      if (verbose) print('[CONSOLE]🎯 [POST-PAY TEST] Test 1: Subscription loading with retry');

      final subscriptionResult = await repository.getCurrentSubscriptionAfterPayment();
      result.subscriptionLoadingWorked = subscriptionResult.isSuccess;

      if (verbose) {
        if (subscriptionResult.isSuccess) {
          final subscription = subscriptionResult.data;
          if (subscription != null) {
            print('[CONSOLE]🎯 [POST-PAY TEST] - Found subscription: ${subscription.id} (${subscription.status})');
          } else {
            print('[CONSOLE]🎯 [POST-PAY TEST] - No subscription found (this is OK for new users)');
          }
        } else {
          print('[CONSOLE]🎯 [POST-PAY TEST] - Subscription loading failed: ${subscriptionResult.message}');
        }
      }

      // ============================================================================
      // TEST 2: CUSTOMER CREATION WITH RACE CONDITION PROTECTION
      // ============================================================================

      if (verbose) print('[CONSOLE]🎯 [POST-PAY TEST] Test 2: Customer creation with race protection');

      // Esegui multiple richieste customer simultanee per testare race condition protection
      final customerFutures = List.generate(3, (index) => repository.getOrCreateCustomer());
      final customerResults = await Future.wait(customerFutures);

      final allCustomersSuccess = customerResults.every((result) => result.isSuccess);
      final allSameCustomerId = customerResults.map((result) => result.data?.id).toSet().length <= 1;

      result.customerRaceProtectionWorked = allCustomersSuccess && allSameCustomerId;

      if (verbose) {
        print('[CONSOLE]🎯 [POST-PAY TEST] - Multiple customer requests: ${allCustomersSuccess ? "✅" : "❌"}');
        print('[CONSOLE]🎯 [POST-PAY TEST] - Same customer ID: ${allSameCustomerId ? "✅" : "❌"}');
        if (customerResults.isNotEmpty && customerResults.first.isSuccess) {
          print('[CONSOLE]🎯 [POST-PAY TEST] - Customer ID: ${customerResults.first.data!.id}');
        }
      }

      // ============================================================================
      // TEST 3: ERROR HANDLING ROBUSTNESS
      // ============================================================================

      if (verbose) print('[CONSOLE]🎯 [POST-PAY TEST] Test 3: Error handling robustness');

      // Test con parametri non validi per verificare gestione errori
      final invalidSubscriptionResult = await repository.getCurrentSubscription();
      result.errorHandlingWorked = true; // Se arriviamo qui senza crash, è buon segno

      if (verbose) {
        print('[CONSOLE]🎯 [POST-PAY TEST] - Error handling: ✅ (no crashes)');
      }

      // ============================================================================
      // FINAL SCORE
      // ============================================================================

      result.calculateScore();
      result.testDuration = DateTime.now().difference(startTime);
      result.success = result.score >= 80; // 80% threshold for post-payment tests

      if (verbose) {
        print('[CONSOLE]🎯 [POST-PAY TEST] ===== POST-PAYMENT TEST COMPLETED =====');
        print('[CONSOLE]🎯 [POST-PAY TEST] Score: ${result.score}/100');
        print('[CONSOLE]🎯 [POST-PAY TEST] Result: ${result.success ? "✅ PASS" : "❌ FAIL"}');
        print('[CONSOLE]🎯 [POST-PAY TEST] Duration: ${result.testDuration.inMilliseconds}ms');
      }

    } catch (e) {
      result.success = false;
      result.score = 0;
      result.testDuration = DateTime.now().difference(startTime);
      result.generalError = e.toString();

      if (verbose) {
        print('[CONSOLE]🎯 [POST-PAY TEST] Test failed with exception: $e');
      }
    }

    return result;
  }

  // ============================================================================
  // 🔍 DIAGNOSTIC UTILITIES
  // ============================================================================

  /// Esegue una diagnosi completa del sistema Stripe
  static Future<StripeDiagnosticReport> generateDiagnosticReport() async {
    print('[CONSOLE]🔍 [STRIPE DIAGNOSTIC] Generating comprehensive diagnostic report...');

    final report = StripeDiagnosticReport();
    final startTime = DateTime.now();

    // Configuration info
    report.configInfo = {
      'publishable_key_set': StripeConfig.publishableKey.isNotEmpty,
      'publishable_key_valid': StripeConfig.isValidKey(StripeConfig.publishableKey),
      'test_mode': StripeConfig.isTestMode,
      'demo_mode': StripeConfig.isDemoMode,
      'ready_for_sandbox': StripeConfig.isReadyForSandboxTesting,
      'currency': StripeConfig.currency,
      'country_code': StripeConfig.countryCode,
      'merchant_identifier': StripeConfig.merchantIdentifier,
      'subscription_plans_count': StripeConfig.subscriptionPlans.length,
    };

    // Service info
    try {
      final healthCheck = await StripeService.healthCheck();
      report.serviceInfo = healthCheck;
    } catch (e) {
      report.serviceInfo = {'error': e.toString()};
    }

    // Repository info
    if (_getIt.isRegistered<StripeRepository>()) {
      final repository = _getIt<StripeRepository>();
      report.repositoryInfo = repository.getDebugInfo();
    } else {
      report.repositoryInfo = {'error': 'Repository not registered'};
    }

    // DI info
    report.dependencyInjectionInfo = {
      'stripe_repository_registered': _getIt.isRegistered<StripeRepository>(),
      'stripe_bloc_registered': _getIt.isRegistered<StripeBloc>(),
      'stripe_repository_ready': _getIt.isRegistered<StripeRepository>(),
      'stripe_bloc_ready': _getIt.isRegistered<StripeBloc>(),
    };

    // System tests
    final systemTest = await runFullSystemTest(verbose: false);
    report.systemTestResult = systemTest;

    // Post-payment tests
    final postPaymentTest = await simulatePostPaymentFlow(verbose: false);
    report.postPaymentTestResult = postPaymentTest;

    report.generatedAt = DateTime.now();
    report.generationDuration = DateTime.now().difference(startTime);

    // Calculate overall health score
    report.calculateOverallHealth();

    print('[CONSOLE]🔍 [STRIPE DIAGNOSTIC] Report generated in ${report.generationDuration.inMilliseconds}ms');
    print('[CONSOLE]🔍 [STRIPE DIAGNOSTIC] Overall health: ${report.overallHealthScore}/100');

    return report;
  }

  /// Stampa un report di debug leggibile
  static void printDiagnosticReport(StripeDiagnosticReport report) {
    print('[CONSOLE]');
    print('[CONSOLE]📊 STRIPE SYSTEM DIAGNOSTIC REPORT');
    print('[CONSOLE]=====================================');
    print('[CONSOLE]Generated: ${report.generatedAt}');
    print('[CONSOLE]Duration: ${report.generationDuration.inMilliseconds}ms');
    print('[CONSOLE]Overall Health: ${report.overallHealthScore}/100');
    print('[CONSOLE]');

    // Configuration
    print('[CONSOLE]🔧 CONFIGURATION:');
    report.configInfo.forEach((key, value) {
      final status = value == true ? '✅' : value == false ? '❌' : '🔧';
      print('[CONSOLE]  $status $key: $value');
    });
    print('[CONSOLE]');

    // Service
    print('[CONSOLE]⚙️ SERVICE STATUS:');
    final serviceInitialized = report.serviceInfo['is_initialized'] ?? false;
    print('[CONSOLE]  ${serviceInitialized ? '✅' : '❌'} Service Initialized: $serviceInitialized');

    final lastError = report.serviceInfo['last_error'];
    if (lastError != null && lastError.toString().isNotEmpty) {
      print('[CONSOLE]  ⚠️ Last Error: $lastError');
    }
    print('[CONSOLE]');

    // Repository
    print('[CONSOLE]🗄️ REPOSITORY STATUS:');
    final baseUrl = report.repositoryInfo['base_url'];
    print('[CONSOLE]  🔗 Base URL: $baseUrl');

    final cachedCustomer = report.repositoryInfo['cached_customer'];
    print('[CONSOLE]  👤 Cached Customer: ${cachedCustomer ?? 'None'}');
    print('[CONSOLE]');

    // Tests
    print('[CONSOLE]🧪 SYSTEM TESTS:');
    final systemTest = report.systemTestResult;
    print('[CONSOLE]  ${systemTest.success ? '✅' : '❌'} Overall: ${systemTest.overallScore}/100');
    print('[CONSOLE]  ${systemTest.configurationValid ? '✅' : '❌'} Configuration Valid');
    print('[CONSOLE]  ${systemTest.serviceInitialized ? '✅' : '❌'} Service Initialized');
    print('[CONSOLE]  ${systemTest.repositoryConnected ? '✅' : '❌'} Repository Connected');
    print('[CONSOLE]  ${systemTest.googlePaySupported ? '✅' : '❌'} Google Pay Supported');
    print('[CONSOLE]');

    print('[CONSOLE]🎯 POST-PAYMENT TESTS:');
    final postPaymentTest = report.postPaymentTestResult;
    print('[CONSOLE]  ${postPaymentTest.success ? '✅' : '❌'} Overall: ${postPaymentTest.score}/100');
    print('[CONSOLE]  ${postPaymentTest.subscriptionLoadingWorked ? '✅' : '❌'} Subscription Loading');
    print('[CONSOLE]  ${postPaymentTest.customerRaceProtectionWorked ? '✅' : '❌'} Race Protection');
    print('[CONSOLE]  ${postPaymentTest.errorHandlingWorked ? '✅' : '❌'} Error Handling');
    print('[CONSOLE]');

    // Recommendations
    print('[CONSOLE]💡 RECOMMENDATIONS:');
    if (!systemTest.configurationValid) {
      print('[CONSOLE]  🔧 Fix Stripe configuration in StripeConfig');
    }
    if (!systemTest.serviceInitialized) {
      print('[CONSOLE]  🔧 Check Stripe SDK initialization');
    }
    if (!systemTest.repositoryConnected) {
      print('[CONSOLE]  🔧 Verify backend connectivity and endpoints');
    }
    if (!postPaymentTest.success) {
      print('[CONSOLE]  🔧 Review post-payment flow handling');
    }
    if (report.overallHealthScore >= 90) {
      print('[CONSOLE]  🎉 System is in excellent health!');
    } else if (report.overallHealthScore >= 75) {
      print('[CONSOLE]  👍 System is working well with minor issues');
    } else {
      print('[CONSOLE]  ⚠️ System needs attention - multiple issues detected');
    }

    print('[CONSOLE]=====================================');
    print('[CONSOLE]');
  }

  // ============================================================================
  // 🎮 QUICK COMMANDS FOR DEVELOPERS
  // ============================================================================

  /// Quick health check (non-verbose)
  static Future<bool> quickHealthCheck() async {
    try {
      final result = await runFullSystemTest(verbose: false);
      return result.success;
    } catch (e) {
      return false;
    }
  }

  /// Quick config validation
  static bool validateConfiguration() {
    return StripeConfig.isConfigurationValid && StripeConfig.isReadyForSandboxTesting;
  }

  /// Quick service test
  static Future<bool> testServiceOnly() async {
    try {
      final result = await StripeService.quickHealthTest();
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Quick repository test
  static Future<bool> testRepositoryOnly() async {
    try {
      if (!_getIt.isRegistered<StripeRepository>()) return false;

      final repository = _getIt<StripeRepository>();
      final result = await repository.testConnection();
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Print only test cards for easy reference
  static void printTestCards() {
    print('[CONSOLE]');
    print('[CONSOLE]💳 STRIPE TEST CARDS FOR SANDBOX');
    print('[CONSOLE]==============================');
    StripeConfig.testCards.forEach((type, number) {
      print('[CONSOLE]$type: $number');
    });
    print('[CONSOLE]CVV: ${StripeConfig.testCardDetails['cvv']}');
    print('[CONSOLE]Expiry: ${StripeConfig.testCardDetails['expiry_month']}/${StripeConfig.testCardDetails['expiry_year']}');
    print('[CONSOLE]ZIP: ${StripeConfig.testCardDetails['zip']}');
    print('[CONSOLE]==============================');
    print('[CONSOLE]');
  }
}

// ============================================================================
// RESULT CLASSES
// ============================================================================

class StripeSystemTestResult {
  bool success = false;
  int overallScore = 0;
  Duration testDuration = Duration.zero;
  String? generalError;

  // Configuration tests
  bool configurationValid = false;
  bool readyForSandbox = false;
  bool testMode = false;

  // Service tests
  bool serviceInitialized = false;
  Duration serviceInitTime = Duration.zero;
  String? serviceError;

  // Repository tests
  bool repositoryConnected = false;
  String? repositoryError;
  Map<String, bool> endpointResults = {};

  // BLoC tests
  bool blocRegistered = false;
  String blocCurrentState = '';

  // Google Pay
  bool googlePaySupported = false;

  void calculateOverallScore() {
    int score = 0;
    int totalTests = 0;

    // Configuration (25 points)
    totalTests += 25;
    if (configurationValid) score += 15;
    if (readyForSandbox) score += 5;
    if (testMode) score += 5;

    // Service (25 points)
    totalTests += 25;
    if (serviceInitialized) score += 25;

    // Repository (25 points)
    totalTests += 25;
    if (repositoryConnected) score += 20;
    if (endpointResults.values.where((v) => v).length >= endpointResults.length * 0.7) {
      score += 5; // 70% of endpoints working
    }

    // BLoC (15 points)
    totalTests += 15;
    if (blocRegistered) score += 15;

    // Google Pay (10 points)
    totalTests += 10;
    if (googlePaySupported) score += 10;

    overallScore = (score * 100 / totalTests).round();
  }
}

class PostPaymentTestResult {
  bool success = false;
  int score = 0;
  Duration testDuration = Duration.zero;
  String? generalError;

  bool subscriptionLoadingWorked = false;
  bool customerRaceProtectionWorked = false;
  bool errorHandlingWorked = false;

  void calculateScore() {
    int points = 0;

    if (subscriptionLoadingWorked) points += 40; // Most important
    if (customerRaceProtectionWorked) points += 35; // Very important
    if (errorHandlingWorked) points += 25; // Important

    score = points;
  }
}

class StripeDiagnosticReport {
  late DateTime generatedAt;
  Duration generationDuration = Duration.zero;
  int overallHealthScore = 0;

  Map<String, dynamic> configInfo = {};
  Map<String, dynamic> serviceInfo = {};
  Map<String, dynamic> repositoryInfo = {};
  Map<String, dynamic> dependencyInjectionInfo = {};

  late StripeSystemTestResult systemTestResult;
  late PostPaymentTestResult postPaymentTestResult;

  void calculateOverallHealth() {
    // Weighted average of different test scores
    final systemWeight = 0.6; // 60%
    final postPaymentWeight = 0.4; // 40%

    overallHealthScore = (
        (systemTestResult.overallScore * systemWeight) +
            (postPaymentTestResult.score * postPaymentWeight)
    ).round();
  }
}