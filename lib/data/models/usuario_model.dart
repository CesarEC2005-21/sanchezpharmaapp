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
  @JsonKey(fromJson: _edadFromJson)
  final int edad;
  final String sexo;
  @JsonKey(name: 'rol_id', fromJson: _rolIdFromJson)
  final int rolId;
  
  // Helper functions to handle null values
  static int _edadFromJson(dynamic json) {
    if (json == null) return 0;
    if (json is num) return json.toInt();
    if (json is String) return int.tryParse(json) ?? 0;
    return 0;
  }
  
  static int _rolIdFromJson(dynamic json) {
    if (json == null) return 1; // Default rol_id
    if (json is num) return json.toInt();
    if (json is String) return int.tryParse(json) ?? 1;
    return 1;
  }

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

