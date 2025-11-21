// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metodo_pago_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetodoPagoModel _$MetodoPagoModelFromJson(Map<String, dynamic> json) =>
    MetodoPagoModel(
      id: (json['id'] as num?)?.toInt(),
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] as String? ?? 'activo',
    );

Map<String, dynamic> _$MetodoPagoModelToJson(MetodoPagoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'estado': instance.estado,
    };
