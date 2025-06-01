import 'package:dio/dio.dart';
import '../services/session_service.dart';

class AuthInterceptor extends Interceptor {
  final SessionService _sessionService;

  AuthInterceptor(this._sessionService);

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final token = await _sessionService.getAuthToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _sessionService.clearSession();
    }

    handler.next(err);
  }
}