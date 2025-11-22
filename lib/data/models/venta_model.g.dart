// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venta_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VentaModel _$VentaModelFromJson(Map<String, dynamic> json) => VentaModel(
  id: (json['id'] as num?)?.toInt(),
  numeroVenta: json['numero_venta'] as String?,
  clienteId: (json['cliente_id'] as num?)?.toInt(),
  usuarioId: VentaModel._usuarioIdFromJson(json['usuario_id']),
  tipoVenta: json['tipo_venta'] as String,
  metodoPagoId: (json['metodo_pago_id'] as num?)?.toInt(),
  subtotal: VentaModel._precioFromJson(json['subtotal']),
  descuento: VentaModel._precioFromJson(json['descuento']),
  impuesto: VentaModel._precioFromJson(json['impuesto']),
  total: VentaModel._precioFromJson(json['total']),
  estado: json['estado'] as String? ?? 'pendiente',
  observaciones: json['observaciones'] as String?,
  fechaVenta: DateParser.fromJson(json['fecha_venta']),
  clienteNombre: json['cliente_nombre'] as String?,
  clienteApellido: json['cliente_apellido'] as String?,
  clienteDocumento: json['cliente_documento'] as String?,
  usuarioNombre: json['usuario_nombre'] as String?,
  metodoPagoNombre: json['metodo_pago_nombre'] as String?,
  detalle: (json['detalle'] as List<dynamic>?)
      ?.map((e) => DetalleVentaModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$VentaModelToJson(VentaModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'numero_venta': instance.numeroVenta,
      'cliente_id': instance.clienteId,
      'usuario_id': instance.usuarioId,
      'tipo_venta': instance.tipoVenta,
      'metodo_pago_id': instance.metodoPagoId,
      'subtotal': instance.subtotal,
      'descuento': instance.descuento,
      'impuesto': instance.impuesto,
      'total': instance.total,
      'estado': instance.estado,
      'observaciones': instance.observaciones,
      'fecha_venta': instance.fechaVenta?.toIso8601String(),
      'cliente_nombre': instance.clienteNombre,
      'cliente_apellido': instance.clienteApellido,
      'cliente_documento': instance.clienteDocumento,
      'usuario_nombre': instance.usuarioNombre,
      'metodo_pago_nombre': instance.metodoPagoNombre,
      'detalle': instance.detalle,
    };
