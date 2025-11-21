-- ============================================================
-- SCRIPT SQL PARA CREAR TABLAS DE REPORTES
-- Base de datos: Sánchez Pharma
-- ============================================================

-- ------------------------------------------------------------
-- TABLA: tipos_reporte
-- Define los tipos de reportes disponibles
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tipos_reporte (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    categoria ENUM('ventas', 'inventario', 'productos', 'envios', 'clientes', 'financiero', 'general') NOT NULL,
    estado ENUM('activo', 'inactivo') DEFAULT 'activo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- TABLA: reportes_generados
-- Almacena los reportes generados por los usuarios
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reportes_generados (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo_reporte_id INT NOT NULL,
    usuario_id INT NOT NULL,
    nombre_reporte VARCHAR(200),
    parametros JSON,
    fecha_desde DATE,
    fecha_hasta DATE,
    datos_reporte JSON,
    formato ENUM('json', 'pdf', 'excel') DEFAULT 'json',
    fecha_generacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tipo_reporte_id) REFERENCES tipos_reporte(id) ON DELETE RESTRICT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    INDEX idx_tipo_reporte (tipo_reporte_id),
    INDEX idx_usuario (usuario_id),
    INDEX idx_fecha_generacion (fecha_generacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- DATOS INICIALES (INSERTS)
-- ============================================================

-- Insertar tipos de reporte básicos
INSERT INTO tipos_reporte (nombre, descripcion, categoria) VALUES
('Ventas Diarias', 'Reporte de ventas del día', 'ventas'),
('Ventas Semanales', 'Reporte de ventas de la semana', 'ventas'),
('Ventas Mensuales', 'Reporte de ventas del mes', 'ventas'),
('Ventas Anuales', 'Reporte de ventas del año', 'ventas'),
('Ventas por Vendedor', 'Reporte de ventas agrupadas por vendedor', 'ventas'),
('Ventas por Cliente', 'Reporte de ventas agrupadas por cliente', 'ventas'),
('Ventas por Método de Pago', 'Reporte de ventas por método de pago', 'ventas'),
('Productos Más Vendidos', 'Ranking de productos más vendidos', 'productos'),
('Productos Menos Vendidos', 'Productos con menor rotación', 'productos'),
('Valor de Inventario', 'Valor total del inventario', 'inventario'),
('Productos Stock Bajo', 'Productos con stock bajo o agotado', 'inventario'),
('Productos Próximos a Vencer', 'Productos próximos a vencer', 'inventario'),
('Movimientos de Inventario', 'Historial de movimientos de inventario', 'inventario'),
('Envíos por Estado', 'Reporte de envíos agrupados por estado', 'envios'),
('Tiempo de Entrega', 'Análisis de tiempos de entrega', 'envios'),
('Clientes Más Frecuentes', 'Ranking de clientes más frecuentes', 'clientes'),
('Ingresos Totales', 'Reporte de ingresos totales', 'financiero'),
('Comparativa de Períodos', 'Comparación entre períodos', 'general')
ON DUPLICATE KEY UPDATE nombre=nombre;

-- ============================================================
-- VISTAS ÚTILES PARA REPORTES
-- ============================================================

-- Vista: Resumen de Ventas Diarias
CREATE OR REPLACE VIEW vista_ventas_diarias AS
SELECT 
    DATE(fecha_venta) as fecha,
    COUNT(*) as total_ventas,
    SUM(total) as ingreso_total,
    AVG(total) as promedio_venta,
    MIN(total) as venta_minima,
    MAX(total) as venta_maxima,
    SUM(CASE WHEN tipo_venta = 'recojo_tienda' THEN 1 ELSE 0 END) as ventas_recojo,
    SUM(CASE WHEN tipo_venta = 'envio_domicilio' THEN 1 ELSE 0 END) as ventas_envio
FROM ventas
WHERE estado = 'completada'
GROUP BY DATE(fecha_venta)
ORDER BY fecha DESC;

-- Vista: Resumen de Ventas Mensuales
CREATE OR REPLACE VIEW vista_ventas_mensuales AS
SELECT 
    YEAR(fecha_venta) as año,
    MONTH(fecha_venta) as mes,
    COUNT(*) as total_ventas,
    SUM(total) as ingreso_total,
    AVG(total) as promedio_venta,
    COUNT(DISTINCT cliente_id) as clientes_unicos,
    COUNT(DISTINCT usuario_id) as vendedores
FROM ventas
WHERE estado = 'completada'
GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
ORDER BY año DESC, mes DESC;

-- Vista: Productos Más Vendidos
CREATE OR REPLACE VIEW vista_productos_mas_vendidos AS
SELECT 
    p.id,
    p.codigo,
    p.nombre,
    p.categoria_nombre,
    SUM(dv.cantidad) as total_vendido,
    SUM(dv.subtotal) as ingreso_total,
    COUNT(DISTINCT dv.venta_id) as veces_vendido,
    AVG(dv.precio_unitario) as precio_promedio
FROM detalle_venta dv
LEFT JOIN productos p ON dv.producto_id = p.id
LEFT JOIN ventas v ON dv.venta_id = v.id
WHERE v.estado = 'completada'
GROUP BY p.id, p.codigo, p.nombre, p.categoria_nombre
ORDER BY total_vendido DESC;

-- Vista: Ventas por Vendedor
CREATE OR REPLACE VIEW vista_ventas_por_vendedor AS
SELECT 
    u.id as usuario_id,
    u.username,
    COUNT(v.id) as total_ventas,
    SUM(v.total) as ingreso_total,
    AVG(v.total) as promedio_venta,
    MIN(v.fecha_venta) as primera_venta,
    MAX(v.fecha_venta) as ultima_venta
FROM ventas v
LEFT JOIN usuarios u ON v.usuario_id = u.id
WHERE v.estado = 'completada'
GROUP BY u.id, u.username
ORDER BY ingreso_total DESC;

-- Vista: Ventas por Cliente
CREATE OR REPLACE VIEW vista_ventas_por_cliente AS
SELECT 
    c.id as cliente_id,
    c.nombre,
    c.apellido,
    c.documento,
    COUNT(v.id) as total_ventas,
    SUM(v.total) as monto_total,
    AVG(v.total) as promedio_venta,
    MIN(v.fecha_venta) as primera_compra,
    MAX(v.fecha_venta) as ultima_compra
FROM ventas v
LEFT JOIN clientes c ON v.cliente_id = c.id
WHERE v.estado = 'completada' AND v.cliente_id IS NOT NULL
GROUP BY c.id, c.nombre, c.apellido, c.documento
ORDER BY monto_total DESC;

-- Vista: Ventas por Método de Pago
CREATE OR REPLACE VIEW vista_ventas_por_metodo_pago AS
SELECT 
    mp.id as metodo_pago_id,
    mp.nombre as metodo_pago,
    COUNT(v.id) as total_ventas,
    SUM(v.total) as monto_total,
    AVG(v.total) as promedio_venta,
    (SUM(v.total) / (SELECT SUM(total) FROM ventas WHERE estado = 'completada') * 100) as porcentaje
FROM ventas v
LEFT JOIN metodos_pago mp ON v.metodo_pago_id = mp.id
WHERE v.estado = 'completada'
GROUP BY mp.id, mp.nombre
ORDER BY monto_total DESC;

-- Vista: Resumen de Envíos
CREATE OR REPLACE VIEW vista_resumen_envios AS
SELECT 
    estado,
    COUNT(*) as total_envios,
    SUM(CASE WHEN fecha_real_entrega IS NOT NULL THEN 1 ELSE 0 END) as entregados,
    AVG(CASE 
        WHEN fecha_real_entrega IS NOT NULL AND fecha_estimada_entrega IS NOT NULL 
        THEN DATEDIFF(fecha_real_entrega, fecha_creacion) 
        ELSE NULL 
    END) as dias_promedio_entrega
FROM envios
GROUP BY estado;

-- Vista: Análisis de Inventario
CREATE OR REPLACE VIEW vista_analisis_inventario AS
SELECT 
    COUNT(*) as total_productos,
    SUM(CASE WHEN estado = 'activo' THEN 1 ELSE 0 END) as productos_activos,
    SUM(CASE WHEN estado = 'agotado' THEN 1 ELSE 0 END) as productos_agotados,
    SUM(CASE WHEN stock_actual <= stock_minimo THEN 1 ELSE 0 END) as productos_stock_bajo,
    SUM(stock_actual * precio_compra) as valor_inventario_compra,
    SUM(stock_actual * precio_venta) as valor_inventario_venta,
    SUM((precio_venta - precio_compra) * stock_actual) as ganancia_potencial
FROM productos
WHERE estado IN ('activo', 'agotado');

-- Vista: Rotación de Productos
CREATE OR REPLACE VIEW vista_rotacion_productos AS
SELECT 
    p.id,
    p.codigo,
    p.nombre,
    p.stock_actual,
    COALESCE(SUM(dv.cantidad), 0) as unidades_vendidas,
    COALESCE(COUNT(DISTINCT dv.venta_id), 0) as veces_vendido,
    CASE 
        WHEN p.stock_actual > 0 
        THEN COALESCE(SUM(dv.cantidad), 0) / p.stock_actual 
        ELSE 0 
    END as indice_rotacion
FROM productos p
LEFT JOIN detalle_venta dv ON p.id = dv.producto_id
LEFT JOIN ventas v ON dv.venta_id = v.id AND v.estado = 'completada'
GROUP BY p.id, p.codigo, p.nombre, p.stock_actual
ORDER BY unidades_vendidas DESC;

-- Vista: Comparativa de Períodos
CREATE OR REPLACE VIEW vista_comparativa_periodos AS
SELECT 
    'Mes Actual' as periodo,
    COUNT(*) as total_ventas,
    SUM(total) as ingreso_total,
    AVG(total) as promedio_venta,
    COUNT(DISTINCT cliente_id) as clientes_unicos
FROM ventas
WHERE estado = 'completada'
AND MONTH(fecha_venta) = MONTH(CURDATE())
AND YEAR(fecha_venta) = YEAR(CURDATE())
UNION ALL
SELECT 
    'Mes Anterior' as periodo,
    COUNT(*) as total_ventas,
    SUM(total) as ingreso_total,
    AVG(total) as promedio_venta,
    COUNT(DISTINCT cliente_id) as clientes_unicos
FROM ventas
WHERE estado = 'completada'
AND MONTH(fecha_venta) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
AND YEAR(fecha_venta) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH));

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS PARA REPORTES
-- ============================================================

