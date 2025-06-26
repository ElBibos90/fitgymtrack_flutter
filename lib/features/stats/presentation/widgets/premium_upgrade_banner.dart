// lib/features/stats/presentation/widgets/premium_upgrade_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';

class PremiumUpgradeBanner extends StatelessWidget {
  const PremiumUpgradeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.indigo600.withOpacity(0.1),
            AppColors.green600.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.indigo600.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.diamond,
            color: AppColors.indigo600,
            size: 48.sp,
          ),
          SizedBox(height: 12.h),

          Text(
            'Sblocca Statistiche Premium',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8.h),

          Text(
            'Accedi a grafici avanzati, analisi dettagliate e confronti temporali',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16.h),

          // Lista benefici
          Column(
            children: [
              _buildBenefitRow('📊 Grafici interattivi e trend'),
              _buildBenefitRow('🎯 Analisi per gruppo muscolare'),
              _buildBenefitRow('📈 Confronti temporali dettagliati'),
              _buildBenefitRow('🏆 Top esercizi per volume'),
              _buildBenefitRow('📅 Distribuzione settimanale'),
            ],
          ),

          SizedBox(height: 20.h),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Navigate to subscription screen
                // Navigator.pushNamed(context, '/subscription');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navigazione alla pagina abbonamenti'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Diventa Premium',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}