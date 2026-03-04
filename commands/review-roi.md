# Review ROI

**Model: Haiku** — reading a CSV and computing aggregates is mechanical.

Analyze `~/.claude/review-ledger.csv` to surface which reviewers are earning their cost.

## Input
"$ARGUMENTS" - Optional project name to filter results. If empty, report across all projects.

## Process

### Step 1: Read Ledger
1. Check if `~/.claude/review-ledger.csv` exists. If not, report "No review data yet — run `/prep-commit` or `/prep-merge-pr` to start collecting data." and stop.
2. Read all rows. If `$ARGUMENTS` is provided, filter to rows where `project` matches.
3. Report the date range and total run count covered by the data.

### Step 2: Aggregate Per Reviewer
For each reviewer, compute across all matching rows:
- **Runs** — number of times this reviewer ran
- **Avg findings/run** — `sum(total_findings) / runs`
- **Unique finds** — `sum(unique_finds)` (total across all runs)
- **Actionable rate** — `sum(actioned) / sum(total_findings)` (skip if total_findings = 0)

### Step 3: Report

Present a ranked table, sorted by `unique_finds` descending:

```
Reviewer              Runs  Avg findings  Unique finds  Actionable rate
──────────────────────────────────────────────────────────────────────
review-security         12       2.1            8            71%
review-correctness      12       3.4            6            58%
reviewer                12       1.8            3            44%
review-quality          12       2.9            1            34%
codex-review            12       1.2            0            17%
```

Then call out:
- **Cut candidates**: reviewers with `unique_finds == 0` across all runs — they add no unique value
- **Low signal**: reviewers with `unique_finds > 0` but actionable rate below 25% — noisy relative to value
- **High value**: reviewers with the highest `unique_finds` and actionable rate above 50%

If fewer than 5 runs exist for a reviewer, note that the data is too sparse to draw conclusions.
