import 'package:json_annotation/json_annotation.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  final bool success;
  final String message;
  final User? user;
  final String? token;
  final String? error;

  const LoginResponse({
    this.success = false,
    this.message = '',
    this.user,
    this.token,
    this.error,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

@JsonSerializable()
class User {
  final int id;
  final String username;
  final String? email;
  final String? name;
  @JsonKey(name: 'role_id')
  final int roleId;
  @JsonKey(name: 'role_name')
  final String roleName;
  final Trainer? trainer;

  const User({
    required this.id,
    required this.username,
    this.email,
    this.name,
    required this.roleId,
    required this.roleName,
    this.trainer,
  });

  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class Trainer {
  final int id;
  final String username;
  final String? name;

  const Trainer({
    required this.id,
    required this.username,
    this.name,
  });

  factory Trainer.fromJson(Map<String, dynamic> json) =>
      _$TrainerFromJson(json);

  Map<String, dynamic> toJson() => _$TrainerToJson(this);
}