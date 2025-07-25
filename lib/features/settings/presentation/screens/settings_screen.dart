import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/legal_documents_screen.dart';
import '../widgets/theme_selector.dart';
import '../widgets/color_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        foregroundColor: isDarkMode ? Colors.white : AppColors.textPrimary,
        elevation: 0,
      ),
      body: Container(
        color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // Sezione Account
            _buildSection(
              context,
              'Account',
              [
                _buildSettingTile(
                  context,
                  'Profilo',
                  'Gestisci il tuo profilo utente',
                  Icons.person,
                  () => _navigateToProfile(context),
                  isDarkMode,
                ),
                _buildSettingTile(
                  context,
                  'Abbonamento',
                  'Gestisci il tuo abbonamento Premium',
                  Icons.star,
                  () => _navigateToSubscription(context),
                  isDarkMode,
                ),
              ],
              isDarkMode,
            ),
            
            SizedBox(height: 24.h),
            
            // Sezione App
            _buildSection(
              context,
              'App',
              [
                _buildSettingTile(
                  context,
                  'Notifiche',
                  'Configura le notifiche dell\'app',
                  Icons.notifications,
                  () => _navigateToNotifications(context),
                  isDarkMode,
                ),
                _buildSettingTile(
                  context,
                  'Aspetto',
                  'Personalizza tema e colori',
                  Icons.palette,
                  () => _showAppearanceSettings(context),
                  isDarkMode,
                ),
                _buildSettingTile(
                  context,
                  'Lingua',
                  'Cambia lingua dell\'app',
                  Icons.language,
                  () => _changeLanguage(context),
                  isDarkMode,
                ),
              ],
              isDarkMode,
            ),
            
            SizedBox(height: 24.h),
            
            // Sezione Supporto
            _buildSection(
              context,
              'Supporto',
              [
                _buildSettingTile(
                  context,
                  'Aiuto',
                  'Guida e FAQ',
                  Icons.help,
                  () => _openHelp(context),
                  isDarkMode,
                ),
                _buildSettingTile(
                  context,
                  'Contattaci',
                  'Invia un messaggio al supporto',
                  Icons.email,
                  () => _contactSupport(context),
                  isDarkMode,
                ),
                _buildSettingTile(
                  context,
                  'Valuta l\'app',
                  'Lascia una recensione su Google Play',
                  Icons.star_rate,
                  () => _rateApp(context),
                  isDarkMode,
                ),
              ],
              isDarkMode,
            ),
            
            SizedBox(height: 24.h),
            
            // Sezione Legale
            _buildSection(
              context,
              'Legale',
              [
                _buildSettingTile(
                  context,
                  'Privacy Policy',
                  'Come gestiamo i tuoi dati',
                  Icons.privacy_tip,
                  () => _openPrivacyPolicy(context),
                  isDarkMode,
                ),
                _buildSettingTile(
                  context,
                  'Terms of Service',
                  'Termini e condizioni d\'uso',
                  Icons.description,
                  () => _openTermsOfService(context),
                  isDarkMode,
                ),
                _buildSettingTile(
                  context,
                  'Licenze',
                  'Licenze software utilizzate',
                  Icons.info,
                  () => _showLicenses(context),
                  isDarkMode,
                ),
              ],
              isDarkMode,
            ),
            
            SizedBox(height: 24.h),
            
            // Sezione Informazioni
            _buildSection(
              context,
              'Informazioni',
              [
                _buildSettingTile(
                  context,
                  'Versione',
                  '1.0.0 (Build 1)',
                  Icons.info_outline,
                  null, // Non cliccabile
                  isDarkMode,
                  showTrailing: false,
                ),
                _buildSettingTile(
                  context,
                  'Sviluppato da',
                  AppConfig.developerName,
                  Icons.code,
                  null, // Non cliccabile
                  isDarkMode,
                  showTrailing: false,
                ),
              ],
              isDarkMode,
            ),
            
            SizedBox(height: 32.h),
            
            // Pulsante Logout
            _buildLogoutButton(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.w, bottom: 12.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : AppColors.border,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
    bool isDarkMode, {
    bool showTrailing = true,
  }) {
    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.blue[600]!.withOpacity(0.2) : Colors.blue[50]!,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          size: 20.sp,
          color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14.sp,
          color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
        ),
      ),
      trailing: showTrailing && onTap != null
          ? Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ElevatedButton.icon(
        onPressed: () => _logout(context),
        icon: Icon(
          Icons.logout,
          size: 20.sp,
          color: Colors.white,
        ),
        label: Text(
          'Logout',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToProfile(BuildContext context) {
    // TODO: Implementare navigazione al profilo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funzionalità in arrivo!')),
    );
  }

  void _navigateToSubscription(BuildContext context) {
    // TODO: Implementare navigazione all'abbonamento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funzionalità in arrivo!')),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    // TODO: Implementare navigazione alle notifiche
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funzionalità in arrivo!')),
    );
  }

  void _toggleTheme(BuildContext context) {
    // TODO: Implementare cambio tema
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funzionalità in arrivo!')),
    );
  }

  void _showAppearanceSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Aspetto',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    ThemeSelector(
                      onThemeChanged: (themeMode) {
                        // TODO: Applicare il tema
                      },
                    ),
                    SizedBox(height: 32.h),
                    ColorPicker(
                      onColorChanged: (color) {
                        // TODO: Applicare il colore
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeLanguage(BuildContext context) {
    // TODO: Implementare cambio lingua
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funzionalità in arrivo!')),
    );
  }

  void _openHelp(BuildContext context) {
    // TODO: Implementare apertura help
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funzionalità in arrivo!')),
    );
  }

  void _contactSupport(BuildContext context) async {
    final email = AppConfig.supportEmail;
    final subject = 'Supporto FitGymTrack';
    final body = 'Ciao, ho bisogno di aiuto con l\'app FitGymTrack...';
    
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile aprire l\'email')),
      );
    }
  }

  void _rateApp(BuildContext context) async {
    // TODO: Implementare apertura Google Play Store per recensione
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funzionalità in arrivo!')),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LegalDocumentsScreen(
          title: 'Privacy Policy',
          documentType: 'privacy',
        ),
      ),
    );
  }

  void _openTermsOfService(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LegalDocumentsScreen(
          title: 'Terms of Service',
          documentType: 'terms',
        ),
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'FitGymTrack',
      applicationVersion: '1.0.0',
      applicationLegalese: '© ${DateTime.now().year} FitGymTrack Team',
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Sei sicuro di voler effettuare il logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementare logout
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logout effettuato')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
} 