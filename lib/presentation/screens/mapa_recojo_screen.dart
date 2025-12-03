import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../data/services/directions_service.dart';
import '../../core/utils/error_message_helper.dart';

class MapaRecojoScreen extends StatefulWidget {
  final String? numeroPedido;
  final DateTime? fechaPedido;

  const MapaRecojoScreen({
    super.key,
    this.numeroPedido,
    this.fechaPedido,
  });

  @override
  State<MapaRecojoScreen> createState() => _MapaRecojoScreenState();
}

class _MapaRecojoScreenState extends State<MapaRecojoScreen> {
  GoogleMapController? _mapController;
  Position? _miUbicacion;
  Position? _ubicacionLocal;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String? _errorMessage;
  String? _routeDistance;
  String? _routeDuration;

  // Ubicación del local (Puerto de Palos 390, La Victoria, Chiclayo, Lambayeque)
  static const String _direccionLocal = 'Puerto de Palos 390, La Victoria, Chiclayo, Lambayeque, Perú';

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obtener coordenadas del local mediante geocodificación
      try {
        List<Location> locations = await locationFromAddress(_direccionLocal);
        if (locations.isNotEmpty) {
          _ubicacionLocal = Position(
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
        } else {
          throw Exception('No se pudo encontrar la dirección del local');
        }
      } catch (e) {
        print('Error al geocodificar dirección del local: $e');
        // Usar coordenadas aproximadas de Chiclayo, Lambayeque como fallback
        // Coordenadas aproximadas de La Victoria, Chiclayo
        _ubicacionLocal = Position(
          latitude: -6.7744,  // Chiclayo, Lambayeque
          longitude: -79.8414, // Chiclayo, Lambayeque
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

      // Obtener ubicación actual del cliente
      try {
        _miUbicacion = await _getCurrentLocation();
      } catch (e) {
        print('Error al obtener ubicación actual: $e');
        // Si no se puede obtener la ubicación, usar la del local como fallback
        _miUbicacion = _ubicacionLocal;
      }

      if (_ubicacionLocal != null && _miUbicacion != null) {
        _updateMarkers();
        await _updateRoute();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error al inicializar mapa: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Error al cargar el mapa.\n\nAsegúrate de que:\n1. La API key de Google Maps esté configurada\n2. Tengas conexión a internet\n3. Los permisos de ubicación estén habilitados';
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

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    return position;
  }

  void _updateMarkers() {
    _markers.clear();

    // Marcador de mi ubicación
    if (_miUbicacion != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('mi_ubicacion'),
          position: LatLng(
            _miUbicacion!.latitude,
            _miUbicacion!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Mi Ubicación',
            snippet: 'Tu ubicación actual',
          ),
        ),
      );
    }

    // Marcador del local
    if (_ubicacionLocal != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('local'),
          position: LatLng(
            _ubicacionLocal!.latitude,
            _ubicacionLocal!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Sánchez Pharma',
            snippet: _direccionLocal,
          ),
        ),
      );
    }
  }

  /// Actualiza la ruta usando Google Directions API para mostrar las calles reales
  Future<void> _updateRoute() async {
    _polylines.clear();
    
    if (_miUbicacion != null && _ubicacionLocal != null) {
      print('🗺️ Obteniendo ruta real por las calles...');
      print('   Cliente: (${_miUbicacion!.latitude}, ${_miUbicacion!.longitude})');
      print('   Local: (${_ubicacionLocal!.latitude}, ${_ubicacionLocal!.longitude})');
      
      try {
        // Obtener la ruta real usando Google Directions API
        final routePoints = await DirectionsService.getRoute(
          originLat: _miUbicacion!.latitude,
          originLng: _miUbicacion!.longitude,
          destLat: _ubicacionLocal!.latitude,
          destLng: _ubicacionLocal!.longitude,
        );
        
        // Obtener información adicional de la ruta
        final routeInfo = await DirectionsService.getRouteInfo(
          originLat: _miUbicacion!.latitude,
          originLng: _miUbicacion!.longitude,
          destLat: _ubicacionLocal!.latitude,
          destLng: _ubicacionLocal!.longitude,
        );
        
        if (routeInfo != null) {
          _routeDistance = routeInfo['distance'];
          _routeDuration = routeInfo['duration'];
        }
        
        if (routePoints.isEmpty) {
          print('   ⚠️ No se pudo obtener la ruta. Mostrando línea recta como fallback.');
          // Fallback: mostrar línea recta si no se puede obtener la ruta
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('ruta_fallback'),
              points: [
                LatLng(_miUbicacion!.latitude, _miUbicacion!.longitude),
                LatLng(_ubicacionLocal!.latitude, _ubicacionLocal!.longitude),
              ],
              color: Colors.orange,
              width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ No se pudo obtener la ruta detallada. Verifica tu conexión a Internet.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else if (routePoints.length < 10) {
          print('⚠️ ADVERTENCIA: La ruta tiene solo ${routePoints.length} puntos.');
          // Aún así dibujar la ruta, pero con advertencia
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('ruta_real'),
              points: routePoints,
              color: Colors.orange,
              width: 5,
              jointType: JointType.round,
              endCap: Cap.roundCap,
              startCap: Cap.roundCap,
            ),
          );
        } else {
          // Ruta con suficientes puntos - dibujar normalmente
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('ruta_real'),
              points: routePoints,
              color: Colors.green,
              width: 5,
              jointType: JointType.round,
              endCap: Cap.roundCap,
              startCap: Cap.roundCap,
            ),
          );
          
          print('✅ Ruta dibujada correctamente con ${routePoints.length} puntos');
        }
      } catch (e, stackTrace) {
        print('❌ Error al obtener ruta: $e');
        print('   Stack trace: $stackTrace');
        
        // Fallback: mostrar línea recta si hay error
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('ruta_error'),
            points: [
              LatLng(_miUbicacion!.latitude, _miUbicacion!.longitude),
              LatLng(_ubicacionLocal!.latitude, _ubicacionLocal!.longitude),
            ],
            color: Colors.orange,
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
      
      if (mounted) {
        setState(() {});
      }
    } else {
      print('⚠️ Esperando ubicación del cliente o local para dibujar ruta');
    }
  }

  void _moveCameraToFitBoth() {
    if (_miUbicacion != null && _ubicacionLocal != null && _mapController != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _miUbicacion!.latitude < _ubicacionLocal!.latitude
              ? _miUbicacion!.latitude
              : _ubicacionLocal!.latitude,
          _miUbicacion!.longitude < _ubicacionLocal!.longitude
              ? _miUbicacion!.longitude
              : _ubicacionLocal!.longitude,
        ),
        northeast: LatLng(
          _miUbicacion!.latitude > _ubicacionLocal!.latitude
              ? _miUbicacion!.latitude
              : _ubicacionLocal!.latitude,
          _miUbicacion!.longitude > _ubicacionLocal!.longitude
              ? _miUbicacion!.longitude
              : _ubicacionLocal!.longitude,
        ),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    }
  }

  double _calculateDistance() {
    if (_miUbicacion == null || _ubicacionLocal == null) return 0.0;
    
    return Geolocator.distanceBetween(
      _miUbicacion!.latitude,
      _miUbicacion!.longitude,
      _ubicacionLocal!.latitude,
      _ubicacionLocal!.longitude,
    ) / 1000; // Convertir a kilómetros
  }

  String _calculateEstimatedTime() {
    if (_miUbicacion == null || _ubicacionLocal == null) return 'N/A';
    
    final distanciaKm = _calculateDistance();
    // Velocidad promedio en ciudad: 30 km/h
    const velocidadPromedio = 30.0;
    final tiempoHoras = distanciaKm / velocidadPromedio;
    final tiempoMinutos = (tiempoHoras * 60).round();
    
    if (tiempoMinutos < 1) {
      return 'Menos de 1 min';
    } else if (tiempoMinutos < 60) {
      return '$tiempoMinutos min';
    } else {
      final horas = tiempoMinutos ~/ 60;
      final minutos = tiempoMinutos % 60;
      return '$horas h ${minutos} min';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.numeroPedido != null 
            ? 'Recojo: Pedido #${widget.numeroPedido}' 
            : 'Ubicación del Local'),
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
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeMap,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : (_miUbicacion == null && _ubicacionLocal == null)
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
                            // Esperar un momento antes de mover la cámara
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted && _mapController != null) {
                                _moveCameraToFitBoth();
                              }
                            });
                          },
                          initialCameraPosition: CameraPosition(
                            target: _ubicacionLocal != null
                                ? LatLng(
                                    _ubicacionLocal!.latitude,
                                    _ubicacionLocal!.longitude,
                                  )
                                : const LatLng(-6.7744, -79.8414), // Chiclayo, Lambayeque por defecto
                            zoom: 15,
                          ),
                          markers: _markers,
                          polylines: _polylines,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          mapType: MapType.normal,
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
                                    Icon(Icons.store, color: Colors.green.shade700),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Sánchez Pharma',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _direccionLocal,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                if (_miUbicacion != null && _ubicacionLocal != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.straighten, color: Colors.green.shade700, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        _routeDistance != null 
                                            ? 'Distancia: $_routeDistance'
                                            : 'Distancia: ${_calculateDistance().toStringAsFixed(2)} km',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, color: Colors.green.shade700, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        _routeDuration != null
                                            ? 'Tiempo estimado: $_routeDuration'
                                            : 'Tiempo estimado: ${_calculateEstimatedTime()}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (widget.fechaPedido != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Fecha del pedido: ${widget.fechaPedido!.day}/${widget.fechaPedido!.month}/${widget.fechaPedido!.year}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

