---
name: review-tracking
description: Defines how review agents emit findings, how the fixer attributes actions, and how per-reviewer ROI is recorded to the global ledger. Use when running prep-commit or prep-merge-pr reviewer agents.
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
ACTED [review-correctness:2] — fixed off-by-one in pagination loop
DISMISSED [codex-review:1] — false positive: validation handled upstream in middleware
```

Format: `ACTED [agent-name:N] — brief description` or `DISMISSED [agent-name:N] — reason`

Every finding ID passed to the fixer must appear in its attribution report.

## Deduplication and Unique Find Tracking

During the deduplication step in prep-commit/prep-merge-pr Step 3:

1. Assign each raw finding a global ID: `{agent-name}:{N}` (e.g., `reviewer:1`, `codex-review:2`)
2. Group findings that refer to the same issue (same file+line, or clearly the same bug described differently)
3. For each group, record all contributing reviewers
4. A finding is **unique** to a reviewer if they are the only contributor in the group
5. Count unique finds per reviewer — used when writing the ledger

## Ledger Format

**Location:** `~/.claude/review-ledger.csv`

**Schema:**
```csv
datetime,project,command,reviewer,total_findings,unique_finds,actioned,dismissed
```

- `datetime` — `YYYY-MM-DD HH:MM` (local time at run start)
- `project` — basename of `git remote get-url origin`, or current directory name if no remote
- `command` — `prep-commit` or `prep-merge-pr`
- `reviewer` — agent name (`reviewer`, `codex-review`, `review-correctness`, `review-quality`, `review-security`)
- `total_findings` — count from **initial run only** (before fix loop)
- `unique_finds` — findings flagged by only this reviewer (from deduplication step)
- `actioned` — findings the fixer acted on (from fixer attribution)
- `dismissed` — findings the fixer dismissed (from fixer attribution)

**Append instructions:**
1. Check if `~/.claude/review-ledger.csv` exists. If not, create it and write the header row first.
2. For each reviewer that ran, append one row.
3. Reviewers that were skipped (e.g., no Codex installed) do not get a row.
4. Append after the fix loop exits — use initial run finding counts, not re-run counts.

## ROI Interpretation

- `unique_finds == 0` across multiple runs → reviewer adds no unique value; consider removing
- `unique_finds > 0` → evaluate `actioned / total_findings` as the actionable rate
- High `dismissed` with low `unique_finds` → reviewer is noisy and redundant
