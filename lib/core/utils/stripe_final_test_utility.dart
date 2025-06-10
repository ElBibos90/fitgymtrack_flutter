// lib/core/utils/stripe_final_test_utility.dart
import 'package:dio/dio.dart';
import '../services/session_service.dart';
import '../config/environment.dart';
import '../config/stripe_config.dart';
import 'stripe_super_debug.dart';

/// Final Test & Recovery Utility per Stripe - SISTEMA DEFINITIVO
class StripeFinalTestUtility {
  static final SessionService _sessionService = SessionService();

  /// Test finale completo con recovery automatico
  static Future<StripeFinalTestResult> runFinalTest({
    required Dio dio,
    bool attemptRecovery = true,
    bool verbose = true,
  }) async {
    if (verbose) {
      print('[CONSOLE] [stripe_final_test_utility]🎯 [FINAL TEST] Starting comprehensive final test...');
    }

    final result = StripeFinalTestResult();

    // ============================================================================
    // FASE 1: PRE-TEST VALIDATION
    // ============================================================================

    await _phase1PreTestValidation(result, verbose);

    // ============================================================================
    // FASE 2: SISTEMA COMPLETO
    // ============================================================================

    if (result.preTestPassed) {
      await _phase2SystemTest(dio, result, verbose);
    } else {
      if (verbose) {
        print('[CONSOLE] [stripe_final_test_utility]⚠️ [FINAL TEST] Pre-test failed - skipping system test');
      }
    }

    // ============================================================================
    // FASE 3: RECOVERY AUTOMATICO (se necessario)
    // ============================================================================

    if (!result.systemTestPassed && attemptRecovery) {
      await _phase3AutoRecovery(dio, result, verbose);
    }

    // ============================================================================
    // FASE 4: VALIDAZIONE FINALE
    // ============================================================================

    await _phase4FinalValidation(dio, result, verbose);

    // ============================================================================
    // FASE 5: REPORT E RACCOMANDAZIONI
    // ============================================================================

    _phase5GenerateReport(result, verbose);

    if (verbose) {
      print('[CONSOLE] [stripe_final_test_utility]🎯 [FINAL TEST] Test completed - Success: ${result.overallSuccess}');
    }

    return result;
  }

  /// FASE 1: Validazione pre-test
  static Future<void> _phase1PreTestValidation(StripeFinalTestResult result, bool verbose) async {
    if (verbose) {
      print('[CONSOLE] [stripe_final_test_utility]📋 [PHASE 1] Pre-test validation...');
    }

    // Test configurazione Stripe
    result.stripeConfigValid = StripeConfig.isValidKey(StripeConfig.publishableKey);
    result.stripeDemoMode = StripeConfig.isDemoMode;
    result.stripeTestMode = StripeConfig.isTestMode;

    // Test configurazione Environment
    result.environmentConfigValid = Environment.baseUrl.isNotEmpty &&
        Environment.baseUrl.startsWith('https://');

    // Test dependency injection
    try {
      final sessionService = SessionService();
      result.dependencyInjectionWorking = true;
    } catch (e) {
      result.dependencyInjectionWorking = false;
      result.preTestErrors.add('Dependency injection failed: $e');
    }

    // Determina se il pre-test è passato
    result.preTestPassed = result.stripeConfigValid &&
        result.environmentConfigValid &&
        result.dependencyInjectionWorking;

    if (verbose) {
      print('[CONSOLE] [stripe_final_test_utility]📋 [PHASE 1] Config valid: ${result.stripeConfigValid}');
      print('[CONSOLE] [stripe_final_test_utility]📋 [PHASE 1] Environment valid: ${result.environmentConfigValid}');
      print('[CONSOLE] [stripe_final_test_utility]📋 [PHASE 1] DI working: ${result.dependencyInjectionWorking}');
      print('[CONSOLE] [stripe_final_test_utility]📋 [PHASE 1] Pre-test passed: ${result.preTestPassed}');
    }
  }

