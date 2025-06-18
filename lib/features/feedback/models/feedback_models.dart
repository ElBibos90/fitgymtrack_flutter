// lib/features/feedback/models/feedback_models.dart

import 'package:json_annotation/json_annotation.dart';

part 'feedback_models.g.dart';

/// Enum per i tipi di feedback
enum FeedbackType {
  @JsonValue('bug')
  bug,
  @JsonValue('feature')
  feature,
  @JsonValue('suggestion')
  suggestion,
  @JsonValue('complaint')
  complaint,
  @JsonValue('compliment')
  compliment,
  @JsonValue('other')
  other,
}

/// Enum per la gravità del feedback
enum FeedbackSeverity {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

/// Enum per lo stato del feedback
enum FeedbackStatus {
  @JsonValue('new')
  new_,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('closed')
  closed,
  @JsonValue('rejected')
  rejected,
}

/// Extension per ottenere le label localizzate
extension FeedbackTypeExtension on FeedbackType {
  String get label {
    switch (this) {
      case FeedbackType.bug:
        return 'Bug/Errore';
      case FeedbackType.feature:
        return 'Richiesta Feature';
      case FeedbackType.suggestion:
        return 'Suggerimento';
      case FeedbackType.complaint:
        return 'Reclamo';
      case FeedbackType.compliment:
        return 'Complimento';
      case FeedbackType.other:
        return 'Altro';
    }
  }

  String get icon {
    switch (this) {
      case FeedbackType.bug:
        return '🐛';
      case FeedbackType.feature:
        return '✨';
      case FeedbackType.suggestion:
        return '💡';
      case FeedbackType.complaint:
        return '😞';
      case FeedbackType.compliment:
        return '😊';
      case FeedbackType.other:
        return '📝';
    }
  }
}

extension FeedbackSeverityExtension on FeedbackSeverity {
  String get label {
    switch (this) {
      case FeedbackSeverity.low:
        return 'Bassa';
      case FeedbackSeverity.medium:
        return 'Media';
      case FeedbackSeverity.high:
        return 'Alta';
      case FeedbackSeverity.critical:
        return 'Critica';
    }
  }

  String get color {
    switch (this) {
      case FeedbackSeverity.low:
        return 'green';
      case FeedbackSeverity.medium:
        return 'orange';
      case FeedbackSeverity.high:
        return 'red';
      case FeedbackSeverity.critical:
        return 'darkred';
    }
  }
}

extension FeedbackStatusExtension on FeedbackStatus {
  String get label {
    switch (this) {
      case FeedbackStatus.new_:
        return 'Nuovo';
      case FeedbackStatus.inProgress:
        return 'In Lavorazione';
      case FeedbackStatus.closed:
        return 'Chiuso';
      case FeedbackStatus.rejected:
        return 'Rifiutato';
    }
  }
}

/// Modello per un allegato del feedback
@JsonSerializable()
class FeedbackAttachment {
  final int? id;
  final int? feedbackId;
  final String filename;
  final String originalName;
  final int fileSize;
  final String? filePath;

  const FeedbackAttachment({
    this.id,
    this.feedbackId,
    required this.filename,
    required this.originalName,
    required this.fileSize,
    this.filePath,
  });

  factory FeedbackAttachment.fromJson(Map<String, dynamic> json) =>
      _$FeedbackAttachmentFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackAttachmentToJson(this);

  FeedbackAttachment copyWith({
    int? id,
    int? feedbackId,
    String? filename,
    String? originalName,
    int? fileSize,
    String? filePath,
  }) {
    return FeedbackAttachment(
      id: id ?? this.id,
      feedbackId: feedbackId ?? this.feedbackId,
      filename: filename ?? this.filename,
      originalName: originalName ?? this.originalName,
      fileSize: fileSize ?? this.fileSize,
      filePath: filePath ?? this.filePath,
    );
  }
}

/// Modello principale per il feedback
@JsonSerializable()
class Feedback {
  final int? id;
  final int? userId;
  final FeedbackType type;
  final String title;
  final String description;
  final String? email;
  final FeedbackSeverity severity;
  final String? deviceInfo;
  final FeedbackStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? adminNotes;
  final String? username;
  final String? userName;
  final List<FeedbackAttachment>? attachments;

