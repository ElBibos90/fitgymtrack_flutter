// lib/shared/widgets/recovery_timer_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🔧 Per HapticFeedback
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

/// 🚀 STEP 2: Recovery Timer Cross-Platform Widget
/// ✅ Auto-countdown con audio feedback
/// ✅ Vibrazione negli ultimi 3 secondi
/// ✅ UI dinamica che cambia colore
/// ✅ Skip/Stop controls
/// ✅ Compatibile Android + iOS
class RecoveryTimerWidget extends StatefulWidget {
  final int initialSeconds;
  final bool isActive;
  final VoidCallback onTimerComplete;
  final VoidCallback onTimerStopped;
  final String? exerciseName;

  const RecoveryTimerWidget({
    super.key,
    required this.initialSeconds,
    required this.isActive,
    required this.onTimerComplete,
    required this.onTimerStopped,
    this.exerciseName,
  });

  @override
  State<RecoveryTimerWidget> createState() => _RecoveryTimerWidgetState();
}

class _RecoveryTimerWidgetState extends State<RecoveryTimerWidget>
    with TickerProviderStateMixin {

  // Timer state
  Timer? _countdown;
  int _remainingSeconds = 0;
  bool _isRunning = false;

  // Audio player per feedback sonoro
  late AudioPlayer _audioPlayer;

  // Animation per effetti visivi
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
    _audioPlayer = AudioPlayer();

    // Setup animazioni
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Auto-start se attivo
    if (widget.isActive) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(RecoveryTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset se cambiano i secondi
    if (oldWidget.initialSeconds != widget.initialSeconds) {
      _remainingSeconds = widget.initialSeconds;
      if (_isRunning) {
        _stopTimer();
        if (widget.isActive) {
          _startTimer();
        }
      }
    }

    // Auto-start/stop basato su isActive
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive && !_isRunning) {
        _startTimer();
      } else if (!widget.isActive && _isRunning) {
        _stopTimer();
      }
    }
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ============================================================================
  // TIMER LOGIC
  // ============================================================================

  void _startTimer() {
    if (_isRunning) return;

    debugPrint("🔄 [RECOVERY TIMER] Starting timer: $_remainingSeconds seconds");

    setState(() {
      _isRunning = true;
    });

    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });

        // 🔊 Audio feedback negli ultimi 3 secondi
        if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
          _playCountdownBeep();
          _triggerPulseAnimation();
          _triggerVibration();
        }

        // ⏰ Timer completato
        if (_remainingSeconds == 0) {
          _onTimerFinished();
        }
      }
    });
  }

  void _stopTimer() {
    debugPrint("⏹️ [RECOVERY TIMER] Timer stopped");

    _countdown?.cancel();
    _countdown = null;

    setState(() {
      _isRunning = false;
    });

    _pulseController.stop();
    widget.onTimerStopped();
  }

  void _onTimerFinished() {
    debugPrint("✅ [RECOVERY TIMER] Timer completed!");

    _countdown?.cancel();
    _countdown = null;

    setState(() {
      _isRunning = false;
    });

    // 🔊 Suono finale più forte
    _playCompletionSound();
    _triggerVibration(isCompletion: true);

    // Callback completamento
    widget.onTimerComplete();
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _remainingSeconds = widget.initialSeconds;
    });
  }

  // ============================================================================
  // AUDIO & HAPTIC FEEDBACK
  // ============================================================================

  void _playCountdownBeep() async {
    try {
      // 🔇 TEMP: Disabilitato audio finché non aggiungiamo assets
      // await _audioPlayer.play(AssetSource('audio/beep_countdown.mp3'));
      debugPrint("🔊 [AUDIO] Countdown beep (audio disabled temporarily)");
    } catch (e) {
      debugPrint("🔊 [AUDIO] Countdown beep not available: $e");
    }
  }

  void _playCompletionSound() async {
    try {
      // 🔇 TEMP: Disabilitato audio finché non aggiungiamo assets
      // await _audioPlayer.play(AssetSource('audio/timer_complete.mp3'));
      debugPrint("🔊 [AUDIO] Completion sound (audio disabled temporarily)");
    } catch (e) {
      debugPrint("🔊 [AUDIO] Completion sound not available: $e");
    }
  }

  void _triggerVibration({bool isCompletion = false}) async {
    try {
      if (isCompletion) {
        // 📳 Vibrazione più forte per completamento
        await HapticFeedback.heavyImpact();
        // Doppia vibrazione per completamento
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.heavyImpact();
        });
      } else {
        // 📳 Vibrazione leggera per countdown
        await HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint("📳 [HAPTIC] Error: $e");
    }
  }

  void _triggerPulseAnimation() {
    if (_pulseController.isAnimating) return;

    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
  }

  // ============================================================================
  // UI HELPERS
  // ============================================================================

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (!_isRunning) return Colors.grey;
    if (_remainingSeconds <= 3) return Colors.red;
    if (_remainingSeconds <= 10) return Colors.orange;
    return Colors.blue;
  }

  IconData _getTimerIcon() {
    if (!_isRunning) return Icons.timer_off;
    if (_remainingSeconds <= 3) return Icons.priority_high;
    return Icons.timer;
  }

  String _getStatusText() {
    if (!_isRunning && _remainingSeconds == 0) return "Recupero completato!";
    if (!_isRunning) return "Recupero in pausa";
    if (_remainingSeconds <= 3) return "COUNTDOWN FINALE!";
    return "Recupero in corso...";
  }

  // ============================================================================
  // BUILD UI
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final timerColor = _getTimerColor();
    final isWarning = _remainingSeconds <= 3 && _isRunning;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isWarning ? _pulseAnimation.value : 1.0,
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isWarning
                    ? [Colors.red.withOpacity(0.8), Colors.red.withOpacity(0.6)]
                    : [timerColor.withOpacity(0.8), timerColor.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: timerColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header con icona e status
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        _getTimerIcon(),
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusText(),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (widget.exerciseName != null) ...[
                            SizedBox(height: 2.h),
                            Text(
                              widget.exerciseName!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Timer display centrale
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 48.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Reset button
                    _buildActionButton(
                      icon: Icons.refresh,
                      label: 'Reset',
                      onPressed: _resetTimer,
                      isSecondary: true,
                    ),

                    // Start/Pause button
                    _buildActionButton(
                      icon: _isRunning ? Icons.pause : Icons.play_arrow,
                      label: _isRunning ? 'Pausa' : 'Avvia',
                      onPressed: _isRunning ? _stopTimer : _startTimer,
                      isSecondary: false,
                    ),

                    // Skip button
                    _buildActionButton(
                      icon: Icons.skip_next,
                      label: 'Salta',
                      onPressed: () {
                        _stopTimer();
                        widget.onTimerComplete(); // Considera come completato
                      },
                      isSecondary: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isSecondary,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20.sp),
      label: Text(
        label,
        style: TextStyle(fontSize: 12.sp),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary
            ? Colors.white.withOpacity(0.2)
            : Colors.white,
        foregroundColor: isSecondary
            ? Colors.white
            : _getTimerColor(),
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }
}