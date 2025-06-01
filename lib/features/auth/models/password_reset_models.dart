import 'package:json_annotation/json_annotation.dart';

part 'password_reset_models.g.dart';

@JsonSerializable()
class PasswordResetRequest {
  final String email;

  const PasswordResetRequest({
    required this.email,
  });

  factory PasswordResetRequest.fromJson(Map<String, dynamic> json) =>
      _$PasswordResetRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PasswordResetRequestToJson(this);
}

@JsonSerializable()
class PasswordResetResponse {
  final bool success;
  final String message;
  final String? token;

  const PasswordResetResponse({
    required this.success,
    required this.message,
    this.token,
  });

  factory PasswordResetResponse.fromJson(Map<String, dynamic> json) =>
      _$PasswordResetResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PasswordResetResponseToJson(this);
}

@JsonSerializable()
class PasswordResetConfirmRequest {
  final String token;
  final String code;
  final String newPassword;

  const PasswordResetConfirmRequest({
    required this.token,
    required this.code,
    required this.newPassword,
  });

  factory PasswordResetConfirmRequest.fromJson(Map<String, dynamic> json) =>
      _$PasswordResetConfirmRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PasswordResetConfirmRequestToJson(this);
}

@JsonSerializable()
class PasswordResetConfirmResponse {
  final bool success;
  final String message;

  const PasswordResetConfirmResponse({
    required this.success,
    required this.message,
  });

  factory PasswordResetConfirmResponse.fromJson(Map<String, dynamic> json) =>
      _$PasswordResetConfirmResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PasswordResetConfirmResponseToJson(this);
}