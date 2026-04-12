---
description: Database conventions — migration-first workflow, schema design, multi-tenancy. Critical rules for SQL and migration files.
globs:
  - "**/*.sql"
  - "**/supabase/**"
---

# Database Conventions

Generic database conventions for migration-first development. If you are writing a migration file, creating a database function, or setting up DB tests, invoke the `ccupa:db-conventions` skill for step-by-step workflow and code templates.

## Critical Rules

1. **NEVER make schema changes without a migration file** — create the file, then apply it. Even "quick fixes" need migrations.
2. **NEVER use destructive database resets** (`supabase db reset`, etc.) — apply migrations individually.
3. **NEVER change a function's return type in-place** (PostgreSQL) — `DROP FUNCTION IF EXISTS` first, then `CREATE OR REPLACE`.

## Migration Naming

- `add_<table>` — new table
- `add_<column>_to_<table>` — new column
- `create_<function>` — new database function
- `update_<function>` — modify existing function
- `add_index_on_<table>_<column>` — new index

## Schema Design

- Normalize to 3NF by default; denormalize only with measured evidence
- Index foreign keys and multi-tenant WHERE columns; don't over-index
- Use `NOT NULL`, `REFERENCES` (with `ON DELETE CASCADE`), `UNIQUE`, and `CHECK` constraints
- Every tenant-specific table must include `organization_id` scoping

## Common Gotchas

1. **CASCADE on FK constraints** — use `ON DELETE CASCADE` or deletes will fail when related records exist
2. **Altering return types** — PostgreSQL requires `DROP FUNCTION` before recreating with a new return type; `CREATE OR REPLACE` alone fails
3. **RETURN QUERY** — use `RETURN QUERY SELECT ...` for TABLE returns, not `RETURN (SELECT ...)`
