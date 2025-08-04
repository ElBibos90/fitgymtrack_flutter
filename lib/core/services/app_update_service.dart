import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../di/dependency_injection.dart';
import '../../features/auth/repository/auth_repository.dart';

/// 🔧 NUOVO: Servizio per gestire il controllo degli aggiornamenti dell'app
class AppUpdateService {
  static const String _lastUpdateCheckKey = 'last_update_check_timestamp';
  // 🔧 PRODUZIONE: Controllo ogni 6 ore (invece di 24 ore)
  static const Duration _updateCheckInterval = Duration(hours: 6);

  /// Controlla se ci sono aggiornamenti disponibili
  static Future<AppUpdateInfo?> checkForUpdates({bool forceCheck = false}) async {
    try {
      // Controlla se è il momento di verificare gli aggiornamenti
      if (!forceCheck && !await _shouldCheckForUpdates()) {
        print('[CONSOLE] [app_update_service]⏰ Update check skipped (too recent)');
        
        // 🚨 NUOVO: Controlla SEMPRE se c'è un aggiornamento forzato
        final criticalUpdate = await _checkForCriticalUpdate();
        if (criticalUpdate != null) {
          print('[CONSOLE] [app_update_service]🚨 CRITICAL UPDATE FOUND! Ignoring time interval');
          return criticalUpdate;
        }
        
        return null;
      }

      print('[CONSOLE] [app_update_service]🔍 Checking for app updates...');

      // Ottieni la versione corrente
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = packageInfo.buildNumber;

      print('[CONSOLE] [app_update_service]📱 Current version: $currentVersion ($currentBuild)');

      // 🔧 NUOVO: Ottieni informazioni utente per targeting
      final isTestUser = await _checkIfUserIsTester();
      final platform = Platform.isAndroid ? 'android' : 'ios';
      
      print('[CONSOLE] [app_update_service]🎯 Targeting - Platform: $platform, IsTester: $isTestUser');

      // Controlla la versione sul server con targeting
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.getAppVersion(
        platform: platform,
        isTester: isTestUser,
      );
      
      if (response is Map<String, dynamic>) {
        final serverVersion = response['version'] as String?;
        final serverBuild = response['build_number'] as String?;
        final updateRequired = response['update_required'] as bool? ?? false;
        final updateMessage = response['message'] as String? ?? '';

        if (serverVersion != null && serverBuild != null) {
          print('[CONSOLE] [app_update_service]🌐 Server version: $serverVersion ($serverBuild)');
          
          final hasUpdate = _compareVersions(currentVersion, serverVersion) < 0;
          
          // 🔧 FIX: Mostra aggiornamento solo se c'è una versione nuova (updateRequired viene gestito separatamente)
          if (hasUpdate) {
            print('[CONSOLE] [app_update_service]✅ Update available!');
            await _saveLastUpdateCheck();
            
            return AppUpdateInfo(
              currentVersion: currentVersion,
              currentBuild: currentBuild,
              serverVersion: serverVersion,
              serverBuild: serverBuild,
              updateRequired: updateRequired,
              message: updateMessage,
              hasUpdate: true,
            );
          } else {
            print('[CONSOLE] [app_update_service]✅ App is up to date');
            await _saveLastUpdateCheck();
            return null;
          }
        }
      }

      print('[CONSOLE] [app_update_service]⚠️ Invalid server response');
      return null;

    } catch (e) {
      print('[CONSOLE] [app_update_service]❌ Update check failed: $e');
      return null;
    }
  }

  /// 🚨 NUOVO: Controlla se c'è un aggiornamento forzato (ignora intervallo tempo)
  static Future<AppUpdateInfo?> _checkForCriticalUpdate() async {
    try {
      print('[CONSOLE] [app_update_service]🚨 Checking for critical updates...');

      // Ottieni la versione corrente
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = packageInfo.buildNumber;

      // 🔧 NUOVO: Ottieni informazioni utente per targeting
      final isTestUser = await _checkIfUserIsTester();
      final platform = Platform.isAndroid ? 'android' : 'ios';

      // Controlla la versione sul server con targeting
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.getAppVersion(
        platform: platform,
        isTester: isTestUser,
      );
      
      if (response is Map<String, dynamic>) {
        final serverVersion = response['version'] as String?;
        final serverBuild = response['build_number'] as String?;
        final updateRequired = response['update_required'] as bool? ?? false;
        final updateMessage = response['message'] as String? ?? '';

        if (serverVersion != null && serverBuild != null) {
          print('[CONSOLE] [app_update_service]🚨 Server version: $serverVersion ($serverBuild), update_required: $updateRequired');
          print('[CONSOLE] [app_update_service]📱 Current version: $currentVersion ($currentBuild)');
          
          // 🔧 FIX: Controlla se le versioni sono diverse prima di mostrare aggiornamento forzato
          final hasUpdate = _compareVersions(currentVersion, serverVersion) < 0;
          print('[CONSOLE] [app_update_service]🔍 Version comparison: current=$currentVersion vs server=$serverVersion, hasUpdate=$hasUpdate');
          
          // Se c'è un aggiornamento forzato E le versioni sono diverse, ritornarlo
          if (updateRequired && hasUpdate) {
            print('[CONSOLE] [app_update_service]🚨 CRITICAL UPDATE DETECTED!');
            return AppUpdateInfo(
              currentVersion: currentVersion,
              currentBuild: currentBuild,
              serverVersion: serverVersion,
              serverBuild: serverBuild,
              updateRequired: true,
              message: updateMessage,
              hasUpdate: true,
            );
          } else {
            print('[CONSOLE] [app_update_service]✅ No critical update needed (versions match or no forced update)');
          }
        }
      }

      print('[CONSOLE] [app_update_service]✅ No critical updates found');
      return null;

    } catch (e) {
      print('[CONSOLE] [app_update_service]❌ Critical update check failed: $e');
      return null;
    }
  }

