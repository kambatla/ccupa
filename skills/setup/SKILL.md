---
description: "Onboard project with tool permissions and conventions"
disable-model-invocation: true
---

# Project Setup

Onboard a consuming project with tool permissions and conventions. Interactive, one-time.

## Input
"$ARGUMENTS" - Not used.

## Execution
Run as a Haiku sub-agent — this is a leaf workflow with no further sub-agents.

## Process

### Step 1: Check Existing Setup
1. Read the project's `CLAUDE.md`
2. Read `.claude/settings.local.json` (if it exists)
3. Note what's already configured — avoid duplicating

### Step 2: Update CLAUDE.md
1. Check if `CLAUDE.md` already has a "Tool Permissions" section
2. If not, draft an addition instructing Claude to run permission preflight before non-interactive autonomous work:
   - Reference `skills/permissions/preflight.md`
   - List the non-interactive commands that spawn agents: `/implement`, `/bug`, `/prep-commit`, `/prep-pr`, `/review-pr`, `/review-branch`
3. Present the addition to the user
4. Write only after user confirms

### Step 3: Sync Rules
1. Run `/sync-rules` to copy ccupa convention rules into the project's `.claude/rules/` directory
2. Report which rules were synced and any CLAUDE.md overlap findings

### Step 4: Bootstrap Settings
1. Discover test and quality commands from the project's `CLAUDE.md` (Essential Commands section or equivalent)
2. Run the preflight procedure (`skills/permissions/preflight.md`) with the discovered commands as dynamic patterns
3. Present discovered patterns and offer to write `.claude/settings.local.json`

### Step 5: Report
1. Summarize what was added
2. Note that `/learn` can be used after any session for ongoing refinement
