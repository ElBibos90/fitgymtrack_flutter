// lib/features/payments/services/stripe_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:developer' as developer;
import '../../../core/config/stripe_config.dart';
import '../models/stripe_models.dart';
import '../../../core/utils/result.dart';

/// Servizio per gestire le operazioni Stripe nel client - VERSIONE ROBUSTA
class StripeService {
  static bool _isInitialized = false;
  static String? _lastError;
  static DateTime? _lastInitAttempt;
  static int _initAttempts = 0;

  /// Inizializza Stripe SDK con gestione errori robusta
  static Future<Result<bool>> initialize() async {
    if (_isInitialized) {
      developer.log('✅ [STRIPE] Already initialized', name: 'StripeService');
      return Result.success(true);
    }

    _lastInitAttempt = DateTime.now();
    _initAttempts++;

    return Result.tryCallAsync(() async {
      developer.log('🔧 [STRIPE] Initializing Stripe SDK (attempt $_initAttempts)...', name: 'StripeService');

      // Verifica prerequisiti
      if (StripeConfig.publishableKey.isEmpty) {
        throw Exception('❌ Publishable key Stripe vuota');
      }

      if (!StripeConfig.publishableKey.startsWith('pk_')) {
        throw Exception('❌ Publishable key formato non valido (deve iniziare con pk_)');
      }

      try {
        // 🔧 STEP 1: Configura Stripe Publishable Key
        developer.log('🔧 [STRIPE] Step 1: Setting publishable key...', name: 'StripeService');
        Stripe.publishableKey = StripeConfig.publishableKey;

        // 🔧 STEP 2: Configura Merchant Identifier
        developer.log('🔧 [STRIPE] Step 2: Setting merchant identifier...', name: 'StripeService');
        Stripe.merchantIdentifier = StripeConfig.merchantIdentifier;

        // 🔧 STEP 3: Applica Settings con retry migliorato
        developer.log('🔧 [STRIPE] Step 3: Applying Stripe settings...', name: 'StripeService');
        await _applySettingsWithEnhancedRetry();

        _isInitialized = true;
        _lastError = null;

        developer.log('✅ [STRIPE] Stripe SDK initialized successfully!', name: 'StripeService');
        developer.log('✅ [STRIPE] - Publishable key: ${StripeConfig.publishableKey.substring(0, 20)}...', name: 'StripeService');
        developer.log('✅ [STRIPE] - Merchant ID: ${StripeConfig.merchantIdentifier}', name: 'StripeService');
        developer.log('✅ [STRIPE] - Test mode: ${StripeConfig.isTestMode}', name: 'StripeService');

        return true;

      } catch (e) {
        _lastError = e.toString();
        developer.log('❌ [STRIPE] Initialization failed: $e', name: 'StripeService');

        // 🔧 Analisi errore per retry intelligente
        if (_shouldRetryWithDelay(e.toString()) && _initAttempts < 3) {
          developer.log('🔄 [STRIPE] Scheduling retry in ${_initAttempts * 2} seconds...', name: 'StripeService');
          await Future.delayed(Duration(seconds: _initAttempts * 2));
          return await _retryInitialization();
        }

        rethrow;
      }
    });
  }

