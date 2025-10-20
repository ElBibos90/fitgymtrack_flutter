import 'package:json_annotation/json_annotation.dart';

part 'security_question_models.g.dart';

// ============================================================================
// SECURITY QUESTION MODEL
// ============================================================================

@JsonSerializable()
class SecurityQuestion {
  final int id;
  final String question;
  @JsonKey(name: 'display_order')
  final int? displayOrder;

  const SecurityQuestion({
    required this.id,
    required this.question,
    this.displayOrder,
  });

  factory SecurityQuestion.fromJson(Map<String, dynamic> json) =>
      _$SecurityQuestionFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityQuestionToJson(this);

  @override
  String toString() => 'SecurityQuestion(id: $id, question: $question)';
}

// ============================================================================
// USER ANSWER MODEL
// ============================================================================

@JsonSerializable()
class UserSecurityAnswer {
  @JsonKey(name: 'question_id')
  final int questionId;
  final String answer;

  const UserSecurityAnswer({
    required this.questionId,
    required this.answer,
  });

  factory UserSecurityAnswer.fromJson(Map<String, dynamic> json) =>
      _$UserSecurityAnswerFromJson(json);

  Map<String, dynamic> toJson() => _$UserSecurityAnswerToJson(this);

  @override
  String toString() =>
      'UserSecurityAnswer(questionId: $questionId, answer: ****)';
}

// ============================================================================
// GET QUESTIONS REQUEST/RESPONSE
// ============================================================================

@JsonSerializable()
class GetQuestionsResponse {
  final bool success;
  final List<SecurityQuestion>? questions;
  final int? count;
  final String? error;
  @JsonKey(name: 'setup_required')
  final bool? setupRequired;

  const GetQuestionsResponse({
    required this.success,
    this.questions,
    this.count,
    this.error,
    this.setupRequired,
  });

  factory GetQuestionsResponse.fromJson(Map<String, dynamic> json) =>
      _$GetQuestionsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetQuestionsResponseToJson(this);
}

// ============================================================================
// VERIFY AND RESET REQUEST/RESPONSE
// ============================================================================

@JsonSerializable()
class VerifyAndResetRequest {
  final String username;
  final List<UserSecurityAnswer> answers;
  @JsonKey(name: 'newPassword')
  final String newPassword;

  const VerifyAndResetRequest({
    required this.username,
    required this.answers,
    required this.newPassword,
  });

  factory VerifyAndResetRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyAndResetRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyAndResetRequestToJson(this);
}

@JsonSerializable()
class VerifyAndResetResponse {
  final bool success;
  final String? message;
  final String? error;
  final int? correct;
  final int? total;
  @JsonKey(name: 'rate_limited')
  final bool? rateLimited;
  @JsonKey(name: 'locked_until')
  final String? lockedUntil;

  const VerifyAndResetResponse({
    required this.success,
    this.message,
    this.error,
    this.correct,
    this.total,
    this.rateLimited,
    this.lockedUntil,
  });

  factory VerifyAndResetResponse.fromJson(Map<String, dynamic> json) =>
      _$VerifyAndResetResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyAndResetResponseToJson(this);
}

// ============================================================================
// SETUP QUESTIONS REQUEST/RESPONSE
// ============================================================================

@JsonSerializable()
class SetupQuestionsRequest {
  final List<UserSecurityAnswer> answers;

  const SetupQuestionsRequest({
    required this.answers,
  });

  factory SetupQuestionsRequest.fromJson(Map<String, dynamic> json) =>
      _$SetupQuestionsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetupQuestionsRequestToJson(this);
}

@JsonSerializable()
class SetupQuestionsResponse {
  final bool success;
  final String? message;
  final String? error;
  final int? count;

  const SetupQuestionsResponse({
    required this.success,
    this.message,
    this.error,
    this.count,
  });

  factory SetupQuestionsResponse.fromJson(Map<String, dynamic> json) =>
      _$SetupQuestionsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SetupQuestionsResponseToJson(this);
}

// ============================================================================
// CHECK STATUS RESPONSE
// ============================================================================

@JsonSerializable()
class AccountStatus {
  final bool allowed;
  final String reason;
  @JsonKey(name: 'attempts_last_hour')
  final int attemptsLastHour;
  @JsonKey(name: 'locked_until')
  final String? lockedUntil;
  @JsonKey(name: 'is_locked')
  final bool isLocked;
  @JsonKey(name: 'questions_configured')
  final int questionsConfigured;
  @JsonKey(name: 'failed_attempts_24h')
  final int failedAttempts24h;

  const AccountStatus({
    required this.allowed,
    required this.reason,
    required this.attemptsLastHour,
    this.lockedUntil,
    required this.isLocked,
    required this.questionsConfigured,
    required this.failedAttempts24h,
  });

  factory AccountStatus.fromJson(Map<String, dynamic> json) =>
      _$AccountStatusFromJson(json);

  Map<String, dynamic> toJson() => _$AccountStatusToJson(this);
}

@JsonSerializable()
class CheckStatusResponse {
  final bool success;
  final AccountStatus? status;
  final String? error;

  const CheckStatusResponse({
    required this.success,
    this.status,
    this.error,
  });

  factory CheckStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CheckStatusResponseToJson(this);
}

// ============================================================================
// LIST QUESTIONS RESPONSE
// ============================================================================

@JsonSerializable()
class ListQuestionsResponse {
  final bool success;
  final List<SecurityQuestion>? questions;
  final int? count;
  final String? error;

  const ListQuestionsResponse({
    required this.success,
    this.questions,
    this.count,
    this.error,
  });

  factory ListQuestionsResponse.fromJson(Map<String, dynamic> json) =>
      _$ListQuestionsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListQuestionsResponseToJson(this);
}

// ============================================================================
// QUESTION WITH USER ANSWER (FOR UI STATE)
// ============================================================================

/// Combines a SecurityQuestion with the user's answer (for UI forms)
class QuestionWithAnswer {
  final SecurityQuestion question;
  String answer;

  QuestionWithAnswer({
    required this.question,
    this.answer = '',
  });

  UserSecurityAnswer toUserAnswer() {
    return UserSecurityAnswer(
      questionId: question.id,
      answer: answer,
    );
  }

  bool get isValid => answer.trim().isNotEmpty;

  @override
  String toString() =>
      'QuestionWithAnswer(questionId: ${question.id}, answered: ${answer.isNotEmpty})';
}

