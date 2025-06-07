// lib/features/payments/services/stripe_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:developer' as developer;
import '../../../core/config/stripe_config.dart';
import '../models/stripe_models.dart';
import '../../../core/utils/result.dart';

/// Servizio per gestire le operazioni Stripe nel client - VERSIONE ENHANCED
class StripeService {
  static bool _isInitialized = false;
  static String? _lastError;
  static DateTime? _lastInitAttempt;

  /// Inizializza Stripe SDK con retry automatico
  static Future<Result<bool>> initialize() async {
    if (_isInitialized) {
      developer.log('✅ [STRIPE] Already initialized', name: 'StripeService');
      return Result.success(true);
    }

    _lastInitAttempt = DateTime.now();

    return Result.tryCallAsync(() async {
      developer.log('🔧 [STRIPE] Initializing Stripe SDK...', name: 'StripeService');

      // Verifica prerequisiti
      if (StripeConfig.publishableKey.isEmpty) {
        throw Exception('Publishable key Stripe vuota');
      }

      if (!StripeConfig.publishableKey.startsWith('pk_')) {
        throw Exception('Publishable key formato non valido');
      }

      try {
        // Configura Stripe
        Stripe.publishableKey = StripeConfig.publishableKey;
        Stripe.merchantIdentifier = StripeConfig.merchantIdentifier;

        developer.log('🔧 [STRIPE] Publishable key set: ${StripeConfig.publishableKey.substring(0, 20)}...', name: 'StripeService');
        developer.log('🔧 [STRIPE] Merchant identifier: ${StripeConfig.merchantIdentifier}', name: 'StripeService');

        // Configura opzioni aggiuntive con retry
        await _applySettingsWithRetry();

        _isInitialized = true;
        _lastError = null;

        developer.log('✅ [STRIPE] Stripe SDK initialized successfully', name: 'StripeService');
        StripeConfig.printConfiguration();

        return true;

      } catch (e) {
        _lastError = e.toString();
        developer.log('❌ [STRIPE] Initialization failed: $e', name: 'StripeService');

        // 🔧 Reset e retry automatico se l'errore è temporaneo
        if (_shouldRetryInit(e.toString())) {
          developer.log('🔄 [STRIPE] Attempting automatic retry...', name: 'StripeService');
          await Future.delayed(const Duration(seconds: 1));
          return await _retryInitialization();
        }

        rethrow;
      }
    });
  }

  /// Applica le impostazioni Stripe con retry
  static Future<void> _applySettingsWithRetry() async {
    int attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        await Stripe.instance.applySettings();
        developer.log('✅ [STRIPE] Settings applied successfully', name: 'StripeService');
        return;
      } catch (e) {
        attempts++;
        developer.log('⚠️ [STRIPE] Settings apply attempt $attempts failed: $e', name: 'StripeService');

        if (attempts >= maxAttempts) {
          throw Exception('Failed to apply Stripe settings after $maxAttempts attempts: $e');
        }

        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
  }

  /// Retry automatico dell'inizializzazione
  static Future<bool> _retryInitialization() async {
    try {
      _isInitialized = false;

      // Reset stato Stripe
      await Future.delayed(const Duration(milliseconds: 500));

      // Retry inizializzazione
      final result = await initialize();
      return result.isSuccess;

    } catch (e) {
      developer.log('❌ [STRIPE] Retry initialization failed: $e', name: 'StripeService');
      return false;
    }
  }

  /// Determina se dovremmo fare retry dell'inizializzazione
  static bool _shouldRetryInit(String error) {
    const retryableErrors = [
      'network',
      'timeout',
      'connection',
      'temporary',
    ];

    final errorLower = error.toLowerCase();
    return retryableErrors.any((retryable) => errorLower.contains(retryable));
  }

  /// Verifica se Stripe è inizializzato
  static bool get isInitialized => _isInitialized;

  /// Ultimo errore di inizializzazione
  static String? get lastError => _lastError;

  /// Presenta Payment Sheet per il pagamento
  static Future<Result<PaymentSheetPaymentOption?>> presentPaymentSheet({
    required String clientSecret,
    String? customerId,
    String? ephemeralKeySecret,
    PaymentSheetAppearance? appearance,
  }) async {
    if (!_isInitialized) {
      return Result.error('Stripe non è stato inizializzato');
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

        developer.log('✅ [STRIPE] Payment Sheet presented successfully', name: 'StripeService');

        return result;

      } catch (e) {
        developer.log('❌ [STRIPE] Payment Sheet error: $e', name: 'StripeService');

        // Gestisci errori specifici di Payment Sheet
        if (e is StripeException) {
          final errorInfo = handleStripeException(e);
          throw Exception('Payment Sheet failed: ${errorInfo['message']}');
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

  /// Gestisce gli errori Stripe
  static Map<String, dynamic> handleStripeException(StripeException exception) {
    developer.log('❌ [STRIPE] Stripe exception: ${exception.error}', name: 'StripeService');

    final error = exception.error;
    return {
      'code': error.code ?? 'unknown_error',
      'message': error.message ?? 'Errore sconosciuto',
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

  /// Force re-initialization
  static Future<Result<bool>> forceReinitialize() async {
    developer.log('🔄 [STRIPE] Forcing re-initialization...', name: 'StripeService');

    _isInitialized = false;
    _lastError = null;

    return await initialize();
  }

  /// Health check per Stripe
  static Future<Map<String, dynamic>> healthCheck() async {
    final health = {
      'is_initialized': _isInitialized,
      'last_error': _lastError,
      'last_init_attempt': _lastInitAttempt?.toIso8601String(),
      'publishable_key_set': Stripe.publishableKey?.isNotEmpty ?? false,
      'merchant_identifier': Stripe.merchantIdentifier,
      'config_valid': StripeConfig.isValidKey(StripeConfig.publishableKey),
    };

    // Test rapido se inizializzato
    if (_isInitialized) {
      try {
        // Semplice test per vedere se Stripe risponde
        await Stripe.instance.isGooglePaySupported(const IsGooglePaySupportedParams());
        health['sdk_responsive'] = true;
      } catch (e) {
        health['sdk_responsive'] = false;
        health['sdk_error'] = e.toString();
      }
    }

    return health;
  }

  /// Cleanup risorse
  static void dispose() {
    developer.log('🔧 [STRIPE] Disposing Stripe service...', name: 'StripeService');
    _isInitialized = false;
    _lastError = null;
    _lastInitAttempt = null;
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
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}