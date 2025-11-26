# 🎨 Gestión de Banners Promocionales - Sánchez Pharma

## ✅ ¿Qué se ha Implementado?

Se ha agregado un sistema completo de banners promocionales que permite:

- ✅ **Carrusel automático** de banners en la pantalla de inicio del cliente
- ✅ **Gestión desde la app** (pantalla administrativa)
- ✅ **Banners con imágenes desde URLs**
- ✅ **Activar/Desactivar banners** sin eliminarlos
- ✅ **Ordenar banners** por prioridad
- ✅ **Vista previa** de imágenes en la app

---

## 📱 Cómo Usar desde la App

### 1. Acceder a la Gestión de Banners

1. **Inicia sesión** como Administrador
2. En el **Dashboard**, verás una nueva tarjeta rosa llamada **"Banners"**
3. Haz clic en ella para acceder a la pantalla de gestión

### 2. Crear un Nuevo Banner

1. En la pantalla de Banners, haz clic en el botón **"+ Nuevo Banner"** (botón flotante verde)
2. Llena el formulario:
   - **Título**: Nombre del banner (ej: "INKA DAYS - BabyLac Pro 3")
   - **Descripción** (opcional): Detalles adicionales
   - **URL de Imagen**: ⚠️ **IMPORTANTE** - Aquí pegas la URL de tu imagen
   - **Enlace** (opcional): Si quieres que redirija a algún lugar al hacer clic
   - **Orden**: Número para ordenar (1 aparece primero, 2 después, etc.)
   - **Banner Activo**: Switch para activar/desactivar

3. **Ver vista previa**: Mientras escribes la URL, verás una vista previa arriba
4. Haz clic en **"Crear"**

### 3. Editar un Banner

1. En la lista de banners, busca el que quieres editar
2. Haz clic en el botón **"Editar"**
3. Modifica los campos que necesites
4. Haz clic en **"Guardar"**

### 4. Activar/Desactivar un Banner

- Usa el **switch** en cada tarjeta de banner
- Los banners desactivados **NO se mostrarán** en la app del cliente

### 5. Eliminar un Banner

1. Haz clic en el botón **"Eliminar"** (rojo)
2. Confirma la acción
3. El banner se eliminará permanentemente

---

## 📸 Cómo Subir Imágenes

### Opción 1: ImgBB (Recomendado - Gratis y Fácil)

1. Ve a **https://imgbb.com**
2. Haz clic en **"Start uploading"**
3. **Sube tu imagen** (arrastra o selecciona)
4. Espera a que se suba
5. Copia la **"Direct link"** (URL que termina en .jpg o .png)
6. **Pégala en tu app** en el campo "URL de Imagen"

### Opción 2: Imgur (Gratis)

1. Ve a **https://imgur.com**
2. Haz clic en **"New post"**
3. Sube tu imagen
4. Click derecho en la imagen > **"Copiar dirección de imagen"**
5. Pégala en tu app

### Opción 3: Google Drive (Si ya tienes imágenes allí)

⚠️ **No recomendado** - Google Drive no permite enlaces directos fácilmente.
Mejor usa ImgBB o Imgur.

---

## 🎨 Recomendaciones para Imágenes de Banners

### Tamaños Recomendados

- **Ancho**: 1200px - 1600px
- **Alto**: 400px - 600px
- **Ratio**: 3:1 o 16:9 (formato horizontal)
- **Formato**: JPG o PNG
- **Peso**: Menos de 500KB (optimizado para carga rápida)

### Herramientas para Crear Banners

1. **Canva** (canva.com) - Gratis y fácil
2. **Adobe Express** - Gratis
3. **Figma** - Profesional y gratis
4. **Photoshop** - Si tienes experiencia

### Consejos de Diseño

✅ **Haz esto:**
- Usa colores llamativos y contrastantes
- Texto grande y legible
- Imágenes de alta calidad
- Llamado a la acción claro ("¡Compra ahora!", "Oferta limitada", etc.)
- Logo de tu farmacia visible

