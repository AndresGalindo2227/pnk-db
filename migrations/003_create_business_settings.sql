-- =============================================================================
-- Migration 003 - Business settings
-- -----------------------------------------------------------------------------
-- One row with the data of the business that uses this installation (name,
-- tax id, contact, opening hours, booking rules). This is what lets the same
-- InvFox code be sold to different customers: each one only edits this row.
-- The CHECK constraint guarantees there is never more than one row (id = 1).
-- =============================================================================

CREATE TABLE IF NOT EXISTS business_settings (
  id                       TINYINT UNSIGNED NOT NULL DEFAULT 1,
  business_name            VARCHAR(150)  NOT NULL,
  legal_name               VARCHAR(150)  NULL,
  tax_id                   VARCHAR(20)   NULL COMMENT 'NIT with verification digit, e.g. 901519959-1',
  address                  VARCHAR(200)  NULL,
  city                     VARCHAR(80)   NULL,
  phone                    VARCHAR(30)   NULL,
  email                    VARCHAR(150)  NULL,
  logo_path                VARCHAR(255)  NULL,
  currency                 CHAR(3)       NOT NULL DEFAULT 'COP',
  timezone                 VARCHAR(64)   NOT NULL DEFAULT 'America/Bogota',
  opens_at                 TIME          NOT NULL DEFAULT '08:00:00' COMMENT 'First bookable slot of the day',
  closes_at                TIME          NOT NULL DEFAULT '23:00:00' COMMENT 'End of the last bookable slot',
  slot_minutes             SMALLINT UNSIGNED NOT NULL DEFAULT 60,
  deposit_percent          TINYINT UNSIGNED  NOT NULL DEFAULT 50 COMMENT 'Deposit required to confirm a booking',
  cancellation_min_hours   TINYINT UNSIGNED  NOT NULL DEFAULT 3  COMMENT 'Minimum hours before start to cancel',
  updated_at               TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT ck_business_settings_single_row CHECK (id = 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
