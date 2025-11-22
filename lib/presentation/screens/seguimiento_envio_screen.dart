import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../data/models/envio_model.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/utils/shared_prefs_helper.dart';

class SeguimientoEnvioScreen extends StatefulWidget {
  final EnvioModel envio;

  const SeguimientoEnvioScreen({
    super.key,
    required this.envio,
  });

  @override
  State<SeguimientoEnvioScreen> createState() => _SeguimientoEnvioScreenState();
}

class _SeguimientoEnvioScreenState extends State<SeguimientoEnvioScreen> {
  GoogleMapController? _mapController;
  Position? _repartidorPosition;
  Position? _destinoPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _rutaRecorrida = []; // Lista de puntos de la ruta recorrida
  bool _isLoading = true;
  String? _errorMessage;
  bool _esRepartidor = false;
  String? _username;
  final ApiService _apiService = ApiService(DioClient.createDio());

  // Timer para actualizar ubicación en tiempo real
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _verificarUsuario();
    _initializeMap();
    _startLocationUpdates();
  }

  Future<void> _verificarUsuario() async {
    final username = await SharedPrefsHelper.getUsername();
    setState(() {
      _username = username;
      // Verificar si el usuario actual es el repartidor asignado
      _esRepartidor = widget.envio.conductorRepartidor != null &&
          widget.envio.conductorRepartidor!.isNotEmpty &&
          username != null &&
          widget.envio.conductorRepartidor!.toLowerCase().contains(username.toLowerCase());
    });
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Primero, obtener la posición del destino
      // Usar coordenadas del modelo si están disponibles, sino geocodificar la dirección
      if (widget.envio.latitudDestino != null && widget.envio.longitudDestino != null) {
        // Usar coordenadas almacenadas en la base de datos (más preciso)
        _destinoPosition = Position(
          latitude: widget.envio.latitudDestino!,
          longitude: widget.envio.longitudDestino!,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      } else {
        // Fallback: convertir dirección de texto a coordenadas (menos preciso)
        try {
          _destinoPosition = await _getLocationFromAddress(widget.envio.direccionEntrega);
        } catch (e) {
          print('Error al geocodificar dirección: $e');
          // Usar ubicación por defecto (Lima, Perú)
          _destinoPosition = Position(
            latitude: -12.0464,
            longitude: -77.0428,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
      }
      
      // Si hay coordenadas del repartidor almacenadas, usarlas
      if (widget.envio.latitudRepartidor != null && widget.envio.longitudRepartidor != null) {
        _repartidorPosition = Position(
          latitude: widget.envio.latitudRepartidor!,
          longitude: widget.envio.longitudRepartidor!,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        // Inicializar ruta recorrida con la posición inicial
        _rutaRecorrida = [LatLng(widget.envio.latitudRepartidor!, widget.envio.longitudRepartidor!)];
      } else {
        // Obtener ubicación actual del dispositivo (simulando ubicación del repartidor)
        try {
          _repartidorPosition = await _getCurrentLocation();
        } catch (e) {
          print('Error al obtener ubicación actual: $e');
          // Si no se puede obtener la ubicación, usar la posición del destino como fallback
          _repartidorPosition = _destinoPosition;
        }
      }

      // Asegurar que al menos una posición esté disponible
      if (_destinoPosition == null) {
        throw Exception('No se pudo obtener la ubicación del destino');
      }

      if (_repartidorPosition == null) {
        _repartidorPosition = _destinoPosition;
      }

      // Inicializar la ruta recorrida con la posición inicial del repartidor
      if (_repartidorPosition != null && _rutaRecorrida.isEmpty) {
        _rutaRecorrida = [LatLng(_repartidorPosition!.latitude, _repartidorPosition!.longitude)];
      }

      if (_repartidorPosition != null && _destinoPosition != null) {
        await _updateMarkers();
        _updateRoute();
        // No llamar _moveCameraToFitBoth aquí porque el controlador aún no está listo
        // Se llamará cuando el mapa se cree en onMapCreated
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error al inicializar mapa: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Error al cargar el mapa: ${e.toString()}\n\nAsegúrate de que:\n1. La API key de Google Maps esté configurada\n2. Tengas conexión a internet\n3. Los permisos de ubicación estén habilitados';
        _isLoading = false;
      });
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Los servicios de ubicación están deshabilitados');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permisos de ubicación denegados');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Los permisos de ubicación están denegados permanentemente');
    }

    // En producción, esto debería obtener la ubicación real del repartidor desde el backend
    // Por ahora, simulamos una ubicación cerca del destino
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
    
    // Simulación: mover el repartidor gradualmente hacia el destino
    if (_destinoPosition != null) {
      final lat = position.latitude + (widget.envio.estado == 'en_camino' ? 0.01 : 0.0);
      final lng = position.longitude + (widget.envio.estado == 'en_camino' ? 0.01 : 0.0);
      return Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        altitude: position.altitude,
        altitudeAccuracy: position.altitudeAccuracy,
        heading: position.heading,
        headingAccuracy: position.headingAccuracy,
        speed: position.speed,
        speedAccuracy: position.speedAccuracy,
      );
    }
    
    return position;
  }

  Future<Position> _getLocationFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return Position(
          latitude: locations.first.latitude,
          longitude: locations.first.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    } catch (e) {
      // Si no se puede geocodificar, usar una ubicación por defecto
      print('Error al geocodificar: $e');
    }
    
    // Ubicación por defecto (Lima, Perú)
    return Position(
      latitude: -12.0464,
      longitude: -77.0428,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  Future<BitmapDescriptor> _crearIconoAutomovil() async {
    return await _crearIconoPersonalizado(
      icono: Icons.directions_car,
      color: Colors.blue.shade700,
    );
  }

  Future<BitmapDescriptor> _crearIconoHumano() async {
    return await _crearIconoPersonalizado(
      icono: Icons.person,
      color: Colors.red,
      texto: 'C',
    );
  }

  Future<BitmapDescriptor> _crearIconoPersonalizado({
    required IconData icono,
    required Color color,
    String? texto,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final Paint paintFondo = Paint()..color = Colors.white;

    // Dibujar círculo de fondo
    canvas.drawCircle(
      const Offset(50, 50),
      40,
      paintFondo,
    );
    canvas.drawCircle(
      const Offset(50, 50),
      40,
      paint..style = PaintingStyle.stroke..strokeWidth = 3,
    );

    // Dibujar icono
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icono.codePoint),
        style: TextStyle(
          fontSize: 50,
          fontFamily: icono.fontFamily,
          color: color,
          package: icono.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (100 - textPainter.width) / 2,
        (100 - textPainter.height) / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(100, 100);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  Future<void> _updateMarkers() async {
    _markers.clear();

    if (_repartidorPosition != null) {
      final iconoAutomovil = await _crearIconoAutomovil();
      _markers.add(
        Marker(
          markerId: const MarkerId('repartidor'),
          position: LatLng(
            _repartidorPosition!.latitude,
            _repartidorPosition!.longitude,
          ),
          icon: iconoAutomovil,
          infoWindow: InfoWindow(
            title: 'Repartidor',
            snippet: widget.envio.conductorRepartidor ?? 'En camino',
          ),
        ),
      );
    }

    if (_destinoPosition != null) {
      final iconoHumano = await _crearIconoHumano();
      _markers.add(
        Marker(
          markerId: const MarkerId('destino'),
          position: LatLng(
            _destinoPosition!.latitude,
            _destinoPosition!.longitude,
          ),
          icon: iconoHumano,
          infoWindow: InfoWindow(
            title: 'Destino',
            snippet: widget.envio.direccionEntrega,
          ),
        ),
      );
    }
    
    setState(() {});
  }

  void _updateRoute() {
    _polylines.clear();
    
    // Ruta recorrida (línea sólida azul)
    if (_rutaRecorrida.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('ruta_recorrida'),
          points: _rutaRecorrida,
          color: Colors.blue,
          width: 5,
          patterns: [],
        ),
      );
    }
    
    // Ruta restante hasta el destino (línea punteada verde)
    if (_repartidorPosition != null && _destinoPosition != null) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('ruta_restante'),
          points: [
            LatLng(_repartidorPosition!.latitude, _repartidorPosition!.longitude),
            LatLng(_destinoPosition!.latitude, _destinoPosition!.longitude),
          ],
          color: Colors.green,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }
  }

  void _moveCameraToFitBoth() {
    if (_repartidorPosition != null && _destinoPosition != null && _mapController != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _repartidorPosition!.latitude < _destinoPosition!.latitude
              ? _repartidorPosition!.latitude
              : _destinoPosition!.latitude,
          _repartidorPosition!.longitude < _destinoPosition!.longitude
              ? _repartidorPosition!.longitude
              : _destinoPosition!.longitude,
        ),
        northeast: LatLng(
          _repartidorPosition!.latitude > _destinoPosition!.latitude
              ? _repartidorPosition!.latitude
              : _destinoPosition!.latitude,
          _repartidorPosition!.longitude > _destinoPosition!.longitude
              ? _repartidorPosition!.longitude
              : _destinoPosition!.longitude,
        ),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    }
  }

  void _startLocationUpdates() {
    // Actualizar ubicación cada 10 segundos si el envío está en camino
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (widget.envio.estado == 'en_camino' && widget.envio.id != null) {
        try {
          if (_esRepartidor) {
            // Si es el repartidor, actualizar su ubicación y enviarla al backend
            final nuevaPosicion = await _getCurrentLocation();
            if (nuevaPosicion != null) {
              final nuevaLatLng = LatLng(nuevaPosicion.latitude, nuevaPosicion.longitude);
              
              setState(() {
                _repartidorPosition = nuevaPosicion;
                // Agregar nueva posición a la ruta recorrida si es diferente a la anterior
                if (_rutaRecorrida.isEmpty || 
                    _rutaRecorrida.last.latitude != nuevaLatLng.latitude ||
                    _rutaRecorrida.last.longitude != nuevaLatLng.longitude) {
                  _rutaRecorrida.add(nuevaLatLng);
                }
              });
              
              // Actualizar ubicación en el backend
              try {
                await _apiService.actualizarEnvio(
                  widget.envio.id!,
                  {
                    'latitud_repartidor': nuevaPosicion.latitude,
                    'longitud_repartidor': nuevaPosicion.longitude,
                  },
                );
              } catch (e) {
                print('Error al actualizar ubicación en backend: $e');
              }
              
              await _updateMarkers();
              _updateRoute();
              
              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(
                      nuevaPosicion.latitude,
                      nuevaPosicion.longitude,
                    ),
                  ),
                );
              }
            }
          } else {
            // Si es cliente, obtener la ubicación actualizada del repartidor desde el backend
            try {
              final response = await _apiService.getEnvio(widget.envio.id!);
              if (response.response.statusCode == 200) {
                final data = response.data;
                if (data['code'] == 1 && data['data'] != null) {
                  final envioActualizado = EnvioModel.fromJson(data['data']);
                  if (envioActualizado.latitudRepartidor != null && 
                      envioActualizado.longitudRepartidor != null) {
                    final nuevaLatLng = LatLng(
                      envioActualizado.latitudRepartidor!,
                      envioActualizado.longitudRepartidor!,
                    );
                    
                    setState(() {
                      _repartidorPosition = Position(
                        latitude: envioActualizado.latitudRepartidor!,
                        longitude: envioActualizado.longitudRepartidor!,
                        timestamp: DateTime.now(),
                        accuracy: 0,
                        altitude: 0,
                        altitudeAccuracy: 0,
                        heading: 0,
                        headingAccuracy: 0,
                        speed: 0,
                        speedAccuracy: 0,
                      );
                      
                      // Agregar nueva posición a la ruta recorrida si es diferente a la anterior
                      if (_rutaRecorrida.isEmpty || 
                          _rutaRecorrida.last.latitude != nuevaLatLng.latitude ||
                          _rutaRecorrida.last.longitude != nuevaLatLng.longitude) {
                        _rutaRecorrida.add(nuevaLatLng);
                      }
                    });
                    
                    await _updateMarkers();
                    _updateRoute();
                  }
                }
              }
            } catch (e) {
              print('Error al obtener ubicación del repartidor: $e');
            }
          }
        } catch (e) {
          print('Error al actualizar ubicación: $e');
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seguimiento: ${widget.envio.numeroSeguimiento ?? "N/A"}'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeMap,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : (_repartidorPosition == null && _destinoPosition == null)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No se pudo cargar la ubicación',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _initializeMap,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        GoogleMap(
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                            // Esperar un momento antes de mover la cámara para asegurar que el mapa esté listo
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted && _mapController != null) {
                                _moveCameraToFitBoth();
                              }
                            });
                          },
                          initialCameraPosition: CameraPosition(
                            target: _repartidorPosition != null
                                ? LatLng(
                                    _repartidorPosition!.latitude,
                                    _repartidorPosition!.longitude,
                                  )
                                : _destinoPosition != null
                                    ? LatLng(
                                        _destinoPosition!.latitude,
                                        _destinoPosition!.longitude,
                                      )
                                    : const LatLng(-12.0464, -77.0428), // Lima, Perú por defecto
                            zoom: 13,
                          ),
                          markers: _markers,
                          polylines: _polylines,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          mapType: MapType.normal,
                          onCameraMoveStarted: () {
                            // Evitar errores durante el movimiento de la cámara
                          },
                          compassEnabled: true,
                          mapToolbarEnabled: false,
                        ),
                    // Panel de información
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getEstadoIcon(widget.envio.estado),
                                  color: _getEstadoColor(widget.envio.estado),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.envio.estadoTexto,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Destino: ${widget.envio.direccionEntrega}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            if (widget.envio.conductorRepartidor != null)
                              Text(
                                'Repartidor: ${widget.envio.conductorRepartidor}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            if (_esRepartidor)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.person, size: 16, color: Colors.blue.shade700),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Eres el repartidor asignado - Tu ubicación se actualiza automáticamente',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_repartidorPosition != null && _destinoPosition != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Distancia aproximada: ${_calculateDistance().toStringAsFixed(2)} km',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  double _calculateDistance() {
    if (_repartidorPosition == null || _destinoPosition == null) return 0.0;
    
    return Geolocator.distanceBetween(
      _repartidorPosition!.latitude,
      _repartidorPosition!.longitude,
      _destinoPosition!.latitude,
      _destinoPosition!.longitude,
    ) / 1000; // Convertir a kilómetros
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.pending;
      case 'preparando':
        return Icons.inventory_2;
      case 'en_camino':
        return Icons.local_shipping;
      case 'entregado':
        return Icons.check_circle;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'preparando':
        return Colors.green;
      case 'en_camino':
        return Colors.purple;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