  /// Applica le impostazioni Stripe con retry più robusto
  static Future<void> _applySettingsWithEnhancedRetry() async {
    int attempts = 0;
    const maxAttempts = 5;
    const baseDelayMs = 500;

    while (attempts < maxAttempts) {
      try {
        attempts++;
        developer.log('🔧 [STRIPE] Applying settings attempt $attempts/$maxAttempts...', name: 'StripeService');

        await Stripe.instance.applySettings();

        developer.log('✅ [STRIPE] Settings applied successfully on attempt $attempts', name: 'StripeService');
        return;

      } catch (e) {
        developer.log('⚠️ [STRIPE] Settings apply attempt $attempts failed: $e', name: 'StripeService');

        if (attempts >= maxAttempts) {
          throw Exception('🚨 STRIPE CONFIGURATION ERROR: Failed to apply Stripe settings after $maxAttempts attempts.\n'
              'Error: $e\n\n'
              '💡 POSSIBLE SOLUTIONS:\n'
              '1. Make sure your Android theme uses Theme.AppCompat or Theme.MaterialComponents\n'
              '2. Verify MainActivity extends FlutterFragmentActivity\n'
              '3. Check if required dependencies are in build.gradle\n'
              '4. Restart the app completely\n\n'
              'See: https://github.com/flutter-stripe/flutter_stripe#android');
        }

        // Delay progressivo per retry
        final delayMs = baseDelayMs * attempts;
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  /// Retry automatico dell'inizializzazione
  static Future<bool> _retryInitialization() async {
    try {
      _isInitialized = false;

      // Reset stato
      await Future.delayed(const Duration(milliseconds: 800));

      // Retry inizializzazione
      final result = await initialize();
      return result.isSuccess;

    } catch (e) {
      developer.log('❌ [STRIPE] Retry initialization failed: $e', name: 'StripeService');
      return false;
    }
  }

  /// Determina se dovremmo fare retry dell'inizializzazione
  static bool _shouldRetryWithDelay(String error) {
    const retryableErrors = [
      'network',
      'timeout',
      'connection',
      'temporary',
      'failed to initialize',
    ];

    final errorLower = error.toLowerCase();
    return retryableErrors.any((retryable) => errorLower.contains(retryable));
  }

  /// Verifica se Stripe è inizializzato
  static bool get isInitialized => _isInitialized;

  /// Ultimo errore di inizializzazione
  static String? get lastError => _lastError;

  /// Numero di tentativi di inizializzazione
  static int get initAttempts => _initAttempts;

  /// Presenta Payment Sheet per il pagamento
  static Future<Result<PaymentSheetPaymentOption?>> presentPaymentSheet({
    required String clientSecret,
    String? customerId,
    String? ephemeralKeySecret,
    PaymentSheetAppearance? appearance,
  }) async {
    if (!_isInitialized) {
      return Result.error('Stripe non è stato inizializzato. Chiama initialize() prima.');
    }

    return Result.tryCallAsync(() async {
      developer.log('🔧 [STRIPE] Presenting Payment Sheet...', name: 'StripeService');
      developer.log('🔧 [STRIPE] Client secret: ${clientSecret.substring(0, 20)}...', name: 'StripeService');

      try {
        // Inizializza Payment Sheet
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'FitGymTrack',
            customerId: customerId,
            customerEphemeralKeySecret: ephemeralKeySecret,
            style: ThemeMode.system,
            appearance: appearance ?? _getDefaultAppearance(),
            allowsDelayedPaymentMethods: true,
            setupIntentClientSecret: null,
          ),
        );

        developer.log('✅ [STRIPE] Payment Sheet initialized', name: 'StripeService');

        // Presenta Payment Sheet
        final result = await Stripe.instance.presentPaymentSheet();

        developer.log('✅ [STRIPE] Payment Sheet completed successfully', name: 'StripeService');

        return result;

      } catch (e) {
        developer.log('❌ [STRIPE] Payment Sheet error: $e', name: 'StripeService');

        // Gestisci errori specifici di Payment Sheet
        if (e is StripeException) {
          final errorInfo = handleStripeException(e);
          throw Exception('Payment failed: ${errorInfo['user_message'] ?? errorInfo['message']}');
        }

        rethrow;
      }
    });
  }

  /// Conferma pagamento con Payment Method
  static Future<Result<PaymentIntent>> confirmPayment({
    required String clientSecret,
    PaymentMethodParams? paymentMethodParams,
    PaymentMethodOptions? options,
  }) async {
    if (!_isInitialized) {
      return Result.error('Stripe non è stato inizializzato');
    }

    return Result.tryCallAsync(() async {
      developer.log('🔧 [STRIPE] Confirming payment...', name: 'StripeService');

      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: paymentMethodParams,
        options: options,
      );

      developer.log('✅ [STRIPE] Payment confirmed: ${result.status}', name: 'StripeService');

      return result;
    });
  }

  /// Crea Payment Method da carta
  static Future<Result<PaymentMethod>> createPaymentMethod({
    required PaymentMethodParams params,
  }) async {
    if (!_isInitialized) {
      return Result.error('Stripe non è stato inizializzato');
    }

    return Result.tryCallAsync(() async {
      developer.log('🔧 [STRIPE] Creating payment method...', name: 'StripeService');

      final result = await Stripe.instance.createPaymentMethod(
        params: params,
      );

      developer.log('✅ [STRIPE] Payment method created: ${result.id}', name: 'StripeService');

      return result;
    });
  }

