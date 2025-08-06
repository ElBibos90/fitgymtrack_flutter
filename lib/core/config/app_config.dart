import 'package:flutter/material.dart';
import 'environment.dart';

class AppConfig {
  // ============================================================================
  // API CONFIGURATION
  // ============================================================================

  /// Base URL per le API
  static const String baseUrl = Environment.baseUrl;

  // ============================================================================
  // DESIGN TOKENS
  // ============================================================================

  // Colors
  static const Color primaryColor = Color(0xFF3B82F6); // Indigo 500
  static const Color secondaryColor = Color(0xFF6366F1); // Indigo 600
  static const Color accentColor = Color(0xFF8B5CF6); // Violet 500

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircle = 50.0;

  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;

  // Icon Sizes
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // Button Heights
  static const double buttonHeightS = 40.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightL = 56.0;

  // ============================================================================
  // TYPOGRAPHY SCALE
  // ============================================================================

  static const double fontSizeXS = 12.0;
  static const double fontSizeS = 14.0;
  static const double fontSizeM = 16.0;
  static const double fontSizeL = 18.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;
  static const double fontSizeTitle = 28.0;
  static const double fontSizeHeading = 32.0;

  // ============================================================================
  // ANIMATION CONFIGS
  // ============================================================================

  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  static const Curve animationCurve = Curves.easeInOut;
  static const Curve animationCurveBounce = Curves.elasticOut;

  // ============================================================================
  // RESPONSIVE BREAKPOINTS
  // ============================================================================

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Determina se siamo su mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Determina se siamo su tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Determina se siamo su desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Padding responsive basato sulla dimensione dello schermo
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(spacingM);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(spacingL);
    } else {
      return const EdgeInsets.all(spacingXL);
    }
  }

  // ============================================================================
  // GOOGLE PLAY STORE COMPLIANCE
  // ============================================================================

  /// URL Privacy Policy (richiesto da Google Play Store)
  static const String privacyPolicyUrl = 'https://fitgymtrack.com/privacy-policy';
  
  /// URL Terms of Service (richiesto da Google Play Store)
  static const String termsOfServiceUrl = 'https://fitgymtrack.com/terms-of-service';
  
  /// URL Support (opzionale ma consigliato)
  static const String supportUrl = 'https://fitgymtrack.com/support';
  
  /// Email support (opzionale ma consigliato)
  static const String supportEmail = 'fitgymtrack@gmail.com';
  
  /// Email privacy (GDPR compliance)
  static const String privacyEmail = 'fitgymtrack@gmail.com';
  
  /// Email legale (Terms of Service)
  static const String legalEmail = 'fitgymtrack@gmail.com';
  
  /// Nome sviluppatore per Google Play Store
  static const String developerName = 'FitGymTrack Team';
  
  /// Categoria app per Google Play Store
  static const String appCategory = 'Health & Fitness';
  
  /// Contenuto rating per Google Play Store
  static const String contentRating = 'Everyone';
  
  /// Versione minima Android supportata
  static const int minAndroidVersion = 21; // Android 5.0
  
  /// Versione target Android
  static const int targetAndroidVersion = 34; // Android 14
}