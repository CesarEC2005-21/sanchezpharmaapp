// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      token: json['token'] as String?,
      user: json['user'] == null
          ? null
          : UserModel.fromJson(json['user'] as Map<String, dynamic>),
      userType: json['user_type'] as String?,
      clienteId: (json['cliente_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'token': instance.token,
      'user': instance.user,
      'user_type': instance.userType,
      'cliente_id': instance.clienteId,
    };
