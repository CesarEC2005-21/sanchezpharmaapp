// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categoria_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoriaModel _$CategoriaModelFromJson(Map<String, dynamic> json) =>
    CategoriaModel(
      id: (json['id'] as num?)?.toInt(),
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] as String? ?? 'activo',
    );

Map<String, dynamic> _$CategoriaModelToJson(CategoriaModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'estado': instance.estado,
    };
