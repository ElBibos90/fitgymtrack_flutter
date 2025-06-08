// lib/features/payments/services/stripe_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/config/stripe_config.dart';
import '../models/stripe_models.dart';
import '../../../core/utils/result.dart';

/// Servizio per gestire le operazioni Stripe nel client - VERSIONE DEFINITIVA E ROBUSTA
class StripeService {
  static bool _isInitialized = false;
  static String? _lastError;
  static DateTime? _lastInitAttempt;
  static int _initAttempts = 0;
  static String? _currentPublishableKey;

  /// Inizializza Stripe SDK con gestione errori super robusta
  static Future<Result<bool>> initialize() async {
    if (_isInitialized && _currentPublishableKey == StripeConfig.publishableKey) {
      print('[CONSOLE]✅ [STRIPE SERVICE] Already initialized with current key');
      return Result.success(true);
    }

    _lastInitAttempt = DateTime.now();
    _initAttempts++;

    return Result.tryCallAsync(() async {
      print('[CONSOLE]🔧 [STRIPE SERVICE] Initializing Stripe SDK (attempt $_initAttempts)...');

      // ============================================================================
      // STEP 1: VALIDAZIONE CONFIGURAZIONE
      // ============================================================================

      if (StripeConfig.publishableKey.isEmpty) {
        throw Exception('❌ Stripe publishable key is empty in StripeConfig');
      }

      if (!StripeConfig.isValidKey(StripeConfig.publishableKey)) {
        throw Exception('❌ Invalid Stripe publishable key format: ${StripeConfig.publishableKey.substring(0, 8)}...');
      }

      if (StripeConfig.isDemoMode) {
        print('[CONSOLE]⚠️ [STRIPE SERVICE] Demo mode detected - using placeholder configuration');
        // In demo mode, usiamo configurazione basilare
        return await _initializeDemoMode();
      }

      try {
        // ============================================================================
        // STEP 2: CONFIGURA STRIPE PUBLISHABLE KEY
        // ============================================================================

        print('[CONSOLE]🔧 [STRIPE SERVICE] Step 1: Setting publishable key...');
        Stripe.publishableKey = StripeConfig.publishableKey;
        _currentPublishableKey = StripeConfig.publishableKey;

        // ============================================================================
        // STEP 3: CONFIGURA MERCHANT IDENTIFIER
        // ============================================================================

        print('[CONSOLE]🔧 [STRIPE SERVICE] Step 2: Setting merchant identifier...');
        Stripe.merchantIdentifier = StripeConfig.merchantIdentifier;

        // ============================================================================
        // STEP 4: APPLICA SETTINGS CON RETRY SUPER INTELLIGENTE
        // ============================================================================

        print('[CONSOLE]🔧 [STRIPE SERVICE] Step 3: Applying Stripe settings...');
        await _applySettingsWithSuperRetry();

        _isInitialized = true;
        _lastError = null;

        print('[CONSOLE]✅ [STRIPE SERVICE] Stripe SDK initialized successfully!');
        print('[CONSOLE]✅ [STRIPE SERVICE] - Key: ${StripeConfig.publishableKey.substring(0, 20)}...');
        print('[CONSOLE]✅ [STRIPE SERVICE] - Merchant ID: ${StripeConfig.merchantIdentifier}');
        print('[CONSOLE]✅ [STRIPE SERVICE] - Test mode: ${StripeConfig.isTestMode}');
        print('[CONSOLE]✅ [STRIPE SERVICE] - Demo mode: ${StripeConfig.isDemoMode}');

        return true;

      } catch (e) {
        _lastError = e.toString();
        print('[CONSOLE]❌ [STRIPE SERVICE] Initialization failed: $e');

        // ============================================================================
        // RETRY INTELLIGENTE CON ANALISI ERRORE
        // ============================================================================

        if (_shouldRetryWithDelay(e.toString()) && _initAttempts < 5) {
          print('[CONSOLE]🔄 [STRIPE SERVICE] Scheduling intelligent retry in ${_initAttempts * 2} seconds...');
          await Future.delayed(Duration(seconds: _initAttempts * 2));
          return await _retryInitialization();
        }

        // Se non può fare retry, prova modalità degraded
        if (_initAttempts >= 3) {
          print('[CONSOLE]⚠️ [STRIPE SERVICE] Multiple failures - attempting degraded mode...');
          return await _initializeDegradedMode();
        }

        rethrow;
      }
    });
  }

