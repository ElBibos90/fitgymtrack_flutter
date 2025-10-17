// lib/shared/widgets/enhanced_recovery_timer_popup.dart
// 🚀 Enhanced Recovery Timer - Minimizzabile e Draggable
// ✅ Minimizzabile in floating button
// ✅ Draggable su tutto lo schermo
// ✅ Gesture support per swipe
// ✅ Animazioni fluide
// ✅ Dark mode support

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../../core/di/dependency_injection.dart';
import '../../core/services/audio_settings_service.dart';
import 'background_timer_wrapper.dart';
import '../theme/workout_design_system.dart';

/// 🚀 Enhanced Recovery Timer - Minimizzabile e Draggable
/// ✅ Minimizzabile in floating button
/// ✅ Draggable su tutto lo schermo  
/// ✅ Gesture support per swipe
/// ✅ Animazioni fluide
/// ✅ Dark mode support
class EnhancedRecoveryTimerPopup extends StatefulWidget {
  final int initialSeconds;
  final bool isActive;
  final String? exerciseName;
  final VoidCallback onTimerComplete;
  final VoidCallback onTimerStopped;
  final VoidCallback? onTimerDismissed;
  final bool isInSuperset;
  final bool isLastInSuperset;
  final String? supersetInfo;

  const EnhancedRecoveryTimerPopup({
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
  State<EnhancedRecoveryTimerPopup> createState() => _EnhancedRecoveryTimerPopupState();
}

class _EnhancedRecoveryTimerPopupState extends State<EnhancedRecoveryTimerPopup>
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
  late AnimationController _dragController;

  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _minimizeAnimation;
  late Animation<double> _dragAnimation;

  // Drag position
  Offset _dragPosition = const Offset(0, 0);
  bool _isDragging = false;

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
          category: AVAudioSessionCategory.ambient,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
      ));
    } catch (e) {
      print("🔊 [ENHANCED TIMER] Error configuring AudioContext: $e");
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
    _dragController.dispose();
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

    // Drag animation
    _dragController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _dragAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeOut,
    ));

    // Avvia l'animazione di ingresso
    _slideController.forward();
  }

  // 🔊 Audio methods (stessi del timer originale)
  Future<void> _playCountdownBeep() async {
    try {
      if (!_audioSettings.timerSoundsEnabled) return;

      final volume = (_audioSettings.beepVolume / 100.0).clamp(0.1, 1.0);
      await _audioPlayer.setVolume(volume);
      await _audioPlayer.play(AssetSource('audio/beep_countdown.mp3'));
    } catch (e) {
      print("🔊 [ENHANCED TIMER] Error playing countdown beep: $e");
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
      print("🔊 [ENHANCED TIMER] Error playing completion sound: $e");
    }
  }

  Future<void> _playCompletionSoundAndFinish() async {
    try {
      await _playCompletionSound();
      widget.onTimerComplete();
      if (mounted && !_isDismissed) {
        _dismissPopup();
      }
    } catch (e) {
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
    _dismissPopup();
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

  // Drag handling
  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _dragController.forward();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDragging) {
      setState(() {
        _dragPosition += details.delta;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    _dragController.reverse();

    // Snap to edges
    final screenSize = MediaQuery.of(context).size;
    final widgetSize = 80.w; // Size of minimized widget

    if (_dragPosition.dx < 0) {
      _dragPosition = Offset(0, _dragPosition.dy);
    } else if (_dragPosition.dx > screenSize.width - widgetSize) {
      _dragPosition = Offset(screenSize.width - widgetSize, _dragPosition.dy);
    }

    if (_dragPosition.dy < 0) {
      _dragPosition = Offset(_dragPosition.dx, 0);
    } else if (_dragPosition.dy > screenSize.height - widgetSize - 100.h) {
      _dragPosition = Offset(_dragPosition.dx, screenSize.height - widgetSize - 100.h);
    }

    setState(() {});
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
            child: Positioned(
              left: _dragPosition.dx,
              top: _dragPosition.dy,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTap: _maximizeTimer,
                child: AnimatedBuilder(
                  animation: _dragAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_dragAnimation.value * 0.1),
                      child: Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: _isDarkMode() 
                              ? WorkoutDesignSystem.darkSurfaceElevated
                              : Colors.white,
                          borderRadius: BorderRadius.circular(40.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: _getTimerColor(_remainingSeconds).withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Progress circle
                            SizedBox(
                              width: 40.w,
                              height: 40.w,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: 1.0,
                                    strokeWidth: 3,
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
                                        strokeWidth: 3,
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
                            SizedBox(height: 4.h),
                            Text(
                              _formatTime(_remainingSeconds),
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: _getTimerColor(_remainingSeconds),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
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
            child: Positioned(
              bottom: 100.h,
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
                        color: _isDarkMode() 
                            ? WorkoutDesignSystem.darkSurfaceElevated
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: _getTimerColor(_remainingSeconds).withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header con controlli
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
                                    SizedBox(width: 4.w),
                                    Icon(
                                      Icons.volume_up,
                                      color: _getTimerColor(_remainingSeconds),
                                      size: 16.sp,
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  _getHeaderText(),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: _isDarkMode() 
                                        ? WorkoutDesignSystem.darkTextPrimary
                                        : Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(
                                  minWidth: 24.w,
                                  minHeight: 24.w,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              // Close button
                              IconButton(
                                onPressed: _dismissPopup,
                                icon: Icon(
                                  Icons.close,
                                  color: _isDarkMode() 
                                      ? WorkoutDesignSystem.darkTextSecondary
                                      : Colors.grey[500],
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

                          // Timer principale
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Progress Circle
                              SizedBox(
                                width: 50.w,
                                height: 50.w,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: 1.0,
                                      strokeWidth: 3,
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
                                          strokeWidth: 3,
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

                              SizedBox(width: 20.w),

                              // Timer text
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: _getTimerColor(_remainingSeconds).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: _getTimerColor(_remainingSeconds).withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _formatTime(_remainingSeconds),
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                    color: _getTimerColor(_remainingSeconds),
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
                                      color: _getTimerColor(_remainingSeconds),
                                      size: 20.sp,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: _getTimerColor(_remainingSeconds).withValues(alpha: 0.1),
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
                                      color: _isDarkMode() 
                                          ? WorkoutDesignSystem.darkTextSecondary
                                          : Colors.grey[600],
                                      size: 20.sp,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: _isDarkMode() 
                                          ? WorkoutDesignSystem.darkSurface
                                          : Colors.grey[100],
                                      padding: EdgeInsets.all(6.w),
                                      minimumSize: Size(32.w, 32.w),
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
                ),
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
    if (_isDismissed) return const SizedBox.shrink();

    return BackgroundTimerWrapper(
      initialSeconds: widget.initialSeconds,
      isActive: widget.isActive,
      type: 'recovery',
      title: _getHeaderText(),
      message: widget.isInSuperset 
          ? 'Pausa tra esercizi del superset'
          : 'Riposati e preparati per la prossima serie',
      exerciseName: widget.exerciseName,
      onTimerComplete: widget.onTimerComplete,
      onTimerStopped: widget.onTimerStopped,
      onTimerDismissed: widget.onTimerDismissed,
      builder: (remainingSeconds, isPaused, pauseResume, skip) {
        return Stack(
          children: [
            // Full timer
            if (!_isMinimized) _buildFullTimer(),
            
            // Minimized timer
            if (_isMinimized) _buildMinimizedTimer(),
          ],
        );
      },
    );
  }
}
