/// Excepción amigable que no muestra detalles técnicos al usuario
class FriendlyException implements Exception {
  final String message;
  final String? code;
  
  FriendlyException(this.message, {this.code});
  
  @override
  String toString() {
    // Retornar solo el mensaje amigable, sin detalles técnicos
    return message;
  }
}

