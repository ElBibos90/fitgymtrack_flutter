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

  // 🔧 FIX: FAQ Dialog migliorato e funzionale con domande reali
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
                  question: '🏋️ Come funziona il timer di recupero?',
                  answer: 'Il timer si avvia automaticamente dopo ogni serie. Continua a funzionare anche quando l\'app è in background e ti notifica quando è completato. Puoi metterlo in pausa o saltarlo se necessario.',
                ),
                _buildFAQItem(
                  question: '🎵 Perché la musica si interrompe durante i timer?',
                  answer: 'Abbiamo risolto questo problema! Ora i timer utilizzano l\'audio ducking che riduce temporaneamente il volume della musica invece di interromperla. Puoi disattivare i suoni timer nelle impostazioni audio.',
                ),
                _buildFAQItem(
                  question: '⏱️ Come funzionano i timer isometrici?',
                  answer: 'I timer isometrici si attivano automaticamente per esercizi come plank o wall sit. Contano i secondi invece delle ripetizioni e completano automaticamente la serie quando finisce il tempo.',
                ),
                _buildFAQItem(
                  question: '📊 Cosa sono i plateau e come funzionano?',
                  answer: 'Il sistema rileva automaticamente quando stai usando gli stessi pesi/ripetizioni per diverse sessioni consecutive. Ti suggerisce come progredire: aumentare peso, ripetizioni o cambiare tecnica.',
                ),
                _buildFAQItem(
                  question: '🔄 Come funzionano i superset e circuit?',
                  answer: 'Gli esercizi vengono raggruppati automaticamente se hanno lo stesso tipo di set. I superset alternano esercizi, i circuit fanno round completi. Il timer di recupero si attiva solo alla fine del gruppo.',
                ),
                _buildFAQItem(
                  question: '💾 I miei dati si perdono se cambio telefono?',
                  answer: 'No! I tuoi dati sono sincronizzati nel cloud. Basta fare login con lo stesso account su un nuovo dispositivo e tutti i tuoi allenamenti, progressi e impostazioni saranno disponibili.',
                ),
                _buildFAQItem(
                  question: '🔢 Come funziona il calcolatore 1RM?',
                  answer: 'Usa la formula di Brzycki per calcolare il tuo massimo teorico. Inserisci peso e ripetizioni di una serie recente e otterrai una stima del tuo 1RM. Utile per programmare gli allenamenti.',
                ),
                _buildFAQItem(
                  question: '📱 L\'app funziona offline?',
                  answer: 'Sì! Puoi creare allenamenti e registrare serie anche senza connessione. I dati si sincronizzano automaticamente quando torni online. Solo alcune funzionalità premium richiedono internet.',
                ),
                _buildFAQItem(
                  question: '🎯 Come funziona il sistema di versioning?',
                  answer: 'Gli utenti tester ricevono aggiornamenti più frequenti per testare nuove funzionalità. Gli utenti normali ricevono versioni stabili. Il sistema è automatico e trasparente.',
                ),
                _buildFAQItem(
                  question: '🔧 Come posso personalizzare l\'esperienza audio?',
                  answer: 'Vai su Impostazioni > Audio per controllare: suoni timer, vibrazione feedback, riduzione volume musica. Le impostazioni vengono salvate e applicate a tutti i timer.',
                ),
                _buildFAQItem(
                  question: '📈 Come tracciare i progressi nel tempo?',
                  answer: 'L\'app salva automaticamente ogni serie. Puoi vedere le statistiche nella sezione Progressi: peso massimo, volume totale, frequenza allenamenti e trend nel tempo.',
                ),
                _buildFAQItem(
                  question: '❓ Non trovi la risposta?',
                  answer: 'Usa il sistema Feedback integrato per contattarci direttamente dall\'app. Includi screenshot se possibile per aiutarci a risolvere il problema più velocemente.',
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