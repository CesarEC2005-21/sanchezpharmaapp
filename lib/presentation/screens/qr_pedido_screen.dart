import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/constants/app_colors.dart';

class QrPedidoScreen extends StatefulWidget {
  final int ventaId;
  final String? numeroVenta;
  final String tipoVenta;

  const QrPedidoScreen({
    super.key,
    required this.ventaId,
    this.numeroVenta,
    required this.tipoVenta,
  });

  @override
  State<QrPedidoScreen> createState() => _QrPedidoScreenState();
}

class _QrPedidoScreenState extends State<QrPedidoScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  String? _codigoQr;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarCodigoQr();
  }

  Future<void> _cargarCodigoQr() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getCodigoQrVenta(widget.ventaId);

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          setState(() {
            _codigoQr = data['data']['codigo_qr'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error al obtener código QR';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error al conectar con el servidor';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Código QR del Pedido'),
        backgroundColor: AppColors.primary,
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
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarCodigoQr,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _codigoQr == null
                  ? const Center(child: Text('No se pudo generar el código QR'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            widget.tipoVenta == 'envio_domicilio'
                                ? 'Muestra este código QR al repartidor'
                                : 'Muestra este código QR al vendedor',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.numeroVenta != null
                                ? 'Pedido: ${widget.numeroVenta}'
                                : 'Pedido #${widget.ventaId}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: _codigoQr!,
                              version: QrVersions.auto,
                              size: 280.0,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.tipoVenta == 'envio_domicilio'
                                        ? 'El repartidor escaneará este código cuando entregue tu pedido'
                                        : 'El vendedor escaneará este código cuando recojas tu pedido en la tienda',
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Código: $_codigoQr',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
    );
  }
}

