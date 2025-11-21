// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detalle_venta_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DetalleVentaModel _$DetalleVentaModelFromJson(Map<String, dynamic> json) =>
    DetalleVentaModel(
      id: (json['id'] as num?)?.toInt(),
      ventaId: (json['venta_id'] as num).toInt(),
      productoId: (json['producto_id'] as num).toInt(),
      cantidad: (json['cantidad'] as num).toInt(),
      precioUnitario: DetalleVentaModel._precioFromJson(
        json['precio_unitario'],
      ),
      descuento: DetalleVentaModel._precioFromJson(json['descuento']),
      subtotal: DetalleVentaModel._precioFromJson(json['subtotal']),
      productoNombre: json['producto_nombre'] as String?,
      productoCodigo: json['producto_codigo'] as String?,
    );

Map<String, dynamic> _$DetalleVentaModelToJson(DetalleVentaModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'venta_id': instance.ventaId,
      'producto_id': instance.productoId,
      'cantidad': instance.cantidad,
      'precio_unitario': instance.precioUnitario,
      'descuento': instance.descuento,
      'subtotal': instance.subtotal,
      'producto_nombre': instance.productoNombre,
      'producto_codigo': instance.productoCodigo,
    };
