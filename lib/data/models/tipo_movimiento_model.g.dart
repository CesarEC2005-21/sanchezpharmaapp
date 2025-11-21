// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tipo_movimiento_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TipoMovimientoModel _$TipoMovimientoModelFromJson(Map<String, dynamic> json) =>
    TipoMovimientoModel(
      id: (json['id'] as num?)?.toInt(),
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      tipo: json['tipo'] as String,
    );

Map<String, dynamic> _$TipoMovimientoModelToJson(
  TipoMovimientoModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'descripcion': instance.descripcion,
  'tipo': instance.tipo,
};
