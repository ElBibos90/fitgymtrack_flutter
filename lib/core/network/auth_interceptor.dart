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

    print('🔍 AuthInterceptor.onRequest: URL=${options.uri}');
    print('🔍 AuthInterceptor.onRequest: Token presente=${token != null && token.isNotEmpty}');
    if (token != null && token.isNotEmpty) {
      print('🔍 AuthInterceptor.onRequest: Token inviato=Bearer ${token.substring(0, 10)}...');
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      print('❌ AuthInterceptor.onRequest: NESSUN TOKEN DISPONIBILE!');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      print('[CONSOLE] [auth_interceptor]🔐 401 Unauthorized - clearing session');
      await _sessionService.clearSession();
      
      // 🔧 FIX: Non propagare l'errore 401 per evitare loop infiniti
      // L'AuthBloc gestirà il logout automatico
      print('[CONSOLE] [auth_interceptor]✅ Session cleared, error handled');
    }

    handler.next(err);
  }
}