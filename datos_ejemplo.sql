-- ============================================================
-- DATOS DE EJEMPLO PARA PRUEBAS
-- Base de datos: Sánchez Pharma
-- ============================================================

-- ============================================================
-- PRODUCTOS DE EJEMPLO
-- ============================================================

-- Productos - Medicamentos
INSERT INTO productos (codigo, codigo_barras, nombre, descripcion, categoria_id, proveedor_id, precio_compra, precio_venta, stock_actual, stock_minimo, unidad_medida, fecha_vencimiento, estado) VALUES
('MED001', '7701234567890', 'Paracetamol 500mg', 'Analgésico y antipirético. Caja con 20 tabletas', 1, 1, 8.50, 12.00, 150, 20, 'caja', DATE_ADD(CURDATE(), INTERVAL 12 MONTH), 'activo'),
('MED002', '7701234567891', 'Ibuprofeno 400mg', 'Antiinflamatorio no esteroideo. Caja con 20 tabletas', 1, 1, 9.00, 13.50, 120, 15, 'caja', DATE_ADD(CURDATE(), INTERVAL 18 MONTH), 'activo'),
('MED003', '7701234567892', 'Amoxicilina 500mg', 'Antibiótico de amplio espectro. Caja con 14 cápsulas', 1, 2, 15.00, 22.00, 80, 10, 'caja', DATE_ADD(CURDATE(), INTERVAL 24 MONTH), 'activo'),
('MED004', '7701234567893', 'Omeprazol 20mg', 'Protector gástrico. Caja con 14 cápsulas', 1, 2, 12.00, 18.00, 100, 15, 'caja', DATE_ADD(CURDATE(), INTERVAL 30 MONTH), 'activo'),
('MED005', '7701234567894', 'Loratadina 10mg', 'Antihistamínico. Caja con 10 tabletas', 1, 1, 7.50, 11.00, 90, 12, 'caja', DATE_ADD(CURDATE(), INTERVAL 20 MONTH), 'activo'),
('MED006', '7701234567895', 'Diclofenaco 50mg', 'Antiinflamatorio. Caja con 20 tabletas', 1, 3, 10.00, 15.00, 70, 10, 'caja', DATE_ADD(CURDATE(), INTERVAL 15 MONTH), 'activo'),
('MED007', '7701234567896', 'Metformina 500mg', 'Antidiabético. Caja con 30 tabletas', 1, 2, 18.00, 26.00, 60, 8, 'caja', DATE_ADD(CURDATE(), INTERVAL 36 MONTH), 'activo'),
('MED008', '7701234567897', 'Losartán 50mg', 'Antihipertensivo. Caja con 30 tabletas', 1, 3, 20.00, 28.00, 50, 10, 'caja', DATE_ADD(CURDATE(), INTERVAL 24 MONTH), 'activo')
ON DUPLICATE KEY UPDATE nombre=nombre;

-- Productos - Cuidado Personal
INSERT INTO productos (codigo, codigo_barras, nombre, descripcion, categoria_id, proveedor_id, precio_compra, precio_venta, stock_actual, stock_minimo, unidad_medida, fecha_vencimiento, estado) VALUES
('CP001', '7701234567898', 'Jabón Antibacterial', 'Jabón líquido antibacterial 500ml', 2, 1, 6.00, 9.50, 200, 30, 'unidad', DATE_ADD(CURDATE(), INTERVAL 24 MONTH), 'activo'),
('CP002', '7701234567899', 'Shampoo Anticaspa', 'Shampoo para caspa 400ml', 2, 1, 8.50, 13.00, 150, 25, 'unidad', DATE_ADD(CURDATE(), INTERVAL 30 MONTH), 'activo'),
('CP003', '7701234567900', 'Crema Dental', 'Pasta dental con flúor 100g', 2, 2, 4.50, 7.00, 300, 50, 'unidad', DATE_ADD(CURDATE(), INTERVAL 36 MONTH), 'activo'),
('CP004', '7701234567901', 'Desodorante Roll-On', 'Desodorante antitranspirante 50ml', 2, 1, 5.00, 8.00, 180, 30, 'unidad', DATE_ADD(CURDATE(), INTERVAL 24 MONTH), 'activo'),
('CP005', '7701234567902', 'Alcohol en Gel', 'Alcohol en gel desinfectante 500ml', 2, 2, 7.00, 11.00, 120, 20, 'unidad', DATE_ADD(CURDATE(), INTERVAL 18 MONTH), 'activo')
ON DUPLICATE KEY UPDATE nombre=nombre;

