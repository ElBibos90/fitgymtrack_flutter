// lib/shared/widgets/loading_shimmer_widgets.dart - VERSIONE OTTIMIZZATA SENZA SHIMMER PACKAGE

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

/// 🚀 PERFORMANCE OPTIMIZED: Shimmer widgets senza overflow (SENZA PACKAGE SHIMMER)
class OptimizedShimmerWidgets {

  /// 🚀 FIX OVERFLOW: ShimmerRecentActivity ottimizzato
  static Widget recentActivity({double? maxHeight}) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? 143.8, // Rispetta il constraint del parent
        minHeight: 0,
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(), // Non scrollabile
        child: Column(
          mainAxisSize: MainAxisSize.min, // 🚀 FIX: Usa dimensione minima
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShimmerItem(
              height: 60.h,
              width: double.infinity,
              borderRadius: 12.r,
            ),
            SizedBox(height: 8.h),
            _buildShimmerItem(
              height: 60.h,
              width: double.infinity,
              borderRadius: 12.r,
            ),
            // 🚀 FIX: Rimosso terzo item per evitare overflow
            // Solo 2 items invece di 3 per rimanere dentro i constraints
          ],
        ),
      ),
    );
  }

  /// 🚀 PERFORMANCE: Shimmer item ottimizzato e riutilizzabile (SENZA PACKAGE)
  static Widget _buildShimmerItem({
    required double height,
    required double width,
    double? borderRadius,
  }) {
    return _CustomShimmer(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColorsShimmer.shimmerBase,
          borderRadius: BorderRadius.circular(borderRadius ?? 8.r),
        ),
      ),
    );
  }

  /// 🚀 PERFORMANCE: Shimmer per workout cards
  static Widget workoutCard() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: 120.h,
        minHeight: 100.h,
      ),
      child: _CustomShimmer(
        child: Container(
          height: 110.h,
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColorsShimmer.shimmerBase,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 20.h,
                  width: 150.w,
                  decoration: BoxDecoration(
                    color: AppColorsShimmer.shimmerHighlight,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 16.h,
                  width: 100.w,
                  decoration: BoxDecoration(
                    color: AppColorsShimmer.shimmerHighlight,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 14.h,
                      width: 80.w,
                      decoration: BoxDecoration(
                        color: AppColorsShimmer.shimmerHighlight,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    Container(
                      height: 24.h,
                      width: 24.w,
                      decoration: BoxDecoration(
                        color: AppColorsShimmer.shimmerHighlight,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🚀 PERFORMANCE: Shimmer per subscription card
  static Widget subscriptionCard() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: 100.h,
        minHeight: 80.h,
      ),
      child: _CustomShimmer(
        child: Container(
          height: 90.h,
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColorsShimmer.shimmerBase,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  height: 40.h,
                  width: 40.w,
                  decoration: BoxDecoration(
                    color: AppColorsShimmer.shimmerHighlight,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 18.h,
                        width: 120.w,
                        decoration: BoxDecoration(
                          color: AppColorsShimmer.shimmerHighlight,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        height: 14.h,
                        width: 80.w,
                        decoration: BoxDecoration(
                          color: AppColorsShimmer.shimmerHighlight,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🚀 PERFORMANCE: Shimmer list ottimizzato
  static Widget listItems({
    required int itemCount,
    double itemHeight = 80,
    double? maxHeight,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? (itemHeight * itemCount),
        minHeight: 0,
      ),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true, // 🚀 FIX: Importante per evitare overflow
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            height: itemHeight.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: _buildShimmerItem(
              height: itemHeight.h,
              width: double.infinity,
              borderRadius: 8.r,
            ),
          );
        },
      ),
    );
  }

  /// 🚀 PERFORMANCE: Shimmer grid ottimizzato
  static Widget gridItems({
    required int itemCount,
    int crossAxisCount = 2,
    double itemHeight = 120,
    double? maxHeight,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? (itemHeight * (itemCount / crossAxisCount).ceil()),
        minHeight: 0,
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return _buildShimmerItem(
            height: itemHeight.h,
            width: double.infinity,
            borderRadius: 12.r,
          );
        },
      ),
    );
  }

  /// 🚀 PERFORMANCE: Shimmer per stats charts
  static Widget statsChart() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: 200.h,
        minHeight: 150.h,
      ),
      child: _CustomShimmer(
        child: Container(
          height: 180.h,
          margin: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColorsShimmer.shimmerBase,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 20.h,
                  width: 100.w,
                  decoration: BoxDecoration(
                    color: AppColorsShimmer.shimmerHighlight,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (index) {
                      return Container(
                        width: 20.w,
                        height: (50 + (index * 15)).h,
                        decoration: BoxDecoration(
                          color: AppColorsShimmer.shimmerHighlight,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      );
                    }),
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

/// 🚀 CUSTOM SHIMMER IMPLEMENTATION (senza package esterno)
class _CustomShimmer extends StatefulWidget {
  final Widget child;

  const _CustomShimmer({required this.child});

  @override
  State<_CustomShimmer> createState() => _CustomShimmerState();
}

class _CustomShimmerState extends State<_CustomShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [
                AppColorsShimmer.shimmerBase,
                AppColorsShimmer.shimmerHighlight,
                AppColorsShimmer.shimmerBase,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// 🚀 PERFORMANCE: Extension per colori shimmer ottimizzati
extension AppColorsShimmer on AppColors {
  static Color get shimmerBase =>
      AppColors.surfaceLight.withValues(alpha: 0.3);

  static Color get shimmerHighlight =>
      AppColors.surfaceLight.withValues(alpha: 0.1);
}

// ============================================================================
// 🚀 LEGACY COMPATIBILITY: Wrapper per mantenere compatibilità
// ============================================================================

/// Wrapper per mantenere compatibilità con codice esistente
class ShimmerRecentActivity extends StatelessWidget {
  const ShimmerRecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedShimmerWidgets.recentActivity(
      maxHeight: 143.8, // 🚀 FIX: Constraint specifico dal log
    );
  }
}

/// Shimmer dashboard esistente (mantenuto per compatibilità)
class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: 20.h),
              OptimizedShimmerWidgets.subscriptionCard(),
              SizedBox(height: 16.h),
              OptimizedShimmerWidgets.gridItems(
                itemCount: 4,
                crossAxisCount: 2,
                maxHeight: 160.h,
              ),
              SizedBox(height: 20.h),
              OptimizedShimmerWidgets.recentActivity(maxHeight: 143.8),
              SizedBox(height: 20.h),
              OptimizedShimmerWidgets.statsChart(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shimmer per workout plans (mantenuto per compatibilità)
class ShimmerWorkoutPlans extends StatelessWidget {
  const ShimmerWorkoutPlans({super.key});

  @override
  Widget build(BuildContext context) {
    return OptimizedShimmerWidgets.listItems(
      itemCount: 5,
      itemHeight: 120,
      maxHeight: 600.h,
    );
  }
}

/// Shimmer per subscription screen (mantenuto per compatibilità)
class ShimmerSubscription extends StatelessWidget {
  const ShimmerSubscription({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OptimizedShimmerWidgets.subscriptionCard(),
        SizedBox(height: 20.h),
        OptimizedShimmerWidgets.gridItems(
          itemCount: 3,
          crossAxisCount: 1,
          maxHeight: 300.h,
        ),
      ],
    );
  }
}

/// 🚀 NUOVO: Shimmer per achievements page (era mancante)
class ShimmerAchievementsPage extends StatelessWidget {
  const ShimmerAchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: 20.h),
              // Header stats shimmer
              OptimizedShimmerWidgets.gridItems(
                itemCount: 3,
                crossAxisCount: 3,
                maxHeight: 100.h,
              ),
              SizedBox(height: 20.h),
              // Achievements list shimmer
              OptimizedShimmerWidgets.listItems(
                itemCount: 6,
                itemHeight: 80,
                maxHeight: 480.h,
              ),
            ],
          ),
        ),
      ],
    );
  }
}