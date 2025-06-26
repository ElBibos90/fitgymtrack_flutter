// lib/shared/widgets/loading_shimmer_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget shimmer base per effetti di caricamento
class ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool enabled;

  const ShimmerWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.grey,
                Colors.white,
                Colors.grey,
              ],
              stops: [
                (_animation.value - 0.5).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.5).clamp(0.0, 1.0),
              ],
              transform: GradientRotation(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer placeholder per contenuto generico
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? color;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
        borderRadius: borderRadius ?? BorderRadius.circular(4.r),
      ),
    );
  }
}

/// Shimmer per card generiche
class ShimmerCard extends StatelessWidget {
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const ShimmerCard({
    super.key,
    this.height,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ShimmerWidget(
      child: Container(
        height: height ?? 70.h, // 🔧 FIX: Ridotta da 80h a 70h per risparmiare spazio
        margin: margin ?? EdgeInsets.symmetric(horizontal: 20.w),
        padding: padding ?? EdgeInsets.all(12.w), // 🔧 FIX: Ridotto da 16w a 12w
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icona placeholder
            ShimmerBox(
              width: 40.w, // 🔧 FIX: Ridotta da 48w a 40w
              height: 40.w,
              borderRadius: BorderRadius.circular(10.r), // 🔧 FIX: Ridotto da 12r a 10r
            ),
            SizedBox(width: 12.w),

            // Contenuto testo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // 🔧 FIX: Spazio minimo
                children: [
                  ShimmerBox(
                    height: 14.h, // 🔧 FIX: Ridotta da 16h a 14h
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  SizedBox(height: 6.h), // 🔧 FIX: Ridotto da 8h a 6h
                  ShimmerBox(
                    height: 12.h,
                    width: 150.w, // 🔧 FIX: Larghezza fissa invece di 200w
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ],
              ),
            ),

            // Badge/Status placeholder
            ShimmerBox(
              width: 50.w, // 🔧 FIX: Ridotta da 60w a 50w
              height: 20.h, // 🔧 FIX: Ridotta da 24h a 20h
              borderRadius: BorderRadius.circular(10.r),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer per Quick Actions Grid
class ShimmerQuickActionsGrid extends StatelessWidget {
  const ShimmerQuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            height: 20.h,
            width: 120.w,
            borderRadius: BorderRadius.circular(4.r),
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 1.3,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return ShimmerWidget(
                child: _buildQuickActionShimmer(context),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionShimmer(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerBox(
            width: 44.w,
            height: 44.w,
            borderRadius: BorderRadius.circular(12.r),
          ),
          SizedBox(height: 8.h),
          ShimmerBox(
            height: 16.h,
            width: 80.w,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ],
      ),
    );
  }
}

/// Shimmer per Recent Activity
class ShimmerRecentActivity extends StatelessWidget {
  const ShimmerRecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Titolo sezione
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: ShimmerBox(
            height: 20.h,
            width: 140.w,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(height: 12.h),

        // ✅ FIX: Usa Container con altezza fissa invece di LayoutBuilder problematico
        Container(
          height: 180.h, // Altezza fissa per evitare calcoli infiniti
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ShimmerCard(height: 80),
              SizedBox(height: 8.h),
              const ShimmerCard(height: 80),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shimmer per Achievement Cards
class ShimmerAchievementCard extends StatelessWidget {
  const ShimmerAchievementCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ShimmerWidget(
      child: Container(
        padding: EdgeInsets.all(16.w),
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ShimmerBox(
                  width: 48.w,
                  height: 48.w,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        height: 16.h,
                        width: double.infinity,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      SizedBox(height: 8.h),
                      ShimmerBox(
                        height: 12.h,
                        width: 200.w,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      SizedBox(height: 8.h),
                      ShimmerBox(
                        height: 12.h,
                        width: 100.w,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ],
                  ),
                ),
                ShimmerBox(
                  width: 60.w,
                  height: 24.h,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ShimmerBox(
              height: 4.h,
              width: double.infinity,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer per Profile Header
class ShimmerProfileHeader extends StatelessWidget {
  const ShimmerProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        margin: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Row(
              children: [
                ShimmerBox(
                  width: 60.w,
                  height: 60.w,
                  borderRadius: BorderRadius.circular(30.r),
                  color: Colors.white.withOpacity(0.3),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        height: 20.h,
                        width: 120.w,
                        borderRadius: BorderRadius.circular(4.r),
                        color: Colors.white.withOpacity(0.3),
                      ),
                      SizedBox(height: 8.h),
                      ShimmerBox(
                        height: 14.h,
                        width: 80.w,
                        borderRadius: BorderRadius.circular(4.r),
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(
                      height: 14.h,
                      width: 100.w,
                      borderRadius: BorderRadius.circular(4.r),
                      color: Colors.white.withOpacity(0.3),
                    ),
                    ShimmerBox(
                      height: 14.h,
                      width: 40.w,
                      borderRadius: BorderRadius.circular(4.r),
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                ShimmerBox(
                  height: 4.h,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(2.r),
                  color: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Utility per creare shimmer lists
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final Widget? Function(BuildContext, int) shimmerBuilder;
  final EdgeInsets? padding;

  const ShimmerList({
    super.key,
    required this.itemCount,
    required this.shimmerBuilder,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: shimmerBuilder,
    );
  }
}

/// Shimmer combinato per Dashboard completa
class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🔧 FIX: Spazio minimo
        children: [
          SizedBox(height: 10.h),

          // Greeting shimmer
          ShimmerCard(height: 100.h), // 🔧 FIX: Ridotta da 120h a 100h

          SizedBox(height: 20.h),

          // Quick Actions shimmer
          const ShimmerQuickActionsGrid(),

          SizedBox(height: 20.h), // 🔧 FIX: Ridotto da 24h a 20h

          // Subscription shimmer
          ShimmerCard(height: 55.h), // 🔧 FIX: Ridotta da 60h a 55h

          SizedBox(height: 20.h), // 🔧 FIX: Ridotto da 24h a 20h

          // Recent Activity shimmer - 🔧 FIX: Con altezza limitata
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 200.h, // 🔧 FIX: Limite massimo di altezza
              minHeight: 100.h,  // 🔧 FIX: Altezza minima garantita
            ),
            child: const ShimmerRecentActivity(),
          ),

          SizedBox(height: 20.h),

          // Altri shimmer cards
          ShimmerCard(height: 60.h), // Donation banner
          ShimmerCard(height: 60.h), // Help section

          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

/// Shimmer per la pagina Achievement completa
class ShimmerAchievementsPage extends StatelessWidget {
  const ShimmerAchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header stats shimmer
          ShimmerCard(
            height: 150.h,
            margin: EdgeInsets.all(16.w),
          ),

          // Tab bar shimmer
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            height: 40.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),

          SizedBox(height: 16.h),

          // Achievement cards shimmer
          ...List.generate(5, (index) => const ShimmerAchievementCard()),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}