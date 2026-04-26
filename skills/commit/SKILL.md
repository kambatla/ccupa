---
description: "Stage, group, and commit changes per git conventions"
disable-model-invocation: true
---

# Commit Changes

## Input
"$ARGUMENTS" - Optional context. Pass `--skip-prep` to bypass the `/prep-commit` prerequisite check.

## Execution
Run as a Haiku sub-agent — this is a leaf workflow with no further sub-agents.

## Required Permissions
For unattended execution, add to `.claude/settings.local.json`. Run `/setup` to configure.
- `Bash(git *)`

## Process

0. **Prerequisites:** if `--skip-prep` is NOT in `$ARGUMENTS`, confirm `/prep-commit` was run in this conversation. If not, stop:
   > Run `/prep-commit` first, or pass `--skip-prep` to commit without it.

1. **Inspect state:**
   - `git status`, `git diff`, `git diff --staged`
   - `git log --oneline -5` to see recent commit style

2. **Analyze commit scope:**
   - **Split signals:** changes need "and" to describe, different motivations, independent subsystems
   - **Don't-split signals:** feature + its tests, refactor + formatting it causes, multiple files for same motivation
   - If **mixed**: propose groups to the user (files + draft subject per group), wait for approval
   - If **cohesive**: proceed as a single group

3. **Stage and commit per group** (infra before feature, refactor before new code):
   1. Stage specific files by name (not `git add -A`)
   2. Warn if `.env`, credentials, or build artifacts are about to be staged
   3. Draft commit message per git-conventions skill: `<type>: <description>`, focus on "why", imperative mood
   4. Commit using HEREDOC format. Do NOT include AI attribution.

4. **Verify:**
   - `git log --oneline -N` (N = commits created) to confirm all commits
   - `git status` to confirm clean working tree
