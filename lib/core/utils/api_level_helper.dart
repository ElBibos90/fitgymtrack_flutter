// lib/core/utils/api_level_helper.dart
import 'dart:io';
import 'package:flutter/services.dart';

class ApiLevelHelper {
  static const MethodChannel _channel = MethodChannel('api_level_helper');

  /// Ottiene l'API level di Android
  static Future<int> getApiLevel() async {
    if (!Platform.isAndroid) {
      return 0; // Non Android
    }

    try {
      final int apiLevel = await _channel.invokeMethod('getApiLevel');
      return apiLevel;
    } catch (e) {
      //print('[CONSOLE] [api_level_helper]Errore nel rilevare API level: $e');
      return 0;
    }
  }

  /// Versione sincrona che restituisce una stringa per debug
  static String getApiLevelSync() {
    if (!Platform.isAndroid) {
      return Platform.operatingSystem.toUpperCase();
    }
    return "Android (API TBD)";
  }

  /// Controlla se siamo su API 34 o inferiore
  static Future<bool> isApi34OrBelow() async {
    final apiLevel = await getApiLevel();
    return apiLevel <= 34 && apiLevel > 0;
  }

  /// Controlla se siamo su API 35 o superiore
  static Future<bool> isApi35OrAbove() async {
    final apiLevel = await getApiLevel();
    return apiLevel >= 35;
  }
}

// ============================================================================
// ANDROID NATIVE CODE DA AGGIUNGERE
// ============================================================================

/*
AGGIUNGI QUESTO al file android/app/src/main/kotlin/MainActivity.kt:

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import android.os.Build

class MainActivity: FlutterActivity() {
    private val CHANNEL = "api_level_helper"

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getApiLevel" -> {
                    val apiLevel = Build.VERSION.SDK_INT
                    result.success(apiLevel)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
*/