// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proveedor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProveedorModel _$ProveedorModelFromJson(Map<String, dynamic> json) =>
    ProveedorModel(
      id: (json['id'] as num?)?.toInt(),
      nombre: json['nombre'] as String,
      contacto: json['contacto'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      direccion: json['direccion'] as String?,
      estado: json['estado'] as String? ?? 'activo',
    );

Map<String, dynamic> _$ProveedorModelToJson(ProveedorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'contacto': instance.contacto,
      'telefono': instance.telefono,
      'email': instance.email,
      'direccion': instance.direccion,
      'estado': instance.estado,
    };
