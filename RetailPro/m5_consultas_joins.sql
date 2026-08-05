-- ═══════════════════════════════════════════════════════════
-- Proyecto: RetailPro
-- Módulo 5 — Pre-entrega: Consultas con JOINs
-- Archivo: m5_consultas_joins.sql
-- Base: Ventas_Tech_DB (SQL Server)
-- Autor: Bruno
-- Fecha: 05/08/2026
-- ═══════════════════════════════════════════════════════════
-- REQUISITO PREVIO
--   Ejecutar en orden: m3_creacion_base.sql → m3b_ampliacion_esquema.sql
--   El segundo agrega `territorios`, `clientes.segmento` y `ventas.canal`,
--   que M5 requiere y M3 no había solicitado.
--
-- SUPUESTOS
--   1. Total de venta = cantidad * precio_unitario.
--   2. El modelo no tiene cabecera de pedido: cada fila de `ventas`
--      es una línea y a la vez un pedido.
--   3. La región proviene de `territorios`, vinculada al cliente y no
--      a la venta. Es decir: región del comprador, no del punto de
--      venta. Con el modelo actual no hay forma de distinguirlas.
-- ═══════════════════════════════════════════════════════════

USE Ventas_Tech_DB;
GO


-- ───────────────────────────────────────────────────────────
-- Consulta 1 — Vista base del proyecto (INNER JOIN)
-- Fuente de datos principal para el dashboard de M7.
-- ───────────────────────────────────────────────────────────
SELECT
    v.fecha_venta                     AS fecha,
    c.nombre                          AS cliente,
    c.segmento,
    t.region,
    p.nombre_producto                 AS producto,
    cat.nombre_categoria              AS categoria,
    v.cantidad,
    v.precio_unitario,
    (v.cantidad * v.precio_unitario)  AS total_venta,
    v.canal
FROM ventas v
INNER JOIN clientes    c   ON v.id_cliente    = c.id_cliente
INNER JOIN territorios t   ON c.id_territorio = t.id_territorio
INNER JOIN productos   p   ON v.id_producto   = p.id_producto
INNER JOIN categorias  cat ON p.id_categoria  = cat.id_categoria
ORDER BY v.fecha_venta, v.id_venta;

-- Todos los JOINs son INNER porque las cuatro relaciones están
-- garantizadas por claves foráneas NOT NULL: ninguna venta puede
-- existir sin cliente ni producto, y ningún producto sin categoría.
-- La única excepción sería `clientes.id_territorio`, que admite NULL;
-- si en el futuro se cargara un cliente sin ciudad reconocida, sus
-- ventas desaparecerían de esta vista. Convendría entonces migrar
-- ese JOIN a LEFT.


-- ───────────────────────────────────────────────────────────
-- Consulta 2 — Clientes sin ventas (LEFT JOIN)
-- Requerimiento del área de CRM.
-- ───────────────────────────────────────────────────────────
SELECT
    c.nombre          AS cliente,
    c.email,
    c.fecha_registro
FROM clientes c
LEFT JOIN ventas v
    ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL
ORDER BY c.fecha_registro;

-- El filtro se aplica sobre `ventas.id_venta`, clave primaria de la
-- tabla: al no admitir NULL en su origen, un NULL en el resultado
-- sólo puede provenir de la ausencia de coincidencia en el JOIN.
-- Filtrar sobre una columna que sí acepta nulos produciría falsos
-- positivos.


-- ───────────────────────────────────────────────────────────
-- Consulta 3 — Productos sin ventas (LEFT JOIN)
-- Requerimiento del área de producto.
-- ───────────────────────────────────────────────────────────
SELECT
    p.nombre_producto     AS producto,
    cat.nombre_categoria  AS categoria,
    p.precio
FROM productos p
INNER JOIN categorias cat
    ON p.id_categoria = cat.id_categoria
LEFT JOIN ventas v
    ON p.id_producto = v.id_producto
WHERE v.id_venta IS NULL
ORDER BY p.nombre_producto;

-- Convivencia de INNER y LEFT en una misma consulta: la categoría
-- se cruza con INNER porque `id_categoria` es NOT NULL y siempre
-- resuelve; las ventas con LEFT porque su ausencia es precisamente
-- lo que se busca detectar.


-- ───────────────────────────────────────────────────────────
-- Consulta 4 — Consolidado por canal (UNION ALL)
-- ───────────────────────────────────────────────────────────

