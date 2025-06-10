import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/session_service.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/password_reset_models.dart';

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
      print('[CONSOLE] [auth_repository]Tentativo di login per: $username');

      final loginRequest = LoginRequest(
        username: username,
        password: password,
      );

      final response = await _apiClient.login('login', loginRequest);

      print('[CONSOLE] [auth_repository]Risposta login: ${response.toJson()}');

      if (response.token != null && response.user != null) {
        await sessionService.saveSession(response.token!, response.user!);
      }

      return Result.success(response);
    } catch (e) {
      print('[CONSOLE] [auth_repository]Errore login: ${e.toString()}');
      return Result.failure(_handleApiError(e));
    }
  }

  Future<Result<RegisterResponse>> register(
      String username,
      String password,
      String email,
      String name,
      ) async {
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
      if (e is DioException && e.response?.statusCode == 409) {
        final errorResponse = RegisterResponse(
          success: false,
          message: "Username o email già in uso. Prova con credenziali diverse.",
        );
        return Result.success(errorResponse);
      } else {
        print('[CONSOLE] [auth_repository]Errore registrazione: ${e.toString()}');
        return Result.failure(_handleApiError(e));
      }
    }
  }

  Future<Result<PasswordResetResponse>> requestPasswordReset(String email) async {
    try {
      final resetRequest = PasswordResetRequest(email: email);

      final responseData = await _apiClient.requestPasswordReset('request', resetRequest);

      print('[CONSOLE] [auth_repository]Password reset response: $responseData');

      final responseBody = responseData.toString();
      if (responseBody.contains('<b>Warning</b>') ||
          responseBody.contains('<b>Fatal error</b>') ||
          responseBody.contains('<br />')) {

        print('[CONSOLE] [auth_repository]Risposta contiene errori PHP: $responseBody');
        return Result.success(PasswordResetResponse(
          success: false,
          message: "Errore del server. Contatta l'amministratore del sistema.",
        ));
      }

      try {
        final Map<String, dynamic> jsonData;
        if (responseData is String) {
          jsonData = jsonDecode(responseData);
        } else {
          jsonData = responseData as Map<String, dynamic>;
        }

        final success = jsonData['success'] ?? false;
        final message = jsonData['message'] ?? '';
        final token = jsonData['token'];

        return Result.success(PasswordResetResponse(
          success: success,
          message: message,
          token: token,
        ));
      } catch (jsonEx) {
        print('[CONSOLE] [auth_repository]Risposta non è JSON valido: $responseData');
        return Result.success(PasswordResetResponse(
          success: false,
          message: "Errore nel formato della risposta. Riprova più tardi.",
        ));
      }
    } catch (e) {
      print('[CONSOLE] [auth_repository]Errore richiesta reset password: ${e.toString()}');
      return Result.failure(_handleApiError(e));
    }
  }

  Future<Result<PasswordResetConfirmResponse>> confirmPasswordReset(
      String token,
      String code,
      String newPassword,
      ) async {
    try {
      final resetConfirmRequest = PasswordResetConfirmRequest(
        token: token,
        code: code,
        newPassword: newPassword,
      );

      final responseData = await _apiClient.confirmPasswordReset('reset', resetConfirmRequest);

      print('[CONSOLE] [auth_repository]Reset password response: $responseData');

      final responseBody = responseData.toString();
      if (responseBody.contains('<b>Warning</b>') ||
          responseBody.contains('<b>Fatal error</b>') ||
          responseBody.contains('<br />')) {

        return Result.success(PasswordResetConfirmResponse(
          success: false,
          message: "Errore del server. Contatta l'amministratore del sistema.",
        ));
      }

      try {
        final Map<String, dynamic> jsonData;
        if (responseData is String) {
          jsonData = jsonDecode(responseData);
        } else {
          jsonData = responseData as Map<String, dynamic>;
        }

        final success = jsonData['success'] ?? false;
        final message = jsonData['message'] ?? '';

        return Result.success(PasswordResetConfirmResponse(
          success: success,
          message: message,
        ));
      } catch (jsonEx) {
        return Result.success(PasswordResetConfirmResponse(
          success: false,
          message: "Errore nel formato della risposta. Riprova più tardi.",
        ));
      }
    } catch (e) {
      print('[CONSOLE] [auth_repository]Errore conferma reset password: ${e.toString()}');
      return Result.failure(_handleApiError(e));
    }
  }

  Future<Result<void>> logout() async {
    try {
      await sessionService.clearSession();
      return Result.success(null);
    } catch (e) {
      return Result.failure(AuthException('Errore durante il logout: ${e.toString()}'));
    }
  }

  Future<bool> isAuthenticated() async {
    return await sessionService.isAuthenticated();
  }

  Future<User?> getCurrentUser() async {
    return await sessionService.getUserData();
  }

  AuthException _handleApiError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return AuthException('Timeout di connessione. Verifica la tua connessione.');

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          switch (statusCode) {
            case 401:
              return AuthException('Credenziali non valide.');
            case 409:
              return AuthException('Username o email già in uso.');
            case 500:
              return AuthException('Errore del server. Riprova più tardi.');
            default:
              return AuthException('Errore dal server: $statusCode');
          }

        case DioExceptionType.cancel:
          return AuthException('Richiesta annullata.');

        case DioExceptionType.unknown:
          return AuthException('Impossibile connettersi al server. Verifica la tua connessione.');

        default:
          return AuthException('Errore di rete sconosciuto.');
      }
    }

    return AuthException(error.toString());
  }
}

class Result<T> {
  final T? data;
  final AuthException? error;
  final bool isSuccess;

  Result._(this.data, this.error, this.isSuccess);

  factory Result.success(T data) => Result._(data, null, true);
  factory Result.failure(AuthException error) => Result._(null, error, false);

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AuthException error) onFailure,
  }) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    } else if (error != null) {
      return onFailure(error!);
    } else {
      return onFailure(AuthException('Stato risultato sconosciuto'));
    }
  }
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}