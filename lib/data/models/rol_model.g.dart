// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rol_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RolModel _$RolModelFromJson(Map<String, dynamic> json) => RolModel(
  id: (json['id'] as num).toInt(),
  nombre: json['nombre'] as String,
  descripcion: json['descripcion'] as String?,
);

Map<String, dynamic> _$RolModelToJson(RolModel instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'descripcion': instance.descripcion,
};
