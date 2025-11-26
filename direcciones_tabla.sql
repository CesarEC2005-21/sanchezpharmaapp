-- ================================================
-- TABLA DE DIRECCIONES DE CLIENTES
-- ================================================

CREATE TABLE IF NOT EXISTS direcciones_clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    titulo VARCHAR(100) NOT NULL,
    direccion TEXT NOT NULL,
    referencia TEXT,
    latitud DECIMAL(10, 8) NOT NULL,
    longitud DECIMAL(11, 8) NOT NULL,
    es_principal BOOLEAN DEFAULT FALSE,
    fecha_creacion DATETIME DEFAULT NOW(),
    fecha_actualizacion DATETIME DEFAULT NOW() ON UPDATE NOW(),
    
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE,
    INDEX idx_cliente (cliente_id),
    INDEX idx_principal (cliente_id, es_principal)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Trigger para asegurar que solo haya una dirección principal por cliente
DELIMITER $$

CREATE TRIGGER trg_direccion_principal_before_insert
BEFORE INSERT ON direcciones_clientes
FOR EACH ROW
BEGIN
    IF NEW.es_principal = TRUE THEN
        UPDATE direcciones_clientes 
        SET es_principal = FALSE 
        WHERE cliente_id = NEW.cliente_id;
    END IF;
END$$

CREATE TRIGGER trg_direccion_principal_before_update
BEFORE UPDATE ON direcciones_clientes
FOR EACH ROW
BEGIN
    IF NEW.es_principal = TRUE AND OLD.es_principal = FALSE THEN
        UPDATE direcciones_clientes 
        SET es_principal = FALSE 
        WHERE cliente_id = NEW.cliente_id AND id != NEW.id;
    END IF;
END$$

DELIMITER ;

-- ================================================
-- DATOS DE EJEMPLO (OPCIONAL)
-- ================================================

-- Dirección de ejemplo para cliente con ID 1
INSERT INTO direcciones_clientes (cliente_id, titulo, direccion, referencia, latitud, longitud, es_principal) 
VALUES (1, 'Casa', 'Av. Bolognesi 123, Chiclayo', 'Casa de 2 pisos, puerta azul', -6.777140, -79.841700, TRUE);

INSERT INTO direcciones_clientes (cliente_id, titulo, direccion, referencia, latitud, longitud, es_principal) 
VALUES (1, 'Trabajo', 'Jr. San José 456, Chiclayo', 'Oficina 201', -6.770000, -79.840000, FALSE);

