import 'package:flutter/material.dart';

/// Helper class para hacer el diseño responsivo
class ResponsiveHelper {
  /// Obtiene el ancho de la pantalla
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Obtiene la altura de la pantalla
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Obtiene el padding horizontal responsivo
  static double horizontalPadding(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return 12.0; // Pantallas muy pequeñas
    } else if (width < 600) {
      return 16.0; // Pantallas pequeñas (móviles)
    } else if (width < 900) {
      return 24.0; // Tablets pequeñas
    } else {
      return 32.0; // Tablets grandes
    }
  }

  /// Obtiene el padding vertical responsivo
  static double verticalPadding(BuildContext context) {
    final height = screenHeight(context);
    if (height < 600) {
      return 12.0; // Pantallas muy pequeñas
    } else if (height < 800) {
      return 16.0; // Pantallas pequeñas
    } else {
      return 20.0; // Pantallas normales y grandes
    }
  }

  /// Obtiene el spacing entre elementos responsivo
  static double spacing(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return 12.0;
    } else if (width < 600) {
      return 16.0;
    } else {
      return 20.0;
    }
  }

  /// Obtiene el tamaño de fuente del título responsivo
  static double titleFontSize(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return 22.0;
    } else if (width < 600) {
      return 26.0;
    } else {
      return 28.0;
    }
  }

  /// Obtiene el tamaño de fuente del subtítulo responsivo
  static double subtitleFontSize(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return 14.0;
    } else if (width < 600) {
      return 15.0;
    } else {
      return 16.0;
    }
  }

  /// Obtiene el tamaño de fuente del cuerpo responsivo
  static double bodyFontSize(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return 13.0;
    } else if (width < 600) {
      return 14.0;
    } else {
      return 16.0;
    }
  }

  /// Obtiene el tamaño del ícono responsivo
  static double iconSize(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return 20.0;
    } else if (width < 600) {
      return 24.0;
    } else {
      return 28.0;
    }
  }

  /// Verifica si es una pantalla pequeña
  static bool isSmallScreen(BuildContext context) {
    return screenWidth(context) < 360;
  }

  /// Verifica si es una pantalla mediana
  static bool isMediumScreen(BuildContext context) {
    final width = screenWidth(context);
    return width >= 360 && width < 600;
  }

  /// Verifica si es una pantalla grande (tablet)
  static bool isLargeScreen(BuildContext context) {
    return screenWidth(context) >= 600;
  }

  /// Obtiene el número de columnas para GridView responsivo
  static int gridCrossAxisCount(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return 1;
    } else if (width < 600) {
      return 2;
    } else if (width < 900) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Obtiene el ancho máximo del contenido para centrarlo en pantallas grandes
  static double? maxContentWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width >= 600) {
      return 600.0; // Limitar ancho en tablets
    }
    return null; // Sin límite en móviles
  }

  /// Obtiene el padding del formulario responsivo
  static EdgeInsets formPadding(BuildContext context) {
    final hPadding = horizontalPadding(context);
    final vPadding = verticalPadding(context);
    return EdgeInsets.symmetric(
      horizontal: hPadding,
      vertical: vPadding,
    );
  }

  /// Obtiene el spacing entre campos del formulario
  static double formFieldSpacing(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return 12.0;
    } else if (width < 600) {
      return 16.0;
    } else {
      return 20.0;
    }
  }
}

