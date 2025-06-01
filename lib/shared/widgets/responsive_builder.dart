import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (AppConfig.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (AppConfig.isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}