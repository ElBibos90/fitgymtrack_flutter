// lib/core/services/biometric_auth_service.dart

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service per gestione autenticazione biometrica (Face ID / Fingerprint)
class BiometricAuthService {
  // Singleton pattern
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  // Local Auth instance
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Secure Storage instance
  // 🔧 ANDROID FIX: Disabilito encryptedSharedPreferences che può causare perdita dati
  // Su Android 6+, usiamo il KeyStore nativo che è più affidabile
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: false,  // ✅ FIX: usa KeyStore invece di EncryptedSharedPrefs
      resetOnError: true,  // ✅ FIX: previene errori di corruzione
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage Keys
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricUsernameKey = 'biometric_username';
  static const String _biometricPasswordKey = 'biometric_password';

  // ============================================================================
  // PUBLIC METHODS
  // ============================================================================

  /// Verifica se il dispositivo supporta autenticazione biometrica
  Future<bool> isBiometricAvailable() async {
    try {
      print('[ACCESS] 🔍 Checking biometric availability...');
      
      // 1. Verifica se il dispositivo ha hardware biometrico
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      print('[ACCESS]   - canCheckBiometrics: $canCheckBiometrics');
      
      // 2. Verifica se il dispositivo è supportato
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      print('[ACCESS]   - isDeviceSupported: $isDeviceSupported');
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        print('[ACCESS] ⚠️ Biometric not available (hardware or support issue)');
        return false;
      }

      // 3. Verifica se almeno un tipo di biometrico è disponibile
      final List<BiometricType> availableBiometrics = 
          await _localAuth.getAvailableBiometrics();
      print('[ACCESS]   - availableBiometrics: $availableBiometrics');
      
      final isAvailable = availableBiometrics.isNotEmpty;
      print('[ACCESS] ✅ Biometric available: $isAvailable');
      
      return isAvailable;
    } catch (e) {
      print('[ACCESS] ❌ Error checking biometric availability: $e');
      return false;
    }
  }

  /// Ottiene il tipo di biometrico disponibile (per UI)
  Future<String> getBiometricType() async {
    try {
      final List<BiometricType> availableBiometrics = 
          await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return 'Fingerprint';
      } else if (availableBiometrics.contains(BiometricType.iris)) {
        return 'Iris';
      } else if (availableBiometrics.contains(BiometricType.strong)) {
        return 'Biometric';
      }
      return 'Biometric';
    } catch (e) {
      return 'Biometric';
    }
  }

  /// Autentica l'utente con biometrico
  /// 🔧 ANDROID FIX: Aggiunto retry automatico per errori temporanei
  Future<bool> authenticateWithBiometrics({String? reason, int maxRetries = 2}) async {
    int attempts = 0;
    
    while (attempts <= maxRetries) {
      try {
        print('[ACCESS] 🔐 Starting biometric authentication (attempt ${attempts + 1}/${maxRetries + 1})...');
        final String localizedReason = reason ?? 
            'Autenticati per accedere a FitGymTrack';

        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: localizedReason,
          options: const AuthenticationOptions(
            stickyAuth: true,  // Rimane attivo anche se app va in background
            biometricOnly: true,  // Solo biometrico (no PIN/password device)
            useErrorDialogs: true,  // Mostra dialog errori nativi
            sensitiveTransaction: true,  // Trattamento dati sensibili
          ),
        );

        if (didAuthenticate) {
          print('[ACCESS] ✅ Biometric authentication successful');
          return true;
        } else {
          print('[ACCESS] ❌ Biometric authentication failed (user cancelled or failed)');
          return false;
        }
      } on PlatformException catch (e) {
        print('[ACCESS] ❌ Platform exception during biometric auth: ${e.code} - ${e.message}');
        
        // Handle specific error codes
        if (e.code == 'NotAvailable') {
          print('[ACCESS]   - Error: Biometric not available on device');
          return false;
        } else if (e.code == 'NotEnrolled') {
          print('[ACCESS]   - Error: User hasn\'t enrolled biometrics');
          return false;
        } else if (e.code == 'LockedOut') {
          print('[ACCESS]   - Error: Too many failed attempts (temporary lockout)');
          throw BiometricException('Troppi tentativi falliti. Riprova più tardi.');
        } else if (e.code == 'PermanentlyLockedOut') {
          print('[ACCESS]   - Error: Permanently locked out');
          throw BiometricException('Biometrico disabilitato. Usa la password.');
        } else if (e.code == 'auth_in_progress' || e.code == 'AuthenticationInProgress') {
          // 🔧 ANDROID FIX: Errore temporaneo, riprova dopo un delay
          print('[ACCESS]   - Error: auth_in_progress, retrying after delay...');
          attempts++;
          if (attempts <= maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * attempts));
            continue;  // Riprova
          }
          return false;
        }
        
        return false;
      } catch (e) {
        print('[ACCESS] ❌ Unexpected error during biometric auth: $e');
        // 🔧 ANDROID FIX: Per errori generici, riprova una volta
        attempts++;
        if (attempts <= maxRetries) {
          print('[ACCESS]   - Retrying after unexpected error...');
          await Future.delayed(Duration(milliseconds: 300 * attempts));
          continue;
        }
        return false;
      }
    }
    
    print('[ACCESS] ❌ Max retries reached, giving up');
    return false;
  }

  /// Salva username e password in modo sicuro per biometric login
  Future<void> saveCredentialsSecurely(String username, String password) async {
    try {
      await _secureStorage.write(key: _biometricUsernameKey, value: username);
      await _secureStorage.write(key: _biometricPasswordKey, value: password);
    } catch (e) {
      throw BiometricException('Impossibile salvare credenziali in modo sicuro');
    }
  }

  /// Recupera username e password salvati
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      print('[ACCESS] 📖 Reading saved credentials...');
      
      final username = await _secureStorage.read(key: _biometricUsernameKey);
      print('[ACCESS]   - Username read: ${username != null ? username : "NULL"}');
      
      final password = await _secureStorage.read(key: _biometricPasswordKey);
      print('[ACCESS]   - Password read: ${password != null ? "Present (${password.length} chars)" : "NULL"}');
      
      if (username != null && password != null) {
        // ✅ VALIDAZIONE: Verifica che le credenziali siano valide
        if (username.trim().isEmpty) {
          print('[ACCESS] ❌ Username is empty after trim, invalid credentials');
          return null;
        }
        if (password.isEmpty) {
          print('[ACCESS] ❌ Password is empty, invalid credentials');
          return null;
        }
        if (password.length < 3) {
          print('[ACCESS] ❌ Password too short (${password.length} chars), invalid credentials');
          return null;
        }
        
        print('[ACCESS] ✅ Credentials retrieved and validated successfully');
        return {'username': username, 'password': password};
      }
      
      print('[ACCESS] ⚠️ No saved credentials found (username=$username, password=${password != null})');
      return null;
    } catch (e) {
      print('[ACCESS] ❌ Error reading credentials: $e');
      return null;
    }
  }

  /// Verifica se l'autenticazione biometrica è abilitata dall'utente
  Future<bool> isBiometricEnabled() async {
    try {
      print('[ACCESS] 🔍 Checking if biometric is enabled...');
      final enabled = await _secureStorage.read(key: _biometricEnabledKey);
      print('[ACCESS]   - Enabled flag: $enabled');
      final isEnabled = enabled == 'true';
      print('[ACCESS] ${isEnabled ? "✅" : "⚠️"} Biometric is ${isEnabled ? "ENABLED" : "DISABLED"}');
      return isEnabled;
    } catch (e) {
      print('[ACCESS] ❌ Error checking if enabled: $e');
      return false;
    }
  }

  /// Abilita l'autenticazione biometrica
  Future<void> enableBiometric(String username, String password) async {
    try {
      // Verifica che il biometrico sia disponibile
      if (!await isBiometricAvailable()) {
        throw BiometricException('Biometrico non disponibile su questo dispositivo');
      }

      // Richiedi autenticazione prima di abilitare
      final authenticated = await authenticateWithBiometrics(
        reason: 'Abilita l\'accesso biometrico',
      );

      if (!authenticated) {
        throw BiometricException('Autenticazione fallita');
      }

      // Salva username/password e abilita biometrico
      await saveCredentialsSecurely(username, password);
      await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
      
    } catch (e) {
      rethrow;
    }
  }

  /// Disabilita l'autenticazione biometrica
  Future<void> disableBiometric() async {
    try {
      print('[ACCESS] 🔒 Disabling biometric authentication (no confirmation)...');
      // Elimina credenziali e disabilita (senza richiedere autenticazione)
      await _secureStorage.delete(key: _biometricUsernameKey);
      print('[ACCESS]   - Username deleted');
      await _secureStorage.delete(key: _biometricPasswordKey);
      print('[ACCESS]   - Password deleted');
      await _secureStorage.delete(key: _biometricEnabledKey);
      print('[ACCESS]   - Enabled flag deleted');
      
      print('[ACCESS] ✅ Biometric authentication disabled');
    } catch (e) {
      print('[ACCESS] ❌ Error disabling biometric: $e');
      rethrow;
    }
  }

  /// Disabilita biometrico con conferma (per settings)
  Future<void> disableBiometricWithConfirmation() async {
    try {
      print('[ACCESS] 🔒 Disabling biometric authentication WITH confirmation...');
      // Richiedi conferma con autenticazione
      final authenticated = await authenticateWithBiometrics(
        reason: 'Conferma per disabilitare l\'accesso biometrico',
      );

      if (!authenticated) {
        print('[ACCESS] ❌ Cannot disable: authentication failed');
        throw BiometricException('Autenticazione fallita');
      }

      // Elimina credenziali e disabilita
      await _secureStorage.delete(key: _biometricUsernameKey);
      print('[ACCESS]   - Username deleted');
      await _secureStorage.delete(key: _biometricPasswordKey);
      print('[ACCESS]   - Password deleted');
      await _secureStorage.delete(key: _biometricEnabledKey);
      print('[ACCESS]   - Enabled flag deleted');
      
      print('[ACCESS] ✅ Biometric authentication disabled with confirmation');
    } catch (e) {
      print('[ACCESS] ❌ Error disabling biometric: $e');
      rethrow;
    }
  }

  /// Cancella tutte le credenziali salvate (per logout completo)
  Future<void> clearAllBiometricData() async {
    try {
      print('[ACCESS] 🗑️ CLEARING ALL BIOMETRIC DATA (LOGOUT)...');
      await _secureStorage.delete(key: _biometricUsernameKey);
      print('[ACCESS]   - Username deleted');
      await _secureStorage.delete(key: _biometricPasswordKey);
      print('[ACCESS]   - Password deleted');
      await _secureStorage.delete(key: _biometricEnabledKey);
      print('[ACCESS]   - Enabled flag deleted');
      print('[ACCESS] ✅ All biometric data cleared');
    } catch (e) {
      print('[ACCESS] ❌ Error clearing data: $e');
    }
  }

  /// Aggiorna credenziali biometriche salvate (se biometrico già abilitato)
  /// Usato dopo login manuale o reset password per sincronizzare
  Future<void> updateCredentials(String username, String password) async {
    try {
      print('[ACCESS] 🔄 Updating biometric credentials...');
      print('[ACCESS]   - Username: $username');
      
      // 🔧 FIX: Valida che le credenziali siano valide prima di aggiornare
      if (username.trim().isEmpty || password.isEmpty) {
        print('[ACCESS] ⚠️ Invalid credentials provided, skipping update');
        return;
      }
      
      // 🔧 PRODUZIONE FIX: Se biometric non è abilitato, abilitalo automaticamente
      if (!await isBiometricEnabled()) {
        print('[ACCESS] 🔓 Biometric not enabled, enabling automatically...');
        try {
          await enableBiometric(username, password);
          print('[ACCESS] ✅ Biometric enabled automatically after login');
        } catch (e) {
          print('[ACCESS] ⚠️ Failed to enable biometric automatically: $e');
          // Non propagare l'errore - abilitazione automatica è opzionale
        }
      } else {
        print('[ACCESS]   - Biometric is enabled, updating credentials');
        await saveCredentialsSecurely(username, password);
        print('[ACCESS] ✅ Biometric credentials updated silently');
      }
    } catch (e) {
      print('[ACCESS] ❌ Error updating credentials: $e');
      // Non propagare l'errore - aggiornamento credenziali è operazione silenziosa
    }
  }
}

/// Custom exception per errori biometrici
class BiometricException implements Exception {
  final String message;
  BiometricException(this.message);

  @override
  String toString() => message;
}

