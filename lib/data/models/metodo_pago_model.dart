import 'package:json_annotation/json_annotation.dart';

part 'metodo_pago_model.g.dart';

@JsonSerializable()
class MetodoPagoModel {
  final int? id;
  final String nombre;
  final String? descripcion;
  final String estado;

  MetodoPagoModel({
    this.id,
    required this.nombre,
    this.descripcion,
    this.estado = 'activo',
  });

  factory MetodoPagoModel.fromJson(Map<String, dynamic> json) =>
      _$MetodoPagoModelFromJson(json);

  Map<String, dynamic> toJson() => _$MetodoPagoModelToJson(this);
}

