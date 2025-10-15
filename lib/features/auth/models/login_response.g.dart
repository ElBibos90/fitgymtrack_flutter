// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'user': instance.user,
      'token': instance.token,
      'error': instance.error,
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      roleId: (json['role_id'] as num).toInt(),
      roleName: json['role_name'] as String,
      isTester: json['is_tester'] as bool?,
      gymId: (json['gym_id'] as num?)?.toInt(),
      trainer: json['trainer'] == null
          ? null
          : Trainer.fromJson(json['trainer'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'name': instance.name,
      'role_id': instance.roleId,
      'role_name': instance.roleName,
      'is_tester': instance.isTester,
      'gym_id': instance.gymId,
      'trainer': instance.trainer,
    };

Trainer _$TrainerFromJson(Map<String, dynamic> json) => Trainer(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$TrainerToJson(Trainer instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'name': instance.name,
    };
