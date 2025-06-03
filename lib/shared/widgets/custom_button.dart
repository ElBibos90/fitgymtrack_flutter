import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../../core/config/app_config.dart';

enum ButtonType { primary, secondary, outline, text }
enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final buttonHeight = _getButtonHeight();
    final textStyle = _getTextStyle();
    final buttonStyle = _getButtonStyle(isDark, colorScheme);

    Widget buttonChild = _buildButtonContent(textStyle, isDark);

    Widget button = SizedBox(
      height: buttonHeight,
      width: isFullWidth ? double.infinity : null,
      child: _buildButtonWidget(buttonStyle, buttonChild),
    );

    return button;
  }

  double _getButtonHeight() {
    switch (size) {
      case ButtonSize.small:
        return AppConfig.buttonHeightS;
      case ButtonSize.medium:
        return AppConfig.buttonHeightM;
      case ButtonSize.large:
        return AppConfig.buttonHeightL;
    }
  }

  TextStyle _getTextStyle() {
    final fontSize = size == ButtonSize.small ? 14.sp : 16.sp;
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );
  }

  ButtonStyle _getButtonStyle(bool isDark, ColorScheme colorScheme) {
    final primaryColor = isDark ? const Color(0xFF90CAF9) : AppColors.indigo600;
    final onPrimaryColor = isDark ? AppColors.backgroundDark : Colors.white;

    switch (type) {
      case ButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.radiusM),
          ),
        );
      case ButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.green600,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.radiusM),
          ),
        );
      case ButtonType.outline:
        return OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.radiusM),
          ),
        );
      case ButtonType.text:
        return TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.radiusM),
          ),
        );
    }
  }

  Widget _buildButtonContent(TextStyle textStyle, bool isDark) {
    if (isLoading) {
      Color spinnerColor;
      switch (type) {
        case ButtonType.outline:
        case ButtonType.text:
          spinnerColor = isDark ? const Color(0xFF90CAF9) : AppColors.indigo600;
          break;
        case ButtonType.primary:
          spinnerColor = isDark ? AppColors.backgroundDark : Colors.white;
          break;
        case ButtonType.secondary:
          spinnerColor = Colors.white;
          break;
      }

      return SizedBox(
        width: 20.w,
        height: 20.w,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: spinnerColor,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          SizedBox(width: AppConfig.spacingS),
          Text(text, style: textStyle),
        ],
      );
    }

    return Text(text, style: textStyle);
  }

  Widget _buildButtonWidget(ButtonStyle buttonStyle, Widget buttonChild) {
    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
      case ButtonType.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
      case ButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
    }
  }
}