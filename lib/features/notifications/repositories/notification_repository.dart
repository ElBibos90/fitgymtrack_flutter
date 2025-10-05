// lib/features/notifications/repositories/notification_repository.dart

import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../models/notification_models.dart';

/// Repository per la gestione delle notifiche
class NotificationRepository {
  final Dio _dio;

  NotificationRepository({required Dio dio}) 
      : _dio = dio;

  /// Recupera le notifiche per l'utente corrente
  Future<NotificationResponse> getUserNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '${AppConfig.baseUrl}/notifications.php',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return NotificationResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Errore nel recupero delle notifiche: $e');
    }
  }

  /// Marca una notifica come letta
  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.put(
        '${AppConfig.baseUrl}/notifications.php',
        queryParameters: {
          'id': notificationId,
          'action': 'read',
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Errore nel marcare la notifica come letta: $e');
    }
  }

  /// Marca una notifica come non letta
  Future<void> markAsUnread(int notificationId) async {
    try {
      await _dio.put(
        '${AppConfig.baseUrl}/notifications.php',
        queryParameters: {
          'id': notificationId,
          'action': 'unread',
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Errore nel marcare la notifica come non letta: $e');
    }
  }

  /// Invia una notifica (solo per gym/trainer)
  Future<SendNotificationResponse> sendNotification(
    SendNotificationRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '${AppConfig.baseUrl}/notifications.php',
        data: request.toJson(),
      );

      return SendNotificationResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Errore nell\'invio della notifica: $e');
    }
  }

  /// Recupera le notifiche inviate (solo per gym/trainer)
  Future<NotificationResponse> getSentNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '${AppConfig.baseUrl}/notifications.php',
        queryParameters: {
          'action': 'sent',
          'page': page,
          'limit': limit,
        },
      );

      return NotificationResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Errore nel recupero delle notifiche inviate: $e');
    }
  }

  /// Recupera il conteggio delle notifiche non lette
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('${AppConfig.baseUrl}/notifications.php');
      final notificationResponse = NotificationResponse.fromJson(response.data);
      
      return notificationResponse.notifications
          .where((notification) => notification.isUnread)
          .length;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Errore nel recupero del conteggio notifiche: $e');
    }
  }

  /// Marca tutte le notifiche come lette
  Future<void> markAllAsRead() async {
    try {
      await _dio.put(
        '${AppConfig.baseUrl}/notifications.php',
        queryParameters: {
          'action': 'mark_all_read',
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Errore nel marcare tutte le notifiche come lette: $e');
    }
  }

  /// Elimina una notifica
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _dio.delete(
        '${AppConfig.baseUrl}/notifications.php',
        queryParameters: {
          'id': notificationId,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Errore nell\'eliminazione della notifica: $e');
    }
  }

  /// Gestisce gli errori Dio
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Timeout di connessione. Verifica la tua connessione internet.');
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['error'] ?? 'Errore del server';
        
        switch (statusCode) {
          case 401:
            return Exception('Non autorizzato. Effettua nuovamente il login.');
          case 403:
            return Exception('Accesso negato. Non hai i permessi necessari.');
          case 404:
            return Exception('Risorsa non trovata.');
          case 500:
            return Exception('Errore interno del server. Riprova più tardi.');
          default:
            return Exception('Errore del server: $message');
        }
      
      case DioExceptionType.cancel:
        return Exception('Operazione annullata.');
      
      case DioExceptionType.connectionError:
        return Exception('Errore di connessione. Verifica la tua connessione internet.');
      
      case DioExceptionType.badCertificate:
        return Exception('Errore di certificato SSL.');
      
      case DioExceptionType.unknown:
      default:
        return Exception('Errore sconosciuto: ${e.message}');
    }
  }
}
