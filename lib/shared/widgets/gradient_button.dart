// lib/shared/widgets/gradient_button.dart
// 🎨 GRADIENT BUTTON - Bottone moderno con gradient e animazioni
// Mobile-optimized con touch target 44px minimum

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/workout_design_system.dart';

/// Bottone moderno con gradient, shadows e animazioni
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final double? width;
  final double height;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final TextStyle? textStyle;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.width,
    this.height = WorkoutDesignSystem.buttonHeightPrimary,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.textStyle,
  });

  /// Bottone primario (Hero - Completa Serie)
  factory GradientButton.primary({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      gradient: WorkoutDesignSystem.primaryGradient,
      height: WorkoutDesignSystem.buttonHeightPrimary,
      icon: icon,
      isLoading: isLoading,
      textStyle: const TextStyle(
        fontSize: WorkoutDesignSystem.fontSizeH2,
        fontWeight: WorkoutDesignSystem.fontWeightBold,
        color: Colors.white,
      ),
    );
  }

  /// Bottone success (Completamento)
  factory GradientButton.success({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      gradient: WorkoutDesignSystem.successGradient,
      height: WorkoutDesignSystem.buttonHeightPrimary,
      icon: icon,
      textStyle: const TextStyle(
        fontSize: WorkoutDesignSystem.fontSizeH2,
        fontWeight: WorkoutDesignSystem.fontWeightBold,
        color: Colors.white,
      ),
    );
  }

  /// Bottone superset (per superset/circuit)
  factory GradientButton.superset({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      gradient: WorkoutDesignSystem.supersetGradient,
      height: WorkoutDesignSystem.buttonHeightPrimary,
      icon: icon,
      textStyle: const TextStyle(
        fontSize: WorkoutDesignSystem.fontSizeH2,
        fontWeight: WorkoutDesignSystem.fontWeightBold,
        color: Colors.white,
      ),
    );
  }

  /// Bottone secondario (compatto)
  factory GradientButton.secondary({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      gradient: null, // Nessun gradient
      height: WorkoutDesignSystem.buttonHeightSecondary,
      icon: icon,
      textStyle: TextStyle(
        fontSize: WorkoutDesignSystem.fontSizeBody,
        fontWeight: WorkoutDesignSystem.fontWeightMedium,
        color: WorkoutDesignSystem.primary600,
      ),
    );
  }

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: WorkoutDesignSystem.animationFast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isDisabled || widget.isLoading) return;
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isDisabled || widget.isLoading) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.isDisabled || widget.isLoading) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.isDisabled || widget.isLoading || widget.onPressed == null;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: isDisabled
                ? const LinearGradient(
                    colors: [
                      WorkoutDesignSystem.gray200,
                      WorkoutDesignSystem.gray400,
                    ],
                  )
                : widget.gradient,
            color: widget.gradient == null && !isDisabled
                ? WorkoutDesignSystem.gray100
                : null,
            borderRadius: WorkoutDesignSystem.borderRadiusM,
            boxShadow: isDisabled || _isPressed
                ? null
                : WorkoutDesignSystem.shadowLevel3,
            border: widget.gradient == null
                ? Border.all(
                    color: WorkoutDesignSystem.primary600,
                    width: 1.5,
                  )
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: widget.textStyle?.color ?? Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: WorkoutDesignSystem.spacingXS),
                      ],
                      Text(
                        widget.text,
                        style: widget.textStyle?.copyWith(
                          color: isDisabled
                              ? WorkoutDesignSystem.gray400
                              : widget.textStyle?.color,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

