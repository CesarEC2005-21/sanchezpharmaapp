import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/date_parser.dart';

part 'cliente_model.g.dart';

@JsonSerializable()
class ClienteModel {
  final int? id;
  final String nombre;
  final String? apellido;
  final String? documento;
  @JsonKey(name: 'tipo_documento')
  final String tipoDocumento;
  final String? telefono;
  final String? email;
  final String? direccion;
  @JsonKey(name: 'fecha_registro', fromJson: DateParser.fromJson)
  final DateTime? fechaRegistro;
  final String estado;

  ClienteModel({
    this.id,
    required this.nombre,
    this.apellido,
    this.documento,
    this.tipoDocumento = 'DNI',
    this.telefono,
    this.email,
    this.direccion,
    this.fechaRegistro,
    this.estado = 'activo',
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) =>
      _$ClienteModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClienteModelToJson(this);

  String get nombreCompleto => apellido != null ? '$nombre $apellido' : nombre;
}

