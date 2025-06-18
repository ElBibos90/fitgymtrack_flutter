// lib/features/feedback/presentation/bloc/feedback_event.dart

import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../models/feedback_models.dart';

abstract class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object?> get props => [];
}

/// Evento per inviare un nuovo feedback con possibili allegati
class SubmitFeedback extends FeedbackEvent {
  final FeedbackRequest request;
  final List<File>? attachments;

  const SubmitFeedback({
    required this.request,
    this.attachments,
  });

  @override
  List<Object?> get props => [request, attachments];

  @override
  String toString() => 'SubmitFeedback(type: ${request.type}, title: ${request.title}, attachments: ${attachments?.length ?? 0})';
}

/// Evento per caricare tutti i feedback (admin)
class LoadFeedbacks extends FeedbackEvent {
  const LoadFeedbacks();

  @override
  String toString() => 'LoadFeedbacks()';
}

/// Evento per aggiornare lo stato di un feedback (admin)
class UpdateFeedbackStatus extends FeedbackEvent {
  final int feedbackId;
  final FeedbackStatus newStatus;

  const UpdateFeedbackStatus({
    required this.feedbackId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [feedbackId, newStatus];

  @override
  String toString() => 'UpdateFeedbackStatus(id: $feedbackId, status: $newStatus)';
}

/// Evento per aggiornare le note admin di un feedback
class UpdateFeedbackNotes extends FeedbackEvent {
  final int feedbackId;
  final String adminNotes;

  const UpdateFeedbackNotes({
    required this.feedbackId,
    required this.adminNotes,
  });

  @override
  List<Object?> get props => [feedbackId, adminNotes];

  @override
  String toString() => 'UpdateFeedbackNotes(id: $feedbackId, notes: ${adminNotes.length} chars)';
}

/// Evento per resettare lo stato del BLoC
class ResetFeedbackState extends FeedbackEvent {
  const ResetFeedbackState();

  @override
  String toString() => 'ResetFeedbackState()';
}

/// Evento per verificare se l'utente è admin
class CheckAdminPermissions extends FeedbackEvent {
  const CheckAdminPermissions();

  @override
  String toString() => 'CheckAdminPermissions()';
}