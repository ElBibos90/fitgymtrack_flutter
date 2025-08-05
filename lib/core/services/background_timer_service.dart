// lib/core/services/background_timer_service.dart
// 🚀 Background Timer Service - Gestione timer anche quando app è in background
// ✅ Timer persistenti con notifiche locali
// ✅ Gestione stato timer con SharedPreferences
// ✅ Integrazione con AudioSettingsService

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../di/dependency_injection.dart';
import 'audio_settings_service.dart';

/// 🚀 Background Timer Service - Gestisce timer anche quando app è in background
/// ✅ Timer persistenti con notifiche locali
/// ✅ Gestione stato timer con SharedPreferences
/// ✅ Integrazione con AudioSettingsService
class BackgroundTimerService {
  static const String _timerStateKey = 'background_timer_state';
  static const String _timerChannelId = 'fitgymtrack_timer_channel';
  static const String _timerChannelName = 'FitGymTrack Timer';
  static const String _timerChannelDescription = 'Notifiche timer allenamento';

  // Singleton pattern
  static final BackgroundTimerService _instance = BackgroundTimerService._internal();
  factory BackgroundTimerService() => _instance;
  BackgroundTimerService._internal();

  // Dependencies
  late FlutterLocalNotificationsPlugin _notifications;
  late AudioSettingsService _audioSettings;
  SharedPreferences? _prefs;

  // Timer state
  Timer? _backgroundTimer;
  DateTime? _timerStartTime;
  int? _timerDuration;
  String? _timerType; // 'recovery', 'isometric', 'rest_pause'
  String? _timerTitle;
  String? _timerMessage;
  bool _isTimerActive = false;

  // Callbacks
  VoidCallback? _onTimerComplete;
  void Function(int)? _onTimerTick;

  /// Inizializza il servizio
  Future<void> initialize() async {
    try {
      // Inizializza timezone
      tz.initializeTimeZones();

      // Inizializza notifiche
      _notifications = FlutterLocalNotificationsPlugin();
      await _initializeNotifications();

      // Inizializza SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Inizializza AudioSettingsService
      _audioSettings = getIt<AudioSettingsService>();

      print("🚀 [BACKGROUND TIMER] Service initialized successfully");
    } catch (e) {
      print("💥 [BACKGROUND TIMER] Error initializing service: $e");
    }
  }

  /// Inizializza le notifiche locali
  Future<void> _initializeNotifications() async {
    // Configurazione Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configurazione iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configurazione iniziale
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Inizializza plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crea canale per Android
    await _createNotificationChannel();
  }

  /// Crea il canale di notifica per Android
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      _timerChannelId,
      _timerChannelName,
      description: _timerChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Avvia un timer in background
  Future<void> startBackgroundTimer({
    required int durationSeconds,
    required String type,
    String? title,
    String? message,
    VoidCallback? onComplete,
    void Function(int)? onTick,
  }) async {
    try {
      // Ferma timer precedente se attivo
      await stopBackgroundTimer();

      // Salva stato timer
      _timerStartTime = DateTime.now();
      _timerDuration = durationSeconds;
      _timerType = type;
      _timerTitle = title ?? _getDefaultTitle(type);
      _timerMessage = message ?? _getDefaultMessage(type);
      _onTimerComplete = onComplete;
      _onTimerTick = onTick;
      _isTimerActive = true;

      // Salva stato in SharedPreferences
      await _saveTimerState();

      // Avvia timer di background
      _startBackgroundTimer();

      // Crea notifica di inizio timer
      await _showTimerStartedNotification();

      print("🚀 [BACKGROUND TIMER] Started timer: $type for $durationSeconds seconds");
    } catch (e) {
      print("💥 [BACKGROUND TIMER] Error starting timer: $e");
    }
  }

  /// Avvia il timer di background
  void _startBackgroundTimer() {
    _backgroundTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isTimerActive || _timerStartTime == null || _timerDuration == null) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(_timerStartTime!).inSeconds;
      final remaining = _timerDuration! - elapsed;

