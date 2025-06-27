import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_config.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.color,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget cardContent = Container(
      padding: padding ?? EdgeInsets.all(AppConfig.spacingM.w),
      child: child,
    );

    return Container(
      margin: margin,
      child: Card(
        elevation: elevation ?? AppConfig.elevationS,
        color: color ?? colorScheme.surface, // ✅ DINAMICO!
        surfaceTintColor: Colors.transparent, // ✅ RIMUOVE TINT MATERIAL 3
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(AppConfig.radiusM.r),
        ),
        child: onTap != null
            ? InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(AppConfig.radiusM.r),
          child: cardContent,
        )
            : cardContent,
      ),
    );
  }
}