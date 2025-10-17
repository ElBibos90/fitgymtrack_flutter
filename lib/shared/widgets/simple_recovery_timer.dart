// lib/shared/widgets/simple_recovery_timer.dart
// 🚀 Simple Recovery Timer - Timer semplice e visibile
// ✅ Altezza fissa e visibile
// ✅ Colori contrastanti
// ✅ Design minimale ma funzionale

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../../core/di/dependency_injection.dart';
import '../../core/services/audio_settings_service.dart';

class SimpleRecoveryTimer extends StatefulWidget {
  final int initialSeconds;
  final bool isActive;
  final String? exerciseName;
  final VoidCallback onTimerComplete;
  final VoidCallback onTimerStopped;
  final VoidCallback? onTimerDismissed;

  const SimpleRecoveryTimer({
    super.key,
    required this.initialSeconds,
    required this.isActive,
    this.exerciseName,
    required this.onTimerComplete,
    required this.onTimerStopped,
    this.onTimerDismissed,
  });

  @override
  State<SimpleRecoveryTimer> createState() => _SimpleRecoveryTimerState();
}

class _SimpleRecoveryTimerState extends State<SimpleRecoveryTimer> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isPaused = false;
  bool _isDismissed = false;

  late AudioPlayer _audioPlayer;
  bool _hasPlayedCompletionSound = false;
  late AudioSettingsService _audioSettings;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
    _audioPlayer = AudioPlayer();
    _audioSettings = getIt<AudioSettingsService>();
    
    if (widget.isActive) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isDismissed) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isDismissed) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
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
    } else {
      _startTimer();
    }
  }

  void _skipTimer() {
    _timer?.cancel();
    widget.onTimerStopped();
    _dismissTimer();
  }

  void _dismissTimer() {
    if (_isDismissed) return;

    setState(() {
      _isDismissed = true;
    });

    if (widget.onTimerDismissed != null) {
      widget.onTimerDismissed!();
    }
  }

  Future<void> _playCompletionSoundAndFinish() async {
    try {
      if (!_hasPlayedCompletionSound && _audioSettings.timerSoundsEnabled) {
        _hasPlayedCompletionSound = true;
        final volume = (_audioSettings.beepVolume / 100.0).clamp(0.1, 1.0);
        await _audioPlayer.setVolume(volume);
        await _audioPlayer.play(AssetSource('audio/timer_complete.mp3'));
        await Future.delayed(const Duration(milliseconds: 900));
      }
    } catch (e) {
      print("🔊 [SIMPLE TIMER] Error playing completion sound: $e");
    } finally {
      widget.onTimerComplete();
      if (mounted && !_isDismissed) {
        _dismissTimer();
      }
    }
  }

  Color _getTimerColor(int remainingSeconds) {
    if (remainingSeconds <= 3) return Colors.red;
    if (remainingSeconds <= 10) return Colors.orange;
    return Colors.blue;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    print("[TIMER] 🚀 SimpleRecoveryTimer build - isDismissed: $_isDismissed, remainingSeconds: $_remainingSeconds");
    
    if (_isDismissed) return const SizedBox.shrink();

    return Container(
      height: 78.h, // 🚀 ALTEZZA RIDOTTA PER EVITARE OVERFLOW
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.red, // 🚀 COLORE ROSSO VISIBILE
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _getTimerColor(_remainingSeconds),
          width: 3,
        ),
      ),
      child: Row(
        children: [
          // Icona timer
          Container(
            width: 50.w,
            height: 50.w,
            margin: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Icon(
              Icons.timer,
              color: _getTimerColor(_remainingSeconds),
              size: 24.sp,
            ),
          ),
          
          // Timer text
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'RECUPERO',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (widget.exerciseName != null) ...[
                  SizedBox(height: 1.h),
                  Text(
                    widget.exerciseName!,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pause/Play
              IconButton(
                onPressed: _pauseTimer,
                icon: Icon(
                  _isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                  size: 20.sp,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: EdgeInsets.all(6.w),
                  minimumSize: Size(32.w, 32.w),
                ),
              ),
              
              SizedBox(width: 4.w),
              
              // Skip
              IconButton(
                onPressed: _skipTimer,
                icon: Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 20.sp,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: EdgeInsets.all(6.w),
                  minimumSize: Size(32.w, 32.w),
                ),
              ),
              
              SizedBox(width: 4.w),
              
              // Close
              IconButton(
                onPressed: _dismissTimer,
                icon: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20.sp,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: EdgeInsets.all(6.w),
                  minimumSize: Size(32.w, 32.w),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
