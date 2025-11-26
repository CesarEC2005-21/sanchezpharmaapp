// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notificacion_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificacionModel _$NotificacionModelFromJson(Map<String, dynamic> json) =>
    NotificacionModel(
      id: (json['id'] as num).toInt(),
      clienteId: (json['cliente_id'] as num).toInt(),
      titulo: json['titulo'] as String,
      cuerpo: json['cuerpo'] as String,
      tipo: json['tipo'] as String,
      relacionId: (json['relacion_id'] as num?)?.toInt(),
      leida: NotificacionModel._boolFromJson(json['leida']),
      fechaCreacion: json['fecha_creacion'] as String,
      fechaLeida: json['fecha_leida'] as String?,
    );

Map<String, dynamic> _$NotificacionModelToJson(NotificacionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cliente_id': instance.clienteId,
      'titulo': instance.titulo,
      'cuerpo': instance.cuerpo,
      'tipo': instance.tipo,
      'relacion_id': instance.relacionId,
      'leida': instance.leida,
      'fecha_creacion': instance.fechaCreacion,
      'fecha_leida': instance.fechaLeida,
    };