  /// FASE 2: Test sistema completo
  static Future<void> _phase2SystemTest(Dio dio, StripeFinalTestResult result, bool verbose) async {
    if (verbose) {
      print('[CONSOLE] [stripe_final_test_utility]🏗️ [PHASE 2] System test...');
    }

    try {
      // Test autenticazione
      final user = await _sessionService.getUserData();
      final token = await _sessionService.getAuthToken();
      result.authenticationWorking = user != null && token != null && token.isNotEmpty;
      result.userId = user?.id;

      if (verbose) {
        print('[CONSOLE] [stripe_final_test_utility]🔐 [PHASE 2] Authentication working: ${result.authenticationWorking}');
      }

      // Test connettività API base
      try {
        final response = await dio.get('/auth.php', queryParameters: {
          'action': 'verify_token',
        }).timeout(const Duration(seconds: 10));
        result.baseApiWorking = response.statusCode == 200;
      } catch (e) {
        result.baseApiWorking = false;
        result.systemTestErrors.add('Base API not reachable: $e');
      }

      // Test Stripe endpoints specifici
      await _testStripeEndpointsDetailed(dio, result, verbose);

      // Test completo con Super Debug
      final superReport = await StripeSuperDebug.runSuperDiagnostic(
        dio: dio,
        verbose: false,
      );
      result.superDebugScore = superReport.overallScore;
      result.superDebugReport = superReport;

      // Determina se il test di sistema è passato
      result.systemTestPassed = result.authenticationWorking &&
          result.baseApiWorking &&
          result.criticalEndpointsWorking >= 3 &&
          result.superDebugScore >= 50;

      if (verbose) {
        print('[CONSOLE] [stripe_final_test_utility]🏗️ [PHASE 2] System test passed: ${result.systemTestPassed}');
      }

    } catch (e) {
      result.systemTestPassed = false;
      result.systemTestErrors.add('System test failed: $e');

      if (verbose) {
        print('[CONSOLE] [stripe_final_test_utility]❌ [PHASE 2] System test error: $e');
      }
    }
  }

  /// Test dettagliato endpoint Stripe
  static Future<void> _testStripeEndpointsDetailed(Dio dio, StripeFinalTestResult result, bool verbose) async {
    final criticalEndpoints = [
      {
        'name': 'customer',
        'endpoint': '/stripe/customer.php',
        'method': 'POST',
        'data': {
          'user_id': result.userId ?? 999999,
          'email': 'finaltest@example.com',
          'name': 'Final Test User',
        },
      },
      {
        'name': 'subscription',
        'endpoint': '/stripe/subscription.php',
        'method': 'GET',
        'queryParams': {
          'user_id': (result.userId ?? 999999).toString(),
        },
      },
      {
        'name': 'subscription_payment',
        'endpoint': '/stripe/create-subscription-payment-intent.php',
        'method': 'POST',
        'data': {
          'user_id': result.userId ?? 999999,
          'price_id': StripeConfig.subscriptionPlans['premium_monthly']?.stripePriceId ?? 'price_test_123',
          'metadata': {'final_test': true},
        },
      },
      {
        'name': 'donation_payment',
        'endpoint': '/stripe/create-donation-payment-intent.php',
        'method': 'POST',
        'data': {
          'user_id': result.userId ?? 999999,
          'amount': 500,
          'currency': 'eur',
          'metadata': {'final_test': true},
        },
      },
    ];

    int workingEndpoints = 0;

    for (final endpointConfig in criticalEndpoints) {
      try {
        Response response;

        if (endpointConfig['method'] == 'GET') {
          response = await dio.get(
            endpointConfig['endpoint'] as String,
            queryParameters: endpointConfig['queryParams'] as Map<String, dynamic>?,
          ).timeout(const Duration(seconds: 10));
        } else {
          response = await dio.post(
            endpointConfig['endpoint'] as String,
            data: endpointConfig['data'] as Map<String, dynamic>?,
          ).timeout(const Duration(seconds: 10));
        }

        final isWorking = response.statusCode == 200 &&
            !response.data.toString().contains('<!DOCTYPE');

        if (isWorking) {
          workingEndpoints++;
          result.workingEndpoints.add(endpointConfig['name'] as String);
        } else {
          result.brokenEndpoints.add(endpointConfig['name'] as String);
        }

        if (verbose) {
          print('[CONSOLE] [stripe_final_test_utility]🎯 [ENDPOINT] ${endpointConfig['name']}: ${isWorking ? "✅" : "❌"}');
        }

      } catch (e) {
        result.brokenEndpoints.add(endpointConfig['name'] as String);
        result.endpointErrors[endpointConfig['name'] as String] = e.toString();

        if (verbose) {
          print('[CONSOLE] [stripe_final_test_utility]❌ [ENDPOINT] ${endpointConfig['name']}: $e');
        }
      }
    }

    result.criticalEndpointsWorking = workingEndpoints;
    result.totalCriticalEndpoints = criticalEndpoints.length;
  }

