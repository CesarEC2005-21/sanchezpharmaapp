// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alerta_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertaModel _$AlertaModelFromJson(Map<String, dynamic> json) => AlertaModel(
  id: (json['id'] as num?)?.toInt(),
  productoId: (json['producto_id'] as num).toInt(),
  tipoAlerta: json['tipo_alerta'] as String,
  mensaje: json['mensaje'] as String?,
  fechaAlerta: DateParser.fromJson(json['fecha_alerta']),
  leida: json['leida'] as bool? ?? false,
  fechaLeida: DateParser.fromJson(json['fecha_leida']),
  productoNombre: json['producto_nombre'] as String?,
  productoCodigo: json['producto_codigo'] as String?,
);

Map<String, dynamic> _$AlertaModelToJson(AlertaModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'producto_id': instance.productoId,
      'tipo_alerta': instance.tipoAlerta,
      'mensaje': instance.mensaje,
      'fecha_alerta': instance.fechaAlerta?.toIso8601String(),
      'leida': instance.leida,
      'fecha_leida': instance.fechaLeida?.toIso8601String(),
      'producto_nombre': instance.productoNombre,
      'producto_codigo': instance.productoCodigo,
    };