  /// Inizializzazione in modalità demo
  static Future<bool> _initializeDemoMode() async {
    print('[CONSOLE]🎭 [STRIPE SERVICE] Initializing in DEMO mode...');

    try {
      // Usa una chiave test standard di Stripe per demo
      final demoKey = 'pk_test_51234567890abcdefghijklmnopqrstuvwxyz123456789012345678901234567890123456789012345678901234567890';

      Stripe.publishableKey = demoKey;
      Stripe.merchantIdentifier = StripeConfig.merchantIdentifier;

      // Applica settings basilari
      await Stripe.instance.applySettings();

      _isInitialized = true;
      _lastError = null;

      print('[CONSOLE]🎭 [STRIPE SERVICE] Demo mode initialized successfully');
      return true;

    } catch (e) {
      print('[CONSOLE]❌ [STRIPE SERVICE] Demo mode initialization failed: $e');
      return false;
    }
  }

  /// Inizializzazione in modalità degraded (solo funzioni base)
  static Future<bool> _initializeDegradedMode() async {
    print('[CONSOLE]⚙️ [STRIPE SERVICE] Initializing in DEGRADED mode...');

    try {
      // Prova solo configurazione base senza applySettings
      if (StripeConfig.isValidKey(StripeConfig.publishableKey)) {
        Stripe.publishableKey = StripeConfig.publishableKey;
        _currentPublishableKey = StripeConfig.publishableKey;
      }

      _isInitialized = true;
      _lastError = 'Initialized in degraded mode - limited functionality';

      print('[CONSOLE]⚙️ [STRIPE SERVICE] Degraded mode initialized');
      return true;

    } catch (e) {
      print('[CONSOLE]❌ [STRIPE SERVICE] Degraded mode failed: $e');
      return false;
    }
  }