  /// FASE 3: Recovery automatico
  static Future<void> _phase3AutoRecovery(Dio dio, StripeFinalTestResult result, bool verbose) async {
    if (verbose) {
      print('[CONSOLE] [stripe_final_test_utility]🔄 [PHASE 3] Attempting auto-recovery...');
    }

    result.attemptedRecovery = true;

    // Recovery 1: Refresh authentication
    if (!result.authenticationWorking) {
      try {
        await _sessionService.clearSession();
        await Future.delayed(const Duration(seconds: 1));
        // Note: In un'app reale, qui dovremmo far rifare il login all'utente
        result.recoveryActions.add('Authentication session cleared');

        if (verbose) {
          print('[CONSOLE] [stripe_final_test_utility]🔄 [RECOVERY] Authentication session cleared');
        }
      } catch (e) {
        result.recoveryErrors.add('Auth recovery failed: $e');
      }
    }

    // Recovery 2: Test connessione con timeout più lungo
    if (!result.baseApiWorking) {
      try {
        final response = await dio.get('/auth.php', queryParameters: {
          'action': 'verify_token',
        }).timeout(const Duration(seconds: 30)); // Timeout più lungo

        if (response.statusCode == 200) {
          result.baseApiWorking = true;
          result.recoveryActions.add('Base API connection recovered with extended timeout');

          if (verbose) {
            print('[CONSOLE] [stripe_final_test_utility]✅ [RECOVERY] Base API recovered');
          }
        }
      } catch (e) {
        result.recoveryErrors.add('API recovery failed: $e');
      }
    }

    // Recovery 3: Re-test endpoint critici
    if (result.criticalEndpointsWorking < 2) {
      await Future.delayed(const Duration(seconds: 2));
      await _testStripeEndpointsDetailed(dio, result, verbose);

      if (result.criticalEndpointsWorking >= 2) {
        result.recoveryActions.add('Critical endpoints recovered after retry');

        if (verbose) {
          print('[CONSOLE] [stripe_final_test_utility]✅ [RECOVERY] Critical endpoints recovered');
        }
      }
    }

    // Recovery 4: Test configurazione alternativa
    if (result.stripeDemoMode) {
      result.recoveryActions.add('System running in demo mode - limited functionality');
      result.demoModeRecovery = true;
    }

    result.recoverySuccessful = result.baseApiWorking && result.criticalEndpointsWorking >= 1;

    if (verbose) {
      print('[CONSOLE] [stripe_final_test_utility]🔄 [PHASE 3] Recovery successful: ${result.recoverySuccessful}');
    }
  }

  /// FASE 4: Validazione finale
  static Future<void> _phase4FinalValidation(Dio dio, StripeFinalTestResult result, bool verbose) async {
    if (verbose) {
      print('[CONSOLE] [stripe_final_test_utility]✅ [PHASE 4] Final validation...');
    }

    // Test finale rapido
    try {
      final quickResults = await StripeSuperDebug.runQuickTest(dio);
      result.finalQuickTestScore = quickResults.score;
      result.finalQuickTestPassed = quickResults.overallSuccess;

      if (verbose) {
        print('[CONSOLE] [stripe_final_test_utility]🧪 [PHASE 4] Quick test score: ${result.finalQuickTestScore}/100');
      }
    } catch (e) {
      result.finalQuickTestPassed = false;
      result.finalValidationErrors.add('Quick test failed: $e');
    }

    // Validazione criteri minimi
    result.meetsMinimumCriteria = _checkMinimumCriteria(result);

    // Determinazione successo generale
    result.overallSuccess = result.preTestPassed &&
        (result.systemTestPassed || result.recoverySuccessful) &&
        result.meetsMinimumCriteria;

    if (verbose) {
      print('[CONSOLE] [stripe_final_test_utility]✅ [PHASE 4] Meets minimum criteria: ${result.meetsMinimumCriteria}');
      print('[CONSOLE] [stripe_final_test_utility]✅ [PHASE 4] Overall success: ${result.overallSuccess}');
    }
  }

