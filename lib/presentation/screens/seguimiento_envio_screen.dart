import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../data/models/envio_model.dart';

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
  bool _isLoading = true;
  String? _errorMessage;

  // Simulación de ubicación del repartidor (en producción esto vendría del backend)
  // Por ahora, simularemos que el repartidor está en movimiento
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _startLocationUpdates();
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

      if (_repartidorPosition != null && _destinoPosition != null) {
        _updateMarkers();
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

  void _updateMarkers() {
    _markers.clear();

    if (_repartidorPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('repartidor'),
          position: LatLng(
            _repartidorPosition!.latitude,
            _repartidorPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Repartidor',
            snippet: widget.envio.conductorRepartidor ?? 'En camino',
          ),
        ),
      );
    }

    if (_destinoPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destino'),
          position: LatLng(
            _destinoPosition!.latitude,
            _destinoPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destino',
            snippet: widget.envio.direccionEntrega,
          ),
        ),
      );
    }
  }

  void _updateRoute() {
    if (_repartidorPosition != null && _destinoPosition != null) {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('ruta'),
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
    // Simular actualizaciones de ubicación cada 5 segundos
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (widget.envio.estado == 'en_camino') {
        try {
          _repartidorPosition = await _getCurrentLocation();
          _updateMarkers();
          _updateRoute();
          
          if (_mapController != null && _repartidorPosition != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(
                  _repartidorPosition!.latitude,
                  _repartidorPosition!.longitude,
                ),
              ),
            );
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

