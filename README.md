# ccupa

Personal [Claude Code](https://claude.ai/code) plugin accumulated over ~6 months of recreational use. Most of it is simple and likely part of hundreds of thousands of similar plugins; a few less common parts called out below.

## Philosophy

Enable Claude Code to independently and quickly deliver high-quality code, so the user can spend as little time as possible.

### Test-driven development

For features and bug fixes alike, define desired outcomes clearly so Claude can (a) author tests verifying those outcomes and (b) iterate on implementation until verified.

**Define → Test → Implement** ordering is enforced in `/design`, `/implement`, and `/bug`. Tests are written against interfaces before implementation exists — this prevents bias toward verifying "how it was written" rather than "what it should do." Test cases are defined during design (Phase 2 of `/design`), carried into the implementation plan, and executed test-first by `/implement`.

**Stash-based bug fix proof** (`/bug`, `/prep-commit --bugfix`): stash the fix → run tests → they must fail (proving the bug is reproducible) → pop the stash → run tests → they must pass (proving the fix works). If the fail step doesn't fail, the test doesn't actually catch the bug — stop and revise.

### Intentional context management

Use agents to (a) reduce context usage of the main session and (b) limit confirmation bias.

**Clean-slate reviews.** Code reviews in `/prep-commit` and `/prep-merge-pr` run in separate agent sessions with no exposure to the implementation reasoning. The reviewer sees `git diff`, not the conversation that produced it.

**Three-reviewer pattern** (`/prep-merge-pr`): correctness, quality, and security — each reviewer goes deep on one concern instead of shallow on all three. They run in parallel (wall-clock time equals one review), produce independent perspectives, and findings are deduplicated before a single fixer agent addresses them in one pass.

### Parallelize where possible

Reduce wall-clock time by running independent workstreams simultaneously.

- `/prep-commit` spawns up to **6 parallel agents**: backend tests, frontend tests, backend quality, frontend quality, code reviewer, and Codex reviewer
- `/prep-merge-pr` spawns up to **8 parallel agents**: 2 test runners + 2 quality checkers + 3 specialized reviewers + Codex reviewer
- `/implement` spawns up to **3 parallel agents** (DB, backend, frontend) for features with independent layers

Conditional skipping avoids wasted work: quality agents are skipped if `/prep-commit` already ran them with no code changes since; the security reviewer only spawns when changes touch auth, API, DB, or user input handling; test/quality agents are skipped entirely for unchanged sides.

### Unattended execution

Agents that spawn sub-agents need tool permissions pre-configured in `.claude/settings.local.json` — otherwise they block waiting for user approval. The permissions skill handles this: `/setup` bootstraps permissions during onboarding and preflight checks run before every agent-heavy command. `/learn` reflects on the full session — including scanning for patterns approved at runtime — and proposes improvements to permissions, conventions, and workflows.

## Workflow

```mermaid
flowchart TB
 subgraph IMPL_A["↳ spawns in parallel (large features)"]
    direction LR
        IDB["db (Sonnet):<br/>Migrations + DB functions"]
        IBE["backend (Sonnet):<br/>API endpoints + tests"]
        IFE["frontend (Sonnet):<br/>UI components + tests"]
  end
 subgraph FEAT["Feature / Improvement"]
    direction TB
        BS["/brainstorm (Opus):<br/>Explore problem space,<br/>challenge assumptions"]
        DS["/design (Opus):<br/>Architect layers,<br/>define test cases, write plan"]
        IMP["/implement (Sonnet):<br/>Orchestrate implementation"]
        IMPL_A
  end
 subgraph BUG["Bug Fix"]
    direction TB
        BG["/bug (Opus):<br/>Trace root cause,<br/>write failing test,<br/>apply fix, verify"]
  end
 subgraph PC_A["↳ spawns in parallel"]
    direction LR
        PCT["backend-tests (Haiku):<br/>Scoped test run"]
        PCF2["frontend-tests (Haiku):<br/>Scoped test run"]
        PCQ["backend-quality (Haiku):<br/>Lint + auto-fix"]
        PCFQ["frontend-quality (Haiku):<br/>Lint + auto-fix"]
        PCR["reviewer (Opus):<br/>Code review"]
        PCC["codex-review (Codex):<br/>Codex CLI review"]
  end
 subgraph PMP_A["↳ spawns in parallel"]
    direction LR
        PMPT["backend-tests (Haiku):<br/>Full suite"]
        PMPF2["frontend-tests (Haiku):<br/>Full suite"]
        PMPI["integration-tests (Haiku):<br/>Full stack"]
        PMPQ["backend-quality (Haiku):<br/>Lint + auto-fix"]
        PMPFQ["frontend-quality (Haiku):<br/>Lint + auto-fix"]
        PMPR["reviewer (Opus):<br/>Correctness + quality"]
        PMPS["review-security (Sonnet):<br/>Security review"]
        PMPC["codex-review (Codex):<br/>Codex CLI review"]
  end
    PC["/prep-commit (Opus):<br/>Verify before each commit"]
    PCFIX["fixer (Sonnet):<br/>Fix findings<br/>(correctness → quality)"]
    CMT["/commit (Sonnet):<br/>Group by intent,<br/>stage, commit"]
    PMP["/prep-merge-pr (Opus):<br/>Full verification<br/>before merge"]
    PMPFIX["fixer (Sonnet):<br/>Fix findings<br/>(correctness → security<br/>→ quality)"]
    PR["/pr (Haiku):<br/>Push branch + create PR"]
    MRG["/merge (Haiku):<br/>Rebase on main,<br/>merge + clean up worktree"]
    SM["/sync-main (Haiku):<br/>Pull main + delete<br/>merged branches"]
    BS --> DS
    DS --> IMP
    IMP --> IMPL_A
    IMPL_A --> PC
    BG --> PC
    PC --> PC_A
    PC_A --> PCFIX
    PCFIX --> CMT
    CMT --> PMP
    PMP --> PMP_A
    PMP_A --> PMPFIX
    PMPFIX --> PR
    PR --> MRG
    MRG --> SM

     IDB:::sonnet
     IBE:::sonnet
     IFE:::sonnet
     BS:::skill
     DS:::skill
     IMP:::skill
     BG:::skill
     PCT:::haiku
     PCF2:::haiku
     PCQ:::haiku
     PCFQ:::haiku
     PCR:::opus
     PCC:::codex
     PMPT:::haiku
     PMPF2:::haiku
     PMPI:::haiku
     PMPQ:::haiku
     PMPFQ:::haiku
     PMPR:::opus
     PMPS:::sonnet
     PMPC:::codex
     PC:::skill
     PCFIX:::sonnet
     CMT:::skill
     PMP:::skill
     PMPFIX:::sonnet
     PR:::skill
     MRG:::skill
     SM:::skill
    classDef skill fill:#1e293b,color:#f8fafc,stroke:#64748b,stroke-width:1.5px
    classDef opus fill:#6d28d9,color:#fff,stroke:none
    classDef sonnet fill:#1d4ed8,color:#fff,stroke:none
    classDef haiku fill:#047857,color:#fff,stroke:none
    classDef codex fill:#800020,color:#fff,stroke:none
    classDef script fill:#92400e,color:#fff,stroke:none
```

## Workflow commands

| Command | Purpose |
|---------|---------|
| `/setup` | Onboard a project: configure permissions, bootstrap settings |
| `/brainstorm` | Explore problem space, challenge assumptions, recommend direction |
| `/design` | Architect layer-by-layer (storage → backend → frontend), define test cases |
| `/implement` | Execute plan — sequential or parallel agents, define → test → implement order |
| `/bug` | Investigate, write regression test, fix, prove fix works |
| `/prep-commit` | Parallel agents: scoped tests, quality checks, code review |
| `/commit` | Stage and commit per git conventions |
| `/prep-merge-pr` | Full test suites + 3 specialized reviews (correctness, quality, security) |
| `/pr` | Push branch, create PR via `gh` with structured body |
| `/merge` | Rebase on main, run `/prep-merge-pr`, merge, clean up |
| `/sync-main` | Pull latest main, delete merged local branches |
| `/push` | Push main to all configured remotes |
| `/learn` | Session reflection: review permissions, corrections, patterns; propose improvements |

## Convention skills

| Skill | Purpose |
|-------|---------|
| **coding-standards** | Python/FastAPI and React/TypeScript patterns, testing standards |
| **db-conventions** | Migration-first workflow, RPC functions, Supabase patterns |
| **git-conventions** | Commit format, branch naming, PR structure |
| **deployment** | Local dev setup and Digital Ocean production deployment |
| **permissions** | Preflight checks before agents, post-session review of runtime approvals |

## Installation

Clone this repository and add it as a Claude Code plugin:

```bash
claude mcp add-json ccupa '{"type":"local","path":"/path/to/ccupa"}'
```

Or add the plugin path in your Claude Code settings.

## License

[MIT](LICENSE)
