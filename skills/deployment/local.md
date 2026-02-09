# Local Development Environment

Patterns for setting up and running a local development environment.

## Startup Sequence

Always start services in dependency order: **database -> backend -> frontend**

```bash
# 1. Start database (example: Supabase local via Docker)
supabase start

# 2. Start backend (example: FastAPI with uvicorn)
source .venv/bin/activate
python3 -m uvicorn src.api:app --reload --host localhost --port 8000

# 3. Start frontend (example: Vite dev server)
cd frontend && npm run dev
```

## Local URLs Convention

| Service | URL |
|---------|-----|
| Frontend | http://localhost:5173 |
| Backend API | http://localhost:8000 |
| API Docs | http://localhost:8000/docs |
| Database Studio | http://127.0.0.1:54323 |

## Environment Variables

Use `.env` files for local configuration — never hardcode values:

```bash
# .env (backend)
DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=<from local setup>
SUPABASE_SERVICE_KEY=<from local setup>

# frontend/.env
VITE_API_URL=http://localhost:8000
VITE_SUPABASE_URL=http://127.0.0.1:54321
VITE_SUPABASE_ANON_KEY=<local key>
```

**Rules:**
- `.env` files are in `.gitignore`
- Provide `.env.example` with placeholder values
- Document which variables are required

## Hot Reload

Both backend and frontend should support hot reload in development:
- **Backend:** `uvicorn --reload` watches for Python file changes
- **Frontend:** Vite HMR (Hot Module Replacement) is enabled by default

## Applying Migrations Locally

**Never use destructive resets** — apply migrations individually:

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" \
  -f migrations/TIMESTAMP_description.sql
```

## Prerequisites

Typical local development stack:
- Docker Desktop (for local database containers)
- Node.js 18+ (frontend)
- Python 3.11+ (backend)
- Database CLI tools (psql, supabase CLI, etc.)
- Package managers (npm, uv/pip)
