import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../features/auth/models/login_response.dart';
import '../network/api_client.dart';
import '../di/dependency_injection.dart';
import 'cache_cleanup_service.dart';

class SessionService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _lastTokenValidationKey = 'last_token_validation';

  // 🔧 ANDROID FIX: Usa stessa configurazione del BiometricAuthService
  // Per evitare storage backend diversi che causano perdita dati biometrici
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: false,  // ✅ FIX: usa KeyStore nativo come BiometricAuthService
      resetOnError: true,  // ✅ FIX: previene errori di corruzione
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    final isAuth = token != null && token.isNotEmpty;
    //debugPrint('🔍 SessionService.isAuthenticated: Token presente=${token != null}, Token non vuoto=${token?.isNotEmpty ?? false}, Risultato=$isAuth');
    if (token != null && token.isNotEmpty) {
      //debugPrint('🔍 SessionService.isAuthenticated: Token=${token.substring(0, 10)}...');
    }
    return isAuth;
  }

  /// 🔧 NUOVO: Valida il token con il server
  Future<bool> validateTokenWithServer() async {
    try {
      final token = await getAuthToken();
      if (token == null || token.isEmpty) {
        //debugPrint('[CONSOLE] [session_service]❌ No token found');
        return false;
      }

      // Usa l'ApiClient per verificare il token
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.verifyToken('verify');
      
      // 🔧 FIX: Controlla il contenuto della risposta
      if (response is Map<String, dynamic>) {
        if (response.containsKey('error')) {
          //debugPrint('[CONSOLE] [session_service]❌ Token validation failed: ${response['error']}');
          await clearSession();
          return false;
        }
        
        // Se non c'è errore, il token è valido
        //debugPrint('[CONSOLE] [session_service]✅ Token validation successful');
        await _saveLastValidationTime();
        return true;
      }
      
      // Se la risposta non è un Map, considera il token valido
      //debugPrint('[CONSOLE] [session_service]✅ Token validation successful (non-map response)');
      await _saveLastValidationTime();
      return true;
      
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        //debugPrint('[CONSOLE] [session_service]❌ Token expired (401)');
        await clearSession();
        return false;
      }
      //debugPrint('[CONSOLE] [session_service]⚠️ Token validation error: ${e.message}');
      return false;
    } catch (e) {
      //debugPrint('[CONSOLE] [session_service]❌ Token validation failed: $e');
      return false;
    }
  }

  /// 🔧 NUOVO: Verifica se il token è stato validato recentemente
  Future<bool> isTokenRecentlyValidated({Duration threshold = const Duration(hours: 1)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastValidation = prefs.getString(_lastTokenValidationKey);
      
      if (lastValidation == null) return false;
      
      final lastValidationTime = DateTime.parse(lastValidation);
      final now = DateTime.now();
      final difference = now.difference(lastValidationTime);
      
      return difference < threshold;
    } catch (e) {
      //debugPrint('[CONSOLE] [session_service]❌ Error checking last validation: $e');
      return false;
    }
  }

  /// 🔧 NUOVO: Salva il timestamp dell'ultima validazione
  Future<void> _saveLastValidationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastTokenValidationKey, DateTime.now().toIso8601String());
    } catch (e) {
      //debugPrint('[CONSOLE] [session_service]❌ Error saving validation time: $e');
    }
  }

  /// 🔧 NUOVO: Verifica intelligente del token (locale + server se necessario)
  Future<bool> validateTokenIntelligently() async {
    //debugPrint('[CONSOLE] [session_service]🔍 Starting intelligent token validation...');
    
    // Prima controlla se è stato validato recentemente
    if (await isTokenRecentlyValidated()) {
      //debugPrint('[CONSOLE] [session_service]✅ Token recently validated, skipping server check');
      return true;
    }

    //debugPrint('[CONSOLE] [session_service]🌐 Token not recently validated, checking with server...');
    // Altrimenti valida con il server
    return await validateTokenWithServer();
  }

  Future<void> saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }

  Future<User?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      }
      return null;
    } catch (e) {
      await clearUserData();
      return null;
    }
  }

  Future<void> saveSession(String token, User user) async {
    await Future.wait([
      saveAuthToken(token),
      saveUserData(user),
      _saveLastValidationTime(), // Salva anche il timestamp di validazione
    ]);
  }

  Future<void> clearSession() async {
    // 1. Pulisci SOLO i token di autenticazione (NON le credenziali biometriche)
    await Future.wait([
      _secureStorage.delete(key: _tokenKey),  // Cancella solo il token di sessione
      clearUserData(),
      _clearLastValidationTime(),
    ]);
    
    // 2. Pulisci cache non essenziali (mantiene solo schede e offline)
    await CacheCleanupService.clearNonEssentialCaches();
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  /// 🔧 NUOVO: Pulisce il timestamp di validazione
  Future<void> _clearLastValidationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastTokenValidationKey);
    } catch (e) {
      //debugPrint('[CONSOLE] [session_service]❌ Error clearing validation time: $e');
    }
  }

  Future<int?> getCurrentUserId() async {
    final user = await getUserData();
    return user?.id;
  }

  Future<String?> getCurrentUsername() async {
    final user = await getUserData();
    return user?.username;
  }

  Future<bool> isPremiumUser() async {
    final user = await getUserData();
    return user?.roleId == 2;
  }
}