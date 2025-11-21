-- ============================================================
-- AGREGAR CAMPO PASSWORD A LA TABLA CLIENTES
-- ============================================================
-- Ejecuta este script en tu base de datos MySQL
-- ============================================================

-- Agregar campo password a la tabla clientes
ALTER TABLE clientes 
ADD COLUMN password VARCHAR(255) AFTER email;

-- Verificar que se agregó correctamente
DESCRIBE clientes;

-- ============================================================
-- OPCIONAL: Crear cliente de prueba
-- ============================================================
-- INSERT INTO clientes (nombre, email, documento, password, estado)
-- VALUES ('Cliente Test', 'test@example.com', '12345678', 'password123', 'activo');

