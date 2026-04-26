---
name: review-resolver
description: Defines how to spawn and brief the fixer agent that resolves deduplicated review findings. Use in the fix-verify loop of prep-commit or review-pr.
---

# Review Resolver

## Spawning

Spawn a fresh **Sonnet** `fixer` agent with:
- The **combined, deduplicated** findings from the most recent check run (test failures, quality errors, review issues), each identified by global ID (`agent-name:N`)
- Instruction: **Fix all valid issues. For false positives or intentional design choices, do not change code — explain why. Report ACTED or DISMISSED for every finding ID using the format below.**

## Attribution Format

```
ACTED [reviewer:1] — added input validation at api/search.py:23
ACTED [reviewer:2] — fixed off-by-one in pagination loop
DISMISSED [ext-review:1] — false positive: validation handled upstream in middleware
```

Every finding ID passed to the resolver must appear in the attribution report.

## Resolver Behavior

1. Make targeted code fixes for valid issues
2. Dismiss false positives with clear reasoning — no code change required
3. After fixes, run scoped tests for every changed file (backend: pytest scoped to changed test files; frontend: vitest `--run` scoped to changed test files). Self-correct up to 2 times if tests fail. Only mark ACTED after relevant tests pass. **Exception:** skip if the calling phase says "do NOT re-run tests" (e.g. Quality phase).
4. Report ACTED/DISMISSED for every finding received
