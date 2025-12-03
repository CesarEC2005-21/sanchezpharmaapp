-- Script de migración para separar nombres y apellidos en la tabla clientes
-- Ejecutar este script en MySQL para actualizar la estructura de la tabla

USE sanchezpharma;

-- Paso 1: Agregar las nuevas columnas
ALTER TABLE clientes 
ADD COLUMN nombres VARCHAR(100) NULL AFTER nombre,
ADD COLUMN apellido_paterno VARCHAR(100) NULL AFTER nombres,
ADD COLUMN apellido_materno VARCHAR(100) NULL AFTER apellido_paterno;

-- Paso 2: Migrar datos existentes
-- Intentar separar nombre y apellido en nombres, apellido_paterno y apellido_materno
-- Si el apellido contiene espacios, asumimos que el primero es paterno y el segundo materno
UPDATE clientes 
SET 
    nombres = CASE 
        WHEN nombre IS NOT NULL AND nombre != '' THEN nombre 
        ELSE NULL 
    END,
    apellido_paterno = CASE 
        WHEN apellido IS NOT NULL AND apellido != '' THEN 
            CASE 
                WHEN LOCATE(' ', apellido) > 0 THEN SUBSTRING_INDEX(apellido, ' ', 1)
                ELSE apellido
            END
        ELSE NULL 
    END,
    apellido_materno = CASE 
        WHEN apellido IS NOT NULL AND apellido != '' AND LOCATE(' ', apellido) > 0 THEN 
            SUBSTRING(apellido, LOCATE(' ', apellido) + 1)
        ELSE NULL 
    END
WHERE nombres IS NULL OR apellido_paterno IS NULL;

-- Paso 3: Hacer las nuevas columnas NOT NULL (opcional, solo si quieres que sean obligatorias)
-- ALTER TABLE clientes MODIFY COLUMN nombres VARCHAR(100) NOT NULL;
-- ALTER TABLE clientes MODIFY COLUMN apellido_paterno VARCHAR(100) NOT NULL;

-- Paso 4: Eliminar las columnas antiguas (descomentar cuando estés seguro de que todo funciona)
-- ALTER TABLE clientes DROP COLUMN nombre;
-- ALTER TABLE clientes DROP COLUMN apellido;

-- Verificar los datos migrados
SELECT id, nombre, apellido, nombres, apellido_paterno, apellido_materno 
FROM clientes 
LIMIT 10;

