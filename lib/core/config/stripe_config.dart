// lib/core/config/stripe_config.dart
import 'package:flutter/foundation.dart';

/// Configurazione Stripe per FitGymTrack - AGGIORNATA con supporto Recurring/OneTime
class StripeConfig {
  // ============================================================================
  // 🔑 STRIPE KEYS - TEST MODE READY FOR REAL TESTING
  // ============================================================================

  /// Publishable Key per Stripe (TEST KEYS for sandbox testing)
  static const String publishableKey = 'pk_test_51RW3uvHHtQGHyul9D48kPP1cBny9yxD75X4hrA1DWsudV37kNGVvPJNzZyCMjIFzuEHlPkRHT4W9R8vCASNpX1xL00qADtuDiY'; // ✅ REAL test key

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
  // 📋 PIANI DI ABBONAMENTO - AGGIORNATI CON RECURRING/ONETIME
  // ============================================================================

  static const Map<String, SubscriptionPlan> subscriptionPlans = {
    'premium_monthly_recurring': SubscriptionPlan(
      id: 'premium_monthly_recurring',
      name: 'Premium Mensile Ricorrente',
      description: 'Si rinnova automaticamente ogni mese. Cancella quando vuoi.',
      stripePriceId: 'price_1RXVOfHHtQGHyul9qMGFmpmO', // ✅ Existing recurring price
      amount: 499, // €4.99 in centesimi
      interval: 'month',
      isRecurring: true, // 🆕 NUOVO CAMPO
      features: [
        '🏋️ Schede di allenamento illimitate',
        '💪 Esercizi personalizzati illimitati',
        '📊 Statistiche avanzate dettagliate',
        '☁️ Backup automatico su cloud',
        '🚫 Nessuna pubblicità',
        '🔄 Rinnovo automatico',
        '❌ Cancella in qualsiasi momento',
      ],
    ),
    'premium_monthly_onetime': SubscriptionPlan(
      id: 'premium_monthly_onetime',
      name: 'Premium Mensile Una Tantum',
      description: '30 giorni di accesso Premium senza rinnovo automatico.',
      stripePriceId: 'price_1RXVOfHHtQGHyul9qMGFmpmO', // ✅ New one-time price
      amount: 499, // €4.99 in centesimi - STESSO PREZZO
      interval: 'month',
      isRecurring: false, // 🆕 NUOVO CAMPO
      features: [
        '🏋️ Schede di allenamento illimitate',
        '💪 Esercizi personalizzati illimitati',
        '📊 Statistiche avanzate dettagliate',
        '☁️ Backup automatico su cloud',
        '🚫 Nessuna pubblicità',
        '⏰ 30 giorni di accesso',
        '🔒 Nessun rinnovo automatico',
      ],
    ),
  };

  // ============================================================================
  // 🎯 HELPER METHODS PER I PIANI
  // ============================================================================

  /// Ottieni il piano ricorrente
  static SubscriptionPlan get recurringPlan => subscriptionPlans['premium_monthly_recurring']!;

  /// Ottieni il piano una tantum
  static SubscriptionPlan get onetimePlan => subscriptionPlans['premium_monthly_onetime']!;

  /// Ottieni lista piani per UI
  static List<SubscriptionPlan> get availablePlans => [recurringPlan, onetimePlan];

  /// Ottieni piano per payment type
  static SubscriptionPlan getPlanByPaymentType(String paymentType) {
    switch (paymentType) {
      case 'recurring':
        return recurringPlan;
      case 'onetime':
        return onetimePlan;
      default:
        return recurringPlan; // Default fallback
    }
  }

  // ============================================================================
  // 🔍 VALIDAZIONE E UTILITY (compatibilità con StripeService esistente)
  // ============================================================================

  /// Verifica se una chiave Stripe è valida
  static bool isValidKey(String key) {
    if (key.isEmpty) return false;
    return key.startsWith('pk_test_') || key.startsWith('pk_live_');
  }

  /// Verifica se siamo in modalità test
  static bool get isTestMode {
    return publishableKey.startsWith('pk_test_');
  }

  /// Verifica se siamo in modalità demo (per debug)
  static bool get isDemoMode {
    // Demo mode se la chiave contiene pattern tipici di demo
    return publishableKey.contains('REPLACE') ||
        publishableKey == 'pk_test_51234567890abcdefghijklmnopqrstuvwxyz123456789012345678901234567890123456789012345678901234567890';
  }

  /// Verifica se è pronto per sandbox testing
  static bool get isReadyForSandboxTesting {
    return isTestMode && !isDemoMode && isValidKey(publishableKey);
  }

  // ============================================================================
  // 💰 PREZZI E FORMATTAZIONE
  // ============================================================================

  /// Formatta un importo in centesimi come stringa
  static String formatAmount(int amountInCents) {
    final euros = amountInCents / 100;
    return '€${euros.toStringAsFixed(2)}';
  }

  /// Converte centesimi in euro
  static double centsToEuro(int cents) => cents / 100.0;

  /// Converte euro in centesimi
  static int euroToCents(double euros) => (euros * 100).round();

