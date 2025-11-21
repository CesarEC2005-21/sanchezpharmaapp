// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'envio_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnvioModel _$EnvioModelFromJson(Map<String, dynamic> json) => EnvioModel(
  id: (json['id'] as num?)?.toInt(),
  ventaId: (json['venta_id'] as num).toInt(),
  numeroSeguimiento: json['numero_seguimiento'] as String?,
  direccionEntrega: json['direccion_entrega'] as String,
  latitudDestino: EnvioModel._precioFromJson(json['latitud_destino']),
  longitudDestino: EnvioModel._precioFromJson(json['longitud_destino']),
  latitudRepartidor: EnvioModel._precioFromJson(json['latitud_repartidor']),
  longitudRepartidor: EnvioModel._precioFromJson(json['longitud_repartidor']),
  telefonoContacto: json['telefono_contacto'] as String,
  nombreDestinatario: json['nombre_destinatario'] as String,
  referenciaDireccion: json['referencia_direccion'] as String?,
  fechaEstimadaEntrega: DateParser.fromJson(json['fecha_estimada_entrega']),
  fechaRealEntrega: DateParser.fromJson(json['fecha_real_entrega']),
  conductorRepartidor: json['conductor_repartidor'] as String?,
  costoEnvio: json['costo_envio'] == null
      ? 0.0
      : EnvioModel._precioFromJson(json['costo_envio']),
  estado: json['estado'] as String? ?? 'pendiente',
  observaciones: json['observaciones'] as String?,
  fechaCreacion: DateParser.fromJson(json['fecha_creacion']),
  numeroVenta: json['numero_venta'] as String?,
  fechaVenta: DateParser.fromJson(json['fecha_venta']),
  total: EnvioModel._precioFromJson(json['total']),
  clienteNombre: json['cliente_nombre'] as String?,
  clienteTelefono: json['cliente_telefono'] as String?,
  historialEstados: (json['historial_estados'] as List<dynamic>?)
      ?.map((e) => EstadoEnvioModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$EnvioModelToJson(
  EnvioModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'venta_id': instance.ventaId,
  'numero_seguimiento': instance.numeroSeguimiento,
  'direccion_entrega': instance.direccionEntrega,
  'latitud_destino': instance.latitudDestino,
  'longitud_destino': instance.longitudDestino,
  'latitud_repartidor': instance.latitudRepartidor,
  'longitud_repartidor': instance.longitudRepartidor,
  'telefono_contacto': instance.telefonoContacto,
  'nombre_destinatario': instance.nombreDestinatario,
  'referencia_direccion': instance.referenciaDireccion,
  'fecha_estimada_entrega': instance.fechaEstimadaEntrega?.toIso8601String(),
  'fecha_real_entrega': instance.fechaRealEntrega?.toIso8601String(),
  'conductor_repartidor': instance.conductorRepartidor,
  'costo_envio': instance.costoEnvio,
  'estado': instance.estado,
  'observaciones': instance.observaciones,
  'fecha_creacion': instance.fechaCreacion?.toIso8601String(),
  'numero_venta': instance.numeroVenta,
  'fecha_venta': instance.fechaVenta?.toIso8601String(),
  'total': instance.total,
  'cliente_nombre': instance.clienteNombre,
  'cliente_telefono': instance.clienteTelefono,
  'historial_estados': instance.historialEstados,
};