  /// Controlla criteri minimi
  static bool _checkMinimumCriteria(StripeFinalTestResult result) {
    // Criteri minimi per considerare il sistema funzionante
    return result.stripeConfigValid &&
        result.environmentConfigValid &&
        (result.baseApiWorking || result.demoModeRecovery) &&
        (result.criticalEndpointsWorking >= 1 || result.demoModeRecovery);
  }

  /// FASE 5: Generazione report
  static void _phase5GenerateReport(StripeFinalTestResult result, bool verbose) {
    if (verbose) {
      print('[CONSOLE] [stripe_final_test_utility]📊 [PHASE 5] Generating final report...');
    }

    // Calcola punteggio finale
    int score = 0;

    if (result.preTestPassed) score += 25;
    if (result.systemTestPassed) score += 35;
    if (result.authenticationWorking) score += 15;
    if (result.baseApiWorking) score += 10;
    score += (result.criticalEndpointsWorking / result.totalCriticalEndpoints * 15).round();

    result.finalScore = score;

    // Genera raccomandazioni finali
    result.finalRecommendations = _generateFinalRecommendations(result);

    // Genera prossimi passi
    result.nextSteps = _generateNextSteps(result);

    if (verbose) {
      print('[CONSOLE] [stripe_final_test_utility]📊 [PHASE 5] Final score: ${result.finalScore}/100');
    }
  }

  /// Genera raccomandazioni finali
  static List<String> _generateFinalRecommendations(StripeFinalTestResult result) {
    final recommendations = <String>[];

    if (!result.stripeConfigValid) {
      recommendations.add('🔑 URGENT: Replace Stripe configuration with valid keys');
    }

    if (result.stripeDemoMode) {
      recommendations.add('⚠️ Replace demo Stripe keys with real test keys for full functionality');
    }

    if (!result.authenticationWorking) {
      recommendations.add('🔐 Fix authentication system - users cannot login');
    }

    if (!result.baseApiWorking) {
      recommendations.add('🌐 Restore API connectivity - server may be down');
    }

    if (result.criticalEndpointsWorking == 0) {
      recommendations.add('🎯 CRITICAL: No Stripe endpoints working - upload PHP files');
    } else if (result.criticalEndpointsWorking < 3) {
      recommendations.add('🎯 Some Stripe endpoints not working - check server configuration');
    }

    if (result.superDebugScore < 75) {
      recommendations.add('🔍 Run full diagnostic for detailed troubleshooting');
    }

    return recommendations;
  }

  /// Genera prossimi passi
  static List<String> _generateNextSteps(StripeFinalTestResult result) {
    final steps = <String>[];

    if (result.overallSuccess) {
      steps.add('✅ System is ready for production testing');
      steps.add('🧪 Test real payment flows with test cards');
      steps.add('📱 Test mobile app functionality');

      if (result.stripeDemoMode) {
        steps.add('🔑 Upgrade to real Stripe keys when ready for production');
      }
    } else {
      if (!result.preTestPassed) {
        steps.add('🔧 Fix configuration issues first');
        steps.add('📖 Check documentation for setup instructions');
      }

      if (!result.systemTestPassed && !result.recoverySuccessful) {
        steps.add('🏥 Contact system administrator');
        steps.add('📋 Check server logs for errors');
        steps.add('🔍 Run full diagnostic for detailed analysis');
      }

      steps.add('🔄 Retry test after fixing issues');
    }

    return steps;
  }

