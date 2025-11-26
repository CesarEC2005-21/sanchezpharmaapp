import 'package:flutter/material.dart';

class PreguntasFrecuentesScreen extends StatefulWidget {
  const PreguntasFrecuentesScreen({super.key});

  @override
  State<PreguntasFrecuentesScreen> createState() => _PreguntasFrecuentesScreenState();
}

class _PreguntasFrecuentesScreenState extends State<PreguntasFrecuentesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 1; // "Proceso de compra" por defecto

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() {
        _tabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preguntas frecuentes'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.green.shade50,
      body: Column(
        children: [
          // Barra de categorías (verde claro)
          Container(
            color: Colors.green.shade100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.green.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              labelColor: Colors.green.shade900,
              unselectedLabelColor: Colors.grey.shade700,
              isScrollable: true,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.smartphone, size: 18),
                      const SizedBox(width: 6),
                      const Text('Ayuda para compras'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_bag, size: 18),
                      const SizedBox(width: 6),
                      const Text('Proceso de compra'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payment, size: 18),
                      const SizedBox(width: 6),
                      const Text('Formas de pago'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPreguntasCompras(),
                _buildPreguntasProcesoCompra(),
                _buildPreguntasPago(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreguntasCompras() {
    final preguntas = [
      '¿Cómo puedo buscar productos en la app?',
      '¿Cómo guardo un producto en favoritos?',
      '¿Puedo ver el stock disponible?',
    ];

    return _buildListaPreguntas(preguntas, 0);
  }

  Widget _buildPreguntasProcesoCompra() {
    final preguntas = [
      '¿Los precios de los productos en línea son similares a los precios de la botica?',
      '¿Cómo puedo guardar un producto que me interesa?',
      '¿Qué es el carrito de compras?',
      '¿Por cuánto tiempo permanecerán los productos seleccionados en el carrito?',
      '¿Puedo revisar el stock de productos en tienda?',
      '¿La app procesará automáticamente las promociones?',
    ];

    return _buildListaPreguntas(preguntas, 1);
  }

  Widget _buildPreguntasPago() {
    final preguntas = [
      '¿Qué métodos de pago aceptan?',
      '¿Es seguro pagar con tarjeta en la app?',
      '¿Puedo pagar al recibir el pedido?',
    ];

    return _buildListaPreguntas(preguntas, 2);
  }

  Widget _buildListaPreguntas(List<String> preguntas, int categoria) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: preguntas.length,
      itemBuilder: (context, index) {
        return _PreguntaItem(
          numero: index + 1,
          pregunta: preguntas[index],
          categoria: categoria,
        );
      },
    );
  }
}

class _PreguntaItem extends StatefulWidget {
  final int numero;
  final String pregunta;
  final int categoria;

  const _PreguntaItem({
    required this.numero,
    required this.pregunta,
    required this.categoria,
  });

  @override
  State<_PreguntaItem> createState() => _PreguntaItemState();
}

class _PreguntaItemState extends State<_PreguntaItem> {
  bool _isExpanded = false;

  String _getRespuesta() {
    final respuestas = {
      0: [
        'Puedes usar la barra de búsqueda en la parte superior de la pantalla de inicio. También puedes navegar por categorías desde el menú principal.',
        'Toca el ícono de corazón en la tarjeta del producto. Los productos guardados aparecerán en la sección "Favoritos" de tu cuenta.',
        'Sí, el stock disponible se muestra en cada producto. Si un producto está agotado, verás una indicación clara.',
      ],
      1: [
        'Sí, los precios en línea son los mismos que en nuestras boticas físicas. Además, ofrecemos promociones exclusivas online.',
        'Puedes agregar productos a favoritos tocando el ícono de corazón. También puedes agregarlos al carrito para comprarlos más tarde.',
        'El carrito es donde guardas temporalmente los productos que deseas comprar. Puedes agregar varios productos y comprarlos todos juntos.',
        'Los productos permanecen en tu carrito hasta que completes la compra o los elimines. No hay límite de tiempo, pero te recomendamos completar tu compra pronto para asegurar disponibilidad.',
        'Sí, la app muestra el stock disponible en tiempo real. Si un producto está agotado, verás la indicación correspondiente.',
        'Sí, todas las promociones activas se aplican automáticamente al agregar productos al carrito. Verás el precio con descuento antes de confirmar tu compra.',
      ],
      2: [
        'Aceptamos efectivo, tarjetas de crédito y débito, y transferencias bancarias. También puedes pagar con Yape o Plin.',
        'Sí, todos los pagos se procesan de forma segura mediante sistemas de encriptación. No almacenamos información completa de tu tarjeta.',
        'Sí, ofrecemos la opción de pago contra entrega para envíos a domicilio. También puedes pagar al recoger en tienda.',
      ],
    };

    return respuestas[widget.categoria]?[widget.numero - 1] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(
                    '${widget.numero}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.pregunta,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(44, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _getRespuesta(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
