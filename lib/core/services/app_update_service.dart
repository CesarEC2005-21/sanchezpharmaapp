import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../core/constants/api_constants.dart';
import '../../data/api/dio_client.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  final Dio _dio = DioClient.createDio();
  bool _hasUpdate = false;
  Map<String, dynamic>? _updateInfo;

  /// Verifica si hay actualizaciones disponibles
  Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.versionCheck}',
        queryParameters: {'version': currentVersion},
      );

      if (response.statusCode == 200 && response.data['code'] == 1) {
        final data = response.data['data'];
        _hasUpdate = data['needs_update'] ?? false;
        _updateInfo = data;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error al verificar actualización: $e');
      return null;
    }
  }

  /// Obtiene información de actualización (sin hacer nueva petición si ya se verificó)
  Map<String, dynamic>? getUpdateInfo() => _updateInfo;

  /// Verifica si hay actualización disponible
  bool get hasUpdate => _hasUpdate;

  /// Descarga e instala el APK
  Future<bool> downloadAndInstallApk({
    required String apkUrl,
    required Function(int received, int total) onProgress,
    required Function(String error) onError,
  }) async {
    try {
      // Solicitar permisos de almacenamiento e instalación
      if (Platform.isAndroid) {
        // Permiso de almacenamiento
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
          if (!storageStatus.isGranted) {
            onError('Se necesita permiso de almacenamiento para descargar la actualización');
            return false;
          }
        }

        // Permiso de instalación de apps desde fuentes desconocidas
        // Este permiso se solicita automáticamente cuando se intenta instalar
      }

      // Obtener directorio temporal
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/app_update.apk';

      // Descargar APK
      await _dio.download(
        apkUrl,
        filePath,
        onReceiveProgress: (received, total) {
          onProgress(received, total);
        },
      );

      // Abrir el instalador de Android
      if (Platform.isAndroid) {
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          onError('Error al abrir el instalador: ${result.message}');
          return false;
        }
        return true;
      }

      return false;
    } catch (e) {
      onError('Error al descargar la actualización: $e');
      return false;
    }
  }

  /// Muestra diálogo de actualización
  static Future<void> showUpdateDialog(
    BuildContext context, {
    required Map<String, dynamic> updateInfo,
    required Function() onDownload,
  }) {
    final forceUpdate = updateInfo['force_update'] ?? false;
    final latestVersion = updateInfo['latest_version'] ?? 'N/A';
    final currentVersion = updateInfo['client_version'] ?? 'N/A';
    final updateMessage = updateInfo['update_message'] ?? 'Nueva versión disponible';
    final releaseNotes = updateInfo['release_notes'] ?? '';
    final apkSize = updateInfo['apk_size'] ?? 0;
    final sizeInMB = (apkSize / (1024 * 1024)).toStringAsFixed(2);

    return showDialog(
      context: context,
      barrierDismissible: !forceUpdate, // No se puede cerrar si es forzada
      builder: (context) => PopScope(
        canPop: !forceUpdate,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.system_update,
                color: Colors.blue.shade700,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Actualización Disponible',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  updateMessage,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Versión actual: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(currentVersion),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Nueva versión: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      latestVersion,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Tamaño: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('$sizeInMB MB'),
                  ],
                ),
                if (releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Notas de la versión:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      releaseNotes,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                if (forceUpdate) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Esta actualización es obligatoria para continuar usando la aplicación.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Más tarde'),
              ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onDownload();
              },
              icon: const Icon(Icons.download),
              label: const Text('Descargar e Instalar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra diálogo de progreso de descarga
  static Future<void> showDownloadProgressDialog(
    BuildContext context, {
    required Function() onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Descargando actualización...'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Por favor espera mientras se descarga la actualización.'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCancel();
                  },
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

