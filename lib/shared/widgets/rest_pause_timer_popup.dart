// 🚀 STEP 3: REST-PAUSE Timer Mini-Recupero Dedicato
// File: lib/shared/widgets/rest_pause_timer_popup.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/di/dependency_injection.dart';
import '../../core/services/audio_settings_service.dart';

/// Popup timer dedicato per mini-recupero REST-PAUSE
/// Design differenziato dal timer normale con feedback specifici
class RestPauseTimerPopup extends StatefulWidget {
  final int initialSeconds; // Secondi totali (es. 21)
  final String exerciseName; // Nome esercizio
  final int currentMicroSeries; // Micro-serie corrente (1, 2, 3...)
  final int totalMicroSeries; // Totale micro-serie
  final int nextTargetReps; // Ripetizioni prossima micro-serie
  final VoidCallback onTimerComplete; // Callback quando timer finisce
  final VoidCallback? onSkip; // Callback quando si salta
  final VoidCallback? onPause; // Callback quando si mette in pausa

  const RestPauseTimerPopup({
    Key? key,
    required this.initialSeconds,
    required this.exerciseName,
    required this.currentMicroSeries,
    required this.totalMicroSeries,
    required this.nextTargetReps,
    required this.onTimerComplete,
    this.onSkip,
    this.onPause,
  }) : super(key: key);

  @override
  State<RestPauseTimerPopup> createState() => _RestPauseTimerPopupState();
}

