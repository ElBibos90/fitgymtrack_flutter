// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_question_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecurityQuestion _$SecurityQuestionFromJson(Map<String, dynamic> json) =>
    SecurityQuestion(
      id: (json['id'] as num).toInt(),
      question: json['question'] as String,
      displayOrder: (json['display_order'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SecurityQuestionToJson(SecurityQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'question': instance.question,
      'display_order': instance.displayOrder,
    };

UserSecurityAnswer _$UserSecurityAnswerFromJson(Map<String, dynamic> json) =>
    UserSecurityAnswer(
      questionId: (json['question_id'] as num).toInt(),
      answer: json['answer'] as String,
    );

Map<String, dynamic> _$UserSecurityAnswerToJson(UserSecurityAnswer instance) =>
    <String, dynamic>{
      'question_id': instance.questionId,
      'answer': instance.answer,
    };

GetQuestionsResponse _$GetQuestionsResponseFromJson(
        Map<String, dynamic> json) =>
    GetQuestionsResponse(
      success: json['success'] as bool,
      questions: (json['questions'] as List<dynamic>?)
          ?.map((e) => SecurityQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num?)?.toInt(),
      error: json['error'] as String?,
      setupRequired: json['setup_required'] as bool?,
    );

Map<String, dynamic> _$GetQuestionsResponseToJson(
        GetQuestionsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'questions': instance.questions,
      'count': instance.count,
      'error': instance.error,
      'setup_required': instance.setupRequired,
    };

VerifyAndResetRequest _$VerifyAndResetRequestFromJson(
        Map<String, dynamic> json) =>
    VerifyAndResetRequest(
      username: json['username'] as String,
      answers: (json['answers'] as List<dynamic>)
          .map((e) => UserSecurityAnswer.fromJson(e as Map<String, dynamic>))
          .toList(),
      newPassword: json['newPassword'] as String,
    );

Map<String, dynamic> _$VerifyAndResetRequestToJson(
        VerifyAndResetRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'answers': instance.answers,
      'newPassword': instance.newPassword,
    };

VerifyAndResetResponse _$VerifyAndResetResponseFromJson(
        Map<String, dynamic> json) =>
    VerifyAndResetResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      error: json['error'] as String?,
      correct: (json['correct'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
      rateLimited: json['rate_limited'] as bool?,
      lockedUntil: json['locked_until'] as String?,
    );

Map<String, dynamic> _$VerifyAndResetResponseToJson(
        VerifyAndResetResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'error': instance.error,
      'correct': instance.correct,
      'total': instance.total,
      'rate_limited': instance.rateLimited,
      'locked_until': instance.lockedUntil,
    };

SetupQuestionsRequest _$SetupQuestionsRequestFromJson(
        Map<String, dynamic> json) =>
    SetupQuestionsRequest(
      answers: (json['answers'] as List<dynamic>)
          .map((e) => UserSecurityAnswer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SetupQuestionsRequestToJson(
        SetupQuestionsRequest instance) =>
    <String, dynamic>{
      'answers': instance.answers,
    };

SetupQuestionsResponse _$SetupQuestionsResponseFromJson(
        Map<String, dynamic> json) =>
    SetupQuestionsResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      error: json['error'] as String?,
      count: (json['count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SetupQuestionsResponseToJson(
        SetupQuestionsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'error': instance.error,
      'count': instance.count,
    };

AccountStatus _$AccountStatusFromJson(Map<String, dynamic> json) =>
    AccountStatus(
      allowed: json['allowed'] as bool,
      reason: json['reason'] as String,
      attemptsLastHour: (json['attempts_last_hour'] as num).toInt(),
      lockedUntil: json['locked_until'] as String?,
      isLocked: json['is_locked'] as bool,
      questionsConfigured: (json['questions_configured'] as num).toInt(),
      failedAttempts24h: (json['failed_attempts_24h'] as num).toInt(),
    );

Map<String, dynamic> _$AccountStatusToJson(AccountStatus instance) =>
    <String, dynamic>{
      'allowed': instance.allowed,
      'reason': instance.reason,
      'attempts_last_hour': instance.attemptsLastHour,
      'locked_until': instance.lockedUntil,
      'is_locked': instance.isLocked,
      'questions_configured': instance.questionsConfigured,
      'failed_attempts_24h': instance.failedAttempts24h,
    };

CheckStatusResponse _$CheckStatusResponseFromJson(Map<String, dynamic> json) =>
    CheckStatusResponse(
      success: json['success'] as bool,
      status: json['status'] == null
          ? null
          : AccountStatus.fromJson(json['status'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$CheckStatusResponseToJson(
        CheckStatusResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'status': instance.status,
      'error': instance.error,
    };

ListQuestionsResponse _$ListQuestionsResponseFromJson(
        Map<String, dynamic> json) =>
    ListQuestionsResponse(
      success: json['success'] as bool,
      questions: (json['questions'] as List<dynamic>?)
          ?.map((e) => SecurityQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num?)?.toInt(),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$ListQuestionsResponseToJson(
        ListQuestionsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'questions': instance.questions,
      'count': instance.count,
      'error': instance.error,
    };
