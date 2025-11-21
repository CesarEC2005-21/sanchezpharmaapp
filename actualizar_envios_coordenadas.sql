-- ============================================================
-- ACTUALIZAR TABLA ENVÍOS PARA INCLUIR COORDENADAS GPS
-- ============================================================

-- Agregar columnas de latitud y longitud a la tabla envios
ALTER TABLE envios
ADD COLUMN latitud_destino DECIMAL(10, 8) NULL AFTER direccion_entrega,
ADD COLUMN longitud_destino DECIMAL(11, 8) NULL AFTER latitud_destino,
ADD COLUMN latitud_repartidor DECIMAL(10, 8) NULL AFTER longitud_destino,
ADD COLUMN longitud_repartidor DECIMAL(11, 8) NULL AFTER latitud_repartidor,
ADD INDEX idx_coordenadas_destino (latitud_destino, longitud_destino),
ADD INDEX idx_coordenadas_repartidor (latitud_repartidor, longitud_repartidor);

-- Comentarios para documentación
ALTER TABLE envios
MODIFY COLUMN latitud_destino DECIMAL(10, 8) NULL COMMENT 'Latitud del destino de entrega',
MODIFY COLUMN longitud_destino DECIMAL(11, 8) NULL COMMENT 'Longitud del destino de entrega',
MODIFY COLUMN latitud_repartidor DECIMAL(10, 8) NULL COMMENT 'Latitud actual del repartidor (se actualiza en tiempo real)',
MODIFY COLUMN longitud_repartidor DECIMAL(11, 8) NULL COMMENT 'Longitud actual del repartidor (se actualiza en tiempo real)';

-- ============================================================
-- ACTUALIZAR VISTA PARA INCLUIR COORDENADAS
-- ============================================================

DROP VIEW IF EXISTS vista_envios_completa;

CREATE OR REPLACE VIEW vista_envios_completa AS
SELECT 
    e.id,
    e.venta_id,
    e.numero_seguimiento,
    e.direccion_entrega,
    e.latitud_destino,
    e.longitud_destino,
    e.latitud_repartidor,
    e.longitud_repartidor,
    e.telefono_contacto,
    e.nombre_destinatario,
    e.referencia_direccion,
    e.fecha_estimada_entrega,
    e.fecha_real_entrega,
    e.conductor_repartidor,
    e.costo_envio,
    e.estado,
    e.observaciones,
    e.fecha_creacion,
    e.fecha_actualizacion,
    v.numero_venta,
    v.fecha_venta,
    v.total,
    c.nombre AS cliente_nombre,
    c.telefono AS cliente_telefono
FROM envios e
LEFT JOIN ventas v ON e.venta_id = v.id
LEFT JOIN clientes c ON v.cliente_id = c.id;

