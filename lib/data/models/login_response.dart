import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  final int code;
  final String message;
  final String? token;
  final UserModel? user;
  @JsonKey(name: 'user_type')
  final String? userType; // 'cliente' o 'usuario'
  @JsonKey(name: 'cliente_id')
  final int? clienteId; // ID del cliente si es tipo 'cliente'

  LoginResponse({
    required this.code,
    required this.message,
    this.token,
    this.user,
    this.userType,
    this.clienteId,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
  
  bool get isCliente => userType == 'cliente';
  bool get isUsuarioInterno => userType == 'usuario' || userType == null;
}

