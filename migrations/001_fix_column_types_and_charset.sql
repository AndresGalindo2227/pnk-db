-- =============================================================================
-- Migration 001 - Fix column types and character set
-- -----------------------------------------------------------------------------
-- * Money columns:   FLOAT  -> DECIMAL(12,2)  (FLOAT causes rounding errors)
-- * Document numbers: INT   -> VARCHAR(20)    (INT overflows above 2,147,483,647
--                                              and drops leading zeros)
-- * Zero dates (0000-00-00) -> NULL           (invalid dates; rejected in strict mode)
-- * Columns the code never fills now have defaults, so inserts work in strict mode
-- * Database and tables: utf8 -> utf8mb4      (full Unicode, including emojis)
--
-- Run as root (the invfox_app user cannot ALTER tables).
-- Take a database backup before running it.
-- =============================================================================

-- Allow reading and fixing the legacy zero dates during this session only.
SET SESSION sql_mode = '';

ALTER DATABASE invfox CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------- categorias
ALTER TABLE categorias CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE categorias
  MODIFY categoria VARCHAR(100) NOT NULL;

-- ---------------------------------------------------------------- clientes
ALTER TABLE clientes CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
UPDATE clientes SET ultima_compra = NULL WHERE ultima_compra = '0000-00-00 00:00:00';
UPDATE clientes SET fecha_nacimiento = NULL WHERE fecha_nacimiento = '0000-00-00';
ALTER TABLE clientes
  MODIFY nombre           VARCHAR(150) NOT NULL,
  MODIFY documento        VARCHAR(20)  NOT NULL,
  MODIFY email            VARCHAR(150) NOT NULL DEFAULT '',
  MODIFY telefono         VARCHAR(30)  NOT NULL DEFAULT '',
  MODIFY direccion        VARCHAR(200) NOT NULL DEFAULT '',
  MODIFY fecha_nacimiento DATE         NULL DEFAULT NULL,
  MODIFY compras          INT          NOT NULL DEFAULT 0,
  MODIFY ultima_compra    DATETIME     NULL DEFAULT NULL;
UPDATE clientes SET ultima_compra = NULL WHERE ultima_compra = '0000-00-00 00:00:00';

-- ---------------------------------------------------------------- proveedor
ALTER TABLE proveedor CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE proveedor
  MODIFY nombre    VARCHAR(150) NOT NULL,
  MODIFY documento VARCHAR(20)  NOT NULL,
  MODIFY email     VARCHAR(150) NOT NULL DEFAULT '',
  MODIFY telefono  VARCHAR(30)  NOT NULL DEFAULT '',
  MODIFY direccion VARCHAR(200) NOT NULL DEFAULT '';

-- ---------------------------------------------------------------- productos
ALTER TABLE productos CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE productos
  MODIFY nombre_pro    VARCHAR(200)  NOT NULL,
  MODIFY codigo        VARCHAR(50)   NOT NULL,
  MODIFY descripcion   VARCHAR(255)  NOT NULL,
  MODIFY imagen        VARCHAR(255)  NOT NULL DEFAULT '',
  MODIFY stock         INT           NOT NULL DEFAULT 0,
  MODIFY precio_compra DECIMAL(12,2) NOT NULL DEFAULT 0,
  MODIFY precio_venta  DECIMAL(12,2) NOT NULL DEFAULT 0,
  MODIFY ventas        INT           NOT NULL DEFAULT 0;

-- ---------------------------------------------------------------- usuarios
ALTER TABLE usuarios CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
UPDATE usuarios SET ultimo_login = NULL WHERE ultimo_login = '0000-00-00 00:00:00';
ALTER TABLE usuarios
  MODIFY nombre       VARCHAR(150) NOT NULL,
  MODIFY usuario      VARCHAR(50)  NOT NULL,
  MODIFY password     VARCHAR(255) NOT NULL,
  MODIFY perfil       VARCHAR(30)  NOT NULL,
  MODIFY foto         VARCHAR(255) NOT NULL DEFAULT '',
  MODIFY estado       TINYINT(1)   NOT NULL DEFAULT 0,
  MODIFY ultimo_login DATETIME     NULL DEFAULT NULL;
UPDATE usuarios SET ultimo_login = NULL WHERE ultimo_login = '0000-00-00 00:00:00';

-- ---------------------------------------------------------------- ventas
ALTER TABLE ventas CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE ventas
  MODIFY id_tecnico  INT           NULL DEFAULT NULL,
  MODIFY productos   LONGTEXT      NOT NULL,
  MODIFY impuesto    DECIMAL(12,2) NOT NULL DEFAULT 0,
  MODIFY neto        DECIMAL(12,2) NOT NULL DEFAULT 0,
  MODIFY total       DECIMAL(12,2) NOT NULL DEFAULT 0,
  MODIFY metodo_pago VARCHAR(50)   NOT NULL DEFAULT '';
-- 0 was used to mean "no technician"; NULL expresses that and allows a foreign key.
UPDATE ventas SET id_tecnico = NULL WHERE id_tecnico = 0;

-- ---------------------------------------------------------------- compra
ALTER TABLE compra CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE compra
  MODIFY productos LONGTEXT      NOT NULL,
  MODIFY impuesto  DECIMAL(12,2) NOT NULL DEFAULT 0,
  MODIFY neto      DECIMAL(12,2) NOT NULL DEFAULT 0,
  MODIFY total     DECIMAL(12,2) NOT NULL DEFAULT 0;
