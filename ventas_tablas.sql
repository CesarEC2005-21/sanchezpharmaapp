-- ============================================================
-- SCRIPT SQL PARA CREAR TABLAS DE VENTAS Y ENVÍOS
-- Base de datos: Sánchez Pharma
-- ============================================================

-- ------------------------------------------------------------
-- TABLA: clientes
-- Almacena información de los clientes
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    apellido VARCHAR(200),
    documento VARCHAR(50) UNIQUE,
    tipo_documento ENUM('DNI', 'RUC', 'PASAPORTE', 'OTRO') DEFAULT 'DNI',
    telefono VARCHAR(20),
    email VARCHAR(100),
    direccion VARCHAR(255),
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('activo', 'inactivo') DEFAULT 'activo',
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_documento (documento),
    INDEX idx_nombre (nombre),
    INDEX idx_estado (estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- TABLA: metodos_pago
-- Define los métodos de pago disponibles
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS metodos_pago (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    estado ENUM('activo', 'inactivo') DEFAULT 'activo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- TABLA: ventas
-- Almacena el encabezado de las ventas
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    numero_venta VARCHAR(50) UNIQUE,
    cliente_id INT,
    usuario_id INT NOT NULL,
    tipo_venta ENUM('recojo_tienda', 'envio_domicilio') NOT NULL,
    metodo_pago_id INT,
    subtotal DECIMAL(10, 2) DEFAULT 0.00,
    descuento DECIMAL(10, 2) DEFAULT 0.00,
    impuesto DECIMAL(10, 2) DEFAULT 0.00,
    total DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    estado ENUM('pendiente', 'completada', 'cancelada', 'anulada') DEFAULT 'pendiente',
    observaciones TEXT,
    fecha_venta DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE SET NULL,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    FOREIGN KEY (metodo_pago_id) REFERENCES metodos_pago(id) ON DELETE SET NULL,
    INDEX idx_numero_venta (numero_venta),
    INDEX idx_cliente (cliente_id),
    INDEX idx_usuario (usuario_id),
    INDEX idx_fecha_venta (fecha_venta),
    INDEX idx_estado (estado),
    INDEX idx_tipo_venta (tipo_venta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- TABLA: detalle_venta
-- Almacena los productos de cada venta
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS detalle_venta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    venta_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10, 2) NOT NULL,
    descuento DECIMAL(10, 2) DEFAULT 0.00,
    subtotal DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (venta_id) REFERENCES ventas(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT,
    INDEX idx_venta (venta_id),
    INDEX idx_producto (producto_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- TABLA: envios
-- Almacena información de los envíos a domicilio
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS envios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    venta_id INT NOT NULL UNIQUE,
    numero_seguimiento VARCHAR(50) UNIQUE,
    direccion_entrega VARCHAR(255) NOT NULL,
    telefono_contacto VARCHAR(20) NOT NULL,
    nombre_destinatario VARCHAR(200) NOT NULL,
    referencia_direccion VARCHAR(255),
    fecha_estimada_entrega DATE,
    fecha_real_entrega DATETIME,
    conductor_repartidor VARCHAR(200),
    costo_envio DECIMAL(10, 2) DEFAULT 0.00,
    estado ENUM('pendiente', 'preparando', 'en_camino', 'entregado', 'cancelado') DEFAULT 'pendiente',
    observaciones TEXT,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (venta_id) REFERENCES ventas(id) ON DELETE CASCADE,
    INDEX idx_numero_seguimiento (numero_seguimiento),
    INDEX idx_venta (venta_id),
    INDEX idx_estado (estado),
    INDEX idx_fecha_estimada (fecha_estimada_entrega)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- TABLA: estados_envio
-- Historial de cambios de estado de los envíos
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS estados_envio (
    id INT AUTO_INCREMENT PRIMARY KEY,
    envio_id INT NOT NULL,
    estado_anterior VARCHAR(50),
    estado_nuevo VARCHAR(50) NOT NULL,
    observaciones TEXT,
    usuario_id INT,
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (envio_id) REFERENCES envios(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    INDEX idx_envio (envio_id),
    INDEX idx_fecha (fecha_cambio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- DATOS INICIALES (INSERTS)
-- ============================================================

-- Insertar métodos de pago básicos
INSERT INTO metodos_pago (nombre, descripcion) VALUES
('Efectivo', 'Pago en efectivo'),
('Tarjeta Débito', 'Pago con tarjeta de débito'),
('Tarjeta Crédito', 'Pago con tarjeta de crédito'),
('Transferencia Bancaria', 'Transferencia bancaria'),
('Yape', 'Pago mediante Yape'),
('Plin', 'Pago mediante Plin')
ON DUPLICATE KEY UPDATE nombre=nombre;

-- ============================================================
-- VISTAS ÚTILES
-- ============================================================

-- Vista: Ventas con información completa
CREATE OR REPLACE VIEW vista_ventas_completa AS
SELECT 
    v.id,
    v.numero_venta,
    v.fecha_venta,
    v.tipo_venta,
    v.total,
    v.estado,
    c.nombre AS cliente_nombre,
    c.apellido AS cliente_apellido,
    c.documento AS cliente_documento,
    c.telefono AS cliente_telefono,
    u.username AS usuario_nombre,
    mp.nombre AS metodo_pago_nombre,
    e.numero_seguimiento,
    e.estado AS estado_envio
FROM ventas v
LEFT JOIN clientes c ON v.cliente_id = c.id
LEFT JOIN usuarios u ON v.usuario_id = u.id
LEFT JOIN metodos_pago mp ON v.metodo_pago_id = mp.id
LEFT JOIN envios e ON v.id = e.venta_id;

-- Vista: Detalle de venta con productos
CREATE OR REPLACE VIEW vista_detalle_venta_completa AS
SELECT 
    dv.id,
    dv.venta_id,
    dv.producto_id,
    dv.cantidad,
    dv.precio_unitario,
    dv.descuento,
    dv.subtotal,
    p.nombre AS producto_nombre,
    p.codigo AS producto_codigo,
    v.numero_venta,
    v.fecha_venta
FROM detalle_venta dv
LEFT JOIN productos p ON dv.producto_id = p.id
LEFT JOIN ventas v ON dv.venta_id = v.id;

-- Vista: Envíos con información completa
CREATE OR REPLACE VIEW vista_envios_completa AS
SELECT 
    e.id,
    e.venta_id,
    e.numero_seguimiento,
    e.direccion_entrega,
    e.telefono_contacto,
    e.nombre_destinatario,
    e.fecha_estimada_entrega,
    e.fecha_real_entrega,
    e.conductor_repartidor,
    e.estado,
    e.fecha_creacion,
    v.numero_venta,
    v.fecha_venta,
    v.total,
    c.nombre AS cliente_nombre,
    c.telefono AS cliente_telefono
FROM envios e
LEFT JOIN ventas v ON e.venta_id = v.id
LEFT JOIN clientes c ON v.cliente_id = c.id;

-- Vista: Envíos pendientes
CREATE OR REPLACE VIEW vista_envios_pendientes AS
SELECT 
    e.*,
    v.numero_venta,
    v.fecha_venta,
    c.nombre AS cliente_nombre,
    c.telefono AS cliente_telefono
FROM envios e
LEFT JOIN ventas v ON e.venta_id = v.id
LEFT JOIN clientes c ON v.cliente_id = c.id
WHERE e.estado IN ('pendiente', 'preparando', 'en_camino')
ORDER BY 
    CASE e.estado
        WHEN 'pendiente' THEN 1
        WHEN 'preparando' THEN 2
        WHEN 'en_camino' THEN 3
        ELSE 4
    END,
    e.fecha_creacion ASC;

-- ============================================================
-- TRIGGERS ÚTILES
-- ============================================================

-- Trigger: Generar número de venta automáticamente
DELIMITER //
CREATE TRIGGER generar_numero_venta
BEFORE INSERT ON ventas
FOR EACH ROW
BEGIN
    IF NEW.numero_venta IS NULL OR NEW.numero_venta = '' THEN
        SET NEW.numero_venta = CONCAT('V-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(LAST_INSERT_ID() + 1, 6, '0'));
    END IF;
END//
DELIMITER ;

-- Trigger: Actualizar stock al completar venta
DELIMITER //
CREATE TRIGGER actualizar_stock_venta
AFTER INSERT ON detalle_venta
FOR EACH ROW
BEGIN
    DECLARE v_estado_venta VARCHAR(50);
    
    SELECT estado INTO v_estado_venta FROM ventas WHERE id = NEW.venta_id;
    
    IF v_estado_venta = 'completada' THEN
        UPDATE productos 
        SET stock_actual = stock_actual - NEW.cantidad,
            estado = CASE 
                WHEN stock_actual - NEW.cantidad <= 0 THEN 'agotado'
                WHEN stock_actual - NEW.cantidad <= stock_minimo THEN 'activo'
                ELSE 'activo'
            END
        WHERE id = NEW.producto_id;
    END IF;
END//
DELIMITER ;

-- Trigger: Crear envío automáticamente cuando la venta es tipo envío
-- Nota: El backend puede crear el envío con todos los datos, pero este trigger
-- asegura que siempre exista un registro de envío para ventas tipo envio_domicilio
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

-- Trigger: Registrar cambio de estado de envío
DELIMITER //
CREATE TRIGGER registrar_cambio_estado_envio
AFTER UPDATE ON envios
FOR EACH ROW
BEGIN
    IF OLD.estado != NEW.estado THEN
        INSERT INTO estados_envio (
            envio_id,
            estado_anterior,
            estado_nuevo,
            fecha_cambio
        ) VALUES (
            NEW.id,
            OLD.estado,
            NEW.estado,
            NOW()
        );
    END IF;
END//
DELIMITER ;

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS ÚTILES
-- ============================================================

-- Procedimiento: Registrar venta completa
DELIMITER //
CREATE PROCEDURE registrar_venta_completa(
    IN p_cliente_id INT,
    IN p_usuario_id INT,
    IN p_tipo_venta VARCHAR(50),
    IN p_metodo_pago_id INT,
    IN p_descuento DECIMAL(10,2),
    IN p_observaciones TEXT,
    IN p_productos JSON
)
BEGIN
    DECLARE v_venta_id INT;
    DECLARE v_subtotal DECIMAL(10,2) DEFAULT 0;
    DECLARE v_total DECIMAL(10,2) DEFAULT 0;
    DECLARE v_producto_id INT;
    DECLARE v_cantidad INT;
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_producto_subtotal DECIMAL(10,2);
    DECLARE i INT DEFAULT 0;
    DECLARE v_count INT;
    
    -- Contar productos
    SET v_count = JSON_LENGTH(p_productos);
    
    -- Calcular subtotal
    WHILE i < v_count DO
        SET v_producto_id = JSON_UNQUOTE(JSON_EXTRACT(p_productos, CONCAT('$[', i, '].producto_id')));
        SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_productos, CONCAT('$[', i, '].cantidad')));
        SET v_precio = (SELECT precio_venta FROM productos WHERE id = v_producto_id);
        SET v_producto_subtotal = v_cantidad * v_precio;
        SET v_subtotal = v_subtotal + v_producto_subtotal;
        SET i = i + 1;
    END WHILE;
    
    -- Calcular total
    SET v_total = v_subtotal - p_descuento;
    
    -- Insertar venta
    INSERT INTO ventas (
        cliente_id, usuario_id, tipo_venta, metodo_pago_id,
        subtotal, descuento, total, estado, observaciones
    ) VALUES (
        p_cliente_id, p_usuario_id, p_tipo_venta, p_metodo_pago_id,
        v_subtotal, p_descuento, v_total, 'completada', p_observaciones
    );
    
    SET v_venta_id = LAST_INSERT_ID();
    
    -- Insertar detalles
    SET i = 0;
    WHILE i < v_count DO
        SET v_producto_id = JSON_UNQUOTE(JSON_EXTRACT(p_productos, CONCAT('$[', i, '].producto_id')));
        SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_productos, CONCAT('$[', i, '].cantidad')));
        SET v_precio = (SELECT precio_venta FROM productos WHERE id = v_producto_id);
        SET v_producto_subtotal = v_cantidad * v_precio;
        
        INSERT INTO detalle_venta (
            venta_id, producto_id, cantidad, precio_unitario, subtotal
        ) VALUES (
            v_venta_id, v_producto_id, v_cantidad, v_precio, v_producto_subtotal
        );
        
        -- Actualizar stock
        UPDATE productos 
        SET stock_actual = stock_actual - v_cantidad
        WHERE id = v_producto_id;
        
        SET i = i + 1;
    END WHILE;
    
    SELECT v_venta_id AS venta_id;
END//
DELIMITER ;

-- Procedimiento: Actualizar estado de envío
DELIMITER //
CREATE PROCEDURE actualizar_estado_envio(
    IN p_envio_id INT,
    IN p_nuevo_estado VARCHAR(50),
    IN p_usuario_id INT,
    IN p_observaciones TEXT
)
BEGIN
    DECLARE v_estado_anterior VARCHAR(50);
    
    -- Obtener estado anterior
    SELECT estado INTO v_estado_anterior FROM envios WHERE id = p_envio_id;
    
    -- Actualizar estado
    UPDATE envios 
    SET estado = p_nuevo_estado,
        fecha_actualizacion = NOW()
    WHERE id = p_envio_id;
    
    -- Si se marca como entregado, actualizar fecha real
    IF p_nuevo_estado = 'entregado' THEN
        UPDATE envios 
        SET fecha_real_entrega = NOW()
        WHERE id = p_envio_id;
    END IF;
    
    -- Registrar cambio en historial
    INSERT INTO estados_envio (
        envio_id, estado_anterior, estado_nuevo, usuario_id, observaciones
    ) VALUES (
        p_envio_id, v_estado_anterior, p_nuevo_estado, p_usuario_id, p_observaciones
    );
END//
DELIMITER ;

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================

