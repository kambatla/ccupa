---
description: "Architect feature as tasks with sub-agent exploration and layer-by-layer decisions"
disable-model-invocation: true
---

# Feature Design

## Input
"$ARGUMENTS" - If empty, ask what feature to design. If `from-plan`, resume from an existing plan mode session (skip to Phase 4). Otherwise, use as starting point.

**Work through phases sequentially. Complete each phase fully before proceeding.**

## Process

### Resume from Plan Mode (`from-plan`)
1. Read `.claude/plan.md`. If it doesn't exist, fall through to Phase 1.
2. Summarize key decisions and ask user to confirm before proceeding.
3. Check whether the plan covers Phases 1–3 (affected layers identified, decision records present).
4. If gaps exist, work through only the missing pieces.
5. Proceed to Phase 4, then Phase 5 (Confirm).

### Phase 1: Clarify (main session)
Ask up to 3–5 targeted questions: scope, affected users, key constraints. No codebase exploration yet.

Goal: identify which layers are touched (DB, backend, frontend) and what the feature must accomplish. State the affected layers and proceed.

### Phase 2: Explore (parallel Explore sub-agents)
Spawn one Explore sub-agent per affected layer in a **single message**. Skip layers with no changes.

Each agent returns:
- Concrete file paths to create or modify
- Existing patterns to reuse (file:function references)
- Potential conflicts with adjacent code

Main session collects outputs and does NOT explore itself.

### Phase 3: Architecture decisions (sequential Plan sub-agents, bottom-up)

Decisions cascade: DB schema → RPC signatures → API contracts → UI. Run one Plan sub-agent per affected layer in order. Each receives only: (a) its layer's exploration output from Phase 2, and (b) the compact decision record from the layer above.

**DB/schema architect** (Plan sub-agent)
- Proposes table/column/migration design and RPC signatures
- When a non-trivial trade-off arises: return options to main session with pros/cons; user decides; feed decision back
- Returns compact DB decision record: table names, column types, RPC function signatures — no prose

**API/backend architect** (Plan sub-agent)
- Input: API exploration + DB decision record
- Proposes endpoint shapes, auth requirements, service logic; surfaces trade-offs to main session
- Returns compact API decision record: endpoint paths, request/response shapes, key invariants

**Frontend architect** (Plan sub-agent — only if frontend changes)
- Input: frontend exploration + API decision record
- Proposes component structure, state management, data-fetching approach; surfaces trade-offs
- Returns compact frontend decision record

Main session accumulates only the compact decision records (~10–20 lines each).

### Phase 4: Task decomposition + plan synthesis (Plan sub-agent)
Spawn one Plan sub-agent with all decision records + Phase 1 constraints.

It decomposes the work into task blocks using the task definition:

> **A task is the largest independent unit of work that accomplishes a verifiable behavioral contract. Its commit message does not require "and".**

Each task block:
```markdown
## Task <N>: <short title>

- **Description**: What to implement and the behavioral contract it fulfills
- **Success criteria**: Testable outcome
- **Primary files**: Known files to create/modify (agent may touch others as needed)
- **Patterns to follow**: file:function references
- **Depends on**: Task IDs (empty = independent)
- **Test**: Test file + assertion description
```

Maps `Depends on` relationships across tasks. Writes the draft plan to `plans/<feature>/implementation-plan.md`.

### Phase 5: Confirm (main session)
Present task list + key decisions to the user. Ask for approval or amendments.

If amendments: update the affected decision record(s) and re-run Phase 4 only — do not redo exploration or architecture for unaffected layers.

## Approach
- Call out tech debt, feature creep, and over-engineering
- Augment-first: extend existing services, endpoints, and UI elements before introducing new abstractions

## Next Step
Use `/implement` to execute the implementation plan.
