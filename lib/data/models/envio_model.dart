import 'package:json_annotation/json_annotation.dart';
import 'estado_envio_model.dart';
import '../../core/utils/date_parser.dart';

part 'envio_model.g.dart';

@JsonSerializable()
class EnvioModel {
  final int? id;
  @JsonKey(name: 'venta_id')
  final int ventaId;
  @JsonKey(name: 'numero_seguimiento')
  final String? numeroSeguimiento;
  @JsonKey(name: 'direccion_entrega')
  final String direccionEntrega;
  @JsonKey(name: 'latitud_destino', fromJson: _precioFromJson)
  final double? latitudDestino;
  @JsonKey(name: 'longitud_destino', fromJson: _precioFromJson)
  final double? longitudDestino;
  @JsonKey(name: 'latitud_repartidor', fromJson: _precioFromJson)
  final double? latitudRepartidor;
  @JsonKey(name: 'longitud_repartidor', fromJson: _precioFromJson)
  final double? longitudRepartidor;
  @JsonKey(name: 'telefono_contacto')
  final String telefonoContacto;
  @JsonKey(name: 'nombre_destinatario')
  final String nombreDestinatario;
  @JsonKey(name: 'referencia_direccion')
  final String? referenciaDireccion;
  @JsonKey(name: 'fecha_estimada_entrega', fromJson: DateParser.fromJson)
  final DateTime? fechaEstimadaEntrega;
  @JsonKey(name: 'fecha_real_entrega', fromJson: DateParser.fromJson)
  final DateTime? fechaRealEntrega;
  @JsonKey(name: 'conductor_repartidor')
  final String? conductorRepartidor;
  @JsonKey(name: 'costo_envio', fromJson: _precioFromJson)
  final double costoEnvio;
  final String estado; // 'pendiente', 'preparando', 'en_camino', 'entregado', 'cancelado'
  final String? observaciones;
  @JsonKey(name: 'fecha_creacion', fromJson: DateParser.fromJson)
  final DateTime? fechaCreacion;
  @JsonKey(name: 'numero_venta')
  final String? numeroVenta;
  @JsonKey(name: 'fecha_venta', fromJson: DateParser.fromJson)
  final DateTime? fechaVenta;
  @JsonKey(name: 'total', fromJson: _precioFromJson)
  final double? total;
  @JsonKey(name: 'cliente_nombre')
  final String? clienteNombre;
  @JsonKey(name: 'cliente_telefono')
  final String? clienteTelefono;
  @JsonKey(name: 'historial_estados')
  final List<EstadoEnvioModel>? historialEstados;

  EnvioModel({
    this.id,
    required this.ventaId,
    this.numeroSeguimiento,
    required this.direccionEntrega,
    this.latitudDestino,
    this.longitudDestino,
    this.latitudRepartidor,
    this.longitudRepartidor,
    required this.telefonoContacto,
    required this.nombreDestinatario,
    this.referenciaDireccion,
    this.fechaEstimadaEntrega,
    this.fechaRealEntrega,
    this.conductorRepartidor,
    this.costoEnvio = 0.0,
    this.estado = 'pendiente',
    this.observaciones,
    this.fechaCreacion,
    this.numeroVenta,
    this.fechaVenta,
    this.total,
    this.clienteNombre,
    this.clienteTelefono,
    this.historialEstados,
  });

  factory EnvioModel.fromJson(Map<String, dynamic> json) =>
      _$EnvioModelFromJson(json);

  Map<String, dynamic> toJson() => _$EnvioModelToJson(this);

  static double _precioFromJson(dynamic json) {
    if (json == null) return 0.0;
    if (json is num) return json.toDouble();
    if (json is String) return double.tryParse(json) ?? 0.0;
    return 0.0;
  }

  String get estadoTexto {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'preparando':
        return 'Preparando';
      case 'en_camino':
        return 'En Camino';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }
}

