// lib/features/settings/presentation/screens/security_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../shared/theme/app_colors.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final BiometricAuthService _biometricService = getIt<BiometricAuthService>();
  
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _biometricType = 'Biometric';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    try {
      final available = await _biometricService.isBiometricAvailable();
      final enabled = await _biometricService.isBiometricEnabled();
      final type = await _biometricService.getBiometricType();
      
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _biometricType = type;
        _isLoading = false;
      });
    } catch (e) {
      //debugPrint('[SecuritySettings] ❌ Error loading status: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Abilita biometrico
      await _enableBiometric();
    } else {
      // Disabilita biometrico
      await _disableBiometric();
    }
  }

  Future<void> _enableBiometric() async {
    try {
      // Chiedi username e password per abilitarlo correttamente
      final usernameController = TextEditingController();
      final passwordController = TextEditingController();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.fingerprint),
                SizedBox(width: 8.w),
                Text('Abilita $_biometricType'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                  ),
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Abilita'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      final username = usernameController.text.trim();
      final password = passwordController.text;

      if (username.isEmpty || password.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inserisci username e password'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Abilita biometrico salvando le credenziali
      await _biometricService.enableBiometric(username, password);
      setState(() => _biometricEnabled = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_biometricType abilitato con successo!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disableBiometric() async {
    // Conferma prima di disabilitare
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: Text('Disabilita $_biometricType'),
          content: Text(
            'Sei sicuro di voler disabilitare l\'accesso con $_biometricType? '
            'Dovrai inserire username e password per accedere.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Disabilita'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
        await _biometricService.disableBiometricWithConfirmation();
      
      setState(() => _biometricEnabled = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_biometricType disabilitato'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sicurezza'),
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        foregroundColor: isDarkMode ? Colors.white : AppColors.textPrimary,
        elevation: 0,
      ),
      body: Container(
        color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  // Sezione Autenticazione Biometrica
                  _buildSection(
                    context,
                    'Autenticazione',
                    [
                      _buildBiometricTile(isDarkMode),
                    ],
                    isDarkMode,
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Sezione Password
                  _buildSection(
                    context,
                    'Password',
                    [
                      _buildSettingTile(
                        context,
                        'Cambia Password',
                        'Aggiorna la tua password',
                        Icons.key,
                        () => _changePassword(context),
                        isDarkMode,
                      ),
                    ],
                    isDarkMode,
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Sezione Recupero Password
                  _buildSection(
                    context,
                    'Recupero Password',
                    [
                      _buildSettingTile(
                        context,
                        'Domande di Sicurezza',
                        'Configura domande per recuperare la password',
                        Icons.help_outline,
                        () => Navigator.pushNamed(context, '/security-questions-setup'),
                        isDarkMode,
                      ),
                    ],
                    isDarkMode,
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Info sul biometrico
                  if (_biometricAvailable)
                    _buildInfoCard(isDarkMode),
                ],
              ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
    bool isDarkMode,
  ) {
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildBiometricTile(bool isDarkMode) {
    if (!_biometricAvailable) {
      return ListTile(
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.fingerprint,
            size: 20.sp,
            color: Colors.grey[600],
          ),
        ),
        title: Text(
          'Autenticazione Biometrica',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white70 : Colors.grey[700],
          ),
        ),
        subtitle: Text(
          'Non disponibile su questo dispositivo',
          style: TextStyle(
            fontSize: 14.sp,
            color: isDarkMode ? Colors.white54 : Colors.grey[500],
          ),
        ),
      );
    }

    return SwitchListTile(
      secondary: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: _biometricEnabled
              ? (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600).withValues(alpha: 0.2)
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          Icons.fingerprint,
          size: 20.sp,
          color: _biometricEnabled 
              ? (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600) 
              : Colors.grey[600],
        ),
      ),
      title: Text(
        'Accedi con $_biometricType',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        _biometricEnabled
            ? 'Attivo - Login rapido abilitato'
            : 'Disattivo - Usa password per accedere',
        style: TextStyle(
          fontSize: 14.sp,
          color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
        ),
      ),
      value: _biometricEnabled,
      onChanged: _toggleBiometric,
      activeColor: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
    bool isDarkMode,
  ) {
    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.blue[600]!.withValues(alpha: 0.2)
              : Colors.blue[50]!,
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
      trailing: Icon(
        Icons.chevron_right,
        color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoCard(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: (isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sicurezza $_biometricType',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Le tue credenziali sono crittografate e salvate in modo sicuro. '
                  '$_biometricType non viene mai inviato ai nostri server.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _changePassword(BuildContext context) {
    // TODO: Implementare cambio password
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funzionalità in arrivo!')),
    );
  }
}

