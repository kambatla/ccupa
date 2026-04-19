---
name: review-tracking
description: Defines how review agents emit findings, how the fixer attributes actions, and how per-reviewer ROI is recorded to the global ledger. Use when running prep-commit or review-pr reviewer agents.
---

# Review Tracking Skill

Tracks reviewer ROI across runs and projects so you can identify which reviewers consistently find unique, actionable issues.

## Finding Format (reviewer agents)

Each reviewer must number and structure their findings:

```
[1] high | security — User input passed directly to query without validation (api/search.py:23)
[2] medium | logic — Pagination skips last item when count equals page size (api/items.py:87)
[3] low | quality — Variable name `x` is not descriptive (utils.py:12)
```

Format: `[N] severity | category — description (file:line)`

- **severity**: `high`, `medium`, or `low`
- **category**: `security`, `logic`, `quality`, `coverage`, or `style`
- If no findings: output `[none]`

## Fixer Attribution Format

After fixing, the fixer must report disposition for every finding ID it received:

```
ACTED [reviewer:1] — added input validation at api/search.py:23
ACTED [reviewer:2] — fixed off-by-one in pagination loop
DISMISSED [codex-review:1] — false positive: validation handled upstream in middleware
```

Format: `ACTED [agent-name:N] — brief description` or `DISMISSED [agent-name:N] — reason`

Every finding ID passed to the fixer must appear in its attribution report.

## Deduplication and Unique Find Tracking

During the deduplication step in prep-commit/review-pr Step 3:

1. Assign each raw finding a global ID: `{agent-name}:{N}` (e.g., `reviewer:1`, `codex-review:2`)
2. Group findings that refer to the same issue (same file+line, or clearly the same bug described differently)
3. For each group, record all contributing reviewers
4. A finding is **unique** to a reviewer if they are the only contributor in the group

