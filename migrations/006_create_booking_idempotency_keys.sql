-- =============================================================================
-- Migration 006 - Idempotency keys of POST /bookings
-- -----------------------------------------------------------------------------
-- The app sends an Idempotency-Key (UUID) with every booking attempt. If the
-- request is retried after a network error, pnk-api finds the key and returns
-- the booking already created instead of creating a second one.
-- Depends on: 004.
-- =============================================================================

CREATE TABLE IF NOT EXISTS booking_idempotency_keys (
  idempotency_key  CHAR(36)     NOT NULL,
  player_id        INT UNSIGNED NOT NULL,
  booking_id       INT UNSIGNED NOT NULL,
  created_at       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (idempotency_key),
  KEY ix_idempotency_player (player_id),
  CONSTRAINT fk_idempotency_player  FOREIGN KEY (player_id)  REFERENCES players (id)  ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_idempotency_booking FOREIGN KEY (booking_id) REFERENCES bookings (id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
