-- ============================================================
-- ALTER TABLE: Agregar campo password a la tabla clientes
-- ============================================================
-- Este script agrega el campo 'password' necesario para 
-- que los clientes puedan iniciar sesión
-- ============================================================

-- Verificar si el campo ya existe antes de agregarlo
-- (Para evitar errores si se ejecuta múltiples veces)

-- Opción 1: Agregar campo password (si no existe)
ALTER TABLE clientes 
ADD COLUMN IF NOT EXISTS password VARCHAR(255) AFTER email;

-- Si tu versión de MySQL no soporta IF NOT EXISTS, usa:
-- ALTER TABLE clientes 
-- ADD COLUMN password VARCHAR(255) AFTER email;

-- ============================================================
-- OPCIONAL: Agregar índice para mejorar búsquedas de login
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_cliente_login ON clientes(email, documento);

-- ============================================================
-- OPCIONAL: Actualizar clientes existentes con contraseña temporal
-- ============================================================
-- Descomenta y modifica según necesites:

-- UPDATE clientes 
-- SET password = SHA2(CONCAT(documento, 'temp123'), 256)
-- WHERE password IS NULL OR password = '';

-- O si prefieres contraseña en texto plano (NO RECOMENDADO):
-- UPDATE clientes 
-- SET password = CONCAT('temp_', documento)
-- WHERE password IS NULL OR password = '';

-- ============================================================
-- VERIFICACIÓN: Ver estructura de la tabla
-- ============================================================
-- DESCRIBE clientes;

-- ============================================================
-- EJEMPLO: Insertar cliente de prueba con contraseña
-- ============================================================
-- INSERT INTO clientes (nombre, email, documento, password, estado)
-- VALUES ('Cliente Test', 'test@example.com', '12345678', SHA2('password123', 256), 'activo');

-- ============================================================
-- NOTAS:
-- ============================================================
-- 1. El campo password puede almacenar:
--    - Texto plano (NO RECOMENDADO para producción)
--    - Hash SHA256 (RECOMENDADO)
--    - Hash bcrypt (MÁS SEGURO, requiere librería en Python)
--
-- 2. Para usar SHA256 en Python:
--    import hashlib
--    password_hash = hashlib.sha256(password.encode()).hexdigest()
--
-- 3. Para verificar contraseña:
--    SELECT * FROM clientes 
--    WHERE email = 'test@example.com' 
--    AND password = SHA2('password123', 256);

