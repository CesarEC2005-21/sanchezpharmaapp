class BannerModel {
  final int? id;
  final String titulo;
  final String? descripcion;
  final String imagenUrl;
  final String? enlace;
  final int orden;
  final bool activo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  BannerModel({
    this.id,
    required this.titulo,
    this.descripcion,
    required this.imagenUrl,
    this.enlace,
    this.orden = 0,
    this.activo = true,
    this.fechaInicio,
    this.fechaFin,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as int?,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      imagenUrl: json['imagen_url'] as String,
      enlace: json['enlace'] as String?,
      orden: json['orden'] as int? ?? 0,
      activo: (json['activo'] is bool) 
          ? json['activo'] as bool
          : (json['activo'] == 1 || json['activo'] == true),
      fechaInicio: _parseDateTime(json['fecha_inicio']),
      fechaFin: _parseDateTime(json['fecha_fin']),
      fechaCreacion: _parseDateTime(json['fecha_creacion']),
      fechaActualizacion: _parseDateTime(json['fecha_actualizacion']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is String) {
        // Manejar formato MySQL: "YYYY-MM-DD HH:MM:SS"
        // Reemplazar espacio por T para ISO 8601
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
      'titulo': titulo,
      'descripcion': descripcion,
      'imagen_url': imagenUrl,
      'enlace': enlace,
      'orden': orden,
      'activo': activo,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'fecha_creacion': fechaCreacion?.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  bool get estaActivo {
    if (!activo) return false;
    
    final now = DateTime.now();
    
    if (fechaInicio != null && now.isBefore(fechaInicio!)) {
      return false;
    }
    
    if (fechaFin != null && now.isAfter(fechaFin!)) {
      return false;
    }
    
    return true;
  }

  BannerModel copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    String? imagenUrl,
    String? enlace,
    int? orden,
    bool? activo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return BannerModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      enlace: enlace ?? this.enlace,
      orden: orden ?? this.orden,
      activo: activo ?? this.activo,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}

