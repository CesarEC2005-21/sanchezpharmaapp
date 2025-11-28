import 'dart:convert';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionsService {
  // API Key de Google Maps (debe ser la misma que se usa en AndroidManifest.xml)
  // En producción, esto debería estar en un archivo de configuración seguro
  static const String _apiKey = 'AIzaSyAF5En1vgFxedwFiErCGL-FADIBCrpcOMc';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Obtiene la ruta entre dos puntos usando Google Directions API
  /// Retorna una lista de LatLng que representa la ruta por las calles
  static Future<List<LatLng>> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      // Agregar parámetros para obtener ruta más detallada por calles
      // Usar avoid=highways para rutas más locales si es necesario
      final url = Uri.parse(
        '$_baseUrl?origin=$originLat,$originLng&destination=$destLat,$destLng&key=$_apiKey&language=es&mode=driving&alternatives=false&units=metric',
      );

      print('🗺️ Obteniendo ruta de Google Directions API...');
      print('   Origen: ($originLat, $originLng)');
      print('   Destino: ($destLat, $destLng)');
      print('   URL: $url');

      final response = await http.get(url);
      
      print('   Status Code: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('   Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Log completo de la respuesta para debug
        print('   Status de API: ${data['status']}');
        if (data['error_message'] != null) {
          print('   ⚠️ Mensaje de error de API: ${data['error_message']}');
        }

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          print('   ✅ Respuesta OK, procesando ruta...');
          // Obtener el polyline codificado de la ruta
          final route = data['routes'][0];
          
          // Usar el polyline completo de cada step para obtener más detalle
          List<LatLng> allRoutePoints = [];
          
          if (route['legs'] != null && route['legs'].isNotEmpty) {
            final leg = route['legs'][0];
            
            final stepsCount = leg['steps']?.length ?? 0;
            print('   Pasos encontrados: $stepsCount');
            
            // SIEMPRE intentar usar los steps primero (más detallado)
            if (leg['steps'] != null && leg['steps'].isNotEmpty) {
              print('   📍 Procesando ${stepsCount} pasos de la ruta...');
              for (var step in leg['steps']) {
                if (step['polyline'] != null && step['polyline']['points'] != null) {
                  final stepPolyline = step['polyline']['points'];
                  try {
                    final decodedStepPoints = decodePolyline(stepPolyline);
                    
                    // Convertir a LatLng
                    final stepPoints = decodedStepPoints
                        .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
                        .toList();
                    
                    allRoutePoints.addAll(stepPoints);
                  } catch (e) {
                    print('   ⚠️ Error al decodificar polyline de un step: $e');
                  }
                }
              }
              print('   ✅ Total de puntos de steps: ${allRoutePoints.length}');
            }
            
            // Si no hay steps o están vacíos, usar el overview_polyline como fallback
            if (allRoutePoints.isEmpty) {
              print('   ⚠️ No se obtuvieron puntos de steps, usando overview_polyline como fallback');
              if (route['overview_polyline'] != null && route['overview_polyline']['points'] != null) {
                final overviewPolyline = route['overview_polyline']['points'];
                try {
                  final decodedPoints = decodePolyline(overviewPolyline);
                  allRoutePoints = decodedPoints
                      .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
                      .toList();
                  print('   📍 Puntos de overview_polyline: ${allRoutePoints.length}');
                } catch (e) {
                  print('   ❌ Error al decodificar overview_polyline: $e');
                }
              } else {
                print('   ❌ No hay overview_polyline disponible');
              }
            }
            
            // Obtener información adicional de la ruta
            if (leg['distance'] != null && leg['duration'] != null) {
              final distance = leg['distance']['text'];
              final duration = leg['duration']['text'];
              print('   Distancia: $distance');
              print('   Duración: $duration');
            }
          } else {
            // Fallback: usar overview_polyline si no hay legs
            print('   ⚠️ No hay legs, usando overview_polyline');
            if (route['overview_polyline'] != null && route['overview_polyline']['points'] != null) {
              final overviewPolyline = route['overview_polyline']['points'];
              final decodedPoints = decodePolyline(overviewPolyline);
              allRoutePoints = decodedPoints
                  .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
                  .toList();
            }
          }

          print('✅ Ruta obtenida: ${allRoutePoints.length} puntos');
          
          // Si tenemos muy pocos puntos, algo está mal
          if (allRoutePoints.length < 3) {
            print('   ⚠️ ADVERTENCIA: Muy pocos puntos en la ruta. Posible problema con la API.');
            print('   Respuesta completa: ${json.encode(data)}');
          }
          
          // Eliminar puntos duplicados consecutivos
          List<LatLng> uniquePoints = [];
          for (int i = 0; i < allRoutePoints.length; i++) {
            if (i == 0 || 
                (allRoutePoints[i].latitude != allRoutePoints[i-1].latitude ||
                 allRoutePoints[i].longitude != allRoutePoints[i-1].longitude)) {
              uniquePoints.add(allRoutePoints[i]);
            }
          }

          return uniquePoints.isNotEmpty ? uniquePoints : allRoutePoints;
        } else {
          print('⚠️ Error en la respuesta de Directions API: ${data['status']}');
          print('   Mensaje: ${data['error_message'] ?? 'Sin mensaje'}');
          print('   ⚠️ IMPORTANTE: La Directions API no está funcionando.');
          print('   Esto puede deberse a:');
          print('   1. La API key no tiene habilitada la Directions API');
          print('   2. La API key no tiene permisos');
          print('   3. Se excedió la cuota de la API');
          print('   4. La API key es inválida');
          
          // NO retornar ruta directa - retornar lista vacía para que no se dibuje nada
          // Esto forzará a que se muestre un error en lugar de una línea recta
          return [];
        }
      } else {
        print('❌ Error HTTP al obtener ruta: ${response.statusCode}');
        print('   Response body: ${response.body}');
        // NO retornar ruta directa - retornar lista vacía
        return [];
      }
    } catch (e, stackTrace) {
      print('❌ Error al obtener ruta: $e');
      print('   Tipo de error: ${e.runtimeType}');
      print('   Stack trace: $stackTrace');
      // NO retornar ruta directa - retornar lista vacía
      return [];
    }
  }

  /// Obtiene información detallada de la ruta (distancia, duración)
  static Future<Map<String, dynamic>?> getRouteInfo({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?origin=$originLat,$originLng&destination=$destLat,$destLng&key=$_apiKey&language=es&mode=driving',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          if (route['legs'].isNotEmpty) {
            final leg = route['legs'][0];
            return {
              'distance': leg['distance']['text'],
              'distance_meters': leg['distance']['value'],
              'duration': leg['duration']['text'],
              'duration_seconds': leg['duration']['value'],
            };
          }
        }
      }
      return null;
    } catch (e) {
      print('Error al obtener información de ruta: $e');
      return null;
    }
  }
}

