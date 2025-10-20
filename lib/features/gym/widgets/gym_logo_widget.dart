// lib/features/gym/widgets/gym_logo_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    
    //debugPrint('[LOGO] 🎨 [GymLogoWidget] Building logo widget');
    //debugPrint('[LOGO] 🎨 [GymLogoWidget] gymLogo: $gymLogo');
    //debugPrint('[LOGO] 🎨 [GymLogoWidget] hasCustomLogo: ${gymLogo?.hasCustomLogo}');
    //debugPrint('[LOGO] 🎨 [GymLogoWidget] logoUrl: ${gymLogo?.logoUrl}');
    
    // Se non c'è logo o non ha logo personalizzato, mostra fallback
    if (gymLogo == null || !gymLogo!.hasCustomLogo) {
      //debugPrint('[LOGO] 🔄 [GymLogoWidget] Showing fallback logo');
      return showFallback 
        ? _buildFallbackLogo(context, colorScheme)
        : const SizedBox.shrink();
    }
    
    //debugPrint('[LOGO] 🖼️ [GymLogoWidget] Showing custom logo: ${gymLogo!.logoUrl}');
    return GestureDetector(
      onTap: onTap,
      child: _buildCustomLogo(context, colorScheme),
    );
  }
  
  Widget _buildCustomLogo(BuildContext context, ColorScheme colorScheme) {
    // Controlla se è SVG
    final isSvg = gymLogo!.logoFilename?.toLowerCase().endsWith('.svg') ?? false;
    
    if (isSvg) {
      //debugPrint('[LOGO] 🎨 [GymLogoWidget] SVG detected, using SvgPicture.network');
      return Container(
        width: width ?? 200.w,  // Aumentato da 120.w
        height: height ?? 50.h, // Aumentato da 32.h
        constraints: BoxConstraints(
          maxWidth: width ?? 200.w,
          maxHeight: height ?? 50.h,
        ),
        child: SvgPicture.network(
          gymLogo!.logoUrl,
          fit: BoxFit.cover, // Cambiato da contain a cover per riempire meglio
          placeholderBuilder: (context) => Container(
            width: width ?? 200.w,
            height: height ?? 50.h,
            child: Center(
              child: SizedBox(
                width: 16.w,
                height: 16.w,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      );
    }
    
    // Per PNG/JPG usa Image.network
    return Container(
      width: width ?? 200.w,  // Aumentato da 120.w
      height: height ?? 50.h, // Aumentato da 32.h
      constraints: BoxConstraints(
        maxWidth: width ?? 200.w,
        maxHeight: height ?? 50.h,
      ),
      child: Image.network(
        gymLogo!.logoUrl,
        fit: BoxFit.cover, // Cambiato da contain a cover per riempire meglio
        errorBuilder: (context, error, stackTrace) {
          //debugPrint('[LOGO] ❌ [GymLogoWidget] Error loading logo: $error');
          //debugPrint('[LOGO] ❌ [GymLogoWidget] StackTrace: $stackTrace');
          return showFallback 
            ? _buildFallbackLogo(context, colorScheme)
            : const SizedBox.shrink();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          
          return Container(
            width: width ?? 200.w,
            height: height ?? 50.h,
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
      width: width ?? 200.w,
      height: height ?? 50.h,
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
            width: widget.width ?? 200.w,
            height: widget.height ?? 50.h,
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
          //debugPrint('[GymLogoWidgetWithLoading] ❌ Error loading gym logo: ${snapshot.error}');
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
