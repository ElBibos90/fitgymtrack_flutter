// lib/shared/theme/workout_design_system.dart
// 🎨 DESIGN SYSTEM PROFESSIONALE - WORKOUT IN PROGRESS
// Mobile-optimized per 375px width (iPhone SE)
// Data: 17 Ottobre 2025

import 'package:flutter/material.dart';

/// 🎨 WORKOUT DESIGN SYSTEM
/// Sistema di design completo per workout in progress
/// Ottimizzato per mobile (375px width min)
class WorkoutDesignSystem {
  WorkoutDesignSystem._();

  // ============================================================================
  // 🎨 COLOR PALETTE PROFESSIONALE
  // ============================================================================

  /// Primary Colors (Azione principale, CTA)
  static const Color primary700 = Color(0xFF1E40AF); // Bottoni, CTA
  static const Color primary600 = Color(0xFF2563EB); // Hover states
  static const Color primary500 = Color(0xFF3B82F6); // Default
  static const Color primary400 = Color(0xFF60A5FA); // Light accents
  static const Color primary50 = Color(0xFFEFF6FF); // Backgrounds

  /// Success Colors (Completamento)
  static const Color success700 = Color(0xFF15803D); // Dark
  static const Color success600 = Color(0xFF16A34A); // Default
  static const Color success500 = Color(0xFF22C55E); // Medium
  static const Color success200 = Color(0xFF86EFAC); // Border
  static const Color success100 = Color(0xFFDCFCE7); // Light
  static const Color success50 = Color(0xFFF0FDF4); // Background

  /// Warning Colors (Attenzione)
  static const Color warning700 = Color(0xFFB45309); // Dark
  static const Color warning600 = Color(0xFFD97706); // Default
  static const Color warning500 = Color(0xFFF59E0B); // Medium
  static const Color warning200 = Color(0xFFFDE047); // Border
  static const Color warning100 = Color(0xFFFEF3C7); // Light
  static const Color warning50 = Color(0xFFFEFCE8); // Background

  /// Error Colors (Errore)
  static const Color error700 = Color(0xFFB91C1C); // Dark
  static const Color error600 = Color(0xFFDC2626); // Default
  static const Color error500 = Color(0xFFEF4444); // Medium
  static const Color error200 = Color(0xFFFCA5A5); // Border
  static const Color error100 = Color(0xFFFEE2E2); // Light
  static const Color error50 = Color(0xFFFEF2F2); // Background

  /// Accent Colors (Timer, Alert)
  static const Color accent700 = Color(0xFFB91C1C); // Urgent
  static const Color accent600 = Color(0xFFDC2626); // Warning
  static const Color accent100 = Color(0xFFFEE2E2); // Light

  /// Neutral Colors (Testo, Bordi)
  static const Color gray900 = Color(0xFF111827); // Testo primario
  static const Color gray700 = Color(0xFF374151); // Testo secondario
  static const Color gray400 = Color(0xFF9CA3AF); // Disabilitato
  static const Color gray200 = Color(0xFFE5E7EB); // Bordi
  static const Color gray100 = Color(0xFFF3F4F6); // Background cards
  static const Color gray50 = Color(0xFFF9FAFB); // Background

  /// Neutral Colors (Extended)
  static const Color neutral600 = Color(0xFF6B7280); // Text secondary
  static const Color neutral500 = Color(0xFF9CA3AF); // Text disabled
  static const Color neutral300 = Color(0xFFD1D5DB); // Border light
  static const Color neutral200 = Color(0xFFE5E7EB); // Border
  static const Color neutral100 = Color(0xFFF3F4F6); // Background light
  static const Color neutral50 = Color(0xFFF9FAFB); // Background

  // 🌙 DARK MODE COLORS
  static const Color darkBackground = Color(0xFF0F0F0F); // Background principale
  static const Color darkSurface = Color(0xFF1A1A1A); // Cards, surface
  static const Color darkSurfaceElevated = Color(0xFF252525); // Cards elevate
  static const Color darkTextPrimary = Color(0xFFE5E5E5); // Testo primario
  static const Color darkTextSecondary = Color(0xFFB3B3B3); // Testo secondario
  static const Color darkBorder = Color(0xFF333333); // Bordi
  static const Color darkDivider = Color(0xFF2A2A2A); // Divisori