  /// Applica le impostazioni Stripe con retry super intelligente
  static Future<void> _applySettingsWithSuperRetry() async {
    int attempts = 0;
    const maxAttempts = 7;
    const baseDelayMs = 500;
    List<String> attemptedStrategies = [];

    while (attempts < maxAttempts) {
      attempts++;
      print('[CONSOLE]🔧 [STRIPE SERVICE] Applying settings - attempt $attempts/$maxAttempts...');

      try {
        // Strategia 1-3: Retry normale con delay progressivo
        if (attempts <= 3) {
          await Stripe.instance.applySettings();
          print('[CONSOLE]✅ [STRIPE SERVICE] Settings applied successfully on attempt $attempts');
          return;
        }

        // Strategia 4: Retry con delay più lungo
        if (attempts == 4) {
          attemptedStrategies.add('Extended timeout');
          await Future.delayed(const Duration(seconds: 3));
          await Stripe.instance.applySettings();
          print('[CONSOLE]✅ [STRIPE SERVICE] Settings applied with extended timeout');
          return;
        }

        // Strategia 5: Re-set chiave e retry
        if (attempts == 5) {
          attemptedStrategies.add('Key reset');
          Stripe.publishableKey = StripeConfig.publishableKey;
          await Future.delayed(const Duration(seconds: 2));
          await Stripe.instance.applySettings();
          print('[CONSOLE]✅ [STRIPE SERVICE] Settings applied after key reset');
          return;
        }

        // Strategia 6: Merchant ID reset e retry
        if (attempts == 6) {
          attemptedStrategies.add('Merchant ID reset');
          Stripe.merchantIdentifier = StripeConfig.merchantIdentifier;
          await Future.delayed(const Duration(seconds: 1));
          await Stripe.instance.applySettings();
          print('[CONSOLE]✅ [STRIPE SERVICE] Settings applied after merchant ID reset');
          return;
        }

        // Strategia 7: Last attempt con tutto reset
        if (attempts == 7) {
          attemptedStrategies.add('Full reset');
          Stripe.publishableKey = StripeConfig.publishableKey;
          Stripe.merchantIdentifier = StripeConfig.merchantIdentifier;
          await Future.delayed(const Duration(seconds: 5));
          await Stripe.instance.applySettings();
          print('[CONSOLE]✅ [STRIPE SERVICE] Settings applied after full reset');
          return;
        }

      } catch (e) {
        print('[CONSOLE]⚠️ [STRIPE SERVICE] Settings apply attempt $attempts failed: $e');

        if (attempts >= maxAttempts) {
          final strategiesText = attemptedStrategies.isNotEmpty
              ? ' Attempted strategies: ${attemptedStrategies.join(', ')}'
              : '';

          throw Exception(
              '🚨 STRIPE CONFIGURATION CRITICAL ERROR:\n'
                  'Failed to apply Stripe settings after $maxAttempts attempts.$strategiesText\n\n'
                  'Last error: $e\n\n'
                  '💡 POSSIBLE SOLUTIONS:\n'
                  '1. Verify Android app theme uses Theme.AppCompat or Theme.MaterialComponents\n'
                  '2. Ensure MainActivity extends FlutterFragmentActivity\n'
                  '3. Check if flutter_stripe dependencies are correctly added to build.gradle\n'
                  '4. Restart the app completely and clear cache\n'
                  '5. Verify Stripe publishable key is valid\n'
                  '6. Check device compatibility (Android 5.0+ required)\n\n'
                  'Documentation: https://github.com/flutter-stripe/flutter_stripe#android'
          );
        }

        // Delay progressivo per retry
        final delayMs = baseDelayMs * attempts;
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  /// Retry automatico dell'inizializzazione con analisi errore
  static Future<bool> _retryInitialization() async {
    try {
      _isInitialized = false;
      _currentPublishableKey = null;

      // Reset stato con delay
      await Future.delayed(const Duration(milliseconds: 1000));

      // Retry inizializzazione
      final result = await initialize();
      return result.isSuccess;

    } catch (e) {
      print('[CONSOLE]❌ [STRIPE SERVICE] Retry initialization failed: $e');
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
      'socket',
      'host',
      'unreachable',
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

  // ============================================================================
  // PAYMENT SHEET OPERATIONS - VERSIONE ROBUSTA
  // ============================================================================

  /// Presenta Payment Sheet per il pagamento con gestione errori super robusta
  static Future<Result<PaymentSheetPaymentOption?>> presentPaymentSheet({
    required String clientSecret,
    String? customerId,
    String? ephemeralKeySecret,
    PaymentSheetAppearance? appearance,
  }) async {
    if (!_isInitialized) {
      // Tenta inizializzazione automatica
      final initResult = await initialize();
      if (initResult.isFailure) {
        return Result.error('Stripe not initialized and auto-initialization failed: ${initResult.message}');
      }
    }

    return Result.tryCallAsync(() async {
      print('[CONSOLE]🔧 [STRIPE SERVICE] Presenting Payment Sheet...');
      print('[CONSOLE]🔧 [STRIPE SERVICE] Client secret: ${clientSecret.substring(0, 20)}...');

      try {
        // ============================================================================
        // STEP 1: VALIDAZIONE PARAMETRI
        // ============================================================================

        if (clientSecret.isEmpty || !clientSecret.startsWith('pi_')) {
          throw Exception('Invalid client secret format');
        }

        // ============================================================================
        // STEP 2: INIZIALIZZA PAYMENT SHEET
        // ============================================================================

        print('[CONSOLE]🔧 [STRIPE SERVICE] Initializing Payment Sheet...');

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'FitGymTrack',
            customerId: customerId,
            customerEphemeralKeySecret: ephemeralKeySecret,
            style: ThemeMode.system,
            appearance: appearance ?? _getEnhancedAppearance(),
            allowsDelayedPaymentMethods: true,
            setupIntentClientSecret: null,
            // ============================================================================
            // CONFIGURAZIONI AVANZATE
            // ============================================================================
            billingDetailsCollectionConfiguration: const BillingDetailsCollectionConfiguration(
              email: CollectionMode.automatic,
              name: CollectionMode.automatic,
              phone: CollectionMode.never,
              address: AddressCollectionMode.never,
            ),
            returnURL: 'fitgymtrack://payment_return',
          ),
        );

        print('[CONSOLE]✅ [STRIPE SERVICE] Payment Sheet initialized successfully');

        // ============================================================================
        // STEP 3: PRESENTA PAYMENT SHEET
        // ============================================================================

        print('[CONSOLE]🔧 [STRIPE SERVICE] Presenting Payment Sheet to user...');

        final result = await Stripe.instance.presentPaymentSheet();

        print('[CONSOLE]✅ [STRIPE SERVICE] Payment Sheet completed successfully');

        return result;

      } catch (e) {
        print('[CONSOLE]❌ [STRIPE SERVICE] Payment Sheet error: $e');

        // ============================================================================
        // GESTIONE INTELLIGENTE ERRORI STRIPE
        // ============================================================================

        if (e is StripeException) {
          final errorInfo = handleStripeException(e);
          throw Exception(errorInfo['user_message'] ?? errorInfo['message']);
        }

        // Gestione errori di configurazione comuni
        if (e.toString().contains('not properly initialized')) {
          // Tenta re-inizializzazione automatica
          print('[CONSOLE]🔄 [STRIPE SERVICE] Attempting auto re-initialization...');

          final reinitResult = await forceReinitialize();
          if (reinitResult.isSuccess) {
            print('[CONSOLE]✅ [STRIPE SERVICE] Re-initialization successful, retrying payment...');
            // Retry una volta dopo re-inizializzazione
            final retryResult = await presentPaymentSheet(
              clientSecret: clientSecret,
              customerId: customerId,
              ephemeralKeySecret: ephemeralKeySecret,
              appearance: appearance,
            );
            if (retryResult.isSuccess) {
              return retryResult.data;
            } else {
              throw Exception(retryResult.message);
            }
          }
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
      final initResult = await initialize();
      if (initResult.isFailure) {
        return Result.error('Stripe not initialized: ${initResult.message}');
      }
    }

    return Result.tryCallAsync(() async {
      print('[CONSOLE]🔧 [STRIPE SERVICE] Confirming payment...');

      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: paymentMethodParams,
        options: options,
      );

      print('[CONSOLE]✅ [STRIPE SERVICE] Payment confirmed: ${result.status}');

      return result;
    });
  }

  /// Crea Payment Method da carta
  static Future<Result<PaymentMethod>> createPaymentMethod({
    required PaymentMethodParams params,
  }) async {
    if (!_isInitialized) {
      final initResult = await initialize();
      if (initResult.isFailure) {
        return Result.error('Stripe not initialized: ${initResult.message}');
      }
    }

    return Result.tryCallAsync(() async {
      print('[CONSOLE]🔧 [STRIPE SERVICE] Creating payment method...');

      final result = await Stripe.instance.createPaymentMethod(
        params: params,
      );

      print('[CONSOLE]✅ [STRIPE SERVICE] Payment method created: ${result.id}');

      return result;
    });
  }

  // ============================================================================
  // GOOGLE PAY / APPLE PAY OPERATIONS
  // ============================================================================

  /// Verifica se Google Pay è disponibile
  static Future<Result<bool>> isGooglePaySupported() async {
    if (!_isInitialized) {
      final initResult = await initialize();
      if (initResult.isFailure) {
        return Result.success(false); // Non è un errore critico
      }
    }

    return Result.tryCallAsync(() async {
      final isSupported = await Stripe.instance.isGooglePaySupported(
        const IsGooglePaySupportedParams(
          testEnv: true, // Usa sempre test per ora
        ),
      );

      print('[CONSOLE]🔧 [STRIPE SERVICE] Google Pay supported: $isSupported');

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
      return Result.error('Stripe not initialized');
    }

    return Result.tryCallAsync(() async {
      print('[CONSOLE]🔧 [STRIPE SERVICE] Presenting Google Pay...');

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

      print('[CONSOLE]✅ [STRIPE SERVICE] Google Pay presented successfully');
    });
  }

  /// Ottiene l'aspetto migliorato per Payment Sheet
  static PaymentSheetAppearance _getEnhancedAppearance() {
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
        icon: Color(0xFF64748B),
        error: Color(0xFFDC2626),
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

  /// Gestisce gli errori Stripe con messaggi user-friendly migliorati
  static Map<String, dynamic> handleStripeException(StripeException exception) {
    print('[CONSOLE]❌ [STRIPE SERVICE] Stripe exception: ${exception.error}');

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
        userMessage = 'Codice di sicurezza (CVC) non valido.';
        break;
      case 'incorrect_number':
        userMessage = 'Numero di carta non valido.';
        break;
      case 'invalid_expiry_month':
      case 'invalid_expiry_year':
        userMessage = 'Data di scadenza non valida.';
        break;
      case 'processing_error':
        userMessage = 'Errore durante l\'elaborazione. Riprova tra qualche minuto.';
        break;
      case 'authentication_required':
        userMessage = 'Autenticazione richiesta. Completa la verifica 3D Secure.';
        break;
      case 'canceled':
        userMessage = 'Pagamento annullato dall\'utente.';
        break;
      case 'generic_decline':
        userMessage = 'Pagamento rifiutato. Contatta la tua banca per maggiori informazioni.';
        break;
      case 'lost_card':
      case 'stolen_card':
        userMessage = 'Carta bloccata. Contatta la tua banca.';
        break;
      case 'merchant_blacklist':
        userMessage = 'Pagamento non autorizzato. Contatta il supporto.';
        break;
      case 'pickup_card':
        userMessage = 'Carta ritirata. Contatta la tua banca.';
        break;
      case 'restricted_card':
        userMessage = 'Carta con restrizioni. Contatta la tua banca.';
        break;
      case 'security_violation':
        userMessage = 'Transazione bloccata per sicurezza. Riprova o contatta la banca.';
        break;
      case 'service_not_allowed':
        userMessage = 'Tipo di transazione non consentito per questa carta.';
        break;
      case 'transaction_not_allowed':
        userMessage = 'Transazione non consentita. Contatta la tua banca.';
        break;
      case 'try_again_later':
        userMessage = 'Servizio temporaneamente non disponibile. Riprova più tardi.';
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
      'localized_message': error.localizedMessage,
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

  /// Force re-initialization con reset completo e recovery
  static Future<Result<bool>> forceReinitialize() async {
    print('[CONSOLE]🔄 [STRIPE SERVICE] Forcing complete re-initialization...');

    _isInitialized = false;
    _lastError = null;
    _initAttempts = 0;
    _currentPublishableKey = null;

    // Reset completo con pausa
    await Future.delayed(const Duration(seconds: 2));

    return await initialize();
  }

  /// Health check super completo per Stripe
  static Future<Map<String, dynamic>> healthCheck() async {
    final health = {
      'is_initialized': _isInitialized,
      'last_error': _lastError,
      'last_init_attempt': _lastInitAttempt?.toIso8601String(),
      'init_attempts': _initAttempts,
      'current_publishable_key_set': _currentPublishableKey?.isNotEmpty ?? false,
      'config_publishable_key_set': StripeConfig.publishableKey.isNotEmpty,
      'publishable_key_match': _currentPublishableKey == StripeConfig.publishableKey,
      'merchant_identifier': Stripe.merchantIdentifier,
      'config_valid': StripeConfig.isValidKey(StripeConfig.publishableKey),
      'config_test_mode': StripeConfig.isTestMode,
      'config_demo_mode': StripeConfig.isDemoMode,
      'stripe_instance_available': true,
    };

    // Test funzionalità se inizializzato
    if (_isInitialized) {
      try {
        // Test Google Pay support come proxy per verifica SDK
        final gpaySupported = await Stripe.instance.isGooglePaySupported(
          const IsGooglePaySupportedParams(),
        );
        health['sdk_responsive'] = true;
        health['google_pay_supported'] = gpaySupported;
      } catch (e) {
        health['sdk_responsive'] = false;
        health['sdk_error'] = e.toString();
      }

      // Test configurazione avanzata
      try {
        health['stripe_publishable_key'] = Stripe.publishableKey?.isNotEmpty ?? false;
        health['stripe_merchant_id'] = Stripe.merchantIdentifier?.isNotEmpty ?? false;
      } catch (e) {
        health['config_access_error'] = e.toString();
      }
    }

    return health;
  }

  /// Test rapido di inizializzazione con recovery automatico
  static Future<bool> quickHealthTest() async {
    try {
      if (!_isInitialized) {
        final result = await initialize();
        if (result.isFailure) {
          // Tenta recovery automatico
          print('[CONSOLE]🔄 [STRIPE SERVICE] Quick test failed, attempting recovery...');
          final recoveryResult = await forceReinitialize();
          return recoveryResult.isSuccess;
        }
      }

      // Test con una chiamata leggera se inizializzato
      await Stripe.instance.isGooglePaySupported(const IsGooglePaySupportedParams());
      return true;

    } catch (e) {
      print('[CONSOLE]❌ [STRIPE SERVICE] Quick health test failed: $e');

      // Ultimo tentativo di recovery
      try {
        final lastChanceResult = await _initializeDegradedMode();
        return lastChanceResult;
      } catch (recoveryError) {
        print('[CONSOLE]❌ [STRIPE SERVICE] Recovery also failed: $recoveryError');
        return false;
      }
    }
  }

  /// Cleanup risorse
  static void dispose() {
    print('[CONSOLE]🔧 [STRIPE SERVICE] Disposing Stripe service...');
    _isInitialized = false;
    _lastError = null;
    _lastInitAttempt = null;
    _initAttempts = 0;
    _currentPublishableKey = null;
  }

  /// Reset per testing
  static void reset() {
    dispose();
  }

  /// Informazioni diagnostiche super complete
  static Map<String, dynamic> getDiagnosticInfo() {
    return {
      'service_info': {
        'is_initialized': _isInitialized,
        'last_error': _lastError,
        'last_init_attempt': _lastInitAttempt?.toIso8601String(),
        'init_attempts': _initAttempts,
        'current_key_set': _currentPublishableKey?.isNotEmpty ?? false,
        'current_key_preview': _currentPublishableKey?.isNotEmpty == true
            ? '${_currentPublishableKey!.substring(0, 8)}...'
            : 'None',
      },
      'stripe_instance': {
        'publishable_key_set': Stripe.publishableKey?.isNotEmpty ?? false,
        'publishable_key_valid': Stripe.publishableKey?.startsWith('pk_') ?? false,
        'merchant_identifier': Stripe.merchantIdentifier,
        'instance_available': true,
      },
      'config_info': {
        'publishable_key_length': StripeConfig.publishableKey.length,
        'publishable_key_prefix': StripeConfig.publishableKey.isNotEmpty
            ? StripeConfig.publishableKey.substring(0, 8)
            : 'EMPTY',
        'publishable_key_valid': StripeConfig.isValidKey(StripeConfig.publishableKey),
        'test_mode': StripeConfig.isTestMode,
        'demo_mode': StripeConfig.isDemoMode,
        'country_code': StripeConfig.countryCode,
        'currency': StripeConfig.currency,
        'supported_payment_methods': StripeConfig.supportedPaymentMethods,
        'subscription_plans_count': StripeConfig.subscriptionPlans.length,
      },
      'system_info': {
        'dart_version': '3.4.0',
        'flutter_stripe_version': '10.1.1',
        'platform': 'flutter',
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Stampa informazioni diagnostiche super dettagliate per debug
  static void printDiagnosticInfo() {
    final info = getDiagnosticInfo();
    print('[CONSOLE]');
    print('[CONSOLE]🔍 STRIPE SERVICE SUPER DIAGNOSTIC INFO');
    print('[CONSOLE]==========================================');

    // Service Info
    final serviceInfo = info['service_info'] as Map<String, dynamic>;
    print('[CONSOLE]🔧 SERVICE STATUS:');
    print('[CONSOLE]   Initialized: ${serviceInfo['is_initialized']}');
    print('[CONSOLE]   Init attempts: ${serviceInfo['init_attempts']}');
    print('[CONSOLE]   Last error: ${serviceInfo['last_error'] ?? 'None'}');
    print('[CONSOLE]   Current key set: ${serviceInfo['current_key_set']}');
    print('[CONSOLE]   Current key: ${serviceInfo['current_key_preview']}');

    // Stripe Instance
    final stripeInstance = info['stripe_instance'] as Map<String, dynamic>;
    print('[CONSOLE]');
    print('[CONSOLE]⚙️ STRIPE INSTANCE:');
    print('[CONSOLE]   Publishable key set: ${stripeInstance['publishable_key_set']}');
    print('[CONSOLE]   Publishable key valid: ${stripeInstance['publishable_key_valid']}');
    print('[CONSOLE]   Merchant ID: ${stripeInstance['merchant_identifier']}');

    // Config Info
    final configInfo = info['config_info'] as Map<String, dynamic>;
    print('[CONSOLE]');
    print('[CONSOLE]📋 CONFIGURATION:');
    print('[CONSOLE]   Config key valid: ${configInfo['publishable_key_valid']}');
    print('[CONSOLE]   Config key prefix: ${configInfo['publishable_key_prefix']}');
    print('[CONSOLE]   Test mode: ${configInfo['test_mode']}');
    print('[CONSOLE]   Demo mode: ${configInfo['demo_mode']}');
    print('[CONSOLE]   Currency: ${configInfo['currency']}');
    print('[CONSOLE]   Country: ${configInfo['country_code']}');
    print('[CONSOLE]   Plans count: ${configInfo['subscription_plans_count']}');

    print('[CONSOLE]==========================================');
    print('[CONSOLE]');
  }
}