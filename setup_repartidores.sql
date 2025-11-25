-- =====================================================
-- SCRIPT: Configuración de Repartidores
-- Base de datos: nxlsxx$PAF (Sánchez Pharma)
-- =====================================================

-- =====================================================
-- 1. VERIFICAR ROLES EXISTENTES
-- =====================================================
SELECT '===== ROLES ACTUALES =====' AS '';
SELECT * FROM roles;

-- =====================================================
-- 2. VERIFICAR REPARTIDORES EXISTENTES
-- =====================================================
SELECT '===== REPARTIDORES ACTUALES (rol_id = 4) =====' AS '';
SELECT id, username, email, nombre, apellido, edad, sexo, rol_id 
FROM usuarios 
WHERE rol_id = 4;

-- =====================================================
-- 3. CREAR REPARTIDORES DE PRUEBA (SI NO EXISTEN)
-- =====================================================

-- Repartidor 1
INSERT INTO usuarios (username, password, email, nombre, apellido, edad, sexo, rol_id)
SELECT 'repartidor1', '123456', 'repartidor1@sanchezpharma.com', 'Carlos', 'Mendoza', 28, 'M', 4
WHERE NOT EXISTS (
    SELECT 1 FROM usuarios WHERE username = 'repartidor1'
);

-- Repartidor 2
INSERT INTO usuarios (username, password, email, nombre, apellido, edad, sexo, rol_id)
SELECT 'repartidor2', '123456', 'repartidor2@sanchezpharma.com', 'María', 'Torres', 26, 'F', 4
WHERE NOT EXISTS (
    SELECT 1 FROM usuarios WHERE username = 'repartidor2'
);

-- Repartidor 3
INSERT INTO usuarios (username, password, email, nombre, apellido, edad, sexo, rol_id)
SELECT 'repartidor3', '123456', 'repartidor3@sanchezpharma.com', 'Luis', 'García', 30, 'M', 4
WHERE NOT EXISTS (
    SELECT 1 FROM usuarios WHERE username = 'repartidor3'
);

-- =====================================================
-- 4. VERIFICAR VENDEDORES EXISTENTES
-- =====================================================
SELECT '===== VENDEDORES ACTUALES (rol_id = 3) =====' AS '';
SELECT id, username, email, nombre, apellido, rol_id 
FROM usuarios 
WHERE rol_id = 3;

-- =====================================================
-- 5. VERIFICAR ADMINISTRADORES EXISTENTES
-- =====================================================
SELECT '===== ADMINISTRADORES ACTUALES (rol_id = 1) =====' AS '';
SELECT id, username, email, nombre, apellido, rol_id 
FROM usuarios 
WHERE rol_id = 1;

-- =====================================================
-- 6. CREAR USUARIO VENDEDOR DE PRUEBA (SI NO EXISTE)
-- =====================================================
INSERT INTO usuarios (username, password, email, nombre, apellido, edad, sexo, rol_id)
SELECT 'vendedor1', '123456', 'vendedor1@sanchezpharma.com', 'Ana', 'López', 32, 'F', 3
WHERE NOT EXISTS (
    SELECT 1 FROM usuarios WHERE username = 'vendedor1'
);

-- =====================================================
-- 7. VERIFICAR ENVÍOS SIN REPARTIDOR ASIGNADO
-- =====================================================
SELECT '===== ENVÍOS DISPONIBLES PARA ASIGNAR REPARTIDOR =====' AS '';
SELECT id, numero_seguimiento, estado, conductor_repartidor, direccion_entrega
FROM envios
WHERE estado IN ('pendiente', 'preparando')
  AND (conductor_repartidor IS NULL OR conductor_repartidor = '')
LIMIT 10;

-- =====================================================
-- 8. VERIFICAR ESTRUCTURA DE LA TABLA ENVÍOS
-- =====================================================
SELECT '===== ESTRUCTURA TABLA ENVIOS =====' AS '';
DESCRIBE envios;

-- =====================================================
-- 9. RESUMEN FINAL
-- =====================================================
SELECT '===== RESUMEN FINAL =====' AS '';
SELECT 
    'Administradores' AS tipo_usuario,
    COUNT(*) AS cantidad
FROM usuarios WHERE rol_id = 1
UNION ALL
SELECT 
    'Vendedores' AS tipo_usuario,
    COUNT(*) AS cantidad
FROM usuarios WHERE rol_id = 3
UNION ALL
SELECT 
    'Repartidores' AS tipo_usuario,
    COUNT(*) AS cantidad
FROM usuarios WHERE rol_id = 4
UNION ALL
SELECT 
    'Almacén' AS tipo_usuario,
    COUNT(*) AS cantidad
FROM usuarios WHERE rol_id = 5;

-- =====================================================
-- NOTAS IMPORTANTES:
-- =====================================================
-- 1. Todos los usuarios de prueba tienen password: 123456
-- 2. Los usuarios solo se crean si NO existen previamente
-- 3. Para usar este script en producción, cambia las contraseñas
-- 4. Los repartidores deben tener rol_id = 4
-- 5. Los vendedores deben tener rol_id = 3
-- 6. Los administradores tienen rol_id = 1
-- =====================================================

