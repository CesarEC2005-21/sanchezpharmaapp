import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/direccion_model.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/utils/responsive_helper.dart';
import '../widgets/cliente_bottom_nav.dart';
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
      bottomNavigationBar: const ClienteBottomNav(currentIndex: 2),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _direcciones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: ResponsiveHelper.isSmallScreen(context) ? 60 : 80,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: ResponsiveHelper.spacing(context)),
                      Text(
                        'No tienes direcciones guardadas',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.subtitleFontSize(context) + 2,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: ResponsiveHelper.spacing(context) / 2),
                      Text(
                        'Agrega tu primera dirección de entrega',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.bodyFontSize(context),
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: ResponsiveHelper.spacing(context) * 1.5),
                      ElevatedButton.icon(
                        onPressed: _agregarDireccion,
                        icon: Icon(Icons.add_location_alt, size: ResponsiveHelper.iconSize(context)),
                        label: Text(
                          'Agregar dirección',
                          style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.spacing(context) * 1.5,
                            vertical: ResponsiveHelper.spacing(context) / 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarDirecciones,
                  child: ListView.builder(
                    padding: ResponsiveHelper.formPadding(context),
                    itemCount: _direcciones.length,
                    itemBuilder: (context, index) {
                      final direccion = _direcciones[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: ResponsiveHelper.spacing(context) / 2),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: direccion.esPrincipal
                              ? BorderSide(color: Colors.green.shade700, width: 2)
                              : BorderSide.none,
                        ),
                        child: Padding(
                          padding: ResponsiveHelper.formPadding(context),
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
                                    size: ResponsiveHelper.iconSize(context),
                                  ),
                                  SizedBox(width: ResponsiveHelper.spacing(context) / 2),
                                  Expanded(
                                    child: Text(
                                      direccion.titulo,
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.subtitleFontSize(context) + 2,
                                        fontWeight: FontWeight.bold,
                                        color: direccion.esPrincipal
                                            ? Colors.green.shade700
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (direccion.esPrincipal)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: ResponsiveHelper.spacing(context) / 2,
                                        vertical: ResponsiveHelper.spacing(context) / 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Principal',
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.bodyFontSize(context) - 2,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade900,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: ResponsiveHelper.spacing(context) / 2),
                              Text(
                                direccion.direccion,
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.bodyFontSize(context),
                                  color: Colors.black87,
                                ),
                              ),
                              if (direccion.referencia != null) ...[
                                SizedBox(height: ResponsiveHelper.spacing(context) / 4),
                                Text(
                                  'Ref: ${direccion.referencia}',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.bodyFontSize(context) - 1,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              SizedBox(height: ResponsiveHelper.spacing(context) / 2),
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
                                    SizedBox(width: ResponsiveHelper.spacing(context) / 2),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _eliminarDireccion(index),
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: ResponsiveHelper.iconSize(context) - 6,
                                      ),
                                      label: Text(
                                        'Eliminar',
                                        style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                                      ),
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

