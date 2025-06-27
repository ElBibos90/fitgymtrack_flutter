// lib/features/auth/presentation/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.indigo600,
              AppColors.indigo700,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: 60.sp,
                    color: AppColors.indigo600,
                  ),
                ),

                SizedBox(height: 24.h),

                Text(
                  'FitGymTrack',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),

                SizedBox(height: 8.h),

                Text(
                  'Il tuo personal trainer digitale',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w300,
                  ),
                ),

                SizedBox(height: 40.h),

                SizedBox(
                  width: 40.w,
                  height: 40.w,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),

                SizedBox(height: 16.h),

                Text(
                  'Caricamento...',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
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