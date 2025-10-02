// lib/core/services/cache_cleanup_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/api_request_debouncer.dart';
import 'audio_settings_service.dart';
import 'theme_service.dart';
import '../../features/workouts/services/workout_schede_cache_service.dart';
import '../../features/workouts/services/workout_offline_service.dart';

/// 🧹 Servizio per pulizia completa delle cache al logout
/// Risolve il problema di contaminazione tra account diversi
class CacheCleanupService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// 🧹 PULIZIA COMPLETA AL LOGOUT
  /// Pulisce TUTTE le cache per evitare contaminazione tra account
  static Future<void> clearAllCachesOnLogout() async {
    //print('[CONSOLE] [cache_cleanup] 🧹 Starting complete cache cleanup on logout...');
    
    try {
      // 1. 🗑️ PULISCI CACHE API (già implementato)
      ApiRequestDebouncer.clearAllCache();
      //print('[CONSOLE] [cache_cleanup] ✅ API cache cleared');

      // 2. 🗑️ PULISCI CACHE IMMAGINI
      await _clearImageCache();
      //print('[CONSOLE] [cache_cleanup] ✅ Image cache cleared');

      // 3. 🗑️ PULISCI CACHE SCHEDE ALLENAMENTO
      await _clearWorkoutSchedeCache();
      //print('[CONSOLE] [cache_cleanup] ✅ Workout schede cache cleared');

      // 4. 🗑️ PULISCI CACHE ALLENAMENTI OFFLINE
      await _clearOfflineWorkoutCache();
      //print('[CONSOLE] [cache_cleanup] ✅ Offline workout cache cleared');

      // 5. 🗑️ PULISCI CACHE IMPOSTAZIONI AUDIO
      await _clearAudioSettingsCache();
      //print('[CONSOLE] [cache_cleanup] ✅ Audio settings cache cleared');

      // 6. 🗑️ PULISCI CACHE TEMA
      await _clearThemeCache();
      //print('[CONSOLE] [cache_cleanup] ✅ Theme cache cleared');

      // 7. 🗑️ PULISCI CACHE SUBSCRIPTION (SharedPreferences)
      await _clearSubscriptionCache();
      //print('[CONSOLE] [cache_cleanup] ✅ Subscription cache cleared');

      // 8. 🗑️ PULISCI CACHE PLATEAU (SharedPreferences)
      await _clearPlateauCache();
      //print('[CONSOLE] [cache_cleanup] ✅ Plateau cache cleared');

      // 9. 🗑️ PULISCI CACHE TIMER BACKGROUND
      await _clearBackgroundTimerCache();
      //print('[CONSOLE] [cache_cleanup] ✅ Background timer cache cleared');

      // 10. 🗑️ PULISCI CACHE APP UPDATE
      await _clearAppUpdateCache();
      //print('[CONSOLE] [cache_cleanup] ✅ App update cache cleared');

      //print('[CONSOLE] [cache_cleanup] 🎉 Complete cache cleanup completed successfully!');
      
    } catch (e) {
      print('[CONSOLE] [cache_cleanup] ❌ Error during cache cleanup: $e');
    }
  }

  /// 🧹 PULIZIA SELEZIONATA (mantiene solo schede e offline)
  /// Per quando vuoi mantenere solo le cache essenziali
  static Future<void> clearNonEssentialCaches() async {
    //print('[CONSOLE] [cache_cleanup] 🧹 Starting non-essential cache cleanup...');
    
    try {
      // Pulisci cache non essenziali (MANTIENE schede e offline)
      ApiRequestDebouncer.clearAllCache();
      await _clearImageCache();
      await _clearAudioSettingsCache();
      await _clearThemeCache();
      await _clearSubscriptionCache();
      await _clearPlateauCache();
      await _clearBackgroundTimerCache();
      await _clearAppUpdateCache();
      
      // 🚫 NON pulire:
      // - workout_schede_cache (per visualizzazione offline)
      // - offline_workout_data (per riprendere allenamenti)
      // - pending_series_queue (per sincronizzazione)
      
      //print('[CONSOLE] [cache_cleanup] ✅ Non-essential caches cleared (kept schede + offline)');
      
    } catch (e) {
      print('[CONSOLE] [cache_cleanup] ❌ Error during non-essential cache cleanup: $e');
    }
  }

  // ============================================================================
  // METODI PRIVATI PER PULIZIA SPECIFICA
  // ============================================================================

  /// Pulisce cache immagini
  static Future<void> _clearImageCache() async {
    try {
      // Pulisce la cache in memoria
      await CachedNetworkImage.evictFromCache('');
      // Nota: clearDiskCache() non esiste in questa versione del plugin
      // La cache su disco viene gestita automaticamente dal sistema
    } catch (e) {
      print('[CONSOLE] [cache_cleanup] ⚠️ Error clearing image cache: $e');
    }
  }

  /// Pulisce cache schede allenamento (SOLO per pulizia completa)
  static Future<void> _clearWorkoutSchedeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('workout_schede_cache');
      await prefs.remove('schede_last_update');
    } catch (e) {
      print('[CONSOLE] [cache_cleanup] ⚠️ Error clearing workout schede cache: $e');
    }
  }

  /// Pulisce cache allenamenti offline (SOLO per pulizia completa)
  static Future<void> _clearOfflineWorkoutCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('offline_workout_data');
      await prefs.remove('pending_series_queue');
      await prefs.remove('sync_status');
      await prefs.remove('offline_completions_queue');
    } catch (e) {
      print('[CONSOLE] [cache_cleanup] ⚠️ Error clearing offline workout cache: $e');
    }
  }

  /// Pulisce cache impostazioni audio
  static Future<void> _clearAudioSettingsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('audio_settings');
      await prefs.remove('timer_sounds_enabled');
      await prefs.remove('beep_volume');
      await prefs.remove('audio_ducking_enabled');
      await prefs.remove('haptic_feedback_enabled');
    } catch (e) {
      print('[CONSOLE] [cache_cleanup] ⚠️ Error clearing audio settings cache: $e');
    }
  }

  /// Pulisce cache tema
  static Future<void> _clearThemeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('app_theme');
      await prefs.remove('app_color_scheme');
      await prefs.remove('app_accent_color');
    } catch (e) {
      print('[CONSOLE] [cache_cleanup] ⚠️ Error clearing theme cache: $e');
    }
  }

  /// Pulisce cache subscription
  static Future<void> _clearSubscriptionCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Pulisce tutte le chiavi relative alla subscription
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.contains('subscription') || 
            key.contains('premium') || 
            key.contains('payment') ||
            key.contains('stripe')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('[CONSOLE] [cache_cleanup] ⚠️ Error clearing subscription cache: $e');
    }
  }

  /// Pulisce cache plateau
  static Future<void> _clearPlateauCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.contains('plateau') || 
            key.contains('historic_data') ||
            key.contains('analysis')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('[CONSOLE] [cache_cleanup] ⚠️ Error clearing plateau cache: $e');
    }
  }

  /// Pulisce cache timer background
  static Future<void> _clearBackgroundTimerCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('background_timer_state');
      await prefs.remove('timer_state');
    } catch (e) {
      print('[CONSOLE] [cache_cleanup] ⚠️ Error clearing background timer cache: $e');
    }
  }

  /// Pulisce cache app update
  static Future<void> _clearAppUpdateCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.contains('app_update') || 
            key.contains('version_check') ||
            key.contains('last_update')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('[CONSOLE] [cache_cleanup] ⚠️ Error clearing app update cache: $e');
    }
  }

  /// 🧹 PULIZIA TOTALE (nuclear option)
  /// Pulisce TUTTO, incluso storage sicuro
  static Future<void> clearEverything() async {
    //print('[CONSOLE] [cache_cleanup] 💥 NUCLEAR OPTION: Clearing everything...');
    
    try {
      // Pulisci tutto
      await clearAllCachesOnLogout();
      
      // Pulisci anche storage sicuro
      await _secureStorage.deleteAll();
      
      // Pulisci SharedPreferences completamente
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      //print('[CONSOLE] [cache_cleanup] 💥 Everything cleared!');
      
    } catch (e) {
      print('[CONSOLE] [cache_cleanup] ❌ Error during nuclear cleanup: $e');
    }
  }

  /// 📊 STATISTICHE CACHE
  /// Mostra informazioni sulle cache attuali
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      return {
        'total_keys': keys.length,
        'keys': keys.toList(),
        'has_workout_schede': keys.contains('workout_schede_cache'),
        'has_offline_workout': keys.contains('offline_workout_data'),
        'has_subscription_data': keys.any((k) => k.contains('subscription')),
        'has_audio_settings': keys.contains('audio_settings'),
        'has_theme_settings': keys.contains('app_theme'),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
