import 'package:flutter/material.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/banner_model.dart';

class BannersScreen extends StatefulWidget {
  const BannersScreen({super.key});

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<BannerModel> _banners = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarBanners();
  }

  Future<void> _cargarBanners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getBanners();

      if (response.response.statusCode == 200) {
        final data = response.data;

        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> bannersJson = data['data'];
          setState(() {
            _banners = bannersJson
                .map((json) => BannerModel.fromJson(json))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error al cargar banners';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error de conexión';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBanner(int bannerId) async {
    try {
      final response = await _apiService.toggleBanner(bannerId);

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              backgroundColor: Colors.green,
            ),
          );
          _cargarBanners();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarBanner(int bannerId) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Está seguro de eliminar este banner?'),
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

    if (confirmado != true) return;

    try {
      final response = await _apiService.eliminarBanner(bannerId);

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Banner eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarBanners();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarFormularioBanner({BannerModel? banner}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioBannerScreen(banner: banner),
      ),
    ).then((_) => _cargarBanners());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Banners'),
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
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarBanners,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _banners.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay banners registrados',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _mostrarFormularioBanner(),
                            icon: const Icon(Icons.add),
                            label: const Text('Crear Primer Banner'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarBanners,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _banners.length,
                        itemBuilder: (context, index) {
                          final banner = _banners[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagen del banner
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                  child: Image.network(
                                    banner.imagenUrl,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 150,
                                        color: Colors.grey.shade300,
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 150,
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Información
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              banner.titulo,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Switch(
                                            value: banner.activo,
                                            onChanged: (value) {
                                              if (banner.id != null) {
                                                _toggleBanner(banner.id!);
                                              }
                                            },
                                            activeColor: Colors.green,
                                          ),
                                        ],
                                      ),
                                      if (banner.descripcion != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          banner.descripcion!,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.sort,
                                              size: 16,
                                              color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Orden: ${banner.orden}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: banner.activo
                                                  ? Colors.green.shade100
                                                  : Colors.red.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              banner.activo
                                                  ? 'Activo'
                                                  : 'Inactivo',
                                              style: TextStyle(
                                                color: banner.activo
                                                    ? Colors.green.shade900
                                                    : Colors.red.shade900,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _mostrarFormularioBanner(
                                                      banner: banner),
                                              icon: const Icon(Icons.edit,
                                                  size: 18),
                                              label: const Text('Editar'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    Colors.green.shade700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                if (banner.id != null) {
                                                  _eliminarBanner(banner.id!);
                                                }
                                              },
                                              icon: const Icon(Icons.delete,
                                                  size: 18),
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
                              ],
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioBanner(),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Banner'),
      ),
    );
  }
}

// ============================================================================
// FORMULARIO DE BANNER
// ============================================================================

class FormularioBannerScreen extends StatefulWidget {
  final BannerModel? banner;

  const FormularioBannerScreen({super.key, this.banner});

  @override
  State<FormularioBannerScreen> createState() => _FormularioBannerScreenState();
}

class _FormularioBannerScreenState extends State<FormularioBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService(DioClient.createDio());

  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _imagenUrlController;
  late TextEditingController _enlaceController;
  late TextEditingController _ordenController;
  bool _activo = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tituloController =
        TextEditingController(text: widget.banner?.titulo ?? '');
    _descripcionController =
        TextEditingController(text: widget.banner?.descripcion ?? '');
    _imagenUrlController =
        TextEditingController(text: widget.banner?.imagenUrl ?? '');
    _enlaceController =
        TextEditingController(text: widget.banner?.enlace ?? '');
    _ordenController =
        TextEditingController(text: widget.banner?.orden.toString() ?? '0');
    _activo = widget.banner?.activo ?? true;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _imagenUrlController.dispose();
    _enlaceController.dispose();
    _ordenController.dispose();
    super.dispose();
  }

  Future<void> _guardarBanner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'titulo': _tituloController.text,
        'descripcion': _descripcionController.text.isNotEmpty
            ? _descripcionController.text
            : null,
        'imagen_url': _imagenUrlController.text,
        'enlace': _enlaceController.text.isNotEmpty ? _enlaceController.text : null,
        'orden': int.tryParse(_ordenController.text) ?? 0,
        'activo': _activo,
      };

      if (widget.banner != null) {
        data['id'] = widget.banner!.id;
      }

      final response = widget.banner != null
          ? await _apiService.editarBanner(data)
          : await _apiService.registrarBanner(data);

      if (response.response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['code'] == 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message']),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message']),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.banner != null ? 'Editar Banner' : 'Nuevo Banner'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vista previa de imagen
            if (_imagenUrlController.text.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imagenUrlController.text,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                size: 50, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'URL de imagen no válida',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),

            // Título
            TextFormField(
              controller: _tituloController,
              decoration: InputDecoration(
                labelText: 'Título *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El título es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descripcionController,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // URL de imagen
            TextFormField(
              controller: _imagenUrlController,
              decoration: InputDecoration(
                labelText: 'URL de Imagen *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.image),
                helperText: 'Pega aquí la URL de la imagen del banner',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La URL de la imagen es requerida';
                }
                if (!value.startsWith('http')) {
                  return 'Debe ser una URL válida (http:// o https://)';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {}); // Actualizar vista previa
              },
            ),
            const SizedBox(height: 16),

            // Enlace
            TextFormField(
              controller: _enlaceController,
              decoration: InputDecoration(
                labelText: 'Enlace (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.link),
                helperText: 'URL a la que redirige al hacer clic',
              ),
            ),
            const SizedBox(height: 16),

            // Orden
            TextFormField(
              controller: _ordenController,
              decoration: InputDecoration(
                labelText: 'Orden de Aparición',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.sort),
                helperText: 'Los banners se ordenan de menor a mayor',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (int.tryParse(value) == null) {
                    return 'Debe ser un número';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Estado activo
            SwitchListTile(
              title: const Text('Banner Activo'),
              subtitle: const Text(
                  'Los banners inactivos no se mostrarán en la app'),
              value: _activo,
              onChanged: (value) {
                setState(() {
                  _activo = value;
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
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _guardarBanner,
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(widget.banner != null ? 'Guardar' : 'Crear'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Instrucciones
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Cómo subir imágenes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Sube tu imagen a un servicio como:\n'
                      '   • ImgBB (imgbb.com)\n'
                      '   • Imgur (imgur.com)\n'
                      '   • CloudImage\n\n'
                      '2. Copia la URL directa de la imagen\n\n'
                      '3. Pégala en el campo "URL de Imagen"\n\n'
                      '4. Verás una vista previa arriba',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

