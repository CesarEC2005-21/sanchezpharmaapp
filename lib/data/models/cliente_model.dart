import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/date_parser.dart';

part 'cliente_model.g.dart';

@JsonSerializable()
class ClienteModel {
  final int? id;
  @JsonKey(name: 'nombres')
  final String nombres;
  @JsonKey(name: 'apellido_paterno')
  final String? apellidoPaterno;
  @JsonKey(name: 'apellido_materno')
  final String? apellidoMaterno;
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
    required this.nombres,
    this.apellidoPaterno,
    this.apellidoMaterno,
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

  String get nombreCompleto {
    final partes = [nombres];
    if (apellidoPaterno != null && apellidoPaterno!.isNotEmpty) {
      partes.add(apellidoPaterno!);
    }
    if (apellidoMaterno != null && apellidoMaterno!.isNotEmpty) {
      partes.add(apellidoMaterno!);
    }
    return partes.join(' ');
  }
}