  /// Controlla se è il momento di verificare gli aggiornamenti
  static Future<bool> _shouldCheckForUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getString(_lastUpdateCheckKey);
      
      if (lastCheck == null) return true;
      
      final lastCheckTime = DateTime.parse(lastCheck);
      final now = DateTime.now();
      final difference = now.difference(lastCheckTime);
      
      return difference >= _updateCheckInterval;
    } catch (e) {
      print('[CONSOLE] [app_update_service]❌ Error checking last update time: $e');
      return true; // In caso di errore, controlla comunque
    }
  }

  /// Salva il timestamp dell'ultimo controllo aggiornamenti
  static Future<void> _saveLastUpdateCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUpdateCheckKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('[CONSOLE] [app_update_service]❌ Error saving update check time: $e');
    }
  }

  /// Confronta due versioni semantiche
  static int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();
    
    print('[CONSOLE] [app_update_service]🔍 Comparing versions: $version1 (${v1Parts}) vs $version2 (${v2Parts})');
    
    // Assicurati che entrambe le versioni abbiano lo stesso numero di parti
    while (v1Parts.length < v2Parts.length) v1Parts.add(0);
    while (v2Parts.length < v1Parts.length) v2Parts.add(0);
    
    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] < v2Parts[i]) {
        print('[CONSOLE] [app_update_service]🔍 Version $version1 is OLDER than $version2 (part $i: ${v1Parts[i]} < ${v2Parts[i]})');
        return -1;
      }
      if (v1Parts[i] > v2Parts[i]) {
        print('[CONSOLE] [app_update_service]🔍 Version $version1 is NEWER than $version2 (part $i: ${v1Parts[i]} > ${v2Parts[i]})');
        return 1;
      }
    }
    
    print('[CONSOLE] [app_update_service]🔍 Versions are EQUAL: $version1 = $version2');
    return 0; // Versioni uguali
  }

  /// 🔧 NUOVO: Controlla se l'utente corrente è un tester
  static Future<bool> _checkIfUserIsTester() async {
    try {
      // Usa AuthRepository per ottenere informazioni utente
      final authRepository = getIt<AuthRepository>();
      final user = await authRepository.getCurrentUser();
      
      if (user != null) {
        final isTester = user.isTester ?? false;
        print('[CONSOLE] [app_update_service]👤 User tester status: $isTester');
        return isTester;
      }
      
      print('[CONSOLE] [app_update_service]❌ No user found, assuming production user');
      return false;
    } catch (e) {
      print('[CONSOLE] [app_update_service]❌ Error checking user tester status: $e');
      return false; // In caso di errore, assume utente di produzione
    }
  }

  /// Apre il link per l'aggiornamento
  static Future<bool> openUpdateLink() async {
    try {
      String updateUrl;
      
      if (Platform.isAndroid) {
        // Link al Google Play Store
        final packageInfo = await PackageInfo.fromPlatform();
        updateUrl = 'https://play.google.com/store/apps/details?id=${packageInfo.packageName}';
      } else if (Platform.isIOS) {
        // Link all'App Store
        final packageInfo = await PackageInfo.fromPlatform();
        updateUrl = 'https://apps.apple.com/app/id${packageInfo.packageName}';
      } else {
        print('[CONSOLE] [app_update_service]❌ Platform not supported for updates');
        return false;
      }

      final uri = Uri.parse(updateUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('[CONSOLE] [app_update_service]✅ Update link opened');
        return true;
      } else {
        print('[CONSOLE] [app_update_service]❌ Cannot launch update URL');
        return false;
      }
    } catch (e) {
      print('[CONSOLE] [app_update_service]❌ Error opening update link: $e');
      return false;
    }
  }

  /// Mostra un dialog di aggiornamento
  static Future<void> showUpdateDialog(BuildContext context, AppUpdateInfo updateInfo) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: !updateInfo.updateRequired,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                updateInfo.updateRequired ? Icons.warning : Icons.system_update,
                color: updateInfo.updateRequired ? Colors.orange : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  updateInfo.updateRequired ? 'Aggiornamento Obbligatorio' : 'Aggiornamento Disponibile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: updateInfo.updateRequired ? FontWeight.bold : FontWeight.normal,
                    color: updateInfo.updateRequired ? Colors.orange : null,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                updateInfo.updateRequired 
                  ? 'È necessario aggiornare FitGymTrack per continuare a utilizzare l\'app!'
                  : 'È disponibile una nuova versione di FitGymTrack!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: updateInfo.updateRequired ? Colors.orange : null,
                  fontWeight: updateInfo.updateRequired ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Versione corrente: ${updateInfo.currentVersion}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Nuova versione: ${updateInfo.serverVersion}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (updateInfo.message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  updateInfo.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
          actions: [
            if (!updateInfo.updateRequired) ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Più tardi'),
              ),
            ],
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openUpdateLink();
              },
              child: const Text('Aggiorna ora'),
            ),
          ],
        );
      },
    );
  }
}

/// 🔧 NUOVO: Classe per le informazioni sull'aggiornamento
class AppUpdateInfo {
  final String currentVersion;
  final String currentBuild;
  final String serverVersion;
  final String serverBuild;
  final bool updateRequired;
  final String message;
  final bool hasUpdate;

  AppUpdateInfo({
    required this.currentVersion,
    required this.currentBuild,
    required this.serverVersion,
    required this.serverBuild,
    required this.updateRequired,
    required this.message,
    required this.hasUpdate,
  });

  @override
  String toString() {
    return 'AppUpdateInfo(currentVersion: $currentVersion, serverVersion: $serverVersion, updateRequired: $updateRequired)';
  }
} 