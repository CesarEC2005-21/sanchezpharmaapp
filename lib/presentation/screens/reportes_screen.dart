import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/date_parser.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _cargarDashboardResumen();
  }

  Future<void> _cargarDashboardResumen() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getDashboardResumen();
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          // Convertir lista a mapa para fácil acceso
          final List<dynamic> lista = data['data'];
          final Map<String, dynamic> mapa = {};
          for (var item in lista) {
            mapa[item['tipo']] = item;
          }
          setState(() {
            _dashboardData = mapa;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error al cargar datos';
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
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
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
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarDashboardResumen,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarDashboardResumen,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dashboard Resumen
                        if (_dashboardData != null) _buildDashboardCards(),
                        const SizedBox(height: 24),
                        // Reportes de Ventas
                        _buildSectionTitle('Reportes de Ventas', Icons.shopping_cart, Colors.green),
                        const SizedBox(height: 12),
                        _buildReporteCard(
                          'Ventas Diarias',
                          'Ver ventas del día',
                          Icons.today,
                          Colors.green,
                          () => _mostrarVentasDiarias(),
                        ),
                        _buildReporteCard(
                          'Ventas Mensuales',
                          'Ver ventas del mes',
                          Icons.calendar_month,
                          Colors.green,
                          () => _mostrarVentasMensuales(),
                        ),
                        _buildReporteCard(
                          'Ventas por Período',
                          'Reporte personalizado de ventas',
                          Icons.date_range,
                          Colors.green,
                          () => _mostrarVentasPeriodo(),
                        ),
                        _buildReporteCard(
                          'Ventas por Vendedor',
                          'Análisis de ventas por vendedor',
                          Icons.person,
                          Colors.green,
                          () => _mostrarVentasPorVendedor(),
                        ),
                        _buildReporteCard(
                          'Ventas por Cliente',
                          'Análisis de ventas por cliente',
                          Icons.people,
                          Colors.green,
                          () => _mostrarVentasPorCliente(),
                        ),
                        _buildReporteCard(
                          'Ventas por Método de Pago',
                          'Distribución de métodos de pago',
                          Icons.payment,
                          Colors.green,
                          () => _mostrarVentasPorMetodoPago(),
                        ),
                        _buildReporteCard(
                          'Ingresos Totales',
                          'Resumen de ingresos',
                          Icons.attach_money,
                          Colors.green,
                          () => _mostrarIngresosTotales(),
                        ),
                        const SizedBox(height: 24),
                        // Reportes de Productos
                        _buildSectionTitle('Reportes de Productos', Icons.inventory, Colors.orange),
                        const SizedBox(height: 12),
                        _buildReporteCard(
                          'Productos Más Vendidos',
                          'Ranking de productos',
                          Icons.trending_up,
                          Colors.orange,
                          () => _mostrarProductosMasVendidos(),
                        ),
                        _buildReporteCard(
                          'Rotación de Productos',
                          'Análisis de rotación',
                          Icons.refresh,
                          Colors.orange,
                          () => _mostrarRotacionProductos(),
                        ),
                        const SizedBox(height: 24),
                        // Reportes de Inventario
                        _buildSectionTitle('Reportes de Inventario', Icons.warehouse, Colors.green),
                        const SizedBox(height: 12),
                        _buildReporteCard(
                          'Análisis de Inventario',
                          'Resumen del inventario',
                          Icons.analytics,
                          Colors.green,
                          () => _mostrarAnalisisInventario(),
                        ),
                        const SizedBox(height: 24),
                        // Reportes de Envíos
                        _buildSectionTitle('Reportes de Envíos', Icons.local_shipping, Colors.purple),
                        const SizedBox(height: 12),
                        _buildReporteCard(
                          'Resumen de Envíos',
                          'Estado de envíos',
                          Icons.summarize,
                          Colors.purple,
                          () => _mostrarResumenEnvios(),
                        ),
                        _buildReporteCard(
                          'Reporte de Envíos',
                          'Reporte detallado de envíos',
                          Icons.description,
                          Colors.purple,
                          () => _mostrarReporteEnvios(),
                        ),
                        const SizedBox(height: 24),
                        // Comparativas
                        _buildSectionTitle('Comparativas', Icons.compare_arrows, Colors.teal),
                        const SizedBox(height: 12),
                        _buildReporteCard(
                          'Comparativa de Períodos',
                          'Comparar meses',
                          Icons.timeline,
                          Colors.teal,
                          () => _mostrarComparativaPeriodos(),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildReporteCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDashboardCards() {
    final ventasDia = _dashboardData!['ventas_dia'];
    final ventasMes = _dashboardData!['ventas_mes'];
    final stockBajo = _dashboardData!['stock_bajo'];
    final enviosPendientes = _dashboardData!['envios_pendientes'];
    final valorInventario = _dashboardData!['valor_inventario'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen General',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Ventas Hoy',
                ventasDia?['cantidad']?.toString() ?? '0',
                'S/ ${_formatNumber(ventasDia?['monto'] ?? 0)}',
                Colors.green,
                Icons.today,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Ventas Mes',
                ventasMes?['cantidad']?.toString() ?? '0',
                'S/ ${_formatNumber(ventasMes?['monto'] ?? 0)}',
                Colors.green,
                Icons.calendar_month,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Stock Bajo',
                stockBajo?['cantidad']?.toString() ?? '0',
                'Productos',
                Colors.orange,
                Icons.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Envíos Pendientes',
                enviosPendientes?['cantidad']?.toString() ?? '0',
                'Envíos',
                Colors.purple,
                Icons.local_shipping,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          'Valor Inventario',
          'S/ ${_formatNumber(valorInventario?['monto'] ?? 0)}',
          'Total',
          Colors.teal,
          Icons.inventory,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0.00';
    final numValue = value is num ? value : double.tryParse(value.toString()) ?? 0;
    return NumberFormat('#,##0.00', 'es_PE').format(numValue);
  }

  // Métodos para mostrar reportes
  Future<void> _mostrarVentasDiarias() async {
    _mostrarLoading();
    try {
      final response = await _apiService.getVistaVentasDiarias();
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          Navigator.pop(context); // Cerrar loading
          _mostrarDialogoReporte('Ventas Diarias', data['data'], _buildVentasDiariasTable);
        } else {
          Navigator.pop(context);
          _mostrarError(data['message'] ?? 'Error al cargar datos');
        }
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error: $e');
    }
  }

  Future<void> _mostrarVentasMensuales() async {
    _mostrarLoading();
    try {
      final response = await _apiService.getVistaVentasMensuales();
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          Navigator.pop(context);
          _mostrarDialogoReporte('Ventas Mensuales', data['data'], _buildVentasMensualesTable);
        } else {
          Navigator.pop(context);
          _mostrarError(data['message'] ?? 'Error al cargar datos');
        }
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error: $e');
    }
  }

  Future<void> _mostrarVentasPeriodo() async {
    final fechaInicio = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fechaInicio == null) return;

    final fechaFin = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: fechaInicio,
      lastDate: DateTime.now(),
    );
    if (fechaFin == null) return;

    _mostrarLoading();
    try {
      final response = await _apiService.reporteVentasPeriodo({
        'fecha_desde': DateFormat('yyyy-MM-dd').format(fechaInicio),
        'fecha_hasta': DateFormat('yyyy-MM-dd').format(fechaFin),
      });
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          Navigator.pop(context);
          _mostrarDialogoReporte('Ventas por Período', data['data'], _buildVentasTable);
        } else {
          Navigator.pop(context);
          _mostrarError(data['message'] ?? 'Error al cargar datos');
        }
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error: $e');
    }
  }

  Future<void> _mostrarVentasPorVendedor() async {
    _mostrarLoading();
    try {
      final response = await _apiService.getVistaVentasPorVendedor();
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          Navigator.pop(context);
          _mostrarDialogoReporte('Ventas por Vendedor', data['data'], _buildVentasPorVendedorTable);
        } else {
          Navigator.pop(context);
          _mostrarError(data['message'] ?? 'Error al cargar datos');
        }
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error: $e');
    }
  }

  Future<void> _mostrarVentasPorCliente() async {
    _mostrarLoading();
    try {
      final response = await _apiService.getVistaVentasPorCliente();
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          Navigator.pop(context);
          _mostrarDialogoReporte('Ventas por Cliente', data['data'], _buildVentasPorClienteTable);
        } else {
          Navigator.pop(context);
          _mostrarError(data['message'] ?? 'Error al cargar datos');
        }
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error: $e');
    }
  }

  Future<void> _mostrarVentasPorMetodoPago() async {
    _mostrarLoading();
    try {
      final response = await _apiService.getVistaVentasPorMetodoPago();
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          Navigator.pop(context);
          _mostrarDialogoReporte('Ventas por Método de Pago', data['data'], _buildVentasPorMetodoPagoTable);
        } else {
          Navigator.pop(context);
          _mostrarError(data['message'] ?? 'Error al cargar datos');
        }
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error: $e');
    }
  }

  Future<void> _mostrarIngresosTotales() async {
    final fechaInicio = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fechaInicio == null) return;

    final fechaFin = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: fechaInicio,
      lastDate: DateTime.now(),
    );
    if (fechaFin == null) return;

    _mostrarLoading();
    try {
      final response = await _apiService.reporteIngresosTotales({
        'fecha_desde': DateFormat('yyyy-MM-dd').format(fechaInicio),
        'fecha_hasta': DateFormat('yyyy-MM-dd').format(fechaFin),
      });
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          Navigator.pop(context);
          _mostrarDialogoReporte('Ingresos Totales', [data['data']], _buildIngresosTotalesTable);
        } else {
          Navigator.pop(context);
          _mostrarError(data['message'] ?? 'Error al cargar datos');
        }
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error: $e');
    }
  }

  Future<void> _mostrarProductosMasVendidos() async {
    _mostrarLoading();
    try {
      final response = await _apiService.getVistaProductosMasVendidos(10);
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          Navigator.pop(context);
          _mostrarDialogoReporte('Productos Más Vendidos', data['data'], _buildProductosMasVendidosTable);
        } else {
          Navigator.pop(context);
          _mostrarError(data['message'] ?? 'Error al cargar datos');
        }
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error: $e');
    }
  }

  Future<void> _mostrarRotacionProductos() async {
    _mostrarLoading();
    try {
      final response = await _apiService.getVistaRotacionProductos(50);
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          Navigator.pop(context);
          _mostrarDialogoReporte('Rotación de Productos', data['data'], _buildRotacionProductosTable);
        } else {
          Navigator.pop(context);
          _mostrarError(data['message'] ?? 'Error al cargar datos');
        }
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error: $e');
    }
  }

  Future<void> _mostrarAnalisisInventario() async {
    _mostrarLoading();
    try {
      final response = await _apiService.getVistaAnalisisInventario();
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          Navigator.pop(context);
          _mostrarDialogoReporte('Análisis de Inventario', [data['data']], _buildAnalisisInventarioTable);
        } else {
          Navigator.pop(context);
          _mostrarError(data['message'] ?? 'Error al cargar datos');
        }
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error: $e');
    }
  }

  Future<void> _mostrarResumenEnvios() async {
    _mostrarLoading();
    try {
      final response = await _apiService.getVistaResumenEnvios();
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          Navigator.pop(context);
          _mostrarDialogoReporte('Resumen de Envíos', data['data'], _buildResumenEnviosTable);
        } else {
          Navigator.pop(context);
          _mostrarError(data['message'] ?? 'Error al cargar datos');
        }
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error: $e');
    }
  }

  Future<void> _mostrarReporteEnvios() async {
    final fechaInicio = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fechaInicio == null) return;

    final fechaFin = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: fechaInicio,
      lastDate: DateTime.now(),
    );
    if (fechaFin == null) return;

    _mostrarLoading();
    try {
      final response = await _apiService.reporteEnvios({
        'fecha_desde': DateFormat('yyyy-MM-dd').format(fechaInicio),
        'fecha_hasta': DateFormat('yyyy-MM-dd').format(fechaFin),
      });
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          Navigator.pop(context);
          _mostrarDialogoReporte('Reporte de Envíos', data['data'], _buildEnviosTable);
        } else {
          Navigator.pop(context);
          _mostrarError(data['message'] ?? 'Error al cargar datos');
        }
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error: $e');
    }
  }

  Future<void> _mostrarComparativaPeriodos() async {
    _mostrarLoading();
    try {
      final response = await _apiService.getVistaComparativaPeriodos();
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          Navigator.pop(context);
          _mostrarDialogoReporte('Comparativa de Períodos', data['data'], _buildComparativaPeriodosTable);
        } else {
          Navigator.pop(context);
          _mostrarError(data['message'] ?? 'Error al cargar datos');
        }
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarError('Error: $e');
    }
  }

  void _mostrarLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _mostrarDialogoReporte(String titulo, List<dynamic> datos, Widget Function(List<dynamic>) builder) {
    showDialog(
      context: context,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final isTablet = screenSize.width > 600;
        final isSmallScreen = screenSize.height < 600;
        
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? screenSize.width * 0.1 : 16,
            vertical: isSmallScreen ? 8 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 800 : screenSize.width * 0.95,
              maxHeight: screenSize.height * (isSmallScreen ? 0.95 : 0.85),
            ),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          titulo,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(),
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: builder(datos),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Builders de tablas
  Widget _buildVentasDiariasTable(List<dynamic> datos) {
    if (datos.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }
    return DataTable(
      columns: const [
        DataColumn(label: Text('Fecha')),
        DataColumn(label: Text('Ventas')),
        DataColumn(label: Text('Ingreso')),
        DataColumn(label: Text('Promedio')),
      ],
      rows: datos.map((item) {
        final fecha = DateParser.fromJson(item['fecha']);
        return DataRow(cells: [
          DataCell(Text(fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : 'N/A')),
          DataCell(Text(item['total_ventas']?.toString() ?? '0')),
          DataCell(Text('S/ ${_formatNumber(item['ingreso_total'] ?? 0)}')),
          DataCell(Text('S/ ${_formatNumber(item['promedio_venta'] ?? 0)}')),
        ]);
      }).toList(),
    );
  }

  Widget _buildVentasMensualesTable(List<dynamic> datos) {
    if (datos.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }
    return DataTable(
      columns: const [
        DataColumn(label: Text('Mes/Año')),
        DataColumn(label: Text('Ventas')),
        DataColumn(label: Text('Ingreso')),
        DataColumn(label: Text('Clientes')),
      ],
      rows: datos.map((item) {
        return DataRow(cells: [
          DataCell(Text('${item['mes']}/${item['año']}')),
          DataCell(Text(item['total_ventas']?.toString() ?? '0')),
          DataCell(Text('S/ ${_formatNumber(item['ingreso_total'] ?? 0)}')),
          DataCell(Text(item['clientes_unicos']?.toString() ?? '0')),
        ]);
      }).toList(),
    );
  }

  Widget _buildVentasTable(List<dynamic> datos) {
    if (datos.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text('No hay datos disponibles'),
      ));
    }
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    if (isSmallScreen) {
      // Para pantallas pequeñas, mostrar como lista
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: datos.take(50).length,
        itemBuilder: (context, index) {
          final item = datos[index];
          final fecha = DateParser.fromJson(item['fecha_venta']);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text('${item['cliente_nombre'] ?? ''} ${item['cliente_apellido'] ?? ''}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : 'N/A'),
                  Text('S/ ${_formatNumber(item['total'] ?? 0)}'),
                  Text(item['tipo_venta']?.toString().replaceAll('_', ' ') ?? ''),
                ],
              ),
              trailing: Text(item['metodo_pago_nombre'] ?? ''),
            ),
          );
        },
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Fecha')),
          DataColumn(label: Text('Cliente')),
          DataColumn(label: Text('Total')),
          DataColumn(label: Text('Tipo')),
          DataColumn(label: Text('Método Pago')),
        ],
        rows: datos.take(50).map((item) {
          final fecha = DateParser.fromJson(item['fecha_venta']);
          return DataRow(cells: [
            DataCell(Text(fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : 'N/A')),
            DataCell(Text('${item['cliente_nombre'] ?? ''} ${item['cliente_apellido'] ?? ''}')),
            DataCell(Text('S/ ${_formatNumber(item['total'] ?? 0)}')),
            DataCell(Text(item['tipo_venta']?.toString().replaceAll('_', ' ') ?? '')),
            DataCell(Text(item['metodo_pago_nombre'] ?? '')),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildVentasPorVendedorTable(List<dynamic> datos) {
    if (datos.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }
    return DataTable(
      columns: const [
        DataColumn(label: Text('Vendedor')),
        DataColumn(label: Text('Ventas')),
        DataColumn(label: Text('Ingreso Total')),
        DataColumn(label: Text('Promedio')),
      ],
      rows: datos.map((item) {
        return DataRow(cells: [
          DataCell(Text(item['username'] ?? 'N/A')),
          DataCell(Text(item['total_ventas']?.toString() ?? '0')),
          DataCell(Text('S/ ${_formatNumber(item['ingreso_total'] ?? 0)}')),
          DataCell(Text('S/ ${_formatNumber(item['promedio_venta'] ?? 0)}')),
        ]);
      }).toList(),
    );
  }

  Widget _buildVentasPorClienteTable(List<dynamic> datos) {
    if (datos.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text('No hay datos disponibles'),
      ));
    }
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    if (isSmallScreen) {
      // Para pantallas pequeñas, mostrar como lista
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: datos.length,
        itemBuilder: (context, index) {
          final item = datos[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text('${item['nombre'] ?? ''} ${item['apellido'] ?? ''}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ventas: ${item['total_ventas']?.toString() ?? '0'}'),
                  Text('Total: S/ ${_formatNumber(item['monto_total'] ?? 0)}'),
                  Text('Promedio: S/ ${_formatNumber(item['promedio_venta'] ?? 0)}'),
                ],
              ),
            ),
          );
        },
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Cliente')),
          DataColumn(label: Text('Ventas')),
          DataColumn(label: Text('Monto Total')),
          DataColumn(label: Text('Promedio')),
        ],
        rows: datos.map((item) {
          return DataRow(cells: [
            DataCell(Text('${item['nombre'] ?? ''} ${item['apellido'] ?? ''}')),
            DataCell(Text(item['total_ventas']?.toString() ?? '0')),
            DataCell(Text('S/ ${_formatNumber(item['monto_total'] ?? 0)}')),
            DataCell(Text('S/ ${_formatNumber(item['promedio_venta'] ?? 0)}')),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildVentasPorMetodoPagoTable(List<dynamic> datos) {
    if (datos.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }
    return DataTable(
      columns: const [
        DataColumn(label: Text('Método de Pago')),
        DataColumn(label: Text('Ventas')),
        DataColumn(label: Text('Monto Total')),
        DataColumn(label: Text('Porcentaje')),
      ],
      rows: datos.map((item) {
        return DataRow(cells: [
          DataCell(Text(item['metodo_pago'] ?? 'N/A')),
          DataCell(Text(item['total_ventas']?.toString() ?? '0')),
          DataCell(Text('S/ ${_formatNumber(item['monto_total'] ?? 0)}')),
          DataCell(Text('${_formatNumber(item['porcentaje'] ?? 0)}%')),
        ]);
      }).toList(),
    );
  }

  Widget _buildIngresosTotalesTable(List<dynamic> datos) {
    if (datos.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }
    final item = datos.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Ingreso Total', 'S/ ${_formatNumber(item['ingreso_total'] ?? 0)}'),
        _buildInfoRow('Total de Ventas', item['total_ventas']?.toString() ?? '0'),
        _buildInfoRow('Promedio de Venta', 'S/ ${_formatNumber(item['promedio_venta'] ?? 0)}'),
        _buildInfoRow('Venta Mínima', 'S/ ${_formatNumber(item['venta_minima'] ?? 0)}'),
        _buildInfoRow('Venta Máxima', 'S/ ${_formatNumber(item['venta_maxima'] ?? 0)}'),
        _buildInfoRow('Ingresos Recojo', 'S/ ${_formatNumber(item['ingresos_recojo'] ?? 0)}'),
        _buildInfoRow('Ingresos Envío', 'S/ ${_formatNumber(item['ingresos_envio'] ?? 0)}'),
      ],
    );
  }

  Widget _buildProductosMasVendidosTable(List<dynamic> datos) {
    if (datos.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text('No hay datos disponibles'),
      ));
    }
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    if (isSmallScreen) {
      // Para pantallas pequeñas, mostrar como lista
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: datos.length,
        itemBuilder: (context, index) {
          final item = datos[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text(item['nombre'] ?? 'N/A'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Categoría: ${item['categoria_nombre'] ?? ''}'),
                  Text('Vendido: ${item['total_vendido']?.toString() ?? '0'}'),
                  Text('Ingreso: S/ ${_formatNumber(item['ingreso_total'] ?? 0)}'),
                  Text('Veces: ${item['veces_vendido']?.toString() ?? '0'}'),
                ],
              ),
            ),
          );
        },
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Producto')),
          DataColumn(label: Text('Categoría')),
          DataColumn(label: Text('Vendido')),
          DataColumn(label: Text('Ingreso')),
          DataColumn(label: Text('Veces Vendido')),
        ],
        rows: datos.map((item) {
          return DataRow(cells: [
            DataCell(Text(item['nombre'] ?? 'N/A')),
            DataCell(Text(item['categoria_nombre'] ?? '')),
            DataCell(Text(item['total_vendido']?.toString() ?? '0')),
            DataCell(Text('S/ ${_formatNumber(item['ingreso_total'] ?? 0)}')),
            DataCell(Text(item['veces_vendido']?.toString() ?? '0')),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildRotacionProductosTable(List<dynamic> datos) {
    if (datos.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text('No hay datos disponibles'),
      ));
    }
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    if (isSmallScreen) {
      // Para pantallas pequeñas, mostrar como lista
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: datos.length,
        itemBuilder: (context, index) {
          final item = datos[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text(item['nombre'] ?? 'N/A'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stock: ${item['stock_actual']?.toString() ?? '0'}'),
                  Text('Vendido: ${item['unidades_vendidas']?.toString() ?? '0'}'),
                  Text('Veces: ${item['veces_vendido']?.toString() ?? '0'}'),
                  Text('Rotación: ${_formatNumber(item['indice_rotacion'] ?? 0)}'),
                ],
              ),
            ),
          );
        },
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Producto')),
          DataColumn(label: Text('Stock')),
          DataColumn(label: Text('Vendido')),
          DataColumn(label: Text('Veces Vendido')),
          DataColumn(label: Text('Rotación')),
        ],
        rows: datos.map((item) {
          return DataRow(cells: [
            DataCell(Text(item['nombre'] ?? 'N/A')),
            DataCell(Text(item['stock_actual']?.toString() ?? '0')),
            DataCell(Text(item['unidades_vendidas']?.toString() ?? '0')),
            DataCell(Text(item['veces_vendido']?.toString() ?? '0')),
            DataCell(Text(_formatNumber(item['indice_rotacion'] ?? 0))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildAnalisisInventarioTable(List<dynamic> datos) {
    if (datos.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }
    final item = datos.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Total Productos', item['total_productos']?.toString() ?? '0'),
        _buildInfoRow('Productos Activos', item['productos_activos']?.toString() ?? '0'),
        _buildInfoRow('Productos Agotados', item['productos_agotados']?.toString() ?? '0'),
        _buildInfoRow('Stock Bajo', item['productos_stock_bajo']?.toString() ?? '0'),
        _buildInfoRow('Valor Inventario (Compra)', 'S/ ${_formatNumber(item['valor_inventario_compra'] ?? 0)}'),
        _buildInfoRow('Valor Inventario (Venta)', 'S/ ${_formatNumber(item['valor_inventario_venta'] ?? 0)}'),
        _buildInfoRow('Ganancia Potencial', 'S/ ${_formatNumber(item['ganancia_potencial'] ?? 0)}'),
      ],
    );
  }

  Widget _buildResumenEnviosTable(List<dynamic> datos) {
    if (datos.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }
    return DataTable(
      columns: const [
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Total')),
        DataColumn(label: Text('Entregados')),
        DataColumn(label: Text('Días Promedio')),
      ],
      rows: datos.map((item) {
        return DataRow(cells: [
          DataCell(Text(item['estado']?.toString().replaceAll('_', ' ') ?? '')),
          DataCell(Text(item['total_envios']?.toString() ?? '0')),
          DataCell(Text(item['entregados']?.toString() ?? '0')),
          DataCell(Text(item['dias_promedio_entrega']?.toString() ?? 'N/A')),
        ]);
      }).toList(),
    );
  }

  Widget _buildEnviosTable(List<dynamic> datos) {
    if (datos.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text('No hay datos disponibles'),
      ));
    }
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    if (isSmallScreen) {
      // Para pantallas pequeñas, mostrar como lista
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: datos.take(50).length,
        itemBuilder: (context, index) {
          final item = datos[index];
          final fecha = DateParser.fromJson(item['fecha_creacion']);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text(item['cliente_nombre'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : 'N/A'),
                  Text('Estado: ${item['estado']?.toString().replaceAll('_', ' ') ?? ''}'),
                  Text('Días: ${item['dias_transcurridos']?.toString() ?? '0'}'),
                ],
              ),
            ),
          );
        },
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Fecha')),
          DataColumn(label: Text('Cliente')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Días')),
        ],
        rows: datos.take(50).map((item) {
          final fecha = DateParser.fromJson(item['fecha_creacion']);
          return DataRow(cells: [
            DataCell(Text(fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : 'N/A')),
            DataCell(Text(item['cliente_nombre'] ?? '')),
            DataCell(Text(item['estado']?.toString().replaceAll('_', ' ') ?? '')),
            DataCell(Text(item['dias_transcurridos']?.toString() ?? '0')),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildComparativaPeriodosTable(List<dynamic> datos) {
    if (datos.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }
    return DataTable(
      columns: const [
        DataColumn(label: Text('Período')),
        DataColumn(label: Text('Ventas')),
        DataColumn(label: Text('Ingreso')),
        DataColumn(label: Text('Promedio')),
        DataColumn(label: Text('Clientes')),
      ],
      rows: datos.map((item) {
        return DataRow(cells: [
          DataCell(Text(item['periodo'] ?? '')),
          DataCell(Text(item['total_ventas']?.toString() ?? '0')),
          DataCell(Text('S/ ${_formatNumber(item['ingreso_total'] ?? 0)}')),
          DataCell(Text('S/ ${_formatNumber(item['promedio_venta'] ?? 0)}')),
          DataCell(Text(item['clientes_unicos']?.toString() ?? '0')),
        ]);
      }).toList(),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

