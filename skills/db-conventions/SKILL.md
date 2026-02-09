---
name: db-conventions
description: Database conventions and migration workflows. Covers migration-first development, schema design principles, multi-tenancy patterns, and function/procedure patterns. See supabase.md for Supabase-specific workflows.
---

# Database Conventions Skill

Generic database conventions for migration-first development.

## When to Use This Skill

Invoke this skill when:
- Creating or modifying database schema (tables, columns, indexes, constraints)
- Adding or updating database functions (stored procedures, RPCs)
- Debugging database operations
- User asks about database changes or "how do I query X"

## Platform-Specific Files

| File | Use When |
|------|----------|
| `supabase.md` | Using Supabase (CLI, RPC wrappers, migration workflow) |

## Critical Rules

### NEVER Do These Things

1. **NEVER make schema changes without creating a migration file first**
   - Always create migration file, THEN apply it
   - Migrations must be tracked in git for production deployment
   - Even "quick fixes" need migration files

2. **NEVER skip the migration workflow**
   - Even for "quick fixes" or "one-line changes"
   - No exceptions

3. **NEVER use raw SQL queries in application code**
   - SQL injection risk — parameterized queries in functions/ORMs handle escaping correctly by default
   - Retry and error handling — function invocation libraries (ORMs, RPC wrappers) provide built-in retry logic, connection pooling, and structured error types that raw SQL strings don't
   - Always use database functions + RPC calls or an ORM instead

4. **NEVER use destructive database resets in dev or prod**
   - Always apply migrations individually
   - Resets destroy data and break reproducibility

5. **NEVER change a function's return type in-place** (PostgreSQL)
   - PostgreSQL cannot alter a function's return type via `CREATE OR REPLACE`
   - You MUST `DROP FUNCTION IF EXISTS function_name(arg_types)` first
   - Then `CREATE OR REPLACE FUNCTION` with the new return type

### ALWAYS Do These Things

1. **ALWAYS use migrations for ALL database changes**
2. **ALWAYS use database functions or an ORM for data access**
3. **ALWAYS include organization/tenant scoping in multi-tenant queries**

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

## Schema Design Principles

### Normalize by Default
- Third normal form for transactional data
- Denormalize only when you have measured performance evidence

### Index Strategy
- Always index foreign keys
- Always index columns used in WHERE clauses for multi-tenant queries
- Composite indexes for common lookup patterns
- Don't over-index — each index slows writes

### Constraints
- Use `NOT NULL` unless you have a reason for nullable
- Use `REFERENCES` for foreign keys with appropriate `ON DELETE` behavior
- Use `UNIQUE` constraints for business rules
- Use `CHECK` constraints for value validation

### Multi-Tenancy Patterns

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
