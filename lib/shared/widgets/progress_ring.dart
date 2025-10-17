// lib/shared/widgets/progress_ring.dart
// ⏱️ PROGRESS RING - Anello progress per timer recupero
// Mobile-optimized

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/workout_design_system.dart';

/// Anello di progresso circolare per timer
class ProgressRing extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = WorkoutDesignSystem.timerProgressRingSize,
    this.strokeWidth = 4.0,
    this.color,
    this.backgroundColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? WorkoutDesignSystem.primary600;
    final effectiveBackgroundColor =
        backgroundColor ?? WorkoutDesignSystem.gray200;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: 1.0,
              color: effectiveBackgroundColor,
              strokeWidth: strokeWidth,
            ),
          ),
          // Progress ring
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: value,
              color: effectiveColor,
              strokeWidth: strokeWidth,
            ),
          ),
          // Content interno
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Disegna arco da -90° (top) in senso orario
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Progress ring con timer interno
class TimerProgressRing extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;
  final double size;

  const TimerProgressRing({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
    this.size = WorkoutDesignSystem.timerProgressRingSize,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0
        ? secondsRemaining / totalSeconds
        : 0.0;
    final color = WorkoutDesignSystem.getTimerColor(secondsRemaining);

    return ProgressRing(
      value: progress,
      size: size,
      strokeWidth: 4.0,
      color: color,
      child: Center(
        child: Text(
          _formatTime(secondsRemaining),
          style: TextStyle(
            fontSize: size * 0.25,
            fontWeight: WorkoutDesignSystem.fontWeightBold,
            fontFamily: WorkoutDesignSystem.fontFamilyNumbers,
            color: color,
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

