// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'estado_envio_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EstadoEnvioModel _$EstadoEnvioModelFromJson(Map<String, dynamic> json) =>
    EstadoEnvioModel(
      id: (json['id'] as num?)?.toInt(),
      envioId: (json['envio_id'] as num).toInt(),
      estadoAnterior: json['estado_anterior'] as String?,
      estadoNuevo: json['estado_nuevo'] as String,
      observaciones: json['observaciones'] as String?,
      usuarioId: (json['usuario_id'] as num?)?.toInt(),
      fechaCambio: DateParser.fromJson(json['fecha_cambio']),
      usuarioNombre: json['usuario_nombre'] as String?,
    );

Map<String, dynamic> _$EstadoEnvioModelToJson(EstadoEnvioModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'envio_id': instance.envioId,
      'estado_anterior': instance.estadoAnterior,
      'estado_nuevo': instance.estadoNuevo,
      'observaciones': instance.observaciones,
      'usuario_id': instance.usuarioId,
      'fecha_cambio': instance.fechaCambio?.toIso8601String(),
      'usuario_nombre': instance.usuarioNombre,
    };
