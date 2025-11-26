class DireccionModel {
  final int? id;
  final int clienteId;
  final String titulo;
  final String direccion;
  final String? referencia;
  final double latitud;
  final double longitud;
  final bool esPrincipal;
  final DateTime? fechaCreacion;

  DireccionModel({
    this.id,
    required this.clienteId,
    required this.titulo,
    required this.direccion,
    this.referencia,
    required this.latitud,
    required this.longitud,
    this.esPrincipal = false,
    this.fechaCreacion,
  });

  factory DireccionModel.fromJson(Map<String, dynamic> json) {
    return DireccionModel(
      id: json['id'] as int?,
      clienteId: json['cliente_id'] as int,
      titulo: json['titulo'] as String,
      direccion: json['direccion'] as String,
      referencia: json['referencia'] as String?,
      latitud: double.parse(json['latitud'].toString()),
      longitud: double.parse(json['longitud'].toString()),
      esPrincipal: (json['es_principal'] is bool)
          ? json['es_principal'] as bool
          : (json['es_principal'] == 1 || json['es_principal'] == true),
      fechaCreacion: json['fecha_creacion'] != null
          ? _parseDateTime(json['fecha_creacion'])
          : null,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    try {
      if (value is String) {
        final isoString = value.replaceFirst(' ', 'T');
        return DateTime.parse(isoString);
      }
      return null;
    } catch (e) {
      print('Error parseando fecha: $value - Error: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'titulo': titulo,
      'direccion': direccion,
      'referencia': referencia,
      'latitud': latitud,
      'longitud': longitud,
      'es_principal': esPrincipal,
      'fecha_creacion': fechaCreacion?.toIso8601String(),
    };
  }

  DireccionModel copyWith({
    int? id,
    int? clienteId,
    String? titulo,
    String? direccion,
    String? referencia,
    double? latitud,
    double? longitud,
    bool? esPrincipal,
    DateTime? fechaCreacion,
  }) {
    return DireccionModel(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      titulo: titulo ?? this.titulo,
      direccion: direccion ?? this.direccion,
      referencia: referencia ?? this.referencia,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      esPrincipal: esPrincipal ?? this.esPrincipal,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}

