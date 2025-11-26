import 'package:flutter/material.dart';
import 'preguntas_frecuentes_screen.dart';
import 'enviar_consulta_screen.dart';

class AtencionClienteScreen extends StatelessWidget {
  const AtencionClienteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atención al cliente'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Ícono de burbuja de pensamiento
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Burbuja principal
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.teal.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Cola de la burbuja (3 círculos pequeños)
                    Positioned(
                      bottom: -20,
                      left: 50,
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Título principal
                const Text(
                  '¿Necesitas ayuda?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Texto instructivo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'Para encontrar respuestas a tus dudas puedes ir a',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.apps,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Botón de Preguntas Frecuentes
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PreguntasFrecuentesScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'PREGUNTAS FRECUENTES',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Texto "o si deseas"
                Text(
                  'o si deseas',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Botón de Enviar Consulta
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EnviarConsultaScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'ENVÍANOS TU CONSULTA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

