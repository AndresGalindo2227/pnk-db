-- =============================================================================
-- Migration 004 - Booking module (PANENKA Booking)
-- -----------------------------------------------------------------------------
-- PANENKA has ONE physical soccer-9 field that can be booked whole, or split
-- into THREE soccer-5 fields. So we separate:
--
--   field_units     the physical sectors of the pitch (A, B, C)
--   fields          what a player can book ("Cancha 5A", "Cancha 9"...) and its price
--   field_unit_map  which sectors each bookable field occupies
--                   (Cancha 5A -> A ; Cancha 9 -> A + B + C)
--   bookings        one row per booking (history: pending, confirmed, cancelled...)
--   booking_slots   the sectors a booking is CURRENTLY holding, one row per
--                   sector and hour. Its primary key (unit_id, slot_start) means
--                   "a sector can be held by only one booking at a given hour".
--                   That single rule enforces every case:
--                     - 5A booked at 18:00 -> Cancha 9 at 18:00 is rejected (A is taken)
--                     - Cancha 9 booked    -> every soccer-5 field at 18:00 is rejected
--                     - 5A booked          -> 5B and 5C are still available
--                   Cancelling a booking deletes its rows here, freeing the sectors.
--   payments        deposits paid online (Wompi) or by transfer receipt
--   refresh_tokens  long-lived login tokens of the mobile app (stored hashed)
--
-- Double booking is therefore blocked by the DATABASE, even if two requests
-- arrive in the same second or the application code has a bug (see ADR-004).
-- =============================================================================

CREATE TABLE IF NOT EXISTS field_units (
  id          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  name        VARCHAR(50)   NOT NULL COMMENT 'Physical sector, e.g. Sector A',
  is_active   TINYINT(1)    NOT NULL DEFAULT 1,
  created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_field_units_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS fields (
  id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  name          VARCHAR(80)   NOT NULL COMMENT 'Name shown to players, e.g. Cancha 5A',
  field_type    VARCHAR(10)   NOT NULL COMMENT 'F5, F7, F9, F11',
  hourly_price  DECIMAL(12,2) NOT NULL,
  is_active     TINYINT(1)    NOT NULL DEFAULT 1,
  created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_fields_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS field_unit_map (
  field_id  INT UNSIGNED NOT NULL,
  unit_id   INT UNSIGNED NOT NULL,
  PRIMARY KEY (field_id, unit_id),
  KEY ix_field_unit_map_unit (unit_id),
  CONSTRAINT fk_field_unit_map_field FOREIGN KEY (field_id) REFERENCES fields (id)      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_field_unit_map_unit  FOREIGN KEY (unit_id)  REFERENCES field_units (id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS players (
  id             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  customer_id    INT           NULL COMMENT 'InvFox customer (clientes.id) created for this player',
  full_name      VARCHAR(150)  NOT NULL,
  email          VARCHAR(150)  NOT NULL,
  phone          VARCHAR(20)   NOT NULL,
  password_hash  VARCHAR(255)  NOT NULL COMMENT 'password_hash() output, never the plain password',
  is_active      TINYINT(1)    NOT NULL DEFAULT 1,
  last_login_at  DATETIME      NULL,
  created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_players_email (email),
  UNIQUE KEY uq_players_phone (phone),
  CONSTRAINT fk_players_customer FOREIGN KEY (customer_id) REFERENCES clientes (id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS bookings (
  id              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  code            VARCHAR(20)   NOT NULL COMMENT 'Public code shown to the player, e.g. PNK-2610-0087',
  field_id        INT UNSIGNED  NOT NULL,
  player_id       INT UNSIGNED  NOT NULL,
  starts_at       DATETIME      NOT NULL,
  ends_at         DATETIME      NOT NULL,
  status          ENUM('pending','confirmed','cancelled','completed','no_show') NOT NULL DEFAULT 'pending',
  total_amount    DECIMAL(12,2) NOT NULL COMMENT 'hourly_price x hours, copied at booking time',
  deposit_amount  DECIMAL(12,2) NOT NULL,
  sale_id         INT           NULL COMMENT 'InvFox sale (ventas.id) registered when the deposit is approved',
  cancelled_at    DATETIME      NULL,
  created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_bookings_code (code),
  KEY ix_bookings_field_start (field_id, starts_at),
  KEY ix_bookings_player (player_id, starts_at),
  CONSTRAINT ck_bookings_time_range CHECK (ends_at > starts_at),
  CONSTRAINT fk_bookings_field  FOREIGN KEY (field_id)  REFERENCES fields (id)  ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_bookings_player FOREIGN KEY (player_id) REFERENCES players (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_bookings_sale   FOREIGN KEY (sale_id)   REFERENCES ventas (id)  ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS booking_slots (
  unit_id     INT UNSIGNED NOT NULL,
  slot_start  DATETIME     NOT NULL COMMENT 'Start of the hour the sector is held',
  booking_id  INT UNSIGNED NOT NULL,
  -- THE anti double-booking rule: one booking per sector per hour.
  PRIMARY KEY (unit_id, slot_start),
  KEY ix_booking_slots_booking (booking_id),
  CONSTRAINT fk_booking_slots_unit    FOREIGN KEY (unit_id)    REFERENCES field_units (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_booking_slots_booking FOREIGN KEY (booking_id) REFERENCES bookings (id)    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payments (
  id                  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  booking_id          INT UNSIGNED  NOT NULL,
  method              ENUM('wompi','transfer_receipt','cash') NOT NULL,
  amount              DECIMAL(12,2) NOT NULL,
  status              ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  provider_reference  VARCHAR(100)  NULL COMMENT 'Wompi transaction id',
  receipt_path        VARCHAR(255)  NULL COMMENT 'Stored photo of the transfer receipt',
  reviewed_by         INT           NULL COMMENT 'InvFox user (usuarios.id) who approved or rejected it',
  reviewed_at         DATETIME      NULL,
  rejection_reason    VARCHAR(255)  NULL,
  created_at          TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_payments_provider_reference (provider_reference),
  KEY ix_payments_booking (booking_id),
  KEY ix_payments_status (status),
  CONSTRAINT fk_payments_booking  FOREIGN KEY (booking_id)  REFERENCES bookings (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_payments_reviewer FOREIGN KEY (reviewed_by) REFERENCES usuarios (id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  subject_type  ENUM('player','staff') NOT NULL COMMENT 'player = players.id, staff = usuarios.id',
  subject_id    INT UNSIGNED  NOT NULL,
  token_hash    CHAR(64)      NOT NULL COMMENT 'SHA-256 of the token; the plain token is never stored',
  expires_at    DATETIME      NOT NULL,
  revoked_at    DATETIME      NULL,
  user_agent    VARCHAR(255)  NULL,
  created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_refresh_tokens_hash (token_hash),
  KEY ix_refresh_tokens_subject (subject_type, subject_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
