// 🚀 FASE 5 - STEP 4: RestPauseTimerPopup Widget
// File: lib/shared/widgets/rest_pause_timer_popup.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class RestPauseTimerPopup extends StatefulWidget {
  final int initialSeconds;
  final bool isActive;
  final String exerciseName;
  final int currentMicroSeries;
  final int totalMicroSeries;
  final int nextTargetReps;
  final VoidCallback onTimerComplete;
  final VoidCallback onTimerStopped;
  final VoidCallback onTimerDismissed;

  const RestPauseTimerPopup({
    super.key,
    required this.initialSeconds,
    required this.isActive,
    required this.exerciseName,
    required this.currentMicroSeries,
    required this.totalMicroSeries,
    required this.nextTargetReps,
    required this.onTimerComplete,
    required this.onTimerStopped,
    required this.onTimerDismissed,
  });

  @override
  State<RestPauseTimerPopup> createState() => _RestPauseTimerPopupState();
}

class _RestPauseTimerPopupState extends State<RestPauseTimerPopup>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Animazioni
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;

    // Setup animazioni
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: Duration(seconds: widget.initialSeconds),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    // Avvia automaticamente se attivo
    if (widget.isActive) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _pulseController.repeat(reverse: true);
    _progressController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });

        // Feedback tattile negli ultimi 3 secondi
        if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
          _triggerHapticFeedback();
        }
      } else {
        _completeTimer();
      }
    });
  }

  void _pauseTimer() {
    if (!_isRunning || _isPaused) return;

    setState(() {
      _isPaused = true;
    });

    _timer?.cancel();
    _pulseController.stop();
    _progressController.stop();
  }

  void _resumeTimer() {
    if (!_isPaused) return;

    setState(() {
      _isPaused = false;
    });

    _startTimer();
  }

  void _stopTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _progressController.stop();

    setState(() {
      _isRunning = false;
      _isPaused = false;
    });

    widget.onTimerStopped();
  }

  void _completeTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _progressController.stop();

    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
    });

    _playCompletionSound();
    _triggerCompletionHaptic();
    widget.onTimerComplete();
  }

  void _skipTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _progressController.stop();

    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
    });

    widget.onTimerComplete();
  }

  Future<void> _playCompletionSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/rest_pause_complete.wav'));
    } catch (e) {
      print('🔊 [REST-PAUSE] Error playing sound: $e');
    }
  }

  Future<void> _triggerHapticFeedback() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 100);
      }
    } catch (e) {
      print('📳 [REST-PAUSE] Error with haptic feedback: $e');
    }
  }

  Future<void> _triggerCompletionHaptic() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 200, 100, 200]);
      }
    } catch (e) {
      print('📳 [REST-PAUSE] Error with completion haptic: $e');
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              margin: EdgeInsets.all(20.w),
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: Colors.purple.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con icona REST-PAUSE
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt,
                          color: Colors.purple,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'MINI-RECUPERO REST-PAUSE',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Timer principale
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Progress circle
                          SizedBox(
                            width: 120.w,
                            height: 120.w,
                            child: CircularProgressIndicator(
                              value: _progressAnimation.value,
                              strokeWidth: 8.w,
                              backgroundColor: Colors.purple.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _remainingSeconds <= 3 ? Colors.red : Colors.purple,
                              ),
                            ),
                          ),
                          // Timer text
                          Text(
                            _formatTime(_remainingSeconds),
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: _remainingSeconds <= 3 ? Colors.red : Colors.purple,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 24.h),

                  // Info micro-serie
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Prossima micro-serie: ${widget.currentMicroSeries + 1}/${widget.totalMicroSeries}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${widget.nextTargetReps} ripetizioni',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Controlli
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Pulsante Skip
                      ElevatedButton(
                        onPressed: _skipTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.skip_next, size: 18.sp),
                            SizedBox(width: 4.w),
                            Text(
                              'Salta',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Pulsante Pause/Resume
                      ElevatedButton(
                        onPressed: _isPaused ? _resumeTimer : _pauseTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPaused ? Colors.green : Colors.amber,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isPaused ? Icons.play_arrow : Icons.pause,
                              size: 18.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              _isPaused ? 'Riprendi' : 'Pausa',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Esercizio info
                  Text(
                    widget.exerciseName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}