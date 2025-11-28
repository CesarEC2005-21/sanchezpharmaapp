import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/date_parser.dart';

part 'producto_model.g.dart';

@JsonSerializable()
class ProductoModel {
  final int? id;
  final String? codigo;
  @JsonKey(name: 'codigo_barras')
  final String? codigoBarras;
  final String nombre;
  final String? descripcion;
  @JsonKey(name: 'categoria_id')
  final int? categoriaId;
  @JsonKey(name: 'proveedor_id')
  final int? proveedorId;
  @JsonKey(name: 'precio_compra', fromJson: _precioFromJson)
  final double precioCompra;
  @JsonKey(name: 'precio_venta', fromJson: _precioFromJson)
  final double precioVenta;
  @JsonKey(name: 'descuento_porcentaje', fromJson: _precioFromJson)
  final double descuentoPorcentaje;
  @JsonKey(name: 'stock_actual', fromJson: _stockFromJson)
  final int stockActual;
  @JsonKey(name: 'stock_minimo', fromJson: _stockFromJson)
  final int stockMinimo;
  @JsonKey(name: 'unidad_medida')
  final String unidadMedida;
  @JsonKey(name: 'fecha_vencimiento', fromJson: DateParser.fromJson)
  final DateTime? fechaVencimiento;
  final String estado;
  @JsonKey(name: 'categoria_nombre')
  final String? categoriaNombre;
  @JsonKey(name: 'proveedor_nombre')
  final String? proveedorNombre;
  @JsonKey(name: 'estado_alerta')
  final String? estadoAlerta;
  @JsonKey(name: 'dias_restantes')
  final int? diasRestantes;
  final int? faltante;
  @JsonKey(name: 'imagen_url')
  final String? imagenUrl;
  @JsonKey(name: 'imagenes')
  final List<String>? imagenes;

  ProductoModel({
    this.id,
    this.codigo,
    this.codigoBarras,
    required this.nombre,
    this.descripcion,
    this.categoriaId,
    this.proveedorId,
    required this.precioCompra,
    required this.precioVenta,
    this.descuentoPorcentaje = 0.0,
    required this.stockActual,
    required this.stockMinimo,
    this.unidadMedida = 'unidad',
    this.fechaVencimiento,
    this.estado = 'activo',
    this.categoriaNombre,
    this.proveedorNombre,
    this.estadoAlerta,
    this.diasRestantes,
    this.faltante,
    this.imagenUrl,
    this.imagenes,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) =>
      _$ProductoModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductoModelToJson(this);

  static double _precioFromJson(dynamic json) {
    if (json == null) return 0.0;
    if (json is num) return json.toDouble();
    if (json is String) return double.tryParse(json) ?? 0.0;
    return 0.0;
  }

  static int _stockFromJson(dynamic json) {
    if (json == null) return 0;
    if (json is num) return json.toInt();
    if (json is String) return int.tryParse(json) ?? 0;
    return 0;
  }

  ProductoModel copyWith({
    int? id,
    String? codigo,
    String? codigoBarras,
    String? nombre,
    String? descripcion,
    int? categoriaId,
    int? proveedorId,
    double? precioCompra,
    double? precioVenta,
    double? descuentoPorcentaje,
    int? stockActual,
    int? stockMinimo,
    String? unidadMedida,
    DateTime? fechaVencimiento,
    String? estado,
    String? imagenUrl,
    List<String>? imagenes,
  }) {
    return ProductoModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoriaId: categoriaId ?? this.categoriaId,
      proveedorId: proveedorId ?? this.proveedorId,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      descuentoPorcentaje: descuentoPorcentaje ?? this.descuentoPorcentaje,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      estado: estado ?? this.estado,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      imagenes: imagenes ?? this.imagenes,
    );
  }
  
  // Método helper para obtener todas las imágenes disponibles
  List<String> get todasLasImagenes {
    List<String> lista = [];
    if (imagenes != null && imagenes!.isNotEmpty) {
      lista.addAll(imagenes!);
    } else if (imagenUrl != null && imagenUrl!.isNotEmpty) {
      lista.add(imagenUrl!);
    }
    return lista;
  }
  
  // Método helper para obtener el precio con descuento aplicado
  double get precioConDescuento {
    if (descuentoPorcentaje > 0) {
      return precioVenta * (1 - descuentoPorcentaje / 100);
    }
    return precioVenta;
  }
  
  // Método helper para verificar si tiene descuento
  bool get tieneDescuento {
    return descuentoPorcentaje > 0;
  }
}

