# Local Development Environment

## Startup Sequence

Start in dependency order: **database → backend → frontend**

## Environment Variables

```bash
# .env (backend)
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
SECRET_KEY=local-dev-key
ENVIRONMENT=development

# frontend/.env
VITE_API_URL=http://localhost:8000
```

- `.env` files are in `.gitignore`; commit `.env.example` with placeholder values

## Applying Migrations Locally

Never use destructive resets — apply migrations individually:

```bash
psql "$DATABASE_URL" -f migrations/TIMESTAMP_description.sql
# or: supabase db push / alembic upgrade head
```

## Prerequisites

Docker Desktop, Node.js 18+, Python 3.11+, psql, npm/uv
