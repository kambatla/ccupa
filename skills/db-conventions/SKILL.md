---
name: db-conventions
description: Database conventions reference — migration-first workflow with examples, multi-tenancy patterns, function templates, testing strategy. Use when writing migrations, database functions, or working with schema changes.
---

# Database Conventions

## Migration-First Workflow

### 1. Create Migration File

```bash
supabase migration new "descriptive_name_of_change"  # Supabase
alembic revision -m "descriptive_name_of_change"     # Alembic
python manage.py makemigrations                       # Django
```

**Naming:** `add_table_name`, `add_column_to_table`, `create_function_name`, `update_function_name`, `add_index_on_table_column`

### 2. Write the Migration

```sql
CREATE TABLE IF NOT EXISTS items (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Always add organization index for multi-tenant queries
CREATE INDEX idx_items_org ON items(organization_id);
```

### 3. Apply Migration

Apply individually — never batch-reset:

```bash
psql "connection-string" -f migrations/TIMESTAMP_file.sql
# or: supabase db push / alembic upgrade head / python manage.py migrate
```

### 4. Commit

Include migration filename in the commit body for traceability.

## Multi-Tenancy Patterns

Every tenant-specific table includes `organization_id`:

```sql
-- GOOD: Multi-tenant safe
WHERE id = p_item_id AND organization_id = p_organization_id

-- BAD: Could access other tenant's data
WHERE id = p_item_id
```

Consider RLS policies for defense-in-depth when the database is accessed from multiple services.

## Function Patterns

### Return Types
- Scalar (`INTEGER`, `BOOLEAN`) for simple operations
- `TABLE` for record queries
- `RETURN QUERY` syntax for TABLE returns:

```sql
-- GOOD
RETURN QUERY SELECT id, name FROM items;

-- BAD: won't work with TABLE return type
RETURN (SELECT id, name FROM items);
```

### Error Handling

```sql
IF NOT EXISTS(SELECT 1 FROM items WHERE id = p_item_id) THEN
    RETURN QUERY SELECT FALSE, 'Item not found'::VARCHAR;
    RETURN;
END IF;
```

## Testing Strategy

```python
@pytest.fixture
def db_connection():
    conn = get_database_connection()
    conn.begin()
    yield conn
    conn.rollback()
    conn.close()
```

- Real database for integration tests (not mocks)
- Transactions with rollback for isolation
- Test organization scoping and both success/failure cases

## Common Gotchas

### Always use CASCADE for FK constraints

```sql
-- GOOD
organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE

-- BAD: fails if related records exist
organization_id INTEGER NOT NULL REFERENCES organizations(id)
```

### Altering Function Return Types (PostgreSQL)

```sql
-- GOOD: Drop first, then recreate
DROP FUNCTION IF EXISTS get_item_rpc(integer);
CREATE OR REPLACE FUNCTION get_item_rpc(p_id INTEGER) RETURNS TABLE (...) AS $$ ... $$;

-- BAD: fails with "cannot change return type"
CREATE OR REPLACE FUNCTION get_item_rpc(p_id INTEGER) RETURNS TABLE (... new_column ...) AS $$ ... $$;
```

## Migration Rollback

Create a new migration — never destructively reset:

```sql
DROP FUNCTION IF EXISTS function_name(parameter_types);
DROP TABLE IF EXISTS table_name CASCADE;
DROP INDEX IF EXISTS idx_name;
ALTER TABLE table_name DROP COLUMN IF EXISTS column_name;
```