-- 4.a — Apilado de ambos canales con la columna de origen
SELECT
    v.id_venta,
    v.fecha_venta,
    c.nombre                          AS cliente,
    p.nombre_producto                 AS producto,
    (v.cantidad * v.precio_unitario)  AS total_venta,
    'Online'                          AS canal
FROM ventas v
INNER JOIN clientes  c ON v.id_cliente  = c.id_cliente
INNER JOIN productos p ON v.id_producto = p.id_producto
WHERE v.canal = 'Online'

UNION ALL

SELECT
    v.id_venta,
    v.fecha_venta,
    c.nombre                          AS cliente,
    p.nombre_producto                 AS producto,
    (v.cantidad * v.precio_unitario)  AS total_venta,
    'Presencial'                      AS canal
FROM ventas v
INNER JOIN clientes  c ON v.id_cliente  = c.id_cliente
INNER JOIN productos p ON v.id_producto = p.id_producto
WHERE v.canal = 'Presencial'

ORDER BY id_venta;

-- 4.b — Total por canal sobre el resultado apilado
SELECT
    canal,
    COUNT(*)          AS cantidad_ventas,
    SUM(total_venta)  AS total_facturado
FROM (
    SELECT
        (v.cantidad * v.precio_unitario) AS total_venta,
        'Online' AS canal
    FROM ventas v
    WHERE v.canal = 'Online'

    UNION ALL

    SELECT
        (v.cantidad * v.precio_unitario) AS total_venta,
        'Presencial' AS canal
    FROM ventas v
    WHERE v.canal = 'Presencial'
) AS ventas_consolidadas
GROUP BY canal
ORDER BY total_facturado DESC;

-- Nota metodológica: el UNION ALL aquí es didáctico, no funcional.
-- Como `canal` es una columna de `ventas` y no dos tablas separadas,
-- apilar dos SELECT filtrados reconstruye exactamente la tabla de
-- origen. El mismo resultado se obtiene con:
--
--     SELECT canal, COUNT(*), SUM(cantidad * precio_unitario)
--     FROM ventas GROUP BY canal;
--
-- El apilado sólo sería la vía correcta si cada canal viviera en su
-- propia tabla (por ejemplo `ventas_online` y `ventas_presencial`,
-- provenientes de sistemas distintos), que es el escenario real donde
-- UNION ALL resulta indispensable. Se resuelve como pide la consigna
-- por su valor de ejercitación, dejando asentada la observación.


-- ═══════════════════════════════════════════════════════════
-- BLOQUE DE CIERRE: Hallazgos de negocio
-- ═══════════════════════════════════════════════════════════
-- 1. LA VISTA ENRIQUECIDA HABILITA CORTES QUE M4 NO PODÍA HACER.
--    Las agregaciones de M4 sólo conocían identificadores: el
--    producto 1 y el cliente 5 eran códigos sin atributos. Al cruzar
--    las cuatro tablas, cada venta queda descrita por segmento,
--    región y categoría, que son las dimensiones sobre las que el
--    dashboard de M7 va a permitir filtrar. Esta consulta, y no las
--    de M4, es la que alimenta Power BI.
--
-- 2. HAY CATÁLOGO Y CARTERA INACTIVOS. La ampliación de esquema
--    incorporó un cliente registrado que nunca compró y un producto
--    nunca vendido. Con el dataset original de M3 ambas consultas
--    devolvían cero filas, no porque no hubiera inactividad sino
--    porque el dataset era demasiado chico para contenerla. La
--    inactividad detectada es, por lo tanto, un artefacto controlado
--    del dataset de prueba y no un hallazgo del negocio.
--
-- 3. EL ANÁLISIS POR REGIÓN ES ESTRUCTURALMENTE AMBIGUO. `region`
--    llega a la vista a través del cliente, no de la venta. Un
--    cliente de Mendoza que comprara en el local de Córdoba figuraría
--    como venta de Cuyo. Con el volumen actual la distinción es
--    irrelevante, pero antes de construir un mapa en M7 conviene
--    definir si la región que se reporta es la del comprador o la
--    del punto de venta: son métricas distintas y el modelo actual
--    sólo puede responder la primera.
--
-- 4. LAS LIMITACIONES DE M4 SIGUEN VIGENTES. El dataset continúa
--    cubriendo un único mes (5 al 15 de marzo de 2024) y 10 ventas.
--    Los cruces enriquecen las dimensiones disponibles, pero no
--    agregan volumen ni cobertura temporal: cualquier lectura de
--    tendencia o estacionalidad sigue siendo improcedente.
-- ═══════════════════════════════════════════════════════════
