import 'package:json_annotation/json_annotation.dart';

part 'rol_model.g.dart';

@JsonSerializable()
class RolModel {
  final int id;
  final String nombre;
  final String? descripcion;

  RolModel({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  factory RolModel.fromJson(Map<String, dynamic> json) =>
      _$RolModelFromJson(json);

  Map<String, dynamic> toJson() => _$RolModelToJson(this);
}

