// lib/features/home/presentation/widgets/help_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';

/// Sezione aiuto e feedback
class HelpSection extends StatelessWidget {
  const HelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: isDarkMode
            ? Border.all(color: Colors.grey.shade700, width: 0.5)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Hai bisogno di aiuto?',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Riga di bottoni aiuto
          Row(
            children: [
              Expanded(
                child: _buildHelpButton(
                  context: context,
                  icon: Icons.feedback_outlined,
                  label: 'Feedback',
                  onTap: () => _showFeedbackDialog(context),
                  isDarkMode: isDarkMode,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildHelpButton(
                  context: context,
                  icon: Icons.help_center_outlined,
                  label: 'FAQ',
                  onTap: () => _showFAQDialog(context),
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8.r),
          border: isDarkMode
              ? Border.all(color: Colors.grey.shade700, width: 0.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.feedback, color: Colors.blue, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Feedback'),
          ],
        ),
        content: const Text(
            'Il tuo feedback è importante per noi!\n\n'
                'Il sistema di feedback integrato sarà disponibile presto. '
                'Nel frattempo puoi:\n\n'
                '• Contattarci via email\n'
                '• Lasciare una recensione sull\'app store\n'
                '• Suggerire miglioramenti\n\n'
                'Grazie per aiutarci a migliorare FitGymTrack!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showContactDialog(context);
            },
            child: const Text('Contattaci'),
          ),
        ],
      ),
    );
  }

  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_center, color: Colors.green, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('FAQ'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFAQItem(
                question: 'Come creo un allenamento?',
                answer: 'Vai alla tab "Allenamenti" e tocca il pulsante "+" per creare una nuova scheda.',
              ),
              _buildFAQItem(
                question: 'Posso personalizzare gli esercizi?',
                answer: 'Sì! Puoi aggiungere esercizi personalizzati dal catalogo o crearne di nuovi.',
              ),
              _buildFAQItem(
                question: 'Come funziona il piano Premium?',
                answer: 'Il piano Premium sblocca schede illimitate, esercizi personalizzati e statistiche avanzate.',
              ),
              _buildFAQItem(
                question: 'I miei dati sono sicuri?',
                answer: 'Sì, tutti i dati sono criptati e memorizzati in modo sicuro sui nostri server.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            answer,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.email, color: Colors.orange, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Contattaci'),
          ],
        ),
        content: const Text(
            'Puoi contattarci per:\n\n'
                '• Segnalazioni di bug\n'
                '• Richieste di funzionalità\n'
                '• Supporto tecnico\n'
                '• Suggerimenti generali\n\n'
                'Email: support@fitgymtrack.com\n'
                'Risponderemo entro 24 ore!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}