// lib/features/home/presentation/widgets/help_section.dart (FIX)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';

/// Sezione aiuto e supporto - 🔧 COLLEGATA A FUNZIONALITÀ REALI
class HelpSection extends StatelessWidget {
  const HelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.surfaceDark.withValues(alpha: 0.5)
            : AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: isDarkMode ? Colors.white70 : AppColors.indigo600,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Hai bisogno di aiuto?',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Manda un feedback per qualsiasi informazione, problema o miglioramenti.',
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.grey.shade400 : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),

          // Row con pulsanti
          Row(
            children: [
              // 🔧 FIX: Pulsante Feedback che naviga direttamente alla schermata
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/feedback'),
                  icon: Icon(
                    Icons.feedback_outlined,
                    size: 16.sp,
                  ),
                  label: const Text('Feedback'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.white70 : AppColors.indigo600,
                    side: BorderSide(
                      color: isDarkMode ? Colors.grey.shade600 : AppColors.indigo600,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // Pulsante FAQ funzionale
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showFAQDialog(context),
                  icon: Icon(
                    Icons.help_center_outlined,
                    size: 16.sp,
                  ),
                  label: const Text('FAQ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.white70 : AppColors.indigo600,
                    side: BorderSide(
                      color: isDarkMode ? Colors.grey.shade600 : AppColors.indigo600,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔧 FIX: FAQ Dialog migliorato e funzionale
  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_center, color: AppColors.indigo600, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Domande Frequenti'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFAQItem(
                  question: '🏋️ Come creo un allenamento?',
                  answer: 'Vai alla tab "Allenamenti" e tocca il pulsante "+" per creare una nuova scheda personalizzata.',
                ),
                _buildFAQItem(
                  question: '📊 Come funziona il tracking?',
                  answer: 'Durante l\'allenamento, inserisci peso e ripetizioni per ogni serie. I dati vengono salvati automaticamente.',
                ),
                _buildFAQItem(
                  question: '💎 Cosa include Premium?',
                  answer: 'Premium include allenamenti illimitati, statistiche avanzate e funzionalità esclusive.',
                ),
                _buildFAQItem(
                  question: '📱 Posso usare l\'app offline?',
                  answer: 'Sì! Gli allenamenti creati sono disponibili offline. I dati si sincronizzano quando torni online.',
                ),
                _buildFAQItem(
                  question: '🔄 Come esporto i miei dati?',
                  answer: 'Vai su Profilo > Impostazioni > Esporta Dati per scaricare la cronologia dei tuoi allenamenti.',
                ),
                _buildFAQItem(
                  question: '❓ Altri problemi?',
                  answer: 'Usa il sistema Feedback integrato per contattarci direttamente dall\'app.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
          // 🔧 NEW: Pulsante per aprire feedback direttamente
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/feedback');
            },
            child: const Text('Invia Feedback'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.indigo600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            answer,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}