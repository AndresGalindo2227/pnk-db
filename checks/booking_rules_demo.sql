-- =============================================================================
-- Demo of the booking rules (run AFTER 004 and 005, on a development database).
-- Everything runs inside a transaction and is rolled back at the end,
-- so it leaves no data behind.
-- =============================================================================

START TRANSACTION;

INSERT INTO players (full_name, email, phone, password_hash)
VALUES ('Demo Player', 'demo@example.com', '3000000000', 'x');
SET @player = LAST_INSERT_ID();

-- 1) Book Cancha 5A today at 18:00 and hold its sector (A)
INSERT INTO bookings (code, field_id, player_id, starts_at, ends_at, total_amount, deposit_amount)
SELECT 'DEMO-5A', id, @player, CONCAT(CURDATE(), ' 18:00:00'), CONCAT(CURDATE(), ' 19:00:00'), 70000, 35000
  FROM fields WHERE name = 'Cancha 5A';
SET @b5a = LAST_INSERT_ID();
INSERT INTO booking_slots (unit_id, slot_start, booking_id)
SELECT m.unit_id, CONCAT(CURDATE(), ' 18:00:00'), @b5a
  FROM field_unit_map m JOIN fields f ON f.id = m.field_id WHERE f.name = 'Cancha 5A';

-- 2) Availability at 18:00: only 5B and 5C must appear
SELECT f.name AS available_at_18h
  FROM fields f
 WHERE f.is_active = 1
   AND NOT EXISTS (SELECT 1 FROM field_unit_map m
                     JOIN booking_slots s ON s.unit_id = m.unit_id
                    WHERE m.field_id = f.id AND s.slot_start = CONCAT(CURDATE(), ' 18:00:00'));

ROLLBACK;

-- 3) To see the database REJECT a double booking, run the block above again
--    but, before the ROLLBACK, try to hold the three sectors for Cancha 9:
--      INSERT INTO booking_slots (unit_id, slot_start, booking_id)
--      SELECT m.unit_id, CONCAT(CURDATE(), ' 18:00:00'), @b5a
--        FROM field_unit_map m JOIN fields f ON f.id = m.field_id WHERE f.name = 'Cancha 9';
--    Expected: #1062 Duplicate entry '...-18:00:00' for key 'PRIMARY'
--    (Sector A is already held by the 5A booking).
