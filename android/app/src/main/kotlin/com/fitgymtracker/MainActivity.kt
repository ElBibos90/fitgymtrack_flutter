package com.fitgymtracker

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.os.Bundle
import android.app.NotificationChannel
import android.app.NotificationManager

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "api_level_helper"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 🔔 NOTIFICATION FIX: Crea notification channel per heads-up notifications
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "fitgymtrack_notifications"
            val channelName = "FitGymTrack Notifications"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = "Notifiche da FitGymTrack"
                enableVibration(true)
                setShowBadge(true)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
        }
    }

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