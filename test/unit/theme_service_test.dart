import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitgymtrack/core/services/theme_service.dart';
import 'package:flutter/material.dart';

void main() {
  group('ThemeService Tests', () {
    late ThemeService themeService;

    setUp(() {
      themeService = ThemeService.instance;
    });

    tearDown(() async {
      // Pulisci le preferenze dopo ogni test
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_theme');
      await prefs.remove('theme_mode');
    });

    test('should return default theme when no theme is set', () async {
      final theme = await themeService.getSelectedTheme();
      expect(theme, equals('indigo'));
    });

    test('should save and retrieve selected theme', () async {
      await themeService.setSelectedTheme('blue');
      final theme = await themeService.getSelectedTheme();
      expect(theme, equals('blue'));
    });

    test('should return system theme mode when no mode is set', () async {
      final mode = await themeService.getThemeMode();
      expect(mode, equals(ThemeMode.system));
    });

    test('should save and retrieve theme mode', () async {
      await themeService.setThemeMode(ThemeMode.dark);
      final mode = await themeService.getThemeMode();
      expect(mode, equals(ThemeMode.dark));
    });

    test('should return correct primary color for theme', () async {
      await themeService.setSelectedTheme('green');
      final color = await themeService.getPrimaryColor();
      expect(color, isA<Color>());
    });

    test('should reset theme preferences', () async {
      await themeService.setSelectedTheme('red');
      await themeService.setThemeMode(ThemeMode.light);
      
      await themeService.resetThemePreferences();
      
      final theme = await themeService.getSelectedTheme();
      final mode = await themeService.getThemeMode();
      
      expect(theme, equals('indigo'));
      expect(mode, equals(ThemeMode.system));
    });

    test('should return all theme preferences as map', () async {
      await themeService.setSelectedTheme('purple');
      await themeService.setThemeMode(ThemeMode.light);
      
      final preferences = await themeService.getAllThemePreferences();
      
      expect(preferences['theme'], equals('purple'));
      expect(preferences['mode'], equals('ThemeMode.light'));
      expect(preferences['primaryColor'], isA<Color>());
      expect(preferences['primaryDarkColor'], isA<Color>());
    });
  });
} 