// lib/features/feedback/presentation/bloc/feedback_state.dart

import 'package:equatable/equatable.dart';
import '../../models/feedback_models.dart';

abstract class FeedbackState extends Equatable {
  const FeedbackState();

  @override
  List<Object?> get props => [];
}

/// Stato iniziale
class FeedbackInitial extends FeedbackState {
  const FeedbackInitial();

  @override
  String toString() => 'FeedbackInitial()';
}

/// Stato generico di loading
class FeedbackLoading extends FeedbackState {
  final String? message;

  const FeedbackLoading({this.message});

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'FeedbackLoading(message: $message)';
}

/// Stato durante l'invio di un feedback
class FeedbackSubmitting extends FeedbackState {
  final FeedbackRequest request;

  const FeedbackSubmitting({required this.request});

  @override
  List<Object?> get props => [request];

  @override
  String toString() => 'FeedbackSubmitting(type: ${request.type})';
}

/// Stato dopo l'invio con successo
class FeedbackSubmitted extends FeedbackState {
  final FeedbackResponse response;
  final DateTime submittedAt;

  const FeedbackSubmitted({
    required this.response,
    required this.submittedAt,
  });

  @override
  List<Object?> get props => [response, submittedAt];

  @override
  String toString() => 'FeedbackSubmitted(id: ${response.feedbackId})';
}

/// Stato durante il caricamento dei feedback
class FeedbacksLoading extends FeedbackState {
  const FeedbacksLoading();

  @override
  String toString() => 'FeedbacksLoading()';
}

/// Stato con i feedback caricati
class FeedbacksLoaded extends FeedbackState {
  final List<Feedback> feedbacks;
  final DateTime loadedAt;
  final bool isAdmin;

  const FeedbacksLoaded({
    required this.feedbacks,
    required this.loadedAt,
    this.isAdmin = false,
  });

  @override
  List<Object?> get props => [feedbacks, loadedAt, isAdmin];

  /// Getter per feedback raggruppati per stato
  Map<FeedbackStatus, List<Feedback>> get feedbacksByStatus {
    final Map<FeedbackStatus, List<Feedback>> grouped = {};

    for (final feedback in feedbacks) {
      grouped.putIfAbsent(feedback.status, () => []).add(feedback);
    }

    return grouped;
  }

  /// Getter per conteggi per stato
  Map<FeedbackStatus, int> get statusCounts {
    final Map<FeedbackStatus, int> counts = {};

    for (final feedback in feedbacks) {
      counts[feedback.status] = (counts[feedback.status] ?? 0) + 1;
    }

    return counts;
  }

  /// Getter per feedback recenti (ultimi 7 giorni)
  List<Feedback> get recentFeedbacks {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return feedbacks
        .where((feedback) =>
    feedback.createdAt != null &&
        feedback.createdAt!.isAfter(sevenDaysAgo))
        .toList();
  }

  @override
  String toString() => 'FeedbacksLoaded(count: ${feedbacks.length}, isAdmin: $isAdmin)';
}

/// Stato durante l'aggiornamento dello stato di un feedback
class FeedbackStatusUpdating extends FeedbackState {
  final int feedbackId;
  final FeedbackStatus newStatus;

  const FeedbackStatusUpdating({
    required this.feedbackId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [feedbackId, newStatus];

  @override
  String toString() => 'FeedbackStatusUpdating(id: $feedbackId, status: $newStatus)';
}

/// Stato dopo aggiornamento dello stato con successo
class FeedbackStatusUpdated extends FeedbackState {
  final int feedbackId;
  final FeedbackStatus newStatus;
  final DateTime updatedAt;

  const FeedbackStatusUpdated({
    required this.feedbackId,
    required this.newStatus,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [feedbackId, newStatus, updatedAt];

  @override
  String toString() => 'FeedbackStatusUpdated(id: $feedbackId, status: $newStatus)';
}

/// Stato durante l'aggiornamento delle note admin
class FeedbackNotesUpdating extends FeedbackState {
  final int feedbackId;

  const FeedbackNotesUpdating({required this.feedbackId});

  @override
  List<Object?> get props => [feedbackId];

  @override
  String toString() => 'FeedbackNotesUpdating(id: $feedbackId)';
}

/// Stato dopo aggiornamento delle note con successo
class FeedbackNotesUpdated extends FeedbackState {
  final int feedbackId;
  final String adminNotes;
  final DateTime updatedAt;

  const FeedbackNotesUpdated({
    required this.feedbackId,
    required this.adminNotes,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [feedbackId, adminNotes, updatedAt];

  @override
  String toString() => 'FeedbackNotesUpdated(id: $feedbackId)';
}

/// Stato per permessi admin verificati
class AdminPermissionsChecked extends FeedbackState {
  final bool isAdmin;
  final DateTime checkedAt;

  const AdminPermissionsChecked({
    required this.isAdmin,
    required this.checkedAt,
  });

  @override
  List<Object?> get props => [isAdmin, checkedAt];

  @override
  String toString() => 'AdminPermissionsChecked(isAdmin: $isAdmin)';
}

/// Stato di errore
class FeedbackError extends FeedbackState {
  final String message;
  final Exception? exception;
  final DateTime occurredAt;
  final String? operation; // Tipo di operazione che ha causato l'errore

  const FeedbackError({
    required this.message,
    this.exception,
    required this.occurredAt,
    this.operation,
  });

  @override
  List<Object?> get props => [message, exception, occurredAt, operation];

  /// Costruttore di convenienza per errori di invio
  factory FeedbackError.submission(String message, [Exception? exception]) {
    return FeedbackError(
      message: message,
      exception: exception,
      occurredAt: DateTime.now(),
      operation: 'submit',
    );
  }

  /// Costruttore di convenienza per errori di caricamento
  factory FeedbackError.loading(String message, [Exception? exception]) {
    return FeedbackError(
      message: message,
      exception: exception,
      occurredAt: DateTime.now(),
      operation: 'load',
    );
  }

  /// Costruttore di convenienza per errori di aggiornamento
  factory FeedbackError.update(String message, [Exception? exception]) {
    return FeedbackError(
      message: message,
      exception: exception,
      occurredAt: DateTime.now(),
      operation: 'update',
    );
  }

  @override
  String toString() => 'FeedbackError(message: $message, operation: $operation)';
}