import 'package:json_annotation/json_annotation.dart';

part 'tipo_movimiento_model.g.dart';

@JsonSerializable()
class TipoMovimientoModel {
  final int? id;
  final String nombre;
  final String? descripcion;
  final String tipo; // 'entrada', 'salida', 'ajuste'

  TipoMovimientoModel({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.tipo,
  });

  factory TipoMovimientoModel.fromJson(Map<String, dynamic> json) =>
      _$TipoMovimientoModelFromJson(json);

  Map<String, dynamic> toJson() => _$TipoMovimientoModelToJson(this);
}

