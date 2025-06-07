package com.fitgymtracker

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "api_level_helper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 🔧 STRIPE FIX: FlutterFragmentActivity è RICHIESTO da flutter_stripe
        // per il corretto funzionamento di Payment Sheet e altri componenti

        // 📱 API Level Helper per gestione compatibilità Android
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