  /// Verifica se Google Pay è disponibile
  static Future<Result<bool>> isGooglePaySupported() async {
    if (!_isInitialized) {
      return Result.error('Stripe non è stato inizializzato');
    }

    return Result.tryCallAsync(() async {
      final isSupported = await Stripe.instance.isGooglePaySupported(
        const IsGooglePaySupportedParams(),
      );

      developer.log('🔧 [STRIPE] Google Pay supported: $isSupported', name: 'StripeService');

      return isSupported;
    });
  }

  /// Presenta Google Pay
  static Future<Result<void>> presentGooglePay({
    required String clientSecret,
    required bool isPaymentIntent,
    String? currencyCode,
  }) async {
    if (!_isInitialized) {
      return Result.error('Stripe non è stato inizializzato');
    }

    return Result.tryCallAsync(() async {
      developer.log('🔧 [STRIPE] Presenting Google Pay...', name: 'StripeService');

      await Stripe.instance.initGooglePay(
        GooglePayInitParams(
          testEnv: StripeConfig.isTestMode,
          merchantName: 'FitGymTrack',
          countryCode: StripeConfig.countryCode,
        ),
      );

      if (isPaymentIntent) {
        await Stripe.instance.presentGooglePay(
          PresentGooglePayParams(
            clientSecret: clientSecret,
            forSetupIntent: false,
          ),
        );
      }

      developer.log('✅ [STRIPE] Google Pay presented successfully', name: 'StripeService');
    });
  }

  /// Ottiene l'aspetto di default per Payment Sheet
  static PaymentSheetAppearance _getDefaultAppearance() {
    return const PaymentSheetAppearance(
      colors: PaymentSheetAppearanceColors(
        primary: Color(0xFF1976D2),
        background: Color(0xFFFFFFFF),
        componentBackground: Color(0xFFF8FAFC),
        componentBorder: Color(0xFFE2E8F0),
        componentDivider: Color(0xFFE2E8F0),
        primaryText: Color(0xFF0F172A),
        secondaryText: Color(0xFF64748B),
        componentText: Color(0xFF0F172A),
        placeholderText: Color(0xFF94A3B8),
      ),
      shapes: PaymentSheetShape(
        borderWidth: 1.0,
      ),
      primaryButton: PaymentSheetPrimaryButtonAppearance(
        colors: PaymentSheetPrimaryButtonTheme(
          light: PaymentSheetPrimaryButtonThemeColors(
            background: Color(0xFF1976D2),
            text: Color(0xFFFFFFFF),
            border: Color(0xFF1976D2),
          ),
          dark: PaymentSheetPrimaryButtonThemeColors(
            background: Color(0xFF90CAF9),
            text: Color(0xFF0D47A1),
            border: Color(0xFF90CAF9),
          ),
        ),
        shapes: PaymentSheetPrimaryButtonShape(
          borderWidth: 1.0,
        ),
      ),
    );
  }

  /// Gestisce gli errori Stripe con messaggi user-friendly
  static Map<String, dynamic> handleStripeException(StripeException exception) {
    developer.log('❌ [STRIPE] Stripe exception: ${exception.error}', name: 'StripeService');

    final error = exception.error;
    String userMessage = 'Si è verificato un errore durante il pagamento.';

    // Traduci errori comuni in messaggi user-friendly
    switch (error.code) {
      case 'card_declined':
        userMessage = 'Carta rifiutata. Controlla i dati o usa un altro metodo di pagamento.';
        break;
      case 'insufficient_funds':
        userMessage = 'Fondi insufficienti sulla carta.';
        break;
      case 'expired_card':
        userMessage = 'Carta scaduta.';
        break;
      case 'incorrect_cvc':
        userMessage = 'Codice di sicurezza non valido.';
        break;
      case 'processing_error':
        userMessage = 'Errore durante l\'elaborazione. Riprova.';
        break;
      case 'authentication_required':
        userMessage = 'Autenticazione richiesta. Completa la verifica 3D Secure.';
        break;
      case 'canceled':
        userMessage = 'Pagamento annullato dall\'utente.';
        break;
      default:
        userMessage = error.message ?? userMessage;
    }

    return {
      'code': error.code ?? 'unknown_error',
      'message': error.message ?? 'Errore sconosciuto',
      'user_message': userMessage,
      'type': error.type.toString(),
      'decline_code': error.declineCode,
      'payment_intent_id': null,
    };
  }

