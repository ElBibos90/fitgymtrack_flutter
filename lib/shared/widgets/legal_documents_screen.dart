import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../shared/theme/app_colors.dart';

class LegalDocumentsScreen extends StatelessWidget {
  final String title;
  final String documentType; // 'privacy' or 'terms'

  const LegalDocumentsScreen({
    super.key,
    required this.title,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        foregroundColor: isDarkMode ? Colors.white : AppColors.textPrimary,
        elevation: 0,
      ),
      body: Container(
        color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        child: Column(
          children: [
            // Header con informazioni
            _buildHeader(context, isDarkMode),
            
            // Contenuto del documento
            Expanded(
              child: _buildDocumentContent(context, isDarkMode),
            ),
            
            // Footer con link esterni
            _buildFooter(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            documentType == 'privacy' ? 'Privacy Policy' : 'Terms of Service',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            documentType == 'privacy' 
                ? 'Come raccogliamo, utilizziamo e proteggiamo le tue informazioni personali'
                : 'Termini e condizioni per l\'utilizzo dell\'app FitGymTrack',
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16.sp,
                color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Questo documento è conforme al GDPR e ai requisiti di Google Play Store',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentContent(BuildContext context, bool isDarkMode) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (documentType == 'privacy') ...[
            _buildPrivacyContent(context, isDarkMode),
          ] else ...[
            _buildTermsContent(context, isDarkMode),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivacyContent(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          context,
          '1. Informazioni Generali',
          'FitGymTrack è un\'applicazione mobile per il tracking degli allenamenti fitness. Questa Privacy Policy spiega come raccogliamo, utilizziamo e proteggiamo le tue informazioni personali.',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '2. Dati che Raccogliamo',
          '• Informazioni di registrazione: Nome utente, email, password\n'
          '• Profilo utente: Nome, età, peso, altezza, obiettivi fitness\n'
          '• Dati di allenamento: Esercizi, serie, ripetizioni, pesi, date\n'
          '• Foto: Immagini degli esercizi (opzionale)\n'
          '• Dati di utilizzo: Come usi l\'app, funzionalità più utilizzate\n'
          '• Dati tecnici: Versione app, sistema operativo, ID dispositivo',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '3. Come Utilizziamo i Dati',
          '• Creare e gestire il tuo account\n'
          '• Salvare e sincronizzare i tuoi allenamenti\n'
          '• Fornire statistiche e analytics personalizzate\n'
          '• Gestire abbonamenti e pagamenti\n'
          '• Migliorare l\'app e risolvere problemi tecnici',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '4. Sicurezza dei Dati',
          '• Crittografia dei dati in transito e a riposo\n'
          '• Accesso limitato ai dati personali\n'
          '• Monitoraggio continuo della sicurezza\n'
          '• Backup regolari e sicuri\n'
          '• I tuoi dati vengono conservati finché mantieni un account attivo',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '5. I Tuoi Diritti (GDPR)',
          'Hai il diritto di:\n'
          '• Accesso: Vedere i dati che abbiamo su di te\n'
          '• Rettifica: Correggere dati inesatti\n'
          '• Cancellazione: Eliminare il tuo account e i dati\n'
          '• Portabilità: Esportare i tuoi dati\n'
          '• Opposizione: Opporti al trattamento dei dati',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '6. Contatti',
          'Per domande su questa Privacy Policy:\n'
          'Email: support@fitgymtrack.com\n'
          'Website: https://fitgymtrack.com',
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildTermsContent(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          context,
          '1. Accettazione dei Termini',
          'Utilizzando l\'app FitGymTrack, accetti di essere vincolato da questi Terms of Service. Se non accetti questi termini, non utilizzare l\'App.',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '2. Descrizione del Servizio',
          'FitGymTrack è un\'applicazione mobile che fornisce:\n'
          '• Tracking degli allenamenti fitness\n'
          '• Gestione di esercizi e schede di allenamento\n'
          '• Statistiche e analytics personalizzate\n'
          '• Funzionalità premium tramite abbonamento',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '3. Registrazione e Account',
          '• Devi avere almeno 13 anni per creare un account\n'
          '• Fornisci informazioni accurate e complete\n'
          '• Sei responsabile della sicurezza del tuo account\n'
          '• Non condividere le tue credenziali',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '4. Uso Accettabile',
          'Puoi:\n'
          '• Utilizzare l\'App per i tuoi allenamenti personali\n'
          '• Creare e gestire le tue schede di allenamento\n'
          '• Condividere i tuoi progressi (se consentito)\n\n'
          'Non puoi:\n'
          '• Utilizzare l\'App per scopi illegali\n'
          '• Violare i diritti di proprietà intellettuale\n'
          '• Interferire con il funzionamento dell\'App',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '5. Abbonamenti e Pagamenti',
          '• Alcune funzionalità richiedono un abbonamento\n'
          '• I prezzi sono indicati nell\'App e possono cambiare\n'
          '• Gli abbonamenti si rinnovano automaticamente\n'
          '• Puoi cancellare l\'abbonamento in qualsiasi momento\n'
          '• I pagamenti sono gestiti da Stripe',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '6. Limitazione di Responsabilità',
          '• L\'App è fornita "così com\'è"\n'
          '• Non garantiamo che l\'App sia priva di errori\n'
          '• Non garantiamo la disponibilità continua del servizio\n'
          '• Non siamo responsabili per lesioni durante l\'allenamento',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '7. Contatti',
          'Per domande sui Terms of Service:\n'
          'Email: legal@fitgymtrack.com\n'
          'Website: https://fitgymtrack.com',
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, bool isDarkMode) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.5,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Versione completa disponibile online',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLinkButton(
                context,
                'Privacy Policy',
                AppConfig.privacyPolicyUrl,
                isDarkMode,
              ),
              _buildLinkButton(
                context,
                'Terms of Service',
                AppConfig.termsOfServiceUrl,
                isDarkMode,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Ultimo aggiornamento: ${DateTime.now().year}',
            style: TextStyle(
              fontSize: 12.sp,
              color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton(BuildContext context, String text, String url, bool isDarkMode) {
    return ElevatedButton.icon(
      onPressed: () => _launchUrl(url),
      icon: Icon(
        Icons.open_in_new,
        size: 16.sp,
        color: Colors.white,
      ),
      label: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? Colors.blue[600] : Colors.blue[500],
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
} 