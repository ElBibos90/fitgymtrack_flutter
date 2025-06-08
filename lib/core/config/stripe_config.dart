// lib/core/config/stripe_config.dart
import 'package:flutter/foundation.dart';

/// Configurazione Stripe per FitGymTrack - READY FOR SANDBOX TESTING
class StripeConfig {
  // ============================================================================
  // 🔑 STRIPE KEYS - TEST MODE READY FOR REAL TESTING
  // ============================================================================

  /// Publishable Key per Stripe (TEST KEYS for sandbox testing)
  static const String publishableKey = kDebugMode
      ? 'pk_test_51RW3uvHHtQGHyul9D48kPP1cBny9yxD75X4hrA1DWsudV37kNGVvPJNzZyCMjIFzuEHlPkRHT4W9R8vCASNpX1xL00qADtuDiY' // ✅ REAL test key
      : 'pk_live_REPLACE_WITH_PRODUCTION_KEY'; // For production later

  /// 🔧 Merchant Identifier for Apple Pay
  static const String merchantIdentifier = 'merchant.com.fitgymtrack.app';

  // ============================================================================
  // 🌍 CONFIGURAZIONE REGIONALE
  // ============================================================================

  static const String currency = 'eur';
  static const String countryCode = 'IT';

  // ============================================================================
  // 💳 METODI DI PAGAMENTO SUPPORTATI
  // ============================================================================

  static const List<String> supportedPaymentMethods = [
    'card',
    'google_pay',
    'apple_pay',
  ];

  // ============================================================================
  // 📋 PIANI DI ABBONAMENTO - READY FOR TESTING
  // ============================================================================

  static const Map<String, SubscriptionPlan> subscriptionPlans = {
    'premium_monthly': SubscriptionPlan(
      id: 'premium_monthly',
      name: 'Premium Mensile',
      description: 'Tutte le funzionalità Premium per un mese',
      stripePriceId: 'price_1RXVOfHHtQGHyul9qMGFmpmO', // ✅ Real test price ID
      amount: 499, // €4.99 in centesimi
      interval: 'month',
      features: [
        '🏋️ Schede di allenamento illimitate',
        '💪 Esercizi personalizzati illimitati',
        '📊 Statistiche avanzate e grafici',
        '☁️ Backup automatico su cloud',
        '🚫 Nessuna pubblicità',
        '🎯 Supporto prioritario',
        '🆕 Accesso alle nuove funzionalità',
      ],
    ),
    'premium_yearly': SubscriptionPlan(
      id: 'premium_yearly',
      name: 'Premium Annuale',
      description: 'Piano annuale con sconto del 17%',
      stripePriceId: 'price_1RXjCDHHtQGHyul9GnnKSoL9', // ✅ Real test price ID
      amount: 4999, // €49.99 in centesimi
      interval: 'year',
      features: [
        '✨ Tutte le funzionalità Premium',
        '💰 Sconto del 17% rispetto al piano mensile',
        '⭐ Priorità massima nel supporto',
        '🚀 Accesso anticipato alle nuove funzionalità',
        '🎁 Contenuti esclusivi premium',
      ],
    ),
  };

  // ============================================================================
  // 🎁 IMPORTI DONAZIONE PREDEFINITI
  // ============================================================================

  static const List<int> donationAmounts = [
    299,  // €2.99
    499,  // €4.99
    999,  // €9.99
    1999, // €19.99
    4999, // €49.99
  ];

  // ============================================================================
  // 🧪 TEST CARD NUMBERS FOR SANDBOX TESTING
  // ============================================================================

  /// Test card numbers for sandbox testing
  static const Map<String, String> testCards = {
    'success': '4242424242424242',
    'declined': '4000000000000002',
    'insufficient_funds': '4000000000009995',
    'require_3d_secure': '4000000000003220',
    'expired': '4000000000000069',
    'incorrect_cvc': '4000000000000127',
  };

  /// Default test card details
  static const Map<String, String> testCardDetails = {
    'cvv': '123',
    'expiry_month': '12',
    'expiry_year': '25',
    'zip': '12345',
  };

  // ============================================================================
  // 🔧 HELPER METHODS
  // ============================================================================

  /// Converte euro in centesimi per Stripe
  static int euroToCents(double euros) {
    return (euros * 100).round();
  }

  /// Converte centesimi in euro
  static double centsToEuro(int cents) {
    return cents / 100.0;
  }

