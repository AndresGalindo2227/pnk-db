# pnk-db

Versioned database migrations of **PANENKA Booking**: the legacy **InvFox** point-of-sale schema
plus the booking module (fields, sectors, bookings, payments, players, refresh tokens).

| | |
|---|---|
| Engine | MySQL 8 / MariaDB 10.4+ (InnoDB, `utf8mb4_unicode_ci`) |
| Consumers | InvFox (PHP) and [`pnk-api`](https://github.com/AndresGalindo2227/pnk-api) |
| Architecture | [ADR-004 — Booking consistency](https://github.com/AndresGalindo2227/pnk-docs/blob/main/01-architecture/decisions/records/ADR-004-booking-consistency-and-offline-strategy.md), [ADR-005 — REST API integrated with InvFox](https://github.com/AndresGalindo2227/pnk-docs/blob/main/01-architecture/decisions/records/ADR-005-backend-rest-api-integrated-with-invfox.md) |
| Documentation hub | [`pnk-docs`](https://github.com/AndresGalindo2227/pnk-docs) |

---

## Layout

| Folder | Content |
|--------|---------|
| `migrations/` | Numbered SQL files. Each one changes the structure **once**, in order. |
| `checks/` | Read-only (or rolled-back) queries to run before a risky migration or to demo a rule. |

### Rules

1. **Never edit a migration that was already run** in any database. Create a new numbered file.
2. One migration = one purpose. File name: `NNN_verb_object.sql` in English.
3. Every migration starts with a header comment: what it does, why, and what it depends on.
4. **No real data** in this repository: no customers, sales, products, user hashes or backups.
   Only structure and demo seed data (`005`).
5. Migrations run as `root`; the applications use the least-privilege user `invfox_app`.

---

## Migrations

| # | File | What it does | Depends on |
|---|------|--------------|-----------|
| 000 | `000_baseline_invfox_schema.sql` | Legacy InvFox tables (structure only). **Skip it on existing installations.** | — |
| 001 | `001_fix_column_types_and_charset.sql` | DECIMAL money, VARCHAR documents, NULL instead of zero dates, defaults, utf8mb4 | 000 |
| 002 | `002_add_foreign_keys_and_indexes.sql` | Foreign keys, unique usernames and codes, search indexes | 001 + `checks/check_before_002.sql` returns 0 rows |
| 003 | `003_create_business_settings.sql` | Single-row table with business data and booking rules | — |
| 004 | `004_create_booking_module.sql` | `field_units`, `fields`, `field_unit_map`, `players`, `bookings`, `booking_slots`, `payments`, `refresh_tokens` | 001, 002 |
| 005 | `005_seed_demo_data.sql` | Business row, sectors A-B-C, fields 5A/5B/5C ($70.000) and 9 ($210.000) | 003, 004 |

### The anti double-booking rule

`booking_slots` has primary key `(unit_id, slot_start)`: a physical sector can be held only once per
hour. `Cancha 9` occupies sectors A + B + C, each `Cancha 5` occupies one sector, so the database itself
rejects overlapping bookings (SQLSTATE 23000 → API `409 SLOT_ALREADY_TAKEN`).
`checks/booking_rules_demo.sql` proves it and rolls back, leaving no data.

---

## How to run the migrations (XAMPP / phpMyAdmin)

**Existing InvFox database** (already has the legacy tables):

1. Back up first: database `invfox` → *Export* → *Quick* → *SQL*. Keep the file **outside** this repo.
2. Log in to phpMyAdmin as `root`, select `invfox`, open the *SQL* tab.
3. Run `001`, then `checks/check_before_002.sql` (all queries must return 0 rows), then `002` … `005`,
   one file at a time. Every statement must finish without errors.

**New installation** (empty database):

1. Create an empty database with collation `utf8mb4_unicode_ci`.
2. Select it and run `000`, `001`, `check_before_002`, `002`, `003`, `004`, `005` in order.
3. Create the first InvFox administrator (the repository has no users on purpose):

   ```bash
   # Generate the hash locally; never commit it.
   php -r "echo password_hash('YOUR-STRONG-PASSWORD', PASSWORD_DEFAULT), PHP_EOL;"
   ```

   ```sql
   INSERT INTO usuarios (nombre, usuario, password, perfil, estado)
   VALUES ('Administrator', 'admin', '<paste-the-hash>', 'Administrador', 1);
   ```

### Database users

| User | Used by | Privileges |
|------|---------|------------|
| `root` | phpMyAdmin, migrations | All — never used by an application |
| `invfox_app` | InvFox and `pnk-api` (credentials only in each app's ignored config file) | `SELECT, INSERT, UPDATE, DELETE` on the InvFox database |

---

## Branches

`develop` → `qa` → `main`, promoted with cherry-pick pull requests and squash merge, as defined in
[`git-conventions.md`](https://github.com/AndresGalindo2227/pnk-docs/blob/main/00-governance/git-conventions.md).