-- Productos - Vitaminas y Suplementos
INSERT INTO productos (codigo, codigo_barras, nombre, descripcion, categoria_id, proveedor_id, precio_compra, precio_venta, stock_actual, stock_minimo, unidad_medida, fecha_vencimiento, estado) VALUES
('VIT001', '7701234567903', 'Vitamina C 1000mg', 'Suplemento de vitamina C. Frasco con 30 tabletas', 3, 3, 12.00, 18.00, 100, 15, 'frasco', DATE_ADD(CURDATE(), INTERVAL 24 MONTH), 'activo'),
('VIT002', '7701234567904', 'Multivitamínico', 'Multivitamínico completo. Frasco con 60 tabletas', 3, 3, 25.00, 35.00, 80, 12, 'frasco', DATE_ADD(CURDATE(), INTERVAL 30 MONTH), 'activo'),
('VIT003', '7701234567905', 'Vitamina D3', 'Suplemento de vitamina D3 2000 UI. Frasco con 30 cápsulas', 3, 2, 15.00, 22.00, 90, 10, 'frasco', DATE_ADD(CURDATE(), INTERVAL 24 MONTH), 'activo'),
('VIT004', '7701234567906', 'Omega 3', 'Aceite de pescado rico en Omega 3. Frasco con 60 cápsulas', 3, 3, 30.00, 42.00, 60, 8, 'frasco', DATE_ADD(CURDATE(), INTERVAL 18 MONTH), 'activo'),
('VIT005', '7701234567907', 'Calcio + Vitamina D', 'Suplemento de calcio con vitamina D. Frasco con 60 tabletas', 3, 2, 18.00, 26.00, 70, 10, 'frasco', DATE_ADD(CURDATE(), INTERVAL 24 MONTH), 'activo')
ON DUPLICATE KEY UPDATE nombre=nombre;

-- Productos - Primeros Auxilios
INSERT INTO productos (codigo, codigo_barras, nombre, descripcion, categoria_id, proveedor_id, precio_compra, precio_venta, stock_actual, stock_minimo, unidad_medida, fecha_vencimiento, estado) VALUES
('PA001', '7701234567908', 'Vendas Elásticas', 'Vendas elásticas 10cm x 5m', 4, 1, 8.00, 12.00, 50, 10, 'unidad', NULL, 'activo'),
('PA002', '7701234567909', 'Gasas Estériles', 'Gasas estériles 10x10cm. Paquete con 10 unidades', 4, 2, 6.50, 10.00, 80, 15, 'paquete', NULL, 'activo'),
('PA003', '7701234567910', 'Alcohol Medicinal', 'Alcohol medicinal 96° 500ml', 4, 1, 5.50, 8.50, 100, 20, 'unidad', DATE_ADD(CURDATE(), INTERVAL 36 MONTH), 'activo'),
('PA004', '7701234567911', 'Agua Oxigenada', 'Agua oxigenada 10 volúmenes 500ml', 4, 2, 4.00, 6.50, 90, 15, 'unidad', DATE_ADD(CURDATE(), INTERVAL 24 MONTH), 'activo'),
('PA005', '7701234567912', 'Tiritas', 'Tiritas adhesivas. Caja con 50 unidades', 4, 1, 3.50, 6.00, 150, 25, 'caja', NULL, 'activo')
ON DUPLICATE KEY UPDATE nombre=nombre;

-- Productos - Bebés
INSERT INTO productos (codigo, codigo_barras, nombre, descripcion, categoria_id, proveedor_id, precio_compra, precio_venta, stock_actual, stock_minimo, unidad_medida, fecha_vencimiento, estado) VALUES
('BEB001', '7701234567913', 'Pañales Talla 1', 'Pañales desechables para recién nacidos. Paquete con 44 unidades', 5, 1, 35.00, 48.00, 40, 8, 'paquete', NULL, 'activo'),
('BEB002', '7701234567914', 'Toallas Húmedas', 'Toallas húmedas para bebé. Paquete con 80 unidades', 5, 2, 12.00, 18.00, 60, 12, 'paquete', DATE_ADD(CURDATE(), INTERVAL 24 MONTH), 'activo'),
('BEB003', '7701234567915', 'Talco para Bebé', 'Talco suave para bebé 200g', 5, 1, 8.00, 12.00, 45, 10, 'unidad', DATE_ADD(CURDATE(), INTERVAL 30 MONTH), 'activo'),
('BEB004', '7701234567916', 'Shampoo Bebé', 'Shampoo suave para bebé 200ml', 5, 2, 10.00, 15.00, 50, 10, 'unidad', DATE_ADD(CURDATE(), INTERVAL 36 MONTH), 'activo')
ON DUPLICATE KEY UPDATE nombre=nombre;

