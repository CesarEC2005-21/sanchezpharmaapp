import 'package:flutter/material.dart';

class EnviarConsultaScreen extends StatelessWidget {
  const EnviarConsultaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envíanos un mensaje'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildOpcion(
            context,
            titulo: 'Manejo de la aplicación',
            onTap: () {
              _mostrarDialogoConsulta(
                context,
                titulo: 'Manejo de la aplicación',
                descripcion: '¿Necesitas ayuda para usar alguna función de la aplicación?',
              );
            },
          ),
          const Divider(height: 1),
          _buildOpcion(
            context,
            titulo: 'Estado del pedido',
            onTap: () {
              _mostrarDialogoConsulta(
                context,
                titulo: 'Estado del pedido',
                descripcion: '¿Tienes alguna consulta sobre el estado de tu pedido?',
              );
            },
          ),
          const Divider(height: 1),
          _buildOpcion(
            context,
            titulo: 'Consulta de productos / stock',
            onTap: () {
              _mostrarDialogoConsulta(
                context,
                titulo: 'Consulta de productos / stock',
                descripcion: '¿Necesitas información sobre algún producto o su disponibilidad?',
              );
            },
          ),
          const Divider(height: 1),
          _buildOpcion(
            context,
            titulo: 'Horario de atención',
            onTap: () {
              _mostrarInformacionHorario(context);
            },
          ),
          const Divider(height: 1),
          _buildOpcion(
            context,
            titulo: 'Sugerencias',
            onTap: () {
              _mostrarDialogoConsulta(
                context,
                titulo: 'Sugerencias',
                descripcion: '¿Tienes alguna sugerencia para mejorar nuestro servicio?',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOpcion(BuildContext context, {required String titulo, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.green.shade700,
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoConsulta(BuildContext context, {required String titulo, required String descripcion}) {
    final TextEditingController mensajeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(descripcion),
            const SizedBox(height: 16),
            TextField(
              controller: mensajeController,
              decoration: const InputDecoration(
                labelText: 'Escribe tu consulta',
                hintText: 'Escribe aquí tu mensaje...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (mensajeController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tu consulta ha sido enviada. Te responderemos pronto.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, escribe tu consulta'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _mostrarInformacionHorario(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Horario de atención'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nuestro horario de atención es:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildHorarioItem('Lunes a Viernes', '9:00 AM - 7:00 PM'),
            _buildHorarioItem('Sábados', '9:00 AM - 6:00 PM'),
            _buildHorarioItem('Domingos', '10:00 AM - 4:00 PM'),
            const SizedBox(height: 16),
            const Text(
              'Atención telefónica:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('(01) 123-4567'),
            const SizedBox(height: 8),
            const Text('Email: contacto@sanchezpharma.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildHorarioItem(String dia, String horario) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(dia),
          Text(
            horario,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

