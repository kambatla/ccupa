# Implementation Plan: Incorporate Forking

## Overview

Add fork sub-agent instructions to four decision-making skills (brainstorm, design, implement, bug) and add "fresh" qualifier to all existing sub-agent spawning language in five other skills.

No new files. No shell scripts. All changes are text edits to existing skill instruction files.

---

## Phase 1: Fork additions

Add forked sub-agent instructions at natural debate/tradeoff points in the four decision-making skills.

### Tasks

- [x] `skills/brainstorm/SKILL.md` — Phase 2, step 2: replace inline pros/cons with fork instruction (foreground)
- [x] `skills/design/SKILL.md` — Phase 2, steps 4–5: split into identify → fork → confirm; insert fork step (foreground)
- [x] `skills/implement/SKILL.md` — Approach section: add fork principle for multi-approach decision points (background)
- [x] `skills/bug/SKILL.md` — Step 2, item 1: append fork instruction for competing hypotheses (foreground or background, by judgment)

### Fork language (consistent across all four)

> When [trigger condition], create a forked, [foreground|background] sub-agent to evaluate tradeoffs and return a compact verdict: decision + rationale (2–3 sentences) + key tradeoff accepted. Record only the verdict — do not debate inline.

**Trigger conditions by skill:**
- brainstorm: comparing 2+ non-trivial approaches
- design: choosing between 2+ non-trivial approaches at a layer
- implement: non-trivial implementation decision with 2+ viable approaches
- bug: 2+ competing hypotheses about root cause

### Test

- Run `/brainstorm` on a 2-option problem → only compact verdict in main session, no inline debate
- Run `/design` on a feature with architectural choices → fork triggered at step 5 per layer; verdict returned; user confirms
- Run `/implement` on a feature that hits a decision point → background fork used; main session notified on completion
- Run `/bug` on a multi-hypothesis bug → fork used with appropriate foreground/background judgment

---

## Phase 2: Fresh additions

Add "fresh" qualifier to all existing sub-agent spawn language to prevent unintended context inheritance when `CLAUDE_CODE_FORK_SUBAGENT=1` is set globally.

### Tasks

- [x] `skills/prep-commit/SKILL.md` — Step 2: "Spawn fresh agents via the Task tool"
- [x] `skills/prep-pr/SKILL.md` — Step 2: "Spawn fresh agents via the Task tool"
- [x] `skills/review-branch/SKILL.md` — Step 2: "Spawn fresh agents via the Task tool"
- [x] `skills/implement/SKILL.md` — Step 2a: "spawn fresh teammates" (team spawn) + "spawn a fresh, single Sonnet `fixer` teammate" (cross-layer fixer)
- [x] `skills/review-resolver/SKILL.md` — Spawning section: "Spawn a fresh, single **Sonnet** `fixer` agent"

### Test

- Run `/prep-commit`, `/prep-pr`, `/review-branch` → agents receive task-specific prompts only; no unintended context inheritance
- Run `/implement` in parallel mode → teammates and cross-layer fixer are fresh, not forked
