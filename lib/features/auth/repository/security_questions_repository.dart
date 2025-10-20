import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/security_question_models.dart';

/// Repository per gestire le domande di sicurezza e il reset password in-app
class SecurityQuestionsRepository {
  final Dio _dio;
  final String _baseUrl = 'https://fitgymtrack.com/api';

  SecurityQuestionsRepository({Dio? dio})
      : _dio = dio ?? DioClient.getInstance();

  // =========================================================================
  // PUBLIC METHODS (NO AUTH REQUIRED)
  // =========================================================================

  /// Get le domande di sicurezza configurate dall'utente
  /// 
  /// [username] - Username dell'utente
  /// Returns: Lista di domande o errore se non configurate
  Future<GetQuestionsResponse> getQuestions(String username) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/password_reset_inapp.php',
        queryParameters: {
          'action': 'get_questions',
          'username': username,
        },
      );

      return GetQuestionsResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return GetQuestionsResponse.fromJson(e.response!.data);
      }
      rethrow;
    }
  }

  /// Verifica le risposte e resetta la password
  /// 
  /// [username] - Username dell'utente
  /// [answers] - Lista di risposte alle domande
  /// [newPassword] - Nuova password
  /// Returns: Risultato del reset (success/error)
  Future<VerifyAndResetResponse> verifyAndResetPassword({
    required String username,
    required List<UserSecurityAnswer> answers,
    required String newPassword,
  }) async {
    try {
      final request = VerifyAndResetRequest(
        username: username,
        answers: answers,
        newPassword: newPassword,
      );

      final response = await _dio.post(
        '$_baseUrl/password_reset_inapp.php',
        queryParameters: {'action': 'verify_and_reset'},
        data: request.toJson(),
      );

      return VerifyAndResetResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return VerifyAndResetResponse.fromJson(e.response!.data);
      }
      rethrow;
    }
  }

  /// Verifica lo stato dell'account (rate limiting, lockout, etc.)
  /// 
  /// [username] - Username dell'utente
  /// Returns: Status dell'account
  Future<CheckStatusResponse> checkStatus(String username) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/password_reset_inapp.php',
        queryParameters: {
          'action': 'check_status',
          'username': username,
        },
      );

      return CheckStatusResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return CheckStatusResponse.fromJson(e.response!.data);
      }
      rethrow;
    }
  }

  /// Get lista completa di domande disponibili per la configurazione
  /// 
  /// Returns: Lista di tutte le domande disponibili
  Future<ListQuestionsResponse> listAvailableQuestions() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/password_reset_inapp.php',
        queryParameters: {'action': 'list_questions'},
      );

      return ListQuestionsResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return ListQuestionsResponse.fromJson(e.response!.data);
      }
      rethrow;
    }
  }

  // =========================================================================
  // AUTHENTICATED METHODS (REQUIRE AUTH TOKEN)
  // =========================================================================

  /// Configura le domande di sicurezza per l'utente autenticato
  /// 
  /// [answers] - Lista di risposte alle domande (minimo 3)
  /// Returns: Risultato della configurazione
  /// 
  /// **REQUIRES AUTHENTICATION**
  Future<SetupQuestionsResponse> setupQuestions(
    List<UserSecurityAnswer> answers,
  ) async {
    try {
      final request = SetupQuestionsRequest(answers: answers);

      final response = await _dio.post(
        '$_baseUrl/password_reset_inapp.php',
        queryParameters: {'action': 'setup_questions'},
        data: request.toJson(),
      );

      return SetupQuestionsResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return SetupQuestionsResponse.fromJson(e.response!.data);
      }
      rethrow;
    }
  }

  // =========================================================================
  // HELPER METHODS
  // =========================================================================

  /// Valida che le risposte siano sufficienti (minimo 3)
  bool validateAnswersCount(List<UserSecurityAnswer> answers) {
    return answers.length >= 3;
  }

  /// Valida che tutte le risposte siano compilate
  bool validateAnswersNotEmpty(List<UserSecurityAnswer> answers) {
    return answers.every((answer) => answer.answer.trim().isNotEmpty);
  }

  /// Valida la lunghezza minima della password
  bool validatePasswordLength(String password, {int minLength = 6}) {
    return password.length >= minLength;
  }

  /// Formatta il messaggio di locked_until per l'utente
  String? formatLockedUntilMessage(String? lockedUntil) {
    if (lockedUntil == null || lockedUntil.isEmpty) return null;
    
    try {
      final dateTime = DateTime.parse(lockedUntil);
      final now = DateTime.now();
      final difference = dateTime.difference(now);
      
      if (difference.isNegative) return null;
      
      if (difference.inHours > 0) {
        return 'Account bloccato per altre ${difference.inHours} ore';
      } else if (difference.inMinutes > 0) {
        return 'Account bloccato per altri ${difference.inMinutes} minuti';
      } else {
        return 'Account bloccato per pochi secondi';
      }
    } catch (e) {
      return 'Account temporaneamente bloccato';
    }
  }
}

