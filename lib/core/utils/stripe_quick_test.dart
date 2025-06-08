// lib/core/utils/stripe_quick_test.dart
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../services/session_service.dart';

/// Test rapido per verificare che gli endpoint Stripe funzionino correttamente
class StripeQuickTest {
  static final SessionService _sessionService = SessionService();

  /// Test completo del flusso Stripe
  static Future<StripeTestResults> runQuickTest(Dio dio) async {
    developer.log('🧪 [STRIPE TEST] Starting quick Stripe test...', name: 'StripeQuickTest');

    final results = StripeTestResults();

    try {
      // 1. Test autenticazione
      final user = await _sessionService.getUserData();
      final token = await _sessionService.getAuthToken();

      if (user == null || token == null) {
        results.authTest = false;
        results.authError = 'User not authenticated or no token';
        return results;
      }

      results.authTest = true;
      results.userId = user.id;

      // 2. Test Customer endpoint
      await _testCustomerEndpoint(dio, results, user.id!, user.email!, user.username!);

      // 3. Test Subscription endpoint
      await _testSubscriptionEndpoint(dio, results, user.id!);

      // 4. Test Payment Intent endpoints
      await _testPaymentIntentEndpoints(dio, results, user.id!);

      // 5. Calcola risultato finale
      results.overallSuccess = results.customerTest &&
          results.subscriptionTest &&
          (results.subscriptionPaymentTest || results.donationPaymentTest);

      developer.log(
          '🧪 [STRIPE TEST] Test completed. Overall success: ${results.overallSuccess}',
          name: 'StripeQuickTest'
      );

    } catch (e) {
      results.overallSuccess = false;
      results.generalError = e.toString();
      developer.log('❌ [STRIPE TEST] Test failed: $e', name: 'StripeQuickTest');
    }

    return results;
  }

  /// Test endpoint customer
  static Future<void> _testCustomerEndpoint(
      Dio dio,
      StripeTestResults results,
      int userId,
      String email,
      String username,
      ) async {
    try {
      developer.log('🧪 [CUSTOMER] Testing customer endpoint...', name: 'StripeQuickTest');

      final response = await dio.post('/stripe/customer.php', data: {
        'user_id': userId,
        'email': email,
        'name': username,
      });

      results.customerTest = response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true;

      if (results.customerTest) {
        results.customerId = response.data['customer']?['id'];
        developer.log('✅ [CUSTOMER] Test passed', name: 'StripeQuickTest');
      } else {
        results.customerError = response.data['message'] ?? 'Unknown customer error';
        developer.log('❌ [CUSTOMER] Test failed: ${results.customerError}', name: 'StripeQuickTest');
      }

    } catch (e) {
      results.customerTest = false;
      results.customerError = e.toString();
      developer.log('❌ [CUSTOMER] Test exception: $e', name: 'StripeQuickTest');
    }
  }

  /// Test endpoint subscription
  static Future<void> _testSubscriptionEndpoint(
      Dio dio,
      StripeTestResults results,
      int userId,
      ) async {
    try {
      developer.log('🧪 [SUBSCRIPTION] Testing subscription endpoint...', name: 'StripeQuickTest');

      final response = await dio.get('/stripe/subscription.php', queryParameters: {
        'user_id': userId,
      });

      results.subscriptionTest = response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true;

      if (results.subscriptionTest) {
        results.hasActiveSubscription = response.data['subscription'] != null;
        developer.log('✅ [SUBSCRIPTION] Test passed', name: 'StripeQuickTest');
      } else {
        results.subscriptionError = response.data['message'] ?? 'Unknown subscription error';
        developer.log('❌ [SUBSCRIPTION] Test failed: ${results.subscriptionError}', name: 'StripeQuickTest');
      }

    } catch (e) {
      results.subscriptionTest = false;
      results.subscriptionError = e.toString();
      developer.log('❌ [SUBSCRIPTION] Test exception: $e', name: 'StripeQuickTest');
    }
  }

  /// Test endpoint payment intent
  static Future<void> _testPaymentIntentEndpoints(
      Dio dio,
      StripeTestResults results,
      int userId,
      ) async {
    // Test Subscription Payment Intent
    try {
      developer.log('🧪 [PAYMENT] Testing subscription payment intent...', name: 'StripeQuickTest');

      final response = await dio.post('/stripe/create-subscription-payment-intent.php', data: {
        'user_id': userId,
        'price_id': 'price_premium_monthly_test',
        'metadata': {'test': true},
      });

      results.subscriptionPaymentTest = response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true;

      if (results.subscriptionPaymentTest) {
        results.subscriptionPaymentIntentId = response.data['payment_intent']?['payment_intent_id'];
        developer.log('✅ [PAYMENT] Subscription payment test passed', name: 'StripeQuickTest');
      } else {
        results.subscriptionPaymentError = response.data['message'] ?? 'Unknown payment error';
        developer.log('❌ [PAYMENT] Subscription payment test failed: ${results.subscriptionPaymentError}', name: 'StripeQuickTest');
      }

    } catch (e) {
      results.subscriptionPaymentTest = false;
      results.subscriptionPaymentError = e.toString();
      developer.log('❌ [PAYMENT] Subscription payment exception: $e', name: 'StripeQuickTest');
    }

    // Test Donation Payment Intent
    try {
      developer.log('🧪 [DONATION] Testing donation payment intent...', name: 'StripeQuickTest');

      final response = await dio.post('/stripe/create-donation-payment-intent.php', data: {
        'user_id': userId,
        'amount': 500, // €5.00
        'currency': 'eur',
        'metadata': {'test': true},
      });

      results.donationPaymentTest = response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true;

      if (results.donationPaymentTest) {
        results.donationPaymentIntentId = response.data['payment_intent']?['payment_intent_id'];
        developer.log('✅ [DONATION] Donation payment test passed', name: 'StripeQuickTest');
      } else {
        results.donationPaymentError = response.data['message'] ?? 'Unknown donation error';
        developer.log('❌ [DONATION] Donation payment test failed: ${results.donationPaymentError}', name: 'StripeQuickTest');
      }

    } catch (e) {
      results.donationPaymentTest = false;
      results.donationPaymentError = e.toString();
      developer.log('❌ [DONATION] Donation payment exception: $e', name: 'StripeQuickTest');
    }
  }

