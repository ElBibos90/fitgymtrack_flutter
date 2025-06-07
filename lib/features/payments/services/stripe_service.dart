// lib/features/payments/services/stripe_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:developer' as developer;
import '../../../core/config/stripe_config.dart';
import '../models/stripe_models.dart';
import '../../../core/utils/result.dart';

/// Servizio per gestire le operazioni Stripe nel client
class StripeService {
  static bool _isInitialized = false;

  /// Inizializza Stripe SDK
  static Future<Result<bool>> initialize() async {
    if (_isInitialized) {
      return Result.success(true);
    }

    return Result.tryCallAsync(() async {
      developer.log('🔧 [STRIPE] Initializing Stripe SDK...', name: 'StripeService');

      // Configura Stripe
      Stripe.publishableKey = StripeConfig.publishableKey;
      Stripe.merchantIdentifier = StripeConfig.merchantIdentifier;

      // Configura opzioni aggiuntive
      await Stripe.instance.applySettings();

      _isInitialized = true;

      developer.log('✅ [STRIPE] Stripe SDK initialized successfully', name: 'StripeService');
      StripeConfig.printConfiguration();

      return true;
    });
  }

  /// Verifica se Stripe è inizializzato
  static bool get isInitialized => _isInitialized;

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

      // Presenta Payment Sheet
      final result = await Stripe.instance.presentPaymentSheet();

      developer.log('✅ [STRIPE] Payment Sheet presented successfully', name: 'StripeService');

      return result;
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
      'payment_intent_id': null, // Non sempre disponibile
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

  /// Cleanup risorse
  static void dispose() {
    developer.log('🔧 [STRIPE] Disposing Stripe service...', name: 'StripeService');
    _isInitialized = false;
  }

  /// Reset per testing
  static void reset() {
    dispose();
  }

  /// Informazioni diagnostiche
  static Map<String, dynamic> getDiagnosticInfo() {
    return {
      'is_initialized': _isInitialized,
      'publishable_key_set': Stripe.publishableKey?.isNotEmpty ?? false,
      'merchant_identifier': Stripe.merchantIdentifier,
      'test_mode': StripeConfig.isTestMode,
      'country_code': StripeConfig.countryCode,
      'currency': StripeConfig.currency,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}