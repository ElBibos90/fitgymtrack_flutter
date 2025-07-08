import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servizio per gestire le preferenze del tema dell'app
class ThemeService {
  static const String _themeKey = 'app_theme';
  static const String _colorSchemeKey = 'app_color_scheme';
  static const String _accentColorKey = 'app_accent_color';
  
  static const String _lightTheme = 'light';
  static const String _darkTheme = 'dark';
  static const String _systemTheme = 'system';

  /// Ottiene il tema corrente dalle preferenze
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? _systemTheme;
    
    switch (themeString) {
      case _lightTheme:
        return ThemeMode.light;
      case _darkTheme:
        return ThemeMode.dark;
      case _systemTheme:
      default:
        return ThemeMode.system;
    }
  }

  /// Salva il tema nelle preferenze
  static Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeString;
    
    switch (themeMode) {
      case ThemeMode.light:
        themeString = _lightTheme;
        break;
      case ThemeMode.dark:
        themeString = _darkTheme;
        break;
      case ThemeMode.system:
      default:
        themeString = _systemTheme;
        break;
    }
    
    await prefs.setString(_themeKey, themeString);
  }

  /// Ottiene lo schema colori personalizzato
  static Future<String?> getColorScheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_colorSchemeKey);
  }

  /// Salva lo schema colori personalizzato
  static Future<void> setColorScheme(String colorScheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorSchemeKey, colorScheme);
  }

  /// Ottiene il colore accent personalizzato
  static Future<Color?> getAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_accentColorKey);
    return colorValue != null ? Color(colorValue) : null;
  }

  /// Salva il colore accent personalizzato
  static Future<void> setAccentColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, color.value);
  }

  /// Resetta tutte le preferenze del tema
  static Future<void> resetThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
    await prefs.remove(_colorSchemeKey);
    await prefs.remove(_accentColorKey);
  }
} 