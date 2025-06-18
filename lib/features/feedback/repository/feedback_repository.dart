// lib/features/feedback/repository/feedback_repository.dart

import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import '../../../core/network/api_client.dart';
import '../../../core/utils/result.dart';
import '../models/feedback_models.dart';

class FeedbackRepository {
  final ApiClient _apiClient;
  final Dio _dio; // ✅ Accesso diretto a Dio per multipart

  FeedbackRepository({
    required ApiClient apiClient,
    required Dio dio, // ✅ Inject Dio
  }) : _apiClient = apiClient, _dio = dio;

  // ============================================================================
  // ✅ FIX PRINCIPALE: IMPLEMENTAZIONE UPLOAD ALLEGATI
  // ============================================================================

  /// Invia un nuovo feedback con possibili allegati
  Future<Result<FeedbackResponse>> submitFeedback(
      FeedbackRequest request, {
        List<File>? attachments,
      }) async {
    try {
      log('[CONSOLE] [feedback_repository] 📤 Invio feedback: ${request.type.label}');

      if (attachments != null && attachments.isNotEmpty) {
        // ✅ NUOVO: Invio con allegati usando multipart
        return await _submitFeedbackWithAttachments(request, attachments);
      } else {
        // ✅ Invio senza allegati (JSON)
        return await _submitFeedbackWithoutAttachments(request);
      }
    } catch (e) {
      log('[CONSOLE] [feedback_repository] ❌ Errore generico: $e');
      return Result.error(
        'Si è verificato un errore imprevisto durante l\'invio del feedback',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// ✅ CORRETTO: Invio senza allegati (JSON) - usa toApiJson() esistente
  Future<Result<FeedbackResponse>> _submitFeedbackWithoutAttachments(
      FeedbackRequest request) async {
    try {
      final response = await _apiClient.submitFeedback(request.toApiJson());
      log('[CONSOLE] [feedback_repository] ✅ Risposta JSON ricevuta: ${response.toString()}');

      final feedbackResponse = FeedbackResponse.fromJson(response);

      if (feedbackResponse.success) {
        log('[CONSOLE] [feedback_repository] ✅ Feedback inviato - ID: ${feedbackResponse.feedbackId}');
        return Result.success(feedbackResponse);
      } else {
        return Result.error(
          feedbackResponse.message,
          Exception('Errore nell\'invio del feedback'),
        );
      }
    } on DioException catch (dioError) {
      return _handleDioError(dioError);
    }
  }

  /// ✅ CORRETTO: Invio con allegati (multipart/form-data) - usa .name invece di .apiValue
  Future<Result<FeedbackResponse>> _submitFeedbackWithAttachments(
      FeedbackRequest request, List<File> attachments) async {
    try {
      log('[CONSOLE] [feedback_repository] 📎 Invio con ${attachments.length} allegati');

      // Crea FormData per multipart
      final formData = FormData();

      // ✅ CORRETTO: Aggiungi campi del feedback usando i valori JSON corretti
      formData.fields.addAll([
        MapEntry('type', _getEnumJsonValue(request.type)), // ✅ USA valori JSON
        MapEntry('title', request.title),
        MapEntry('description', request.description),
        MapEntry('severity', _getEnumJsonValue(request.severity)), // ✅ USA valori JSON
        MapEntry('device_info', request.deviceInfo ?? '{}'),
      ]);

      // Aggiungi email se presente
      if (request.email != null && request.email!.isNotEmpty) {
        formData.fields.add(MapEntry('email', request.email!));
      }

      // ✅ AGGIUNGI ALLEGATI
      for (int i = 0; i < attachments.length; i++) {
        final file = attachments[i];
        if (await file.exists()) {
          final fileName = path.basename(file.path);
          final multipartFile = await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          );

          // ✅ Il PHP si aspetta 'attachments[]' per array di file
          formData.files.add(MapEntry('attachments[]', multipartFile));

          log('[CONSOLE] [feedback_repository] 📎 Allegato aggiunto: $fileName (${await file.length()} bytes)');
        }
      }

      // Invia richiesta multipart
      final response = await _dio.post(
        '/feedback_api.php',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      log('[CONSOLE] [feedback_repository] ✅ Risposta multipart: ${response.data}');

      final feedbackResponse = FeedbackResponse.fromJson(response.data);

      if (feedbackResponse.success) {
        log('[CONSOLE] [feedback_repository] ✅ Feedback con allegati inviato - ID: ${feedbackResponse.feedbackId}');
        return Result.success(feedbackResponse);
      } else {
        return Result.error(
          feedbackResponse.message,
          Exception('Errore nell\'invio del feedback con allegati'),
        );
      }
    } on DioException catch (dioError) {
      return _handleDioError(dioError);
    }
  }

  Result<FeedbackResponse> _handleDioError(DioException dioError) {
    log('[CONSOLE] [feedback_repository] ❌ Errore DIO: ${dioError.message}');

    String errorMessage;
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Timeout della connessione. Riprova più tardi.';
        break;
      case DioExceptionType.badResponse:
        errorMessage = 'Errore del server (${dioError.response?.statusCode}). Riprova più tardi.';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'Errore di connessione. Controlla la tua connessione internet.';
        break;
      default:
        errorMessage = 'Errore di rete. Riprova più tardi.';
    }

    return Result.error(errorMessage, dioError);
  }

  // ============================================================================
  // ✅ CORRETTO: METODI ESISTENTI CON RETURN TYPES CORRETTI
  // ============================================================================

  /// Recupera tutti i feedback (solo admin)
  Future<Result<List<Feedback>>> getFeedbacks() async {
    try {
      log('[CONSOLE] [feedback_repository] 📥 Recupero feedback (admin)');

      final response = await _apiClient.getFeedback();

      log('[CONSOLE] [feedback_repository] ✅ Risposta feedback ricevuta');

      // Parsing della risposta
      if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;

        if (success) {
          final feedbacksData = response['feedbacks'] as List<dynamic>? ?? [];

          final feedbacks = feedbacksData.map((feedbackJson) {
            try {
              // Converte le date string in DateTime
              if (feedbackJson['created_at'] != null) {
                feedbackJson['created_at'] = DateTime.tryParse(feedbackJson['created_at']);
              }
              if (feedbackJson['updated_at'] != null) {
                feedbackJson['updated_at'] = DateTime.tryParse(feedbackJson['updated_at']);
              }

              // Converte gli allegati
              if (feedbackJson['attachments'] != null) {
                final attachmentsData = feedbackJson['attachments'] as List<dynamic>;
                feedbackJson['attachments'] = attachmentsData
                    .map((attachJson) => FeedbackAttachment.fromJson(attachJson))
                    .toList();
              }

              return Feedback.fromJson(feedbackJson);
            } catch (e) {
              log('[CONSOLE] [feedback_repository] ⚠️ Errore parsing feedback: $e');
              // Ritorna un feedback con dati di fallback
              return Feedback(
                id: feedbackJson['id'],
                type: FeedbackType.other,
                title: feedbackJson['title'] ?? 'Titolo non disponibile',
                description: feedbackJson['description'] ?? 'Descrizione non disponibile',
                severity: FeedbackSeverity.medium,
                status: FeedbackStatus.new_,
              );
            }
          }).toList();

          log('[CONSOLE] [feedback_repository] ✅ ${feedbacks.length} feedback recuperati');
          return Result.success(feedbacks);
        } else {
          final message = response['message'] as String? ?? 'Errore nel recupero dei feedback';
          return Result.error(message, Exception(message));
        }
      } else {
        return Result.error(
          'Formato risposta non valido',
          Exception('Formato risposta non valido'),
        );
      }
    } on DioException catch (dioError) {
      return _handleDioErrorGeneric<List<Feedback>>(dioError);
    } catch (e) {
      log('[CONSOLE] [feedback_repository] ❌ Errore imprevisto: $e');
      return Result.error(
        'Errore imprevisto nel recupero dei feedback',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// ✅ CORRETTO: Aggiorna lo stato di un feedback (usa oggetto request)
  Future<Result<bool>> updateFeedbackStatus(FeedbackStatusUpdateRequest request) async {
    try {
      log('[CONSOLE] [feedback_repository] 🔄 Aggiornamento stato feedback ${request.feedbackId} -> ${request.status}');

      final response = await _apiClient.updateFeedbackStatus(
        request.toApiJson(),
        'update_status',
      );

      if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;

        if (success) {
          log('[CONSOLE] [feedback_repository] ✅ Stato feedback aggiornato');
          return Result.success(true);
        } else {
          final message = response['message'] as String? ?? 'Errore nell\'aggiornamento dello stato';
          return Result.error(message, Exception(message));
        }
      }

      return Result.error(
        'Formato risposta non valido',
        Exception('Formato risposta non valido'),
      );
    } on DioException catch (dioError) {
      return _handleDioErrorGeneric<bool>(dioError);
    } catch (e) {
      log('[CONSOLE] [feedback_repository] ❌ Errore aggiornamento stato: $e');
      return Result.error(
        'Errore nell\'aggiornamento dello stato del feedback',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// ✅ CORRETTO: Aggiorna le note admin di un feedback (usa oggetto request)
  Future<Result<bool>> updateFeedbackNotes(FeedbackNotesUpdateRequest request) async {
    try {
      log('[CONSOLE] [feedback_repository] 📝 Aggiornamento note feedback ${request.feedbackId}');

      final response = await _apiClient.updateFeedbackNotes(
        request.toApiJson(),
        'update_notes',
      );

      if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;

        if (success) {
          log('[CONSOLE] [feedback_repository] ✅ Note feedback aggiornate');
          return Result.success(true);
        } else {
          final message = response['message'] as String? ?? 'Errore nell\'aggiornamento delle note';
          return Result.error(message, Exception(message));
        }
      }

      return Result.error(
        'Formato risposta non valido',
        Exception('Formato risposta non valido'),
      );
    } on DioException catch (dioError) {
      return _handleDioErrorGeneric<bool>(dioError);
    } catch (e) {
      log('[CONSOLE] [feedback_repository] ❌ Errore aggiornamento note: $e');
      return Result.error(
        'Errore nell\'aggiornamento delle note del feedback',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// ✅ NUOVO: Verifica se l'utente corrente è admin (usando SessionService)
  Future<Result<bool>> isCurrentUserAdmin() async {
    try {
      // Per ora ritorniamo false, poi integreremo con SessionService
      log('[CONSOLE] [feedback_repository] 🔍 Verifica permessi admin (TODO: integrare con SessionService)');
      return Result.success(false);
    } catch (e) {
      log('[CONSOLE] [feedback_repository] ❌ Errore verifica admin: $e');
      return Result.error(
        'Errore nella verifica dei permessi',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ============================================================================
  // ✅ METODI HELPER STATICI (per attachment widget)
  // ============================================================================

  /// Ottiene la dimensione massima supportata (5MB)
  static int get maxFileSize => 5 * 1024 * 1024;

  /// Formatta la dimensione del file in formato leggibile
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Valida se un file immagine è supportato per l'upload
  static bool isFileSupported(String fileName) {
    final supportedExtensions = [
      'jpg', 'jpeg', 'png', 'gif',  // Solo immagini
    ];

    final extension = fileName.split('.').last.toLowerCase();
    return supportedExtensions.contains(extension);
  }

  // ============================================================================
  // ✅ HELPER GENERICO PER ERRORI DIO
  // ============================================================================

  /// Helper per ottenere il valore JSON corretto degli enum
  String _getEnumJsonValue(dynamic enumValue) {
    if (enumValue is FeedbackType) {
      const map = {
        FeedbackType.bug: 'bug',
        FeedbackType.feature: 'feature',
        FeedbackType.suggestion: 'suggestion',
        FeedbackType.complaint: 'complaint',
        FeedbackType.compliment: 'compliment',
        FeedbackType.other: 'other',
      };
      return map[enumValue]!;
    } else if (enumValue is FeedbackSeverity) {
      const map = {
        FeedbackSeverity.low: 'low',
        FeedbackSeverity.medium: 'medium',
        FeedbackSeverity.high: 'high',
        FeedbackSeverity.critical: 'critical',
      };
      return map[enumValue]!;
    }
    return enumValue.toString();
  }

  /// Helper generico per gestire errori Dio con return type corretto
  Result<T> _handleDioErrorGeneric<T>(DioException dioError) {
    log('[CONSOLE] [feedback_repository] ❌ Errore DIO: ${dioError.message}');

    String errorMessage;
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Timeout della connessione. Riprova più tardi.';
        break;
      case DioExceptionType.badResponse:
        errorMessage = 'Errore del server (${dioError.response?.statusCode}). Riprova più tardi.';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'Errore di connessione. Controlla la tua connessione internet.';
        break;
      default:
        errorMessage = 'Errore di rete. Riprova più tardi.';
    }

    return Result.error(errorMessage, dioError);
  }
}