  /// Stampa risultati in formato leggibile
  static void printResults(StripeTestResults results) {
    print('');
    print('🧪 STRIPE QUICK TEST RESULTS');
    print('============================');
    print('Overall Success: ${results.overallSuccess ? "✅ PASS" : "❌ FAIL"}');
    print('');

    print('🔐 Authentication:');
    print('  Status: ${results.authTest ? "✅ PASS" : "❌ FAIL"}');
    if (results.authError != null) {
      print('  Error: ${results.authError}');
    }
    print('  User ID: ${results.userId}');
    print('');

    print('👤 Customer Endpoint:');
    print('  Status: ${results.customerTest ? "✅ PASS" : "❌ FAIL"}');
    if (results.customerError != null) {
      print('  Error: ${results.customerError}');
    }
    if (results.customerId != null) {
      print('  Customer ID: ${results.customerId}');
    }
    print('');

    print('📋 Subscription Endpoint:');
    print('  Status: ${results.subscriptionTest ? "✅ PASS" : "❌ FAIL"}');
    if (results.subscriptionError != null) {
      print('  Error: ${results.subscriptionError}');
    }
    print('  Has Active Subscription: ${results.hasActiveSubscription}');
    print('');

    print('💳 Payment Intent Tests:');
    print('  Subscription Payment: ${results.subscriptionPaymentTest ? "✅ PASS" : "❌ FAIL"}');
    if (results.subscriptionPaymentError != null) {
      print('    Error: ${results.subscriptionPaymentError}');
    }
    if (results.subscriptionPaymentIntentId != null) {
      print('    Payment Intent ID: ${results.subscriptionPaymentIntentId}');
    }

    print('  Donation Payment: ${results.donationPaymentTest ? "✅ PASS" : "❌ FAIL"}');
    if (results.donationPaymentError != null) {
      print('    Error: ${results.donationPaymentError}');
    }
    if (results.donationPaymentIntentId != null) {
      print('    Payment Intent ID: ${results.donationPaymentIntentId}');
    }
    print('');

    if (results.generalError != null) {
      print('🚨 General Error: ${results.generalError}');
      print('');
    }

    // Suggerimenti
    if (!results.overallSuccess) {
      print('🔧 TROUBLESHOOTING SUGGESTIONS:');

      if (!results.authTest) {
        print('  - Login again to refresh authentication');
      }

      if (!results.customerTest) {
        print('  - Check Stripe keys in backend configuration');
        print('  - Verify customer.php endpoint on server');
      }

      if (!results.subscriptionPaymentTest && !results.donationPaymentTest) {
        print('  - Check payment intent endpoints on server');
        print('  - Verify Stripe SDK installation on backend');
        print('  - Check PHP error logs');
      }

      print('  - Verify all Stripe PHP files are uploaded');
      print('  - Check .htaccess configuration in /stripe/ directory');
    }

    print('============================');
    print('');
  }
}

/// Risultati del test rapido
class StripeTestResults {
  // Overall
  bool overallSuccess = false;
  String? generalError;

  // Authentication
  bool authTest = false;
  String? authError;
  int? userId;

  // Customer
  bool customerTest = false;
  String? customerError;
  String? customerId;

  // Subscription
  bool subscriptionTest = false;
  String? subscriptionError;
  bool hasActiveSubscription = false;

  // Payment Intents
  bool subscriptionPaymentTest = false;
  String? subscriptionPaymentError;
  String? subscriptionPaymentIntentId;

  bool donationPaymentTest = false;
  String? donationPaymentError;
  String? donationPaymentIntentId;

  /// Conta i test passati
  int get passedTests {
    int count = 0;
    if (authTest) count++;
    if (customerTest) count++;
    if (subscriptionTest) count++;
    if (subscriptionPaymentTest) count++;
    if (donationPaymentTest) count++;
    return count;
  }

  /// Conta i test totali
  int get totalTests => 5;

  /// Percentuale di successo
  double get successRate => (passedTests / totalTests) * 100;

  /// Stato complessivo in testo
  String get statusText {
    if (overallSuccess) return 'ALL SYSTEMS OPERATIONAL';
    if (successRate >= 80) return 'MOSTLY OPERATIONAL';
    if (successRate >= 50) return 'PARTIALLY OPERATIONAL';
    return 'SYSTEM DOWN';
  }
}