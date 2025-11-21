-- ============================================================
-- ACTUALIZAR TRIGGER: crear_envio_automatico
-- ============================================================
-- Este script actualiza el trigger para que no cause conflictos
-- si el backend crea el envío primero

-- Eliminar el trigger existente
DROP TRIGGER IF EXISTS crear_envio_automatico;

-- Crear el trigger actualizado
DELIMITER //
CREATE TRIGGER crear_envio_automatico
AFTER INSERT ON ventas
FOR EACH ROW
BEGIN
    IF NEW.tipo_venta = 'envio_domicilio' THEN
        -- Solo crear si no existe ya (el backend puede haberlo creado primero)
        IF NOT EXISTS (SELECT 1 FROM envios WHERE venta_id = NEW.id) THEN
            INSERT INTO envios (
                venta_id,
                numero_seguimiento,
                estado,
                fecha_creacion
            ) VALUES (
                NEW.id,
                CONCAT('ENV-', NEW.id, '-', DATE_FORMAT(NOW(), '%Y%m%d')),
                'pendiente',
                NOW()
            );
        END IF;
    END IF;
END//
DELIMITER ;

-- Verificar que el trigger se creó correctamente
SHOW TRIGGERS LIKE 'crear_envio_automatico';