-- Procedimiento: Reporte de Ventas por Período
DELIMITER //
CREATE PROCEDURE reporte_ventas_periodo(
    IN p_fecha_desde DATE,
    IN p_fecha_hasta DATE
)
BEGIN
    SELECT 
        v.*,
        c.nombre as cliente_nombre,
        c.apellido as cliente_apellido,
        u.username as vendedor,
        mp.nombre as metodo_pago_nombre
    FROM ventas v
    LEFT JOIN clientes c ON v.cliente_id = c.id
    LEFT JOIN usuarios u ON v.usuario_id = u.id
    LEFT JOIN metodos_pago mp ON v.metodo_pago_id = mp.id
    WHERE v.estado = 'completada'
    AND DATE(v.fecha_venta) BETWEEN p_fecha_desde AND p_fecha_hasta
    ORDER BY v.fecha_venta DESC;
END//
DELIMITER ;

-- Procedimiento: Reporte de Productos Más Vendidos
DELIMITER //
CREATE PROCEDURE reporte_productos_mas_vendidos(
    IN p_fecha_desde DATE,
    IN p_fecha_hasta DATE,
    IN p_limite INT
)
BEGIN
    SELECT 
        p.id,
        p.codigo,
        p.nombre,
        p.categoria_nombre,
        SUM(dv.cantidad) as total_vendido,
        SUM(dv.subtotal) as ingreso_total,
        COUNT(DISTINCT dv.venta_id) as veces_vendido
    FROM detalle_venta dv
    LEFT JOIN productos p ON dv.producto_id = p.id
    LEFT JOIN ventas v ON dv.venta_id = v.id
    WHERE v.estado = 'completada'
    AND DATE(v.fecha_venta) BETWEEN p_fecha_desde AND p_fecha_hasta
    GROUP BY p.id, p.codigo, p.nombre, p.categoria_nombre
    ORDER BY total_vendido DESC
    LIMIT p_limite;
