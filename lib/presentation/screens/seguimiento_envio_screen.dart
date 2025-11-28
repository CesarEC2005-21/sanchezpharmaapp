import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../data/models/envio_model.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../data/services/directions_service.dart';
import '../widgets/cliente_bottom_nav.dart';

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
  bool _esRepartidor = false;
  String? _username;
  final ApiService _apiService = ApiService(DioClient.createDio());
  
  // Marcador personalizado para el repartidor
  BitmapDescriptor? _repartidorIcon;
  
  // Información de la ruta
  String? _routeDistance;
  String? _routeDuration;

  // Timer para actualizar ubicación en tiempo real
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _createRepartidorIcon();
    _verificarUsuario();
    _initializeMap();
    _startLocationUpdates();
  }
  
  /// Crea un ícono personalizado para el repartidor (vehículo)
  Future<void> _createRepartidorIcon() async {
    // Crear un marcador personalizado con color azul para el repartidor
    try {
      // Intentar crear un marcador personalizado con un círculo azul
      _repartidorIcon = await _createCustomMarkerIcon();
    } catch (e) {
      print('Error al crear ícono personalizado: $e');
      // Usar marcador por defecto con color azul
      _repartidorIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
  }
  
  /// Crea un marcador personalizado para el repartidor
  Future<BitmapDescriptor> _createCustomMarkerIcon() async {
    // Por ahora, usar un marcador azul para el repartidor
    // En el futuro se puede crear un ícono de vehículo personalizado
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
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
        _destinoPosition = await _getLocationFromAddress(widget.envio.direccionEntrega);
        
        // Si no se pudo geocodificar, lanzar error
        if (_destinoPosition == null) {
          throw Exception('No se pudo obtener la ubicación del destino. Verifica que la dirección de entrega sea válida.');
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
        print('📍 Repartidor inicial: ${widget.envio.latitudRepartidor}, ${widget.envio.longitudRepartidor}');
      } else {
        // Obtener ubicación actual del dispositivo (simulando ubicación del repartidor)
        try {
          _repartidorPosition = await _getCurrentLocation();
          if (_repartidorPosition != null) {
            print('📍 Repartidor (ubicación actual): ${_repartidorPosition!.latitude}, ${_repartidorPosition!.longitude}');
          }
        } catch (e) {
          print('Error al obtener ubicación actual del repartidor: $e');
          // El mapa simplemente mostrará solo el destino hasta que el repartidor tenga ubicación
        }
      }

      // Asegurar que tengamos al menos la ubicación del destino
      if (_destinoPosition == null) {
        throw Exception('No se pudo obtener la ubicación del destino');
      }

      // Si no hay posición del repartidor, el mapa solo mostrará el destino
      // NO agregar el destino a la ruta recorrida
      if (_repartidorPosition == null) {
        print('Advertencia: No hay ubicación del repartidor disponible. El mapa mostrará solo el destino.');
      }

      // Actualizar marcadores y ruta INMEDIATAMENTE
      if (_repartidorPosition != null) {
        await _updateMarkers();
        await _updateRoute(); // Dibujar la ruta automáticamente
      } else if (_destinoPosition != null) {
        await _updateMarkers(); // Al menos mostrar el destino
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

  Future<Position?> _getLocationFromAddress(String address) async {
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
      print('Error al geocodificar dirección "$address": $e');
    }
    
    // Si no se puede geocodificar, retornar null en lugar de una ubicación por defecto
    print('No se pudo obtener coordenadas para la dirección: $address');
    return null;
  }


  Future<void> _updateMarkers() async {
    _markers.clear();

    // Mostrar marcador del REPARTIDOR con ícono personalizado
    if (_repartidorPosition != null) {
      print('📍 Repartidor: ${_repartidorPosition!.latitude}, ${_repartidorPosition!.longitude}');
      
      _markers.add(
        Marker(
          markerId: const MarkerId('repartidor'),
          position: LatLng(
            _repartidorPosition!.latitude,
            _repartidorPosition!.longitude,
          ),
          icon: _repartidorIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: '🚚 Repartidor',
            snippet: widget.envio.conductorRepartidor ?? 'En camino',
          ),
          // Rotar el marcador según la dirección del movimiento (si está disponible)
          rotation: _repartidorPosition!.heading,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    // Mostrar marcador del DESTINO (rojo)
    if (_destinoPosition != null) {
      print('📍 Destino: ${_destinoPosition!.latitude}, ${_destinoPosition!.longitude}');
      
      _markers.add(
        Marker(
          markerId: const MarkerId('destino'),
          position: LatLng(
            _destinoPosition!.latitude,
            _destinoPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '📍 Destino',
            snippet: widget.envio.direccionEntrega,
          ),
        ),
      );
    }
    
    print('✅ Total de marcadores: ${_markers.length}');
    
    if (mounted) {
      setState(() {});
    }
  }

  /// Actualiza la ruta usando Google Directions API para mostrar las calles reales
  Future<void> _updateRoute() async {
    _polylines.clear();
    
    if (_repartidorPosition != null && _destinoPosition != null) {
      print('🗺️ Obteniendo ruta real por las calles...');
      print('   Repartidor: (${_repartidorPosition!.latitude}, ${_repartidorPosition!.longitude})');
      print('   Destino: (${_destinoPosition!.latitude}, ${_destinoPosition!.longitude})');
      
      try {
        // Obtener la ruta real usando Google Directions API
        final routePoints = await DirectionsService.getRoute(
          originLat: _repartidorPosition!.latitude,
          originLng: _repartidorPosition!.longitude,
          destLat: _destinoPosition!.latitude,
          destLng: _destinoPosition!.longitude,
        );
        
        // Obtener información adicional de la ruta
        final routeInfo = await DirectionsService.getRouteInfo(
          originLat: _repartidorPosition!.latitude,
          originLng: _repartidorPosition!.longitude,
          destLat: _destinoPosition!.latitude,
          destLng: _destinoPosition!.longitude,
        );
        
        if (routeInfo != null) {
          _routeDistance = routeInfo['distance'];
          _routeDuration = routeInfo['duration'];
        }
        
        if (routePoints.isEmpty) {
          print('❌ ERROR: No se obtuvieron puntos de ruta.');
          print('   La Directions API no está funcionando correctamente.');
          print('   Por favor, verifica:');
          print('   1. Que la API key tenga habilitada la Directions API en Google Cloud Console');
          print('   2. Que la API key tenga los permisos necesarios');
          print('   3. Que no se haya excedido la cuota de la API');
          
          // Mostrar mensaje al usuario
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ No se pudo obtener la ruta. Verifica la configuración de la API.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          }
        } else if (routePoints.length < 10) {
          print('⚠️ ADVERTENCIA: La ruta tiene solo ${routePoints.length} puntos.');
          print('   Esto puede indicar que la Directions API no está funcionando correctamente.');
          print('   Verifica que la API key tenga habilitada la Directions API en Google Cloud Console.');
          
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
          
          print('⚠️ Ruta dibujada con solo ${routePoints.length} puntos (puede verse como línea recta)');
        } else {
          // Ruta con suficientes puntos - dibujar normalmente
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('ruta_real'),
              points: routePoints,
              color: Colors.blue,
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
        
        // NO dibujar línea recta como fallback - mejor mostrar error
        // para que el usuario sepa que hay un problema
        print('   ⚠️ No se pudo obtener la ruta por las calles. Verifica:');
        print('      1. Que la API key tenga habilitada la Directions API');
        print('      2. Que haya conexión a internet');
        print('      3. Revisa los logs para más detalles');
      }
      
      if (mounted) {
        setState(() {});
      }
    } else {
      print('⚠️ Esperando ubicación del repartidor o destino para dibujar ruta');
    }
  }

  // Calcular distancia en kilómetros entre dos coordenadas (fórmula de Haversine)
  double _calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Radio de la Tierra en kilómetros
    final dLat = _gradosARadianes(lat2 - lat1);
    final dLon = _gradosARadianes(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_gradosARadianes(lat1)) * cos(_gradosARadianes(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _gradosARadianes(double grados) {
    return grados * pi / 180;
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
    // Log inicial
    print('🚀 Iniciando actualizaciones de ubicación...');
    print('   Estado del envío: ${widget.envio.estado}');
    print('   ID del envío: ${widget.envio.id}');
    print('   Es repartidor: $_esRepartidor');
    
    // Actualizar ubicación cada 3 segundos si el envío está en camino (tiempo real)
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      // Verificar que el widget todavía esté montado
      if (!mounted) {
        print('❌ Widget no montado, cancelando timer');
        timer.cancel();
        return;
      }
      
      if (widget.envio.estado == 'en_camino' && widget.envio.id != null) {
        try {
          if (_esRepartidor) {
            // Si es el repartidor, actualizar su ubicación y enviarla al backend
            final nuevaPosicion = await _getCurrentLocation();
            if (nuevaPosicion != null) {
              setState(() {
                _repartidorPosition = nuevaPosicion;
              });
              
              // Actualizar ubicación en el backend
              try {
                print('📤 Repartidor: enviando ubicación al backend...');
                await _apiService.actualizarEnvio(
                  widget.envio.id!,
                  {
                    'latitud_repartidor': nuevaPosicion.latitude,
                    'longitud_repartidor': nuevaPosicion.longitude,
                  },
                );
                print('✅ Ubicación del repartidor actualizada en backend');
              } catch (e) {
                print('❌ Error al actualizar ubicación en backend: $e');
              }
              
              await _updateMarkers();
              await _updateRoute();
              
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
              print('🔄 Cliente: consultando ubicación del repartidor...');
              final response = await _apiService.getEnvio(widget.envio.id!);
              if (response.response.statusCode == 200) {
                final data = response.data;
                if (data['code'] == 1 && data['data'] != null) {
                  final envioActualizado = EnvioModel.fromJson(data['data']);
                  if (envioActualizado.latitudRepartidor != null && 
                      envioActualizado.longitudRepartidor != null) {
                    print('✅ Nueva ubicación del repartidor: ${envioActualizado.latitudRepartidor}, ${envioActualizado.longitudRepartidor}');
                    
                    if (mounted) {
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
                      });
                      
                      await _updateMarkers();
                      await _updateRoute();
                      
                      // Mover cámara para mostrar ambas ubicaciones
                      if (_mapController != null && mounted) {
                        _moveCameraToFitBoth();
                      }
                    }
                  } else {
                    print('⚠️ El repartidor aún no tiene ubicación GPS');
                  }
                }
              }
            } catch (e) {
              print('❌ Error al obtener ubicación del repartidor: $e');
            }
          }
        } catch (e) {
          print('❌ Error general al actualizar ubicación: $e');
        }
      } else if (widget.envio.estado != 'en_camino') {
        print('⏸️ El envío ya no está en camino (estado: ${widget.envio.estado}), pausando actualizaciones');
        // No cancelar el timer, solo saltar esta iteración por si vuelve a "en_camino"
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: const ClienteBottomNav(currentIndex: 2),
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
                          myLocationEnabled: false, // Desactivar porque usamos marcador personalizado
                          myLocationButtonEnabled: false,
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_routeDistance != null && _routeDuration != null)
                                      Row(
                                        children: [
                                          Icon(Icons.route, size: 16, color: Colors.blue.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Ruta: $_routeDistance',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.access_time, size: 16, color: Colors.blue.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Tiempo: $_routeDuration',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                        'Distancia aproximada: ${_calculateDistance().toStringAsFixed(2)} km',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                  ],
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

