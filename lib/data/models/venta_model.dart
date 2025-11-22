import 'package:json_annotation/json_annotation.dart';
import 'detalle_venta_model.dart';
import '../../core/utils/date_parser.dart';

part 'venta_model.g.dart';

@JsonSerializable()
class VentaModel {
  final int? id;
  @JsonKey(name: 'numero_venta')
  final String? numeroVenta;
  @JsonKey(name: 'cliente_id')
  final int? clienteId;
  @JsonKey(name: 'usuario_id', fromJson: _usuarioIdFromJson)
  final int usuarioId;
  @JsonKey(name: 'tipo_venta')
  final String tipoVenta; // 'recojo_tienda' o 'envio_domicilio'
  @JsonKey(name: 'metodo_pago_id')
  final int? metodoPagoId;
  @JsonKey(name: 'subtotal', fromJson: _precioFromJson)
  final double subtotal;
  @JsonKey(name: 'descuento', fromJson: _precioFromJson)
  final double descuento;
  @JsonKey(name: 'impuesto', fromJson: _precioFromJson)
  final double impuesto;
  @JsonKey(name: 'total', fromJson: _precioFromJson)
  final double total;
  final String estado;
  final String? observaciones;
  @JsonKey(name: 'fecha_venta', fromJson: DateParser.fromJson)
  final DateTime? fechaVenta;
  @JsonKey(name: 'cliente_nombre')
  final String? clienteNombre;
  @JsonKey(name: 'cliente_apellido')
  final String? clienteApellido;
  @JsonKey(name: 'cliente_documento')
  final String? clienteDocumento;
  @JsonKey(name: 'usuario_nombre')
  final String? usuarioNombre;
  @JsonKey(name: 'metodo_pago_nombre')
  final String? metodoPagoNombre;
  @JsonKey(name: 'detalle')
  final List<DetalleVentaModel>? detalle;

  VentaModel({
    this.id,
    this.numeroVenta,
    this.clienteId,
    required this.usuarioId,
    required this.tipoVenta,
    this.metodoPagoId,
    required this.subtotal,
    required this.descuento,
    required this.impuesto,
    required this.total,
    this.estado = 'pendiente',
    this.observaciones,
    this.fechaVenta,
    this.clienteNombre,
    this.clienteApellido,
    this.clienteDocumento,
    this.usuarioNombre,
    this.metodoPagoNombre,
    this.detalle,
  });

  factory VentaModel.fromJson(Map<String, dynamic> json) =>
      _$VentaModelFromJson(json);

  Map<String, dynamic> toJson() => _$VentaModelToJson(this);

  static double _precioFromJson(dynamic json) {
    if (json == null) return 0.0;
    if (json is num) return json.toDouble();
    if (json is String) return double.tryParse(json) ?? 0.0;
    return 0.0;
  }

  static int _usuarioIdFromJson(dynamic json) {
    if (json == null) return 0;
    if (json is num) return json.toInt();
    if (json is String) return int.tryParse(json) ?? 0;
    return 0;
  }

  String get clienteCompleto {
    if (clienteApellido != null) {
      return '$clienteNombre $clienteApellido';
    }
    return clienteNombre ?? 'Cliente no registrado';
  }
}

