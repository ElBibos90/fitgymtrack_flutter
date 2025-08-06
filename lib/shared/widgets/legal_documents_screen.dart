import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          'FitGymTrack è un\'applicazione mobile per il tracking degli allenamenti fitness. Questa Privacy Policy spiega come raccogliamo, utilizziamo e proteggiamo le tue informazioni personali in conformità con il GDPR (Regolamento UE 2016/679).',
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
          '• Dati tecnici: Versione app, sistema operativo, ID dispositivo\n'
          '• Dati di pagamento: Gestiti da Stripe, stato abbonamento',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '3. Base Giuridica (GDPR)',
          '• Consenso: Per marketing e comunicazioni promozionali\n'
          '• Esecuzione del contratto: Per fornire i servizi dell\'app\n'
          '• Interesse legittimo: Per migliorare l\'app e prevenire abusi\n'
          '• Obbligo legale: Per rispettare le leggi applicabili',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '4. Come Utilizziamo i Dati',
          '• Creare e gestire il tuo account\n'
          '• Salvare e sincronizzare i tuoi allenamenti\n'
          '• Fornire statistiche e analytics personalizzate\n'
          '• Gestire abbonamenti e pagamenti\n'
          '• Migliorare l\'app e risolvere problemi tecnici\n'
          '• Prevenire frodi e abusi',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '5. Sicurezza dei Dati',
          '• Crittografia AES-256 dei dati in transito e a riposo\n'
          '• Accesso limitato ai dati personali con autenticazione multi-fattore\n'
          '• Backup regolari e sicuri con crittografia\n'
          '• Monitoraggio continuo della sicurezza\n'
          '• I dati vengono eliminati entro 30 giorni dalla cancellazione account',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '6. I Tuoi Diritti (GDPR)',
          'Hai il diritto di:\n'
          '• Accesso: Vedere i dati che abbiamo su di te\n'
          '• Rettifica: Correggere dati inesatti o incompleti\n'
          '• Cancellazione: Eliminare il tuo account e i dati ("diritto all\'oblio")\n'
          '• Portabilità: Esportare i tuoi dati in formato leggibile\n'
          '• Opposizione: Opporti al trattamento per marketing\n'
          '• Limitazione: Limitare il trattamento in determinate circostanze\n'
          '• Revoca del Consenso: Revocare il consenso in qualsiasi momento',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '7. Conservazione dei Dati',
          '• Dati dell\'account: Finché mantieni un account attivo\n'
          '• Dati di allenamento: Finché mantieni un account attivo\n'
          '• Dati di pagamento: Come richiesto dalla legge fiscale (10 anni)\n'
          '• Log di sicurezza: 12 mesi',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '8. Contatti',
          'Per domande su questa Privacy Policy:\n'
          'Email: fitgymtrack@gmail.com\n'
          'Website: https://fitgymtrack.com\n\n'
          'Hai il diritto di presentare un reclamo all\'autorità di controllo per la protezione dei dati personali del tuo paese di residenza.',
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
          'Utilizzando l\'app FitGymTrack, accetti di essere vincolato da questi Terms of Service. Se non accetti questi termini, non utilizzare l\'App. L\'uso dell\'App costituisce accettazione di questi termini.',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '2. Descrizione del Servizio',
          'FitGymTrack è un\'applicazione mobile che fornisce:\n'
          '• Tracking degli allenamenti fitness con statistiche avanzate\n'
          '• Gestione di esercizi e schede di allenamento personalizzate\n'
          '• Timer intelligenti per recupero e esercizi isometrici\n'
          '• Analisi plateau e suggerimenti di progressione\n'
          '• Funzionalità premium tramite abbonamento\n'
          '• Sincronizzazione cloud dei dati di allenamento',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '3. Registrazione e Account',
          '• Devi avere almeno 13 anni per creare un account\n'
          '• Fornisci informazioni accurate, complete e aggiornate\n'
          '• Sei responsabile della sicurezza del tuo account e password\n'
          '• Non condividere le tue credenziali con terzi\n'
          '• Account inattivi per 12 mesi potrebbero essere sospesi\n'
          '• Un solo account per persona fisica',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '4. Uso Accettabile',
          'Puoi:\n'
          '• Utilizzare l\'App per i tuoi allenamenti personali\n'
          '• Creare e gestire le tue schede di allenamento\n'
          '• Condividere i tuoi progressi (se esplicitamente consentito)\n'
          '• Utilizzare le funzionalità premium con abbonamento valido\n\n'
          'Non puoi:\n'
          '• Utilizzare l\'App per scopi illegali o non autorizzati\n'
          '• Violare i diritti di proprietà intellettuale\n'
          '• Interferire con il funzionamento dell\'App o dei server\n'
          '• Tentare di accedere a dati di altri utenti',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '5. Abbonamenti e Pagamenti',
          '• Alcune funzionalità richiedono un abbonamento a pagamento\n'
          '• I pagamenti sono gestiti da Stripe e soggetti ai loro termini\n'
          '• I prezzi sono indicati nell\'App e possono cambiare con preavviso\n'
          '• Gli abbonamenti si rinnovano automaticamente fino alla cancellazione\n'
          '• Puoi cancellare l\'abbonamento in qualsiasi momento dalle impostazioni\n'
          '• Non ci sono rimborsi per periodi già pagati, salvo dove richiesto dalla legge',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '6. Limitazione di Responsabilità',
          '• L\'App è fornita "così com\'è" senza garanzie di alcun tipo\n'
          '• Non garantiamo che l\'App sia priva di errori o interruzioni\n'
          '• Non garantiamo la disponibilità continua del servizio\n'
          '• Non siamo responsabili per danni indiretti o lesioni durante l\'allenamento\n'
          '• La responsabilità totale è limitata all\'importo pagato per l\'abbonamento',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '7. Disclaimers Medici',
          '• L\'App non fornisce consigli medici o diagnosi\n'
          '• Consulta sempre un medico prima di iniziare un programma di allenamento\n'
          '• Non siamo responsabili per lesioni o problemi di salute\n'
          '• L\'App è uno strumento di supporto, non un sostituto della consulenza medica',
          isDarkMode,
        ),
        
        _buildSection(
          context,
          '8. Contatti',
          'Per domande sui Terms of Service:\n'
          'Email: fitgymtrack@gmail.com\n'
          'Website: https://fitgymtrack.com\n\n'
          'Questi termini sono regolati dalla legge italiana e le controversie saranno risolte nei tribunali italiani.',
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
            'Ultimo aggiornamento: 1 Agosto 2025',
            style: TextStyle(
              fontSize: 12.sp,
              color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}