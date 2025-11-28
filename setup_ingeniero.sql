-- =====================================================
-- SCRIPT: Configuración del Rol Ingeniero
-- Base de datos: nxlsxx$PAF (Sánchez Pharma)
-- =====================================================

-- =====================================================
-- 1. CREAR ROL INGENIERO (ID 6)
-- =====================================================
INSERT INTO roles (id, nombre, descripcion)
SELECT 6, 'Ingeniero', 'Rol con todos los permisos de Administrador y acceso exclusivo a Backups'
WHERE NOT EXISTS (
    SELECT 1 FROM roles WHERE id = 6 OR nombre = 'Ingeniero'
);

-- =====================================================
-- 2. VERIFICAR ROL CREADO
-- =====================================================
SELECT '===== ROL INGENIERO CREADO =====' AS '';
SELECT * FROM roles WHERE id = 6 OR nombre = 'Ingeniero';

-- =====================================================
-- 3. CREAR TABLA PARA HISTORIAL DE BACKUPS (OPCIONAL)
-- =====================================================
CREATE TABLE IF NOT EXISTS backups_historial (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo VARCHAR(50) NOT NULL COMMENT 'Tipo de backup: bd, archivos, completo',
    nombre_archivo VARCHAR(255) NOT NULL,
    ruta_archivo VARCHAR(500) NOT NULL,
    tamano_bytes BIGINT,
    usuario_id INT,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'completado' COMMENT 'completado, error, en_proceso',
    observaciones TEXT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    INDEX idx_fecha_creacion (fecha_creacion),
    INDEX idx_tipo (tipo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 4. VERIFICAR TABLA CREADA
-- =====================================================
SELECT '===== TABLA BACKUPS_HISTORIAL CREADA =====' AS '';
SHOW CREATE TABLE backups_historial;

