/// Utilidad para parsear fechas desde diferentes formatos
class DateParser {
  /// Parsea una fecha desde JSON, manejando múltiples formatos
  static DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    
    if (json is DateTime) return json;
    
    if (json is String) {
      // Intentar parsear formato ISO 8601 (estándar)
      try {
        return DateTime.parse(json);
      } catch (e) {
        // Si falla, intentar otros formatos
      }
      
      // Intentar parsear formato HTTP/RFC 2822 (ej: "Sun, 21 Nov 2027 00:00:00 GMT")
      try {
        // Mapeo de meses en inglés
        final monthMap = {
          'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
          'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
        };
        
        // Patrón: "Sun, 21 Nov 2027 00:00:00 GMT"
        final regex = RegExp(r'(\w+),\s+(\d+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\w+)');
        final match = regex.firstMatch(json);
        
        if (match != null) {
          final day = int.parse(match.group(2)!);
          final monthStr = match.group(3)!;
          final year = int.parse(match.group(4)!);
          final hour = int.parse(match.group(5)!);
          final minute = int.parse(match.group(6)!);
          final second = int.parse(match.group(7)!);
          
          final month = monthMap[monthStr];
          if (month != null) {
            return DateTime(year, month, day, hour, minute, second);
          }
        }
      } catch (e) {
        // Continuar con otros formatos
      }
      
      // Intentar formato MySQL (YYYY-MM-DD o YYYY-MM-DD HH:MM:SS)
      try {
        if (json.contains(' ')) {
          // YYYY-MM-DD HH:MM:SS
          return DateTime.parse(json.replaceAll(' ', 'T'));
        } else {
          // YYYY-MM-DD
          return DateTime.parse('${json}T00:00:00');
        }
      } catch (e) {
        // Si todos fallan, retornar null
      }
    }
    
    return null;
  }
}

