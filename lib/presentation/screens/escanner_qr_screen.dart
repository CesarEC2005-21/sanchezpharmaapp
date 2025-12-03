import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/utils/error_message_helper.dart';
import '../../core/constants/app_colors.dart';

class EscannerQrScreen extends StatefulWidget {
  final String titulo;
  final String? mensajeAyuda;

  const EscannerQrScreen({
    super.key,
    required this.titulo,
    this.mensajeAyuda,
  });

  @override
  State<EscannerQrScreen> createState() => _EscannerQrScreenState();
}

class _EscannerQrScreenState extends State<EscannerQrScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcesando = false;
  String? _ultimoCodigoEscaneado;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _procesarCodigoQr(String codigoQr) async {
    // Evitar procesar el mismo código múltiples veces
    if (_isProcesando || _ultimoCodigoEscaneado == codigoQr) {
      return;
    }

    setState(() {
      _isProcesando = true;
      _ultimoCodigoEscaneado = codigoQr;
    });

    try {
      final response = await _apiService.validarQrEntrega({
        'codigo_qr': codigoQr,
      });

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          if (mounted) {
            // Detener el escáner temporalmente
            await _controller.stop();
            
            // Mostrar diálogo de éxito
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                    SizedBox(width: 10),
                    Text('Pedido Entregado'),
                  ],
                ),
                content: Text(
                  data['message'] ?? 'El pedido ha sido marcado como entregado correctamente',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Cerrar diálogo
                      Navigator.of(context).pop(true); // Volver a la pantalla anterior con éxito
                    },
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Error al procesar el código QR'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
            // Reiniciar el escáner después de un error
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) {
              await _controller.start();
            }
          }
        }
      } else {
        if (mounted) {
          String mensajeError = 'Error al conectar con el servidor';
          Color colorError = Colors.red;
          
          final statusCode = response.response.statusCode;
          
          // Intentar obtener el mensaje de error del servidor si está disponible
          try {
            final errorData = response.data;
            if (errorData is Map && errorData['message'] != null) {
              String serverMessage = errorData['message'].toString();
              
              // Limpiar mensajes de error técnicos y hacerlos más amigables
              if (serverMessage.contains('Unknown column')) {
                mensajeError = 'Error en la configuración del servidor. Por favor, contacta al administrador del sistema.';
              } else if (serverMessage.contains('OperationalError')) {
                mensajeError = 'Error en la base de datos. Por favor, contacta al administrador del sistema.';
              } else {
                mensajeError = serverMessage;
              }
            }
          } catch (e) {
            // Si no se puede obtener el mensaje, usar el mensaje por defecto
          }
          
          // Manejar diferentes códigos de estado
          if (statusCode == 500) {
            if (mensajeError == 'Error al conectar con el servidor' || 
                mensajeError.contains('Error del servidor') == false) {
              mensajeError = 'Error del servidor al procesar el pedido de envío a domicilio. Por favor, verifica que el envío esté correctamente configurado o contacta al administrador.';
            }
            colorError = Colors.orange;
          } else if (statusCode == 401) {
            mensajeError = 'Sesión expirada. Por favor, inicia sesión nuevamente.';
            colorError = Colors.orange;
          } else if (statusCode == 403) {
            mensajeError = 'No tienes permisos para realizar esta acción.';
            colorError = Colors.orange;
          } else if (statusCode == 404) {
            mensajeError = 'El código QR no es válido o el pedido no existe.';
            colorError = Colors.orange;
          } else if (statusCode != null && statusCode >= 500) {
            mensajeError = 'Error del servidor. Por favor, intenta nuevamente más tarde.';
            colorError = Colors.orange;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensajeError),
              backgroundColor: colorError,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Cerrar',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            await _controller.start();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Usar ErrorMessageHelper para obtener mensaje amigable
        // No mostrar si es error 401 (el interceptor ya lo maneja)
        final errorString = e.toString().toLowerCase();
        if (!errorString.contains('401') && 
            !errorString.contains('sesión expirada') &&
            !errorString.contains('unauthorized')) {
          ErrorMessageHelper.showErrorSnackBar(context, e);
        }
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          await _controller.start();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcesando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Encender/Apagar linterna',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Cámara con escáner QR
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _procesarCodigoQr(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          
          // Overlay con guía de escaneo
          Positioned.fill(
            child: CustomPaint(
              painter: QrScannerOverlay(),
            ),
          ),
          
          // Mensaje de ayuda
          if (widget.mensajeAyuda != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.mensajeAyuda!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          
          // Indicador de procesamiento
          if (_isProcesando)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Procesando...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Clase para dibujar el overlay del escáner
class QrScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Dibujar fondo oscuro
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Calcular área de escaneo (cuadrado en el centro)
    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final scanArea = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Limpiar el área de escaneo
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear;
    canvas.drawRect(scanArea, clearPaint);

    // Dibujar bordes del área de escaneo
    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Esquinas del rectángulo
    final cornerLength = 30.0;
    
    // Esquina superior izquierda
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerLength),
      borderPaint,
    );

    // Esquina superior derecha
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize - cornerLength, top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize, top + cornerLength),
      borderPaint,
    );

    // Esquina inferior izquierda
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left, top + scanAreaSize - cornerLength),
      borderPaint,
    );

    // Esquina inferior derecha
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

