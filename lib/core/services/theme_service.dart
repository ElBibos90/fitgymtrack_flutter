import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme/app_colors.dart';

class ThemeService {
  static const String _themeKey = 'selected_theme';
  static const String _themeModeKey = 'theme_mode';
  static const String _defaultTheme = 'indigo';

  static ThemeService? _instance;
  static ThemeService get instance => _instance ??= ThemeService._();

  ThemeService._();

  /// Ottiene il tema selezionato dall'utente
  Future<String> getSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? _defaultTheme;
  }

  /// Salva il tema selezionato dall'utente
  Future<void> setSelectedTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeName);
  }

  /// Ottiene la modalità tema (light/dark/system)
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_themeModeKey) ?? 'system';
    
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Salva la modalità tema
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeString;
    
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
      default:
        modeString = 'system';
        break;
    }
    
    await prefs.setString(_themeModeKey, modeString);
  }

  /// Ottiene il colore primario per il tema corrente
  Future<Color> getPrimaryColor() async {
    final themeName = await getSelectedTheme();
    return AppColors.getPrimaryColor(themeName);
  }

  /// Ottiene il colore primario scuro per il tema corrente
  Future<Color> getPrimaryDarkColor() async {
    final themeName = await getSelectedTheme();
    return AppColors.getPrimaryDarkColor(themeName);
  }

  /// Resetta le preferenze tema ai valori di default
  Future<void> resetThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
    await prefs.remove(_themeModeKey);
  }

  /// Ottiene tutte le preferenze tema come Map
  Future<Map<String, dynamic>> getAllThemePreferences() async {
    final theme = await getSelectedTheme();
    final mode = await getThemeMode();
    
    return {
      'theme': theme,
      'mode': mode.toString(),
      'primaryColor': AppColors.getPrimaryColor(theme),
      'primaryDarkColor': AppColors.getPrimaryDarkColor(theme),
    };
  }
} 