  // ============================================================================
  // 🧪 TEST CONFIGURATION & VERIFICATION
  // ============================================================================

  /// Test cards da usare durante lo sviluppo
  static const Map<String, String> testCards = {
    'success': '4242424242424242',
    'declined': '4000000000000002',
    'insufficient_funds': '4000000000009995',
    'authentication_required': '4000002500003155',
  };

  /// Verifica se la configurazione è pronta per il testing
  static List<String> get configurationChecks {
    final checks = <String>[];

    // Check keys
    if (publishableKey.isEmpty || publishableKey.contains('REPLACE')) {
      checks.add('❌ Publishable key non configurata');
    } else {
      checks.add('✅ Publishable key configurata');
    }

    // Check piani
    if (subscriptionPlans.isEmpty) {
      checks.add('❌ Nessun piano configurato');
    } else {
      checks.add('✅ ${subscriptionPlans.length} piani configurati');

      // Check price IDs
      for (final plan in subscriptionPlans.values) {
        if (plan.stripePriceId.isEmpty || plan.stripePriceId.contains('REPLACE')) {
          checks.add('❌ Price ID non configurato per ${plan.name}');
        } else {
          checks.add('✅ Price ID configurato per ${plan.name}');
        }
      }
    }

    // Check merchant identifier per Apple Pay
    if (merchantIdentifier.isEmpty) {
      checks.add('⚠️ Merchant identifier per Apple Pay non configurato');
    } else {
      checks.add('✅ Merchant identifier configurato');
    }

    return checks;
  }

  /// Verifica se la configurazione è pronta per il testing
  static bool get isReadyForTesting {
    return isValidKey(publishableKey) && !isDemoMode;
  }

  /// Stampa informazioni di configurazione per debug
  static void printTestingInfo() {
    print('[CONSOLE] [stripe_config]');
    print('[CONSOLE] [stripe_config]🔍 STRIPE CONFIGURATION STATUS');
    print('[CONSOLE] [stripe_config]=====================================');

    for (final check in configurationChecks) {
      print('[CONSOLE] [stripe_config]$check');
    }

    print('[CONSOLE] [stripe_config]');

    if (isReadyForTesting) {
      print('[CONSOLE] [stripe_config]✅ READY FOR TESTING');
      print('[CONSOLE] [stripe_config]');
      print('[CONSOLE] [stripe_config]🚀 TEST FLOW:');
      print('[CONSOLE] [stripe_config]   1. Dashboard → "Vai all\'Abbonamento"');
      print('[CONSOLE] [stripe_config]   2. Subscription Screen → Scegli tipo pagamento');
      print('[CONSOLE] [stripe_config]   3. Payment Flow → Use test card: ${testCards['success']}');
      print('[CONSOLE] [stripe_config]   4. Verify success and return to dashboard');
    } else {
      print('[CONSOLE] [stripe_config]❌ NOT READY FOR TESTING');
      print('[CONSOLE] [stripe_config]');
      print('[CONSOLE] [stripe_config]🔧 ISSUES TO FIX:');
      for (final check in configurationChecks) {
        if (check.startsWith('❌') || check.startsWith('⚠️')) {
          print('[CONSOLE] [stripe_config]   $check');
        }
      }
    }

    print('[CONSOLE] [stripe_config]=========================================');
    print('[CONSOLE] [stripe_config]');
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

/// Modello per un piano di abbonamento - AGGIORNATO
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final String stripePriceId;
  final int amount; // in centesimi
  final String interval; // month, year
  final bool isRecurring; // 🆕 NUOVO CAMPO
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.stripePriceId,
    required this.amount,
    required this.interval,
    required this.isRecurring, // 🆕 NUOVO CAMPO
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
        return isRecurring ? 'mensile ricorrente' : 'mensile una tantum';
      case 'year':
        return isRecurring ? 'annuale ricorrente' : 'annuale una tantum';
      case 'week':
        return isRecurring ? 'settimanale ricorrente' : 'settimanale una tantum';
      case 'day':
        return isRecurring ? 'giornaliero ricorrente' : 'giornaliero una tantum';
      default:
        return interval;
    }
  }

  /// È un piano annuale?
  bool get isYearly => interval == 'year';

  /// È un piano mensile?
  bool get isMonthly => interval == 'month';

  /// Payment type per il backend
  String get paymentType => isRecurring ? 'recurring' : 'onetime';

  /// Badge description per UI
  String get badgeText {
    if (isRecurring) {
      return 'RINNOVO AUTOMATICO';
    } else {
      return 'UNA TANTUM';
    }
  }

  /// Badge color per UI
  String get badgeColor {
    if (isRecurring) {
      return 'blue'; // Blu per ricorrente
    } else {
      return 'green'; // Verde per una tantum
    }
  }

  /// Subtitle per UI
  String get subtitle {
    if (isRecurring) {
      return 'Si rinnova automaticamente. Cancella quando vuoi.';
    } else {
      return '30 giorni di accesso. Nessun rinnovo automatico.';
    }
  }
}