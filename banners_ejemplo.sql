-- ============================================================================
-- SCRIPT DE EJEMPLO: Insertar Banners para Sánchez Pharma
-- ============================================================================
-- Este archivo contiene ejemplos de banners que puedes insertar en tu base de datos
-- para comenzar a probar la funcionalidad de banners promocionales.
-- 
-- IMPORTANTE: 
-- 1. Reemplaza las URLs de imagen con URLs reales de imágenes que hayas subido
-- 2. Puedes usar servicios gratuitos como ImgBB (imgbb.com) o Imgur (imgur.com)
-- 3. Las imágenes deben tener un tamaño recomendado de 1200x400 píxeles
-- ============================================================================

-- Crear la tabla de banners (si no existe)
CREATE TABLE IF NOT EXISTS banners (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    descripcion TEXT,
    imagen_url VARCHAR(500) NOT NULL,
    enlace VARCHAR(500),
    orden INT DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE,
    fecha_inicio DATETIME,
    fecha_fin DATETIME,
    fecha_creacion DATETIME DEFAULT NOW(),
    fecha_actualizacion DATETIME DEFAULT NOW() ON UPDATE NOW(),
    INDEX idx_activo (activo),
    INDEX idx_orden (orden)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- BANNERS DE EJEMPLO
-- ============================================================================

-- Banner 1: Promoción de Inka Days (como en la imagen)
-- NOTA: La URL debe ser una URL DIRECTA de imagen (debe terminar en .jpg, .png, etc.)
-- Ejemplo de ImgBB: https://i.ibb.co/xxxxx/imagen.jpg (NO https://ibb.co/xxxxx)
INSERT INTO banners (titulo, descripcion, imagen_url, enlace, orden, activo) 
VALUES (
    'INKA DAYS - BabyLac Pro 3',
    'Promoción especial de BabyLac Lata de 1.8 kg. Precio especial S/ 105.90 por lata',
    'https://i.ibb.co/XfHJdzzX/banner.jpg',  -- REEMPLAZAR con URL DIRECTA (debe incluir /nombre.jpg)
    NULL,
    1,
    TRUE
);

-- Banner 2: Promoción de Cupón INKA30
INSERT INTO banners (titulo, descripcion, imagen_url, enlace, orden, activo) 
VALUES (
    'Cupón INKA30 - Paga S/ 30',
    'Usa tu cupón INKA30 y paga solo S/ 30. Válido hasta agotar stock.',
    'https://i.ibb.co/ejemplo2.jpg',  -- REEMPLAZAR con URL real
    NULL,
    2,
    TRUE
);

-- Banner 3: Ofertas de Vitaminas
INSERT INTO banners (titulo, descripcion, imagen_url, enlace, orden, activo) 
VALUES (
    'Ofertas en Vitaminas',
    'Descuentos especiales en vitaminas y suplementos. ¡No te lo pierdas!',
    'https://i.ibb.co/ejemplo3.jpg',  -- REEMPLAZAR con URL real
    NULL,
    3,
    TRUE
);

-- Banner 4: Medicamentos para el Resfriado
INSERT INTO banners (titulo, descripcion, imagen_url, enlace, orden, activo) 
VALUES (
    'Protégete del Resfriado',
    'Encuentra los mejores medicamentos para combatir el resfriado común',
    'https://i.ibb.co/ejemplo4.jpg',  -- REEMPLAZAR con URL real
    NULL,
    4,
    TRUE
);

-- Banner 5: Cuidado Personal
INSERT INTO banners (titulo, descripcion, imagen_url, enlace, orden, activo) 
VALUES (
    'Cuidado Personal Premium',
    'Productos de cuidado personal de las mejores marcas',
    'https://i.ibb.co/ejemplo5.jpg',  -- REEMPLAZAR con URL real
    NULL,
    5,
    TRUE
);

-- ============================================================================
-- VERIFICAR BANNERS INSERTADOS
-- ============================================================================
SELECT * FROM banners ORDER BY orden;

-- ============================================================================
-- COMANDOS ÚTILES PARA GESTIONAR BANNERS
-- ============================================================================

-- Ver solo banners activos
-- SELECT * FROM banners WHERE activo = TRUE ORDER BY orden;

-- Desactivar un banner
-- UPDATE banners SET activo = FALSE WHERE id = 1;

-- Activar un banner
-- UPDATE banners SET activo = TRUE WHERE id = 1;

-- Cambiar el orden de un banner
-- UPDATE banners SET orden = 10 WHERE id = 1;

-- Eliminar un banner
-- DELETE FROM banners WHERE id = 1;

-- Eliminar todos los banners (¡CUIDADO!)
-- DELETE FROM banners;

-- ============================================================================
-- NOTAS IMPORTANTES
-- ============================================================================

/*
📸 CÓMO SUBIR IMÁGENES Y OBTENER URLs:

Opción 1: ImgBB (Recomendado - Gratis)
1. Ve a https://imgbb.com
2. Haz clic en "Start uploading"
3. Sube tu imagen (formato JPG o PNG)
4. Copia la "Direct link" que te dan
5. Pégala en el campo imagen_url

Opción 2: Imgur (Gratis)
1. Ve a https://imgur.com
2. Haz clic en "New post"
3. Sube tu imagen
4. Click derecho en la imagen > "Copiar dirección de imagen"
5. Pégala en el campo imagen_url

Opción 3: Cloudinary (Profesional)
1. Crea una cuenta gratuita en cloudinary.com
2. Sube tus imágenes
3. Copia la URL pública
4. Pégala en el campo imagen_url

📏 TAMAÑOS RECOMENDADOS DE IMÁGENES:
- Ancho: 1200px - 1600px
- Alto: 400px - 600px
- Ratio: 3:1 o 16:9
- Formato: JPG o PNG
- Peso: Menos de 500KB (optimizado)

🎨 DISEÑO DE BANNERS:
- Usa colores llamativos
- Texto grande y legible
- Imágenes de alta calidad
- Llamado a la acción claro
- Marca visible

📅 FECHAS DE INICIO Y FIN:
- fecha_inicio: Cuándo se empieza a mostrar
- fecha_fin: Cuándo deja de mostrarse
- Si son NULL, el banner se muestra siempre (mientras esté activo)

🔢 ORDEN:
- Los banners se muestran de menor a mayor orden
- Ejemplo: orden 1 aparece primero, orden 2 después, etc.

✅ ESTADO ACTIVO:
- activo = TRUE: Se muestra en la app
- activo = FALSE: No se muestra (útil para pausar temporalmente)
*/

