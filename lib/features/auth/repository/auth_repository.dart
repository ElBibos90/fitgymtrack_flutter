import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/session_service.dart';
import '../../../core/utils/result.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/password_reset_models.dart';

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final ApiClient _apiClient;
  final SessionService sessionService;

  AuthRepository({
    required ApiClient apiClient,
    required SessionService sessionService,
  })  : _apiClient = apiClient,
        sessionService = sessionService;

  Future<Result<LoginResponse>> login(String username, String password) async {
    try {
      ////print('[CONSOLE] [auth_repository]Tentativo di login per: $username');

      final loginRequest = LoginRequest(
        username: username,
        password: password,
      );

      final response = await _apiClient.login('login', loginRequest);

      ////print('[CONSOLE] [auth_repository]Risposta login: ${response.toJson()}');

      if (response.token != null && response.user != null) {
        await sessionService.saveSession(response.token!, response.user!);
      }

      return Result.success(response);
    } catch (e) {
      ////print('[CONSOLE] [auth_repository]Errore login: ${e.toString()}');
      return Result.error(_handleApiError(e).toString(), _handleApiError(e));
    }
  }

  Future<Result<RegisterResponse>> register(
      String username, String password, String email, String name) async {
    try {
      final registerRequest = RegisterRequest(
        username: username,
        password: password,
        email: email,
        name: name,
      );

      final response = await _apiClient.register(registerRequest);

      return Result.success(response);
    } catch (e) {
        return Result.error(_handleApiError(e).toString(), _handleApiError(e));
    }
  }

  Future<Result<PasswordResetResponse>> requestPasswordReset(String email) async {
    try {
      final request = PasswordResetRequest(email: email);
      final response = await _apiClient.requestPasswordReset('forgot-password', request);
      return Result.success(response);
    } catch (e) {
      return Result.error(_handleApiError(e).toString(), _handleApiError(e));
    }
  }

  Future<Result<PasswordResetConfirmResponse>> confirmPasswordReset(
      String token, String code, String newPassword) async {
    try {
      final request = PasswordResetConfirmRequest(
        token: token,
        code: code,
        newPassword: newPassword,
      );
      final response = await _apiClient.confirmPasswordReset('reset-password', request);
      return Result.success(response);
    } catch (e) {
      return Result.error(_handleApiError(e).toString(), _handleApiError(e));
    }
  }

  Future<Result<void>> logout() async {
    try {
      final token = await sessionService.getAuthToken();
      if (token != null) {
        await _apiClient.logout('logout', {'token': token});
      }
      await sessionService.clearSession();
      return Result.success(null);
    } catch (e) {
      // Anche se il logout fallisce, pulisci la sessione locale
      await sessionService.clearSession();
      return Result.error(_handleApiError(e).toString(), _handleApiError(e));
    }
  }

  /// 🔧 AGGIORNATO: Usa la validazione intelligente del token
  Future<bool> isAuthenticated() async {
    try {
      // Prima controlla se c'è un token
      final hasToken = await sessionService.isAuthenticated();
      if (!hasToken) {
        print('[CONSOLE] [auth_repository]❌ No token found');
        return false;
      }

      // Poi valida il token in modo intelligente
      final isValid = await sessionService.validateTokenIntelligently();
      //print('[CONSOLE] [auth_repository]🔍 Token validation result: $isValid');
      return isValid;
      
    } catch (e) {
      print('[CONSOLE] [auth_repository]❌ Authentication check failed: $e');
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
    return await sessionService.getUserData();
    } catch (e) {
      print('[CONSOLE] [auth_repository]❌ Error getting current user: $e');
      return null;
    }
  }

  Exception _handleApiError(dynamic error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return AuthException('Credenziali non valide');
      } else if (error.response?.statusCode == 400) {
        final data = error.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('error')) {
          return AuthException(data['error']);
        }
        return AuthException('Dati non validi');
      } else if (error.response?.statusCode == 500) {
        return AuthException('Errore del server');
      } else if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return AuthException('Timeout di connessione');
      } else if (error.type == DioExceptionType.connectionError) {
        return AuthException('Errore di connessione');
      }
    }
    return AuthException('Errore sconosciuto');
  }
}