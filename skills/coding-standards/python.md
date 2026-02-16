# Python / FastAPI Standards

Project-specific patterns for the Python backend. General Python/FastAPI best practices are not repeated here.

## API Endpoints
- Auth via `Annotated[dict, Depends(get_current_user)]`; check permissions inline before business logic
- Database access via RPC wrappers — never raw SQL in endpoint code
- Re-raise `HTTPException` without wrapping; map domain exceptions to `HTTPException` at the API layer
- Pydantic models for request/response validation

## Database Access

Always use RPC wrappers — never raw SQL in endpoint code. See `db-conventions` skill for implementation details.

## Testing (pytest)

- Use real database with transaction rollback when testing DB boundaries; mock the DB layer elsewhere
- Mock external services (email, auth providers, third-party APIs)
- Test naming: `test_<what>_<condition>_<expected>`
- Group related tests in classes
- Type hints always on function signatures
- Tests verify intended behavior, not implementation details. If a code change breaks a test, check whether the expected behavior has changed — if not, fix the implementation, don't update the test to match

## Tooling

- **black** for formatting
- **ruff** for linting
- **mypy** for type checking