class _RestPauseTimerPopupState extends State<RestPauseTimerPopup>
    with TickerProviderStateMixin {

  // ====== TIMER STATE ======
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isPaused = false;
  bool _isFinished = false;

  // 🔊 Audio management
  late AudioPlayer _audioPlayer;
  late AudioSettingsService _audioSettings;
  bool _hasPlayedCompletionSound = false;

  // ====== ANIMATION CONTROLLERS ======
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _breathController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    //print('⚡ [REST-PAUSE TIMER] Starting timer: ${widget.initialSeconds}s');

    _remainingSeconds = widget.initialSeconds;
    _audioPlayer = AudioPlayer();
    _audioSettings = getIt<AudioSettingsService>();
    
    // ✅ FIXED: Configura AudioContext una sola volta per tutto il timer
    _configureAudioContext();
    
    _initializeAnimations();
    _startTimer();
  }

  // ✅ FIXED: Configura AudioContext una sola volta
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
      print("🔊 [REST PAUSE AUDIO] AudioContext configured for ducking");
    } catch (e) {
      print("🔊 [REST PAUSE AUDIO] Error configuring AudioContext: $e");
    }
  }

  // 🔧 FIX: Method to restore audio session after timer completion
  Future<void> _restoreAudioSession() async {
    try {
      // 🔧 NEW APPROACH: Disable ducking explicitly by reconfiguring AudioContext
      // without duckOthers option to allow music to restore
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
            // 🔧 REMOVED: AVAudioSessionOptions.duckOthers to stop ducking
          },
        ),
      ));
      
      // Force a brief pause to let the system process the audio context change
      await Future.delayed(const Duration(milliseconds: 200));
      
      print("🔊 [REST PAUSE AUDIO] Audio session restored - ducking disabled");
    } catch (e) {
      print("🔊 [REST PAUSE AUDIO] Error restoring audio session: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  // ====== INITIALIZATION ======

  void _initializeAnimations() {
    // Pulse animation per il timer
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Progress animation per la barra
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Breathing animation per relax effect
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _breathAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // Start animations
    _pulseController.repeat(reverse: true);
    _breathController.repeat(reverse: true);
  }

  // 🔊 Audio methods
  Future<void> _playCountdownBeep() async {
    try {
      // ✅ FIXED: Controlla impostazioni audio
      if (!_audioSettings.timerSoundsEnabled) {
        return; // Audio disabilitato
      }

      // ✅ FIXED: Applica volume dalle impostazioni (assicurati che sia > 0)
      final volume = (_audioSettings.beepVolume / 100.0).clamp(0.1, 1.0);
      await _audioPlayer.setVolume(volume);

      print("🔊 [REST PAUSE AUDIO] Playing countdown beep (volume: $volume, enabled: ${_audioSettings.timerSoundsEnabled})");
      await _audioPlayer.play(AssetSource('audio/beep_countdown.mp3'));
    } catch (e) {
      print("🔊 [REST PAUSE AUDIO] Error playing countdown beep: $e");
    }
  }

  Future<void> _playCompletionSound() async {
    try {
      if (!_hasPlayedCompletionSound) {
        // ✅ FIXED: Controlla impostazioni audio
        if (!_audioSettings.timerSoundsEnabled) {
          return; // Audio disabilitato
        }

        print("🔊 [REST PAUSE AUDIO] Playing completion sound");
        _hasPlayedCompletionSound = true;

        // ✅ FIXED: Applica volume dalle impostazioni (assicurati che sia > 0)
        final volume = (_audioSettings.beepVolume / 100.0).clamp(0.1, 1.0);
        await _audioPlayer.setVolume(volume);

        // 🔧 FIX: Aspetta che l'audio finisca davvero
        await _audioPlayer.play(AssetSource('audio/timer_complete.mp3'));

        // Piccolo delay extra per sicurezza
        await Future.delayed(const Duration(milliseconds: 900));

        print("🔊 [REST PAUSE AUDIO] Completion sound finished");
      }
    } catch (e) {
      print("🔊 [REST PAUSE AUDIO] Error playing completion sound: $e");
    }
  }

  // ====== TIMER LOGIC ======

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });

        _updateProgress();
        _handleTimerEvents();

      } else if (_remainingSeconds <= 0) {
        _completeTimer();
      }
    });
  }

  void _updateProgress() {
    final progress = 1.0 - (_remainingSeconds / widget.initialSeconds);
    _progressController.animateTo(progress);
  }

  void _handleTimerEvents() {
    // 🔊 Audio + Haptic feedback agli ultimi 3 secondi
    if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
      if (_audioSettings.hapticFeedbackEnabled) {
        HapticFeedback.lightImpact();
      }
      _playCountdownBeep(); // ✅ FIXED: Aggiunto audio countdown
    }

    // Feedback a metà tempo
    if (_remainingSeconds == (widget.initialSeconds / 2).round()) {
      if (_audioSettings.hapticFeedbackEnabled) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _completeTimer() {
    //print('⚡ [REST-PAUSE TIMER] Timer completed');

    setState(() {
      _isFinished = true;
      _remainingSeconds = 0;
    });

    _timer?.cancel();
    _pulseController.stop();

    // 🔊 Audio + Haptic feedback finale
    if (_audioSettings.hapticFeedbackEnabled) {
      HapticFeedback.heavyImpact();
    }
    _playCompletionSound(); // ✅ FIXED: Aggiunto audio completion

    // 🔧 FIX: Restore audio session after completion
    _restoreAudioSession();

    // Auto-close dopo 1 secondo
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        widget.onTimerComplete();
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _pulseController.stop();
      _breathController.stop();
    } else {
      _pulseController.repeat(reverse: true);
      _breathController.repeat(reverse: true);
    }

    //print('⚡ [REST-PAUSE TIMER] Timer ${_isPaused ? "paused" : "resumed"}');
    widget.onPause?.call();
  }

  void _skipTimer() {
    //print('⚡ [REST-PAUSE TIMER] Timer skipped');

    _timer?.cancel();
    widget.onSkip?.call();
  }

  // ====== UI HELPERS ======

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progressValue {
    return widget.initialSeconds > 0
        ? 1.0 - (_remainingSeconds / widget.initialSeconds)
        : 1.0;
  }

  Color get _currentColor {
    if (_isFinished) return Colors.green;
    if (_remainingSeconds <= 5) return Colors.red;
    if (_remainingSeconds <= 10) return Colors.deepOrange;
    return Colors.orange;
  }

  // ====== UI BUILD ======

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: _buildTimerContent(),
    );
  }

  Widget _buildTimerContent() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _currentColor.withValues(alpha:0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _currentColor.withValues(alpha:0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          SizedBox(height: 20.h),
          _buildTimerDisplay(),
          SizedBox(height: 20.h),
          _buildProgressBar(),
          SizedBox(height: 20.h),
          _buildNextInfo(),
          SizedBox(height: 24.h),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: _currentColor.withValues(alpha:0.2),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: _currentColor.withValues(alpha:0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flash_on,
                color: _currentColor,
                size: 16.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                'MINI-RECUPERO REST-PAUSE',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: _currentColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          widget.exerciseName,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTimerDisplay() {
    if (_isFinished) {
      return _buildFinishedDisplay();
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPaused ? 1.0 : _pulseAnimation.value,
          child: AnimatedBuilder(
            animation: _breathAnimation,
            builder: (context, child) {
              return Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentColor.withValues(alpha:0.1),
                  border: Border.all(
                    color: _currentColor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _currentColor.withValues(alpha:_breathAnimation.value * 0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isPaused) ...[
                        Icon(
                          Icons.pause,
                          color: _currentColor,
                          size: 32.sp,
                        ),
                      ] else ...[
                        Text(
                          _formattedTime,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: _currentColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFinishedDisplay() {
    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green.withValues(alpha:0.2),
        border: Border.all(color: Colors.green, width: 3),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 40.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              'PRONTO!',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white70,
              ),
            ),
            Text(
              '${(_progressValue * 100).round()}%',
              style: TextStyle(
                fontSize: 12.sp,
                color: _currentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        LinearProgressIndicator(
          value: _progressValue,
          backgroundColor: Colors.grey.withValues(alpha:0.3),
          valueColor: AlwaysStoppedAnimation<Color>(_currentColor),
          minHeight: 6.h,
        ),
      ],
    );
  }

  Widget _buildNextInfo() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.deepPurple.withValues(alpha:0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Prossima micro-serie',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.currentMicroSeries}/${widget.totalMicroSeries}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              Text(
                ' • ',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white70,
                ),
              ),
              Text(
                '${widget.nextTargetReps} reps',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isFinished) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.onTimerComplete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            'CONTINUA',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _skipTimer,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _currentColor),
              foregroundColor: _currentColor,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'SALTA',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton(
            onPressed: _pauseTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              _isPaused ? 'RIPRENDI' : 'PAUSA',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 🚀 STEP 3: Helper per mostrare il timer popup
class RestPauseTimerHelper {
  /// Mostra il timer popup REST-PAUSE
  static Future<void> showRestPauseTimer({
    required BuildContext context,
    required int seconds,
    required String exerciseName,
    required int currentMicroSeries,
    required int totalMicroSeries,
    required int nextTargetReps,
    required VoidCallback onComplete,
    VoidCallback? onSkip,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha:0.8),
      builder: (context) => RestPauseTimerPopup(
        initialSeconds: seconds,
        exerciseName: exerciseName,
        currentMicroSeries: currentMicroSeries,
        totalMicroSeries: totalMicroSeries,
        nextTargetReps: nextTargetReps,
        onTimerComplete: () {
          Navigator.of(context).pop();
          onComplete();
        },
        onSkip: () {
          Navigator.of(context).pop();
          onSkip?.call();
        },
      ),
    );
  }
}

/// 🚀 STEP 3: Screen di test per il timer isolato
class RestPauseTimerTestScreen extends StatelessWidget {
  const RestPauseTimerTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REST-PAUSE Timer Test'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Test Timer Mini-Recupero',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40.h),
            ElevatedButton(
              onPressed: () {
                RestPauseTimerHelper.showRestPauseTimer(
                  context: context,
                  seconds: 15,
                  exerciseName: 'Dips assistiti',
                  currentMicroSeries: 2,
                  totalMicroSeries: 3,
                  nextTargetReps: 4,
                  onComplete: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Timer completato!')),
                    );
                  },
                  onSkip: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Timer saltato!')),
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
              ),
              child: Text(
                'TEST TIMER 15s',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () {
                RestPauseTimerHelper.showRestPauseTimer(
                  context: context,
                  seconds: 5,
                  exerciseName: 'Test Veloce',
                  currentMicroSeries: 1,
                  totalMicroSeries: 2,
                  nextTargetReps: 8,
                  onComplete: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Timer veloce completato!')),
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
              ),
              child: Text(
                'TEST VELOCE 5s',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}