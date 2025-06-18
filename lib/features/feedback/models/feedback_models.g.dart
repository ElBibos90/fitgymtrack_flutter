// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedbackAttachment _$FeedbackAttachmentFromJson(Map<String, dynamic> json) =>
    FeedbackAttachment(
      id: (json['id'] as num?)?.toInt(),
      feedbackId: (json['feedbackId'] as num?)?.toInt(),
      filename: json['filename'] as String,
      originalName: json['originalName'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      filePath: json['filePath'] as String?,
    );

Map<String, dynamic> _$FeedbackAttachmentToJson(FeedbackAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'feedbackId': instance.feedbackId,
      'filename': instance.filename,
      'originalName': instance.originalName,
      'fileSize': instance.fileSize,
      'filePath': instance.filePath,
    };

Feedback _$FeedbackFromJson(Map<String, dynamic> json) => Feedback(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      type: $enumDecode(_$FeedbackTypeEnumMap, json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      email: json['email'] as String?,
      severity: $enumDecode(_$FeedbackSeverityEnumMap, json['severity']),
      deviceInfo: json['deviceInfo'] as String?,
      status: $enumDecodeNullable(_$FeedbackStatusEnumMap, json['status']) ??
          FeedbackStatus.new_,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      adminNotes: json['adminNotes'] as String?,
      username: json['username'] as String?,
      userName: json['userName'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => FeedbackAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FeedbackToJson(Feedback instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': _$FeedbackTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'email': instance.email,
      'severity': _$FeedbackSeverityEnumMap[instance.severity]!,
      'deviceInfo': instance.deviceInfo,
      'status': _$FeedbackStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'adminNotes': instance.adminNotes,
      'username': instance.username,
      'userName': instance.userName,
      'attachments': instance.attachments,
    };

const _$FeedbackTypeEnumMap = {
  FeedbackType.bug: 'bug',
  FeedbackType.feature: 'feature',
  FeedbackType.suggestion: 'suggestion',
  FeedbackType.complaint: 'complaint',
  FeedbackType.compliment: 'compliment',
  FeedbackType.other: 'other',
};

const _$FeedbackSeverityEnumMap = {
  FeedbackSeverity.low: 'low',
  FeedbackSeverity.medium: 'medium',
  FeedbackSeverity.high: 'high',
  FeedbackSeverity.critical: 'critical',
};

const _$FeedbackStatusEnumMap = {
  FeedbackStatus.new_: 'new',
  FeedbackStatus.inProgress: 'in_progress',
  FeedbackStatus.closed: 'closed',
  FeedbackStatus.rejected: 'rejected',
};

FeedbackRequest _$FeedbackRequestFromJson(Map<String, dynamic> json) =>
    FeedbackRequest(
      type: $enumDecode(_$FeedbackTypeEnumMap, json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      email: json['email'] as String?,
      severity: $enumDecode(_$FeedbackSeverityEnumMap, json['severity']),
      deviceInfo: json['deviceInfo'] as String?,
    );

Map<String, dynamic> _$FeedbackRequestToJson(FeedbackRequest instance) =>
    <String, dynamic>{
      'type': _$FeedbackTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'email': instance.email,
      'severity': _$FeedbackSeverityEnumMap[instance.severity]!,
      'deviceInfo': instance.deviceInfo,
    };

FeedbackResponse _$FeedbackResponseFromJson(Map<String, dynamic> json) =>
    FeedbackResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      feedbackId: (json['feedbackId'] as num?)?.toInt(),
      attachmentsCount: (json['attachmentsCount'] as num?)?.toInt(),
      debug: json['debug'] as String?,
    );

Map<String, dynamic> _$FeedbackResponseToJson(FeedbackResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'feedbackId': instance.feedbackId,
      'attachmentsCount': instance.attachmentsCount,
      'debug': instance.debug,
    };

FeedbackStatusUpdateRequest _$FeedbackStatusUpdateRequestFromJson(
        Map<String, dynamic> json) =>
    FeedbackStatusUpdateRequest(
      feedbackId: (json['feedbackId'] as num).toInt(),
      status: $enumDecode(_$FeedbackStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$FeedbackStatusUpdateRequestToJson(
        FeedbackStatusUpdateRequest instance) =>
    <String, dynamic>{
      'feedbackId': instance.feedbackId,
      'status': _$FeedbackStatusEnumMap[instance.status]!,
    };

FeedbackNotesUpdateRequest _$FeedbackNotesUpdateRequestFromJson(
        Map<String, dynamic> json) =>
    FeedbackNotesUpdateRequest(
      feedbackId: (json['feedbackId'] as num).toInt(),
      adminNotes: json['adminNotes'] as String,
    );

Map<String, dynamic> _$FeedbackNotesUpdateRequestToJson(
        FeedbackNotesUpdateRequest instance) =>
    <String, dynamic>{
      'feedbackId': instance.feedbackId,
      'adminNotes': instance.adminNotes,
    };

FeedbackApiResponse _$FeedbackApiResponseFromJson(Map<String, dynamic> json) =>
    FeedbackApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      feedbacks: (json['feedbacks'] as List<dynamic>?)
          ?.map((e) => Feedback.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FeedbackApiResponseToJson(
        FeedbackApiResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'feedbacks': instance.feedbacks,
    };
