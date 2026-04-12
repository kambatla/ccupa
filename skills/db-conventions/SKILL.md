---
name: db-conventions
description: Database conventions reference — migration-first workflow with examples, multi-tenancy patterns, function templates, testing strategy. Use when writing migrations, database functions, or working with schema changes.
---

# Database Conventions Skill

Detailed reference for database development patterns. The `db-conventions` rule provides critical rules and quick reminders; this skill provides the full walkthrough with examples.

## When to Use This Skill

Claude should invoke this skill when:
- Writing a new migration file
- Creating or modifying database functions
- Setting up database tests with transaction rollback
- User asks "how should I structure this migration?" or similar
- Working with multi-tenancy patterns

## Migration-First Workflow

### Step 1: Create Migration File

Use your platform's migration tool to create a timestamped file:
```bash
# Example: Supabase
supabase migration new "descriptive_name_of_change"

# Example: Alembic
alembic revision -m "descriptive_name_of_change"

# Example: Django
python manage.py makemigrations
```

**Naming conventions:**
- `add_table_name` - New table creation
- `add_column_to_table` - Adding columns
- `create_function_name` - New database function
- `update_function_name` - Modifying existing function
- `add_index_on_table_column` - New indexes

### Step 2: Write the Migration

**Schema changes:**
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

### Step 3: Apply Migration

Apply individually — never batch-reset:
```bash
# Direct psql
psql "connection-string" -f migrations/TIMESTAMP_file.sql

# Or via platform CLI
supabase db push
alembic upgrade head
python manage.py migrate
```

### Step 4: Test

Run tests for affected code to verify the migration works correctly.

### Step 5: Commit

Include migration filename in the commit for traceability:
```
feature: Add items table

Migration file: migrations/20250115_add_items.sql
```

## Multi-Tenancy Patterns

**Organization scoping:** Every tenant-specific table includes `organization_id`:
```sql
-- GOOD: Multi-tenant safe
WHERE id = p_item_id AND organization_id = p_organization_id

-- BAD: Could access other tenant's data
WHERE id = p_item_id
```

**Row-Level Security (RLS):** Consider RLS policies for defense-in-depth, especially when the database is accessed from multiple services.

## Function / Procedure Patterns

### Input Validation
- Validate parameters before executing queries
- Return meaningful error messages

### Return Types
- Use scalar returns (INTEGER, BOOLEAN) for simple operations
- Use TABLE returns for record queries
- Use consistent naming for returned fields

### Error Handling
```sql
-- Validate before operating
IF NOT EXISTS(SELECT 1 FROM items WHERE id = p_item_id) THEN
    RETURN QUERY SELECT FALSE, 'Item not found'::VARCHAR;
    RETURN;
END IF;
```

## Testing Strategy

### Real Database with Transaction Rollback

```python
@pytest.fixture
def db_connection():
    conn = get_database_connection()
    conn.begin()
    yield conn
    conn.rollback()
    conn.close()
```

**Rules:**
- Use real database for integration tests (not mocks)
- Always use transactions with rollback for isolation
- Test organization scoping (multi-tenancy)
- Test both success and failure cases

## Common Gotchas

### 1. Always Use CASCADE for FK Constraints
```sql
-- GOOD: Automatically delete related records
organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE

-- BAD: Will fail if related records exist
organization_id INTEGER NOT NULL REFERENCES organizations(id)
```

### 2. Altering Function Return Types (PostgreSQL)
```sql
-- GOOD: Drop first, then recreate
DROP FUNCTION IF EXISTS get_item_rpc(integer);
CREATE OR REPLACE FUNCTION get_item_rpc(p_id INTEGER)
RETURNS TABLE (...) AS $$ ... $$;

-- BAD: Will fail with "cannot change return type"
CREATE OR REPLACE FUNCTION get_item_rpc(p_id INTEGER)
RETURNS TABLE (... new_column ...) AS $$ ... $$;
```

### 3. Use RETURN QUERY for TABLE Returns
```sql
-- GOOD
RETURN QUERY SELECT id, name FROM items;

-- BAD: Won't work with TABLE return type
RETURN (SELECT id, name FROM items);
```

## Migration Rollback Pattern

If you need to undo a migration, create a new migration:

```sql
-- In a new migration file
DROP FUNCTION IF EXISTS function_name(parameter_types);
DROP TABLE IF EXISTS table_name CASCADE;
DROP INDEX IF EXISTS idx_name;
ALTER TABLE table_name DROP COLUMN IF EXISTS column_name;
```
