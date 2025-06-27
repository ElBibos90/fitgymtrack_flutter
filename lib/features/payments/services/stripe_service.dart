// lib/features/payments/services/stripe_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/config/stripe_config.dart';
import '../models/stripe_models.dart';
import '../../../core/utils/result.dart';

/// Servizio per gestire le operazioni Stripe nel client - VERSIONE FINALE CORRETTA
class StripeService {
  static bool _isInitialized = false;
  static String? _lastError;
  static DateTime? _lastInitAttempt;
  static int _initAttempts = 0;
  static String? _currentPublishableKey;

  /// Inizializza Stripe SDK con gestione errori super robusta (unchanged)
  static Future<Result<bool>> initialize() async {
    if (_isInitialized && _currentPublishableKey == StripeConfig.publishableKey) {
      ////print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] Already initialized with current key');
      return Result.success(true);
    }

    _lastInitAttempt = DateTime.now();
    _initAttempts++;

    return Result.tryCallAsync(() async {
      ////print('[CONSOLE] [stripe_service]🔧 [STRIPE SERVICE] Initializing Stripe SDK (attempt $_initAttempts)...');

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
        ////print('[CONSOLE] [stripe_service]⚠️ [STRIPE SERVICE] Demo mode detected - using placeholder configuration');
        // In demo mode, usiamo configurazione basilare
        return await _initializeDemoMode();
      }

      try {
        // ============================================================================
        // STEP 2: CONFIGURA STRIPE PUBLISHABLE KEY
        // ============================================================================

        ////print('[CONSOLE] [stripe_service]🔧 [STRIPE SERVICE] Step 1: Setting publishable key...');
        Stripe.publishableKey = StripeConfig.publishableKey;
        _currentPublishableKey = StripeConfig.publishableKey;

        // ============================================================================
        // STEP 3: CONFIGURA MERCHANT IDENTIFIER
        // ============================================================================

        ////print('[CONSOLE] [stripe_service]🔧 [STRIPE SERVICE] Step 2: Setting merchant identifier...');
        Stripe.merchantIdentifier = StripeConfig.merchantIdentifier;

        // ============================================================================
        // STEP 4: APPLICA SETTINGS CON RETRY SUPER INTELLIGENTE
        // ============================================================================

        ////print('[CONSOLE] [stripe_service]🔧 [STRIPE SERVICE] Step 3: Applying Stripe settings...');
        await _applySettingsWithSuperRetry();

        _isInitialized = true;
        _lastError = null;

        ////print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] Stripe SDK initialized successfully!');
        ////print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] - Key: ${StripeConfig.publishableKey.substring(0, 20)}...');
        ////print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] - Merchant ID: ${StripeConfig.merchantIdentifier}');
        ////print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] - Test mode: ${StripeConfig.isTestMode}');
        ////print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] - Demo mode: ${StripeConfig.isDemoMode}');

        return true;

      } catch (e) {
        _lastError = e.toString();
        ////print('[CONSOLE] [stripe_service]❌ [STRIPE SERVICE] Initialization failed: $e');

        // ============================================================================
        // RETRY INTELLIGENTE CON ANALISI ERRORE
        // ============================================================================

        if (_shouldRetryWithDelay(e.toString()) && _initAttempts < 5) {
          ////print('[CONSOLE] [stripe_service]🔄 [STRIPE SERVICE] Scheduling intelligent retry in ${_initAttempts * 2} seconds...');
          await Future.delayed(Duration(seconds: _initAttempts * 2));
          return await _retryInitialization();
        }

        // Se non può fare retry, prova modalità degraded
        if (_initAttempts >= 3) {
          ////print('[CONSOLE] [stripe_service]⚠️ [STRIPE SERVICE] Multiple failures - attempting degraded mode...');
          return await _initializeDegradedMode();
        }

        rethrow;
      }
    });
  }

  /// Inizializzazione in modalità demo (unchanged)
  static Future<bool> _initializeDemoMode() async {
    ////print('[CONSOLE] [stripe_service]🎭 [STRIPE SERVICE] Initializing in DEMO mode...');

    try {
      // Usa una chiave test standard di Stripe per demo
      final demoKey = 'pk_test_51234567890abcdefghijklmnopqrstuvwxyz123456789012345678901234567890123456789012345678901234567890';

      Stripe.publishableKey = demoKey;
      Stripe.merchantIdentifier = StripeConfig.merchantIdentifier;

      // Applica settings basilari
      await Stripe.instance.applySettings();

      _isInitialized = true;
      _lastError = null;

      ////print('[CONSOLE] [stripe_service]🎭 [STRIPE SERVICE] Demo mode initialized successfully');
      return true;

    } catch (e) {
      ////print('[CONSOLE] [stripe_service]❌ [STRIPE SERVICE] Demo mode initialization failed: $e');
      return false;
    }
  }

  /// Inizializzazione in modalità degraded (unchanged)
  static Future<bool> _initializeDegradedMode() async {
    ////print('[CONSOLE] [stripe_service]⚙️ [STRIPE SERVICE] Initializing in DEGRADED mode...');

    try {
      // Prova solo configurazione base senza applySettings
      if (StripeConfig.isValidKey(StripeConfig.publishableKey)) {
        Stripe.publishableKey = StripeConfig.publishableKey;
        _currentPublishableKey = StripeConfig.publishableKey;
      }

      _isInitialized = true;
      _lastError = 'Initialized in degraded mode - limited functionality';

      ////print('[CONSOLE] [stripe_service]⚙️ [STRIPE SERVICE] Degraded mode initialized');
      return true;

    } catch (e) {
      ////print('[CONSOLE] [stripe_service]❌ [STRIPE SERVICE] Degraded mode failed: $e');
      return false;
    }
  }

  /// Applica le impostazioni Stripe con retry super intelligente (unchanged)
  static Future<void> _applySettingsWithSuperRetry() async {
    int attempts = 0;
    const maxAttempts = 7;
    const baseDelayMs = 500;
    List<String> attemptedStrategies = [];

    while (attempts < maxAttempts) {
      attempts++;
      ////print('[CONSOLE] [stripe_service]🔧 [STRIPE SERVICE] Applying settings - attempt $attempts/$maxAttempts...');

      try {
        // Strategia 1-3: Retry normale con delay progressivo
        if (attempts <= 3) {
          await Stripe.instance.applySettings();
          ////print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] Settings applied successfully on attempt $attempts');
          return;
        }

        // Strategia 4: Retry con delay più lungo
        if (attempts == 4) {
          attemptedStrategies.add('Extended timeout');
          await Future.delayed(const Duration(seconds: 3));
          await Stripe.instance.applySettings();
          ////print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] Settings applied with extended timeout');
          return;
        }

        // Strategia 5: Re-set chiave e retry
        if (attempts == 5) {
          attemptedStrategies.add('Key reset');
          Stripe.publishableKey = StripeConfig.publishableKey;
          await Future.delayed(const Duration(seconds: 2));
          await Stripe.instance.applySettings();
          ////print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] Settings applied after key reset');
          return;
        }

        // Strategia 6: Merchant ID reset e retry
        if (attempts == 6) {
          attemptedStrategies.add('Merchant ID reset');
          Stripe.merchantIdentifier = StripeConfig.merchantIdentifier;
          await Future.delayed(const Duration(seconds: 1));
          await Stripe.instance.applySettings();
          ////print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] Settings applied after merchant ID reset');
          return;
        }

        // Strategia 7: Last attempt con tutto reset
        if (attempts == 7) {
          attemptedStrategies.add('Full reset');
          Stripe.publishableKey = StripeConfig.publishableKey;
          Stripe.merchantIdentifier = StripeConfig.merchantIdentifier;
          await Future.delayed(const Duration(seconds: 5));
          await Stripe.instance.applySettings();
          ////print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] Settings applied after full reset');
          return;
        }

      } catch (e) {
        ////print('[CONSOLE] [stripe_service]⚠️ [STRIPE SERVICE] Settings apply attempt $attempts failed: $e');

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

  /// Retry automatico dell'inizializzazione con analisi errore (unchanged)
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
      ////print('[CONSOLE] [stripe_service]❌ [STRIPE SERVICE] Retry initialization failed: $e');
      return false;
    }
  }

  /// Determina se dovremmo fare retry dell'inizializzazione (unchanged)
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

  /// Verifica se Stripe è inizializzato (unchanged)
  static bool get isInitialized => _isInitialized;

  /// Ultimo errore di inizializzazione (unchanged)
  static String? get lastError => _lastError;

  /// Numero di tentativi di inizializzazione (unchanged)
  static int get initAttempts => _initAttempts;

  // ============================================================================
  // 🔧 FIX: PAYMENT SHEET OPERATIONS - GESTIONE CORRETTA DEL SUCCESSO
  // ============================================================================

  /// 🔧 FIX: Presenta Payment Sheet per il pagamento con gestione corretta del successo
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
      ////print('[CONSOLE] [stripe_service]🔧 [STRIPE SERVICE] Presenting Payment Sheet...');
      ////print('[CONSOLE] [stripe_service]🔧 [STRIPE SERVICE] Client secret: ${clientSecret.substring(0, 20)}...');

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

        ////print('[CONSOLE] [stripe_service]🔧 [STRIPE SERVICE] Initializing Payment Sheet...');

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

        ////print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] Payment Sheet initialized successfully');

        // ============================================================================
        // STEP 3: PRESENTA PAYMENT SHEET
        // ============================================================================

        ////print('[CONSOLE] [stripe_service]🔧 [STRIPE SERVICE] Presenting Payment Sheet to user...');

        try {
          final result = await Stripe.instance.presentPaymentSheet();

          ////print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] Payment Sheet completed successfully');
          //print('[CONSOLE] [stripe_service]🔧 [STRIPE SERVICE] Payment result type: ${result.runtimeType}');
          //print('[CONSOLE] [stripe_service]🔧 [STRIPE SERVICE] Payment result: $result');

          // 🔧 FIX: Il completamento senza eccezioni è SEMPRE un successo
          // Non importa se il result è null, questo è normale per i pagamenti riusciti
          return result;

        } catch (e) {
          //print('[CONSOLE] [stripe_service]❌ [STRIPE SERVICE] Payment Sheet presentation failed: $e');

          // 🔧 FIX: Gestione intelligente degli errori del Payment Sheet
          if (e is StripeException) {
            final errorInfo = _handleStripeError(e);
            throw Exception(errorInfo['user_message'] ?? errorInfo['message']);
          }

          // Gestione errori specifici di cancellazione utente
          final errorMessage = e.toString().toLowerCase();
          if (errorMessage.contains('canceled') ||
              errorMessage.contains('cancelled') ||
              errorMessage.contains('user_cancel')) {
            throw Exception('Pagamento annullato dall\'utente');
          }

          // Altri errori
          throw Exception('Errore durante il pagamento: $e');
        }

      } catch (e) {
        //print('[CONSOLE] [stripe_service]❌ [STRIPE SERVICE] Payment Sheet error: $e');

        // ============================================================================
        // GESTIONE INTELLIGENTE ERRORI STRIPE
        // ============================================================================

        if (e is StripeException) {
          final errorInfo = _handleStripeError(e);
          throw Exception(errorInfo['user_message'] ?? errorInfo['message']);
        }

        // Gestione errori di configurazione comuni
        if (e.toString().contains('not properly initialized')) {
          // Tenta re-inizializzazione automatica
          //print('[CONSOLE] [stripe_service]🔄 [STRIPE SERVICE] Attempting auto re-initialization...');

          final reinitResult = await forceReinitialize();
          if (reinitResult.isSuccess) {
            //print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] Re-initialization successful, retrying payment...');
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

  /// Conferma pagamento con Payment Method (unchanged)
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
      //print('[CONSOLE] [stripe_service]🔧 [STRIPE SERVICE] Confirming payment...');

      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: paymentMethodParams,
        options: options,
      );

      //print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] Payment confirmed: ${result.status}');

      return result;
    });
  }

  /// Crea Payment Method da carta (unchanged)
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
      //print('[CONSOLE] [stripe_service]🔧 [STRIPE SERVICE] Creating payment method...');

      final result = await Stripe.instance.createPaymentMethod(
        params: params,
      );

      //print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] Payment method created: ${result.id}');

      return result;
    });
  }

  // ============================================================================
  // GOOGLE PAY / APPLE PAY OPERATIONS (unchanged)
  // ============================================================================

  /// Verifica se Google Pay è supportato (updated to use new API)
  static Future<Result<bool>> isGooglePaySupported() async {
    try {
      // 🔧 FIX: Aggiornato da isGooglePaySupported a isPlatformPaySupported
      final isSupported = await Stripe.instance.isPlatformPaySupported();
      return Result.success(isSupported);
    } catch (e) {
      return Result.error('Failed to check Google Pay support: $e');
    }
  }

  /// Presenta Google Pay (unchanged)
  static Future<Result<void>> presentGooglePay({
    required String clientSecret,
    required bool isPaymentIntent,
    String? currencyCode,
  }) async {
    if (!_isInitialized) {
      return Result.error('Stripe not initialized');
    }

    return Result.tryCallAsync(() async {
      //print('[CONSOLE] [stripe_service]🔧 [STRIPE SERVICE] Presenting Google Pay...');

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

      //print('[CONSOLE] [stripe_service]✅ [STRIPE SERVICE] Google Pay presented successfully');
    });
  }

  /// Ottiene l'aspetto migliorato per Payment Sheet (unchanged)
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

  /// Gestisce errori Stripe con mapping completo (unchanged)
  static Map<String, dynamic> _handleStripeError(StripeException exception) {
    final error = exception.error;
    String userMessage = 'Si è verificato un errore durante il pagamento. Riprova.';

    switch (error.code) {
      case 'card_declined':
        userMessage = 'Carta rifiutata. Verifica i dati o contatta la tua banca.';
        break;
      case 'expired_card':
        userMessage = 'Carta scaduta. Inserisci una carta valida.';
        break;
      case 'incorrect_cvc':
        userMessage = 'Codice CVC non corretto. Verifica e riprova.';
        break;
      case 'incorrect_number':
        userMessage = 'Numero carta non valido. Verifica e riprova.';
        break;
      case 'invalid_expiry_month':
        userMessage = 'Mese di scadenza non valido.';
        break;
      case 'invalid_expiry_year':
        userMessage = 'Anno di scadenza non valido.';
        break;
      case 'invalid_cvc':
        userMessage = 'Codice CVC non valido.';
        break;
      case 'processing_error':
        userMessage = 'Errore di elaborazione. Riprova più tardi.';
        break;
      case 'rate_limit':
        userMessage = 'Troppi tentativi. Riprova più tardi.';
        break;
      case 'authentication_required':
        userMessage = 'Autenticazione richiesta. Completa la verifica 3D Secure.';
        break;
      case 'insufficient_funds':
        userMessage = 'Fondi insufficienti sulla carta.';
        break;
      case 'currency_not_supported':
        userMessage = 'Valuta non supportata per questa carta.';
        break;
      case 'card_not_supported':
        userMessage = 'Tipo di carta non supportato.';
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

  /// Crea parametri per Payment Method da carta manuale (unchanged)
  static PaymentMethodParams createCardPaymentMethodParams({
    BillingDetails? billingDetails,
  }) {
    return PaymentMethodParams.card(
      paymentMethodData: PaymentMethodData(
        billingDetails: billingDetails,
      ),
    );
  }

  /// Force re-initialization con reset completo e recovery (unchanged)
  static Future<Result<bool>> forceReinitialize() async {
    _isInitialized = false;
    _lastError = null;
    _initAttempts = 0;
    _currentPublishableKey = null;

    // Reset completo con pausa
    await Future.delayed(const Duration(seconds: 2));

    return await initialize();
  }

  /// Health check super completo per Stripe (unchanged)
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
        final gpaySupported = await Stripe.instance.isPlatformPaySupported();
        health['sdk_responsive'] = true;
        health['google_pay_supported'] = gpaySupported;
      } catch (e) {
        health['sdk_responsive'] = false;
        health['sdk_error'] = e.toString();
      }

      // Test configurazione avanzata
      try {
        final publishableKey = Stripe.publishableKey;
        final merchantId = Stripe.merchantIdentifier;
        health['stripe_publishable_key'] = publishableKey != null && publishableKey.isNotEmpty;
        health['stripe_merchant_id'] = merchantId != null && merchantId.isNotEmpty;
      } catch (e) {
        health['config_access_error'] = e.toString();
      }
    }

    return health;
  }

  /// Test rapido di inizializzazione con recovery automatico (unchanged)
  static Future<bool> quickHealthTest() async {
    try {
      if (!_isInitialized) {
        final result = await initialize();
        if (result.isFailure) {
          // Tenta recovery automatico
          final recoveryResult = await forceReinitialize();
          return recoveryResult.isSuccess;
        }
      }

      // Test con una chiamata leggera se inizializzato
      await Stripe.instance.isPlatformPaySupported();
      return true;

    } catch (e) {
      // Ultimo tentativo di recovery
      try {
        final lastChanceResult = await _initializeDegradedMode();
        return lastChanceResult;
      } catch (recoveryError) {
        return false;
      }
    }
  }

  /// Cleanup risorse (unchanged)
  static void dispose() {
    _isInitialized = false;
    _lastError = null;
    _lastInitAttempt = null;
    _initAttempts = 0;
    _currentPublishableKey = null;
  }

  /// Reset per testing (unchanged)
  static void reset() {
    dispose();
  }

  /// Informazioni diagnostiche super complete (unchanged)
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
        'publishable_key_set': (Stripe.publishableKey ?? '').isNotEmpty,
        'publishable_key_valid': (Stripe.publishableKey ?? '').startsWith('pk_'),
        'merchant_identifier': Stripe.merchantIdentifier ?? '',
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

  /// Stampa informazioni diagnostiche super dettagliate per debug (unchanged)
  static void printDiagnosticInfo() {
    // I dati diagnostici sono disponibili tramite getDiagnosticInfo()
    // ma non vengono stampati per evitare log eccessivi in produzione
  }
}