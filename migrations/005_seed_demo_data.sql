-- =============================================================================
-- Migration 005 - Demo data (development and demos only)
-- -----------------------------------------------------------------------------
-- PANENKA layout: one soccer-9 pitch split into three soccer-5 sectors.
--   Cancha 5A / 5B / 5C  ->  $70.000 per hour, one sector each
--   Cancha 9             ->  $210.000 per hour, all three sectors
-- Edit the values for each real installation.
-- =============================================================================

INSERT INTO business_settings (id, business_name, city, currency, timezone, opens_at, closes_at, slot_minutes, deposit_percent, cancellation_min_hours)
VALUES (1, 'PANENKA Canchas Sinteticas', 'Neiva', 'COP', 'America/Bogota', '08:00:00', '23:00:00', 60, 50, 3)
ON DUPLICATE KEY UPDATE business_name = VALUES(business_name);

-- Physical sectors
INSERT INTO field_units (name) VALUES ('Sector A'), ('Sector B'), ('Sector C')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- Bookable fields and prices
INSERT INTO fields (name, field_type, hourly_price) VALUES
  ('Cancha 5A', 'F5', 70000.00),
  ('Cancha 5B', 'F5', 70000.00),
  ('Cancha 5C', 'F5', 70000.00),
  ('Cancha 9',  'F9', 210000.00)
ON DUPLICATE KEY UPDATE hourly_price = VALUES(hourly_price), field_type = VALUES(field_type);

-- Which sectors each field occupies
INSERT IGNORE INTO field_unit_map (field_id, unit_id)
SELECT f.id, u.id FROM fields f JOIN field_units u
 WHERE (f.name = 'Cancha 5A' AND u.name = 'Sector A')
    OR (f.name = 'Cancha 5B' AND u.name = 'Sector B')
    OR (f.name = 'Cancha 5C' AND u.name = 'Sector C')
    OR (f.name = 'Cancha 9'  AND u.name IN ('Sector A', 'Sector B', 'Sector C'));
