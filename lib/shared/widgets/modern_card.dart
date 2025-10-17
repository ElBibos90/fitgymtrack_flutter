// lib/shared/widgets/modern_card.dart
// 🎨 MODERN CARD - Widget base con shadows e gradient
// Mobile-optimized

import 'package:flutter/material.dart';
import '../theme/workout_design_system.dart';

/// Modern Card con shadow, gradient e radius personalizzabili
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Gradient? gradient;
  final List<BoxShadow>? shadows;
  final BorderRadius? borderRadius;
  final Border? border;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.gradient,
    this.shadows,
    this.borderRadius,
    this.border,
    this.width,
    this.height,
    this.onTap,
  });

  /// Card standard (Level 1 shadow)
  factory ModernCard.standard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) {
    return ModernCard(
      padding: padding ?? const EdgeInsets.all(WorkoutDesignSystem.spacingL),
      backgroundColor: Colors.white,
      shadows: WorkoutDesignSystem.shadowLevel1,
      borderRadius: WorkoutDesignSystem.borderRadiusM,
      onTap: onTap,
      child: child,
    );
  }

  /// Card elevata (Level 2 shadow)
  factory ModernCard.elevated({
    required Widget child,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) {
    return ModernCard(
      padding: padding ?? const EdgeInsets.all(WorkoutDesignSystem.spacingL),
      backgroundColor: Colors.white,
      shadows: WorkoutDesignSystem.shadowLevel2,
      borderRadius: WorkoutDesignSystem.borderRadiusL,
      onTap: onTap,
      child: child,
    );
  }

  /// Card con gradient
  factory ModernCard.gradient({
    required Widget child,
    required Gradient gradient,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) {
    return ModernCard(
      padding: padding ?? const EdgeInsets.all(WorkoutDesignSystem.spacingL),
      gradient: gradient,
      shadows: WorkoutDesignSystem.shadowLevel1,
      borderRadius: WorkoutDesignSystem.borderRadiusM,
      onTap: onTap,
      child: child,
    );
  }

  /// Card compatta (per peso/reps)
  factory ModernCard.compact({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return ModernCard(
      padding: const EdgeInsets.all(WorkoutDesignSystem.spacingS),
      backgroundColor: Colors.white,
      shadows: WorkoutDesignSystem.shadowLevel1,
      borderRadius: WorkoutDesignSystem.borderRadiusM,
      width: WorkoutDesignSystem.weightRepsCardWidth,
      height: WorkoutDesignSystem.weightRepsCardHeight,
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: gradient,
        borderRadius: borderRadius ?? WorkoutDesignSystem.borderRadiusM,
        boxShadow: shadows,
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? WorkoutDesignSystem.borderRadiusM,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

