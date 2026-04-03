# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

This is a **Claude Code plugin** (`ccupa`) — a collection of skills and slash commands that define development workflow conventions. It is not an application codebase. It gets installed as a plugin and provides standards for projects that use it.

The plugin is defined in `.claude-plugin/plugin.json`.

## Repository Structure

```
.claude-plugin/plugin.json     # Plugin manifest
skills/                        # All skills — reference docs and workflow commands
  coding-standards/            # SKILL.md routes to python.md or react-typescript.md
  db-conventions/              # SKILL.md routes to supabase.md
  deployment/                  # SKILL.md routes to local.md or digital-ocean.md
  git-conventions/             # SKILL.md (single file, no sub-routes)
  permissions/                 # SKILL.md routes to preflight.md and review.md
  codex-review/                # SKILL.md (single file, no sub-routes)
  review-tracking/             # SKILL.md (single file, no sub-routes)
  review-resolver/             # SKILL.md (single file, no sub-routes)
  brainstorm/                  # Workflow skill (disable-model-invocation: true)
  bug/                         # Workflow skill (disable-model-invocation: true)
  commit/                      # Workflow skill (disable-model-invocation: true)
  design/                      # Workflow skill (disable-model-invocation: true)
  implement/                   # Workflow skill (disable-model-invocation: true)
  learn/                       # Workflow skill (disable-model-invocation: true)
  merge/                       # Workflow skill (disable-model-invocation: true)
  pr/                          # Workflow skill (disable-model-invocation: true)
  prep-commit/                 # Workflow skill (disable-model-invocation: true)
  prep-merge-pr/               # Workflow skill (disable-model-invocation: true)
  push/                        # Workflow skill (disable-model-invocation: true)
  ralph/                       # Workflow skill: loop.md, cancel.md, help.md
  review-roi/                  # Workflow skill (disable-model-invocation: true)
  setup/                       # Workflow skill (disable-model-invocation: true)
  sync-main/                   # Workflow skill (disable-model-invocation: true)
scripts/                       # Shared shell scripts invoked by workflow skills
  setup-worktree.sh            # Create worktree, check gitignore, symlink config files
  teardown-worktree.sh         # Remove worktree and delete branch after merge
  push-all-remotes.sh          # Push main to all configured remotes
  setup-ralph-loop.sh          # Initialize Ralph loop state file
```

**Reference skills** (auto-invoked by context): coding-standards, db-conventions, deployment, git-conventions, permissions, codex-review, review-tracking, review-resolver. Each has a `SKILL.md` router that points to language- or platform-specific files.

**Workflow skills** (explicit invocation only, `disable-model-invocation: true`): all others. These define multi-step processes with agent coordination and skip conditions. Scripts in `scripts/` handle deterministic shell sequences; judgment and orchestration stay in the skill instructions.

## Workflow Lifecycle

The workflow skills form a feature development pipeline:

0. `/setup` — Onboard a consuming project: configure permissions, bootstrap settings
1. `/brainstorm` — Explore problem space, challenge assumptions, recommend direction
2. `/design` — Architect layer-by-layer (storage → backend → frontend), define test cases during design, Codex design review
3. `/implement` — Execute the plan (sequential or parallel with agent teams), follows define→test→implement order
4. `/bug` — Investigate, write regression test (must fail first), fix, prove fix works
5. `/prep-commit` — Parallel agents: run scoped tests, quality checks, code review + Codex review; fix issues
6. `/commit` — Stage, draft message per git-conventions, commit with HEREDOC
7. `/prep-merge-pr` — Full test suites, quality checks, 2 specialized reviews (unified correctness+quality, security) + Codex review; fix issues
8. `/pr` — Push branch, create PR via `gh` with structured body
9. `/merge` — Rebase on main, run `/prep-merge-pr`, merge, delete branch
10. `/sync-main` — Pull latest main, delete merged local branches
11. `/push` — Push main to all configured remotes
12. `/learn` — Session reflection: review permissions, corrections, and patterns; propose improvements

## Key Conventions Defined by This Plugin

These are the standards this plugin enforces in consuming projects:

- **Git**: `<type>: <description>` commit format, HEREDOC for multi-line messages, no AI attribution, branch naming `<type>-<2-3-word-desc>`
- **Python/FastAPI**: Auth via `Depends(get_current_user)`, database via RPC wrappers (never raw SQL), Pydantic models, pytest with real DB + transaction rollback
- **React/TypeScript**: `React.FC<Props>`, Context+Hook state pattern, semantic Tailwind tokens (no hardcoded colors), shared UI components, Vitest + RTL with `userEvent`
- **Database**: Migration-first workflow (never `db reset`), RPC functions with `_rpc` suffix, `p_*` params, `result_*` returns, organization scoping for multi-tenancy
- **Testing**: 80%+ coverage target, define→test→implement order, mock external services only (real DB for integration tests), RTL query priority: ByRole > ByLabel > ByText > ByTestId
- **Permissions**: Preflight checks before spawning agents, post-session review of runtime-approved patterns, `/setup` for initial configuration

## Agent Model Selection

When spawning agents, match the model to the task complexity:

| Model | Use for |
|-------|---------|
| **Opus** | `/brainstorm`, `/design`, `/learn`, plan mode, `/prep-commit` and `/prep-merge-pr` orchestrators, Claude code reviews (`reviewer` in both prep-commit and prep-merge-pr) |
| **Sonnet** | `/commit` (grouping changes by intent requires judgment), `/implement` (orchestrator + implementation teammates), `review-resolver` fixer agents, `review-security` in prep-merge-pr |
| **Haiku** | Test runners, quality/formatting checks, git workflows (`/pr`, `/push`, `/sync-main`, `/merge`, `/setup`, `/review-roi`), `codex-review` agent wrappers |
| **Codex (gpt-codex-5)** | Review model invoked inside `codex-review` agents — see codex-review skill for invocation flags and prompt templates |

**Principle:** Use the cheapest model that can do the job well. Opus for reasoning-heavy work (design, review). Sonnet for implementation that requires understanding but not deep reasoning. Haiku for mechanical tasks with clear instructions.

## Issue Tracking

Issues are tracked on GitHub: https://github.com/kambatla/ccupa/issues

## Editing Guidelines

When modifying this plugin:
- Reference skills are reference docs — keep them scannable with tables, code blocks, and clear rules
- Workflow skills define multi-step processes — they specify sequential steps, agent coordination, and skip conditions
- Each SKILL.md is an entrypoint — reference skill SKILL.mds should describe when to use the skill and link to sub-files; workflow skill SKILL.mds contain the full workflow
- Workflow skills reference each other (e.g., `/commit` calls `/prep-commit`, `/pr` calls `/prep-merge-pr`) — maintain these dependencies when renaming or restructuring
- Workflow skills specify model choices per the Agent Model Selection table above — preserve these when editing
- Scripts in `scripts/` handle deterministic shell sequences — keep them focused and single-purpose; invoke via `${CLAUDE_PLUGIN_ROOT}/scripts/<name>.sh`
