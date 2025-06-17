// lib/shared/widgets/isometric_timer_popup.dart
// 🔥 Timer per Esercizi Isometrici - Conta secondi di tenuta
// 🔊 AUDIO: beep_countdown.mp3 negli ultimi 3s, timer_complete.mp3 al termine

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

/// 🔥 Isometric Timer Popup - Timer per esercizi isometrici
/// ✅ Mostra countdown per la tenuta isometrica
/// ✅ Al termine completa automaticamente la serie
/// ✅ Design coerente con Recovery Timer
/// 🔊 AUDIO: beep_countdown.mp3 negli ultimi 3s, timer_complete.mp3 al termine
class IsometricTimerPopup extends StatefulWidget {
  final int initialSeconds;
  final bool isActive;
  final String exerciseName;
  final VoidCallback onIsometricComplete;
  final VoidCallback onIsometricCancelled;
  final VoidCallback? onIsometricDismissed;

  const IsometricTimerPopup({
    super.key,
    required this.initialSeconds,
    required this.isActive,
    required this.exerciseName,
    required this.onIsometricComplete,
    required this.onIsometricCancelled,
    this.onIsometricDismissed,
  });

  @override
  State<IsometricTimerPopup> createState() => _IsometricTimerPopupState();
}

class _IsometricTimerPopupState extends State<IsometricTimerPopup>
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.12,
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
      //print("🔊 [ISOMETRIC AUDIO] Playing countdown beep");
      await _audioPlayer.play(AssetSource('audio/beep_countdown.mp3'));
    } catch (e) {
      //print("🔊 [ISOMETRIC AUDIO] Error playing countdown beep: $e");
    }
  }

  Future<void> _playCompletionSound() async {
    try {
      if (!_hasPlayedCompletionSound) {
        //print("🔊 [ISOMETRIC AUDIO] Playing completion sound");
        _hasPlayedCompletionSound = true;

        // 🔧 FIX: Aspetta che l'audio finisca davvero
        await _audioPlayer.play(AssetSource('audio/timer_complete.mp3'));

        // Piccolo delay extra per sicurezza
        await Future.delayed(const Duration(milliseconds: 900));

        //print("🔊 [ISOMETRIC AUDIO] Completion sound finished");
      }
    } catch (e) {
      //print("🔊 [ISOMETRIC AUDIO] Error playing completion sound: $e");
    }
  }

  // 🔧 FIX: Gestisce audio + callback + dismiss in sequenza
  Future<void> _playCompletionSoundAndFinish() async {
    try {
      // Play completion sound e aspetta che finisca
      await _playCompletionSound();

      // Callback di completamento
      widget.onIsometricComplete();

      // Dismiss popup
      if (mounted && !_isDismissed) {
        _dismissPopup();
      }
    } catch (e) {
      //print("🔊 [ISOMETRIC AUDIO] Error in completion sequence: $e");
      // Fallback: chiama comunque il callback
      widget.onIsometricComplete();
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

          // 🔊 Audio + Pulse negli ultimi 5 secondi (più lungo per isometrico)
          if (_remainingSeconds <= 5 && _remainingSeconds > 0) {
            _pulseController.repeat(reverse: true);

            // 🔊 Play countdown beep negli ultimi 3 secondi
            if (_remainingSeconds <= 3) {
              _playCountdownBeep();
            }

            // Haptic feedback più intenso negli ultimi secondi
            if (_remainingSeconds <= 3) {
              HapticFeedback.heavyImpact();
            } else {
              HapticFeedback.lightImpact();
            }
          }
        } else {
          // Timer completato
          timer.cancel();
          _pulseController.stop();

          // Haptic feedback finale - doppio impulso
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 100), () {
            HapticFeedback.heavyImpact();
          });

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

  void _cancelTimer() {
    _timer?.cancel();
    _progressController.stop();
    _pulseController.stop();

    widget.onIsometricCancelled();
    _dismissPopup();
  }

  void _dismissPopup() {
    if (_isDismissed) return;

    setState(() {
      _isDismissed = true;
    });

    _slideController.reverse().then((_) {
      if (widget.onIsometricDismissed != null) {
        widget.onIsometricDismissed!();
      }
    });
  }

  Color _getTimerColor() {
    if (_remainingSeconds <= 3) return Colors.red;
    if (_remainingSeconds <= 5) return Colors.orange;
    return Colors.deepPurple; // Colore distintivo per isometrico
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
      top: MediaQuery.of(context).size.height * 0.3, // Più alto per isometrico
      left: 20.w,
      right: 20.w,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: _getTimerColor().withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con nome esercizio
                  Row(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            color: _getTimerColor(),
                            size: 24.sp,
                          ),
                          // 🔊 Audio indicator negli ultimi 3 secondi
                          if (_remainingSeconds <= 3 && !_isPaused) ...[
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.volume_up,
                              color: _getTimerColor(),
                              size: 18.sp,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔥 ESERCIZIO ISOMETRICO',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: _getTimerColor(),
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              widget.exerciseName,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _cancelTimer,
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey[500],
                          size: 24.sp,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Timer principale (più grande per isometrico)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Progress Circle (più grande)
                      SizedBox(
                        width: 80.w,
                        height: 80.w,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background circle
                            CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 6,
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
                                  strokeWidth: 6,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getTimerColor(),
                                  ),
                                );
                              },
                            ),
                            // Icona centrale con audio indicator
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer,
                                  color: _getTimerColor(),
                                  size: 24.sp,
                                ),
                                if (_remainingSeconds <= 3 && !_isPaused)
                                  Icon(
                                    Icons.volume_up,
                                    color: _getTimerColor(),
                                    size: 12.sp,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 32.w),

                      // Timer text (molto più grande)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                        decoration: BoxDecoration(
                          color: _getTimerColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: _getTimerColor().withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TENUTA',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: _getTimerColor(),
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _formatTime(_remainingSeconds),
                              style: TextStyle(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.bold,
                                color: _getTimerColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Controls (più grandi)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pause/Play
                      Container(
                        decoration: BoxDecoration(
                          color: _getTimerColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: IconButton(
                          onPressed: _pauseTimer,
                          icon: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                            color: _getTimerColor(),
                            size: 28.sp,
                          ),
                          style: IconButton.styleFrom(
                            padding: EdgeInsets.all(12.w),
                            minimumSize: Size(48.w, 48.w),
                          ),
                        ),
                      ),

                      SizedBox(width: 16.w),

                      // Cancel
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: IconButton(
                          onPressed: _cancelTimer,
                          icon: Icon(
                            Icons.stop,
                            color: Colors.red,
                            size: 28.sp,
                          ),
                          style: IconButton.styleFrom(
                            padding: EdgeInsets.all(12.w),
                            minimumSize: Size(48.w, 48.w),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Status message
                  if (_isPaused) ...[
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '⏸️ Tenuta in pausa',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  if (_remainingSeconds <= 5 && !_isPaused) ...[
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                              size: 16.sp,
                            ),
                            SizedBox(width: 6.w),
                          ],
                          Text(
                            _remainingSeconds <= 3
                                ? '🔥 Tieni ancora!'
                                : '💪 Quasi fatto!',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: _getTimerColor(),
                              fontWeight: FontWeight.w600,
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