END//
DELIMITER ;

-- Procedimiento: Reporte de Ingresos Totales
DELIMITER //
CREATE PROCEDURE reporte_ingresos_totales(
    IN p_fecha_desde DATE,
    IN p_fecha_hasta DATE
)
BEGIN
    SELECT 
        SUM(total) as ingreso_total,
        COUNT(*) as total_ventas,
        AVG(total) as promedio_venta,
        MIN(total) as venta_minima,
        MAX(total) as venta_maxima,
        SUM(CASE WHEN tipo_venta = 'recojo_tienda' THEN total ELSE 0 END) as ingresos_recojo,
        SUM(CASE WHEN tipo_venta = 'envio_domicilio' THEN total ELSE 0 END) as ingresos_envio
    FROM ventas
    WHERE estado = 'completada'
    AND DATE(fecha_venta) BETWEEN p_fecha_desde AND p_fecha_hasta;
END//
DELIMITER ;

-- Procedimiento: Reporte de Envíos
DELIMITER //
CREATE PROCEDURE reporte_envios(
    IN p_fecha_desde DATE,
    IN p_fecha_hasta DATE,
    IN p_estado VARCHAR(50)
)
BEGIN
    SELECT 
        e.*,
        v.numero_venta,
        v.total,
        c.nombre as cliente_nombre,
        c.telefono as cliente_telefono,
        DATEDIFF(COALESCE(e.fecha_real_entrega, CURDATE()), e.fecha_creacion) as dias_transcurridos
    FROM envios e
    LEFT JOIN ventas v ON e.venta_id = v.id
    LEFT JOIN clientes c ON v.cliente_id = c.id
    WHERE DATE(e.fecha_creacion) BETWEEN p_fecha_desde AND p_fecha_hasta
    AND (p_estado IS NULL OR e.estado = p_estado)
    ORDER BY e.fecha_creacion DESC;
