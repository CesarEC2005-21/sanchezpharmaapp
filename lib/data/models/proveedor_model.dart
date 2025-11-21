import 'package:json_annotation/json_annotation.dart';

part 'proveedor_model.g.dart';

@JsonSerializable()
class ProveedorModel {
  final int? id;
  final String nombre;
  final String? contacto;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String estado;

  ProveedorModel({
    this.id,
    required this.nombre,
    this.contacto,
    this.telefono,
    this.email,
    this.direccion,
    this.estado = 'activo',
  });

  factory ProveedorModel.fromJson(Map<String, dynamic> json) =>
      _$ProveedorModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProveedorModelToJson(this);
}

