// lib/features/gym/widgets/gym_logo_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/gym_logo_model.dart';

class GymLogoWidget extends StatelessWidget {
  final GymLogoModel? gymLogo;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool showFallback;
  final String fallbackText;
  
  const GymLogoWidget({
    super.key,
    this.gymLogo,
    this.width,
    this.height,
    this.onTap,
    this.showFallback = true,
    this.fallbackText = 'FitGymTrack',
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Se non c'è logo o non ha logo personalizzato, mostra fallback
    if (gymLogo == null || !gymLogo!.hasCustomLogo) {
      return showFallback 
        ? _buildFallbackLogo(context, colorScheme)
        : const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: onTap,
      child: _buildCustomLogo(context, colorScheme),
    );
  }
  
  Widget _buildCustomLogo(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: width ?? 120.w,
      height: height ?? 32.h,
      constraints: BoxConstraints(
        maxWidth: width ?? 120.w,
        maxHeight: height ?? 32.h,
      ),
      child: Image.network(
        gymLogo!.logoUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('[GymLogoWidget] ❌ Error loading logo: $error');
          return showFallback 
            ? _buildFallbackLogo(context, colorScheme)
            : const SizedBox.shrink();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          
          return Container(
            width: width ?? 120.w,
            height: height ?? 32.h,
            child: Center(
              child: SizedBox(
                width: 16.w,
                height: 16.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildFallbackLogo(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: width ?? 120.w,
      height: height ?? 32.h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 20.sp,
            color: colorScheme.primary,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              fallbackText,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget per logo con loading state
class GymLogoWidgetWithLoading extends StatefulWidget {
  final Future<GymLogoModel?> gymLogoFuture;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool showFallback;
  final String fallbackText;
  
  const GymLogoWidgetWithLoading({
    super.key,
    required this.gymLogoFuture,
    this.width,
    this.height,
    this.onTap,
    this.showFallback = true,
    this.fallbackText = 'FitGymTrack',
  });
  
  @override
  State<GymLogoWidgetWithLoading> createState() => _GymLogoWidgetWithLoadingState();
}

class _GymLogoWidgetWithLoadingState extends State<GymLogoWidgetWithLoading> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GymLogoModel?>(
      future: widget.gymLogoFuture,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: widget.width ?? 120.w,
            height: widget.height ?? 32.h,
            child: Center(
              child: SizedBox(
                width: 16.w,
                height: 16.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }
        
        // Error state - mostra fallback
        if (snapshot.hasError) {
          print('[GymLogoWidgetWithLoading] ❌ Error loading gym logo: ${snapshot.error}');
          return GymLogoWidget(
            gymLogo: null,
            width: widget.width,
            height: widget.height,
            onTap: widget.onTap,
            showFallback: widget.showFallback,
            fallbackText: widget.fallbackText,
          );
        }
        
        // Success state
        return GymLogoWidget(
          gymLogo: snapshot.data,
          width: widget.width,
          height: widget.height,
          onTap: widget.onTap,
          showFallback: widget.showFallback,
          fallbackText: widget.fallbackText,
        );
      },
    );
  }
}