  /// Crea parametri per Payment Method da carta manuale
  static PaymentMethodParams createCardPaymentMethodParams({
    BillingDetails? billingDetails,
  }) {
    return PaymentMethodParams.card(
      paymentMethodData: PaymentMethodData(
        billingDetails: billingDetails,
      ),
    );
  }

  /// Force re-initialization con reset completo
  static Future<Result<bool>> forceReinitialize() async {
    developer.log('🔄 [STRIPE] Forcing complete re-initialization...', name: 'StripeService');

    _isInitialized = false;
    _lastError = null;
    _initAttempts = 0;

    // Breve pausa per reset completo
    await Future.delayed(const Duration(seconds: 1));

    return await initialize();
  }

  /// Health check completo per Stripe
  static Future<Map<String, dynamic>> healthCheck() async {
    final health = {
      'is_initialized': _isInitialized,
      'last_error': _lastError,
      'last_init_attempt': _lastInitAttempt?.toIso8601String(),
      'init_attempts': _initAttempts,
      'publishable_key_set': Stripe.publishableKey?.isNotEmpty ?? false,
      'merchant_identifier': Stripe.merchantIdentifier,
      'config_valid': StripeConfig.isValidKey(StripeConfig.publishableKey),
      'config_test_mode': StripeConfig.isTestMode,
    };

    // Test funzionalità se inizializzato
    if (_isInitialized) {
      try {
        // Test Google Pay come proxy per verifica SDK
        final gpaySupported = await Stripe.instance.isGooglePaySupported(
          const IsGooglePaySupportedParams(),
        );
        health['sdk_responsive'] = true;
        health['google_pay_supported'] = gpaySupported;
      } catch (e) {
        health['sdk_responsive'] = false;
        health['sdk_error'] = e.toString();
      }
    }

    return health;
  }

  /// Test rapido di inizializzazione
  static Future<bool> quickHealthTest() async {
    try {
      if (!_isInitialized) {
        final result = await initialize();
        return result.isSuccess;
      }

      // Se già inizializzato, testa con una chiamata leggera
      await Stripe.instance.isGooglePaySupported(const IsGooglePaySupportedParams());
      return true;

    } catch (e) {
      developer.log('❌ [STRIPE] Quick health test failed: $e', name: 'StripeService');
      return false;
    }
  }

  /// Cleanup risorse
  static void dispose() {
    developer.log('🔧 [STRIPE] Disposing Stripe service...', name: 'StripeService');
    _isInitialized = false;
    _lastError = null;
    _lastInitAttempt = null;
    _initAttempts = 0;
  }

  /// Reset per testing
  static void reset() {
    dispose();
  }

  /// Informazioni diagnostiche complete
  static Map<String, dynamic> getDiagnosticInfo() {
    return {
      'is_initialized': _isInitialized,
      'last_error': _lastError,
      'last_init_attempt': _lastInitAttempt?.toIso8601String(),
      'init_attempts': _initAttempts,
      'publishable_key_set': Stripe.publishableKey?.isNotEmpty ?? false,
      'publishable_key_valid': StripeConfig.isValidKey(StripeConfig.publishableKey),
      'merchant_identifier': Stripe.merchantIdentifier,
      'test_mode': StripeConfig.isTestMode,
      'country_code': StripeConfig.countryCode,
      'currency': StripeConfig.currency,
      'config': {
        'publishable_key_length': StripeConfig.publishableKey.length,
        'publishable_key_prefix': StripeConfig.publishableKey.isNotEmpty
            ? StripeConfig.publishableKey.substring(0, 8)
            : 'EMPTY',
        'supported_payment_methods': StripeConfig.supportedPaymentMethods,
      },
      'system_info': {
        'dart_version': '3.4.0',
        'flutter_stripe_version': '10.1.1',
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Stampa informazioni diagnostiche per debug
  static void printDiagnosticInfo() {
    final info = getDiagnosticInfo();
    print('');
    print('🔍 STRIPE SERVICE DIAGNOSTIC INFO');
    print('================================');
    print('✅ Initialized: ${info['is_initialized']}');
    print('🔧 Init attempts: ${info['init_attempts']}');
    print('⚠️ Last error: ${info['last_error'] ?? 'None'}');
    print('🔑 Key set: ${info['publishable_key_set']}');
    print('🏪 Merchant ID: ${info['merchant_identifier']}');
    print('🧪 Test mode: ${info['test_mode']}');
    print('================================');
    print('');
  }
}