  /// Superset Colors
  static const Color supersetPurple700 = Color(0xFF7C3AED); // Dark
  static const Color supersetPurple600 = Color(0xFF8B5CF6); // Default
  static const Color supersetPurple50 = Color(0xFFFAF5FF); // Background

  /// Circuit Colors
  static const Color circuitOrange700 = Color(0xFFC2410C); // Dark
  static const Color circuitOrange600 = Color(0xFFEA580C); // Default
  static const Color circuitOrange50 = Color(0xFFFFF7ED); // Background

  /// Rest-Pause Colors
  static const Color restPauseRed700 = Color(0xFFB91C1C);
  static const Color restPauseRed600 = Color(0xFFDC2626);
  static const Color restPauseRed50 = Color(0xFFFEF2F2);

  /// Isometric Colors
  static const Color isometricBlue700 = Color(0xFF1D4ED8);
  static const Color isometricBlue600 = Color(0xFF2563EB);
  static const Color isometricBlue50 = Color(0xFFEFF6FF);

  // ============================================================================
  // 📏 TYPOGRAPHY SCALE
  // ============================================================================

  /// Font Families
  static const String fontFamilyPrimary = 'Inter'; // General text
  static const String fontFamilyNumbers = 'JetBrainsMono'; // Peso/Reps
  static const String fontFamilyDisplay = 'Manrope'; // Titoli grandi

  /// Font Sizes (Mobile optimized)
  static const double fontSizeDisplay = 24.0; // Pagina titolo
  static const double fontSizeH1 = 18.0; // Sezione principale
  static const double fontSizeH2 = 16.0; // Sottosezione
  static const double fontSizeH3 = 15.0; // Card titolo
  static const double fontSizeBody = 14.0; // Testo normale
  static const double fontSizeCaption = 12.0; // Etichette
  static const double fontSizeSmall = 11.0; // Info secondarie

  /// Font Sizes - Special
  static const double fontSizeNumberLarge = 32.0; // Peso/Reps
  static const double fontSizeTimer = 36.0; // Timer

  /// Font Weights
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightRegular = FontWeight.w400;

  /// Text Styles
  static const TextStyle displayStyle = TextStyle(
    fontSize: fontSizeDisplay,
    fontWeight: fontWeightBold,
    fontFamily: fontFamilyDisplay,
    color: gray900,
  );

  static const TextStyle h1Style = TextStyle(
    fontSize: fontSizeH1,
    fontWeight: fontWeightBold,
    fontFamily: fontFamilyPrimary,
    color: gray900,
  );

  static const TextStyle h2Style = TextStyle(
    fontSize: fontSizeH2,
    fontWeight: fontWeightSemiBold,
    fontFamily: fontFamilyPrimary,
    color: gray900,
  );

  static const TextStyle h3Style = TextStyle(
    fontSize: fontSizeH3,
    fontWeight: fontWeightSemiBold,
    fontFamily: fontFamilyPrimary,
    color: gray900,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: fontSizeBody,
    fontWeight: fontWeightRegular,
    fontFamily: fontFamilyPrimary,
    color: gray900,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: fontSizeCaption,
    fontWeight: fontWeightMedium,
    fontFamily: fontFamilyPrimary,
    color: gray700,
  );

  static const TextStyle smallStyle = TextStyle(
    fontSize: fontSizeSmall,
    fontWeight: fontWeightRegular,
    fontFamily: fontFamilyPrimary,
    color: gray700,
  );

  static const TextStyle numberStyle = TextStyle(
    fontSize: fontSizeNumberLarge,
    fontWeight: fontWeightBold,
    fontFamily: fontFamilyNumbers,
    color: gray900,
  );

  static const TextStyle timerStyle = TextStyle(
    fontSize: fontSizeTimer,
    fontWeight: fontWeightBold,
    fontFamily: fontFamilyNumbers,
    color: primary600,
  );

