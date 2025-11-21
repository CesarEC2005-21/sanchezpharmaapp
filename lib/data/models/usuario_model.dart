import 'package:json_annotation/json_annotation.dart';

part 'usuario_model.g.dart';

@JsonSerializable()
class UsuarioModel {
  final int? id;
  final String username;
  final String email;
  final String? password;
  final String nombre;
  final String apellido;
  final int edad;
  final String sexo;
  final int rolId;

  UsuarioModel({
    this.id,
    required this.username,
    required this.email,
    this.password,
    required this.nombre,
    required this.apellido,
    required this.edad,
    required this.sexo,
    required this.rolId,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) =>
      _$UsuarioModelFromJson(json);

  Map<String, dynamic> toJson() => _$UsuarioModelToJson(this);
  
  // Método para crear copia con algunos campos actualizados (útil para edición)
  UsuarioModel copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    String? nombre,
    String? apellido,
    int? edad,
    String? sexo,
    int? rolId,
  }) {
    return UsuarioModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      edad: edad ?? this.edad,
      sexo: sexo ?? this.sexo,
      rolId: rolId ?? this.rolId,
    );
  }
}

