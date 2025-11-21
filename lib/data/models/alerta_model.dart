import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/date_parser.dart';

part 'alerta_model.g.dart';

@JsonSerializable()
class AlertaModel {
  final int? id;
  @JsonKey(name: 'producto_id')
  final int productoId;
  @JsonKey(name: 'tipo_alerta')
  final String tipoAlerta; // 'stock_bajo', 'producto_vencido', 'proximo_vencer', 'sin_movimiento'
  final String? mensaje;
  @JsonKey(name: 'fecha_alerta', fromJson: DateParser.fromJson)
  final DateTime? fechaAlerta;
  final bool leida;
  @JsonKey(name: 'fecha_leida', fromJson: DateParser.fromJson)
  final DateTime? fechaLeida;
  @JsonKey(name: 'producto_nombre')
  final String? productoNombre;
  @JsonKey(name: 'producto_codigo')
  final String? productoCodigo;

  AlertaModel({
    this.id,
    required this.productoId,
    required this.tipoAlerta,
    this.mensaje,
    this.fechaAlerta,
    this.leida = false,
    this.fechaLeida,
    this.productoNombre,
    this.productoCodigo,
  });

  factory AlertaModel.fromJson(Map<String, dynamic> json) =>
      _$AlertaModelFromJson(json);

  Map<String, dynamic> toJson() => _$AlertaModelToJson(this);
}