  /// Verifica formato chiavi Stripe
  static bool isValidKey(String key) {
    if (key.isEmpty) return false;

    // Verifica formato chiave test
    if (key.startsWith('pk_test_')) {
      return key.length >= 107; // Lunghezza minima chiave test Stripe
    }

    // Verifica formato chiave live
    if (key.startsWith('pk_live_')) {
      return key.length >= 107; // Lunghezza minima chiave live Stripe
    }

    return false;
  }

  /// Indica se siamo in modalità test
  static bool get isTestMode => publishableKey.startsWith('pk_test_');

  /// Indica se siamo in modalità demo (chiavi placeholder)
  static bool get isDemoMode => publishableKey.contains('REPLACE') ||
      publishableKey.contains('1234567890');

  /// Formatta un importo in euro
  static String formatAmount(int centesimi, {String symbol = '€'}) {
    final euros = centsToEuro(centesimi);
    return '$symbol${euros.toStringAsFixed(2)}';
  }

  /// Ottiene il piano per ID
  static SubscriptionPlan? getPlan(String planId) {
    return subscriptionPlans[planId];
  }

  /// Lista di tutti i piani disponibili
  static List<SubscriptionPlan> get availablePlans => subscriptionPlans.values.toList();

  // ============================================================================
  // 🔍 VALIDAZIONE CONFIGURAZIONE
  // ============================================================================

  /// Verifica se la configurazione è valida per testing
  static bool get isConfigurationValid {
    if (!isValidKey(publishableKey)) return false;
    if (currency.isEmpty) return false;
    if (countryCode.isEmpty) return false;
    if (merchantIdentifier.isEmpty) return false;

    // Verifica che tutti i piani abbiano price ID validi
    for (final plan in subscriptionPlans.values) {
      if (plan.stripePriceId.isEmpty || !plan.stripePriceId.startsWith('price_')) {
        return false;
      }
    }

    return true;
  }

  /// Verifica se siamo pronti per il test sandbox
  static bool get isReadyForSandboxTesting {
    return isTestMode &&
        !isDemoMode &&
        isConfigurationValid;
  }

  /// Verifica se siamo pronti per la produzione
  static bool get isReadyForProduction {
    return !isTestMode &&
        !isDemoMode &&
        isConfigurationValid;
  }

  /// Lista di controlli di configurazione
  static List<String> get configurationChecks {
    final checks = <String>[];

    if (publishableKey.isEmpty) {
      checks.add('❌ Publishable key mancante');
    } else if (!isValidKey(publishableKey)) {
      checks.add('❌ Publishable key formato non valido');
    } else if (isDemoMode) {
      checks.add('⚠️ Usando chiavi demo - sostituire con chiavi reali');
    } else {
      checks.add('✅ Publishable key configurata correttamente');
    }

    if (isTestMode) {
      checks.add('🧪 Modalità TEST attiva - Pronto per sandbox testing');
    } else {
      checks.add('🚨 Modalità LIVE attiva - PRODUZIONE');
    }

    if (currency != 'eur') {
      checks.add('⚠️ Valuta non euro: $currency');
    }

    if (subscriptionPlans.isEmpty) {
      checks.add('❌ Nessun piano di abbonamento configurato');
    } else {
      checks.add('✅ ${subscriptionPlans.length} piani configurati');
    }

    // Check specific per sandbox testing
    if (isReadyForSandboxTesting) {
      checks.add('🎯 READY FOR SANDBOX TESTING');
    }

    return checks;
  }

  /// Informazioni di debug per sandbox testing
  static Map<String, dynamic> get debugInfo => {
    'publishable_key_set': publishableKey.isNotEmpty,
    'publishable_key_valid': isValidKey(publishableKey),
    'publishable_key_length': publishableKey.length,
    'publishable_key_prefix': publishableKey.isNotEmpty
        ? publishableKey.substring(0, 8)
        : 'EMPTY',
    'test_mode': isTestMode,
    'demo_mode': isDemoMode,
    'ready_for_sandbox': isReadyForSandboxTesting,
    'ready_for_production': isReadyForProduction,
    'currency': currency,
    'country_code': countryCode,
    'merchant_identifier': merchantIdentifier,
    'plans_count': subscriptionPlans.length,
    'donation_amounts_count': donationAmounts.length,
    'supported_payment_methods': supportedPaymentMethods,
    'configuration_valid': isConfigurationValid,
    'test_cards_available': testCards.keys.toList(),
  };

