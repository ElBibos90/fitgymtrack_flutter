// lib/shared/widgets/recovery_timer_popup.dart
// 🚀 Recovery Timer come Popup - Non invasivo e elegante
// ✅ IMPROVED: Better readability for timer text + Audio feedback

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

/// 🚀 Recovery Timer Popup - Elegante e non invasivo
/// ✅ Appare come overlay senza disturbare l'esercizio
/// ✅ Dismissibile e con controlli
/// ✅ Posizionamento smart (in basso)
/// ✅ Animazioni fluide
/// ✅ IMPROVED: Timer text readability
/// 🔊 AUDIO: beep_countdown.mp3 negli ultimi 3s, timer_complete.mp3 al termine
class RecoveryTimerPopup extends StatefulWidget {
  final int initialSeconds;
  final bool isActive;
  final String? exerciseName;
  final VoidCallback onTimerComplete;
  final VoidCallback onTimerStopped;
  final VoidCallback? onTimerDismissed;

  const RecoveryTimerPopup({
    super.key,
    required this.initialSeconds,
    required this.isActive,
    this.exerciseName,
    required this.onTimerComplete,
    required this.onTimerStopped,
    this.onTimerDismissed,
  });

  @override
  State<RecoveryTimerPopup> createState() => _RecoveryTimerPopupState();
}

