---
description: Python/FastAPI coding standards — auth patterns, database access, testing with pytest, tooling.
globs:
  - "**/*.py"
---

# Python / FastAPI Standards

Project-specific patterns for the Python backend. General Python/FastAPI best practices are not repeated here.

## API Endpoints
- Auth via `Annotated[dict, Depends(get_current_user)]`; check permissions inline before business logic
- Database access via RPC wrappers — never raw SQL in endpoint code
- Re-raise `HTTPException` without wrapping; map domain exceptions to `HTTPException` at the API layer
- Pydantic models for request/response validation

## Database Access

Always use RPC wrappers — never raw SQL in endpoint code. See the db-conventions and db-conventions-supabase rules for implementation details.

## Testing (pytest)

- Use real database with transaction rollback when testing DB boundaries; mock the DB layer elsewhere
- Mock external services (email, auth providers, third-party APIs)
- Test naming: `test_<what>_<condition>_<expected>`
- Group related tests in classes
- Type hints always on function signatures
- See coding-standards rule for handling test failures

## Tooling

- **black** for formatting
- **ruff** for linting
- **mypy** in strict mode for type checking — projects should enable `strict = true` in `mypy.ini` or `pyproject.toml`
