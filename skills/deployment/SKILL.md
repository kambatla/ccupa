---
name: deployment
description: Deployment philosophy and patterns. Covers environment parity, deployment checklists, rollback strategy, health checks, and monitoring. See local.md and digital-ocean.md for platform-specific guides.
---

# Deployment

## Platform-Specific Files

| File | Use When |
|------|----------|
| `local.md` | Setting up or running local development |
| `digital-ocean.md` | Deploying to a Digital Ocean droplet |

## Core Principles

**Environment parity:** Same DB engine, same service architecture, env vars for config — never hardcoded values.

**Deployment sequence:** Pull → Install → Build → Smoke test → Restart → Health check.

**Rollback:** Keep previous release accessible. Test rollback process periodically.

**Health checks:** Verify real dependencies (DB connection). Fail loudly on health check failure.

**Monitoring:** Structured logging, process manager status, log rotation, access logs.

**Credentials:** Never in source code, config files, scripts, or docs. Use env vars or secrets managers.
