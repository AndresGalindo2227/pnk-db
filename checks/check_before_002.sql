-- =============================================================================
-- Pre-check for migration 002 (foreign keys and unique indexes).
-- Run it BEFORE 002. Every query must return 0 rows.
-- If a query returns rows, fix or delete those records first, otherwise 002 fails.
-- =============================================================================

-- Sales whose customer does not exist
SELECT v.id, v.codigo, v.id_cliente FROM ventas v LEFT JOIN clientes c ON c.id = v.id_cliente WHERE c.id IS NULL;

-- Sales whose seller does not exist
SELECT v.id, v.codigo, v.id_vendedor FROM ventas v LEFT JOIN usuarios u ON u.id = v.id_vendedor WHERE u.id IS NULL;

-- Sales whose technician does not exist (0 and NULL are allowed: "no technician")
SELECT v.id, v.codigo, v.id_tecnico FROM ventas v LEFT JOIN usuarios u ON u.id = v.id_tecnico
 WHERE v.id_tecnico IS NOT NULL AND v.id_tecnico <> 0 AND u.id IS NULL;

-- Purchases whose supplier does not exist
SELECT c.id, c.codigo, c.id_proveedor FROM compra c LEFT JOIN proveedor p ON p.id = c.id_proveedor WHERE p.id IS NULL;

-- Purchases whose buyer (user) does not exist
SELECT c.id, c.codigo, c.id_vendedor FROM compra c LEFT JOIN usuarios u ON u.id = c.id_vendedor WHERE u.id IS NULL;

-- Duplicated usernames, sale codes and purchase codes
SELECT usuario, COUNT(*) AS total FROM usuarios GROUP BY usuario HAVING total > 1;
SELECT codigo, COUNT(*) AS total FROM ventas GROUP BY codigo HAVING total > 1;
SELECT codigo, COUNT(*) AS total FROM compra GROUP BY codigo HAVING total > 1;
