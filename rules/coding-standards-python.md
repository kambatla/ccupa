---
description: Python/FastAPI coding standards — auth patterns, database access, testing with pytest, tooling.
globs:
  - "**/*.py"
---

# Python / FastAPI Standards

Project-specific patterns for the Python backend. General Python/FastAPI best practices are not repeated here.

## API Endpoints
- Auth via `Annotated[dict, Depends(get_current_user)]`; check permissions inline before business logic
- Re-raise `HTTPException` without wrapping; map domain exceptions to `HTTPException` at the API layer
- Pydantic models for request/response validation

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
- **mypy** in strict mode (`strict = true` in `pyproject.toml`)

All errors from these tools must be resolved before committing. Fix the root cause — never suppress or widen types (e.g., `int | str`) to silence errors.
