import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

/// Repository per gestire il check del primo login e password temporanee
class CheckFirstLoginRepository {
  final Dio _dio;
  final String _baseUrl = 'https://fitgymtrack.com/api';

  CheckFirstLoginRepository({Dio? dio})
      : _dio = dio ?? DioClient.getInstance();

  /// Verifica se l'utente è al primo login (password temporanea)
  /// 
  /// Returns: CheckFirstLoginResponse con informazioni sul primo login
  Future<CheckFirstLoginResponse> checkFirstLogin() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/check_first_login.php',
      );

      return CheckFirstLoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        return CheckFirstLoginResponse.fromJson(e.response!.data);
      }
      rethrow;
    }
  }
}

/// Response model per il check del primo login
class CheckFirstLoginResponse {
  final bool success;
  final String message;
  final bool firstLogin;
  final bool hasSecurityQuestions;

  CheckFirstLoginResponse({
    required this.success,
    required this.message,
    required this.firstLogin,
    required this.hasSecurityQuestions,
  });

  factory CheckFirstLoginResponse.fromJson(Map<String, dynamic> json) {
    return CheckFirstLoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      firstLogin: json['first_login'] ?? false,
      hasSecurityQuestions: json['has_security_questions'] ?? false,
    );
  }
}

