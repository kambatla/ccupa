---
name: sync-rules
description: Copy ccupa convention rules to the consuming project's .claude/rules/ directory.
disable-model-invocation: true
---

# /sync-rules

Copies the latest ccupa convention rules from this plugin into the consuming project so they are loaded as Claude Code rules.

## Execution
Run as a Haiku sub-agent — this is a leaf workflow with no further sub-agents.

## Steps

1. **Verify context** — if the current working directory is the ccupa plugin repo itself (i.e., `${CLAUDE_PLUGIN_ROOT}` equals the working directory), stop:
   > `/sync-rules` must be run from a consuming project, not from inside the ccupa plugin repo.

2. **Identify the project root** — the current working directory.

3. **Ensure `.claude/rules/` exists** in the project root. Create it if missing.

4. **Copy all rule files** from `${CLAUDE_PLUGIN_ROOT}/rules/` to the project's `.claude/rules/`, prefixing each filename with `ccupa-`:

   - Glob `${CLAUDE_PLUGIN_ROOT}/rules/*.md` to discover all rule files
   - For each file, copy to `.claude/rules/ccupa-<original-filename>`
   - Example: `rules/coding-standards-python.md` → `.claude/rules/ccupa-coding-standards-python.md`

5. **Report results** — list each file copied and whether it was created or updated (file already existed).

6. **Check for overlapping project rules** — scan non-`ccupa-` rule files in `.claude/rules/` for content that overlaps with the synced rules. Look for keywords and patterns covered by each rule:

   | Rule | Search for |
   |------|-----------|
   | git-operations | commit format, branch naming, HEREDOC, PR structure |
   | coding-standards | fix all failures, test contract, contract verification |
   | coding-standards-python | `get_current_user`, RPC wrapper, pytest, black, ruff, mypy |
   | coding-standards-react-ts | design tokens, semantic Tailwind, Context+Hook, Vitest, RTL, `userEvent` |
   | db-conventions | migration-first, `db reset`, multi-tenancy, organization scoping |
   | db-conventions-supabase | `_rpc` suffix, `p_*` prefix, `result_*` prefix, supabase migration |
   | db-app-layer | raw SQL, RPC wrapper, ORM, database access |

   For each match found, report:
   - The project rule file and approximate line range
   - Which ccupa rule covers the same ground
   - A recommendation to remove or consolidate the section

   **Do not edit or delete project rules** — only report findings so the user can decide.

7. **Check for overlapping guidance in CLAUDE.md** — scan the project's `CLAUDE.md` (and any `**/CLAUDE.md` files) for overlaps using the same keyword table from step 5. For each match found, report:
   - The file and approximate line range
   - Which synced rule now covers it
   - A recommendation to remove or trim the section

   **Do not edit CLAUDE.md files** — only report findings so the user can decide what to remove.

## Guard Rails

- **Never delete** existing rules in `.claude/rules/` that don't have the `ccupa-` prefix — those belong to the project.
- **Overwrite** existing `ccupa-*` files — that's the point of syncing.
