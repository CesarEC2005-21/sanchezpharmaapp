import 'package:json_annotation/json_annotation.dart';

part 'detalle_venta_model.g.dart';

@JsonSerializable()
class DetalleVentaModel {
  final int? id;
  @JsonKey(name: 'venta_id')
  final int ventaId;
  @JsonKey(name: 'producto_id')
  final int productoId;
  final int cantidad;
  @JsonKey(name: 'precio_unitario', fromJson: _precioFromJson)
  final double precioUnitario;
  @JsonKey(name: 'descuento', fromJson: _precioFromJson)
  final double descuento;
  @JsonKey(name: 'subtotal', fromJson: _precioFromJson)
  final double subtotal;
  @JsonKey(name: 'producto_nombre')
  final String? productoNombre;
  @JsonKey(name: 'producto_codigo')
  final String? productoCodigo;

  DetalleVentaModel({
    this.id,
    required this.ventaId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.descuento,
    required this.subtotal,
    this.productoNombre,
    this.productoCodigo,
  });

  factory DetalleVentaModel.fromJson(Map<String, dynamic> json) =>
      _$DetalleVentaModelFromJson(json);

  Map<String, dynamic> toJson() => _$DetalleVentaModelToJson(this);

  static double _precioFromJson(dynamic json) {
    if (json == null) return 0.0;
    if (json is num) return json.toDouble();
    if (json is String) return double.tryParse(json) ?? 0.0;
    return 0.0;
  }
}

