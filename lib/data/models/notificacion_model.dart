import 'package:json_annotation/json_annotation.dart';

part 'notificacion_model.g.dart';

@JsonSerializable()
class NotificacionModel {
  final int id;
  @JsonKey(name: 'cliente_id')
  final int clienteId;
  final String titulo;
  final String cuerpo;
  final String tipo;
  @JsonKey(name: 'relacion_id')
  final int? relacionId;
  @JsonKey(fromJson: _boolFromJson)
  final bool leida;
  @JsonKey(name: 'fecha_creacion')
  final String fechaCreacion;
  @JsonKey(name: 'fecha_leida')
  final String? fechaLeida;

  NotificacionModel({
    required this.id,
    required this.clienteId,
    required this.titulo,
    required this.cuerpo,
    required this.tipo,
    this.relacionId,
    required this.leida,
    required this.fechaCreacion,
    this.fechaLeida,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) => _$NotificacionModelFromJson(json);
  Map<String, dynamic> toJson() => _$NotificacionModelToJson(this);

  static bool _boolFromJson(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}

