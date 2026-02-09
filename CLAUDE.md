# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

This is a **Claude Code plugin** (`ccupa`) — a collection of skills and slash commands that define development workflow conventions. It is not an application codebase. It gets installed as a plugin and provides standards for projects that use it.

The plugin is defined in `.claude-plugin/plugin.json`.

## Repository Structure

```
.claude-plugin/plugin.json     # Plugin manifest
skills/                        # Skill definitions (invoked automatically by context)
  coding-standards/            # SKILL.md routes to python.md or react-typescript.md
  db-conventions/              # SKILL.md routes to supabase.md
  deployment/                  # SKILL.md routes to local.md or digital-ocean.md
  git-conventions/             # SKILL.md (single file, no sub-routes)
commands/                      # Slash commands (user-invoked workflows)
```

**Skills** are reference material that Claude invokes contextually (coding patterns, DB conventions, git standards, deployment guides). Each skill has a `SKILL.md` router that points to language- or platform-specific files.

**Commands** are multi-step workflows the user triggers explicitly. They define processes, not reference material.

## Command Lifecycle

The commands form a feature development pipeline:

1. `/brainstorm` — Explore problem space, challenge assumptions, recommend direction
2. `/design` — Architect layer-by-layer (storage → backend → frontend), define test cases during design
3. `/implement` — Execute the plan (sequential or parallel with agent teams), follows define→test→implement order
4. `/bug` — Investigate, write regression test (must fail first), fix, prove fix works
5. `/prep-commit` — Parallel agents: run scoped tests, quality checks, code review; fix issues
6. `/commit` — Stage, draft message per git-conventions, commit with HEREDOC
7. `/prep-merge-pr` — Full test suites, quality checks, 3 specialized reviews (correctness, quality, security); fix issues
8. `/pr` — Push branch, create PR via `gh` with structured body
9. `/merge` — Rebase on main, run `/prep-merge-pr`, merge, delete branch
10. `/sync-main` — Pull latest main, delete merged local branches
11. `/push` — Push main to all configured remotes

## Key Conventions Defined by This Plugin

These are the standards this plugin enforces in consuming projects:

- **Git**: `<type>: <description>` commit format, HEREDOC for multi-line messages, no AI attribution, branch naming `<type>-<2-3-word-desc>`
- **Python/FastAPI**: Auth via `Depends(get_current_user)`, database via RPC wrappers (never raw SQL), Pydantic models, pytest with real DB + transaction rollback
- **React/TypeScript**: `React.FC<Props>`, Context+Hook state pattern, semantic Tailwind tokens (no hardcoded colors), shared UI components, Vitest + RTL with `userEvent`
- **Database**: Migration-first workflow (never `db reset`), RPC functions with `_rpc` suffix, `p_*` params, `result_*` returns, organization scoping for multi-tenancy
- **Testing**: 80%+ coverage target, define→test→implement order, mock external services only (real DB for integration tests), RTL query priority: ByRole > ByLabel > ByText > ByTestId

## Editing Guidelines

When modifying this plugin:
- Skills are reference docs — keep them scannable with tables, code blocks, and clear rules
- Commands are workflow definitions — they specify sequential steps, agent coordination, and skip conditions
- Each SKILL.md is a router — it should only describe when to use the skill and link to sub-files
- Commands reference each other (e.g., `/commit` calls `/prep-commit`, `/pr` calls `/prep-merge-pr`) — maintain these dependencies when renaming or restructuring
- Several commands specify agent delegation strategies (Haiku for simple git workflows, parallel teams for prep-commit/prep-merge-pr) — preserve these performance hints
