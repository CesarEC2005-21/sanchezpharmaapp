import 'package:json_annotation/json_annotation.dart';

part 'categoria_model.g.dart';

@JsonSerializable()
class CategoriaModel {
  final int? id;
  final String nombre;
  final String? descripcion;
  final String estado;

  CategoriaModel({
    this.id,
    required this.nombre,
    this.descripcion,
    this.estado = 'activo',
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) =>
      _$CategoriaModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoriaModelToJson(this);
}

