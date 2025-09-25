// lib/features/notifications/models/notification_models.dart

import 'package:json_annotation/json_annotation.dart';

part 'notification_models.g.dart';

/// Modello per rappresentare una notifica
@JsonSerializable()
class Notification {
  final int id;
  final String title;
  final String message;
  final String type;
  final String priority;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'read_at')
  final String? readAt;
  @JsonKey(name: 'is_broadcast')
  final bool? isBroadcast;
  @JsonKey(name: 'sender_name')
  final String? senderName;
  @JsonKey(name: 'sender_username')
  final String? senderUsername;

  const Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.isBroadcast,
    this.senderName,
    this.senderUsername,
  });

  /// Factory per creare da JSON
  factory Notification.fromJson(Map<String, dynamic> json) => 
      _$NotificationFromJson(json);

  /// Converte in JSON
  Map<String, dynamic> toJson() => _$NotificationToJson(this);

  /// Verifica se la notifica è stata letta
  bool get isRead => readAt != null;

  /// Verifica se la notifica è non letta
  bool get isUnread => !isRead;

  /// Ottiene l'icona per il tipo di notifica
  String get typeIcon {
    switch (type) {
      case 'announcement':
        return '📢';
      case 'reminder':
        return '⏰';
      case 'message':
      default:
        return '💬';
    }
  }

  /// Ottiene il colore per la priorità
  String get priorityColor {
    switch (priority) {
      case 'high':
        return 'red';
      case 'normal':
        return 'blue';
      case 'low':
        return 'gray';
      default:
        return 'gray';
    }
  }

  /// Ottiene il nome del mittente
  String get senderDisplayName {
    if (senderName != null && senderName!.isNotEmpty) {
      return senderName!;
    }
    if (senderUsername != null && senderUsername!.isNotEmpty) {
      return senderUsername!;
    }
    return 'Sistema';
  }

  /// Ottiene la data formattata
  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} giorni fa';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ore fa';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minuti fa';
      } else {
        return 'Ora';
      }
    } catch (e) {
      return createdAt;
    }
  }
}

/// Modello per la risposta API delle notifiche
@JsonSerializable()
class NotificationResponse {
  final bool success;
  final List<Notification> notifications;
  final NotificationPagination? pagination;

  const NotificationResponse({
    required this.success,
    required this.notifications,
    this.pagination,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) => 
      _$NotificationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationResponseToJson(this);
}

/// Modello per la paginazione
@JsonSerializable()
class NotificationPagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  const NotificationPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) => 
      _$NotificationPaginationFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPaginationToJson(this);
}

/// Modello per inviare una notifica
@JsonSerializable()
class SendNotificationRequest {
  final String title;
  final String message;
  final String type;
  final String priority;
  @JsonKey(name: 'recipient_id')
  final int? recipientId;
  @JsonKey(name: 'is_broadcast')
  final bool isBroadcast;

  const SendNotificationRequest({
    required this.title,
    required this.message,
    this.type = 'message',
    this.priority = 'normal',
    this.recipientId,
    this.isBroadcast = false,
  });

  factory SendNotificationRequest.fromJson(Map<String, dynamic> json) => 
      _$SendNotificationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendNotificationRequestToJson(this);
}

/// Modello per la risposta dell'invio notifica
@JsonSerializable()
class SendNotificationResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'notification_id')
  final int? notificationId;

  const SendNotificationResponse({
    required this.success,
    required this.message,
    this.notificationId,
  });

  factory SendNotificationResponse.fromJson(Map<String, dynamic> json) => 
      _$SendNotificationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SendNotificationResponseToJson(this);
}

/// Enumerazione per i tipi di notifica
enum NotificationType {
  message('message', 'Messaggio', '💬'),
  announcement('announcement', 'Annuncio', '📢'),
  reminder('reminder', 'Promemoria', '⏰');

  const NotificationType(this.value, this.displayName, this.icon);
  final String value;
  final String displayName;
  final String icon;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.message,
    );
  }
}

/// Enumerazione per le priorità
enum NotificationPriority {
  low('low', 'Bassa', 'gray'),
  normal('normal', 'Normale', 'blue'),
  high('high', 'Alta', 'red');

  const NotificationPriority(this.value, this.displayName, this.color);
  final String value;
  final String displayName;
  final String color;

  static NotificationPriority fromString(String value) {
    return NotificationPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => NotificationPriority.normal,
    );
  }
}

/// Enumerazione per lo stato
enum NotificationStatus {
  sent('sent', 'Inviata'),
  delivered('delivered', 'Consegnata'),
  read('read', 'Letta');

  const NotificationStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static NotificationStatus fromString(String value) {
    return NotificationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => NotificationStatus.sent,
    );
  }
}
