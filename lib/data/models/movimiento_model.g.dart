// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movimiento_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MovimientoModel _$MovimientoModelFromJson(Map<String, dynamic> json) =>
    MovimientoModel(
      id: (json['id'] as num?)?.toInt(),
      productoId: (json['producto_id'] as num).toInt(),
      tipoMovimientoId: (json['tipo_movimiento_id'] as num).toInt(),
      cantidad: (json['cantidad'] as num).toInt(),
      stockAnterior: (json['stock_anterior'] as num).toInt(),
      stockNuevo: (json['stock_nuevo'] as num).toInt(),
      precioUnitario: (json['precio_unitario'] as num?)?.toDouble(),
      motivo: json['motivo'] as String?,
      referencia: json['referencia'] as String?,
      usuarioId: (json['usuario_id'] as num?)?.toInt(),
      fechaMovimiento: DateParser.fromJson(json['fecha_movimiento']),
      productoNombre: json['producto_nombre'] as String?,
      productoCodigo: json['producto_codigo'] as String?,
      tipoMovimientoNombre: json['tipo_movimiento_nombre'] as String?,
      tipoMovimientoTipo: json['tipo_movimiento_tipo'] as String?,
      usuarioNombre: json['usuario_nombre'] as String?,
    );

Map<String, dynamic> _$MovimientoModelToJson(MovimientoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'producto_id': instance.productoId,
      'tipo_movimiento_id': instance.tipoMovimientoId,
      'cantidad': instance.cantidad,
      'stock_anterior': instance.stockAnterior,
      'stock_nuevo': instance.stockNuevo,
      'precio_unitario': instance.precioUnitario,
      'motivo': instance.motivo,
      'referencia': instance.referencia,
      'usuario_id': instance.usuarioId,
      'fecha_movimiento': instance.fechaMovimiento?.toIso8601String(),
      'producto_nombre': instance.productoNombre,
      'producto_codigo': instance.productoCodigo,
      'tipo_movimiento_nombre': instance.tipoMovimientoNombre,
      'tipo_movimiento_tipo': instance.tipoMovimientoTipo,
      'usuario_nombre': instance.usuarioNombre,
    };
