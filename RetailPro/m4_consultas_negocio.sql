-- ═══════════════════════════════════════════════════════════
-- Proyecto: RetailPro
-- Módulo 4 — Pre-entrega: Consultas SQL de negocio
-- Archivo: m4_consultas_negocio.sql
-- Base: Ventas_Tech_DB (SQL Server) · Tabla: ventas
-- Autor: Bruno
-- Fecha: 28/07/2026
-- ═══════════════════════════════════════════════════════════
-- NOTA SOBRE EL MOTOR
--   La base fue creada en M3 sobre SQL Server. La consigna de M4
--   indica EXTRACT(MONTH FROM fecha_venta), función que SQL Server
--   no implementa. Se usa su equivalente DATEPART(MONTH, fecha_venta),
--   que produce el mismo resultado. Del mismo modo, el límite de filas
--   se resuelve con TOP 5 y no con LIMIT.
--
-- SUPUESTOS
--   1. Total de una línea = cantidad * precio_unitario.
--   2. "Pedido" = una fila de ventas (el modelo de M3 no tiene
--      cabecera de pedido, así que cada línea es un pedido).
--   3. Los datos cargados en M3 abarcan un único mes (marzo 2024),
--      lo que limita el alcance de las Consultas 1 y 4. Ver el
--      bloque de cierre.
-- ═══════════════════════════════════════════════════════════

USE Ventas_Tech_DB;
GO


-- ───────────────────────────────────────────────────────────
-- Consulta 1 — Resumen ejecutivo mensual
-- Total facturado, cantidad de pedidos y ticket promedio por mes.
-- ───────────────────────────────────────────────────────────
SELECT
    DATEPART(MONTH, fecha_venta)    AS mes,
    SUM(cantidad * precio_unitario) AS total_facturado,
    COUNT(*)                        AS cantidad_pedidos,
    AVG(cantidad * precio_unitario) AS ticket_promedio
FROM ventas
GROUP BY DATEPART(MONTH, fecha_venta)
ORDER BY mes;

-- Con los datos actuales devuelve una sola fila (mes 3).
-- La consulta queda escrita para escalar cuando la tabla cubra
-- más meses. Si además llegara a cubrir más de un año, habría que
-- agregar DATEPART(YEAR, fecha_venta) al SELECT y al GROUP BY para
-- que marzo de dos años distintos no colapse en la misma fila.


-- ───────────────────────────────────────────────────────────
-- Consulta 2 — Ranking de productos
-- Top 5 de id_producto por total facturado.
-- ───────────────────────────────────────────────────────────
SELECT TOP 5
    id_producto,
    SUM(cantidad)                   AS unidades_vendidas,
    SUM(cantidad * precio_unitario) AS total_generado
FROM ventas
GROUP BY id_producto
ORDER BY total_generado DESC;

-- Advertencia de lectura: el corte del top 5 es frágil. El quinto
-- puesto (producto 2, $364,00) y el sexto (producto 4, $360,00)
-- difieren en $4,00 — poco más del 1%. Presentar este ranking como
-- "los 5 productos que importan" induciría una conclusión que un
-- solo pedido más podría invertir.


-- ───────────────────────────────────────────────────────────
-- Consulta 3 — Clientes recurrentes
-- Clientes con más de un pedido, con su volumen de gasto.
-- ───────────────────────────────────────────────────────────
SELECT
    id_cliente,
    COUNT(*)                        AS cantidad_pedidos,
    SUM(cantidad * precio_unitario) AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;

-- Esta consulta filtra: devuelve únicamente a los recurrentes.
-- Para afirmar qué proporción del total representan hace falta
-- el denominador, que se obtiene con SELECT COUNT(DISTINCT id_cliente)
-- FROM ventas. Ese dato se usó para redactar el hallazgo 2.


-- ───────────────────────────────────────────────────────────
-- Consulta 4 — Meses por encima / por debajo del promedio
-- Criterio de empate: un mes exactamente igual al promedio se
-- etiqueta 'Por encima' (decisión explícita).
-- ───────────────────────────────────────────────────────────
WITH ventas_mensuales AS (
    SELECT
        DATEPART(MONTH, fecha_venta)    AS mes,
        SUM(cantidad * precio_unitario) AS total_mes
    FROM ventas
    GROUP BY DATEPART(MONTH, fecha_venta)
)
SELECT
    mes,
    total_mes,
    (SELECT AVG(total_mes) FROM ventas_mensuales) AS promedio_general,
    CASE
        WHEN total_mes >= (SELECT AVG(total_mes) FROM ventas_mensuales)
            THEN 'Por encima'
        ELSE 'Por debajo'
    END AS evaluacion_promedio
FROM ventas_mensuales
ORDER BY mes;

-- Con un único mes cargado, esta consulta no discrimina: el total
-- del mes coincide con el promedio general y la etiqueta resulta
-- 'Por encima' por construcción, no por desempeño. La lógica es
-- correcta y produce una comparación real en cuanto existan dos o
-- más meses; hoy su resultado no debe leerse como un hallazgo.


-- ═══════════════════════════════════════════════════════════
-- BLOQUE DE CIERRE: Hallazgos de negocio
-- ═══════════════════════════════════════════════════════════
-- Facturación total del período: $6.444,00 sobre 10 pedidos
-- (ticket promedio $644,40), entre el 05/03/2024 y el 15/03/2024.
--
-- 1. LA FACTURACIÓN SE CONCENTRA EN UN PRODUCTO CARO, NO EN UNO
--    POPULAR. El producto 1 genera $3.600,00, el 55,87% de la
--    facturación total, con apenas 3 unidades vendidas. En el otro
--    extremo, el producto 2 es el más vendido en volumen (13
--    unidades) pero aporta $364,00, el 5,65%. Un ranking por
--    unidades y uno por facturación darían recomendaciones
--    opuestas al equipo comercial: conviene explicitar cuál se
--    está usando antes de decidir sobre stock o promociones.
--
-- 2. NO HAY CLIENTES DE COMPRA ÚNICA. Los 5 clientes distintos
--    registrados hicieron exactamente 2 pedidos cada uno: la
--    recurrencia es del 100%. Dos de ellos (clientes 1 y 5)
--    concentran $4.740,00, el 73,56% de la facturación, pese a
--    que todos compraron la misma cantidad de veces. La diferencia
--    la explica el ticket, no la frecuencia. Nota metodológica: una
--    uniformidad tan exacta sugiere un dataset sintético de prueba,
--    no un comportamiento de compra real; el dato no es extrapolable.
--
-- 3. EL PERÍODO NO PERMITE ANÁLISIS TEMPORAL. Las 10 ventas caen
--    en un rango de 11 días de marzo de 2024. Con un solo mes no
--    se puede evaluar tendencia, ni comparar meses contra el
--    promedio, ni hablar de estacionalidad — que además requeriría
--    observar el patrón repetido a lo largo de más de un año. La
--    Consulta 4 queda escrita y operativa, pero su resultado hoy
--    es tautológico. Antes de llevar métricas temporales a Power BI
--    en M6, la tabla necesita cobertura de varios meses.
-- ═══════════════════════════════════════════════════════════
