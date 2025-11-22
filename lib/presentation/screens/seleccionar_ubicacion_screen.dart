import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class SeleccionarUbicacionScreen extends StatefulWidget {
  final String? direccionInicial;
  final double? latitudInicial;
  final double? longitudInicial;

  const SeleccionarUbicacionScreen({
    super.key,
    this.direccionInicial,
    this.latitudInicial,
    this.longitudInicial,
  });

  @override
  State<SeleccionarUbicacionScreen> createState() => _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState extends State<SeleccionarUbicacionScreen> {
  GoogleMapController? _mapController;
  LatLng? _ubicacionSeleccionada;
  String _direccionCompleta = '';
  bool _isLoading = true;
  bool _isObteniendoDireccion = false;
  Marker? _marker;

  @override
  void initState() {
    super.initState();
    _inicializarMapa();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _inicializarMapa() async {
    try {
      // Si hay coordenadas iniciales, usarlas
      if (widget.latitudInicial != null && widget.longitudInicial != null) {
        _ubicacionSeleccionada = LatLng(widget.latitudInicial!, widget.longitudInicial!);
        await _obtenerDireccionDesdeCoordenadas(_ubicacionSeleccionada!);
      } else {
        // Obtener ubicación actual del usuario
        try {
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
          
          _ubicacionSeleccionada = LatLng(position.latitude, position.longitude);
          await _obtenerDireccionDesdeCoordenadas(_ubicacionSeleccionada!);
        } catch (e) {
          print('Error al obtener ubicación actual: $e');
          // Usar ubicación por defecto (Chiclayo, Lambayeque)
          _ubicacionSeleccionada = const LatLng(-6.7744, -79.8414);
          await _obtenerDireccionDesdeCoordenadas(_ubicacionSeleccionada!);
        }
      }

      _actualizarMarcador();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar mapa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _obtenerDireccionDesdeCoordenadas(LatLng coordenadas) async {
    setState(() {
      _isObteniendoDireccion = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coordenadas.latitude,
        coordenadas.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final direccion = _construirDireccion(placemark);
        setState(() {
          _direccionCompleta = direccion;
          _isObteniendoDireccion = false;
        });
      } else {
        setState(() {
          _direccionCompleta = '${coordenadas.latitude}, ${coordenadas.longitude}';
          _isObteniendoDireccion = false;
        });
      }
    } catch (e) {
      print('Error al obtener dirección: $e');
      setState(() {
        _direccionCompleta = '${coordenadas.latitude}, ${coordenadas.longitude}';
        _isObteniendoDireccion = false;
      });
    }
  }

  String _construirDireccion(Placemark placemark) {
    final partes = <String>[];
    
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      partes.add(placemark.street!);
    }
    if (placemark.subThoroughfare != null && placemark.subThoroughfare!.isNotEmpty) {
      partes.add(placemark.subThoroughfare!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      partes.add(placemark.locality!);
    }
    if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
      partes.add(placemark.subAdministrativeArea!);
    }
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      partes.add(placemark.administrativeArea!);
    }
    
    return partes.join(', ');
  }

  void _actualizarMarcador() {
    if (_ubicacionSeleccionada != null) {
      setState(() {
        _marker = Marker(
          markerId: const MarkerId('ubicacion_seleccionada'),
          position: _ubicacionSeleccionada!,
          draggable: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Ubicación de entrega',
            snippet: _direccionCompleta.isNotEmpty ? _direccionCompleta : 'Arrastra el marcador para ajustar',
          ),
          onDragEnd: (LatLng nuevaPosicion) async {
            setState(() {
              _ubicacionSeleccionada = nuevaPosicion;
            });
            await _obtenerDireccionDesdeCoordenadas(nuevaPosicion);
            _actualizarMarcador();
          },
        );
      });
    }
  }

  void _onMapTap(LatLng coordenadas) async {
    setState(() {
      _ubicacionSeleccionada = coordenadas;
    });
    await _obtenerDireccionDesdeCoordenadas(coordenadas);
    _actualizarMarcador();
  }

  void _confirmarUbicacion() {
    if (_ubicacionSeleccionada != null) {
      Navigator.of(context).pop({
        'latitud': _ubicacionSeleccionada!.latitude,
        'longitud': _ubicacionSeleccionada!.longitude,
        'direccion': _direccionCompleta,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    // Mover cámara a la ubicación seleccionada
                    if (_ubicacionSeleccionada != null) {
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(_ubicacionSeleccionada!, 16),
                      );
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: _ubicacionSeleccionada ?? const LatLng(-6.7744, -79.8414),
                    zoom: 16,
                  ),
                  markers: _marker != null ? {_marker!} : {},
                  onTap: _onMapTap,
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
                            Icon(Icons.location_on, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _isObteniendoDireccion
                                  ? const Row(
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        SizedBox(width: 8),
                                        Text('Obteniendo dirección...'),
                                      ],
                                    )
                                  : Text(
                                      _direccionCompleta.isNotEmpty
                                          ? _direccionCompleta
                                          : 'Toca el mapa para seleccionar ubicación',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Toca el mapa o arrastra el marcador para seleccionar tu ubicación exacta',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _ubicacionSeleccionada != null ? _confirmarUbicacion : null,
                            icon: const Icon(Icons.check),
                            label: const Text('Confirmar Ubicación'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
}