  /// Test definitivo semplificato
  static Future<bool> simpleSystemCheck(Dio dio) async {
    try {
      // Test 1: Configurazione base
      if (!StripeConfig.isValidKey(StripeConfig.publishableKey)) {
        return false;
      }

      // Test 2: API connectivity
      final response = await dio.get('/auth.php', queryParameters: {
        'action': 'verify_token',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        return false;
      }

      // Test 3: Almeno un endpoint Stripe funzionante
      try {
        final stripeResponse = await dio.post('/stripe/customer.php', data: {
          'user_id': 999999,
          'email': 'test@test.com',
          'name': 'System Check',
        }).timeout(const Duration(seconds: 5));

        return stripeResponse.statusCode == 200 &&
            !stripeResponse.data.toString().contains('<!DOCTYPE');
      } catch (e) {
        return false;
      }

    } catch (e) {
      return false;
    }
  }

  /// Stampa report finale completo
  static void printFinalReport(StripeFinalTestResult result) {
    print('[CONSOLE] [stripe_final_test_utility]');
    print('[CONSOLE] [stripe_final_test_utility]🎯 STRIPE FINAL TEST REPORT');
    print('[CONSOLE] [stripe_final_test_utility]===========================================================');
    print('[CONSOLE] [stripe_final_test_utility]📊 Final Score: ${result.finalScore}/100');
    print('[CONSOLE] [stripe_final_test_utility]✅ Overall Success: ${result.overallSuccess}');
    print('[CONSOLE] [stripe_final_test_utility]');

    // Pre-test
    print('[CONSOLE] [stripe_final_test_utility]📋 PRE-TEST VALIDATION:');
    print('[CONSOLE] [stripe_final_test_utility]   Stripe Config Valid: ${result.stripeConfigValid}');
    print('[CONSOLE] [stripe_final_test_utility]   Environment Valid: ${result.environmentConfigValid}');
    print('[CONSOLE] [stripe_final_test_utility]   Dependency Injection: ${result.dependencyInjectionWorking}');
    print('[CONSOLE] [stripe_final_test_utility]   Demo Mode: ${result.stripeDemoMode}');
    print('[CONSOLE] [stripe_final_test_utility]   Pre-test Passed: ${result.preTestPassed}');
    print('[CONSOLE] [stripe_final_test_utility]');

    // System test
    print('[CONSOLE] [stripe_final_test_utility]🏗️ SYSTEM TEST:');
    print('[CONSOLE] [stripe_final_test_utility]   Authentication Working: ${result.authenticationWorking}');
    print('[CONSOLE] [stripe_final_test_utility]   Base API Working: ${result.baseApiWorking}');
    print('[CONSOLE] [stripe_final_test_utility]   Critical Endpoints Working: ${result.criticalEndpointsWorking}/${result.totalCriticalEndpoints}');
    print('[CONSOLE] [stripe_final_test_utility]   Super Debug Score: ${result.superDebugScore}/100');
    print('[CONSOLE] [stripe_final_test_utility]   System Test Passed: ${result.systemTestPassed}');
    print('[CONSOLE] [stripe_final_test_utility]');

    // Working/Broken endpoints
    if (result.workingEndpoints.isNotEmpty) {
      print('[CONSOLE] [stripe_final_test_utility]✅ WORKING ENDPOINTS:');
      for (final endpoint in result.workingEndpoints) {
        print('[CONSOLE] [stripe_final_test_utility]   ✅ $endpoint');
      }
      print('[CONSOLE] [stripe_final_test_utility]');
    }

    if (result.brokenEndpoints.isNotEmpty) {
      print('[CONSOLE] [stripe_final_test_utility]❌ BROKEN ENDPOINTS:');
      for (final endpoint in result.brokenEndpoints) {
        print('[CONSOLE] [stripe_final_test_utility]   ❌ $endpoint');
        if (result.endpointErrors.containsKey(endpoint)) {
          print('[CONSOLE] [stripe_final_test_utility]      Error: ${result.endpointErrors[endpoint]}');
        }
      }
      print('[CONSOLE] [stripe_final_test_utility]');
    }

    // Recovery
    if (result.attemptedRecovery) {
      print('[CONSOLE] [stripe_final_test_utility]🔄 RECOVERY ATTEMPT:');
      print('[CONSOLE] [stripe_final_test_utility]   Recovery Successful: ${result.recoverySuccessful}');

      if (result.recoveryActions.isNotEmpty) {
        print('[CONSOLE] [stripe_final_test_utility]   Actions Taken:');
        for (final action in result.recoveryActions) {
          print('[CONSOLE] [stripe_final_test_utility]     • $action');
        }
      }

      if (result.recoveryErrors.isNotEmpty) {
        print('[CONSOLE] [stripe_final_test_utility]   Recovery Errors:');
        for (final error in result.recoveryErrors) {
          print('[CONSOLE] [stripe_final_test_utility]     • $error');
        }
      }
      print('[CONSOLE] [stripe_final_test_utility]');
    }

    // Final validation
    print('[CONSOLE] [stripe_final_test_utility]✅ FINAL VALIDATION:');
    print('[CONSOLE] [stripe_final_test_utility]   Quick Test Score: ${result.finalQuickTestScore}/100');
    print('[CONSOLE] [stripe_final_test_utility]   Quick Test Passed: ${result.finalQuickTestPassed}');
    print('[CONSOLE] [stripe_final_test_utility]   Meets Minimum Criteria: ${result.meetsMinimumCriteria}');
    print('[CONSOLE] [stripe_final_test_utility]');

    // Recommendations
    if (result.finalRecommendations.isNotEmpty) {
      print('[CONSOLE] [stripe_final_test_utility]💡 FINAL RECOMMENDATIONS:');
      for (final recommendation in result.finalRecommendations) {
        print('[CONSOLE] [stripe_final_test_utility]   $recommendation');
      }
      print('[CONSOLE] [stripe_final_test_utility]');
    }

    // Next steps
    if (result.nextSteps.isNotEmpty) {
      print('[CONSOLE] [stripe_final_test_utility]🚀 NEXT STEPS:');
      for (int i = 0; i < result.nextSteps.length; i++) {
        print('[CONSOLE] [stripe_final_test_utility]   ${i + 1}. ${result.nextSteps[i]}');
      }
      print('[CONSOLE] [stripe_final_test_utility]');
    }

    // System status
    String statusIcon;
    if (result.finalScore >= 90) {
      statusIcon = '🟢 EXCELLENT';
    } else if (result.finalScore >= 75) {
      statusIcon = '🟡 GOOD';
    } else if (result.finalScore >= 50) {
      statusIcon = '🟠 NEEDS WORK';
    } else {
      statusIcon = '🔴 CRITICAL';
    }

    print('[CONSOLE] [stripe_final_test_utility]🏥 SYSTEM STATUS: $statusIcon');
    print('[CONSOLE] [stripe_final_test_utility]===========================================================');
    print('[CONSOLE] [stripe_final_test_utility]');
  }
}

/// Risultato del test finale
class StripeFinalTestResult {
  // Pre-test
  bool stripeConfigValid = false;
  bool stripeDemoMode = false;
  bool stripeTestMode = false;
  bool environmentConfigValid = false;
  bool dependencyInjectionWorking = false;
  bool preTestPassed = false;
  List<String> preTestErrors = [];

