# Python / FastAPI Standards

Code patterns, conventions, and testing standards for the Python backend.

## API Endpoints

```python
@app.get("/resource/{id}", response_model=ResponseModel)
def get_resource(
    id: int,
    current_user: dict = Depends(get_current_user),
):
    user_roles = current_user.get("roles_by_organization", {})
    org_roles = user_roles.get(str(organization_id), {})
    if not org_roles.get("is_admin", False):
        _raise_forbidden("Only admins can access this")

    try:
        result = rpc.call_single("get_resource_rpc", {"p_id": id})
        if not result:
            _raise_not_found("Resource not found")
        return ResponseModel(**result)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed: {e!s}") from e
```

**Rules:**
- Auth via `Depends(get_current_user)`, role checks inline
- Database via RPC wrappers — never raw SQL
- Re-raise `HTTPException` without wrapping
- Pydantic models for request/response validation

## Database Access

Always use RPC — see `db-conventions` skill for details.

```python
from src.database_rpc import rpc
result = rpc.call_single("function_rpc", {"p_param": value})
results = rpc.call_list("function_rpc", {"p_param": value})
```

## Error Handling

```python
# Domain exceptions in business logic
class DatabaseError(Exception): ...
class ItemNotFoundError(DatabaseError): ...

# API layer catches and maps to HTTP status codes
except SpecificDomainError as e:
    raise HTTPException(status_code=409, detail=str(e)) from e
except Exception as e:
    raise HTTPException(status_code=500, detail=f"Failed: {e!s}") from e
```

## Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Files | `snake_case.py` | `order_processor.py` |
| Functions/variables | `snake_case` | `get_item_by_id` |
| Classes | `PascalCase` | `OrderProcessor` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_RETRIES` |
| Type hints | Always on function signatures | `def foo(x: int) -> str:` |

---

## Testing Standards (pytest)

### Core Philosophy

**DO test:**
- Business logic and algorithms
- API endpoints (request/response, status codes, error handling)
- Database operations (CRUD, RPC functions, data integrity)
- Edge cases and error conditions
- Integration points (API calls, authentication, data flow)

**DON'T test:**
- Third-party library internals (React, FastAPI)
- Framework behavior (unless using incorrectly)
- Implementation details (private methods, internal state)
- Trivial getters/setters without logic
- Constants or configuration files

**Target: 80%+ coverage for new code.** Coverage does not equal quality — focus on testing behavior and edge cases.

### Test Organization

```
tests/
├── test_api.py              # API endpoint tests
├── test_orders.py           # Business logic tests
├── test_crud.py             # Database CRUD tests
└── conftest.py              # Shared fixtures
```

**Rules:**
- Group related tests in classes
- One test file per module or logical domain
- Descriptive test names: `test_<what>_<condition>_<expected>`

### Test Structure: Arrange-Act-Assert

```python
def test_create_item_with_valid_data_returns_id(self):
    # Arrange: Set up test data and mocks
    item_data = {
        "name": "Widget",
        "price": 9.99,
        "organization_id": 1
    }

    # Act: Execute the code under test
    result = create_item(db, **item_data)

    # Assert: Verify expected outcome
    assert isinstance(result, int)
    assert result > 0
```

### FastAPI Testing Patterns

**Basic endpoint test:**
```python
from fastapi.testclient import TestClient
from src.api import app

client = TestClient(app)

def test_health_endpoint_returns_200():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
```

**Authentication override:**
```python
from src.auth import get_current_user

def test_endpoint_requires_admin():
    def mock_get_current_user():
        return {
            "user_id": "user-123",
            "organization_id": 1,
            "is_admin": True
        }

    app.dependency_overrides[get_current_user] = mock_get_current_user

    try:
        response = client.get("/admin/endpoint")
        assert response.status_code == 200
    finally:
        app.dependency_overrides.clear()
```

### Database Testing

**Use real database with transaction rollback:**
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
- Always use transactions with rollback (isolation)
- Test organization scoping (multi-tenancy)
- Test both success and failure cases

### Mocking Patterns

**When to mock:**
- External services (email, auth providers)
- Third-party APIs
- Time-dependent code (use freezegun)
- Expensive operations during unit tests

**When NOT to mock:**
- Database (use real DB with transactions)
- Internal business logic
- Simple data transformations

```python
from unittest.mock import Mock, patch

@patch('src.email_service.send_email')
def test_invitation_sends_email(mock_send_email):
    mock_send_email.return_value = True
    send_invitation("user@example.com", "token-123")
    mock_send_email.assert_called_once()
```

```python
from freezegun import freeze_time

@freeze_time("2025-01-15 10:00:00")
def test_report_uses_current_date():
    result = generate_report()
    assert result.start_date == datetime(2025, 1, 15)
```

### Parametrized Tests

```python
import pytest

@pytest.mark.parametrize("item_count,expected_status", [
    (10, "optimal"),
    (5, "feasible"),
    (0, "empty"),
])
def test_processing_status(item_count, expected_status):
    items = create_items(count=item_count)
    result = process_items(items)
    assert result.status == expected_status
```

### Edge Cases and Error Testing

```python
def test_create_item_with_invalid_email_raises_error():
    with pytest.raises(ValidationError) as exc_info:
        create_item(name="Widget", email="invalid-email", organization_id=1)
    assert "email" in str(exc_info.value).lower()

def test_process_with_zero_items():
    result = process_items(items={})
    assert result.status == "empty"
```

### Common Pitfalls

**Don't test implementation details:**
```python
# BAD: Testing private method
def test_private_method():
    obj = MyClass()
    assert obj._internal_helper() == 5

# GOOD: Test public behavior
def test_calculation_result():
    obj = MyClass()
    assert obj.calculate() == expected_result
```

**Don't create brittle tests:**
```python
# BAD: Exact string matching
assert "Error occurred" in str(exception)

# GOOD: Key information check
assert "item" in str(exception).lower()
assert "not found" in str(exception).lower()
```

## Running Tests

```bash
python3 -m pytest                                    # All tests
python3 -m pytest tests/test_api.py -v               # Specific file
python3 -m pytest tests/test_api.py::TestHealth -v    # Specific class
python3 -m pytest --cov=src tests/                    # With coverage
```

## Quick Reference

| Aspect | Standard |
|--------|----------|
| Coverage target | 80%+ |
| Test structure | Arrange-Act-Assert |
| Mock strategy | External services only |
| Database | Real DB + transactions |
| Naming | `test_<what>_<condition>_<expected>` |
| Organization | Class-based grouping |
