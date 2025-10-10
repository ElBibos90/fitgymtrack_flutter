// lib/core/config/environment.dart
import 'package:flutter/foundation.dart'; // Per kDebugMode

class Environment {
  // ============================================================================
  // API CONFIGURATION - AUTO-SWITCH DEBUG/RELEASE
  // ============================================================================

  /// Base URL per API - CAMBIA AUTOMATICAMENTE:
  /// - Debug/Simulatore → http://192.168.1.113/api/ (DEV)
  /// - Release/Produzione → https://fitgymtrack.com/api/ (PROD)
  static String get baseUrl {
    if (kDebugMode) {
      // 🟡 Modalità DEBUG - Usa server locale DEV
      return 'http://192.168.1.113/api/';
    } else {
      // 🟢 Modalità RELEASE - Usa server produzione
      return 'https://fitgymtrack.com/api/';
    }
  }

  // ============================================================================
  // APP CONFIGURATION
  // ============================================================================

  static const String appName = 'FitGymTrack Flutter';
  static const String version = '1.0.0';

  // 🔧 Debug mode automatico da Flutter
  static bool get isDebug => kDebugMode;

  // ============================================================================
  // TIMEOUT CONFIGURATION
  // ============================================================================

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ============================================================================
  // STORAGE KEYS
  // ============================================================================

  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String firstLaunchKey = 'first_launch';

  // ============================================================================
  // API ENDPOINTS
  // ============================================================================

  static const String loginEndpoint = '/auth.php';
  static const String registerEndpoint = '/standalone_register.php';
  static const String passwordResetEndpoint = '/password_reset.php';
  static const String passwordResetConfirmEndpoint = '/reset_simple.php';
  static const String userProfileEndpoint = '/utente_profilo.php';
  static const String workoutsEndpoint = '/schede_standalone.php';
  static const String userStatsEndpoint = '/android_user_stats.php';
  static const String subscriptionEndpoint = '/subscription_api.php';

  // ============================================================================
  // VALIDATION RULES
  // ============================================================================

  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int maxNameLength = 50;

  // ============================================================================
  // UI CONFIGURATION
  // ============================================================================

  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);

  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================

  static const String networkErrorMessage = 'Impossibile connettersi al server. Verifica la tua connessione.';
  static const String timeoutErrorMessage = 'Timeout di connessione. Riprova più tardi.';
  static const String serverErrorMessage = 'Errore del server. Riprova più tardi.';
  static const String unknownErrorMessage = 'Si è verificato un errore sconosciuto.';

  // ============================================================================
  // FEATURE FLAGS
  // ============================================================================

  static const bool enableOfflineMode = false;
  static const bool enablePushNotifications = false;
  static const bool enableBiometric = false;
  static const bool enableDarkMode = true;
  static const bool enableAnalytics = false;

  // ============================================================================
  // ENVIRONMENT METHODS
  // ============================================================================

  /// Ritorna true se siamo in ambiente di sviluppo
  static bool get isDevelopment => isDebug;

  /// Ritorna true se siamo in ambiente di produzione
  static bool get isProduction => !isDebug;

  /// Ritorna la versione completa dell'app
  static String get fullVersion => '${appName} v${version}';

  /// Ritorna l'URL completo per un endpoint
  static String getFullUrl(String endpoint) => baseUrl + endpoint.replaceFirst('/', '');

  // ============================================================================
  // DEBUG HELPERS
  // ============================================================================

  /// Mostra informazioni di configurazione per debug
  static void printConfiguration() {
    print('🔧 [ENV] Environment Configuration:');
    print('🔧 [ENV] Mode: ${kDebugMode ? "🟡 DEBUG" : "🟢 RELEASE"}');
    print('🔧 [ENV] Base URL: $baseUrl');
    print('🔧 [ENV] Is Debug: $isDebug');
    print('🔧 [ENV] Is Production: $isProduction');
    print('🔧 [ENV] App Version: $fullVersion');
  }

  /// Valida la configurazione dell'ambiente
  static bool validateConfiguration() {
    final currentUrl = baseUrl;
    
    if (currentUrl.isEmpty) {
      print('❌ [ENV] ERROR: Base URL is empty');
      return false;
    }

    if (!currentUrl.startsWith('http')) {
      print('❌ [ENV] ERROR: Base URL must start with http/https');
      return false;
    }

    // In debug mode è OK usare URL locale
    if (isProduction && (currentUrl.contains('localhost') || currentUrl.contains('192.168'))) {
      print('⚠️ [ENV] WARNING: Production mode but using local URL');
      return false;
    }

    print('✅ [ENV] Configuration is valid');
    return true;
  }
}