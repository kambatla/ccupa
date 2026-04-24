# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

This is a **Claude Code plugin** (`ccupa`) — a collection of rules, skills, and slash commands that define development workflow conventions. It is not an application codebase. It gets installed as a plugin and provides standards for projects that use it.

The plugin is defined in `.claude-plugin/plugin.json`.

## Repository Structure

```
.claude-plugin/plugin.json     # Plugin manifest
rules/                         # Convention rules — synced to consuming projects via /sync-rules
  git-operations.md            # Always active — points to git-conventions skill
  coding-standards.md          # Always active — general principles (fix all failures, tests as contracts)
  coding-standards-python.md   # Glob: **/*.py
  coding-standards-react-ts.md # Glob: **/*.{ts,tsx,js,jsx}
  db-conventions.md            # Glob: **/*.sql, **/supabase/** — critical rules, migration naming, schema design
  db-conventions-supabase.md   # Glob: **/supabase/**, **/*.sql
  db-app-layer.md              # Glob: **/*.py — no raw SQL in application code
skills/                        # Skills — reference docs and workflow commands
  db-conventions/              # SKILL.md (single file, no sub-routes)
  deployment/                  # SKILL.md routes to local.md or digital-ocean.md
  git-conventions/             # SKILL.md (single file, no sub-routes)
  permissions/                 # SKILL.md routes to preflight.md and review.md
  codex-review/                # SKILL.md (single file, no sub-routes)
    run-codex-review.sh        # Invoke codex review with branch+timestamp output path
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
  prep-pr/                     # Workflow skill (disable-model-invocation: true)
  review-branch/               # Workflow skill (disable-model-invocation: true)
  review-pr/                   # Workflow skill (disable-model-invocation: true)
  ralph/                       # Workflow skill: loop.md, cancel.md, help.md
    setup-ralph-loop.sh        # Initialize Ralph loop state file
  setup/                       # Workflow skill (disable-model-invocation: true)
  sync-rules/                  # Workflow skill (disable-model-invocation: true)
  create-worktree/             # Workflow skill (disable-model-invocation: true)
    setup-worktree.sh          # Create worktree, check gitignore, symlink config files
  delete-worktree/             # Workflow skill (disable-model-invocation: true)
    teardown-worktree.sh       # Remove worktree, preserving branch (commits WIP if dirty)
```

**Rules** (synced to consuming projects): Convention rules in `rules/` define coding standards, database conventions, and git operation guidance. Rules can't be served directly from a plugin — `/sync-rules` copies them to the consuming project's `.claude/rules/` directory. Path-scoped rules load only when working with matching files.

**Reference skills** (auto-invoked by context): db-conventions, deployment, git-conventions, permissions, codex-review, review-tracking, review-resolver. Each has a `SKILL.md` router that points to language- or platform-specific files.

**Workflow skills** (explicit invocation only, `disable-model-invocation: true`): all others. These define multi-step processes with agent coordination and skip conditions. Shell scripts co-located in each skill's directory handle deterministic sequences; judgment and orchestration stay in the skill instructions.

## Workflow Lifecycle

The workflow skills form a feature development pipeline:

0. `/setup` — Onboard a consuming project: configure permissions, bootstrap settings, sync rules
1. `/brainstorm` — Explore problem space, challenge assumptions, recommend direction
2. `/design` — Architect layer-by-layer (storage → backend → frontend), define test cases during design, Codex design review
3. `/implement` — Execute the plan (sequential or parallel with agent teams), follows define→test→implement order
4. `/bug` — Investigate, write regression test (must fail first), fix, prove fix works
5. `/prep-commit` — Parallel agents: run scoped tests, quality checks, code review + Codex review; fix issues
6. `/commit` — Stage, draft message per git-conventions, commit with HEREDOC (requires `/prep-commit`)
7. `/prep-pr` — Full test suites, quality checks; fix issues (gates `/pr`)
8. `/pr` — Push branch, create PR via `gh` with structured body (requires `/prep-pr`)
9. `/review-pr` — Delegates to `/review-branch`, then posts results as PR comment (gates `/merge`)
10. `/merge` — Rebase on main, merge, push to all remotes, clean up merged branches (requires `/review-pr` or `/review-branch`)
11. `/learn` — Session reflection: review permissions, corrections, and patterns; propose improvements

**Alternate path (no PR):** `/review-branch` — same review+fix workflow as `/review-pr` but no PR required; reports to conversation only. Supersedes `/prep-pr` and `/review-pr` when used. Satisfies the `/merge` prerequisite.