  /// Stampa informazioni di configurazione per testing
  static void printSandboxTestingInfo() {
    print('');
    print('🧪 STRIPE SANDBOX TESTING CONFIGURATION');
    print('=========================================');
    print('🔑 Test Mode: ${isTestMode ? "✅ ACTIVE" : "❌ INACTIVE"}');
    print('🎯 Ready for Testing: ${isReadyForSandboxTesting ? "✅ YES" : "❌ NO"}');
    print('');

    if (isReadyForSandboxTesting) {
      print('✅ TESTING READY - You can now test payments!');
      print('');
      print('🧪 TEST CARDS FOR SANDBOX:');
      print('   Success: ${testCards['success']} (CVV: 123, Exp: 12/25)');
      print('   Declined: ${testCards['declined']} (CVV: 123, Exp: 12/25)');
      print('   3D Secure: ${testCards['require_3d_secure']} (CVV: 123, Exp: 12/25)');
      print('   Insufficient: ${testCards['insufficient_funds']} (CVV: 123, Exp: 12/25)');
      print('');
      print('💳 AVAILABLE PLANS:');
      for (final plan in subscriptionPlans.values) {
        print('   ${plan.name}: ${plan.formattedPrice}/${plan.interval}');
      }
      print('');
      print('🎯 TEST FLOW:');
      print('   1. Dashboard → "Vai all\'Abbonamento"');
      print('   2. Subscription Screen → "Sottoscrivi Premium"');
      print('   3. Payment Flow → Use test card: ${testCards['success']}');
      print('   4. Verify success and return to dashboard');
    } else {
      print('❌ NOT READY FOR TESTING');
      print('');
      print('🔧 ISSUES TO FIX:');
      for (final check in configurationChecks) {
        if (check.startsWith('❌') || check.startsWith('⚠️')) {
          print('   $check');
        }
      }
    }

    print('=========================================');
    print('');
  }

  // ============================================================================
  // 🚀 PRODUCTION CONFIGURATION HELPERS
  // ============================================================================

  /// Configura per produzione (da usare quando siamo pronti)
  static Map<String, String> getProductionConfiguration() {
    return {
      'publishable_key': 'pk_live_REPLACE_WITH_REAL_LIVE_KEY',
      'webhook_endpoint': 'https://fitgymtrack.com/api/stripe/webhook.php',
      'return_url': 'https://app.fitgymtrack.com/payment/success',
      'cancel_url': 'https://app.fitgymtrack.com/payment/cancelled',
    };
  }

  /// Checklist per il passaggio in produzione
  static List<String> get productionChecklist {
    return [
      '🔑 Replace test publishable key with live key',
      '🔗 Configure live webhook endpoint',
      '💳 Test with real card in live mode',
      '📱 Test mobile app payments',
      '🔐 Verify security configuration',
      '📊 Set up monitoring and alerts',
      '💰 Configure tax handling if needed',
      '📞 Set up customer support flow',
    ];
  }
}

/// Modello per un piano di abbonamento
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final String stripePriceId;
  final int amount; // in centesimi
  final String interval; // month, year
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.stripePriceId,
    required this.amount,
    required this.interval,
    required this.features,
  });

  /// Prezzo formattato
  String get formattedPrice => StripeConfig.formatAmount(amount);

  /// Prezzo in euro
  double get priceInEuro => StripeConfig.centsToEuro(amount);

  /// Descrizione del periodo
  String get intervalDescription {
    switch (interval) {
      case 'month':
        return 'mensile';
      case 'year':
        return 'annuale';
      case 'week':
        return 'settimanale';
      case 'day':
        return 'giornaliero';
      default:
        return interval;
    }
  }

  /// È un piano annuale?
  bool get isYearly => interval == 'year';

  /// È un piano mensile?
  bool get isMonthly => interval == 'month';

  /// Calcola il risparmio rispetto al piano mensile (se applicabile)
  double? get yearlySavingsPercentage {
    if (!isYearly) return null;

    final monthlyPlan = StripeConfig.subscriptionPlans['premium_monthly'];
    if (monthlyPlan == null) return null;

    final yearlyPricePerMonth = priceInEuro / 12;
    final monthlyCost = monthlyPlan.priceInEuro;

    final savingsPercentage = ((monthlyCost - yearlyPricePerMonth) / monthlyCost) * 100;
    return savingsPercentage;
  }

  /// Stringa del risparmio formattata
  String? get formattedYearlySavings {
    final savings = yearlySavingsPercentage;
    if (savings == null) return null;
    return 'Risparmi ${savings.toStringAsFixed(0)}%';
  }

  @override
  String toString() {
    return 'SubscriptionPlan(id: $id, name: $name, price: $formattedPrice, interval: $interval)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionPlan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}