-- ============================================================
-- SCRIPT SQL PARA CREAR TABLAS DE INVENTARIO
-- Base de datos: Sánchez Pharma
-- ============================================================

-- ------------------------------------------------------------
-- TABLA: categorias
-- Almacena las categorías de productos (medicamentos, cuidado personal, etc.)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categorias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    estado ENUM('activo', 'inactivo') DEFAULT 'activo',
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- TABLA: proveedores
-- Almacena información de los proveedores
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS proveedores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    contacto VARCHAR(100),
    telefono VARCHAR(20),
    email VARCHAR(100),
    direccion VARCHAR(255),
    estado ENUM('activo', 'inactivo') DEFAULT 'activo',
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- TABLA: productos
-- Almacena información de los productos/medicamentos del inventario
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE,
    codigo_barras VARCHAR(50) UNIQUE,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    categoria_id INT,
    proveedor_id INT,
    precio_compra DECIMAL(10, 2) DEFAULT 0.00,
    precio_venta DECIMAL(10, 2) DEFAULT 0.00,
    stock_actual INT DEFAULT 0,
    stock_minimo INT DEFAULT 0,
    unidad_medida VARCHAR(20) DEFAULT 'unidad',
    fecha_vencimiento DATE,
    estado ENUM('activo', 'inactivo', 'agotado') DEFAULT 'activo',
    imagen_url VARCHAR(255),
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE SET NULL,
    FOREIGN KEY (proveedor_id) REFERENCES proveedores(id) ON DELETE SET NULL,
    INDEX idx_codigo (codigo),
    INDEX idx_nombre (nombre),
    INDEX idx_categoria (categoria_id),
    INDEX idx_proveedor (proveedor_id),
    INDEX idx_fecha_vencimiento (fecha_vencimiento),
    INDEX idx_estado (estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- TABLA: tipo_movimiento
-- Define los tipos de movimientos (entrada, salida, ajuste, etc.)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tipo_movimiento (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    tipo ENUM('entrada', 'salida', 'ajuste') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- TABLA: movimientos_inventario
-- Registra todos los movimientos de inventario (entradas, salidas, ajustes)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS movimientos_inventario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    tipo_movimiento_id INT NOT NULL,
    cantidad INT NOT NULL,
    stock_anterior INT NOT NULL,
    stock_nuevo INT NOT NULL,
    precio_unitario DECIMAL(10, 2),
    motivo VARCHAR(255),
    referencia VARCHAR(100),
    usuario_id INT,
    fecha_movimiento DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (tipo_movimiento_id) REFERENCES tipo_movimiento(id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    INDEX idx_producto (producto_id),
    INDEX idx_tipo_movimiento (tipo_movimiento_id),
    INDEX idx_fecha (fecha_movimiento),
    INDEX idx_usuario (usuario_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- TABLA: alertas_inventario
-- Almacena alertas de stock bajo, productos próximos a vencer, etc.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS alertas_inventario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    tipo_alerta ENUM('stock_bajo', 'producto_vencido', 'proximo_vencer', 'sin_movimiento') NOT NULL,
    mensaje VARCHAR(255),
    fecha_alerta DATETIME DEFAULT CURRENT_TIMESTAMP,
    leida BOOLEAN DEFAULT FALSE,
    fecha_leida DATETIME,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    INDEX idx_producto (producto_id),
    INDEX idx_tipo (tipo_alerta),
    INDEX idx_leida (leida)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- DATOS INICIALES (INSERTS)
-- ============================================================

-- Insertar tipos de movimiento básicos
INSERT INTO tipo_movimiento (nombre, descripcion, tipo) VALUES
('Compra', 'Entrada de productos por compra a proveedor', 'entrada'),
('Devolución Cliente', 'Entrada por devolución de cliente', 'entrada'),
('Ajuste Entrada', 'Ajuste de inventario positivo', 'entrada'),
('Venta', 'Salida de productos por venta', 'salida'),
('Merma', 'Salida por pérdida o daño', 'salida'),
('Vencimiento', 'Salida por producto vencido', 'salida'),
('Ajuste Salida', 'Ajuste de inventario negativo', 'salida'),
('Transferencia Entrada', 'Entrada por transferencia', 'entrada'),
('Transferencia Salida', 'Salida por transferencia', 'salida')
ON DUPLICATE KEY UPDATE nombre=nombre;

-- Insertar algunas categorías básicas
INSERT INTO categorias (nombre, descripcion) VALUES
('Medicamentos', 'Medicamentos de prescripción y de venta libre'),
('Cuidado Personal', 'Productos de higiene y cuidado personal'),
('Vitaminas y Suplementos', 'Vitaminas, minerales y suplementos alimenticios'),
('Primeros Auxilios', 'Productos para primeros auxilios'),
('Bebés', 'Productos para bebés y niños'),
('Dermocosméticos', 'Productos dermatológicos y cosméticos')
ON DUPLICATE KEY UPDATE nombre=nombre;

-- Insertar algunos proveedores de ejemplo
INSERT INTO proveedores (nombre, contacto, telefono, email) VALUES
('Farmacéutica Nacional S.A.', 'Juan Pérez', '555-0101', 'contacto@farmanacional.com'),
('Distribuidora Médica', 'María González', '555-0202', 'ventas@distmedica.com'),
('Laboratorios Unidos', 'Carlos Rodríguez', '555-0303', 'info@labunidos.com')
ON DUPLICATE KEY UPDATE nombre=nombre;

-- ============================================================
-- VISTAS ÚTILES
-- ============================================================

-- Vista: Productos con información completa
CREATE OR REPLACE VIEW vista_productos_completa AS
SELECT 
    p.id,
    p.codigo,
    p.codigo_barras,
    p.nombre,
    p.descripcion,
    p.precio_compra,
    p.precio_venta,
    p.stock_actual,
    p.stock_minimo,
    p.unidad_medida,
    p.fecha_vencimiento,
    p.estado,
    c.nombre AS categoria_nombre,
    pr.nombre AS proveedor_nombre,
    CASE 
        WHEN p.stock_actual <= p.stock_minimo THEN 'stock_bajo'
        WHEN p.fecha_vencimiento IS NOT NULL AND p.fecha_vencimiento < CURDATE() THEN 'vencido'
        WHEN p.fecha_vencimiento IS NOT NULL AND p.fecha_vencimiento <= DATE_ADD(CURDATE(), INTERVAL 30 DAY) THEN 'proximo_vencer'
        ELSE 'normal'
    END AS estado_alerta
FROM productos p
LEFT JOIN categorias c ON p.categoria_id = c.id
LEFT JOIN proveedores pr ON p.proveedor_id = pr.id;

-- Vista: Productos con stock bajo
CREATE OR REPLACE VIEW vista_stock_bajo AS
SELECT 
    p.id,
    p.codigo,
    p.nombre,
    p.stock_actual,
    p.stock_minimo,
    (p.stock_minimo - p.stock_actual) AS faltante,
    c.nombre AS categoria_nombre
FROM productos p
LEFT JOIN categorias c ON p.categoria_id = c.id
WHERE p.stock_actual <= p.stock_minimo 
AND p.estado = 'activo';

-- Vista: Productos próximos a vencer (30 días)
CREATE OR REPLACE VIEW vista_proximos_vencer AS
SELECT 
    p.id,
    p.codigo,
    p.nombre,
    p.fecha_vencimiento,
    DATEDIFF(p.fecha_vencimiento, CURDATE()) AS dias_restantes,
    p.stock_actual,
    c.nombre AS categoria_nombre
FROM productos p
LEFT JOIN categorias c ON p.categoria_id = c.id
WHERE p.fecha_vencimiento IS NOT NULL
AND p.fecha_vencimiento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
AND p.estado = 'activo'
ORDER BY p.fecha_vencimiento ASC;

-- ============================================================
-- TRIGGERS ÚTILES
-- ============================================================

-- Trigger: Actualizar stock después de un movimiento
DELIMITER //
CREATE TRIGGER actualizar_stock_despues_movimiento
AFTER INSERT ON movimientos_inventario
FOR EACH ROW
BEGIN
    UPDATE productos 
    SET stock_actual = NEW.stock_nuevo,
        estado = CASE 
            WHEN NEW.stock_nuevo <= 0 THEN 'agotado'
            WHEN NEW.stock_nuevo <= stock_minimo THEN 'activo'
            ELSE 'activo'
        END
    WHERE id = NEW.producto_id;
END//
DELIMITER ;

-- Trigger: Crear alerta cuando el stock está bajo
DELIMITER //
CREATE TRIGGER alerta_stock_bajo
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
    IF NEW.stock_actual <= NEW.stock_minimo AND OLD.stock_actual > OLD.stock_minimo THEN
        INSERT INTO alertas_inventario (producto_id, tipo_alerta, mensaje)
        VALUES (NEW.id, 'stock_bajo', CONCAT('El producto ', NEW.nombre, ' tiene stock bajo. Actual: ', NEW.stock_actual, ', Mínimo: ', NEW.stock_minimo));
    END IF;
END//
DELIMITER ;

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS ÚTILES
-- ============================================================

-- Procedimiento: Registrar entrada de productos
DELIMITER //
CREATE PROCEDURE registrar_entrada(
    IN p_producto_id INT,
    IN p_cantidad INT,
    IN p_precio_unitario DECIMAL(10,2),
    IN p_motivo VARCHAR(255),
    IN p_usuario_id INT
)
BEGIN
    DECLARE v_stock_anterior INT;
    DECLARE v_stock_nuevo INT;
    DECLARE v_tipo_movimiento_id INT;
    
    -- Obtener stock actual
    SELECT stock_actual INTO v_stock_anterior FROM productos WHERE id = p_producto_id;
    
    -- Calcular nuevo stock
    SET v_stock_nuevo = v_stock_anterior + p_cantidad;
    
    -- Obtener ID del tipo de movimiento "Compra"
    SELECT id INTO v_tipo_movimiento_id FROM tipo_movimiento WHERE nombre = 'Compra' LIMIT 1;
    
    -- Registrar movimiento
    INSERT INTO movimientos_inventario 
    (producto_id, tipo_movimiento_id, cantidad, stock_anterior, stock_nuevo, precio_unitario, motivo, usuario_id)
    VALUES 
    (p_producto_id, v_tipo_movimiento_id, p_cantidad, v_stock_anterior, v_stock_nuevo, p_precio_unitario, p_motivo, p_usuario_id);
END//
DELIMITER ;

-- Procedimiento: Registrar salida de productos
DELIMITER //
CREATE PROCEDURE registrar_salida(
    IN p_producto_id INT,
    IN p_cantidad INT,
    IN p_tipo_movimiento VARCHAR(50),
    IN p_motivo VARCHAR(255),
    IN p_usuario_id INT
)
BEGIN
    DECLARE v_stock_anterior INT;
    DECLARE v_stock_nuevo INT;
    DECLARE v_tipo_movimiento_id INT;
    
    -- Obtener stock actual
    SELECT stock_actual INTO v_stock_anterior FROM productos WHERE id = p_producto_id;
    
    -- Validar que hay suficiente stock
    IF v_stock_anterior < p_cantidad THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente';
    END IF;
    
    -- Calcular nuevo stock
    SET v_stock_nuevo = v_stock_anterior - p_cantidad;
    
    -- Obtener ID del tipo de movimiento
    SELECT id INTO v_tipo_movimiento_id FROM tipo_movimiento WHERE nombre = p_tipo_movimiento LIMIT 1;
    
    -- Registrar movimiento
    INSERT INTO movimientos_inventario 
    (producto_id, tipo_movimiento_id, cantidad, stock_anterior, stock_nuevo, motivo, usuario_id)
    VALUES 
    (p_producto_id, v_tipo_movimiento_id, p_cantidad, v_stock_anterior, v_stock_nuevo, p_motivo, p_usuario_id);
END//
DELIMITER ;

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================

