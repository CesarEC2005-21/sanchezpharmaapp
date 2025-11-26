import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/direccion_model.dart';

class AgregarDireccionScreen extends StatefulWidget {
  final DireccionModel? direccion;

  const AgregarDireccionScreen({super.key, this.direccion});

  @override
  State<AgregarDireccionScreen> createState() => _AgregarDireccionScreenState();
}

class _AgregarDireccionScreenState extends State<AgregarDireccionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng _selectedPosition = const LatLng(-6.777, -79.841); // Chiclayo por defecto
  bool _isLoading = false;
  bool _esPrincipal = false;
  int? _clienteId;

  @override
  void initState() {
    super.initState();
    _cargarDatosCliente();
    _obtenerUbicacionActual();

    if (widget.direccion != null) {
      _tituloController.text = widget.direccion!.titulo;
      _direccionController.text = widget.direccion!.direccion;
      _referenciaController.text = widget.direccion!.referencia ?? '';
      _selectedPosition = LatLng(widget.direccion!.latitud, widget.direccion!.longitud);
      _esPrincipal = widget.direccion!.esPrincipal;
    }
  }

  Future<void> _cargarDatosCliente() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _clienteId = prefs.getInt('cliente_id') ?? prefs.getInt('user_id');
    });
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Servicios de ubicación deshabilitados');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permisos de ubicación denegados');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Permisos de ubicación denegados permanentemente');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedPosition = LatLng(position.latitude, position.longitude);
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedPosition, 15),
        );
      }

      // Obtener dirección automáticamente
      await _obtenerDireccionDesdeCoordenadas();
    } catch (e) {
      print('Error al obtener ubicación: $e');
    }
  }

  Future<void> _obtenerDireccionDesdeCoordenadas() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedPosition.latitude,
        _selectedPosition.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String address = '';

        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          address += ' ${place.subThoroughfare!}';
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.locality!;
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.administrativeArea!;
        }

        setState(() {
          _direccionController.text = address.isNotEmpty
              ? address
              : '${_selectedPosition.latitude.toStringAsFixed(6)}, ${_selectedPosition.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      print('Error al obtener dirección: $e');
      setState(() {
        _direccionController.text = '${_selectedPosition.latitude.toStringAsFixed(6)}, ${_selectedPosition.longitude.toStringAsFixed(6)}';
      });
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
    _obtenerDireccionDesdeCoordenadas();
  }

  Future<void> _guardarDireccion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo identificar el cliente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final direccion = DireccionModel(
        id: widget.direccion?.id,
        clienteId: _clienteId!,
        titulo: _tituloController.text,
        direccion: _direccionController.text,
        referencia: _referenciaController.text.isNotEmpty ? _referenciaController.text : null,
        latitud: _selectedPosition.latitude,
        longitud: _selectedPosition.longitude,
        esPrincipal: _esPrincipal,
        fechaCreacion: widget.direccion?.fechaCreacion ?? DateTime.now(),
      );

      // Devolver la dirección al screen anterior
      if (mounted) {
        Navigator.pop(context, direccion);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _direccionController.dispose();
    _referenciaController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.direccion != null ? 'Editar dirección' : 'Nueva dirección'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Mapa
          SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedPosition,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: _onMapTapped,
              markers: {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: _selectedPosition,
                  draggable: true,
                  onDragEnd: (newPosition) {
                    setState(() {
                      _selectedPosition = newPosition;
                    });
                    _obtenerDireccionDesdeCoordenadas();
                  },
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
            ),
          ),

          // Formulario
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Instrucción
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Toca el mapa o arrastra el marcador para seleccionar tu ubicación exacta',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Título
                  TextFormField(
                    controller: _tituloController,
                    decoration: InputDecoration(
                      labelText: 'Título *',
                      hintText: 'Ej: Casa, Trabajo, etc.',
                      prefixIcon: const Icon(Icons.label_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El título es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dirección
                  TextFormField(
                    controller: _direccionController,
                    decoration: InputDecoration(
                      labelText: 'Dirección *',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La dirección es requerida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Referencia
                  TextFormField(
                    controller: _referenciaController,
                    decoration: InputDecoration(
                      labelText: 'Referencia (opcional)',
                      hintText: 'Ej: Puerta verde, cerca al parque',
                      prefixIcon: const Icon(Icons.home_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Marcar como principal
                  SwitchListTile(
                    title: const Text('Dirección principal'),
                    subtitle: const Text('Usar como dirección predeterminada para entregas'),
                    value: _esPrincipal,
                    onChanged: (value) {
                      setState(() {
                        _esPrincipal = value;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                  const SizedBox(height: 24),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _guardarDireccion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Guardar dirección'),
                        ),
                      ),
                    ],
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

