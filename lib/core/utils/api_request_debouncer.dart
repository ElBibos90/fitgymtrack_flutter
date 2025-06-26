// lib/core/utils/api_request_debouncer.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// 🚀 PERFORMANCE: Previene richieste API duplicate
class ApiRequestDebouncer {
  static final Map<String, Timer> _timers = {};
  static final Map<String, bool> _activeRequests = {};
  static final Map<String, dynamic> _requestCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  /// Durata cache per diversi tipi di richieste
  static const Duration _defaultCacheDuration = Duration(minutes: 2);
  static const Duration _subscriptionCacheDuration = Duration(minutes: 5);
  static const Duration _plansCacheDuration = Duration(minutes: 10);

  /// Previene chiamate duplicate con debouncing
  static Future<T?> debounceRequest<T>({
    required String key,
    required Future<T> Function() request,
    Duration delay = const Duration(milliseconds: 300),
    Duration? cacheDuration,
  }) async {
    // 1. Controlla se c'è una richiesta già attiva
    if (_activeRequests[key] == true) {
      debugPrint('🚫 [DEBOUNCER] Request blocked - already active: $key');
      return null;
    }

    // 2. Controlla cache
    final cacheResult = _getCachedResult<T>(key, cacheDuration);
    if (cacheResult != null) {
      debugPrint('⚡ [DEBOUNCER] Cache hit for: $key');
      return cacheResult;
    }

    // 3. Cancella timer precedente
    _timers[key]?.cancel();

    // 4. Crea completer per gestire il risultato
    final completer = Completer<T?>();

    // 5. Crea nuovo timer
    _timers[key] = Timer(delay, () async {
      if (_activeRequests[key] == true) {
        debugPrint('🚫 [DEBOUNCER] Request blocked - race condition: $key');
        completer.complete(null);
        return;
      }

      _activeRequests[key] = true;
      debugPrint('🚀 [DEBOUNCER] Executing request: $key');

      try {
        final result = await request();

        // Cache il risultato
        _requestCache[key] = result;
        _cacheTimestamps[key] = DateTime.now();

        debugPrint('✅ [DEBOUNCER] Request completed: $key');
        completer.complete(result);
      } catch (e) {
        debugPrint('❌ [DEBOUNCER] Request failed: $key - $e');
        completer.completeError(e);
      } finally {
        _activeRequests[key] = false;
      }
    });

    return completer.future;
  }

  /// Ottieni risultato dalla cache se valido
  static T? _getCachedResult<T>(String key, Duration? cacheDuration) {
    final cachedData = _requestCache[key];
    final timestamp = _cacheTimestamps[key];

    if (cachedData == null || timestamp == null) return null;

    final duration = cacheDuration ?? _getDurationForKey(key);
    final isValid = DateTime.now().difference(timestamp) < duration;

    return isValid ? cachedData as T : null;
  }

  /// Ottieni durata cache basata sul tipo di richiesta
  static Duration _getDurationForKey(String key) {
    if (key.contains('subscription')) return _subscriptionCacheDuration;
    if (key.contains('plans')) return _plansCacheDuration;
    return _defaultCacheDuration;
  }

  /// Cancella cache per una chiave specifica
  static void clearCache(String key) {
    _requestCache.remove(key);
    _cacheTimestamps.remove(key);
    debugPrint('🗑️ [DEBOUNCER] Cache cleared for: $key');
  }

  /// Cancella tutta la cache
  static void clearAllCache() {
    _requestCache.clear();
    _cacheTimestamps.clear();
    debugPrint('🗑️ [DEBOUNCER] All cache cleared');
  }

  /// Cancella timer attivi
  static void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _activeRequests.clear();
    debugPrint('🧹 [DEBOUNCER] Disposed all timers');
  }

  /// Statistiche per debugging
  static Map<String, dynamic> getStats() {
    return {
      'active_requests': _activeRequests.length,
      'cached_items': _requestCache.length,
      'active_timers': _timers.length,
    };
  }
}

/// Helper methods per subscription requests
class SubscriptionApiDebouncer {
  static Future<T?> subscriptionRequest<T>({
    required String endpoint,
    required Future<T> Function() request,
  }) {
    return ApiRequestDebouncer.debounceRequest<T>(
      key: 'subscription_$endpoint',
      request: request,
      delay: const Duration(milliseconds: 500), // Più lungo per subscription
      cacheDuration: const Duration(minutes: 5),
    );
  }
}