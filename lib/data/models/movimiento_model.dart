import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/date_parser.dart';

part 'movimiento_model.g.dart';

@JsonSerializable()
class MovimientoModel {
  final int? id;
  @JsonKey(name: 'producto_id')
  final int productoId;
  @JsonKey(name: 'tipo_movimiento_id')
  final int tipoMovimientoId;
  final int cantidad;
  @JsonKey(name: 'stock_anterior')
  final int stockAnterior;
  @JsonKey(name: 'stock_nuevo')
  final int stockNuevo;
  @JsonKey(name: 'precio_unitario')
  final double? precioUnitario;
  final String? motivo;
  final String? referencia;
  @JsonKey(name: 'usuario_id')
  final int? usuarioId;
  @JsonKey(name: 'fecha_movimiento', fromJson: DateParser.fromJson)
  final DateTime? fechaMovimiento;
  @JsonKey(name: 'producto_nombre')
  final String? productoNombre;
  @JsonKey(name: 'producto_codigo')
  final String? productoCodigo;
  @JsonKey(name: 'tipo_movimiento_nombre')
  final String? tipoMovimientoNombre;
  @JsonKey(name: 'tipo_movimiento_tipo')
  final String? tipoMovimientoTipo;
  @JsonKey(name: 'usuario_nombre')
  final String? usuarioNombre;

  MovimientoModel({
    this.id,
    required this.productoId,
    required this.tipoMovimientoId,
    required this.cantidad,
    required this.stockAnterior,
    required this.stockNuevo,
    this.precioUnitario,
    this.motivo,
    this.referencia,
    this.usuarioId,
    this.fechaMovimiento,
    this.productoNombre,
    this.productoCodigo,
    this.tipoMovimientoNombre,
    this.tipoMovimientoTipo,
    this.usuarioNombre,
  });

  factory MovimientoModel.fromJson(Map<String, dynamic> json) =>
      _$MovimientoModelFromJson(json);

  Map<String, dynamic> toJson() => _$MovimientoModelToJson(this);
}

