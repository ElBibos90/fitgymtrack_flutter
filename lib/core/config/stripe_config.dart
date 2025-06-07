// lib/core/config/stripe_config.dart
class StripeConfig {
  // ============================================================================
  // STRIPE KEYS (TEST MODE)
  // ============================================================================

  /// Publishable key per il client (pubblico)
  static const String publishableKey = 'pk_test_51RW3uvHHtQGHyul9D48kPP1cBny9yxD75X4hrA1DWsudV37kNGVvPJNzZyCMjIFzuEHlPkRHT4W9R8vCASNpX1xL00qADtuDiY';

  /// Secret key per il server (da NON usare nel client)
  /// Questa è solo per referenza - il server deve usarla
  static const String _secretKey = 'STRIPE_SECRET_KEY';

  // ============================================================================
  // STRIPE CONFIGURATION
  // ============================================================================

  /// Merchant identifier per Apple Pay
  static const String merchantIdentifier = 'merchant.com.fitgymtrack.app';

  /// Country code
  static const String countryCode = 'IT';

  /// Currency
  static const String currency = 'EUR';

  /// Test mode flag
  static const bool isTestMode = true;

  // ============================================================================
  // SUBSCRIPTION CONFIGURATION
  // ============================================================================

  /// Price ID per il piano Premium mensile (da creare in Stripe Dashboard)
  static const String premiumMonthlyPriceId = 'price_premium_monthly_test';

  /// Price ID per il piano Premium annuale (futuro)
  static const String premiumYearlyPriceId = 'price_premium_yearly_test';

  // ============================================================================
  // WEBHOOK CONFIGURATION
  // ============================================================================

  /// Webhook endpoint per ricevere eventi da Stripe
  static const String webhookEndpoint = '/stripe/webhook';

  /// Webhook secret (da configurare nel backend)
  static const String webhookSecret = 'whsec_test_webhook_secret';

  // ============================================================================
  // PAYMENT CONFIGURATION
  // ============================================================================

  /// Timeout per payment intent
  static const Duration paymentTimeout = Duration(minutes: 10);

  /// Metodi di pagamento supportati
  static const List<String> supportedPaymentMethods = [
    'card',
    'google_pay',
    'apple_pay',
  ];

  /// Configurazione per Payment Sheet
  static Map<String, dynamic> get paymentSheetConfiguration => {
    'merchantDisplayName': 'FitGymTrack',
    'allowsDelayedPaymentMethods': true,
    'appearance': {
      'primaryButton': {
        'backgroundColor': '#1976D2',
      }
    }
  };

  // ============================================================================
  // PRODUCTS CONFIGURATION
  // ============================================================================

  /// Configurazione dei piani di abbonamento
  static const Map<String, SubscriptionPlanConfig> subscriptionPlans = {
    'premium_monthly': SubscriptionPlanConfig(
      id: 'premium_monthly',
      stripePriceId: premiumMonthlyPriceId,
      name: 'Premium Mensile',
      description: 'Piano Premium con fatturazione mensile',
      amount: 499, // in centesimi (€4.99)
      currency: currency,
      interval: 'month',
      intervalCount: 1,
    ),
  };

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Ritorna la configurazione per l'inizializzazione di Stripe
  static Map<String, dynamic> getInitConfiguration() {
    return {
      'publishableKey': publishableKey,
      'merchantIdentifier': merchantIdentifier,
      'countryCode': countryCode,
    };
  }

  /// Converte euro in centesimi per Stripe
  static int euroToCents(double euros) {
    return (euros * 100).round();
  }

  /// Converte centesimi in euro da Stripe
  static double centsToEuro(int cents) {
    return cents / 100.0;
  }

  /// Valida una chiave Stripe
  static bool isValidKey(String key) {
    if (key.isEmpty) return false;
    return key.startsWith('pk_') || key.startsWith('sk_');
  }

  /// Ritorna l'environment corrente
  static String get environment => isTestMode ? 'test' : 'live';

  /// Log delle configurazioni per debug
  static void printConfiguration() {
    print('🔧 [STRIPE] Stripe Configuration:');
    print('🔧 [STRIPE] Environment: $environment');
    print('🔧 [STRIPE] Country: $countryCode');
    print('🔧 [STRIPE] Currency: $currency');
    print('🔧 [STRIPE] Merchant ID: $merchantIdentifier');
    print('🔧 [STRIPE] Publishable Key: ${publishableKey.substring(0, 12)}...');
    print('🔧 [STRIPE] Supported Payment Methods: $supportedPaymentMethods');
  }
}

/// Configurazione per un piano di abbonamento
class SubscriptionPlanConfig {
  final String id;
  final String stripePriceId;
  final String name;
  final String description;
  final int amount; // in centesimi
  final String currency;
  final String interval; // 'month', 'year'
  final int intervalCount;

  const SubscriptionPlanConfig({
    required this.id,
    required this.stripePriceId,
    required this.name,
    required this.description,
    required this.amount,
    required this.currency,
    required this.interval,
    required this.intervalCount,
  });

  /// Prezzo formattato
  String get formattedPrice {
    final euros = amount / 100.0;
    return '€${euros.toStringAsFixed(2)}/${interval == 'month' ? 'mese' : 'anno'}';
  }

  /// Converte in Map per API calls
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'price_id': stripePriceId,
      'name': name,
      'description': description,
      'amount': amount,
      'currency': currency,
      'interval': interval,
      'interval_count': intervalCount,
    };
  }
}