// lib/features/home/presentation/widgets/donation_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Banner per donazioni e supporto
class DonationBanner extends StatelessWidget {
  const DonationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53E3E), Color(0xFFFC8181)],
        ),
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
            Icons.favorite,
            color: Colors.white,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supporta lo sviluppo',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Aiutaci a migliorare FitGymTrack',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showDonationDialog(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            ),
            child: Text(
              'Dona',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDonationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.favorite, color: Colors.red, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Supporta FitGymTrack'),
          ],
        ),
        content: const Text(
            'Grazie per voler supportare lo sviluppo di FitGymTrack!\n\n'
                'Il sistema di donazioni sarà disponibile presto. '
                'Nel frattempo, puoi supportarci:\n\n'
                '• Lasciando una recensione positiva\n'
                '• Condividendo l\'app con gli amici\n'
                '• Inviando feedback per miglioramenti'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showThankYouDialog(context);
            },
            child: const Text('Grazie!'),
          ),
        ],
      ),
    );
  }

  void _showThankYouDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emoji_emotions, color: Colors.orange, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Grazie!'),
          ],
        ),
        content: const Text(
            'Il tuo supporto significa molto per noi! 🙏\n\n'
                'Continueremo a lavorare per migliorare FitGymTrack '
                'e renderlo ancora più utile per i tuoi allenamenti.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Prego!'),
          ),
        ],
      ),
    );
  }
}