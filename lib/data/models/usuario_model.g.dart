// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsuarioModel _$UsuarioModelFromJson(Map<String, dynamic> json) => UsuarioModel(
  id: (json['id'] as num?)?.toInt(),
  username: json['username'] as String,
  email: json['email'] as String,
  password: json['password'] as String?,
  nombre: json['nombre'] as String,
  apellido: json['apellido'] as String,
  edad: UsuarioModel._edadFromJson(json['edad']),
  sexo: json['sexo'] as String,
  rolId: UsuarioModel._rolIdFromJson(json['rol_id']),
);

Map<String, dynamic> _$UsuarioModelToJson(UsuarioModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'password': instance.password,
      'nombre': instance.nombre,
      'apellido': instance.apellido,
      'edad': instance.edad,
      'sexo': instance.sexo,
      'rol_id': instance.rolId,
    };
