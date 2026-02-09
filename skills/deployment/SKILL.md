---
name: deployment
description: Deployment philosophy and patterns. Covers environment parity, deployment checklists, rollback strategy, health checks, and monitoring. See local.md and digital-ocean.md for platform-specific guides.
---

# Deployment Skill

Generic deployment philosophy and patterns for web applications.

## When to Use This Skill

Invoke this skill when:
- Setting up local development environment
- Deploying to production
- Troubleshooting deployment issues
- Planning infrastructure changes

## Platform-Specific Files

| File | Use When |
|------|----------|
| `local.md` | Setting up or running local development environment |
| `digital-ocean.md` | Deploying to a Digital Ocean droplet |

## Core Principles

### Environment Parity
Local development should mirror production structure as closely as possible:
- Same database engine (not SQLite locally + PostgreSQL in prod)
- Same service architecture (database + backend + frontend)
- Environment variables for configuration (never hardcoded)

### Deployment Checklist Pattern
Every deployment follows the same sequence:

1. **Pull** latest code
2. **Install** dependencies
3. **Build** artifacts (frontend, etc.)
4. **Test** import/smoke test before restart
5. **Restart** services
6. **Health check** to verify deployment succeeded

### Rollback Strategy
- Always keep the previous release accessible
- Maintain a quick rollback script
- Test rollback process periodically
- Document rollback steps

### Health Checks
- Always verify services after deploy
- Health endpoint should check real dependencies (DB connection, etc.)
- Automated health checks in deployment scripts
- Alert on health check failure

### Monitoring Basics
- Structured logging (not print statements)
- Service status checks via process manager
- Log rotation to prevent disk exhaustion
- Access logs for debugging and auditing

## No Credentials

**Never store credentials in:**
- Source code
- Configuration files committed to git
- Deployment scripts
- Documentation

Use environment variables or secrets managers for all sensitive values.
