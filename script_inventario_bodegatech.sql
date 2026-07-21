-- ══════════════════════════════════════════════════
-- BodegaTech — Script de Inventario
-- Autor: Bruno Dibella
-- Fecha: 2026-07-20
-- ══════════════════════════════════════════════════

-- ── SECCIÓN DDL ──────────────────────────────────────

-- DROP TABLE: permite re-ejecutar el script sin errores si la tabla ya existe
DROP TABLE IF EXISTS inventario;

-- CREATE TABLE: estructura de inventario
CREATE TABLE inventario (
    id_producto      INT PRIMARY KEY,        -- identificador único, PK
    nombre_producto  VARCHAR(100),           -- texto corto, 100 caracteres: nombres de productos
    categoria        VARCHAR(50),            -- texto corto, categorías: etiquetas breves
    precio_unitario  DECIMAL(10,2),          -- DECIMAL para evitar errores de redondeo (precios unitarios)
    stock_actual     INT,                    -- cantidad entera, de unidades
    stock_minimo     INT,                    -- mínimo entero de reposición, misma naturaleza que 'stock_actual'
    fecha_ingreso    DATE,                   -- solo fecha
    activo           TINYINT                 -- booleano, representación: [1 = disponible, 0 = descontinuado]
);


-- ── SECCIÓN DML ──────────────────────────────────────

-- INSERT INTO: carga de los 10 productos iniciales
INSERT INTO inventario (id_producto, nombre_producto, categoria, precio_unitario, stock_actual, stock_minimo, fecha_ingreso, activo)
VALUES
    (1,  'Laptop Pro 15',        'Computación',     1200.00, 15, 3,  '2024-01-10', 1),
    (2,  'Mouse Inalámbrico',    'Accesorios',        28.00, 80, 10, '2024-01-10', 1),
    (3,  'Monitor 4K 27"',       'Computación',      450.00, 12, 2,  '2024-01-15', 1),
    (4,  'Teclado Mecánico',     'Accesorios',        95.00, 40, 5,  '2024-01-15', 1),
    (5,  'Laptop Basic 14',      'Computación',      650.00, 20, 3,  '2024-02-01', 1),
    (6,  'Auriculares BT Pro',   'Audio',            120.00, 35, 5,  '2024-02-01', 1),
    (7,  'Hub USB-C 7 puertos',  'Accesorios',        45.00, 60, 10, '2024-02-10', 1),
    (8,  'Webcam HD 1080p',      'Accesorios',        85.00, 25, 5,  '2024-02-10', 1),
    (9,  'SSD Externo 1TB',      'Almacenamiento',   130.00, 18, 3,  '2024-03-01', 1),
    (10, 'Parlante Bluetooth',   'Audio',             60.00, 45, 8,  '2024-03-01', 1);



-- UPDATE ventas del día: descuenta las unidades vendidas del stock_actual
UPDATE inventario SET stock_actual = stock_actual - 3  WHERE id_producto = 1;  -- Laptop Pro 15: 15 - 3  = 12
UPDATE inventario SET stock_actual = stock_actual - 12 WHERE id_producto = 2;  -- Mouse Inalámbrico: 80 - 12 = 68
UPDATE inventario SET stock_actual = stock_actual - 5  WHERE id_producto = 6;  -- Auriculares BT Pro: 35 - 5  = 30


-- UPDATE para producto descontinuado: Webcam HD 1080p
UPDATE inventario SET activo = 0 WHERE id_producto = 8;


-- SELECT validaciones
-- Verificación de carga de datos
SELECT * FROM inventario;
