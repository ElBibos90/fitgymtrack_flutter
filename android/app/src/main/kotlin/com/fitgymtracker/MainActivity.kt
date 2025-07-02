package com.fitgymtracker

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.tasks.Tasks
import android.content.Context

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "api_level_helper"
    private val WEAR_CHANNEL = "fitgymtrack/wear"

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

        // ⌚️ Wear OS Connection Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WEAR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isWearConnected" -> {
                    checkWearConnection(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkWearConnection(result: MethodChannel.Result) {
        Thread {
            try {
                val nodeListTask = Wearable.getNodeClient(this).connectedNodes
                val nodes = Tasks.await(nodeListTask)
                result.success(nodes.isNotEmpty())
            } catch (e: Exception) {
                result.error("WEAR_ERROR", e.localizedMessage, null)
            }
        }.start()
    }
}