  // System test
  bool authenticationWorking = false;
  bool baseApiWorking = false;
  int? userId;
  int criticalEndpointsWorking = 0;
  int totalCriticalEndpoints = 4;
  int superDebugScore = 0;
  StripeSystemReport? superDebugReport;
  bool systemTestPassed = false;
  List<String> systemTestErrors = [];

  // Endpoints
  List<String> workingEndpoints = [];
  List<String> brokenEndpoints = [];
  Map<String, String> endpointErrors = {};

  // Recovery
  bool attemptedRecovery = false;
  bool recoverySuccessful = false;
  bool demoModeRecovery = false;
  List<String> recoveryActions = [];
  List<String> recoveryErrors = [];

  // Final validation
  int finalQuickTestScore = 0;
  bool finalQuickTestPassed = false;
  bool meetsMinimumCriteria = false;
  List<String> finalValidationErrors = [];

  // Overall
  bool overallSuccess = false;
  int finalScore = 0;
  List<String> finalRecommendations = [];
  List<String> nextSteps = [];

  /// Status del sistema in formato user-friendly
  String get systemStatus {
    if (finalScore >= 90) return 'EXCELLENT';
    if (finalScore >= 75) return 'GOOD';
    if (finalScore >= 50) return 'NEEDS_WORK';
    return 'CRITICAL';
  }

  /// Percentuale di endpoint funzionanti
  double get endpointSuccessRate {
    if (totalCriticalEndpoints == 0) return 0.0;
    return (criticalEndpointsWorking / totalCriticalEndpoints) * 100;
  }

  /// È pronto per la produzione?
  bool get readyForProduction {
    return overallSuccess &&
        !stripeDemoMode &&
        finalScore >= 80 &&
        criticalEndpointsWorking >= 3;
  }

  /// È utilizzabile in modalità limitata?
  bool get usableWithLimitations {
    return overallSuccess ||
        (demoModeRecovery && baseApiWorking) ||
        (criticalEndpointsWorking >= 1 && authenticationWorking);
  }
}