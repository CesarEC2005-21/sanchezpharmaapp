// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cliente_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClienteModel _$ClienteModelFromJson(Map<String, dynamic> json) => ClienteModel(
  id: (json['id'] as num?)?.toInt(),
  nombres: json['nombres'] as String,
  apellidoPaterno: json['apellido_paterno'] as String?,
  apellidoMaterno: json['apellido_materno'] as String?,
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
      'nombres': instance.nombres,
      'apellido_paterno': instance.apellidoPaterno,
      'apellido_materno': instance.apellidoMaterno,
      'documento': instance.documento,
      'tipo_documento': instance.tipoDocumento,
      'telefono': instance.telefono,
      'email': instance.email,
      'direccion': instance.direccion,
      'fecha_registro': instance.fechaRegistro?.toIso8601String(),
      'estado': instance.estado,
    };
