import 'package:flutter/material.dart';

class DocumentoLegalScreen extends StatelessWidget {
  final String titulo;
  final String contenido;

  const DocumentoLegalScreen({
    super.key,
    required this.titulo,
    required this.contenido,
  });

  String _getFechaActualizacion() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título principal
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Última actualización: ${_getFechaActualizacion()}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Divider(height: 32),
            
            // Contenido
            _buildContenidoFormateado(contenido),
          ],
        ),
      ),
    );
  }

  Widget _buildContenidoFormateado(String texto) {
    // Dividir por párrafos (doble salto de línea)
    final parrafos = texto.split('\n\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parrafos.map((parrafo) {
        if (parrafo.trim().isEmpty) {
          return const SizedBox(height: 16);
        }
        
        // Detectar si es un título (líneas que terminan con :)
        final esTitulo = parrafo.trim().endsWith(':') && parrafo.length < 100;
        
        // Detectar si es una lista (líneas que empiezan con - o •)
        final esLista = parrafo.trim().startsWith('-') || parrafo.trim().startsWith('•');
        
        if (esTitulo) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              parrafo.trim(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          );
        } else if (esLista) {
          final items = parrafo.split('\n').where((line) => line.trim().isNotEmpty).toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.replaceFirst(RegExp(r'^[-•]\s*'), '').trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              parrafo.trim(),
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          );
        }
      }).toList(),
    );
  }
}

