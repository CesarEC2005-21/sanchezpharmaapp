// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'producto_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductoModel _$ProductoModelFromJson(Map<String, dynamic> json) =>
    ProductoModel(
      id: (json['id'] as num?)?.toInt(),
      codigo: json['codigo'] as String?,
      codigoBarras: json['codigo_barras'] as String?,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      categoriaId: (json['categoria_id'] as num?)?.toInt(),
      proveedorId: (json['proveedor_id'] as num?)?.toInt(),
      precioCompra: ProductoModel._precioFromJson(json['precio_compra']),
      precioVenta: ProductoModel._precioFromJson(json['precio_venta']),
      stockActual: ProductoModel._stockFromJson(json['stock_actual']),
      stockMinimo: ProductoModel._stockFromJson(json['stock_minimo']),
      unidadMedida: json['unidad_medida'] as String? ?? 'unidad',
      fechaVencimiento: DateParser.fromJson(json['fecha_vencimiento']),
      estado: json['estado'] as String? ?? 'activo',
      categoriaNombre: json['categoria_nombre'] as String?,
      proveedorNombre: json['proveedor_nombre'] as String?,
      estadoAlerta: json['estado_alerta'] as String?,
      diasRestantes: (json['dias_restantes'] as num?)?.toInt(),
      faltante: (json['faltante'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProductoModelToJson(ProductoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'codigo': instance.codigo,
      'codigo_barras': instance.codigoBarras,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'categoria_id': instance.categoriaId,
      'proveedor_id': instance.proveedorId,
      'precio_compra': instance.precioCompra,
      'precio_venta': instance.precioVenta,
      'stock_actual': instance.stockActual,
      'stock_minimo': instance.stockMinimo,
      'unidad_medida': instance.unidadMedida,
      'fecha_vencimiento': instance.fechaVencimiento?.toIso8601String(),
      'estado': instance.estado,
      'categoria_nombre': instance.categoriaNombre,
      'proveedor_nombre': instance.proveedorNombre,
      'estado_alerta': instance.estadoAlerta,
      'dias_restantes': instance.diasRestantes,
      'faltante': instance.faltante,
    };