**Worktree utilities** (optional, used when parallel isolation is needed):
- `/create-worktree` — Attach a worktree to an existing branch
- `/delete-worktree` — Remove the worktree, preserve the branch (run before `/merge`)

## Key Conventions Defined by This Plugin

These are the standards this plugin enforces in consuming projects. Coding standards and database conventions are delivered as **rules** (synced via `/sync-rules`). Git conventions and permissions are delivered as **skills**.

- **Git** (skill): `<type>: <description>` commit format, HEREDOC for multi-line messages, no AI attribution, branch naming `<type>-<2-3-word-desc>`
- **Python/FastAPI** (rule, `**/*.py`): Auth via `Depends(get_current_user)`, Pydantic models, pytest with real DB + transaction rollback
- **React/TypeScript** (rule, `**/*.{ts,tsx,js,jsx}`): `React.FC<Props>`, Context+Hook state pattern, semantic Tailwind tokens (no hardcoded colors), shared UI components, Vitest + RTL with `userEvent`
- **Database** (rule + skill): Critical rules and schema design in rules (`db-conventions`, `db-conventions-supabase`, `db-app-layer`); detailed workflow examples in `db-conventions` skill. Migration-first, organization scoping, RPC functions with `_rpc` suffix / `p_*` params / `result_*` returns
- **Testing** (rule): 80%+ coverage target, define→test→implement order, mock external services only (real DB for integration tests), RTL query priority: ByRole > ByLabel > ByText > ByTestId
- **Permissions** (skill): Preflight checks before spawning agents, post-session review of runtime-approved patterns, `/setup` for initial configuration

## Execution Model

Workflow skills follow two patterns based on whether they spawn sub-agents:

**Leaf workflows** (no sub-agents) run as a **Haiku sub-agent** to save cost and avoid context pollution in the main session:
`/commit`, `/pr`, `/merge`, `/setup`, `/sync-rules`, `/create-worktree`, `/delete-worktree`

**Orchestrator workflows** (spawn sub-agents) run **in the current session** to avoid agent nesting:
`/prep-commit`, `/prep-pr`, `/review-pr`, `/review-branch`, `/implement`, `/bug`, `/brainstorm`, `/design`, `/learn`

**Prerequisite pattern:** `/commit` requires `/prep-commit`; `/pr` requires `/prep-pr`; `/merge` requires `/review-pr` or `/review-branch`. These skills check that their prerequisite was already run in the conversation and refuse to proceed if not — they never auto-trigger the prerequisite themselves, which would cause agent nesting.

## Sub-Agent Model Selection

When orchestrator workflows spawn sub-agents, match the model to the task:

| Model | Use for |
|-------|---------|
| **Opus** | Claude code reviews (`reviewer` in prep-commit and review-pr) |
| **Sonnet** | Implementation teammates (`db`, `backend`, `frontend`), `review-resolver` fixer agents, `review-security` in review-pr |
| **Haiku** | Test runners, quality/formatting checks, `codex-review` agent wrappers |
| **Codex (gpt-codex-5)** | Review model invoked inside `codex-review` agents — see codex-review skill for invocation flags and prompt templates |

**Principle:** Use the cheapest model that can do the job well. Opus for reasoning-heavy review. Sonnet for implementation that requires understanding. Haiku for mechanical tasks with clear instructions.

## Issue Tracking

Issues are tracked on GitHub: https://github.com/kambatla/ccupa/issues

## Editing Guidelines

When modifying this plugin:
- **Rules** define conventions (coding standards, DB patterns) — keep them scannable with tables, code blocks, and clear rules. Use `globs` in frontmatter for path scoping. Only document what the model would get wrong without instruction — each line should pass the test: "Would Claude do something different or wrong without this line?"
- **Reference skills** are reference docs — keep them scannable with tables, code blocks, and clear rules
- **Workflow skills** define multi-step processes — they specify sequential steps, agent coordination, and skip conditions
- Each SKILL.md is an entrypoint — reference skill SKILL.mds should describe when to use the skill and link to sub-files; workflow skill SKILL.mds contain the full workflow
- Workflow skills have prerequisite chains (e.g., `/commit` requires `/prep-commit`, `/pr` requires `/prep-pr`, `/merge` requires `/review-pr` or `/review-branch`) — maintain these dependencies when renaming or restructuring
- Leaf workflows specify `## Execution: Run as a Haiku sub-agent` — preserve this when adding new leaf workflows. Orchestrator workflows run in the current session with sub-agent model choices per the Sub-Agent Model Selection table.
- Shell scripts live in the owning skill's directory — keep them focused and single-purpose; invoke via `${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/<script>.sh`
