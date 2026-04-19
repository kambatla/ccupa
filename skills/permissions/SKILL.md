---
name: permissions
description: Tool permission management for unattended agent execution. Handles preflight checks before spawning agents and review of runtime-approved patterns via /learn. Use during project onboarding and before non-interactive commands.
---

# Permissions Skill

This skill manages tool permissions so agents can run without blocking on approval prompts.

## When to Use This Skill

Claude should invoke this skill when:
- About to spawn agents in non-interactive commands (`/implement`, `/bug`, `/prep-commit`, `/prep-pr`, `/review-pr`)
- Running `/learn` to reflect on a session (review runtime approvals)
- Onboarding a project via `/setup`

## Procedure Files

| File | Use When |
|------|----------|
| `preflight.md` | Before spawning agents — check and configure permissions |
| `review.md` | During `/learn` — scan conversation for runtime-approved patterns |
