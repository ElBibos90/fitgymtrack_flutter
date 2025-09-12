// lib/shared/theme/stats_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 🎨 Design System Moderno per le Statistiche
/// Colori, gradienti, tipografia e componenti professionali
class StatsTheme {
  // ============================================================================
  // 🎨 COLOR PALETTE - Palette Colori Professionale
  // ============================================================================
  
  // Primary Colors - Colori principali
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryIndigo = Color(0xFF6366F1);
  
  // Success Colors - Colori di successo
  static const Color successGreen = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);
  
  // Warning Colors - Colori di avviso
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color warningAmber = Color(0xFFFBBF24);
  static const Color warningRed = Color(0xFFEF4444);
  
  // Danger Colors - Colori di pericolo
  static const Color dangerRed = Color(0xFFEF4444);
  
  // Info Colors - Colori informativi
  static const Color infoCyan = Color(0xFF06B6D4);
  static const Color infoBlue = Color(0xFF0EA5E9);
  static const Color infoSky = Color(0xFF0EA5E9);
  
  // Neutral Colors - Colori neutri
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);
  
  // ============================================================================
  // 🌈 GRADIENTS - Gradienti Moderni
  // ============================================================================
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryPurple],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successGreen, successLight],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warningOrange, warningAmber],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [infoCyan, infoBlue],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    stops: [0.0, 1.0],
  );
  
  // ============================================================================
  // 📝 TYPOGRAPHY - Tipografia Professionale
  // ============================================================================
  
  static const String fontFamily = 'Inter';
  
  // Headers
  static TextStyle get h1 => TextStyle(
    fontFamily: fontFamily,
    fontSize: 32.sp,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static TextStyle get h2 => TextStyle(
    fontFamily: fontFamily,
    fontSize: 28.sp,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.3,
  );
  
  static TextStyle get h3 => TextStyle(
    fontFamily: fontFamily,
    fontSize: 24.sp,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );
  
  static TextStyle get h4 => TextStyle(
    fontFamily: fontFamily,
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // Body Text
  static TextStyle get bodyLarge => TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle get body1 => TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle get bodyMedium => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle get body2 => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle get bodySmall => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  static TextStyle get h5 => TextStyle(
    fontFamily: fontFamily,
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static TextStyle get button => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // Numbers & Metrics
  static TextStyle get metricLarge => TextStyle(
    fontFamily: fontFamily,
    fontSize: 36.sp,
    fontWeight: FontWeight.w900,
    height: 1.1,
    letterSpacing: -1.0,
  );
  
  static TextStyle get metricMedium => TextStyle(
    fontFamily: fontFamily,
    fontSize: 28.sp,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static TextStyle get metricSmall => TextStyle(
    fontFamily: fontFamily,
    fontSize: 20.sp,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  
  // Labels & Captions
  static TextStyle get labelLarge => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static TextStyle get labelMedium => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  
  static TextStyle get caption => TextStyle(
    fontFamily: fontFamily,
    fontSize: 10.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
  
  // ============================================================================
  // 📏 SPACING - Sistema di Spaziatura
  // ============================================================================
  
  // Base spacing unit: 4px
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;
  static const double space16 = 64.0;
  static const double space20 = 80.0;
  
  // ============================================================================
  // 🎯 BORDER RADIUS - Raggi di Bordo
  // ============================================================================
  
  static const double radius1 = 4.0;
  static const double radius2 = 8.0;
  static const double radius3 = 12.0;
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusXXLarge = 32.0;
  
  // ============================================================================
  // 🌟 SHADOWS - Ombre Moderne
  // ============================================================================
  
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get shadowXLarge => [
    BoxShadow(
      color: Colors.black.withOpacity(0.16),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  // ============================================================================
  // 🎨 THEME HELPERS - Helper per Temi
  // ============================================================================
  
  /// Ottiene il colore del testo primario in base al tema
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : neutral900;
  }
  
  /// Ottiene il colore del testo secondario in base al tema
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? neutral300
        : neutral600;
  }
  
  /// Ottiene il colore di sfondo delle card in base al tema
  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? neutral800
        : Colors.white;
  }
  
  /// Ottiene il colore di sfondo della pagina in base al tema
  static Color getPageBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? neutral900
        : neutral50;
  }
  
  /// Ottiene il colore del bordo in base al tema
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? neutral700
        : neutral200;
  }
  
  // ============================================================================
  // 🎯 ANIMATION DURATIONS - Durate Animazioni
  // ============================================================================
  
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // ============================================================================
  // 📱 BREAKPOINTS - Breakpoint Responsive
  // ============================================================================
  
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  /// Verifica se è un dispositivo mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }
  
  /// Verifica se è un tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }
  
  /// Verifica se è un desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
}
