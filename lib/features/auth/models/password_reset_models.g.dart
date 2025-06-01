// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_reset_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PasswordResetRequest _$PasswordResetRequestFromJson(
        Map<String, dynamic> json) =>
    PasswordResetRequest(
      email: json['email'] as String,
    );

Map<String, dynamic> _$PasswordResetRequestToJson(
        PasswordResetRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
    };

PasswordResetResponse _$PasswordResetResponseFromJson(
        Map<String, dynamic> json) =>
    PasswordResetResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      token: json['token'] as String?,
    );

Map<String, dynamic> _$PasswordResetResponseToJson(
        PasswordResetResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'token': instance.token,
    };

PasswordResetConfirmRequest _$PasswordResetConfirmRequestFromJson(
        Map<String, dynamic> json) =>
    PasswordResetConfirmRequest(
      token: json['token'] as String,
      code: json['code'] as String,
      newPassword: json['newPassword'] as String,
    );

Map<String, dynamic> _$PasswordResetConfirmRequestToJson(
        PasswordResetConfirmRequest instance) =>
    <String, dynamic>{
      'token': instance.token,
      'code': instance.code,
      'newPassword': instance.newPassword,
    };

PasswordResetConfirmResponse _$PasswordResetConfirmResponseFromJson(
        Map<String, dynamic> json) =>
    PasswordResetConfirmResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
    );

Map<String, dynamic> _$PasswordResetConfirmResponseToJson(
        PasswordResetConfirmResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
    };
