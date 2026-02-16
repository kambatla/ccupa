# Local Development Environment

Patterns for setting up and running a local development environment.

## Startup Sequence

Always start services in dependency order: **database → backend → frontend**

```bash
# 1. Start database (e.g., Docker container, Supabase local, etc.)
# 2. Start backend (e.g., uvicorn --reload, Django runserver, etc.)
# 3. Start frontend (e.g., npm run dev)
```

## Environment Variables

Use `.env` files for local configuration — never hardcode values:

```bash
# .env (backend)
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
SECRET_KEY=local-dev-key
ENVIRONMENT=development

# frontend/.env
VITE_API_URL=http://localhost:8000
```

**Rules:**
- `.env` files are in `.gitignore`
- Provide `.env.example` with placeholder values
- Document which variables are required

## Hot Reload

Both backend and frontend should support hot reload in development:
- **Backend:** Use framework reload flags (e.g., `uvicorn --reload`, `Django runserver`)
- **Frontend:** Vite HMR or equivalent is enabled by default

## Applying Migrations Locally

**Never use destructive resets** — apply migrations individually:

```bash
# Direct psql
psql "$DATABASE_URL" -f migrations/TIMESTAMP_description.sql

# Or via platform CLI (e.g., supabase db push, alembic upgrade head)
```

## Prerequisites

Typical local development stack:
- Docker Desktop (for local database containers)
- Node.js 18+ (frontend)
- Python 3.11+ (backend)
- Database CLI tools (psql, etc.)
- Package managers (npm, uv/pip)
