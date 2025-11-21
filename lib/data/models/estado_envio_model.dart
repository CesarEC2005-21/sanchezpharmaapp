import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/date_parser.dart';

part 'estado_envio_model.g.dart';

@JsonSerializable()
class EstadoEnvioModel {
  final int? id;
  @JsonKey(name: 'envio_id')
  final int envioId;
  @JsonKey(name: 'estado_anterior')
  final String? estadoAnterior;
  @JsonKey(name: 'estado_nuevo')
  final String estadoNuevo;
  final String? observaciones;
  @JsonKey(name: 'usuario_id')
  final int? usuarioId;
  @JsonKey(name: 'fecha_cambio', fromJson: DateParser.fromJson)
  final DateTime? fechaCambio;
  @JsonKey(name: 'usuario_nombre')
  final String? usuarioNombre;

  EstadoEnvioModel({
    this.id,
    required this.envioId,
    this.estadoAnterior,
    required this.estadoNuevo,
    this.observaciones,
    this.usuarioId,
    this.fechaCambio,
    this.usuarioNombre,
  });

  factory EstadoEnvioModel.fromJson(Map<String, dynamic> json) =>
      _$EstadoEnvioModelFromJson(json);

  Map<String, dynamic> toJson() => _$EstadoEnvioModelToJson(this);
}

