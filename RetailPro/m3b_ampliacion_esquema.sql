-- ═══════════════════════════════════════════════════════════
-- Proyecto: RetailPro
-- Módulo 3b — Ampliación de esquema (previa a M5)
-- Archivo: m3b_ampliacion_esquema.sql
-- Base: Ventas_Tech_DB (SQL Server)
-- Autor: Bruno
-- Fecha: 05/08/2026
-- ═══════════════════════════════════════════════════════════
-- MOTIVO DE ESTE SCRIPT
--   La consigna de M5 requiere cruzar `territorios`, obtener el
--   `segmento` del cliente y discriminar ventas por `canal`. Ninguno
--   de esos tres elementos fue solicitado en M3, de modo que la base
--   entregada en aquel módulo no los contiene.
--
--   Este script amplía el esquema existente en lugar de reescribir
--   m3_creacion_base.sql, para que quede documentado qué se entregó
--   originalmente y qué se agregó después por un requerimiento
--   posterior. Ejecutar DESPUÉS de m3_creacion_base.sql.
--
-- QUÉ AGREGA
--   1. Tabla `territorios` y su vínculo con `clientes`.
--   2. Columna `clientes.segmento`.
--   3. Columna `ventas.canal`.
--   4. Un cliente y un producto sin ventas asociadas.
--
-- SOBRE EL PUNTO 4
--   Las Consultas 2 y 3 de M5 buscan clientes y productos sin
--   movimiento. En el dataset de M3 los 5 clientes compraron y los
--   6 productos se vendieron, así que ambas consultas devolverían
--   cero filas: serían correctas pero indemostrables. Se incorpora
--   un caso de cada tipo para que el resultado sea verificable, con
--   el mismo criterio que emplean los datasets de práctica del curso.
--
-- El script es idempotente: puede re-ejecutarse sin error.
-- ═══════════════════════════════════════════════════════════

USE Ventas_Tech_DB;
GO


-- ───────────────────────────────────────────────────────────
-- 1. Tabla territorios
-- Granularidad: una fila por ciudad. La región agrupa ciudades,
-- de modo que la jerarquía ciudad → región queda normalizada y
-- Power BI puede usarla para desglose geográfico en M7.
-- ───────────────────────────────────────────────────────────
IF OBJECT_ID('territorios', 'U') IS NULL
BEGIN
    CREATE TABLE territorios (
        id_territorio INT PRIMARY KEY NOT NULL,
        ciudad        VARCHAR(50)  NOT NULL,
        region        VARCHAR(50)  NOT NULL,
        pais          VARCHAR(50)  NOT NULL DEFAULT 'Argentina'
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM territorios)
BEGIN
    INSERT INTO territorios (id_territorio, ciudad, region, pais) VALUES
        (1, 'Buenos Aires', 'Centro',  'Argentina'),
        (2, 'Córdoba',      'Centro',  'Argentina'),
        (3, 'Rosario',      'Litoral', 'Argentina'),
        (4, 'Mendoza',      'Cuyo',    'Argentina'),
        (5, 'Tucumán',      'NOA',     'Argentina'),
        (6, 'Salta',        'NOA',     'Argentina');
END
GO


-- ───────────────────────────────────────────────────────────
-- 2. Vínculo clientes → territorios
-- Se agrega la FK sin eliminar `clientes.ciudad`: la columna
-- original queda como dato de origen y el id_territorio pasa a ser
-- la vía canónica de acceso a la región.
-- ───────────────────────────────────────────────────────────
IF COL_LENGTH('clientes', 'id_territorio') IS NULL
    ALTER TABLE clientes ADD id_territorio INT NULL;
GO

-- Poblado por coincidencia de ciudad
UPDATE c
SET c.id_territorio = t.id_territorio
FROM clientes c
INNER JOIN territorios t
    ON c.ciudad = t.ciudad
WHERE c.id_territorio IS NULL;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_clientes_territorios'
)
    ALTER TABLE clientes
    ADD CONSTRAINT FK_clientes_territorios
        FOREIGN KEY (id_territorio) REFERENCES territorios(id_territorio);
GO


-- ───────────────────────────────────────────────────────────
-- 3. Columna clientes.segmento
-- Valores admitidos: 'Corporativo', 'PyME', 'Consumidor final'.
-- La restricción CHECK evita que el campo degenere en texto libre.
-- ───────────────────────────────────────────────────────────
IF COL_LENGTH('clientes', 'segmento') IS NULL
    ALTER TABLE clientes ADD segmento VARCHAR(30) NULL;
GO

UPDATE clientes SET segmento = 'Corporativo'      WHERE id_cliente = 1 AND segmento IS NULL;
UPDATE clientes SET segmento = 'PyME'             WHERE id_cliente = 2 AND segmento IS NULL;
UPDATE clientes SET segmento = 'Consumidor final' WHERE id_cliente = 3 AND segmento IS NULL;
UPDATE clientes SET segmento = 'PyME'             WHERE id_cliente = 4 AND segmento IS NULL;
UPDATE clientes SET segmento = 'Corporativo'      WHERE id_cliente = 5 AND segmento IS NULL;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints WHERE name = 'CK_clientes_segmento'
)
    ALTER TABLE clientes
    ADD CONSTRAINT CK_clientes_segmento
        CHECK (segmento IN ('Corporativo', 'PyME', 'Consumidor final'));
GO


-- ───────────────────────────────────────────────────────────
-- 4. Columna ventas.canal
-- Valores admitidos: 'Online', 'Presencial'.
-- ───────────────────────────────────────────────────────────
IF COL_LENGTH('ventas', 'canal') IS NULL
    ALTER TABLE ventas ADD canal VARCHAR(20) NULL;
GO

UPDATE ventas SET canal = 'Online'     WHERE id_venta IN (1, 3, 5, 7, 9)  AND canal IS NULL;
UPDATE ventas SET canal = 'Presencial' WHERE id_venta IN (2, 4, 6, 8, 10) AND canal IS NULL;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ventas_canal'
)
    ALTER TABLE ventas
    ADD CONSTRAINT CK_ventas_canal
        CHECK (canal IN ('Online', 'Presencial'));
GO


-- ───────────────────────────────────────────────────────────
-- 5. Registros sin movimiento (para las Consultas 2 y 3 de M5)
-- ───────────────────────────────────────────────────────────

-- Cliente 6: registrado, nunca compró
IF NOT EXISTS (SELECT 1 FROM clientes WHERE id_cliente = 6)
    INSERT INTO clientes (id_cliente, nombre, email, ciudad, fecha_registro, id_territorio, segmento)
    VALUES (6, 'Sofía Herrera', 'sofia@mail.com', 'Salta', '2024-03-20', 6, 'Consumidor final');
GO

-- Producto 7: en catálogo, nunca vendido
IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = 7)
    INSERT INTO productos (id_producto, nombre_producto, id_categoria, precio, stock, activo)
    VALUES (7, 'Parlante Bluetooth', 3, 60.00, 45, 1);
GO


-- ───────────────────────────────────────────────────────────
-- 6. Verificación
-- ───────────────────────────────────────────────────────────
SELECT * FROM territorios;
SELECT id_cliente, nombre, ciudad, id_territorio, segmento, fecha_registro FROM clientes;
SELECT id_venta, id_cliente, id_producto, cantidad, precio_unitario, fecha_venta, canal FROM ventas;
SELECT id_producto, nombre_producto, id_categoria, precio FROM productos;
GO
