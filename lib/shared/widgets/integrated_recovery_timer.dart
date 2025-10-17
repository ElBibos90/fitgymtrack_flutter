// lib/shared/widgets/integrated_recovery_timer.dart
// 🚀 Integrated Recovery Timer - Timer integrato nel layout dell'esercizio
// ✅ Non flottante, integrato nel design
// ✅ Minimizzabile in banner compatto
// ✅ Animazioni fluide
// ✅ Dark mode support
// ✅ Professionale e funzionale

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../../core/di/dependency_injection.dart';
import '../../core/services/audio_settings_service.dart';
import '../theme/workout_design_system.dart';

/// 🚀 Integrated Recovery Timer - Timer integrato nel layout
/// ✅ Non flottante, integrato nel design
/// ✅ Minimizzabile in banner compatto
/// ✅ Animazioni fluide
/// ✅ Dark mode support
class IntegratedRecoveryTimer extends StatefulWidget {
  final int initialSeconds;
  final bool isActive;
  final String? exerciseName;
  final VoidCallback onTimerComplete;
  final VoidCallback onTimerStopped;
  final VoidCallback? onTimerDismissed;
  final bool isInSuperset;
  final bool isLastInSuperset;
  final String? supersetInfo;

  const IntegratedRecoveryTimer({
    super.key,
    required this.initialSeconds,
    required this.isActive,
    this.exerciseName,
    required this.onTimerComplete,
    required this.onTimerStopped,
    this.onTimerDismissed,
    this.isInSuperset = false,
    this.isLastInSuperset = false,
    this.supersetInfo,
  });

  @override
  State<IntegratedRecoveryTimer> createState() => _IntegratedRecoveryTimerState();
}

