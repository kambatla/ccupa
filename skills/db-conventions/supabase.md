# Supabase Database Patterns

Supabase-specific workflows, RPC conventions, and migration patterns.

## Supabase CLI Workflow

### Create Migration

```bash
supabase migration new "descriptive_name_of_change"
```

This creates a timestamped file in `supabase/migrations/`.

### Apply Migration

**Always use `psql` — never `supabase db reset`** (it destroys all data):

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" \
  -f supabase/migrations/TIMESTAMP_descriptive_name.sql
```

### Supabase Management

```bash
supabase start     # Start local Docker containers
supabase stop      # Stop local containers
supabase status    # Show service URLs and keys
```

## RPC Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Function name | `*_rpc` suffix | `get_item_by_id_rpc` |
| Parameters | `p_*` prefix | `p_item_id`, `p_organization_id` |
| Return fields | `result_*` prefix | `result_id`, `result_name` |

## RPC Function Patterns

### SELECT — Single Record

```sql
CREATE OR REPLACE FUNCTION get_item_by_id_rpc(
    p_item_id INTEGER,
    p_organization_id INTEGER
)
RETURNS TABLE (
    result_id INTEGER,
    result_name VARCHAR,
    result_status VARCHAR,
    result_organization_id INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT id, name, status, organization_id
    FROM items
    WHERE id = p_item_id
      AND organization_id = p_organization_id;
END;
$$ LANGUAGE plpgsql;
```

### SELECT — Multiple Records

```sql
CREATE OR REPLACE FUNCTION get_items_by_organization_rpc(
    p_organization_id INTEGER,
    p_active_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    result_id INTEGER,
    result_name VARCHAR,
    result_status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT id, name, status
    FROM items
    WHERE organization_id = p_organization_id
      AND (NOT p_active_only OR status = 'active')
    ORDER BY name;
END;
$$ LANGUAGE plpgsql;
```

### INSERT — Return ID

```sql
CREATE OR REPLACE FUNCTION create_item_rpc(
    p_organization_id INTEGER,
    p_name VARCHAR,
    p_status VARCHAR DEFAULT 'active'
)
RETURNS TABLE (result_id INTEGER) AS $$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO items (organization_id, name, status)
    VALUES (p_organization_id, p_name, p_status)
    RETURNING id INTO new_id;

    RETURN QUERY SELECT new_id;
END;
$$ LANGUAGE plpgsql;
```

### INSERT — Bulk with UNNEST

```sql
CREATE OR REPLACE FUNCTION create_items_bulk_rpc(
    p_organization_id INTEGER,
    p_names VARCHAR[],
    p_statuses VARCHAR[]
)
RETURNS INTEGER AS $$
DECLARE
    inserted_count INTEGER;
BEGIN
    INSERT INTO items (organization_id, name, status)
    SELECT p_organization_id, UNNEST(p_names), UNNEST(p_statuses);

    GET DIAGNOSTICS inserted_count = ROW_COUNT;
    RETURN inserted_count;
END;
$$ LANGUAGE plpgsql;
```

### UPDATE — Return Success

```sql
CREATE OR REPLACE FUNCTION update_item_rpc(
    p_item_id INTEGER,
    p_organization_id INTEGER,
    p_name VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE items
    SET name = p_name, updated_at = NOW()
    WHERE id = p_item_id
      AND organization_id = p_organization_id;

    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count > 0;
END;
$$ LANGUAGE plpgsql;
```

### DELETE — Return Count

```sql
CREATE OR REPLACE FUNCTION delete_items_by_date_range_rpc(
    p_organization_id INTEGER,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM items
    WHERE organization_id = p_organization_id
      AND created_at::date BETWEEN p_start_date AND p_end_date;

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;
```

### Transaction with Validation

```sql
CREATE OR REPLACE FUNCTION reassign_item_rpc(
    p_item_id INTEGER,
    p_old_owner_id INTEGER,
    p_new_owner_id INTEGER,
    p_organization_id INTEGER
)
RETURNS TABLE (result_success BOOLEAN, result_message VARCHAR) AS $$
DECLARE
    item_exists BOOLEAN;
    new_owner_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM items
        WHERE id = p_item_id
          AND owner_id = p_old_owner_id
          AND organization_id = p_organization_id
    ) INTO item_exists;

    IF NOT item_exists THEN
        RETURN QUERY SELECT FALSE, 'Item not found or does not belong to specified owner'::VARCHAR;
        RETURN;
    END IF;

    SELECT EXISTS(
        SELECT 1 FROM users
        WHERE id = p_new_owner_id
          AND organization_id = p_organization_id
          AND is_active = TRUE
    ) INTO new_owner_exists;

    IF NOT new_owner_exists THEN
        RETURN QUERY SELECT FALSE, 'New owner not found or inactive'::VARCHAR;
        RETURN;
    END IF;

    UPDATE items
    SET owner_id = p_new_owner_id, updated_at = NOW()
    WHERE id = p_item_id;

    RETURN QUERY SELECT TRUE, 'Item reassigned successfully'::VARCHAR;
END;
$$ LANGUAGE plpgsql;
```

## Performance Considerations

- Avoid N+1 queries — use JOINs or batch queries instead of looping with individual calls
- Use bulk operations (e.g., `UNNEST`) for batch inserts instead of individual inserts in a loop

## Changing a Function's Return Type

```sql
-- Drop old signature (must include argument types)
DROP FUNCTION IF EXISTS get_item_rpc(integer, integer);

-- Recreate with new return columns
CREATE OR REPLACE FUNCTION get_item_rpc(p_item_id INTEGER, p_organization_id INTEGER)
RETURNS TABLE (
    result_id INTEGER,
    result_name VARCHAR,
    result_new_field TEXT  -- newly added
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT id, name, new_field
    FROM items
    WHERE id = p_item_id AND organization_id = p_organization_id;
END;
$$;
```

**Key points:**
- `DROP FUNCTION IF EXISTS` makes the migration re-runnable
- Always specify argument types in the DROP to match the overload
- `CREATE OR REPLACE` alone works fine when only the function *body* changes (same return type)

## Common Gotchas

### 1. Always Prefix Return Fields
```sql
-- GOOD: Works with SupabaseRPC wrapper
RETURNS TABLE (result_id INTEGER, result_name VARCHAR)

-- BAD: Won't auto-map field names
RETURNS TABLE (id INTEGER, name VARCHAR)
```

### 2. Always Include Organization Scoping
```sql
-- GOOD: Multi-tenant safe
WHERE id = p_item_id AND organization_id = p_organization_id

-- BAD: Could access other tenant's data
WHERE id = p_item_id
```

### 3. Use RETURN QUERY for TABLE Returns
```sql
-- GOOD
RETURN QUERY SELECT id, name FROM items;

-- BAD
RETURN (SELECT id, name FROM items);
```

## Quick Reference

| Task | Command |
|------|---------|
| Create migration | `supabase migration new "description"` |
| Apply migration | `psql "connection-string" -f supabase/migrations/TIMESTAMP_file.sql` |
| List migrations | `ls -la supabase/migrations/` |
| Check status | `supabase status` |
