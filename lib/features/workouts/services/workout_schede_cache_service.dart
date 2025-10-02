// lib/features/workouts/services/workout_schede_cache_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_plan_models.dart';

/// 🚀 NUOVO: Servizio per cache locale delle schede di allenamento
/// Permette di visualizzare le schede anche offline
class WorkoutSchedeCacheService {
  static const String _schedeCacheKey = 'workout_schede_cache';
  static const String _lastUpdateKey = 'schede_last_update';
  static const Duration _cacheValidity = Duration(hours: 24); // Cache valida per 24 ore
  
  SharedPreferences? _prefs;
  
  WorkoutSchedeCacheService({SharedPreferences? prefs}) : _prefs = prefs;

  /// Inizializza SharedPreferences se non è già stato fatto
  Future<void> _ensurePrefsInitialized() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  /// Salva le schede nel cache locale
  Future<void> cacheSchede(List<WorkoutPlan> schede) async {
    try {
      await _ensurePrefsInitialized();
      
      final cacheData = {
        'schede': schede.map((s) => s.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _prefs!.setString(_schedeCacheKey, jsonEncode(cacheData));
      await _prefs!.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      
      //print('[CONSOLE] [schede_cache] 💾 Cached ${schede.length} workout plans');
    } catch (e) {
      print('[CONSOLE] [schede_cache] ❌ Error caching schede: $e');
    }
  }

  /// Carica le schede dal cache locale
  Future<List<WorkoutPlan>?> getCachedSchede() async {
    try {
      await _ensurePrefsInitialized();
      
      final cacheData = _prefs!.getString(_schedeCacheKey);
      if (cacheData == null) return null;

      final data = jsonDecode(cacheData) as Map<String, dynamic>;
      final timestamp = DateTime.parse(data['timestamp']);
      
      // Verifica se il cache è ancora valido
      final isExpired = DateTime.now().difference(timestamp) > _cacheValidity;
      if (isExpired) {
        //print('[CONSOLE] [schede_cache] ⏰ Cache expired, clearing...');
        await clearCache();
        return null;
      }

      final schedeList = (data['schede'] as List<dynamic>)
          .map((s) => WorkoutPlan.fromJson(s as Map<String, dynamic>))
          .toList();

      //print('[CONSOLE] [schede_cache] 📱 Loaded ${schedeList.length} cached workout plans');
      return schedeList;
    } catch (e) {
      print('[CONSOLE] [schede_cache] ❌ Error loading cached schede: $e');
      return null;
    }
  }

  /// Verifica se ci sono schede in cache
  Future<bool> hasCachedSchede() async {
    try {
      await _ensurePrefsInitialized();
      final cacheData = _prefs!.getString(_schedeCacheKey);
      if (cacheData == null) return false;

      final data = jsonDecode(cacheData) as Map<String, dynamic>;
      final timestamp = DateTime.parse(data['timestamp']);
      
      // Verifica se il cache è ancora valido
      final isExpired = DateTime.now().difference(timestamp) > _cacheValidity;
      if (isExpired) {
        await clearCache();
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Pulisce il cache
  Future<void> clearCache() async {
    await _ensurePrefsInitialized();
    await _prefs!.remove(_schedeCacheKey);
    await _prefs!.remove(_lastUpdateKey);
    //print('[CONSOLE] [schede_cache] 🧹 Cache cleared');
  }

  /// Ottiene informazioni sul cache
  Future<Map<String, dynamic>> getCacheInfo() async {
    await _ensurePrefsInitialized();
    final lastUpdate = _prefs!.getString(_lastUpdateKey);
    final hasCache = await hasCachedSchede();
    
    return {
      'has_cache': hasCache,
      'last_update': lastUpdate,
      'is_valid': hasCache,
    };
  }
}