-- Productos - Dermocosméticos
INSERT INTO productos (codigo, codigo_barras, nombre, descripcion, categoria_id, proveedor_id, precio_compra, precio_venta, stock_actual, stock_minimo, unidad_medida, fecha_vencimiento, estado) VALUES
('DERM001', '7701234567917', 'Protector Solar FPS 50', 'Protector solar de amplio espectro 100ml', 6, 3, 28.00, 40.00, 35, 8, 'unidad', DATE_ADD(CURDATE(), INTERVAL 12 MONTH), 'activo'),
('DERM002', '7701234567918', 'Crema Hidratante', 'Crema hidratante facial 50g', 6, 2, 15.00, 22.00, 55, 10, 'unidad', DATE_ADD(CURDATE(), INTERVAL 24 MONTH), 'activo'),
('DERM003', '7701234567919', 'Gel Limpiador Facial', 'Gel limpiador para piel grasa 150ml', 6, 3, 12.00, 18.00, 45, 8, 'unidad', DATE_ADD(CURDATE(), INTERVAL 18 MONTH), 'activo')
ON DUPLICATE KEY UPDATE nombre=nombre;

-- ============================================================
-- CLIENTES DE EJEMPLO
-- ============================================================

INSERT INTO clientes (nombre, apellido, documento, tipo_documento, telefono, email, direccion, estado) VALUES
('María', 'González Pérez', '12345678', 'DNI', '987654321', 'maria.gonzalez@email.com', 'Los Claveles 213, José Leonardo Ortiz', 'activo'),
('Juan', 'Rodríguez López', '23456789', 'DNI', '987654322', 'juan.rodriguez@email.com', 'Av. Arequipa 456, Miraflores', 'activo'),
('Carmen', 'Martínez Silva', '34567890', 'DNI', '987654323', 'carmen.martinez@email.com', 'Jr. Los Olivos 789, San Isidro', 'activo'),
('Carlos', 'Fernández Torres', '45678901', 'DNI', '987654324', 'carlos.fernandez@email.com', 'Calle Las Flores 321, La Molina', 'activo'),
('Ana', 'Sánchez Díaz', '56789012', 'DNI', '987654325', 'ana.sanchez@email.com', 'Av. Javier Prado 654, San Borja', 'activo'),
('Luis', 'Ramírez Vargas', '67890123', 'DNI', '987654326', 'luis.ramirez@email.com', 'Jr. Unión 987, Surco', 'activo'),
('Patricia', 'Morales Castro', '78901234', 'DNI', '987654327', 'patricia.morales@email.com', 'Av. Brasil 147, Magdalena', 'activo'),
('Roberto', 'Jiménez Ruiz', '89012345', 'DNI', '987654328', 'roberto.jimenez@email.com', 'Calle Los Pinos 258, Pueblo Libre', 'activo'),
('Sofía', 'Herrera Mendoza', '90123456', 'DNI', '987654329', 'sofia.herrera@email.com', 'Av. La Marina 369, San Miguel', 'activo'),
('Miguel', 'Torres Ríos', '01234567', 'DNI', '987654330', 'miguel.torres@email.com', 'Jr. Las Palmas 741, Callao', 'activo')
ON DUPLICATE KEY UPDATE nombre=nombre;

-- ============================================================
-- NOTAS
-- ============================================================
-- 
-- Total de productos insertados: 28 productos
-- - 8 Medicamentos
-- - 5 Cuidado Personal
-- - 5 Vitaminas y Suplementos
-- - 5 Primeros Auxilios
-- - 4 Bebés
-- - 3 Dermocosméticos
--
-- Total de clientes insertados: 10 clientes
-- - El primer cliente tiene la dirección proporcionada: "Los Claveles 213, José Leonardo Ortiz"
--
-- Todos los productos tienen:
-- - Precios de compra y venta configurados
-- - Stock inicial suficiente para hacer ventas
-- - Fechas de vencimiento futuras
-- - Estado activo
--
-- ============================================================

