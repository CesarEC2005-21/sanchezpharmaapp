# 🎨 Guía de Diseño de Modales - Sánchez Pharma

## Colores Corporativos

### Paleta Principal
- **Verde Principal**: `#2E7D32` - Color corporativo principal
- **Verde Oscuro**: `#1B5E20` - Para degradados y sombras
- **Verde Claro**: `#4CAF50` - Para acentos
- **Blanco**: Para texto en headers

### Aplicación
- **Headers**: Degradado de Verde Claro a Verde Principal
- **Iconos**: Verde Principal con fondo blanco semitransparente
- **Botones Primarios**: Verde Principal (#2E7D32)
- **Campos de texto**: Borde Verde Principal al enfocarse

## Estructura del Modal

```
┌─────────────────────────────────────────┐
│ [📋] Título del Modal           [X]     │ ← Header verde degradado
├─────────────────────────────────────────┤
│                                         │
│ 🔹 Sección 1                           │ ← Títulos de sección
│ ─────────────────────────────          │
│ [Campo 1]                              │
│ [Campo 2]                              │
│                                         │
│ 🔹 Sección 2                           │
│ ─────────────────────────────          │
│ [Campo 3]                              │
│ [Campo 4]                              │
│                                         │
├─────────────────────────────────────────┤
│           [Cancelar] [✓ Guardar]       │ ← Footer gris claro
└─────────────────────────────────────────┘
```

## Componentes Clave

### 1. `CustomModalDialog` - Modal Base
- Borde redondeado (16px)
- Header con degradado verde corporativo
- Footer con fondo gris claro
- Elevación de 8 para sombra profesional

### 2. `ModalSectionBuilder.buildSectionTitle()` - Títulos de Sección
- Icono verde + título en negrita
- Línea divisora verde clara
- Espaciado consistente

### 3. `ModalSectionBuilder.buildTextField()` - Campos de Texto
- Bordes redondeados (12px)
- Icono prefijo en verde
- Fondo gris muy claro
- Borde verde al enfocarse

### 4. `ModalSectionBuilder.buildButton()` - Botones
- Primario: Verde con texto blanco
- Secundario: Gris con borde
- Bordes redondeados (10px)
- Iconos integrados

## Ejemplos Completos

Ver archivos de implementación actualizados para cada módulo.

---
**Sánchez Pharma** - Sistema de Gestión Farmacéutica
Versión 1.0.0

