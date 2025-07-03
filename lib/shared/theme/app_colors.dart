import 'package:flutter/material.dart';

class AppColors {
  static const Color indigo600 = Color(0xFF1976D2);
  static const Color indigo50 = Color(0xFFE6E8F4);
  static const Color indigo700 = Color(0xFF1565C0);
  static const Color green600 = Color(0xFF2E7D32);
  static const Color green700 = Color(0xFF1B5E20);
  static const Color orange600 = Color(0xFFE65100);
  static const Color orange700 = Color(0xFFBF360C);
  static const Color purple600 = Color(0xFF7B1FA2);
  static const Color purple700 = Color(0xFF4A148C);

  static const Color blue600 = Color(0xFF1976D2);
  static const Color blue700 = Color(0xFF1565C0);
  static const Color teal600 = Color(0xFF00695C);
  static const Color teal700 = Color(0xFF004D40);
  static const Color red600 = Color(0xFFD32F2F);
  static const Color red700 = Color(0xFFC62828);
  static const Color pink600 = Color(0xFFC2185B);
  static const Color pink700 = Color(0xFFAD1457);
  static const Color amber600 = Color(0xFFFF8F00);
  static const Color amber700 = Color(0xFFFF6F00);
  static const Color lime600 = Color(0xFF827717);
  static const Color lime700 = Color(0xFF558B2F);

  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  static const Color border = Color(0xFFE0E0E0);
  static const Color borderFocused = indigo600;

  static const Color shadow = Color(0x1A000000);

  static Color getPrimaryColor(String themeName) {
    switch (themeName) {
      case 'blue':
        return blue600;
      case 'teal':
        return teal600;
      case 'red':
        return red600;
      case 'pink':
        return pink600;
      case 'amber':
        return amber600;
      case 'lime':
        return lime600;
      case 'purple':
        return purple600;
      case 'orange':
        return orange600;
      case 'green':
        return green600;
      default:
        return indigo600;
    }
  }

  static Color getPrimaryDarkColor(String themeName) {
    switch (themeName) {
      case 'blue':
        return blue700;
      case 'teal':
        return teal700;
      case 'red':
        return red700;
      case 'pink':
        return pink700;
      case 'amber':
        return amber700;
      case 'lime':
        return lime700;
      case 'purple':
        return purple700;
      case 'orange':
        return orange700;
      case 'green':
        return green700;
      default:
        return indigo700;
    }
  }

  static const List<Map<String, dynamic>> availableThemes = [
    {'name': 'indigo', 'displayName': 'Indigo', 'color': indigo600},
    {'name': 'blue', 'displayName': 'Blu', 'color': blue600},
    {'name': 'teal', 'displayName': 'Teal', 'color': teal600},
    {'name': 'green', 'displayName': 'Verde', 'color': green600},
    {'name': 'lime', 'displayName': 'Lime', 'color': lime600},
    {'name': 'amber', 'displayName': 'Ambra', 'color': amber600},
    {'name': 'orange', 'displayName': 'Arancione', 'color': orange600},
    {'name': 'red', 'displayName': 'Rosso', 'color': red600},
    {'name': 'pink', 'displayName': 'Rosa', 'color': pink600},
    {'name': 'purple', 'displayName': 'Viola', 'color': purple600},
  ];
}