// lib/core/config/stripe_config.dart
import 'package:flutter/foundation.dart';

/// Configurazione Stripe per FitGymTrack - PRODUZIONE
class StripeConfig {
  // ============================================================================
  // 🔑 STRIPE KEYS - SOSTITUIRE CON CHIAVI REALI
  // ============================================================================

  /// Publishable Key per Stripe (SOSTITUIRE CON QUELLA REALE)
  static const String publishableKey = kDebugMode
      ? 'pk_test_51234567890abcdefghijklmnopqrstuvwxyz' // Test key
      : 'pk_live_SOSTITUIRE_CON_CHIAVE_REALE'; // Live key

  /// Merchant Identifier per Apple Pay
  static const String merchantIdentifier = 'merchant.com.fitgymtracker';

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
  // 📋 PIANI DI ABBONAMENTO
  // ============================================================================

  static const Map<String, SubscriptionPlan> subscriptionPlans = {
    'premium_monthly': SubscriptionPlan(
      id: 'premium_monthly',
      name: 'Premium Mensile',
      description: 'Tutte le funzionalità Premium',
      stripePriceId: 'price_1RXVOfHHtQGHyul9qMGFmpmO', // SOSTITUIRE CON PRICE ID REALE
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

  /// Verifica se una chiave Stripe è valida
  static bool isValidKey(String key) {
    return key.isNotEmpty && (key.startsWith('pk_test_') || key.startsWith('pk_live_'));
  }

  /// Indica se siamo in modalità test
  static bool get isTestMode => publishableKey.startsWith('pk_test_');

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

  /// Informazioni di debug
  static Map<String, dynamic> get debugInfo => {
    'publishable_key_set': publishableKey.isNotEmpty,
    'publishable_key_valid': isValidKey(publishableKey),
    'test_mode': isTestMode,
    'currency': currency,
    'country_code': countryCode,
    'merchant_identifier': merchantIdentifier,
    'plans_count': subscriptionPlans.length,
    'supported_payment_methods': supportedPaymentMethods,
    'configuration_valid': isConfigurationValid,
  };

  /// Stampa informazioni di debug
  static void printDebugInfo() {
    print('🔍 STRIPE CONFIGURATION DEBUG INFO');
    print('=====================================');
    debugInfo.forEach((key, value) {
      print('$key: $value');
    });
    print('=====================================');
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
}