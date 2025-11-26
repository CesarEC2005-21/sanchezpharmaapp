import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/direccion_model.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import 'agregar_direccion_screen.dart';

class MisDireccionesScreen extends StatefulWidget {
  const MisDireccionesScreen({super.key});

  @override
  State<MisDireccionesScreen> createState() => _MisDireccionesScreenState();
}

class _MisDireccionesScreenState extends State<MisDireccionesScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<DireccionModel> _direcciones = [];
  bool _isLoading = true;
  int? _clienteId;

  @override
  void initState() {
    super.initState();
    _cargarDirecciones();
  }

  Future<void> _cargarDirecciones() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _clienteId = prefs.getInt('cliente_id') ?? prefs.getInt('user_id');

      if (_clienteId == null) {
        print('❌ No se encontró el ID del cliente');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('🔄 Cargando direcciones desde API para cliente: $_clienteId');

      // Cargar direcciones desde la API
      final response = await _apiService.getDireccionesCliente(_clienteId!);

      if (response.response.statusCode == 200) {
        final data = response.data;
        
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> direccionesJson = data['data'];
          final List<DireccionModel> direcciones = direccionesJson
              .map((json) => DireccionModel.fromJson(json as Map<String, dynamic>))
              .toList();
          
          setState(() {
            _direcciones = direcciones;
          });
          
          print('✅ Direcciones cargadas desde API: ${_direcciones.length}');
        } else {
          print('⚠️ Respuesta sin direcciones o código != 1');
        }
      } else {
        print('❌ Error HTTP: ${response.response.statusCode}');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar direcciones: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _eliminarDireccion(int index) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Está seguro de eliminar esta dirección?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      final direccion = _direcciones[index];
      if (direccion.id == null) return;

      try {
        print('🗑️ Eliminando dirección ID: ${direccion.id}');
        final response = await _apiService.eliminarDireccion(direccion.id!);

        if (response.response.statusCode == 200) {
          final data = response.data;
          if (data['code'] == 1) {
            setState(() {
              _direcciones.removeAt(index);
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dirección eliminada correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(data['message'] ?? 'Error al eliminar'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } catch (e) {
        print('❌ Error al eliminar dirección: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _marcarComoPrincipal(int index) async {
    final direccion = _direcciones[index];
    if (direccion.id == null) return;

    try {
      print('⭐ Marcando dirección ID: ${direccion.id} como principal');
      final response = await _apiService.marcarDireccionPrincipal(direccion.id!);

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          setState(() {
            for (int i = 0; i < _direcciones.length; i++) {
              _direcciones[i] = _direcciones[i].copyWith(esPrincipal: i == index);
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dirección principal actualizada'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Error al actualizar'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error al marcar como principal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _agregarDireccion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AgregarDireccionScreen(),
      ),
    ).then((resultado) async {
      if (resultado != null && resultado is DireccionModel) {
        try {
          print('➕ Guardando nueva dirección en API...');
          
          final data = {
            'cliente_id': _clienteId,
            'titulo': resultado.titulo,
            'direccion': resultado.direccion,
            'referencia': resultado.referencia,
            'latitud': resultado.latitud,
            'longitud': resultado.longitud,
            'es_principal': resultado.esPrincipal,
          };

          final response = await _apiService.registrarDireccion(data);

          if (response.response.statusCode == 200) {
            final responseData = response.data;
            if (responseData['code'] == 1) {
              // Recargar direcciones desde la API
              await _cargarDirecciones();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dirección agregada exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(responseData['message'] ?? 'Error al guardar'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        } catch (e) {
          print('❌ Error al guardar dirección: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis direcciones'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _direcciones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes direcciones guardadas',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega tu primera dirección de entrega',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _agregarDireccion,
                        icon: const Icon(Icons.add_location_alt),
                        label: const Text('Agregar dirección'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarDirecciones,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _direcciones.length,
                    itemBuilder: (context, index) {
                      final direccion = _direcciones[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: direccion.esPrincipal
                              ? BorderSide(color: Colors.green.shade700, width: 2)
                              : BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    direccion.esPrincipal
                                        ? Icons.location_on
                                        : Icons.location_on_outlined,
                                    color: direccion.esPrincipal
                                        ? Colors.green.shade700
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      direccion.titulo,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: direccion.esPrincipal
                                            ? Colors.green.shade700
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (direccion.esPrincipal)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Principal',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade900,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                direccion.direccion,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              if (direccion.referencia != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Ref: ${direccion.referencia}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (!direccion.esPrincipal)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _marcarComoPrincipal(index),
                                        icon: const Icon(Icons.star_border, size: 18),
                                        label: const Text('Principal'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  if (!direccion.esPrincipal)
                                    const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _eliminarDireccion(index),
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      label: const Text('Eliminar'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _direcciones.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _agregarDireccion,
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Nueva dirección'),
            )
          : null,
    );
  }
}

