// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cliente_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClienteModel _$ClienteModelFromJson(Map<String, dynamic> json) => ClienteModel(
  id: (json['id'] as num?)?.toInt(),
  nombre: json['nombre'] as String,
  apellido: json['apellido'] as String?,
  documento: json['documento'] as String?,
  tipoDocumento: json['tipo_documento'] as String? ?? 'DNI',
  telefono: json['telefono'] as String?,
  email: json['email'] as String?,
  direccion: json['direccion'] as String?,
  fechaRegistro: DateParser.fromJson(json['fecha_registro']),
  estado: json['estado'] as String? ?? 'activo',
);

Map<String, dynamic> _$ClienteModelToJson(ClienteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'apellido': instance.apellido,
      'documento': instance.documento,
      'tipo_documento': instance.tipoDocumento,
      'telefono': instance.telefono,
      'email': instance.email,
      'direccion': instance.direccion,
      'fecha_registro': instance.fechaRegistro?.toIso8601String(),
      'estado': instance.estado,
    };
