-- ============================================================
-- EJEMPLO: Crear cliente de prueba para testing
-- ============================================================

-- Opción 1: Cliente con contraseña en texto plano (solo para pruebas)
INSERT INTO clientes (nombre, apellido, email, documento, password, estado)
VALUES (
    'Juan', 
    'Pérez', 
    'juan.perez@example.com', 
    '12345678', 
    'password123',  -- Contraseña en texto plano
    'activo'
);

-- Opción 2: Cliente con contraseña hasheada (SHA256) - RECOMENDADO
INSERT INTO clientes (nombre, apellido, email, documento, password, estado)
VALUES (
    'María', 
    'González', 
    'maria.gonzalez@example.com', 
    '87654321', 
    SHA2('password123', 256),  -- Contraseña hasheada
    'activo'
);

-- ============================================================
-- Verificar cliente creado
-- ============================================================
-- SELECT id, nombre, email, documento, estado FROM clientes WHERE email = 'juan.perez@example.com';

-- ============================================================
-- Actualizar contraseña de cliente existente
-- ============================================================
-- UPDATE clientes 
-- SET password = SHA2('nuevaPassword123', 256)
-- WHERE email = 'juan.perez@example.com';

-- ============================================================
-- Crear múltiples clientes de prueba
-- ============================================================
INSERT INTO clientes (nombre, email, documento, password, estado) VALUES
('Cliente 1', 'cliente1@test.com', '11111111', SHA2('pass123', 256), 'activo'),
('Cliente 2', 'cliente2@test.com', '22222222', SHA2('pass123', 256), 'activo'),
('Cliente 3', 'cliente3@test.com', '33333333', SHA2('pass123', 256), 'activo');

