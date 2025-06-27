// 🔧 AUTOFILL UPDATE: CustomTextField con supporto completo per autofill Android
// File: lib/shared/widgets/custom_text_field.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final bool enabled;
  final int maxLines;
  final VoidCallback? onTap;
  final bool readOnly;

  // 🔧 AUTOFILL: Nuovi parametri per supporto autofill
  final Iterable<String>? autofillHints;
  final bool enableSuggestions;
  final VoidCallback? onEditingComplete;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.onTap,
    this.readOnly = false,
    // 🔧 AUTOFILL: Parametri opzionali per backward compatibility
    this.autofillHints,
    this.enableSuggestions = true,
    this.onEditingComplete,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      onTap: widget.onTap,
      readOnly: widget.readOnly,

      // 🔧 AUTOFILL: Configurazione completa autofill
      autofillHints: widget.autofillHints,
      enableSuggestions: widget.enableSuggestions,
      onEditingComplete: widget.onEditingComplete,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,

      // 🔧 AUTOFILL: Configurazione smartdashes e smartquotes per password
      smartDashesType: widget.isPassword ? SmartDashesType.disabled : SmartDashesType.enabled,
      smartQuotesType: widget.isPassword ? SmartQuotesType.disabled : SmartQuotesType.enabled,

      style: TextStyle(
        fontSize: 16.sp,
        color: colorScheme.onSurface, // ✅ DINAMICO!
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6), // ✅ DINAMICO!
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.8), // ✅ DINAMICO!
        ),
        prefixIcon: Icon(
          widget.prefixIcon,
          color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600, // ✅ DINAMICO!
          size: 20.sp,
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            color: colorScheme.onSurface.withValues(alpha: 0.6), // ✅ DINAMICO!
            size: 20.sp,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: colorScheme.outline, // ✅ DINAMICO!
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: colorScheme.outline, // ✅ DINAMICO!
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600, // ✅ DINAMICO!
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: colorScheme.error, // ✅ DINAMICO!
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: colorScheme.error, // ✅ DINAMICO!
            width: 2.0,
          ),
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF2C2C2C) // ✅ TEMA SCURO
            : const Color(0xFFF5F5F5), // ✅ TEMA CHIARO
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 16.h,
        ),
      ),
    );
  }
}