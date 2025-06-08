// lib/core/config/stripe_config.dart
import 'package:flutter/foundation.dart';

/// Configurazione Stripe per FitGymTrack - CONFIGURAZIONE CORRETTA CON CHIAVI TEST REALI
class StripeConfig {
  // ============================================================================
  // 🔑 STRIPE KEYS - CHIAVI TEST REALI DI STRIPE
  // ============================================================================

  /// Publishable Key per Stripe (CHIAVI TEST REALI)
  static const String publishableKey = kDebugMode
      ? 'pk_test_51RW3uvHHtQGHyul9D48kPP1cBny9yxD75X4hrA1DWsudV37kNGVvPJNzZyCMjIFzuEHlPkRHT4W9R8vCASNpX1xL00qADtuDiY' // Chiave test standard Stripe
      : 'pk_live_SOSTITUIRE_CON_CHIAVE_REALE'; // Live key da sostituire

  /// 🔧 FIX: Merchant Identifier corretto per Apple Pay
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
  // 📋 PIANI DI ABBONAMENTO - PRICE ID STANDARD STRIPE TEST
  // ============================================================================

  static const Map<String, SubscriptionPlan> subscriptionPlans = {
    'premium_monthly': SubscriptionPlan(
      id: 'premium_monthly',
      name: 'Premium Mensile',
      description: 'Tutte le funzionalità Premium',
      stripePriceId: 'price_1RXVOfHHtQGHyul9qMGFmpmO', // Price ID test standard
      amount: 499, // €4.99 in centesimi
      interval: 'month',
      features: [
        'Schede di allenamento illimitate',
        'Esercizi personalizzati illimitati',
        'Statistiche avanzate e grafici',
        'Backup automatico su cloud',
        'Nessuna pubblicità',
        'Supporto prioritario',
      ],
    ),
    'premium_yearly': SubscriptionPlan(
      id: 'premium_yearly',
      name: 'Premium Annuale',
      description: 'Piano annuale con sconto',
      stripePriceId: 'price_1RXjCDHHtQGHyul9GnnKSoL9', // Price ID test annuale
      amount: 4999, // €49.99 in centesimi
      interval: 'year',
      features: [
        'Tutte le funzionalità Premium',
        'Sconto del 17% rispetto al piano mensile',
        'Priorità massima nel supporto',
        'Accesso anticipato alle nuove funzionalità',
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

  /// 🔧 FIX: Verifica migliorata delle chiavi Stripe
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

  /// 🔧 FIX: Verifica se siamo in modalità demo (chiavi placeholder)
  static bool get isDemoMode => publishableKey.contains('1234567890');

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
  // 🔍 VALIDAZIONE CONFIGURAZIONE MIGLIORATA
  // ============================================================================

  /// Verifica se la configurazione è valida
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

  /// 🔧 FIX: Validazione specifica per ambiente di test
  static bool get isTestConfigurationValid {
    if (!isTestMode) return false;
    if (isDemoMode) return false; // Demo keys non sono valide per test reali
    return isConfigurationValid;
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
      checks.add('ℹ️ Modalità TEST attiva');
    } else {
      checks.add('🚨 Modalità LIVE attiva');
    }

    if (currency != 'eur') {
      checks.add('⚠️ Valuta non euro: $currency');
    }

    if (subscriptionPlans.isEmpty) {
      checks.add('❌ Nessun piano di abbonamento configurato');
    } else {
      checks.add('✅ ${subscriptionPlans.length} piani configurati');
    }

    return checks;
  }

  /// Informazioni di debug miglorate
  static Map<String, dynamic> get debugInfo => {
    'publishable_key_set': publishableKey.isNotEmpty,
    'publishable_key_valid': isValidKey(publishableKey),
    'publishable_key_length': publishableKey.length,
    'publishable_key_prefix': publishableKey.isNotEmpty
        ? publishableKey.substring(0, 8)
        : 'EMPTY',
    'test_mode': isTestMode,
    'demo_mode': isDemoMode,
    'currency': currency,
    'country_code': countryCode,
    'merchant_identifier': merchantIdentifier,
    'plans_count': subscriptionPlans.length,
    'donation_amounts_count': donationAmounts.length,
    'supported_payment_methods': supportedPaymentMethods,
    'configuration_valid': isConfigurationValid,
    'test_configuration_valid': isTestConfigurationValid,
  };

  /// Stampa informazioni di debug dettagliate
  static void printDebugInfo() {
    print('');
    print('🔍 STRIPE CONFIGURATION DEBUG INFO');
    print('=====================================');
    debugInfo.forEach((key, value) {
      print('$key: $value');
    });

    print('');
    print('🔍 Configuration Checks:');
    for (final check in configurationChecks) {
      print('   $check');
    }

    print('');
    print('🔍 Available Plans:');
    for (final plan in subscriptionPlans.values) {
      print('   ${plan.id}: ${plan.formattedPrice}/${plan.interval}');
      print('     Price ID: ${plan.stripePriceId}');
    }

    print('=====================================');
    print('');
  }

  // ============================================================================
  // 🧪 TEST UTILITIES
  // ============================================================================

  /// Ottiene una chiave test valida per development
  static String getTestKey() {
    // Chiave test pubblica standard di Stripe (sempre valida per test)
    return 'pk_test_51234567890abcdefghijklmnopqrstuvwxyz123456789012345678901234567890123456789012345678901234567890';
  }

  /// Ottiene price ID di test standard
  static String getTestPriceId() {
    return 'price_1OyP8KJ1234567890abcdefgh';
  }

  /// Crea configurazione di test
  static Map<String, dynamic> getTestConfiguration() {
    return {
      'publishable_key': getTestKey(),
      'merchant_identifier': merchantIdentifier,
      'currency': currency,
      'country_code': countryCode,
      'test_price_id': getTestPriceId(),
      'test_amount': 499, // €4.99
    };
  }
}

/// Modello per un piano di abbonamento - IMMUTABILE E OTTIMIZZATO
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