❌ **Evita esto:**
- Texto muy pequeño
- Muchos elementos (mantén simple)
- Imágenes borrosas o de baja calidad
- Demasiado texto

---

## 🗄️ Insertar Banners desde la Base de Datos (Alternativa)

Si prefieres insertar banners directamente en la base de datos:

1. Abre el archivo **`banners_ejemplo.sql`**
2. **Reemplaza las URLs de ejemplo** con tus URLs reales
3. Ejecuta el script SQL en tu base de datos MySQL

```sql
-- Ejemplo de inserción
INSERT INTO banners (titulo, descripcion, imagen_url, enlace, orden, activo) 
VALUES (
    'INKA DAYS - BabyLac Pro 3',
    'Promoción especial',
    'https://i.ibb.co/TU_URL_AQUI.jpg',  -- TU URL AQUÍ
    NULL,
    1,
    TRUE
);
```

---

## 🔄 Cómo Funciona el Carrusel

En la pantalla de inicio del cliente:

- Los banners se muestran en un **carrusel horizontal**
- **Cambia automáticamente** cada 5 segundos
- Los clientes pueden **deslizar manualmente** para ver otros banners
- Los **puntos indicadores** (abajo) muestran qué banner está activo
- Solo se muestran banners **activos**
- Se ordenan según el campo **"orden"** (de menor a mayor)

---

## 🐛 Solución de Problemas

### "No veo ningún banner en la app del cliente"

✅ **Soluciones:**
1. Verifica que hayas **creado al menos un banner** desde el dashboard
2. Asegúrate de que el banner esté **ACTIVO** (switch verde)
3. Verifica que la **URL de la imagen** sea correcta y accesible
4. **Reinicia la app** del cliente (cierra y abre de nuevo)
5. Verifica tu conexión a internet

### "La imagen del banner no se carga"

✅ **Soluciones:**
1. Verifica que la URL sea una **URL directa** a la imagen (debe terminar en .jpg, .png, etc.)
2. Prueba abrir la URL en tu navegador - ¿se ve la imagen?
3. Usa **ImgBB o Imgur** - son más confiables
4. Verifica que la imagen no esté en un servicio que requiera autenticación

### "Los banners no están en el orden correcto"

✅ **Solución:**
- Edita cada banner y cambia el campo **"Orden"**
- Los banners con **número menor** aparecen primero
- Ejemplo: orden 1, orden 2, orden 3...

---

## 📊 Ejemplos de URLs de Banners

Aquí hay algunos ejemplos de banners que puedes crear:

### 1. Promoción de Productos
```
Título: "Promoción 2x1 en Vitaminas"
Descripción: "Compra 2 y lleva 3 - Solo por hoy"
URL: [Tu imagen subida en ImgBB]
Orden: 1
```

### 2. Descuento por Temporada
```
Título: "Descuento de Invierno - 30% OFF"
Descripción: "En medicamentos para el resfriado"
URL: [Tu imagen subida en ImgBB]
Orden: 2
```

### 3. Nuevos Productos
```
Título: "Nuevos Productos Naturales"
Descripción: "Conoce nuestra nueva línea natural"
URL: [Tu imagen subida en ImgBB]
Orden: 3
```

---

## 🎯 Próximos Pasos Recomendados

1. **Crea 3-5 banners** para empezar
2. **Prueba el carrusel** en la app del cliente
3. **Actualiza los banners** según tus promociones activas
4. **Monitorea** cuáles banners generan más interés
5. **Rota los banners** regularmente para mantener contenido fresco

---

## 📞 Notas Finales

- Los banners se **cargan automáticamente** cuando el cliente abre la app
- No es necesario que los clientes actualicen la app
- Puedes tener **tantos banners como quieras**, pero se recomienda 3-7 activos
- Los banners **desactivados** se guardan y puedes reactivarlos cuando quieras
- El **orden** es flexible - puedes cambiarlo cuando quieras

---

**¡Listo! Ya tienes todo configurado para usar banners promocionales en tu app.** 🎉

Si tienes problemas, revisa la sección "Solución de Problemas" o verifica que los endpoints estén funcionando correctamente en el backend.

