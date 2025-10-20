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
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
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
      print('[LOGIN] 🔍 Checking biometric availability...');
      
      // 1. Verifica se il dispositivo ha hardware biometrico
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      print('[LOGIN]   - canCheckBiometrics: $canCheckBiometrics');
      
      // 2. Verifica se il dispositivo è supportato
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      print('[LOGIN]   - isDeviceSupported: $isDeviceSupported');
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        print('[LOGIN] ⚠️ Biometric not available (hardware or support issue)');
        return false;
      }

      // 3. Verifica se almeno un tipo di biometrico è disponibile
      final List<BiometricType> availableBiometrics = 
          await _localAuth.getAvailableBiometrics();
      print('[LOGIN]   - availableBiometrics: $availableBiometrics');
      
      final isAvailable = availableBiometrics.isNotEmpty;
      print('[LOGIN] ✅ Biometric available: $isAvailable');
      
      return isAvailable;
    } catch (e) {
      print('[LOGIN] ❌ Error checking biometric availability: $e');
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
  Future<bool> authenticateWithBiometrics({String? reason}) async {
    try {
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
        print('[LOGIN] ✅ Authentication successful');
      } else {
        print('[LOGIN] ❌ Authentication failed');
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('[LOGIN] ❌ Platform exception: ${e.code} - ${e.message}');
      
      // Handle specific error codes
      if (e.code == 'NotAvailable') {
        // Biometric not available on device
        return false;
      } else if (e.code == 'NotEnrolled') {
        // User hasn't enrolled biometrics
        return false;
      } else if (e.code == 'LockedOut') {
        // Too many failed attempts
        throw BiometricException('Troppi tentativi falliti. Riprova più tardi.');
      } else if (e.code == 'PermanentlyLockedOut') {
        // Permanently locked out
        throw BiometricException('Biometrico disabilitato. Usa la password.');
      }
      
      return false;
    } catch (e) {
      print('[LOGIN] ❌ Unexpected error: $e');
      return false;
    }
  }

  /// Salva username e password in modo sicuro per biometric login
  Future<void> saveCredentialsSecurely(String username, String password) async {
    try {
      await _secureStorage.write(key: _biometricUsernameKey, value: username);
      await _secureStorage.write(key: _biometricPasswordKey, value: password);
      print('[LOGIN] ✅ Credentials saved securely');
    } catch (e) {
      print('[LOGIN] ❌ Error saving credentials: $e');
      throw BiometricException('Impossibile salvare credenziali in modo sicuro');
    }
  }

  /// Recupera username e password salvati
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final username = await _secureStorage.read(key: _biometricUsernameKey);
      final password = await _secureStorage.read(key: _biometricPasswordKey);
      
      if (username != null && password != null) {
        print('[LOGIN] ✅ Credentials retrieved successfully');
        return {'username': username, 'password': password};
      }
      
      print('[LOGIN] ⚠️ No saved credentials found');
      return null;
    } catch (e) {
      print('[LOGIN] ❌ Error reading credentials: $e');
      return null;
    }
  }

  /// Verifica se l'autenticazione biometrica è abilitata dall'utente
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      print('[LOGIN] ❌ Error checking if enabled: $e');
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
      
      print('[LOGIN] ✅ Biometric authentication enabled');
    } catch (e) {
      print('[LOGIN] ❌ Error enabling biometric: $e');
      rethrow;
    }
  }

  /// Disabilita l'autenticazione biometrica
  Future<void> disableBiometric() async {
    try {
      // Elimina credenziali e disabilita (senza richiedere autenticazione)
      await _secureStorage.delete(key: _biometricUsernameKey);
      await _secureStorage.delete(key: _biometricPasswordKey);
      await _secureStorage.delete(key: _biometricEnabledKey);
      
      print('[LOGIN] ✅ Biometric authentication disabled');
    } catch (e) {
      print('[LOGIN] ❌ Error disabling biometric: $e');
      rethrow;
    }
  }

  /// Disabilita biometrico con conferma (per settings)
  Future<void> disableBiometricWithConfirmation() async {
    try {
      // Richiedi conferma con autenticazione
      final authenticated = await authenticateWithBiometrics(
        reason: 'Conferma per disabilitare l\'accesso biometrico',
      );

      if (!authenticated) {
        throw BiometricException('Autenticazione fallita');
      }

      // Elimina credenziali e disabilita
      await _secureStorage.delete(key: _biometricUsernameKey);
      await _secureStorage.delete(key: _biometricPasswordKey);
      await _secureStorage.delete(key: _biometricEnabledKey);
      
      print('[LOGIN] ✅ Biometric authentication disabled with confirmation');
    } catch (e) {
      print('[LOGIN] ❌ Error disabling biometric: $e');
      rethrow;
    }
  }

  /// Cancella tutte le credenziali salvate (per logout completo)
  Future<void> clearAllBiometricData() async {
    try {
      await _secureStorage.delete(key: _biometricUsernameKey);
      await _secureStorage.delete(key: _biometricPasswordKey);
      await _secureStorage.delete(key: _biometricEnabledKey);
      print('[LOGIN] ✅ All biometric data cleared');
    } catch (e) {
      print('[LOGIN] ❌ Error clearing data: $e');
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

