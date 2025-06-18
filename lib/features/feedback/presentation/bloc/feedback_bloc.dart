// lib/features/feedback/presentation/bloc/feedback_bloc.dart

import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/feedback_repository.dart';
import '../../models/feedback_models.dart';
import 'feedback_event.dart';
import 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final FeedbackRepository _feedbackRepository;

  FeedbackBloc({
    required FeedbackRepository feedbackRepository,
  })  : _feedbackRepository = feedbackRepository,
        super(const FeedbackInitial()) {
    // Registra gli handler per ogni evento
    on<SubmitFeedback>(_onSubmitFeedback);
    on<LoadFeedbacks>(_onLoadFeedbacks);
    on<UpdateFeedbackStatus>(_onUpdateFeedbackStatus);
    on<UpdateFeedbackNotes>(_onUpdateFeedbackNotes);
    on<CheckAdminPermissions>(_onCheckAdminPermissions);
    on<ResetFeedbackState>(_onResetFeedbackState);
  }

  /// Handler per l'invio di un feedback
  Future<void> _onSubmitFeedback(
      SubmitFeedback event,
      Emitter<FeedbackState> emit,
      ) async {
    try {
      log('[CONSOLE] [feedback_bloc] 📤 Avvio invio feedback: ${event.request.type.label}');

      // Emette stato di caricamento
      emit(FeedbackSubmitting(request: event.request));

      // Chiama il repository per inviare il feedback
      final result = await _feedbackRepository.submitFeedback(
        event.request,
        attachments: event.attachments,
      );

      // Gestisce il risultato
      result.fold(
        onSuccess: (feedbackResponse) {
          log('[CONSOLE] [feedback_bloc] ✅ Feedback inviato con successo - ID: ${feedbackResponse.feedbackId}');
          emit(FeedbackSubmitted(
            response: feedbackResponse,
            submittedAt: DateTime.now(),
          ));
        },
        onFailure: (exception, message) {
          log('[CONSOLE] [feedback_bloc] ❌ Errore invio feedback: $message');
          emit(FeedbackError.submission(
            message ?? 'Errore nell\'invio del feedback',
            exception,
          ));
        },
      );
    } catch (e) {
      log('[CONSOLE] [feedback_bloc] ❌ Errore imprevisto in _onSubmitFeedback: $e');
      emit(FeedbackError.submission(
        'Si è verificato un errore imprevisto durante l\'invio',
        e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler per il caricamento dei feedback (admin)
  Future<void> _onLoadFeedbacks(
      LoadFeedbacks event,
      Emitter<FeedbackState> emit,
      ) async {
    try {
      log('[CONSOLE] [feedback_bloc] 📥 Caricamento feedback (admin)');

      // Prima verifica se l'utente è admin
      final adminResult = await _feedbackRepository.isCurrentUserAdmin();

      adminResult.fold(
        onSuccess: (isAdmin) async {
          if (!isAdmin) {
            emit(FeedbackError.loading('Non hai i permessi per visualizzare i feedback'));
            return;
          }

          // Emette stato di caricamento
          emit(const FeedbackLoading());

          // Carica i feedback
          final result = await _feedbackRepository.getFeedbacks();

          result.fold(
            onSuccess: (feedbacks) {
              log('[CONSOLE] [feedback_bloc] ✅ ${feedbacks.length} feedback caricati');
              emit(FeedbacksLoaded(
                feedbacks: feedbacks,
                isAdmin: true,
                loadedAt: DateTime.now(),
              ));
            },
            onFailure: (exception, message) {
              log('[CONSOLE] [feedback_bloc] ❌ Errore caricamento feedback: $message');
              emit(FeedbackError.loading(
                message ?? 'Errore nel caricamento dei feedback',
                exception,
              ));
            },
          );
        },
        onFailure: (exception, message) {
          emit(FeedbackError.loading('Errore nella verifica dei permessi'));
        },
      );
    } catch (e) {
      log('[CONSOLE] [feedback_bloc] ❌ Errore imprevisto in _onLoadFeedbacks: $e');
      emit(FeedbackError.loading(
        'Si è verificato un errore imprevisto',
        e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler per l'aggiornamento dello stato di un feedback (admin)
  Future<void> _onUpdateFeedbackStatus(
      UpdateFeedbackStatus event,
      Emitter<FeedbackState> emit,
      ) async {
    try {
      log('[CONSOLE] [feedback_bloc] 🔄 Aggiornamento stato feedback ${event.feedbackId} -> ${event.newStatus}');

      // ✅ CORRETTO: Usa oggetto request
      final request = FeedbackStatusUpdateRequest(
        feedbackId: event.feedbackId,
        status: event.newStatus,
      );
      final result = await _feedbackRepository.updateFeedbackStatus(request);

      result.fold(
        onSuccess: (success) {
          if (success) {
            log('[CONSOLE] [feedback_bloc] ✅ Stato feedback aggiornato con successo');
            emit(FeedbackStatusUpdated(
              feedbackId: event.feedbackId,
              newStatus: event.newStatus,
              updatedAt: DateTime.now(),
            ));
          } else {
            emit(FeedbackError.update('Errore nell\'aggiornamento dello stato'));
          }
        },
        onFailure: (exception, message) {
          log('[CONSOLE] [feedback_bloc] ❌ Errore aggiornamento stato: $message');
          emit(FeedbackError.update(
            message ?? 'Errore nell\'aggiornamento dello stato del feedback',
            exception,
          ));
        },
      );
    } catch (e) {
      log('[CONSOLE] [feedback_bloc] ❌ Errore imprevisto in _onUpdateFeedbackStatus: $e');
      emit(FeedbackError.update(
        'Si è verificato un errore imprevisto',
        e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler per l'aggiornamento delle note admin di un feedback
  Future<void> _onUpdateFeedbackNotes(
      UpdateFeedbackNotes event,
      Emitter<FeedbackState> emit,
      ) async {
    try {
      log('[CONSOLE] [feedback_bloc] 📝 Aggiornamento note feedback ${event.feedbackId}');

      // ✅ CORRETTO: Usa oggetto request
      final request = FeedbackNotesUpdateRequest(
        feedbackId: event.feedbackId,
        adminNotes: event.adminNotes,
      );
      final result = await _feedbackRepository.updateFeedbackNotes(request);

      result.fold(
        onSuccess: (success) {
          if (success) {
            log('[CONSOLE] [feedback_bloc] ✅ Note feedback aggiornate con successo');
            emit(FeedbackNotesUpdated(
              feedbackId: event.feedbackId,
              adminNotes: event.adminNotes,
              updatedAt: DateTime.now(),
            ));
          } else {
            emit(FeedbackError.update('Errore nell\'aggiornamento delle note'));
          }
        },
        onFailure: (exception, message) {
          log('[CONSOLE] [feedback_bloc] ❌ Errore aggiornamento note: $message');
          emit(FeedbackError.update(
            message ?? 'Errore nell\'aggiornamento delle note del feedback',
            exception,
          ));
        },
      );
    } catch (e) {
      log('[CONSOLE] [feedback_bloc] ❌ Errore imprevisto in _onUpdateFeedbackNotes: $e');
      emit(FeedbackError.update(
        'Si è verificato un errore imprevisto',
        e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler per il reset dello stato del BLoC
  void _onResetFeedbackState(
      ResetFeedbackState event,
      Emitter<FeedbackState> emit,
      ) {
    log('[CONSOLE] [feedback_bloc] 🔄 Reset stato del BLoC');
    emit(const FeedbackInitial());
  }

  /// Handler per la verifica dei permessi admin
  Future<void> _onCheckAdminPermissions(
      CheckAdminPermissions event,
      Emitter<FeedbackState> emit,
      ) async {
    try {
      log('[CONSOLE] [feedback_bloc] 🔍 Verifica permessi admin');

      final result = await _feedbackRepository.isCurrentUserAdmin();

      result.fold(
        onSuccess: (isAdmin) {
          log('[CONSOLE] [feedback_bloc] ✅ Permessi admin verificati: $isAdmin');
          emit(AdminPermissionsChecked(
            isAdmin: isAdmin,
            checkedAt: DateTime.now(),
          ));
        },
        onFailure: (exception, message) {
          log('[CONSOLE] [feedback_bloc] ❌ Errore verifica permessi: $message');
          emit(FeedbackError.loading(
            message ?? 'Errore nella verifica dei permessi',
            exception,
          ));
        },
      );
    } catch (e) {
      log('[CONSOLE] [feedback_bloc] ❌ Errore imprevisto in _onCheckAdminPermissions: $e');
      emit(FeedbackError.loading(
        'Si è verificato un errore imprevisto nella verifica dei permessi',
        e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}