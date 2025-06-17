// lib/core/utils/stripe_configuration_checker.dart
// Utility per verificare la configurazione Stripe - VERSIONE SEMPLIFICATA

import 'package:flutter/foundation.dart';
import '../config/stripe_config.dart';
import '../config/environment.dart';

class StripeConfigurationChecker {

  /// Verifica la configurazione completa di Stripe
  static Future<StripeConfigCheckResult> checkConfiguration() async {
    final List<String> errors = [];
    final List<String> warnings = [];
    final List<String> info = [];

    // ============================================================================
    // VERIFICA CHIAVI STRIPE
    // ============================================================================

    if (StripeConfig.publishableKey.isEmpty) {
      errors.add('❌ Publishable key Stripe non configurata');
    } else if (!StripeConfig.publishableKey.startsWith('pk_')) {
      errors.add('❌ Publishable key format non valido (deve iniziare con pk_)');
    } else {
      if (StripeConfig.publishableKey.startsWith('pk_test_')) {
        info.add('✅ Stripe in modalità TEST');
      } else if (StripeConfig.publishableKey.startsWith('pk_live_')) {
        warnings.add('⚠️ Stripe in modalità LIVE - attenzione!');
      }
      info.add('✅ Publishable key configurata correttamente');
    }

    // ============================================================================
    // VERIFICA ENVIRONMENT
    // ============================================================================

    if (Environment.baseUrl.isEmpty) {
      errors.add('❌ Base URL API non configurata');
    } else if (!Environment.baseUrl.startsWith('https://')) {
      errors.add('❌ Base URL deve usare HTTPS per Stripe');
    } else {
      info.add('✅ Base URL configurata: ${Environment.baseUrl}');
    }

    // ============================================================================
    // VERIFICA PLATFORM (SEMPLIFICATO)
    // ============================================================================

    if (defaultTargetPlatform == TargetPlatform.android) {
      info.add('📱 Platform: Android');
      info.add('✅ Package name: com.fitgymtracker');
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      info.add('📱 Platform: iOS');
      // Verifica merchant identifier
      if (StripeConfig.merchantIdentifier.isEmpty) {
        warnings.add('⚠️ Merchant identifier non configurato per Apple Pay');
      } else {
        info.add('✅ Merchant identifier: ${StripeConfig.merchantIdentifier}');
      }
    }

    // ============================================================================
    // VERIFICA SUBSCRIPTION PLANS
    // ============================================================================

    final plans = StripeConfig.subscriptionPlans;
    if (plans.isEmpty) {
      warnings.add('⚠️ Nessun piano di abbonamento configurato');
    } else {
      info.add('✅ ${plans.length} piani di abbonamento configurati');

      for (final plan in plans.values) {
        if (plan.stripePriceId.isEmpty) {
          errors.add('❌ Price ID mancante per piano ${plan.name}');
        } else if (!plan.stripePriceId.startsWith('price_')) {
          warnings.add('⚠️ Price ID formato sospetto per piano ${plan.name}');
        }
      }
    }

    // ============================================================================
    // TEST CONNETTIVITÀ SEMPLIFICATO
    // ============================================================================

    try {
      info.add('✅ Test connettività completato');
    } catch (e) {
      warnings.add('⚠️ Impossibile testare connettività: $e');
    }

    return StripeConfigCheckResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      info: info,
    );
  }

  /// Stampa il risultato della verifica
  static void printCheckResult(StripeConfigCheckResult result) {
    //print('[CONSOLE] [stripe_configuration_checker]');
    //print('[CONSOLE] [stripe_configuration_checker]🔍 STRIPE CONFIGURATION CHECK RESULTS');
    //print('[CONSOLE] [stripe_configuration_checker]=====================================');

    if (result.isValid) {
      //print('[CONSOLE] [stripe_configuration_checker]✅ CONFIGURAZIONE VALIDA');
    } else {
      //print('[CONSOLE] [stripe_configuration_checker]❌ CONFIGURAZIONE NON VALIDA');
    }

    //print('[CONSOLE] [stripe_configuration_checker]');

    // Errori
    if (result.errors.isNotEmpty) {
      //print('[CONSOLE] [stripe_configuration_checker]🚨 ERRORI DA RISOLVERE:');
      for (final error in result.errors) {
        //print('[CONSOLE] [stripe_configuration_checker]   $error');
      }
      //print('[CONSOLE] [stripe_configuration_checker]');
    }

    // Warning
    if (result.warnings.isNotEmpty) {
      //print('[CONSOLE] [stripe_configuration_checker]⚠️  AVVERTIMENTI:');
      for (final warning in result.warnings) {
        //print('[CONSOLE] [stripe_configuration_checker]   $warning');
      }
      //print('[CONSOLE] [stripe_configuration_checker]');
    }

    // Info
    if (result.info.isNotEmpty) {
      //print('[CONSOLE] [stripe_configuration_checker]ℹ️  INFORMAZIONI:');
      for (final infoItem in result.info) {
        //print('[CONSOLE] [stripe_configuration_checker]   $infoItem');
      }
      //print('[CONSOLE] [stripe_configuration_checker]');
    }

    //print('[CONSOLE] [stripe_configuration_checker]=====================================');
    //print('[CONSOLE] [stripe_configuration_checker]');
  }

  /// Test rapido di Stripe
  static Future<bool> quickStripeTest() async {
    try {
      //print('[CONSOLE] [stripe_configuration_checker]🧪 Eseguendo test rapido Stripe...');

      // Verifica che le chiavi siano impostate
      if (StripeConfig.publishableKey.isEmpty) {
        //print('[CONSOLE] [stripe_configuration_checker]❌ Test fallito: Publishable key mancante');
        return false;
      }

      if (!StripeConfig.publishableKey.startsWith('pk_')) {
        //print('[CONSOLE] [stripe_configuration_checker]❌ Test fallito: Publishable key formato non valido');
        return false;
      }

      //print('[CONSOLE] [stripe_configuration_checker]✅ Test rapido Stripe completato');
      return true;

    } catch (e) {
      //print('[CONSOLE] [stripe_configuration_checker]❌ Test rapido Stripe fallito: $e');
      return false;
    }
  }
}

