// lib/shared/widgets/background_timer_wrapper.dart
// 🚀 Background Timer Wrapper - Integra timer con servizio background
// ✅ Gestione automatica timer in background
// ✅ Integrazione con AudioSettingsService
// ✅ Notifiche locali per completamento

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/di/dependency_injection.dart';
import '../../core/services/background_timer_service.dart';
import '../../core/services/audio_settings_service.dart';

/// 🚀 Background Timer Wrapper - Gestisce timer anche quando app è in background
/// ✅ Timer persistenti con notifiche locali
/// ✅ Integrazione con AudioSettingsService
/// ✅ Gestione automatica pausa/ripresa
class BackgroundTimerWrapper extends StatefulWidget {
  final int initialSeconds;
  final bool isActive;
  final String type; // 'recovery', 'isometric', 'rest_pause'
  final String? title;
  final String? message;
  final String? exerciseName;
  final VoidCallback onTimerComplete;
  final VoidCallback onTimerStopped;
  final VoidCallback? onTimerDismissed;
  final Widget Function(int remainingSeconds, bool isPaused, VoidCallback pauseResume, VoidCallback skip) builder;

  const BackgroundTimerWrapper({
    super.key,
    required this.initialSeconds,
    required this.isActive,
    required this.type,
    this.title,
    this.message,
    this.exerciseName,
    required this.onTimerComplete,
    required this.onTimerStopped,
    this.onTimerDismissed,
    required this.builder,
  });

  @override
  State<BackgroundTimerWrapper> createState() => _BackgroundTimerWrapperState();
}

class _BackgroundTimerWrapperState extends State<BackgroundTimerWrapper>
    with WidgetsBindingObserver {

  // Services
  late BackgroundTimerService _backgroundTimerService;
  late AudioSettingsService _audioSettings;

  // Timer state
  int _remainingSeconds = 0;
  bool _isPaused = false;
  bool _isDismissed = false;
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    
    // Inizializza servizi
    _backgroundTimerService = getIt<BackgroundTimerService>();
    _audioSettings = getIt<AudioSettingsService>();

    // Registra observer per lifecycle
    WidgetsBinding.instance.addObserver(this);

    // Inizializza stato
    _remainingSeconds = widget.initialSeconds;

    // Avvia timer se attivo
    if (widget.isActive) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uiTimer?.cancel();
    super.dispose();
  }

  /// Gestisce cambiamenti del lifecycle dell'app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App ripresa, ripristina timer se necessario
        _handleAppResume();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App in background, pausa timer UI ma mantieni background timer
        _pauseUITimer();
        break;
      case AppLifecycleState.detached:
        // App chiusa, ferma tutto
        _stopTimer();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Gestisce il ripristino dell'app
  void _handleAppResume() {
    if (_backgroundTimerService.isTimerActive) {
      // Ripristina timer UI dal background service
      final remaining = _backgroundTimerService.remainingSeconds;
      if (remaining != null) {
        setState(() {
          _remainingSeconds = remaining;
          _isPaused = false;
        });
        _startUITimer();
      }
    }
  }

  /// Avvia il timer
  void _startTimer() {
    if (_isDismissed) return;

    // Avvia background timer
    _backgroundTimerService.startBackgroundTimer(
      durationSeconds: widget.initialSeconds,
      type: widget.type,
      title: widget.title ?? _getDefaultTitle(),
      message: widget.message ?? _getDefaultMessage(),
      onComplete: _onTimerComplete,
      onTick: _onTimerTick,
    );

    // Avvia UI timer
    _startUITimer();
  }

  /// Avvia il timer UI
  void _startUITimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isDismissed) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;

          // 🔊 Audio + Haptic negli ultimi 3 secondi
          if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
            _playCountdownBeep();
            _triggerHapticFeedback();
          }
        } else {
          // Timer completato
          timer.cancel();
          _onTimerComplete();
        }
      });
    });
  }

  /// Pausa il timer UI (mantiene background timer attivo)
  void _pauseUITimer() {
    _uiTimer?.cancel();
    setState(() {
      _isPaused = true;
    });
  }

  /// Pausa/Riprendi il timer
  void _pauseResumeTimer() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _uiTimer?.cancel();
      _backgroundTimerService.pauseTimer();
    } else {
      _backgroundTimerService.resumeTimer();
      _startUITimer();
    }
  }

  /// Salta il timer
  void _skipTimer() {
    _stopTimer();
    widget.onTimerStopped();
  }

  /// Ferma il timer
  void _stopTimer() {
    _uiTimer?.cancel();
    _backgroundTimerService.stopBackgroundTimer();
    _isDismissed = true;
  }

  /// Callback per tick del background timer
  void _onTimerTick(int remaining) {
    if (mounted && !_isDismissed) {
      setState(() {
        _remainingSeconds = remaining;
      });
    }
  }

  /// Callback per completamento timer
  void _onTimerComplete() {
    if (_isDismissed) return;

    // Haptic feedback finale
    _triggerHapticFeedback();

    // Callback di completamento
    widget.onTimerComplete();

    // Dismiss se necessario
    if (widget.onTimerDismissed != null) {
      widget.onTimerDismissed!();
    }
  }

  /// Riproduce beep di countdown
  void _playCountdownBeep() {
    if (_audioSettings.timerSoundsEnabled) {
      // Per ora solo haptic feedback
      // Il suono richiederebbe integrazione con audioplayers
    }
  }

  /// Attiva feedback haptic
  void _triggerHapticFeedback() {
    if (_audioSettings.hapticFeedbackEnabled) {
      if (_remainingSeconds <= 3) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  /// Restituisce il titolo di default
  String _getDefaultTitle() {
    switch (widget.type) {
      case 'recovery':
        return '⏱️ Recupero ${widget.exerciseName ?? ''}';
      case 'isometric':
        return '💪 Timer Isometrico';
      case 'rest_pause':
        return '🔥 Rest-Pause';
      default:
        return '⏰ Timer';
    }
  }

  /// Restituisce il messaggio di default
  String _getDefaultMessage() {
    switch (widget.type) {
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

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      _remainingSeconds,
      _isPaused,
      _pauseResumeTimer,
      _skipTimer,
    );
  }
} 