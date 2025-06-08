import 'package:dio/dio.dart';


class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String errorMessage = 'Errore sconosciuto';

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Timeout di connessione. Verifica la tua connessione.';
        break;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        switch (statusCode) {
          case 400:
            errorMessage = 'Richiesta non valida';
            break;
          case 401:
            errorMessage = 'Non autorizzato. Effettua nuovamente il login.';
            break;
          case 403:
            errorMessage = 'Accesso negato';
            break;
          case 404:
            errorMessage = 'Risorsa non trovata';
            break;
          case 409:
            errorMessage = 'Conflitto nei dati. Username o email già in uso.';
            break;
          case 500:
            errorMessage = 'Errore interno del server. Riprova più tardi.';
            break;
          default:
            errorMessage = 'Errore dal server: $statusCode';
        }
        break;

      case DioExceptionType.cancel:
        errorMessage = 'Richiesta annullata';
        break;

      case DioExceptionType.unknown:
        if (err.message?.contains('SocketException') == true) {
          errorMessage = 'Impossibile connettersi al server. Verifica la tua connessione.';
        } else {
          errorMessage = 'Errore di rete: ${err.message}';
        }
        break;

      default:
        errorMessage = 'Errore di rete sconosciuto';
    }

    print('API Error: $errorMessage');

    final customError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: errorMessage,
      message: errorMessage,
    );

    handler.next(customError);
  }
}