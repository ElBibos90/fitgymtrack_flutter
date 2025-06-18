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
      log('[CONSOLE] [feedback_bloc] 📥 Avvio caricamento feedback');

      // Emette stato di caricamento
      emit(const FeedbacksLoading());

      // Prima verifica se l'utente è admin
      final adminResult = await _feedbackRepository.isCurrentUserAdmin();
      bool isAdmin = false;

      adminResult.fold(
        onSuccess: (adminStatus) {
          isAdmin = adminStatus;
          log('[CONSOLE] [feedback_bloc] 🔍 Permessi admin: $isAdmin');
        },
        onFailure: (exception, message) {
          log('[CONSOLE] [feedback_bloc] ⚠️ Errore verifica admin: $message');
          // Continua comunque con il caricamento
        },
      );

      // Carica i feedback
      final result = await _feedbackRepository.getFeedbacks();

      result.fold(
        onSuccess: (feedbacks) {
          log('[CONSOLE] [feedback_bloc] ✅ ${feedbacks.length} feedback caricati');
          emit(FeedbacksLoaded(
            feedbacks: feedbacks,
            loadedAt: DateTime.now(),
            isAdmin: isAdmin,
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
    } catch (e) {
      log('[CONSOLE] [feedback_bloc] ❌ Errore imprevisto in _onLoadFeedbacks: $e');
      emit(FeedbackError.loading(
        'Si è verificato un errore imprevisto durante il caricamento',
        e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler per l'aggiornamento dello stato di un feedback
  Future<void> _onUpdateFeedbackStatus(
      UpdateFeedbackStatus event,
      Emitter<FeedbackState> emit,
      ) async {
    try {
      log('[CONSOLE] [feedback_bloc] 📝 Aggiornamento stato feedback ${event.feedbackId} -> ${event.newStatus.label}');

      // Emette stato di aggiornamento
      emit(FeedbackStatusUpdating(
        feedbackId: event.feedbackId,
        newStatus: event.newStatus,
      ));

      // Crea la request
      final request = FeedbackStatusUpdateRequest(
        feedbackId: event.feedbackId,
        status: event.newStatus,
      );

      // Chiama il repository
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

            // Ricarica automaticamente i feedback per aggiornare la lista
            add(const LoadFeedbacks());
          } else {
            log('[CONSOLE] [feedback_bloc] ❌ Aggiornamento stato fallito');
            emit(FeedbackError.update('Aggiornamento dello stato fallito'));
          }
        },
        onFailure: (exception, message) {
          log('[CONSOLE] [feedback_bloc] ❌ Errore aggiornamento stato: $message');
          emit(FeedbackError.update(
            message ?? 'Errore nell\'aggiornamento dello stato',
            exception,
          ));
        },
      );
    } catch (e) {
      log('[CONSOLE] [feedback_bloc] ❌ Errore imprevisto in _onUpdateFeedbackStatus: $e');
      emit(FeedbackError.update(
        'Si è verificato un errore imprevisto durante l\'aggiornamento',
        e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler per l'aggiornamento delle note admin
  Future<void> _onUpdateFeedbackNotes(
      UpdateFeedbackNotes event,
      Emitter<FeedbackState> emit,
      ) async {
    try {
      log('[CONSOLE] [feedback_bloc] 📝 Aggiornamento note feedback ${event.feedbackId}');

      // Emette stato di aggiornamento
      emit(FeedbackNotesUpdating(feedbackId: event.feedbackId));

      // Crea la request
      final request = FeedbackNotesUpdateRequest(
        feedbackId: event.feedbackId,
        adminNotes: event.adminNotes,
      );

      // Chiama il repository
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

            // Ricarica automaticamente i feedback per aggiornare la lista
            add(const LoadFeedbacks());
          } else {
            log('[CONSOLE] [feedback_bloc] ❌ Aggiornamento note fallito');
            emit(FeedbackError.update('Aggiornamento delle note fallito'));
          }
        },
        onFailure: (exception, message) {
          log('[CONSOLE] [feedback_bloc] ❌ Errore aggiornamento note: $message');
          emit(FeedbackError.update(
            message ?? 'Errore nell\'aggiornamento delle note',
            exception,
          ));
        },
      );
    } catch (e) {
      log('[CONSOLE] [feedback_bloc] ❌ Errore imprevisto in _onUpdateFeedbackNotes: $e');
      emit(FeedbackError.update(
        'Si è verificato un errore imprevisto durante l\'aggiornamento',
        e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Handler per la verifica dei permessi admin
  Future<void> _onCheckAdminPermissions(
      CheckAdminPermissions event,
      Emitter<FeedbackState> emit,
      ) async {
    try {
      log('[CONSOLE] [feedback_bloc] 🔍 Verifica permessi admin');

      // Emette stato di caricamento
      emit(const FeedbackLoading(message: 'Verifica permessi...'));

      // Verifica i permessi
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
          emit(FeedbackError(
            message: message ?? 'Errore nella verifica dei permessi',
            exception: exception,
            occurredAt: DateTime.now(),
            operation: 'permissions',
          ));
        },
      );
    } catch (e) {
      log('[CONSOLE] [feedback_bloc] ❌ Errore imprevisto in _onCheckAdminPermissions: $e');
      emit(FeedbackError(
        message: 'Si è verificato un errore imprevisto nella verifica dei permessi',
        exception: e is Exception ? e : Exception(e.toString()),
        occurredAt: DateTime.now(),
        operation: 'permissions',
      ));
    }
  }

  /// Handler per il reset dello stato
  Future<void> _onResetFeedbackState(
      ResetFeedbackState event,
      Emitter<FeedbackState> emit,
      ) async {
    log('[CONSOLE] [feedback_bloc] 🔄 Reset stato feedback');
    emit(const FeedbackInitial());
  }

  /// Getter di convenienza per verificare se lo stato corrente è di loading
  bool get isLoading {
    return state is FeedbackLoading ||
        state is FeedbackSubmitting ||
        state is FeedbacksLoading ||
        state is FeedbackStatusUpdating ||
        state is FeedbackNotesUpdating;
  }

  /// Getter di convenienza per verificare se l'ultimo invio è stato successful
  bool get lastSubmissionSuccessful {
    return state is FeedbackSubmitted;
  }

  /// Getter di convenienza per ottenere i feedback caricati
  List<Feedback> get currentFeedbacks {
    if (state is FeedbacksLoaded) {
      return (state as FeedbacksLoaded).feedbacks;
    }
    return [];
  }

  /// Getter di convenienza per verificare se l'utente corrente è admin
  bool get isCurrentUserAdmin {
    if (state is FeedbacksLoaded) {
      return (state as FeedbacksLoaded).isAdmin;
    }
    if (state is AdminPermissionsChecked) {
      return (state as AdminPermissionsChecked).isAdmin;
    }
    return false;
  }

  @override
  void onChange(Change<FeedbackState> change) {
    super.onChange(change);
    log('[CONSOLE] [feedback_bloc] 🔄 State change: ${change.currentState.runtimeType} -> ${change.nextState.runtimeType}');
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    log('[CONSOLE] [feedback_bloc] ❌ BLoC Error: $error');
    super.onError(error, stackTrace);
  }
}