  // ============================================================================
  // 📐 SPACING SYSTEM (8-point grid)
  // ============================================================================

  static const double spacingXXS = 4.0; // Padding interno bottoni
  static const double spacingXS = 8.0; // Gap tra elementi piccoli
  static const double spacingS = 12.0; // Padding card interne
  static const double spacingM = 16.0; // Margin elementi
  static const double spacingL = 20.0; // Padding card principali (mobile)
  static const double spacingXL = 24.0; // Spazio tra sezioni (ridotto mobile)
  static const double spacingXXL = 32.0; // Top padding principale (ridotto mobile)

  /// Mobile Content Width (375px screen)
  static const double mobileScreenWidth = 375.0;
  static const double mobileHorizontalPadding = 20.0;
  static const double mobileContentWidth = 335.0; // 375 - (20 * 2)

  // ============================================================================
  // 💫 SHADOW SYSTEM
  // ============================================================================

  /// Level 1 (Card)
  static const List<BoxShadow> shadowLevel1 = [
    BoxShadow(
      color: Color(0x1F000000), // rgba(0,0,0,0.12)
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x3D000000), // rgba(0,0,0,0.24)
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Level 2 (Dialog)
  static const List<BoxShadow> shadowLevel2 = [
    BoxShadow(
      color: Color(0x26000000), // rgba(0,0,0,0.15)
      blurRadius: 6,
      offset: Offset(0, 3),
    ),
    BoxShadow(
      color: Color(0x1F000000), // rgba(0,0,0,0.12)
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Level 3 (Popup)
  static const List<BoxShadow> shadowLevel3 = [
    BoxShadow(
      color: Color(0x26000000), // rgba(0,0,0,0.15)
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x1A000000), // rgba(0,0,0,0.10)
      blurRadius: 6,
      offset: Offset(0, 3),
    ),
  ];

  /// Level 4 (Modal)
  static const List<BoxShadow> shadowLevel4 = [
    BoxShadow(
      color: Color(0x26000000), // rgba(0,0,0,0.15)
      blurRadius: 25,
      offset: Offset(0, 15),
    ),
    BoxShadow(
      color: Color(0x0D000000), // rgba(0,0,0,0.05)
      blurRadius: 10,
      offset: Offset(0, 5),
    ),
  ];

  // ============================================================================
  // 🔘 BORDER RADIUS
  // ============================================================================

  static const double radiusXS = 4.0; // Piccoli elementi
  static const double radiusS = 8.0; // Badge, chips
  static const double radiusM = 12.0; // Card standard
  static const double radiusL = 16.0; // Card grandi
  static const double radiusXL = 24.0; // Bottoni grandi, hero
  static const double radiusFull = 999.0; // Pills, circular

  static BorderRadius get borderRadiusXS => BorderRadius.circular(radiusXS);
  static BorderRadius get borderRadiusS => BorderRadius.circular(radiusS);
  static BorderRadius get borderRadiusM => BorderRadius.circular(radiusM);
  static BorderRadius get borderRadiusL => BorderRadius.circular(radiusL);
  static BorderRadius get borderRadiusXL => BorderRadius.circular(radiusXL);
  static BorderRadius get borderRadiusFull => BorderRadius.circular(radiusFull);

  // ============================================================================
  // 🎯 COMPONENT SIZES (Mobile Optimized)
  // ============================================================================

  /// Header
  static const double headerHeight = 60.0;
  static const double progressBarHeight = 3.0;

  /// Images
  static const double exerciseImageNormal = 200.0;
  static const double exerciseImageSuperset = 180.0;
  static const double exerciseImageCircuit = 160.0;

  /// Buttons
  static const double buttonHeightPrimary = 56.0; // Hero button
  static const double buttonHeightSecondary = 44.0; // Normal button
  static const double buttonHeightSmall = 36.0; // Small action
  static const double touchTargetMin = 44.0; // iOS HIG minimum

  /// Cards
  static const double weightRepsCardWidth = 140.0; // 🔧 FIX: Ridotto da 155 a 140 per evitare overflow
  static const double weightRepsCardHeight = 80.0;
  static const double weightRepsCardGap = 15.0; // 🔧 FIX: Aumentato gap per compensare larghezza ridotta

  /// Collapsible Sections
  static const double noteTrainerCollapsedHeight = 80.0;
  static const double noteTrainerExpandedHeight = 150.0;
  static const double historicoCollapsedHeight = 120.0;
  static const double historicoExpandedHeight = 280.0;

  /// Timer Popup
  static const double timerPopupWidth = 280.0;
  static const double timerPopupBottom = 120.0; // Sopra safe area
  static const double timerProgressRingSize = 80.0;
  static const double timerMiniBadgeSize = 40.0;

  /// Safe Area
  static const double safeAreaTop = 44.0; // Notch
  static const double safeAreaBottom = 34.0; // Home indicator

  // ============================================================================
  // 🎨 GRADIENTS
  // ============================================================================

  /// Primary Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary600, primary700],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Success Gradient
  static const LinearGradient successGradient = LinearGradient(
    colors: [success600, success700],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Superset Gradient
  static const LinearGradient supersetGradient = LinearGradient(
    colors: [supersetPurple600, supersetPurple700],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Card Subtle Gradient
  static const LinearGradient cardSubtleGradient = LinearGradient(
    colors: [Colors.white, gray50],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // 🌙 DARK MODE GRADIENTS
  static const LinearGradient cardSubtleGradientDark = LinearGradient(
    colors: [darkSurface, darkBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardElevatedGradientDark = LinearGradient(
    colors: [darkSurfaceElevated, darkSurface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ============================================================================
  // 🏷️ BADGE STYLES
  // ============================================================================

  /// Badge per tipo esercizio
  static BoxDecoration getBadgeDecoration(String type) {
    Color backgroundColor;
    Color borderColor;

    switch (type.toLowerCase()) {
      case 'superset':
        backgroundColor = supersetPurple50;
        borderColor = supersetPurple600;
        break;
      case 'circuit':
        backgroundColor = circuitOrange50;
        borderColor = circuitOrange600;
        break;
      case 'rest-pause':
        backgroundColor = restPauseRed50;
        borderColor = restPauseRed600;
        break;
      case 'isometric':
        backgroundColor = isometricBlue50;
        borderColor = isometricBlue600;
        break;
      default:
        backgroundColor = primary50;
        borderColor = primary600;
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadiusS,
      border: Border.all(color: borderColor.withValues(alpha: 0.3)),
    );
  }

  static Color getBadgeColor(String type) {
    switch (type.toLowerCase()) {
      case 'superset':
        return supersetPurple600;
      case 'circuit':
        return circuitOrange600;
      case 'rest-pause':
        return restPauseRed600;
      case 'isometric':
        return isometricBlue600;
      default:
        return primary600;
    }
  }

  // ============================================================================
  // 🎬 ANIMATION DURATIONS
  // ============================================================================

  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);

  // ============================================================================
  // 🎯 HELPER METHODS
  // ============================================================================

  /// Ottieni colore timer in base a secondi rimanenti
  static Color getTimerColor(int secondsRemaining) {
    if (secondsRemaining <= 3) return accent600; // Rosso urgente
    if (secondsRemaining <= 10) return circuitOrange600; // Arancione attenzione
    return primary600; // Blu calmo
  }

  /// Ottieni icona per tipo esercizio
  static IconData getExerciseTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'superset':
        return Icons.link;
      case 'circuit':
        return Icons.loop;
      case 'rest-pause':
        return Icons.pause_circle;
      case 'isometric':
        return Icons.timer;
      default:
        return Icons.fitness_center;
    }
  }

  /// Ottieni emoji per tipo esercizio
  static String getExerciseTypeEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'superset':
        return '🔗';
      case 'circuit':
        return '🔄';
      case 'rest-pause':
        return '🔥';
      case 'isometric':
        return '⏱️';
      default:
        return '💪';
    }
  }
}