class _IntegratedRecoveryTimerState extends State<IntegratedRecoveryTimer>
    with TickerProviderStateMixin {

  // Timer management
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isPaused = false;
  bool _isDismissed = false;
  bool _isMinimized = false;

  // 🔊 Audio management
  late AudioPlayer _audioPlayer;
  bool _hasPlayedCompletionSound = false;
  late AudioSettingsService _audioSettings;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _minimizeController;

  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _minimizeAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
    _audioPlayer = AudioPlayer();
    _audioSettings = getIt<AudioSettingsService>();
    
    _configureAudioContext();
    _initializeAnimations();
    
    if (widget.isActive) {
      _startTimer();
    }
  }

  Future<void> _configureAudioContext() async {
    try {
      await _audioPlayer.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
      ));
    } catch (e) {
      print("🔊 [INTEGRATED TIMER] Error configuring AudioContext: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _minimizeController.dispose();
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

    // Minimize animation
    _minimizeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _minimizeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _minimizeController,
      curve: Curves.easeInOut,
    ));

    // Avvia l'animazione di ingresso
    _slideController.forward();
  }

  // 🔊 Audio methods
  Future<void> _playCountdownBeep() async {
    try {
      if (!_audioSettings.timerSoundsEnabled) return;

      final volume = (_audioSettings.beepVolume / 100.0).clamp(0.1, 1.0);
      await _audioPlayer.setVolume(volume);
      await _audioPlayer.play(AssetSource('audio/beep_countdown.mp3'));
    } catch (e) {
      print("🔊 [INTEGRATED TIMER] Error playing countdown beep: $e");
    }
  }

  Future<void> _playCompletionSound() async {
    try {
      if (!_hasPlayedCompletionSound && _audioSettings.timerSoundsEnabled) {
        _hasPlayedCompletionSound = true;
        final volume = (_audioSettings.beepVolume / 100.0).clamp(0.1, 1.0);
        await _audioPlayer.setVolume(volume);
        await _audioPlayer.play(AssetSource('audio/timer_complete.mp3'));
        await Future.delayed(const Duration(milliseconds: 900));
      }
    } catch (e) {
      print("🔊 [INTEGRATED TIMER] Error playing completion sound: $e");
    }
  }

  Future<void> _playCompletionSoundAndFinish() async {
    try {
      await _playCompletionSound();
      widget.onTimerComplete();
      if (mounted && !_isDismissed) {
        _dismissTimer();
      }
    } catch (e) {
      widget.onTimerComplete();
      if (mounted && !_isDismissed) {
        _dismissTimer();
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
            _playCountdownBeep();

            if (_audioSettings.hapticFeedbackEnabled) {
              HapticFeedback.heavyImpact();
            }
          }
        } else {
          timer.cancel();
          _pulseController.stop();

          if (_audioSettings.hapticFeedbackEnabled) {
            HapticFeedback.heavyImpact();
          }

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
    _dismissTimer();
  }

  void _minimizeTimer() {
    setState(() {
      _isMinimized = true;
    });
    _minimizeController.forward();
  }

  void _maximizeTimer() {
    setState(() {
      _isMinimized = false;
    });
    _minimizeController.reverse();
  }

  void _dismissTimer() {
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

  Color _getTimerColor(int remainingSeconds) {
    if (widget.isInSuperset) {
      if (remainingSeconds <= 3) return WorkoutDesignSystem.primary700;
      if (remainingSeconds <= 10) return WorkoutDesignSystem.primary600;
      return WorkoutDesignSystem.primary500;
    }

    if (remainingSeconds <= 3) return Colors.red;
    if (remainingSeconds <= 10) return Colors.orange;
    return WorkoutDesignSystem.primary500;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  String _getHeaderText() {
    if (widget.isInSuperset) {
      if (widget.isLastInSuperset) {
        return 'Recupero ${widget.supersetInfo ?? 'Superset'}';
      } else {
        return 'Pausa tra esercizi';
      }
    }

    return widget.exerciseName != null
        ? 'Recupero ${widget.exerciseName}'
        : 'Recupero';
  }

  Widget _buildMinimizedTimer() {
    return AnimatedBuilder(
      animation: _minimizeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - (_minimizeAnimation.value * 0.3),
          child: Opacity(
            opacity: 1.0 - (_minimizeAnimation.value * 0.3),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: _isDarkMode() 
                    ? Colors.grey[800]
                    : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: _getTimerColor(_remainingSeconds).withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  // Progress circle
                  SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 2,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey[300]!,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return CircularProgressIndicator(
                              value: _progressAnimation.value,
                              strokeWidth: 2,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getTimerColor(_remainingSeconds),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: 12.w),
                  
                  // Timer text
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getTimerColor(_remainingSeconds).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _formatTime(_remainingSeconds),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: _getTimerColor(_remainingSeconds),
                        ),
                      ),
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
                          color: _getTimerColor(_remainingSeconds),
                          size: 16.sp,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _getTimerColor(_remainingSeconds).withValues(alpha: 0.1),
                          padding: EdgeInsets.all(4.w),
                          minimumSize: Size(20.w, 20.w),
                        ),
                      ),
                      
                      SizedBox(width: 4.w),
                      
                      // Maximize
                      IconButton(
                        onPressed: _maximizeTimer,
                        icon: Icon(
                          Icons.expand_less,
                          color: _isDarkMode() 
                              ? WorkoutDesignSystem.darkTextSecondary
                              : Colors.grey[600],
                          size: 16.sp,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _isDarkMode() 
                              ? WorkoutDesignSystem.darkSurface
                              : Colors.grey[100],
                          padding: EdgeInsets.all(4.w),
                          minimumSize: Size(20.w, 20.w),
                        ),
                      ),
                      
                      SizedBox(width: 4.w),
                      
                      // Close
                      IconButton(
                        onPressed: _dismissTimer,
                        icon: Icon(
                          Icons.close,
                          color: _isDarkMode() 
                              ? WorkoutDesignSystem.darkTextSecondary
                              : Colors.grey[600],
                          size: 16.sp,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _isDarkMode() 
                              ? WorkoutDesignSystem.darkSurface
                              : Colors.grey[100],
                          padding: EdgeInsets.all(4.w),
                          minimumSize: Size(20.w, 20.w),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullTimer() {
    return AnimatedBuilder(
      animation: _minimizeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - (_minimizeAnimation.value * 0.1),
          child: Opacity(
            opacity: 1.0 - _minimizeAnimation.value,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: _isDarkMode() 
                    ? Colors.grey[800]
                    : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: _getTimerColor(_remainingSeconds).withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isInSuperset ? Icons.link : Icons.timer,
                            color: _getTimerColor(_remainingSeconds),
                            size: 20.sp,
                          ),
                          if (_remainingSeconds <= 3 && !_isPaused) ...[
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.volume_up,
                              color: _getTimerColor(_remainingSeconds),
                              size: 16.sp,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          _getHeaderText(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: _isDarkMode() 
                                ? WorkoutDesignSystem.darkTextPrimary
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                      // Minimize button
                      IconButton(
                        onPressed: _minimizeTimer,
                        icon: Icon(
                          Icons.minimize,
                          color: _isDarkMode() 
                              ? WorkoutDesignSystem.darkTextSecondary
                              : Colors.grey[500],
                          size: 20.sp,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _isDarkMode() 
                              ? WorkoutDesignSystem.darkSurface
                              : Colors.grey[100],
                          padding: EdgeInsets.all(6.w),
                          minimumSize: Size(24.w, 24.w),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // Close button
                      IconButton(
                        onPressed: _dismissTimer,
                        icon: Icon(
                          Icons.close,
                          color: _isDarkMode() 
                              ? WorkoutDesignSystem.darkTextSecondary
                              : Colors.grey[500],
                          size: 20.sp,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _isDarkMode() 
                              ? WorkoutDesignSystem.darkSurface
                              : Colors.grey[100],
                          padding: EdgeInsets.all(6.w),
                          minimumSize: Size(24.w, 24.w),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Timer principale
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Progress Circle
                      SizedBox(
                        width: 60.w,
                        height: 60.w,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 4,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey[200]!,
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return CircularProgressIndicator(
                                  value: _progressAnimation.value,
                                  strokeWidth: 4,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getTimerColor(_remainingSeconds),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 24.w),

                      // Timer text
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: _getTimerColor(_remainingSeconds).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: _getTimerColor(_remainingSeconds).withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _formatTime(_remainingSeconds),
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: _getTimerColor(_remainingSeconds),
                          ),
                        ),
                      ),

                      SizedBox(width: 24.w),

                      // Controls
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pause/Play
                          IconButton(
                            onPressed: _pauseTimer,
                            icon: Icon(
                              _isPaused ? Icons.play_arrow : Icons.pause,
                              color: _getTimerColor(_remainingSeconds),
                              size: 24.sp,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: _getTimerColor(_remainingSeconds).withValues(alpha: 0.1),
                              padding: EdgeInsets.all(8.w),
                              minimumSize: Size(40.w, 40.w),
                            ),
                          ),
                          
                          SizedBox(height: 8.h),
                          
                          // Skip
                          IconButton(
                            onPressed: _skipTimer,
                            icon: Icon(
                              Icons.skip_next,
                              color: _isDarkMode() 
                                  ? WorkoutDesignSystem.darkTextSecondary
                                  : Colors.grey[600],
                              size: 24.sp,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: _isDarkMode() 
                                  ? WorkoutDesignSystem.darkSurface
                                  : Colors.grey[100],
                              padding: EdgeInsets.all(8.w),
                              minimumSize: Size(40.w, 40.w),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isDarkMode() {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    print("[TIMER] 🚀 IntegratedRecoveryTimer build - isDismissed: $_isDismissed, isMinimized: $_isMinimized, remainingSeconds: $_remainingSeconds");
    
    if (_isDismissed) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: _isMinimized ? _buildMinimizedTimer() : _buildFullTimer(),
      ),
    );
  }
}