      // Callback tick
      _onTimerTick?.call(remaining);

      if (remaining <= 0) {
        // Timer completato
        timer.cancel();
        await _onTimerCompleted();
      } else {
        // Aggiorna stato
        await _saveTimerState();
      }
    });
  }

  /// Gestisce il completamento del timer
  Future<void> _onTimerCompleted() async {
    try {
      _isTimerActive = false;

      // Mostra notifica di completamento
      await _showTimerCompletedNotification();

      // Riproduce suono se abilitato
      if (_audioSettings.timerSoundsEnabled) {
        await _playCompletionSound();
      }

      // Callback di completamento
      _onTimerComplete?.call();

      // Pulisci stato
      await _clearTimerState();

      print("✅ [BACKGROUND TIMER] Timer completed: $_timerType");
    } catch (e) {
      print("💥 [BACKGROUND TIMER] Error completing timer: $e");
    }
  }

  /// Ferma il timer in background
  Future<void> stopBackgroundTimer() async {
    try {
      _backgroundTimer?.cancel();
      _backgroundTimer = null;
      _isTimerActive = false;

      // Cancella notifiche
      await _notifications.cancelAll();

      // Pulisci stato
      await _clearTimerState();

      print("⏹️ [BACKGROUND TIMER] Timer stopped");
    } catch (e) {
      print("💥 [BACKGROUND TIMER] Error stopping timer: $e");
    }
  }

  /// Pausa il timer
  Future<void> pauseTimer() async {
    if (_isTimerActive) {
      _backgroundTimer?.cancel();
      _backgroundTimer = null;
      await _saveTimerState();
      print("⏸️ [BACKGROUND TIMER] Timer paused");
    }
  }

  /// Riprendi il timer
  Future<void> resumeTimer() async {
    if (_isTimerActive && _backgroundTimer == null) {
      _startBackgroundTimer();
      print("▶️ [BACKGROUND TIMER] Timer resumed");
    }
  }

  /// Ripristina timer da stato salvato
  Future<void> restoreTimer() async {
    try {
      final state = await _loadTimerState();
      if (state != null && state['isActive'] == true) {
        final startTime = DateTime.parse(state['startTime']);
        final duration = state['duration'] as int;
        final elapsed = DateTime.now().difference(startTime).inSeconds;
        final remaining = duration - elapsed;

        if (remaining > 0) {
          // Ripristina timer
          _timerStartTime = startTime;
          _timerDuration = duration;
          _timerType = state['type'];
          _timerTitle = state['title'];
          _timerMessage = state['message'];
          _isTimerActive = true;

          // Avvia timer con tempo rimanente
          _startBackgroundTimer();

          print("🔄 [BACKGROUND TIMER] Timer restored with $remaining seconds remaining");
        } else {
          // Timer scaduto, pulisci stato
          await _clearTimerState();
        }
      }
    } catch (e) {
      print("💥 [BACKGROUND TIMER] Error restoring timer: $e");
    }
  }

  /// Salva lo stato del timer
  Future<void> _saveTimerState() async {
    try {
      if (_prefs != null && _timerStartTime != null && _timerDuration != null) {
        final state = {
          'startTime': _timerStartTime!.toIso8601String(),
          'duration': _timerDuration,
          'type': _timerType,
          'title': _timerTitle,
          'message': _timerMessage,
          'isActive': _isTimerActive,
        };

        await _prefs!.setString(_timerStateKey, jsonEncode(state));
      }
    } catch (e) {
      print("💥 [BACKGROUND TIMER] Error saving timer state: $e");
    }
  }

  /// Carica lo stato del timer
  Future<Map<String, dynamic>?> _loadTimerState() async {
    try {
      if (_prefs != null) {
        final stateString = _prefs!.getString(_timerStateKey);
        if (stateString != null) {
          return jsonDecode(stateString) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print("💥 [BACKGROUND TIMER] Error loading timer state: $e");
    }
    return null;
  }

  /// Pulisce lo stato del timer
  Future<void> _clearTimerState() async {
    try {
      _timerStartTime = null;
      _timerDuration = null;
      _timerType = null;
      _timerTitle = null;
      _timerMessage = null;
      _isTimerActive = false;
      _onTimerComplete = null;
      _onTimerTick = null;

      if (_prefs != null) {
        await _prefs!.remove(_timerStateKey);
      }
    } catch (e) {
      print("💥 [BACKGROUND TIMER] Error clearing timer state: $e");
    }
  }

  /// Mostra notifica di inizio timer
  Future<void> _showTimerStartedNotification() async {
    try {
      await _notifications.show(
        1,
        _timerTitle ?? 'Timer Avviato',
        _timerMessage ?? 'Il timer è attivo in background',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _timerChannelId,
            _timerChannelName,
            channelDescription: _timerChannelDescription,
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: false,
            presentBadge: false,
            presentSound: false,
          ),
        ),
      );
    } catch (e) {
      print("💥 [BACKGROUND TIMER] Error showing start notification: $e");
    }
  }

  /// Mostra notifica di completamento timer
  Future<void> _showTimerCompletedNotification() async {
    try {
      await _notifications.show(
        2,
        '⏰ Timer Completato',
        _timerMessage ?? 'Il timer è terminato',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _timerChannelId,
            _timerChannelName,
            channelDescription: _timerChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: _audioSettings.timerSoundsEnabled,
            enableVibration: _audioSettings.hapticFeedbackEnabled,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: _audioSettings.timerSoundsEnabled,
          ),
        ),
      );
    } catch (e) {
      print("💥 [BACKGROUND TIMER] Error showing completion notification: $e");
    }
  }

  /// Riproduce suono di completamento
  Future<void> _playCompletionSound() async {
    try {
      // Per ora usiamo solo vibrazione, il suono richiederebbe audio files
      if (_audioSettings.hapticFeedbackEnabled) {
        // Vibrazione di completamento
        // HapticFeedback.heavyImpact();
      }
    } catch (e) {
      print("💥 [BACKGROUND TIMER] Error playing completion sound: $e");
    }
  }

  /// Gestisce il tap sulla notifica
  void _onNotificationTapped(NotificationResponse response) {
    // Gestisce il tap sulla notifica
    print("🔔 [BACKGROUND TIMER] Notification tapped: ${response.payload}");
  }

  /// Restituisce il titolo di default per tipo timer
  String _getDefaultTitle(String type) {
    switch (type) {
      case 'recovery':
        return '⏱️ Recupero';
      case 'isometric':
        return '💪 Timer Isometrico';
      case 'rest_pause':
        return '🔥 Rest-Pause';
      default:
        return '⏰ Timer';
    }
  }

  /// Restituisce il messaggio di default per tipo timer
  String _getDefaultMessage(String type) {
    switch (type) {
      case 'recovery':
        return 'Riposati e preparati per la prossima serie';
      case 'isometric':
        return 'Mantieni la posizione isometrica';
      case 'rest_pause':
        return 'Pausa breve, poi continua';
      default:
        return 'Timer in corso';
    }
  }

  /// Getter per lo stato del timer
  bool get isTimerActive => _isTimerActive;
  int? get remainingSeconds {
    if (_timerStartTime == null || _timerDuration == null) return null;
    final elapsed = DateTime.now().difference(_timerStartTime!).inSeconds;
    final remaining = _timerDuration! - elapsed;
    return remaining > 0 ? remaining : 0;
  }
  String? get timerType => _timerType;
  String? get timerTitle => _timerTitle;

  /// Dispose del servizio
  void dispose() {
    _backgroundTimer?.cancel();
    _notifications.cancelAll();
  }
} 