// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notification _$NotificationFromJson(Map<String, dynamic> json) => Notification(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      readAt: json['read_at'] as String?,
      isBroadcast: json['is_broadcast'] as bool?,
      senderName: json['sender_name'] as String?,
      senderUsername: json['sender_username'] as String?,
    );

Map<String, dynamic> _$NotificationToJson(Notification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'message': instance.message,
      'type': instance.type,
      'priority': instance.priority,
      'status': instance.status,
      'created_at': instance.createdAt,
      'read_at': instance.readAt,
      'is_broadcast': instance.isBroadcast,
      'sender_name': instance.senderName,
      'sender_username': instance.senderUsername,
    };

NotificationResponse _$NotificationResponseFromJson(
        Map<String, dynamic> json) =>
    NotificationResponse(
      success: json['success'] as bool,
      notifications: (json['notifications'] as List<dynamic>)
          .map((e) => Notification.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: json['pagination'] == null
          ? null
          : NotificationPagination.fromJson(
              json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NotificationResponseToJson(
        NotificationResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'notifications': instance.notifications,
      'pagination': instance.pagination,
    };

NotificationPagination _$NotificationPaginationFromJson(
        Map<String, dynamic> json) =>
    NotificationPagination(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$NotificationPaginationToJson(
        NotificationPagination instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'pages': instance.pages,
    };

SendNotificationRequest _$SendNotificationRequestFromJson(
        Map<String, dynamic> json) =>
    SendNotificationRequest(
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String? ?? 'message',
      priority: json['priority'] as String? ?? 'normal',
      recipientId: (json['recipient_id'] as num?)?.toInt(),
      isBroadcast: json['is_broadcast'] as bool? ?? false,
    );

Map<String, dynamic> _$SendNotificationRequestToJson(
        SendNotificationRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'message': instance.message,
      'type': instance.type,
      'priority': instance.priority,
      'recipient_id': instance.recipientId,
      'is_broadcast': instance.isBroadcast,
    };

SendNotificationResponse _$SendNotificationResponseFromJson(
        Map<String, dynamic> json) =>
    SendNotificationResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      notificationId: (json['notification_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SendNotificationResponseToJson(
        SendNotificationResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'notification_id': instance.notificationId,
    };
