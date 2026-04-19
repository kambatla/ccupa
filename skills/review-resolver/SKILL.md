---
name: review-resolver
description: Defines how to spawn and brief the fixer agent that resolves deduplicated review findings. Use in the fix-verify loop of prep-commit or review-pr.
---

# Review Resolver Skill

The review resolver is a **Sonnet** agent that receives combined, deduplicated findings from all review agents and resolves each one — fixing valid issues or explicitly dismissing false positives with reasoning.

## Spawning the Resolver

Spawn a single **Sonnet** `fixer` agent with:
- The **combined, deduplicated** findings from the most recent check run — test failures, quality errors, and review issues — each identified by global ID (`agent-name:N`)
- This instruction: **Fix all issues. For each finding, report disposition per `ccupa:review-tracking` skill (ACTED or DISMISSED with reason). If an issue is a false positive or intentional design choice, do not change code for it — explain why in your response.**

## Resolver Behavior

The resolver must:
1. Address each finding by its global ID
2. Make targeted code fixes for valid issues
3. Dismiss false positives and intentional design choices with clear reasoning — no code change required
4. **After applying fixes, run scoped tests for every file changed** — backend files: run pytest scoped to the changed test files; frontend files: run vitest with `--run` scoped to the changed test files. If tests fail, self-correct: update tests that are now stale due to behavior changes, or revise the fix approach. Up to 2 self-correction attempts per fix. Only mark a finding ACTED after the relevant tests pass. **Exception:** if the calling command's phase rules say "do NOT re-run tests" (e.g., Quality phase), skip this step — the orchestrator controls when tests run.
5. Report ACTED/DISMISSED attribution for every finding it received (see `ccupa:review-tracking` for format)

Every finding ID passed to the resolver must appear in its attribution report.
