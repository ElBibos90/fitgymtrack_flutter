// lib/features/home/presentation/widgets/subscription_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../subscription/bloc/subscription_bloc.dart';

/// Sezione status abbonamento nella dashboard
class SubscriptionSection extends StatelessWidget {
  const SubscriptionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        if (state is SubscriptionLoaded) {
          final subscription = state.subscription;
          final hasPremium = subscription.isPremium;

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: hasPremium
                  ? const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              )
                  : null,
              color: hasPremium
                  ? null
                  : (isDarkMode ? AppColors.surfaceDark : Colors.white),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  hasPremium ? Icons.workspace_premium : Icons.lock_outline,
                  color: hasPremium ? Colors.white : (isDarkMode ? Colors.grey : Colors.grey.shade600),
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasPremium ? 'Premium Attivo' : 'Piano Gratuito',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: hasPremium ? Colors.white : (isDarkMode ? Colors.white : Colors.black),
                        ),
                      ),
                      if (!hasPremium) ...[
                        Text(
                          '${subscription.currentCount}/${subscription.maxWorkouts ?? 3} schede create',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!hasPremium)
                  TextButton(
                    onPressed: () => _navigateToSubscription(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    ),
                    child: Text(
                      'Upgrade',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
              ],
            ),
          );
        }

        // Loading state
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          height: 60.h,
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  void _navigateToSubscription(BuildContext context) {
    // Per ora usa GoRouter, in futuro integreremo con bottom navigation
    context.go('/subscription'    );
  }
}