class _RecoveryTimerPopupState extends State<RecoveryTimerPopup>
    with TickerProviderStateMixin {

  // Timer management
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isPaused = false;
  bool _isDismissed = false;

  // 🔊 Audio management
  late AudioPlayer _audioPlayer;
  bool _hasPlayedCompletionSound = false;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
    _audioPlayer = AudioPlayer();
    _initializeAnimations();
    if (widget.isActive) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    // Slide animation per l'ingresso dal basso
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Pulse animation per attirare attenzione negli ultimi secondi
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Progress animation per la barra circolare
    _progressController = AnimationController(
      duration: Duration(seconds: widget.initialSeconds),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));

    // Avvia l'animazione di ingresso
    _slideController.forward();
  }

  // 🔊 Audio methods
  Future<void> _playCountdownBeep() async {
    try {
      debugPrint("🔊 [RECOVERY AUDIO] Playing countdown beep");
      await _audioPlayer.play(AssetSource('audio/beep_countdown.mp3'));
    } catch (e) {
      debugPrint("🔊 [RECOVERY AUDIO] Error playing countdown beep: $e");
    }
  }

  Future<void> _playCompletionSound() async {
    try {
      if (!_hasPlayedCompletionSound) {
        debugPrint("🔊 [RECOVERY AUDIO] Playing completion sound");
        _hasPlayedCompletionSound = true;

        // 🔧 FIX: Aspetta che l'audio finisca davvero
        await _audioPlayer.play(AssetSource('audio/timer_complete.mp3'));

        // Piccolo delay extra per sicurezza
        await Future.delayed(const Duration(milliseconds: 900));

        debugPrint("🔊 [RECOVERY AUDIO] Completion sound finished");
      }
    } catch (e) {
      debugPrint("🔊 [RECOVERY AUDIO] Error playing completion sound: $e");
    }
  }

  // 🔧 FIX: Gestisce audio + callback + dismiss in sequenza
  Future<void> _playCompletionSoundAndFinish() async {
    try {
      // Play completion sound e aspetta che finisca
      await _playCompletionSound();

      // Callback di completamento
      widget.onTimerComplete();

      // Dismiss popup
      if (mounted && !_isDismissed) {
        _dismissPopup();
      }
    } catch (e) {
      debugPrint("🔊 [RECOVERY AUDIO] Error in completion sequence: $e");
      // Fallback: chiama comunque il callback
      widget.onTimerComplete();
      if (mounted && !_isDismissed) {
        _dismissPopup();
      }
    }
  }

  void _startTimer() {
    if (_isDismissed) return;

    _progressController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isDismissed) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;

          // 🔊 Audio + Pulse negli ultimi 3 secondi
          if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
            _pulseController.repeat(reverse: true);

            // 🔊 Play countdown beep
            _playCountdownBeep();

            // Haptic feedback più intenso negli ultimi secondi
            if (_remainingSeconds <= 3) {
              HapticFeedback.heavyImpact();
            }
          }
        } else {
          // Timer completato
          timer.cancel();
          _pulseController.stop();

          // Haptic feedback finale
          HapticFeedback.heavyImpact();

          // 🔧 FIX: Play audio e aspetta, poi callback e dismiss
          _playCompletionSoundAndFinish();
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _timer?.cancel();
      _progressController.stop();
      _pulseController.stop();
    } else {
      _startTimer();
    }
  }

  void _skipTimer() {
    _timer?.cancel();
    _progressController.stop();
    _pulseController.stop();

    widget.onTimerStopped();
    _dismissPopup();
  }

  void _dismissPopup() {
    if (_isDismissed) return;

    setState(() {
      _isDismissed = true;
    });

    _slideController.reverse().then((_) {
      if (widget.onTimerDismissed != null) {
        widget.onTimerDismissed!();
      }
    });
  }

  Color _getTimerColor() {
    if (_remainingSeconds <= 3) return Colors.red;
    if (_remainingSeconds <= 10) return Colors.orange;
    return Colors.blue;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    return Positioned(
      bottom: 100.h, // Sopra la navigazione ma non troppo in alto
      left: 20.w,
      right: 20.w,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: _getTimerColor().withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con nome esercizio e dismiss
                  Row(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            color: _getTimerColor(),
                            size: 20.sp,
                          ),
                          // 🔊 Audio indicator negli ultimi 3 secondi
                          if (_remainingSeconds <= 3 && !_isPaused) ...[
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.volume_up,
                              color: _getTimerColor(),
                              size: 16.sp,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          widget.exerciseName != null
                              ? 'Recupero ${widget.exerciseName}'
                              : 'Recupero',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: _dismissPopup,
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey[500],
                          size: 20.sp,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 24.w,
                          minHeight: 24.w,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // 🆕 IMPROVED: Timer principale con layout separato
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Progress Circle (più piccolo)
                      SizedBox(
                        width: 50.w,
                        height: 50.w,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background circle
                            CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 3,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey[200]!,
                              ),
                            ),
                            // Progress circle
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return CircularProgressIndicator(
                                  value: _progressAnimation.value,
                                  strokeWidth: 3,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getTimerColor(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 20.w),

                      // 🆕 Timer text separato (più leggibile)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: _getTimerColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: _getTimerColor().withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _formatTime(_remainingSeconds),
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: _getTimerColor(),
                          ),
                        ),
                      ),

                      SizedBox(width: 20.w),

                      // Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pause/Play
                          IconButton(
                            onPressed: _pauseTimer,
                            icon: Icon(
                              _isPaused ? Icons.play_arrow : Icons.pause,
                              color: _getTimerColor(),
                              size: 20.sp,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: _getTimerColor().withOpacity(0.1),
                              padding: EdgeInsets.all(6.w),
                              minimumSize: Size(32.w, 32.w),
                            ),
                          ),

                          SizedBox(width: 8.w),

                          // Skip
                          IconButton(
                            onPressed: _skipTimer,
                            icon: Icon(
                              Icons.skip_next,
                              color: Colors.grey[600],
                              size: 20.sp,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              padding: EdgeInsets.all(6.w),
                              minimumSize: Size(32.w, 32.w),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Status message
                  if (_isPaused) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '⏸️ Timer in pausa',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  if (_remainingSeconds <= 10 && !_isPaused) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getTimerColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_remainingSeconds <= 3) ...[
                            Icon(
                              Icons.volume_up,
                              color: _getTimerColor(),
                              size: 14.sp,
                            ),
                            SizedBox(width: 4.w),
                          ],
                          Text(
                            _remainingSeconds <= 3
                                ? '🔥 Ultimi secondi!'
                                : '⚡ Quasi pronto!',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: _getTimerColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}