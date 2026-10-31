-- =============================================================================
-- Migration 002 - Foreign keys and indexes
-- -----------------------------------------------------------------------------
-- Foreign keys make the database itself reject orphan records: a sale can no
-- longer point to a customer, seller or technician that does not exist, and a
-- customer with sales cannot be deleted (ON DELETE RESTRICT).
-- Unique indexes stop duplicated usernames and duplicated sale/purchase codes.
--
-- BEFORE running it: run database/checks/check_before_002.sql (all queries must
-- return 0 rows). Run as root.
-- =============================================================================

-- ---------------------------------------------------------------- unique values
ALTER TABLE usuarios ADD UNIQUE KEY uq_usuarios_usuario (usuario);
ALTER TABLE ventas   ADD UNIQUE KEY uq_ventas_codigo (codigo);
ALTER TABLE compra   ADD UNIQUE KEY uq_compra_codigo (codigo);

-- ---------------------------------------------------------------- search indexes
ALTER TABLE productos ADD KEY ix_productos_codigo (codigo);
ALTER TABLE productos ADD KEY ix_productos_descripcion (descripcion);
ALTER TABLE clientes  ADD KEY ix_clientes_documento (documento);
ALTER TABLE ventas    ADD KEY ix_ventas_fecha (fecha);
ALTER TABLE compra    ADD KEY ix_compra_fecha (fecha);

-- ---------------------------------------------------------------- sales
ALTER TABLE ventas
  ADD CONSTRAINT fk_ventas_cliente  FOREIGN KEY (id_cliente)  REFERENCES clientes (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  ADD CONSTRAINT fk_ventas_vendedor FOREIGN KEY (id_vendedor) REFERENCES usuarios (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  ADD CONSTRAINT fk_ventas_tecnico  FOREIGN KEY (id_tecnico)  REFERENCES usuarios (id) ON UPDATE CASCADE ON DELETE RESTRICT;

-- ---------------------------------------------------------------- purchases
ALTER TABLE compra
  ADD CONSTRAINT fk_compra_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedor (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  ADD CONSTRAINT fk_compra_vendedor  FOREIGN KEY (id_vendedor)  REFERENCES usuarios (id)  ON UPDATE CASCADE ON DELETE RESTRICT;
