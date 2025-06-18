// lib/features/feedback/repository/feedback_repository.dart

import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/result.dart';
import '../models/feedback_models.dart';

class FeedbackRepository {
  final ApiClient _apiClient;

  FeedbackRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  /// Invia un nuovo feedback con possibili allegati
  Future<Result<FeedbackResponse>> submitFeedback(
      FeedbackRequest request, {
        List<File>? attachments,
      }) async {
    try {
      log('[CONSOLE] [feedback_repository] 📤 Invio feedback: ${request.type.label}');

      // Per ora inviamo solo JSON (senza allegati)
      // TODO: Implementare upload multipart per allegati in futuro
      if (attachments != null && attachments.isNotEmpty) {
        log('[CONSOLE] [feedback_repository] ⚠️ Allegati presenti ma upload multipart non implementato ancora');
        // Per ora procediamo senza allegati
      }

      final response = await _apiClient.submitFeedback(request.toApiJson());

      log('[CONSOLE] [feedback_repository] ✅ Risposta ricevuta: ${response.toString()}');

      // Converte la risposta in FeedbackResponse
      final feedbackResponse = FeedbackResponse.fromJson(response);

      if (feedbackResponse.success) {
        log('[CONSOLE] [feedback_repository] ✅ Feedback inviato con successo - ID: ${feedbackResponse.feedbackId}');
        return Result.success(feedbackResponse);
      } else {
        log('[CONSOLE] [feedback_repository] ❌ Errore nell\'invio: ${feedbackResponse.message}');
        return Result.error(
          feedbackResponse.message,
          Exception('Errore nell\'invio del feedback'),
        );
      }
    } on DioException catch (dioError) {
      log('[CONSOLE] [feedback_repository] ❌ Errore DIO: ${dioError.message}');

      // Gestisce gli errori specifici di rete
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
    } catch (e) {
      log('[CONSOLE] [feedback_repository] ❌ Errore generico: $e');
      return Result.error(
        'Si è verificato un errore imprevisto durante l\'invio del feedback',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

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
          final message = response['message'] as String? ?? 'Errore sconosciuto';
          log('[CONSOLE] [feedback_repository] ❌ Errore API: $message');
          return Result.error(message, Exception('Errore API'));
        }
      } else {
        log('[CONSOLE] [feedback_repository] ❌ Formato risposta non valido');
        return Result.error(
          'Formato di risposta inaspettato dal server',
          Exception('Formato risposta non valido'),
        );
      }
    } on DioException catch (dioError) {
      log('[CONSOLE] [feedback_repository] ❌ Errore DIO nel recupero: ${dioError.message}');

      String errorMessage = 'Errore di rete nel recupero dei feedback';
      if (dioError.response?.statusCode == 403) {
        errorMessage = 'Non hai i permessi per visualizzare i feedback';
      }

      return Result.error(errorMessage, dioError);
    } catch (e) {
      log('[CONSOLE] [feedback_repository] ❌ Errore generico nel recupero: $e');
      return Result.error(
        'Errore nel recupero dei feedback',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Aggiorna lo stato di un feedback (solo admin)
  Future<Result<bool>> updateFeedbackStatus(FeedbackStatusUpdateRequest request) async {
    try {
      log('[CONSOLE] [feedback_repository] 📝 Aggiornamento stato feedback ${request.feedbackId} -> ${request.status.label}');

      final response = await _apiClient.updateFeedbackStatus(
        request.toApiJson(),
        'update_status',
      );

      if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;
        final message = response['message'] as String? ?? 'Operazione completata';

        if (success) {
          log('[CONSOLE] [feedback_repository] ✅ Stato aggiornato con successo');
          return Result.success(true);
        } else {
          log('[CONSOLE] [feedback_repository] ❌ Errore aggiornamento stato: $message');
          return Result.error(message, Exception('Errore aggiornamento stato'));
        }
      } else {
        return Result.error(
          'Risposta del server non valida',
          Exception('Formato risposta non valido'),
        );
      }
    } on DioException catch (dioError) {
      log('[CONSOLE] [feedback_repository] ❌ Errore DIO aggiornamento stato: ${dioError.message}');
      return Result.error('Errore di rete nell\'aggiornamento dello stato', dioError);
    } catch (e) {
      log('[CONSOLE] [feedback_repository] ❌ Errore generico aggiornamento stato: $e');
      return Result.error(
        'Errore nell\'aggiornamento dello stato del feedback',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Aggiorna le note admin di un feedback (solo admin)
  Future<Result<bool>> updateFeedbackNotes(FeedbackNotesUpdateRequest request) async {
    try {
      log('[CONSOLE] [feedback_repository] 📝 Aggiornamento note feedback ${request.feedbackId}');

      final response = await _apiClient.updateFeedbackNotes(
        request.toApiJson(),
        'update_notes',
      );

      if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;
        final message = response['message'] as String? ?? 'Operazione completata';

        if (success) {
          log('[CONSOLE] [feedback_repository] ✅ Note aggiornate con successo');
          return Result.success(true);
        } else {
          log('[CONSOLE] [feedback_repository] ❌ Errore aggiornamento note: $message');
          return Result.error(message, Exception('Errore aggiornamento note'));
        }
      } else {
        return Result.error(
          'Risposta del server non valida',
          Exception('Formato risposta non valido'),
        );
      }
    } on DioException catch (dioError) {
      log('[CONSOLE] [feedback_repository] ❌ Errore DIO aggiornamento note: ${dioError.message}');
      return Result.error('Errore di rete nell\'aggiornamento delle note', dioError);
    } catch (e) {
      log('[CONSOLE] [feedback_repository] ❌ Errore generico aggiornamento note: $e');
      return Result.error(
        'Errore nell\'aggiornamento delle note del feedback',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Verifica se l'utente corrente è admin (utilizzando SessionService)
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

  /// Ottiene informazioni sul dispositivo per il feedback
  String getDeviceInfo() {
    try {
      // TODO: Implementare il recupero delle info dispositivo
      // Per ora ritorniamo dati di base
      return 'Flutter App - Device info TODO';
    } catch (e) {
      log('[CONSOLE] [feedback_repository] ⚠️ Errore recupero info dispositivo: $e');
      return 'Device info non disponibile';
    }
  }

  /// Valida se un file immagine è supportato per l'upload
  static bool isFileSupported(String fileName) {
    final supportedExtensions = [
      'jpg', 'jpeg', 'png', 'gif',  // Solo immagini
    ];

    final extension = fileName.split('.').last.toLowerCase();
    return supportedExtensions.contains(extension);
  }

  /// Ottiene la dimensione massima supportata (5MB)
  static int get maxFileSize => 5 * 1024 * 1024;

  /// Formatta la dimensione del file in formato leggibile
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}