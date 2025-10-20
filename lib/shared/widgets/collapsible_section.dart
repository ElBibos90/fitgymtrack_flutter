// lib/shared/widgets/collapsible_section.dart
// 📱 COLLAPSIBLE SECTION - Sezione espandibile per risparmiare spazio mobile
// Per storico, note trainer, etc.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/workout_design_system.dart';

/// Sezione collapsible per ottimizzare spazio mobile
class CollapsibleSection extends StatefulWidget {
  final String title;
  final IconData? icon;
  final Widget collapsedChild;
  final Widget expandedChild;
  final double collapsedHeight;
  final double? expandedHeight;
  final bool initiallyExpanded;
  final Color? headerColor;
  final VoidCallback? onToggle;

  const CollapsibleSection({
    super.key,
    required this.title,
    this.icon,
    required this.collapsedChild,
    required this.expandedChild,
    this.collapsedHeight = WorkoutDesignSystem.noteTrainerCollapsedHeight,
    this.expandedHeight,
    this.initiallyExpanded = false,
    this.headerColor,
    this.onToggle,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _controller = AnimationController(
      duration: WorkoutDesignSystem.animationNormal,
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5, // 180 degrees
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });

    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: WorkoutDesignSystem.mobileHorizontalPadding.w,
        vertical: WorkoutDesignSystem.spacingXS.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: WorkoutDesignSystem.borderRadiusM,
        boxShadow: WorkoutDesignSystem.shadowLevel1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header cliccabile
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(WorkoutDesignSystem.radiusM),
                bottom: _isExpanded
                    ? Radius.zero
                    : Radius.circular(WorkoutDesignSystem.radiusM),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: WorkoutDesignSystem.spacingM.w,
                  vertical: WorkoutDesignSystem.spacingS.h,
                ),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.headerColor ?? WorkoutDesignSystem.primary600,
                        size: 20.sp,
                      ),
                      SizedBox(width: WorkoutDesignSystem.spacingXS.w),
                    ],
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: WorkoutDesignSystem.fontSizeH3.sp,
                          fontWeight: WorkoutDesignSystem.fontWeightSemiBold,
                          color: WorkoutDesignSystem.gray900,
                        ),
                      ),
                    ),
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: WorkoutDesignSystem.gray700,
                        size: 24.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider
          Container(
            height: 2,
            margin: EdgeInsets.symmetric(
              horizontal: WorkoutDesignSystem.spacingM.w,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (widget.headerColor ?? WorkoutDesignSystem.primary600)
                      .withValues(alpha: 0.3),
                  widget.headerColor ?? WorkoutDesignSystem.primary600,
                  (widget.headerColor ?? WorkoutDesignSystem.primary600)
                      .withValues(alpha: 0.3),
                ],
              ),
            ),
          ),

          // Content animato
          AnimatedSize(
            duration: WorkoutDesignSystem.animationNormal,
            curve: Curves.easeInOut,
            child: Container(
              padding: EdgeInsets.all(WorkoutDesignSystem.spacingM.w),
              child: _isExpanded ? widget.expandedChild : widget.collapsedChild,
            ),
          ),

          // Bottone "Mostra tutto" / "Nascondi"
          if (!_isExpanded || widget.expandedHeight != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggle,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(WorkoutDesignSystem.radiusM),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: WorkoutDesignSystem.spacingXS.h,
                  ),
                  decoration: BoxDecoration(
                    color: WorkoutDesignSystem.gray50,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(WorkoutDesignSystem.radiusM),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _isExpanded ? 'Nascondi' : 'Mostra tutto',
                      style: TextStyle(
                        fontSize: WorkoutDesignSystem.fontSizeCaption.sp,
                        fontWeight: WorkoutDesignSystem.fontWeightMedium,
                        color: widget.headerColor ?? WorkoutDesignSystem.primary600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