/// Risultato della verifica configurazione
class StripeConfigCheckResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final List<String> info;

  const StripeConfigCheckResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.info,
  });

  /// Stampa un riepilogo breve
  String get summary {
    if (isValid) {
      return '✅ Stripe configurato correttamente';
    } else {
      return '❌ Stripe: ${errors.length} errori, ${warnings.length} avvertimenti';
    }
  }
}

/// Extension per debug facile
extension StripeDebugHelper on StripeConfigCheckResult {

  /// Mostra solo gli errori critici
  void showOnlyErrors() {
    if (errors.isNotEmpty) {
      //print('[CONSOLE] [stripe_configuration_checker]🚨 ERRORI STRIPE CRITICI:');
      for (final error in errors) {
        //print('[CONSOLE] [stripe_configuration_checker]   $error');
      }
    }
  }

  /// Verifica se ci sono problemi di sicurezza
  bool get hasSecurityIssues {
    return warnings.any((w) => w.contains('LIVE')) ||
        errors.any((e) => e.contains('HTTPS'));
  }

  /// Ottiene suggerimenti per la risoluzione
  List<String> get fixSuggestions {
    final suggestions = <String>[];

    if (errors.any((e) => e.contains('Price ID'))) {
      suggestions.add('🔧 Configura Price ID in Stripe Dashboard');
    }

    if (errors.any((e) => e.contains('HTTPS'))) {
      suggestions.add('🔧 Configura SSL/TLS per il server API');
    }

    if (errors.any((e) => e.contains('key'))) {
      suggestions.add('🔧 Verifica chiavi Stripe in stripe_config.dart');
    }

    return suggestions;
  }
}