  const Feedback({
    this.id,
    this.userId,
    required this.type,
    required this.title,
    required this.description,
    this.email,
    required this.severity,
    this.deviceInfo,
    this.status = FeedbackStatus.new_,
    this.createdAt,
    this.updatedAt,
    this.adminNotes,
    this.username,
    this.userName,
    this.attachments,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) => _$FeedbackFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackToJson(this);

  Feedback copyWith({
    int? id,
    int? userId,
    FeedbackType? type,
    String? title,
    String? description,
    String? email,
    FeedbackSeverity? severity,
    String? deviceInfo,
    FeedbackStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminNotes,
    String? username,
    String? userName,
    List<FeedbackAttachment>? attachments,
  }) {
    return Feedback(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      email: email ?? this.email,
      severity: severity ?? this.severity,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      username: username ?? this.username,
      userName: userName ?? this.userName,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  String toString() => 'Feedback(id: $id, type: $type, title: $title, status: $status)';
}

/// Request per inviare un nuovo feedback
@JsonSerializable()
class FeedbackRequest {
  final FeedbackType type;
  final String title;
  final String description;
  final String? email;
  final FeedbackSeverity severity;
  final String? deviceInfo;

  const FeedbackRequest({
    required this.type,
    required this.title,
    required this.description,
    this.email,
    required this.severity,
    this.deviceInfo,
  });

  factory FeedbackRequest.fromJson(Map<String, dynamic> json) =>
      _$FeedbackRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackRequestToJson(this);

  /// Converte in formato per API PHP
  Map<String, dynamic> toApiJson() {
    return {
      'type': type.name,
      'title': title,
      'description': description,
      'email': email ?? '',
      'severity': severity.name,
      'device_info': deviceInfo ?? '',
    };
  }
}

/// Response dall'API per l'invio del feedback
@JsonSerializable()
class FeedbackResponse {
  final bool success;
  final String message;
  final int? feedbackId;
  final int? attachmentsCount;
  final String? debug;

  const FeedbackResponse({
    required this.success,
    required this.message,
    this.feedbackId,
    this.attachmentsCount,
    this.debug,
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) =>
      _$FeedbackResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackResponseToJson(this);
}

/// Request per aggiornare lo stato di un feedback (admin)
@JsonSerializable()
class FeedbackStatusUpdateRequest {
  final int feedbackId;
  final FeedbackStatus status;

  const FeedbackStatusUpdateRequest({
    required this.feedbackId,
    required this.status,
  });

  factory FeedbackStatusUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$FeedbackStatusUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackStatusUpdateRequestToJson(this);

  /// Converte in formato per API PHP
  Map<String, dynamic> toApiJson() {
    return {
      'action': 'update_status',
      'feedback_id': feedbackId,
      'status': status.name == 'new_' ? 'new' : status.name,
    };
  }
}

/// Request per aggiornare le note admin di un feedback
@JsonSerializable()
class FeedbackNotesUpdateRequest {
  final int feedbackId;
  final String adminNotes;

  const FeedbackNotesUpdateRequest({
    required this.feedbackId,
    required this.adminNotes,
  });

  factory FeedbackNotesUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$FeedbackNotesUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackNotesUpdateRequestToJson(this);

  /// Converte in formato per API PHP
  Map<String, dynamic> toApiJson() {
    return {
      'action': 'update_notes',
      'feedback_id': feedbackId,
      'admin_notes': adminNotes,
    };
  }
}

/// Response generica per operazioni feedback
@JsonSerializable()
class FeedbackApiResponse {
  final bool success;
  final String message;
  final List<Feedback>? feedbacks;

  const FeedbackApiResponse({
    required this.success,
    required this.message,
    this.feedbacks,
  });

  factory FeedbackApiResponse.fromJson(Map<String, dynamic> json) =>
      _$FeedbackApiResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackApiResponseToJson(this);
}