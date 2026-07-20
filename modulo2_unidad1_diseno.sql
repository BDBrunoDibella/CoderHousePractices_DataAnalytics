-- modulo2_unidad1_diseno.sql
-- Sistema de gestión de ventas


-- Tabla: clientes
CREATE TABLE clientes (
    id_cliente      INT,                   -- identificador numérico entero simple (sin decimales)
    nombre          VARCHAR(100),          -- texto corto de hasta 100 caracteres
    perfil_bio      VARCHAR(MAX),          -- texto largo/variable para biografía o notas
    fecha_registro  DATE                   -- solo fecha 
);

-- Tabla: productos
CREATE TABLE productos (
    id_producto     INT,                  -- identificador numérico entero simple
    descripcion     VARCHAR(255),         -- texto corto de hasta 255 caracteres
    precio          DECIMAL(10,2),        -- precio/importe: DECIMAL para dinero con 2 decimales
    esta_activo     BIT                   -- booleano: indica si el producto está activo (a la venta)
);
