import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/constants/role_constants.dart';
import '../../core/constants/api_constants.dart';
import 'login_screen.dart';

class BackupsScreen extends StatefulWidget {
  const BackupsScreen({super.key});

  @override
  State<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends State<BackupsScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<dynamic> _backups = [];
  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _verificarPermisos();
    _cargarHistorial();
  }

  Future<void> _verificarPermisos() async {
    final rolId = await SharedPrefsHelper.getRolId();
    final userType = await SharedPrefsHelper.getUserType();
    
    // Verificar que sea usuario interno (no cliente)
    if (userType == 'cliente') {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso denegado. Solo usuarios internos pueden acceder a esta sección.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    // Verificar que tenga acceso a backups (solo Ingeniero)
    if (!RoleConstants.tieneAccesoABackups(rolId)) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso denegado. Solo el rol Ingeniero puede acceder a esta sección.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getBackupsHistorial();
      
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          setState(() {
            _backups = data['data'] ?? [];
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Error al cargar historial'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } else if (response.response.statusCode == 401) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No autorizado. Por favor, inicia sesión nuevamente.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else if (response.response.statusCode == 403) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Acceso denegado. Solo el rol Ingeniero puede acceder.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Error al cargar historial';
        if (e.toString().contains('401')) {
          errorMsg = 'No autorizado. Por favor, inicia sesión nuevamente.';
        } else if (e.toString().contains('403')) {
          errorMsg = 'Acceso denegado. Solo el rol Ingeniero puede acceder a esta sección.';
        } else {
          errorMsg = 'Error al cargar historial: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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

  Future<void> _generarBackup(String tipo) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      HttpResponse<dynamic> response;
      String mensaje;

      switch (tipo) {
        case 'bd':
          response = await _apiService.generarBackupBd();
          mensaje = 'Backup de base de datos';
          break;
        case 'archivos':
          response = await _apiService.generarBackupArchivos();
          mensaje = 'Backup de archivos';
          break;
        case 'completo':
          response = await _apiService.generarBackupCompleto();
          mensaje = 'Backup completo';
          break;
        default:
          return;
      }

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$mensaje generado correctamente'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          // Recargar historial
          await _cargarHistorial();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Error al generar backup'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else if (response.response.statusCode == 401) {
        // Token inválido o expirado
        final data = response.data;
        final message = data['message']?.toString() ?? '';
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.contains('no autenticado') 
                  ? 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.'
                  : 'No autorizado. Por favor, inicia sesión nuevamente.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        
        // Limpiar token y redirigir al login
        await SharedPrefsHelper.clearAuthData();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
        }
      } else if (response.response.statusCode == 403) {
        if (mounted) {
          final data = response.data;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Acceso denegado. Solo el rol Ingeniero puede generar backups.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Error al generar backup: ${e.toString()}';
        
        // Detectar errores 401 en el mensaje de error
        if (e.toString().contains('401') || e.toString().contains('no autenticado')) {
          errorMsg = 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
          await SharedPrefsHelper.clearAuthData();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
              (route) => false,
            );
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _descargarBackup(int backupId, String nombreArchivo) async {
    try {
      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Descargando backup...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      final dio = DioClient.createDio();
      final token = await SharedPrefsHelper.getToken();
      
      if (token != null) {
        // Usar formato Bearer para consistencia con el resto de la app
        dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.descargarBackup}/$backupId',
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        // Obtener el directorio de descargas
        Directory? directory;
        
        try {
          if (Platform.isAndroid) {
            // En Android, usar el directorio externo de la app (compatible con Scoped Storage)
            directory = await getExternalStorageDirectory();
            if (directory != null) {
              // Crear subdirectorio "Backups" dentro del directorio de la app
              directory = Directory('${directory.path}/Backups');
            } else {
              // Fallback: usar directorio de documentos de la app
              directory = await getApplicationDocumentsDirectory();
              if (directory != null) {
                directory = Directory('${directory.path}/Backups');
              }
            }
          } else if (Platform.isIOS) {
            // En iOS, usar el directorio de documentos de la app
            directory = await getApplicationDocumentsDirectory();
          } else if (Platform.isWindows) {
            // En Windows, usar el directorio de descargas del usuario
            final userProfile = Platform.environment['USERPROFILE'];
            if (userProfile != null) {
              directory = Directory('$userProfile\\Downloads');
            } else {
              directory = await getApplicationDocumentsDirectory();
            }
          } else {
            // Para otras plataformas, usar el directorio de documentos
            directory = await getApplicationDocumentsDirectory();
          }

          if (directory == null) {
            throw Exception('No se pudo obtener el directorio de descargas');
          }

          // Crear el directorio si no existe
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }

          // Crear el archivo
          final file = File('${directory.path}/$nombreArchivo');
          
          // Escribir los bytes al archivo
          await file.writeAsBytes(response.data);

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Backup descargado exitosamente',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Guardado en: ${file.path}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Tamaño: ${_formatearTamano(response.data.length)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } catch (fileError) {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al guardar archivo: ${fileError.toString()}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al descargar backup: ${response.statusMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar backup: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _formatearTamano(int? bytes) {
    if (bytes == null) return 'N/A';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Color _getColorTipo(String? tipo) {
    switch (tipo) {
      case 'bd':
        return Colors.blue;
      case 'archivos':
        return Colors.orange;
      case 'completo':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconoTipo(String? tipo) {
    switch (tipo) {
      case 'bd':
        return Icons.storage;
      case 'archivos':
        return Icons.folder;
      case 'completo':
        return Icons.backup;
      default:
        return Icons.file_copy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backups'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Botones de generación
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Generar Backup',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : () => _generarBackup('bd'),
                        icon: const Icon(Icons.storage),
                        label: const Text('BD'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : () => _generarBackup('archivos'),
                        icon: const Icon(Icons.folder),
                        label: const Text('Archivos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : () => _generarBackup('completo'),
                        icon: const Icon(Icons.backup),
                        label: const Text('Completo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isGenerating)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
          
          // Historial
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _backups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.backup_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay backups generados',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _backups.length,
                        itemBuilder: (context, index) {
                          final backup = _backups[index];
                          final tipo = backup['tipo'] ?? 'desconocido';
                          final nombreArchivo = backup['nombre_archivo'] ?? 'N/A';
                          final fecha = backup['fecha_creacion'] ?? 'N/A';
                          final tamano = backup['tamano_bytes'];
                          final estado = backup['estado'] ?? 'desconocido';
                          final backupId = backup['id'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getColorTipo(tipo),
                                child: Icon(
                                  _getIconoTipo(tipo),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                nombreArchivo,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          tipo.toUpperCase(),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        backgroundColor: _getColorTipo(tipo).withOpacity(0.2),
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          estado,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        backgroundColor: estado == 'completado'
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.red.withOpacity(0.2),
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Fecha: $fecha'),
                                  Text('Tamano: ${_formatearTamano(tamano)}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: estado == 'completado'
                                    ? () => _descargarBackup(backupId, nombreArchivo)
                                    : null,
                                tooltip: 'Descargar backup',
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _cargarHistorial,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