END//
DELIMITER ;

-- Procedimiento: Dashboard Resumen
DELIMITER //
CREATE PROCEDURE dashboard_resumen()
BEGIN
    -- Ventas del día
    SELECT 
        'ventas_dia' as tipo,
        COUNT(*) as cantidad,
        SUM(total) as monto
    FROM ventas
    WHERE estado = 'completada'
    AND DATE(fecha_venta) = CURDATE()
    
    UNION ALL
    
    -- Ventas del mes
    SELECT 
        'ventas_mes' as tipo,
        COUNT(*) as cantidad,
        SUM(total) as monto
    FROM ventas
    WHERE estado = 'completada'
    AND MONTH(fecha_venta) = MONTH(CURDATE())
    AND YEAR(fecha_venta) = YEAR(CURDATE())
    
    UNION ALL
    
    -- Productos con stock bajo
    SELECT 
        'stock_bajo' as tipo,
        COUNT(*) as cantidad,
        0 as monto
    FROM productos
    WHERE stock_actual <= stock_minimo
    AND estado = 'activo'
    
    UNION ALL
    
    -- Envíos pendientes
    SELECT 
        'envios_pendientes' as tipo,
        COUNT(*) as cantidad,
        0 as monto
    FROM envios
    WHERE estado IN ('pendiente', 'preparando', 'en_camino')
    
    UNION ALL
    
    -- Valor del inventario
    SELECT 
        'valor_inventario' as tipo,
        COUNT(*) as cantidad,
        SUM(stock_actual * precio_compra) as monto
    FROM productos
    WHERE estado = 'activo';
END//
DELIMITER ;

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================

